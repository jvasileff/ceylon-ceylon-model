import com.vasileff.ceylon.model {
    Unit,
    Type,
    union,
    intersection,
    Package,
    Variance,
    contravariant,
    covariant,
    TypeDeclaration,
    unionType
}

shared
Type parseType(Unit unit, String input) {
    variable List<Token> tokens
        =   TokenStream(input)
                .filter((token) => !token is IgnoredToken)
                .sequence();

    void consume(Integer count = 1) {
        tokens = tokens.sublistFrom(count);
    }

    Token check(Token? token, String? type) {
        if (!exists token) {
            if (exists type) {
                throw Exception("Unexpected end of input: expected ``type``");
            }
            else {
                throw Exception("Unexpected end of input");
            }
        }
        if (exists type, !token.type == type) {
            throw Exception("Unexpected token: expected ``type``, found ``token``");
        }
        return token;
    }

    Token checkAny(Token? token, String+ types) {
        if (!exists token) {
            throw Exception("Unexpected end of input: expected ``types``");
        }
        if (!token.type in types) {
            throw Exception("Unexpected token: expected ``types``, found ``token``");
        }
        return token;
    }

    Token expectAny(String+ types) {
        value token = checkAny(tokens.first, *types);
        consume();
        return token;
    }

    Token expect(String? type) {
        value token = check(tokens.first, type);
        consume();
        return token;
    }

    TypeDeclaration? lookup(Package | Type | Null qualifier, String name) {
        switch (qualifier)
        case (is Package) {
            if (is TypeDeclaration d = qualifier.findDeclaration([name])) {
                return d;
            }
        }
        case (is Type) {
            if (is TypeDeclaration d = qualifier.declaration.getMember(name)) {
                return d;
            }
        }
        case (is Null) {
            // TODO search unit's imports, not just it's declarations.
            if (is TypeDeclaration found
                =   unit.declarations.find((d) => d.name == name)) {
                return found;
            }
        }
        return null;
    }

    """
       Type: UnionType | EntryType
       EntryType: UnionType "->" UnionType
    """
    Type parseType() {
        """
           UnionType: IntersectionType ("|" IntersectionType)*
        """
        Type parseUnionType() {

            """
               GroupedType: "<" Type ">"
            """
            Type parseGroupedType() {
                expect("SmallerOp");
                value result = parseType();
                expect("LargerOp");
                return result;
            }

            """
               TypeArgument: Variance Type
               Variance: ("out" | "in")?
            """
            [Variance?, Type] parseTypeArgument() {
                Variance? variance
                    =   switch (token = tokens.first)
                        case (is InKeyword) contravariant
                        case (is OutKeyword) covariant
                        else null;

                if (variance exists) {
                    consume();
                }

                return [variance, parseType()];
            }

            """
               TypeArguments: "<" ((TypeArgument ",")* TypeArgument)? ">"
            """
            [[Variance?, Type]*] parseTypeArguments() {
                expect("SmallerOp");

                variable {[Variance?, Type]*} arguments = [];
                while (true) {
                    arguments = arguments.follow(parseTypeArgument());
                    if (!tokens.first is Comma) {
                        break;
                    }
                    consume();
                }

                expect("LargerOp");
                return arguments.sequence().reversed;
            }

            """
               TypeNameWithArguments: TypeName TypeArguments?
            """
            String parseTypeName() {
                value token = expect("UIdentifier");
                assert (is UIdentifier token);
                return token.identifier;
            }

            """
               TypeNameWithArguments: TypeName TypeArguments?
            """
            Type parseTypeNameWithArguments(Package | Type | Null qualifier) {
                value name = parseTypeName();

                if (exists declaration = lookup(qualifier, name)) {

                    value typeArguments
                        =   if (tokens.first is SmallerOp)
                            then parseTypeArguments()
                            else [];

                    value [overrideAnnotations, types]
                        =   if (typeArguments.empty)
                            then [[],[]]
                            else unzipPairs(typeArguments);

                    value overrides
                        =   if (typeArguments.empty
                                || overrideAnnotations.coalesced.empty)
                            then emptyMap
                            else
                                let (entries
                                    =   zipEntries(declaration.typeParameters,
                                                   overrideAnnotations))
                                map {
                                    for (parameter -> override in entries)
                                     if (exists  override)
                                      parameter -> override
                                };

                    return declaration.appliedType {
                        qualifyingType
                            =   if (is Type qualifier)
                                then qualifier
                                else null;
                        typeArguments = types;
                        varianceOverrides = overrides;
                    };
                }
                else {
                    throw Exception("type does not exist: ``name`` \
                                     in ``qualifier else unit``");
                }
            }

            """
               PackageQualifier: "package" "."
            """
            Package? parsePackageQualifier() {
                // FIXME cleanup; check before consuming.
                // FIXME detect "package" and return unit.package.
                //       also document lident (. lident)* `::`

                value token = tokens.first;
                if (!is LIdentifier token) {
                    return null;
                }

                value packageName = StringBuilder();
                packageName.append(token.identifier);
                consume();

                while (tokens.first is MemberOp) {
                    consume();
                    packageName.append(".");
                    value namePart = expect("LIdentifier");
                    assert (is LIdentifier namePart);
                    packageName.append(namePart.identifier);
                }

                expect("DoubleColon");

                value result = unit.mod.findPackage(packageName.string);
                if (!exists result) {
                    throw Exception("package not found: '``packageName.string``'");
                }

                return result;
            }

            """
               BaseType: PackageQualifier? TypeNameWithArguments | GroupedType
               TypeNameWithArguments: TypeName TypeArguments?
               PackageQualifier: "package" "."
               GroupedType: "<" Type ">"
            """
            Type parseBaseType()
                =>  if (tokens.first is SmallerOp) then
                        parseGroupedType()
                    else
                        parseTypeNameWithArguments {
                            parsePackageQualifier();
                        };

            """
               QualifiedType: BaseType ("." TypeNameWithArguments)*
            """
            Type parseQualifiedType() {
                variable value type = parseBaseType();
                while (tokens.first is MemberOp) {
                    consume();
                    type = parseTypeNameWithArguments(type);
                }
                return type;
            }

            """
               TypeList: (DefaultedType ",")* (DefaultedType | VariadicType)

               DefaultedType: Type "="?
               VariadicType: UnionType ("*" | "+")
            """
            Type parseTypeList() {
                // TODO for now, using parseType, so a variadic like 'String->String*'
                //      is accepted. More correct would be to use parseUnion and then
                //      check for "->" and handle Entries here, which would allow us
                //      to disallow Entry variadics.

                variable value defaulted = 0;

                variable {Type*} types = [parseType()];

                if (tokens.first is Specify ) {
                    consume();
                    defaulted++;
                }

                while (tokens.first is Comma) {
                    consume();
                    types = types.follow(parseType());
                    if (tokens.first is Specify ) {
                        consume();
                        defaulted++;
                    }
                    else if (defaulted.positive && !tokens.first is ProductOp) {
                        // TODO better location info
                        throw Exception(
                            "Non-defaulted argument after defaulted argument");
                    }
                }

                ProductOp | SumOp | Null variadic;
                if (is ProductOp | SumOp symbol = tokens.first) {
                    consume();
                    variadic = symbol;
                }
                else {
                    variadic = null;
                }

                variable Type result;
                variable Type element;

                // calculate rest
                switch (variadic)
                case (is Null) {
                    result = unit.emptyDeclaration.type;
                    element = unit.nothingDeclaration.type;
                }
                case (is ProductOp | SumOp) {
                    value declaration
                        =   switch (variadic)
                            case (is ProductOp) unit.sequentialDeclaration
                            case (is SumOp) unit.sequenceDeclaration;

                    assert (exists restType = types.first);
                    result = declaration.appliedType {
                        null;
                        [restType];
                    };
                    element = restType;
                    types = types.rest;
                }

                // build the leading part of the tuple
                for (first in types) {
                    element = unionType(first, element, unit);
                    result = unit.tupleDeclaration.appliedType {
                        null;
                        [element, first, result];
                    };
                    if (defaulted-- > 0) {
                        result = unionType {
                            result;
                            unit.emptyDeclaration.type;
                            unit;
                        };
                    }
                }

                return result;
            }

            """
               TupleType: "[" TypeList "]" | PrimaryType "[" DecimalLiteral "]"

               This method handles the first. The second is handled by
               parseSequence().
            """
            Type parseTupleType() {
                expect("LBracket");
                value result = parseTypeList();
                expect("RBracket");
                return result;
            }

            """
               IterableType: "{" UnionType ("*"|"+") "}"
            """
            Type parseIterableType() {
                expect("LBrace");
                value type = parseUnionType();
                value absent = switch(_ = expectAny("ProductOp", "SumOp"))
                               case (is ProductOp) unit.nullDeclaration.type
                               else unit.nothingDeclaration.type;
                expect("RBrace");
                return unit.iterableDeclaration.appliedType(null, [type, absent]);
            }

            """
               AtomicType: QualifiedType | EmptyType | TupleType | IterableType
            """
            Type parseAtomicType() {
                switch (token = tokens.first)
                case (is LBracket) { // empty or tuple
                    if (tokens[1] is RBracket) {
                        consume(2);
                        return unit.emptyDeclaration.type;
                    }
                    else {
                        return parseTupleType();
                    }
                }
                case (is LBrace) {
                    return parseIterableType();
                }
                else {
                    return parseQualifiedType();
                }
            }

            """
               SequenceType: PrimaryType "[" "]"

               This method also handles the second part of:

               TupleType: "[" TypeList "]" | PrimaryType "[" DecimalLiteral "]"
            """
            Type parseSequenceType(Type primaryType) {
                expect("LBracket");
                if (is DecimalLiteral sizeToken = tokens.first) {
                    // TupleType[123]
                    assert (exists size = parseInteger(sizeToken.text));
                    if (!size.positive) {
                        throw Exception("Tuple size must be positive");
                    }
                    consume();
                    expect("RBracket");
                    variable value type
                        =   unit.tupleDeclaration.appliedType {
                                null;
                                [primaryType, primaryType, unit.emptyDeclaration.type];
                            };
                    for (_ in 0:size-1) {
                        type
                            =   unit.tupleDeclaration.appliedType {
                                    null;
                                    [primaryType, primaryType, type];
                                 };
                    }
                    return type;
                }
                else {
                    // SequenceType[]
                    expect("RBracket");
                    return unit.getSequentialType(primaryType);
                }
            }

            """
               OptionalType: PrimaryType "?"
            """
            Type parseOptionalType(Type primaryType) {
                expect("QuestionMark");
                return union([primaryType, unit.nullDeclaration.type], unit);
            }

            """
               PrimaryType: AtomicType | OptionalType | SequenceType | CallableType

               AtomicType: QualifiedType | EmptyType | TupleType | IterableType
               OptionalType: PrimaryType "?"
               SequenceType: PrimaryType "[" "]"
               CallableType: PrimaryType "(" (TypeList? | SpreadType) ")"
            """
            Type parsePrimaryType() {
                """
                   CallableType: PrimaryType "(" (TypeList? | SpreadType) ")"

                   SpreadType: "*" UnionType
                """
                Type parseCallableType(Type primaryType) {
                    Type arguments;
                    expect("LParen");
                    if (!tokens.first is RParen) {
                        if (tokens.first is ProductOp) {
                            // spread type; the type is the type of the argument list
                            consume();
                            arguments = parseUnionType();
                        }
                        else {
                            arguments = parseTypeList();
                        }
                    }
                    else {
                        arguments = unit.emptyDeclaration.type;
                    }
                    expect("RParen");

                    return unit.callableDeclaration.appliedType {
                        null;
                        [primaryType, arguments];
                    };
                }

                // PrimaryType: AtomicType | OptionalType | SequenceType | CallableType
                variable value type = parseAtomicType();
                while (exists token = tokens.first) {
                    switch (token)
                    case (is QuestionMark) {
                        type = parseOptionalType(type);
                    }
                    case (is LBracket) {
                        type = parseSequenceType(type);
                    }
                    case (is LParen) {
                        type = parseCallableType(type);
                    }
                    else {
                        break;
                    }
                }
                return type;
            }

            """
               IntersectionType: PrimaryType ("&" PrimaryType)*
            """
            Type parseIntersectionType() {
                value type = parsePrimaryType();
                if (tokens.empty) {
                    return type;
                }
                else {
                    variable {Type+} types = [type];
                    while (tokens.first is IntersectionOp) {
                        types.follow(parsePrimaryType());
                    }
                    return intersection(types.sequence().reversed, unit);
                }
            }

            // UnionType: IntersectionType ("|" IntersectionType)*
            value type = parseIntersectionType();
            if (tokens.empty) {
                return type;
            }
            else {
                variable {Type+} types = [type];
                while (tokens.first is UnionOp) {
                    types.follow(parseIntersectionType());
                }
                return union(types.sequence().reversed, unit);
            }
        }

        // Type: UnionType | EntryType
        // EntryType: UnionType "->" UnionType
        value type = parseUnionType();
        if (tokens.first is EntryOp) {
            consume();
            Type type2 = parseUnionType();
            return unit.entryDeclaration.appliedType(null, {type, type2});
        }

        return type;
    }

    value result = parseType();
    if (exists token = tokens.first) {
        throw Exception("unexpected token: found ``token``");
    }
    return result;
}
