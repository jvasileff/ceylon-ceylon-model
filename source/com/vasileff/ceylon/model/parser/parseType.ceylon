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
            .filter((token) => !token.type in [whitespace, lineComment, multiComment])
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
    Token? peekIf(TokenType | {TokenType*} | Boolean(TokenType) type) {
        value token = peek();
        if (!exists token) {
            return null;
        }
        if (is TokenType type) {
            if (type == token.type) {
                return token;
            }
        }
        else if (is {Anything*} type) {
            if (token.type in type) {
                return token;
            }
        }
        else if (type(token.type)) {
            return token;
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
    Token? advanceIf(TokenType | {TokenType*} | Boolean(TokenType) type) {
        value token = peekIf(type);
        if (token exists) {
            advance();
        }
        return token;
    }

    "Advance to the next token and return `true` if one exists and it matches [[type]];
     otherwise return `false`."
    Boolean accept(TokenType | {TokenType*} | Boolean(TokenType) type)
        =>  advanceIf(type) exists;

    "Return true if the next token exists and matches [[type]]; do not advance."
    Boolean check(TokenType | {TokenType*} | Boolean(TokenType) type)
        =>  peekIf(type) exists;

    "Advance past the next token which must be of the given [[type]], or raise an error
     if the next token does not exist or does not match the given `type`."
    Token consume(TokenType | {TokenType*} | Boolean(TokenType) type) {
        if (exists token = advanceIf(type)) {
            return token;
        }
        throw error(peek(), "expected ``type``");
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
    String parseTypeName()
        =>  cleanIdentifier(consume(uIdentifier).text);

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
        value token = consume([packageKeyword, dollarSign, memberOp, lIdentifier]);

        switch (token.type)
        case (packageKeyword) {
            consume(memberOp);
            return scope.pkg;
        }
        case (dollarSign) {
            // '$' is a shortcut for "ceylon.language"
            packageName.append("ceylon.language");
        }
        case (memberOp) {
            // '.' is a shortcut for the scope's package
            packageName.append(scope.pkg.qualifiedName);
            if (exists identifier = advanceIf(lIdentifier)) {
                packageName.append(".");
                packageName.append(cleanIdentifier(identifier.text));
            }
        }
        case (lIdentifier) {
            packageName.append(cleanIdentifier(token.text));
        }
        else {
            throw AssertionError("unexpected type in supposedly exhaustive switch");
        }

        while (accept(memberOp)) {
            packageName.append(".");
            value namePart = consume(lIdentifier);
            packageName.append(cleanIdentifier(namePart.text));
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
        return switch (peek()?.type)
        case (largerOp)
            parseGroupedType()
        case (packageKeyword | dollarSign | memberOp | lIdentifier)
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

        value variadic = advanceIf([productOp, sumOp]);

        variable Type result;
        variable Type element;

        // calculate rest
        value declaration
            =   switch (variadic?.type)
                case (productOp) scope.unit.sequentialDeclaration
                case (sumOp) scope.unit.sequenceDeclaration
                else null;

        if (!exists declaration) {
            result = scope.unit.emptyDeclaration.type;
            element = scope.unit.nothingDeclaration.type;            
        }
        else {
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
        value absent = switch(consume([productOp, sumOp]).type)
                       case (productOp) scope.unit.nullDeclaration.type
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
        =>  switch (peek()?.type)
            case (lBracket) parseTupleType()
            case (lBrace) parseIterableType()
            case (caret) parseSubstitution()
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

        value arguments
            =   if (accept(productOp)) then
                    parseUnionType() // spread types
                else if (!check(rParen)) then
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
        =>  switch (peek()?.type)
            case (questionMark) parseOptionalSuffix(primaryType)
            case (lBracket) parseSequenceSuffix(primaryType)
            case (lParen) parseParameterListSuffix(primaryType)
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
