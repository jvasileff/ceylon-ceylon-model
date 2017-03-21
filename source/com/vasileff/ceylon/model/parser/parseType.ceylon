import com.vasileff.ceylon.model {
    Type,
    union,
    intersection,
    Package,
    Variance,
    contravariant,
    covariant,
    TypeDeclaration,
    unionType,
    Scope
}

shared
Type parseType(String input, Scope scope, {Type*} substitutions = []) {
    variable value nextToken = null of Token | Finished | Null;

    value substitutionIterator = substitutions.iterator();

    value tokenIterator = TokenStream(input)
            .filter((token) => !token is IgnoredToken)
            .iterator();

    void consume() {
        if (nextToken exists) {
            nextToken = null;
        }
        else {
            tokenIterator.next();
        }
    }

    Token? peek() {
        value token = nextToken else (nextToken = tokenIterator.next());
        if (is Finished token) {
            return null;
        }
        return token;
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
        value token = checkAny(peek(), *types);
        consume();
        return token;
    }

    Token expect(String? type) {
        value token = check(peek(), type);
        consume();
        return token;
    }

    Token? match(String type) {
        value token = peek();
        if (exists token, token.type == type) {
            consume();
            return token;
        }
        return null;
    }

    TypeDeclaration? lookup(Package | Type | Null qualifier, String name)
        =>  if (is TypeDeclaration declaration
                =   switch (qualifier)
                    case (is Package) qualifier.findDeclaration([name])
                    case (is Type) qualifier.declaration.getMember(name, scope.unit)
                    case (is Null) scope.getBase(name, scope.unit))
            then declaration
            else null;

    """
       Type      : UnionType | EntryType
    """
    Type parseType() {
        """
           UnionType : IntersectionType ("|" IntersectionType)*\
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
               TypeArgument : Variance Type
               Variance     : ("out" | "in")?
            """
            [Variance?, Type] parseTypeArgument() {
                Variance? variance
                    =   switch (token = peek())
                        case (is InKeyword) contravariant
                        case (is OutKeyword) covariant
                        else null;

                if (variance exists) {
                    consume();
                }

                return [variance, parseType()];
            }

            """
               TypeArguments : "<" ((TypeArgument ",")* TypeArgument)? ">"
            """
            [[Variance?, Type]*] parseTypeArguments() {
                expect("SmallerOp");

                variable {[Variance?, Type]*} arguments = [];
                while (true) {
                    arguments = arguments.follow(parseTypeArgument());
                    if (!match("Comma") exists) {
                        break;
                    }
                }

                expect("LargerOp");
                return arguments.sequence().reversed;
            }

            """
               TypeNameWithArguments : TypeName TypeArguments?
            """
            String parseTypeName() {
                value token = expect("UIdentifier");
                return token.text;
            }

            """
               TypeNameWithArguments : TypeName TypeArguments?
            """
            Type parseTypeNameWithArguments(Package | Type | Null qualifier = null) {
                value name = parseTypeName();

                if (exists declaration = lookup(qualifier, name)) {

                    value typeArguments
                        =   if (peek() is SmallerOp)
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
                                     in ``qualifier else scope``");
                }
            }

            """
               PackageQualifier : ("package" ".")
                                  | ("$" | "."? LIdentifier) ("." LIdentifier)* "::"
            """
            Package parsePackageQualifier() {
                value packageName = StringBuilder();

                value token = expectAny("PackageKeyword", "DollarSign",
                                        "MemberOp", "LIdentifier");

                switch (token)
                case (is PackageKeyword) {
                    expect("MemberOp");
                    return scope.pkg;
                }
                case (is DollarSign) {
                    // '$' is a shortcut for "ceylon.language"
                    packageName.append("ceylon.language");
                }
                case (is MemberOp) {
                    // '.' is a shortcut for the scope's package
                    packageName.append(scope.pkg.qualifiedName);
                    if (exists identifier = match("LIdentifier")) {
                        packageName.append(".");
                        packageName.append(identifier.text);
                    }
                }
                else {
                    assert (is LIdentifier token);
                    packageName.append(token.text);
                }

                while (match("MemberOp") exists) {
                    packageName.append(".");
                    value namePart = expect("LIdentifier");
                    packageName.append(namePart.text);
                }

                expect("DoubleColon");

                value result = scope.unit.mod.findPackage(packageName.string);
                if (!exists result) {
                    throw Exception("package not found: '``packageName.string``'");
                }

                return result;
            }

            """
               BaseType : GroupedType | PackageQualifier? TypeNameWithArguments
            """
            Type parseBaseType() {
                return switch (token = peek())
                case (is LargerOp)
                    parseGroupedType()
                case (is PackageKeyword | DollarSign | MemberOp | LIdentifier)
                    parseTypeNameWithArguments(parsePackageQualifier())
                else
                    parseTypeNameWithArguments();
            }

            """
               QualifiedType: BaseType ("." TypeNameWithArguments)*
            """
            Type parseQualifiedType() {
                variable value type = parseBaseType();
                while (match("MemberOp") exists) {
                    type = parseTypeNameWithArguments(type);
                }
                return type;
            }

            """
               TypeList      : (DefaultedType ",")* (DefaultedType | VariadicType)

               DefaultedType : Type "="?
               VariadicType  : UnionType ("*" | "+")
            """
            Type parseTypeList() {
                // TODO for now, using parseType, so a variadic like 'String->String*'
                //      is accepted. More correct would be to use parseUnion and then
                //      check for "->" and handle Entries here, which would allow us
                //      to disallow Entry variadics.

                variable value defaulted = 0;

                variable {Type*} types = [parseType()];

                if (match("Specify") exists) {
                    defaulted++;
                }

                while (match("Comma") exists) {
                    types = types.follow(parseType());
                    if (match("Specify") exists) {
                        defaulted++;
                    }
                    else if (defaulted.positive && !peek() is ProductOp) {
                        throw Exception(
                            "Non-defaulted argument after defaulted argument");
                    }
                }

                ProductOp | SumOp | Null variadic;
                if (is ProductOp | SumOp symbol = peek()) {
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
                    result = scope.unit.emptyDeclaration.type;
                    element = scope.unit.nothingDeclaration.type;
                }
                case (is ProductOp | SumOp) {
                    value declaration
                        =   switch (variadic)
                            case (is ProductOp) scope.unit.sequentialDeclaration
                            case (is SumOp) scope.unit.sequenceDeclaration;

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
                    element = unionType(first, element, scope.unit);
                    result = scope.unit.tupleDeclaration.appliedType {
                        null;
                        [element, first, result];
                    };
                    if (defaulted-- > 0) {
                        result = unionType {
                            scope.unit.emptyDeclaration.type;
                            result;
                            scope.unit;
                        };
                    }
                }

                return result;
            }

            """
               TupleType : "[" TypeList? "]"
            """
            Type parseTupleType() {
                expect("LBracket");
                if (match("RBracket") exists) {
                    return scope.unit.emptyDeclaration.type;
                }
                value result = parseTypeList();
                expect("RBracket");
                return result;
            }

            """
               IterableType : "{" UnionType ("*"|"+") "}"
            """
            Type parseIterableType() {
                expect("LBrace");
                value type = parseUnionType();
                value absent
                    =   switch(_ = expectAny("ProductOp", "SumOp"))
                        case (is ProductOp) scope.unit.nullDeclaration.type
                        else scope.unit.nothingDeclaration.type;
                expect("RBrace");
                return scope.unit.iterableDeclaration.appliedType(
                        null, [type, absent]);
            }

            """
               Substitution : "^"
            """
            Type parseSubstitution() {
                expect("Caret");
                assert (is Type t = substitutionIterator.next());
                return t;
            }

            """
               AtomicType : QualifiedType | TupleType | IterableType | Substitution
            """
            Type parseAtomicType()
                =>  switch (_ = peek())
                    case (is LBracket) parseTupleType()
                    case (is LBrace) parseIterableType()
                    case (is Caret) parseSubstitution()
                    else parseQualifiedType();

            """
               TypeSuffix : ( OptionalSuffix
                            | SequenceSuffix
                            | TupleLengthSuffix
                            | ParameterListSuffix )?
            """
            Type parseTypeSuffix(Type primaryType) {
                """
                   OptionalSuffix : "?" TypeSuffix
                """
                Type parseOptionalSuffix(Type primaryType) {
                    expect("QuestionMark");
                    return parseTypeSuffix(union(
                        [primaryType, scope.unit.nullDeclaration.type],
                        scope.unit
                    ));
                }

                """
                   SequenceSuffix : "[" DecimalLiteral? "]" TypeSuffix
                """
                Type parseSequenceSuffix(Type primaryType) {
                    expect("LBracket");
                    if (exists sizeToken = match("DecimalLiteral")) {
                        assert (is Integer size = Integer.parse(sizeToken.text));
                        if (!size.positive) {
                            throw Exception("Tuple size must be positive");
                        }
                        expect("RBracket");
                        variable value type
                            =   scope.unit.tupleDeclaration.appliedType {
                                    null;
                                    [primaryType, primaryType,
                                    scope.unit.emptyDeclaration.type];
                                };
                        for (_ in 0:size-1) {
                            type = scope.unit.tupleDeclaration.appliedType {
                                null;
                                [primaryType, primaryType, type];
                            };
                        }
                        return parseTypeSuffix(type);
                    }
                    else {
                        expect("RBracket");
                        return parseTypeSuffix(scope.unit.getSequentialType(primaryType));
                    }
                }

                """
                   ParameterListSuffix : "(" (TypeList? | SpreadType) ")" TypeSuffix
                   SpreadType          : "*" UnionType
                """
                Type parseParameterListSuffix(Type primaryType) {
                    expect("LParen");

                    Type arguments
                        =   if (match("ProductOp") exists) then
                                parseUnionType() // spread types
                            else if (!peek() is RParen) then
                                parseTypeList()
                            else
                                scope.unit.emptyDeclaration.type;

                    expect("RParen");

                    return scope.unit.callableDeclaration.appliedType {
                        null;
                        [primaryType, arguments];
                    };
                }

                return switch (_ = peek())
                    case (is QuestionMark) parseOptionalSuffix(primaryType)
                    case (is LBracket) parseSequenceSuffix(primaryType)
                    case (is LParen) parseParameterListSuffix(primaryType)
                    else primaryType;
            }

            """
               PrimaryType         : AtomicType TypeSuffix
            """
            Type parsePrimaryType()
                =>  parseTypeSuffix(parseAtomicType());

            """
               IntersectionType: PrimaryType ("&" PrimaryType)*
            """
            Type parseIntersectionType() {
                variable {Type+} types = [parsePrimaryType()];
                while (match("IntersectionOp") exists) {
                    types = types.follow(parsePrimaryType());
                }
                return intersection(types.sequence().reversed, scope.unit);
            }

            // UnionType: IntersectionType ("|" IntersectionType)*
            variable {Type+} types = [parseIntersectionType()];
            while (match("UnionOp") exists) {
                types = types.follow(parseIntersectionType());
            }
            return union(types.sequence().reversed, scope.unit);
        }

        // parseType()
        //     Type      : UnionType | EntryType
        //     EntryType : UnionType "->" UnionType
        value type1 = parseUnionType();
        if (match("EntryOp") exists) {
            Type type2 = parseUnionType();
            return scope.unit.entryDeclaration.appliedType(null, [type1, type2]);
        }

        return type1;
    }

    value result = parseType();
    if (exists token = peek()) {
        throw Exception("unexpected token: found ``token``");
    }
    return result;
}
