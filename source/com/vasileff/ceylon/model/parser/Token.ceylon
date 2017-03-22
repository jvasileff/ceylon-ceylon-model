"A single token, that is, a fragment of code with a certain [[type]]."
shared abstract
class Token()
        of IgnoredToken | IdentifierToken | LiteralToken
            | KeywordToken | SymbolToken | ErrorToken {

    shared formal TokenType type;
    shared formal String text;
    //shared Integer? column;
    //shared Integer? line;

    shared actual default String string {
        Boolean verbatimQuoteText;
        if (this is IdentifierToken) {
            verbatimQuoteText = text.startsWith("\\");
        } else { // TODO literal tokens
            verbatimQuoteText = false;
        }
        value quotes = verbatimQuoteText
                then "\"\"\""
                else "\"";
        return "``type``(``quotes````text````quotes``)";
    }
}

shared abstract class TokenType(shared String name) {}
shared object whitespace extends TokenType("Whitespace") {}
shared object lineComment extends TokenType("LineComment") {}
shared object multiComment extends TokenType("MultiComment") {}
shared object lIdentifier extends TokenType("LIdentifier") {}
shared object uIdentifier extends TokenType("UIdentifier") {}
shared object decimalLiteral extends TokenType("DecimalLiteral") {}
shared object packageKeyword extends TokenType("PackageKeyword") {}
shared object inKeyword extends TokenType("InKeyword") {}
shared object outKeyword extends TokenType("OutKeyword") {}
shared object doubleColon extends TokenType("DoubleColon") {}
shared object comma extends TokenType("Comma") {}
shared object lBrace extends TokenType("LBrace") {}
shared object rBrace extends TokenType("RBrace") {}
shared object lParen extends TokenType("LParen") {}
shared object rParen extends TokenType("RParen") {}
shared object lBracket extends TokenType("LBracket") {}
shared object rBracket extends TokenType("RBracket") {}
shared object questionMark extends TokenType("QuestionMark") {}
shared object memberOp extends TokenType("MemberOp") {}
shared object specify extends TokenType("Specify") {}
shared object sumOp extends TokenType("SumOp") {}
shared object productOp extends TokenType("ProductOp") {}
shared object entryOp extends TokenType("EntryOp") {}
shared object intersectionOp extends TokenType("IntersectionOp") {}
shared object unionOp extends TokenType("UnionOp") {}
shared object smallerOp extends TokenType("SmallerOp") {}
shared object largerOp extends TokenType("LargerOp") {}
shared object dollarSign extends TokenType("DollarSign") {}
shared object caret extends TokenType("Caret") {}
shared object unknownCharacter extends TokenType("UnknownCharacter") {}
shared object unknownEscape extends TokenType("UnknownEscape") {}
shared object openMultiComment extends TokenType("OpenMultiComment") {}

"An ignored token that’s not visible to the parser."
shared abstract class IgnoredToken()
        of Whitespace | LineComment | MultiComment
        extends Token() {}

"Whitespace."
shared class Whitespace(text) extends IgnoredToken() {
    shared actual String text;
    shared actual TokenType type => whitespace;
}

"A single-line comment, for example:

     // comment
     #!/usr/bin/ceylon"
shared class LineComment(text) extends IgnoredToken() {
    shared actual String text;
    shared actual TokenType type => lineComment;
}

"A multi-line comment, for example:

     /*
      * comment
      */

     /* doesn’t actually have to be multi-line */

     /* can /* be */ nested */"
shared class MultiComment(text) extends IgnoredToken() {
    shared actual String text;
    shared actual TokenType type => multiComment;
}

"""An identifier (with optional prefix), for example:

       Anything
       \iSOUTH"""
shared abstract class IdentifierToken()
        of LIdentifier | UIdentifier
        extends Token() {

    "The identifier, without a leading '\\I' or '\\i'."
    shared String identifier
        =>  if (text.startsWith("\\"))
            then text[2...]
            else text;
}

"""An initial lowercase identifier (with optional prefix), for example:

       null
       \iSOUTH"""
shared class LIdentifier(text) extends IdentifierToken() {
    shared actual String text;
    shared actual TokenType type => lIdentifier;
}

"""An initial uppercase identifier (with optional prefix), for example:

       Object
       \Iklass"""
shared class UIdentifier(text) extends IdentifierToken() {
    shared actual String text;
    shared actual TokenType type => uIdentifier;
}

"A literal value token."
shared abstract class LiteralToken()
        of NumericLiteralToken
        extends Token() {}

"A numeric literal."
shared abstract class NumericLiteralToken()
        of IntegerLiteralToken
        extends LiteralToken() {}

"An integer literal."
shared abstract class IntegerLiteralToken()
        of DecimalLiteral
        extends NumericLiteralToken() {}

"A decimal integer literal, with an optional magnitude, for example:

     10_000
     10k"
shared class DecimalLiteral(text) extends IntegerLiteralToken() {
    shared actual String text;
    shared actual TokenType type => decimalLiteral;
}

"A keyword."
shared abstract class KeywordToken()
        of InKeyword | OutKeyword | PackageKeyword
        extends Token() {}

"The ‘`package`’ keyword."
shared class PackageKeyword() extends KeywordToken() {
    shared actual String text => "package";
    shared actual TokenType type => packageKeyword;
}

"The ‘`in`’ keyword."
shared class InKeyword() extends KeywordToken() {
    shared actual String text => "in";
    shared actual TokenType type => inKeyword;
}

"The ‘`out`’ keyword."
shared class OutKeyword() extends KeywordToken() {
    shared actual String text => "out";
    shared actual TokenType type => outKeyword;
}

"A symbol, that is, an operator or punctuation."
shared abstract
class SymbolToken()
        of Comma | LBrace | RBrace | LParen | RParen | LBracket | RBracket | QuestionMark
            | MemberOp | Specify | SumOp | ProductOp | EntryOp | IntersectionOp | UnionOp
            | SmallerOp | LargerOp | DoubleColon | Caret | DollarSign
        extends Token() {}

"Two colons: ‘`::`’"
shared class DoubleColon() extends SymbolToken() {
    shared actual String text => "::";
    shared actual TokenType type => doubleColon;
}

"A comma: ‘`,`’"
shared class Comma() extends SymbolToken() {
    shared actual String text => ",";
    shared actual TokenType type => comma;
}

"A left brace: ‘`{`’"
shared class LBrace() extends SymbolToken() {
    shared actual String text => "{";
    shared actual TokenType type => lBrace;
}

"A right brace: ‘`}`’"
shared class RBrace() extends SymbolToken() {
    shared actual String text => "}";
    shared actual TokenType type => rBrace;
}

"A left parenthesis: ‘`(`’"
shared class LParen() extends SymbolToken() {
    shared actual String text => "(";
    shared actual TokenType type => lParen;
}

"A right parenthesis: ‘`)`’"
shared class RParen() extends SymbolToken() {
    shared actual String text => ")";
    shared actual TokenType type => rParen;
}

"A left bracket: ‘`[`’"
shared class LBracket() extends SymbolToken() {
    shared actual String text => "[";
    shared actual TokenType type => lBracket;
}

"A right bracket: ‘`]`’"
shared class RBracket() extends SymbolToken() {
    shared actual String text => "]";
    shared actual TokenType type => rBracket;
}

"A question mark: ‘`?`’"
shared class QuestionMark() extends SymbolToken() {
    shared actual String text => "?";
    shared actual TokenType type => questionMark;
}

"A member operator: ‘`.`’"
shared class MemberOp() extends SymbolToken() {
    shared actual String text => ".";
    shared actual TokenType type => memberOp;
}

"An eager specification operator: ‘`=`’"
shared class Specify() extends SymbolToken() {
    shared actual String text => "=";
    shared actual TokenType type => specify;
}

"A sum operator: ‘`+`’"
shared class SumOp() extends SymbolToken() {
    shared actual String text => "+";
    shared actual TokenType type => sumOp;
}

"A product or spread operator: ‘`*`’"
shared class ProductOp() extends SymbolToken() {
    shared actual String text => "*";
    shared actual TokenType type => productOp;
}

"An entry operator: ‘`->`’"
shared class EntryOp() extends SymbolToken() {
    shared actual String text => "->";
    shared actual TokenType type => entryOp;
}

"An intersection operator: ‘`&`’"
shared class IntersectionOp() extends SymbolToken() {
    shared actual String text => "&";
    shared actual TokenType type => intersectionOp;
}

"A union operator: ‘`|`’"
shared class UnionOp() extends SymbolToken() {
    shared actual String text => "|";
    shared actual TokenType type => unionOp;
}

"A smaller-as operator: ‘`<`’"
shared class SmallerOp() extends SymbolToken() {
    shared actual String text => "<";
    shared actual TokenType type => smallerOp;
}

"A larger-as operator: ‘`>`’"
shared class LargerOp() extends SymbolToken() {
    shared actual String text => ">";
    shared actual TokenType type => largerOp;
}

"A dollar sign, which serves as a shortcut for the language module: ‘`$`’"
shared class DollarSign() extends SymbolToken() {
    shared actual String text => "$";
    shared actual TokenType type => dollarSign;
}

"A caret, which serves as a placeholder for a type: ‘`^`’"
shared class Caret() extends SymbolToken() {
    shared actual String text => "^";
    shared actual TokenType type => caret;
}

"An erroneous token."
shared abstract class ErrorToken()
        of UnknownToken | OpenToken
        extends Token() {}

"A token where the lexer does not understand a character,
 but is able to proceed past it."
shared abstract class UnknownToken()
        of UnknownCharacter | UnknownEscape
        extends ErrorToken() {}

"A character that cannot begin any token."
shared class UnknownCharacter(text) extends UnknownToken()  {
    shared actual String text;
    shared actual TokenType type => unknownCharacter;
}

"A character other than lower-or uppercase I after a backslash."
shared class UnknownEscape(text) extends UnknownToken()  {
    shared actual String text;
    shared actual TokenType type => unknownEscape;
}

"A token that was not terminated. The token stream ends after this token."
shared abstract class OpenToken()
        of OpenMultiComment
        extends ErrorToken() {}

"An unterminated [[MultiComment]]."
shared class OpenMultiComment(text) extends OpenToken() {
    shared actual String text;
    shared actual TokenType type => openMultiComment;
}
