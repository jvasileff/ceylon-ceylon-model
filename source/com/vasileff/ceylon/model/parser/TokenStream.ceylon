shared
class TokenStream({Character*} characters) satisfies {Token*} {

    shared actual
    Iterator<Token> iterator() => object satisfies Iterator<Token> {
        value t = Tokenizer(characters);

        shared actual
        Token|Finished next() {

            "Assuming at least one identifer character has already been accepted, accept
             remaining identifer characters and return an [[LIdentifier]] or
             [[UIdentifier]] token."
            function identifier() {
                t.acceptRun(isIdentifierPart);
                value text = t.newToken();
                value lowercase = text.first?.lowercase;
                "Caller guarantees token is non-empty"
                assert (exists lowercase);
                return if (lowercase)
                       then LIdentifier(text)
                       else UIdentifier(text);
            }

            switch (first = t.advance())
            case (null) {
                return finished;
            }
            case ('/') {
                // start of comment?
                switch (t.advance())
                case ('/') {
                    // line comment
                    t.acceptRun(not('\n'.equals));
                    return LineComment(t.newToken());
                }
                case ('*') {
                    // multi comment
                    variable value level = 1;
                    while (level != 0) {
                        value next = t.advance();
                        if (!exists next) {
                            return OpenMultiComment(t.newToken());
                        }
                        else if (next == '/', t.accept('*')) {
                            level++;
                        } else if (next == '*', t.accept('/')) {
                            level--;
                        }
                    }
                    return MultiComment(t.newToken());
                }
                else {
                    return UnknownCharacter(t.newToken());
                }
            }
            case ('#') {
                if (t.accept('!')) {
                    #! line comment
                    t.acceptRun(not('\n'.equals));
                    return LineComment(t.newToken());
                }
                else {
                    return UnknownCharacter(t.newToken());
                }
            }
            case ('\\') {
                switch (next = t.advance())
                case ('i') {
                    // forced lowercase identifier
                    t.acceptRun(isIdentifierPart);
                    return LIdentifier(t.newToken());
                }
                case ('I') {
                    // forced uppercase identifier
                    t.acceptRun(isIdentifierPart);
                    return UIdentifier(t.newToken());
                }
                else {
                    // unknown escape, consume only the backslash
                    return UnknownEscape(t.newToken());
                }
            }
            case ('0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9') {
                // numeric literal, we don’t know yet which kind
                t.acceptRun((c) => '0' <= c <= '9' || c == '_');
                t.accept("kMGTP");
                return DecimalLiteral(t.newToken());
            }
            case ('i') {
                if (t.accept('n') && !t.accept(isIdentifierPart)) {
                    t.ignore();
                    return InKeyword();
                }
                else {
                    return identifier();
                }
            }
            case ('o') {
                if (t.accept('u') && t.accept('t') && !t.accept(isIdentifierPart)) {
                    t.ignore();
                    return OutKeyword();
                }
                else {
                    return identifier();
                }
            }
            case (',') { t.ignore(); return Comma(); }
            case ('{') { t.ignore(); return LBrace(); }
            case ('}') { t.ignore(); return RBrace(); }
            case ('(') { t.ignore(); return LParen(); }
            case (')') { t.ignore(); return RParen(); }
            case ('[') { t.ignore(); return LBracket(); }
            case (']') { t.ignore(); return RBracket(); }
            case ('.') { t.ignore(); return MemberOp(); }
            case ('?') { t.ignore(); return QuestionMark(); }
            case ('*') { t.ignore(); return ProductOp(); }
            case ('=') { t.ignore(); return Specify(); }
            case ('+') { t.ignore(); return SumOp(); }
            case ('&') { t.ignore(); return IntersectionOp(); }
            case ('|') { t.ignore(); return UnionOp(); }
            case ('<') { t.ignore(); return SmallerOp(); }
            case ('>') { t.ignore(); return LargerOp(); }
            case ('^') { t.ignore(); return Caret(); }
            case ('$') { t.ignore(); return DollarSign(); }
            case ('-') {
                if (t.accept('>')) {
                    t.ignore();
                    return EntryOp();
                }
                else {
                    return UnknownCharacter(t.newToken());
                }
            }
            case (':') {
                if (t.accept(':')) {
                    t.ignore();
                    return DoubleColon();
                }
                else {
                    return UnknownCharacter(t.newToken());
                }
            }
            else {
                if (isIdentifierStart(first)) {
                    return identifier();
                }
                else {
                    if (first.whitespace) {
                        t.acceptRun(Character.whitespace);
                        return Whitespace(t.newToken());
                    } else {
                        return UnknownCharacter(t.newToken());
                    }
                }
            }
        }
    };

    Boolean isIdentifierStart(Character character)
        =>  character.letter || character == '_';

    Boolean isIdentifierPart(Character character)
        =>  character.letter || character.digit || character == '_';
}
