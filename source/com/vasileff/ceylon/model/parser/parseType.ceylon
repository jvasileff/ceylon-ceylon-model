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
Type parseType(String input, Scope scope, {Type*} substitutions = [])
        => object satisfies Producer<Type> {

    variable value nextToken = null of Token | Finished | Null;

    value substitutionIterator = substitutions.iterator();

    value tokenIterator = TokenStream(input)
            .filter((token) => !token is IgnoredToken)
            .iterator();

    ParseException error(Token? token, String errorDescription) {
        if (!exists token) {
            return ParseException("Unexpected end of input; ``errorDescription``");
        }
        return ParseException("Unexpected token ``token``; ``errorDescription``");
    }

    "Return the next token, or null if there is no next token; do not advance."
    Token? peek()
        =>  let (token = nextToken else (nextToken = tokenIterator.next()))
            if (!is Finished token) then token else null;

    "Return the next token if one exists and it matches [[type]]; do not advance."
    Token? peekIf(Boolean(TokenType) | TokenType type) {
        value token = peek();
        if (!exists token) {
            return null;
        }
        if (is TokenType type) {
            if (type == token.type) {
                return token;
            }
        }
        else if (type(token.type)) {
            return token;
        }
        return null;
    }

    "Return the next token if one exists and it matches any of the given [[types]];
     do not advance."
    Token? peekIfAny(Boolean(TokenType) | TokenType+ types) {
        value token = peek();
        if (!exists token) {
            return null;
        }
        for (type in types) {
            if (is TokenType type) {
                if (type == token.type) {
                    return token;
                }
            }
            else if (type(token.type)) {
                return token;
            }
        }
        return null;
    }

    "Advance and return the next token if one exists."
    Token? advance() {
        value token = peek();
        nextToken = null;
        return token;
    }

    "Advance and return the next token if one exists and it matches [[type]]."
    Token? advanceIf(Boolean(TokenType) | TokenType type) {
        value token = peekIf(type);
        if (token exists) {
            advance();
        }
        return token;
    }

    "Advance and return the next token if one exists and it matches any of the given
     [[types]]."
    Token? advanceIfAny(Boolean(TokenType) | TokenType+ types) {
        value token = peekIfAny(*types);
        if (token exists) {
            advance();
        }
        return token;
    }

    "Advance to the next token and return `true` if one exists and it matches [[type]];
     otherwise return `false`."
    Boolean accept(Boolean(TokenType) | TokenType type)
        =>  advanceIf(type) exists;

    "Return true if the next token exists and matches [[type]]; do not advance."
    Boolean check(Boolean(TokenType) | TokenType type)
        =>  peekIf(type) exists;

    "Advance past the next token which must be of the given [[type]], or raise an error
     if the next token does not exist or does not match the given `type`."
    Token consume(Boolean(TokenType) | TokenType type) {
        if (exists token = advanceIf(type)) {
            return token;
        }
        throw error(peek(), "expected ``type``");
    }

    "Advance past the next token which must be of one of the given [[types]], or raise an
     error if the next token does not exist or does not match the given `types`."
    Token consumeAny(Boolean(TokenType) | TokenType+ types) {
        if (exists token = advanceIfAny(*types)) {
            return token;
        }
        throw error(peek(), "expected ``types``");
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
        GroupedType: "<" Type ">"
    """
    Type parseGroupedType() {
        consume(smallerOp);
        value result = parseType();
        consume(largerOp);
        return result;
    }

    """
        TypeArgument : Variance Type
        Variance     : ("out" | "in")?
    """
    [Variance?, Type] parseTypeArgument() {
        value variance = if (accept(inKeyword)) then contravariant
                         else if (accept(outKeyword)) then covariant
                         else null;

        return [variance, parseType()];
    }

    """
        TypeArguments : "<" ((TypeArgument ",")* TypeArgument)? ">"
    """
    [[Variance?, Type]*] parseTypeArguments() {
        consume(smallerOp);

        variable {[Variance?, Type]*} arguments = [];
        while (true) {
            arguments = arguments.follow(parseTypeArgument());
            if (!accept(comma)) {
                break;
            }
        }

        consume(largerOp);
        return arguments.sequence().reversed;
    }

    """
        TypeNameWithArguments : TypeName TypeArguments?
    """
    String parseTypeName() {
        assert (is UIdentifier token = consume(uIdentifier));
        return token.identifier;
    }

    """
        TypeNameWithArguments : TypeName TypeArguments?
    """
    Type parseTypeNameWithArguments(Package | Type | Null qualifier = null) {
        value name = parseTypeName();

        if (exists declaration = lookup(qualifier, name)) {

            value typeArguments
                =   if (check(smallerOp))
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

        value token = consumeAny(
                packageKeyword, dollarSign, memberOp, lIdentifier);

        switch (token)
        case (is PackageKeyword) {
            consume(memberOp);
            return scope.pkg;
        }
        case (is DollarSign) {
            // '$' is a shortcut for "ceylon.language"
            packageName.append("ceylon.language");
        }
        case (is MemberOp) {
            // '.' is a shortcut for the scope's package
            packageName.append(scope.pkg.qualifiedName);
            if (exists identifier = advanceIf(lIdentifier)) {
                assert (is LIdentifier identifier);
                packageName.append(".");
                packageName.append(identifier.identifier);
            }
        }
        else {
            assert (is LIdentifier token);
            packageName.append(token.identifier);
        }

        while (accept(memberOp)) {
            packageName.append(".");
            assert (is LIdentifier namePart = consume(lIdentifier));
            packageName.append(namePart.identifier);
        }

        consume(doubleColon);

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
        while (accept(memberOp)) {
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

        if (accept(specify)) {
            defaulted++;
        }

        while (accept(comma)) {
            types = types.follow(parseType());
            if (accept(specify)) {
                defaulted++;
            }
            else if (defaulted.positive && !check(productOp)) {
                throw Exception(
                    "Non-defaulted argument after defaulted argument");
            }
        }

        assert (is ProductOp | SumOp | Null variadic = advanceIfAny(productOp, sumOp));

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
        consume(lBracket);
        if (accept(rBracket)) {
            return scope.unit.emptyDeclaration.type;
        }
        value result = parseTypeList();
        consume(rBracket);
        return result;
    }

    """
        IterableType : "{" UnionType ("*"|"+") "}"
    """
    Type parseIterableType() {
        consume(lBrace);
        value type = parseUnionType();
        value absent
            =   switch(_ = consumeAny(productOp, sumOp))
                case (is ProductOp) scope.unit.nullDeclaration.type
                else scope.unit.nothingDeclaration.type;
        consume(rBrace);
        return scope.unit.iterableDeclaration.appliedType(
                null, [type, absent]);
    }

    """
        Substitution : "^"
    """
    Type parseSubstitution() {
        consume(caret);
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
        OptionalSuffix : "?" TypeSuffix
    """
    Type parseOptionalSuffix(Type primaryType) {
        consume(questionMark);
        return parseTypeSuffix(union(
            [primaryType, scope.unit.nullDeclaration.type],
            scope.unit
        ));
    }

    """
        SequenceSuffix : "[" DecimalLiteral? "]" TypeSuffix
    """
    Type parseSequenceSuffix(Type primaryType) {
        consume(lBracket);
        if (exists sizeToken = advanceIf(decimalLiteral)) {
            assert (is Integer size = Integer.parse(sizeToken.text));
            if (!size.positive) {
                throw Exception("Tuple size must be positive");
            }
            consume(rBracket);
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
            consume(rBracket);
            return parseTypeSuffix(scope.unit.getSequentialType(primaryType));
        }
    }

    """
        ParameterListSuffix : "(" (TypeList? | SpreadType) ")" TypeSuffix
        SpreadType          : "*" UnionType
    """
    Type parseParameterListSuffix(Type primaryType) {
        consume(lParen);

        Type arguments
            =   if (accept(productOp)) then
                    parseUnionType() // spread types
                else if (!peek() is RParen) then
                    parseTypeList()
                else
                    scope.unit.emptyDeclaration.type;

        consume(rParen);

        return scope.unit.callableDeclaration.appliedType {
            null;
            [primaryType, arguments];
        };
    }

    """
        TypeSuffix : ( OptionalSuffix
                    | SequenceSuffix
                    | TupleLengthSuffix
                    | ParameterListSuffix )?
    """
    Type parseTypeSuffix(Type primaryType)
        =>  switch (_ = peek())
            case (is QuestionMark) parseOptionalSuffix(primaryType)
            case (is LBracket) parseSequenceSuffix(primaryType)
            case (is LParen) parseParameterListSuffix(primaryType)
            else primaryType;

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
        while (accept(intersectionOp)) {
            types = types.follow(parsePrimaryType());
        }
        return intersection(types.sequence().reversed, scope.unit);
    }

    """
        UnionType : IntersectionType ("|" IntersectionType)*
    """
    Type parseUnionType() {
        // UnionType: IntersectionType ("|" IntersectionType)*
        variable {Type+} types = [parseIntersectionType()];
        while (accept(unionOp)) {
            types = types.follow(parseIntersectionType());
        }
        return union(types.sequence().reversed, scope.unit);
    }

    """
       Type      : UnionType | EntryType
    """
    Type parseType() {
        // parseType()
        //     Type      : UnionType | EntryType
        //     EntryType : UnionType "->" UnionType
        value type1 = parseUnionType();
        if (accept(entryOp)) {
            Type type2 = parseUnionType();
            return scope.unit.entryDeclaration.appliedType(null, [type1, type2]);
        }

        return type1;
    }

    shared actual Type get() {
        value result = parseType();
        if (exists token = peek()) {
            throw Exception("unexpected token: found ``token``");
        }
        return result;
    }
}.get();

interface Producer<T> {
    shared formal T get();
}
