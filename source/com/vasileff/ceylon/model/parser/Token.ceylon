"A single token, that is, a fragment of code with a certain [[type]]."
shared final
class Token(type, text) {
    shared TokenType type;
    shared String text;
    //shared Integer? column;
    //shared Integer? line;

    shared actual String string {
        Boolean verbatimQuoteText;
        if (type == lIdentifier || type == uIdentifier) {
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

"Whitespace."
shared object whitespace extends TokenType("Whitespace") {}

"A single-line comment, for example:

     // comment
     #!/usr/bin/ceylon"
shared object lineComment extends TokenType("LineComment") {}

"A multi-line comment, for example:

     /*
      * comment
      */

     /* doesn’t actually have to be multi-line */

     /* can /* be */ nested */"
shared object multiComment extends TokenType("MultiComment") {}

"""An initial lowercase identifier (with optional prefix), for example:

       null
       \iSOUTH"""
shared object lIdentifier extends TokenType("LIdentifier") {}

"""An initial uppercase identifier (with optional prefix), for example:

       Object
       \Iklass"""
shared object uIdentifier extends TokenType("UIdentifier") {}

"A decimal integer literal, with an optional magnitude, for example:

     10_000
     10k"
shared object decimalLiteral extends TokenType("DecimalLiteral") {}

"The ‘`package`’ keyword."
shared object packageKeyword extends TokenType("PackageKeyword") {}

"The ‘`in`’ keyword."
shared object inKeyword extends TokenType("InKeyword") {}

"The ‘`out`’ keyword."
shared object outKeyword extends TokenType("OutKeyword") {}

"Two colons: ‘`::`’"
shared object doubleColon extends TokenType("DoubleColon") {}

"A comma: ‘`,`’"
shared object comma extends TokenType("Comma") {}

"A left brace: ‘`{`’"
shared object lBrace extends TokenType("LBrace") {}

"A right brace: ‘`}`’"
shared object rBrace extends TokenType("RBrace") {}

"A left parenthesis: ‘`(`’"
shared object lParen extends TokenType("LParen") {}

"A right parenthesis: ‘`)`’"
shared object rParen extends TokenType("RParen") {}

"A left bracket: ‘`[`’"
shared object lBracket extends TokenType("LBracket") {}

"A right bracket: ‘`]`’"
shared object rBracket extends TokenType("RBracket") {}

"A question mark: ‘`?`’"
shared object questionMark extends TokenType("QuestionMark") {}

"A member operator: ‘`.`’"
shared object memberOp extends TokenType("MemberOp") {}

"An eager specification operator: ‘`=`’"
shared object specify extends TokenType("Specify") {}

"A sum operator: ‘`+`’"
shared object sumOp extends TokenType("SumOp") {}

"A product or spread operator: ‘`*`’"
shared object productOp extends TokenType("ProductOp") {}

"An entry operator: ‘`->`’"
shared object entryOp extends TokenType("EntryOp") {}

"An intersection operator: ‘`&`’"
shared object intersectionOp extends TokenType("IntersectionOp") {}

"A union operator: ‘`|`’"
shared object unionOp extends TokenType("UnionOp") {}

"A smaller-as operator: ‘`<`’"
shared object smallerOp extends TokenType("SmallerOp") {}

"A larger-as operator: ‘`>`’"
shared object largerOp extends TokenType("LargerOp") {}

"A dollar sign, which serves as a shortcut for the language module: ‘`$`’"
shared object dollarSign extends TokenType("DollarSign") {}

"A caret, which serves as a placeholder for a type: ‘`^`’"
shared object caret extends TokenType("Caret") {}

"A character that cannot begin any token."
shared object unknownCharacter extends TokenType("UnknownCharacter") {}

"A character other than lower-or uppercase I after a backslash."
shared object unknownEscape extends TokenType("UnknownEscape") {}

"An unterminated [[multiComment]]."
shared object openMultiComment extends TokenType("OpenMultiComment") {}

"The identifier, without a leading '\\I' or '\\i'."
shared String cleanIdentifier(String text)
    =>  if (text.startsWith("\\"))
        then text[2...]
        else text;
