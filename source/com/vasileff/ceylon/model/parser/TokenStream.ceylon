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
                value lowercase = t.accumulatedText.first?.lowercase;
                "Caller guarantees token is non-empty"
                assert (exists lowercase);
                return if (lowercase)
                       then t.newToken(lIdentifier)
                       else t.newToken(uIdentifier);
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
                    return t.newToken(lineComment);
                }
                case ('*') {
                    // multi comment
                    variable value level = 1;
                    while (level != 0) {
                        value next = t.advance();
                        if (!exists next) {
                            return t.newToken(openMultiComment);
                        }
                        else if (next == '/', t.accept('*')) {
                            level++;
                        } else if (next == '*', t.accept('/')) {
                            level--;
                        }
                    }
                    return t.newToken(multiComment);
                }
                else {
                    return t.newToken(unknownCharacter);
                }
            }
            case ('#') {
                if (t.accept('!')) {
                    #! line comment
                    t.acceptRun(not('\n'.equals));
                    return t.newToken(lineComment);
                }
                else {
                    return t.newToken(unknownCharacter);
                }
            }
            case ('\\') {
                switch (next = t.advance())
                case ('i') {
                    // forced lowercase identifier
                    t.acceptRun(isIdentifierPart);
                    return t.newToken(lIdentifier);
                }
                case ('I') {
                    // forced uppercase identifier
                    t.acceptRun(isIdentifierPart);
                    return t.newToken(uIdentifier);
                }
                else {
                    // unknown escape, consume only the backslash
                    return t.newToken(unknownEscape);
                }
            }
            case ('0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9') {
                // numeric literal, we don’t know yet which kind
                t.acceptRun((c) => '0' <= c <= '9' || c == '_');
                t.accept("kMGTP");
                return t.newToken(decimalLiteral);
            }
            case ('i') {
                if (t.accept('n') && !t.accept(isIdentifierPart)) {
                    t.ignore();
                    return t.newToken(inKeyword);
                }
                else {
                    return identifier();
                }
            }
            case ('o') {
                if (t.accept('u') && t.accept('t') && !t.accept(isIdentifierPart)) {
                    t.ignore();
                    return t.newToken(outKeyword);
                }
                else {
                    return identifier();
                }
            }
            case (',') { return t.newToken(comma); }
            case ('{') { return t.newToken(lBrace); }
            case ('}') { return t.newToken(rBrace); }
            case ('(') { return t.newToken(lParen); }
            case (')') { return t.newToken(rParen); }
            case ('[') { return t.newToken(lBracket); }
            case (']') { return t.newToken(rBracket); }
            case ('.') { return t.newToken(memberOp); }
            case ('?') { return t.newToken(questionMark); }
            case ('*') { return t.newToken(productOp); }
            case ('=') { return t.newToken(specify); }
            case ('+') { return t.newToken(sumOp); }
            case ('&') { return t.newToken(intersectionOp); }
            case ('|') { return t.newToken(unionOp); }
            case ('<') { return t.newToken(smallerOp); }
            case ('>') { return t.newToken(largerOp); }
            case ('^') { return t.newToken(caret); }
            case ('$') { return t.newToken(dollarSign); }
            case ('-') {
                if (t.accept('>')) {
                    t.ignore();
                    return t.newToken(entryOp);
                }
                else {
                    return t.newToken(unknownCharacter);
                }
            }
            case (':') {
                if (t.accept(':')) {
                    t.ignore();
                    return t.newToken(doubleColon);
                }
                else {
                    return t.newToken(unknownCharacter);
                }
            }
            else {
                if (isIdentifierStart(first)) {
                    return identifier();
                }
                else {
                    if (first.whitespace) {
                        t.acceptRun(Character.whitespace);
                        return t.newToken(whitespace);
                    } else {
                        return t.newToken(unknownCharacter);
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
