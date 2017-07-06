shared class Tokenizer({Character*} input,
        Integer offsetPosition = 0,
        Integer offsetLine = 1,
        Integer offsetColumn = 1) {

    value builder = StringBuilder();
    value iterator = PeekingIterator(input.iterator());

    variable Integer position = offsetPosition;
    variable Integer line = offsetLine;
    variable Integer column = offsetColumn;

    shared variable Integer startPosition = position;
    shared variable Integer startLine = line;
    shared variable Integer startColumn = column;

    shared Character? advance() {
        if (!is Finished c = iterator.next()) {
            position += 1;
            if (c == '\n') {
                line += 1;
                column = 1;
            }
            else if (c != '\r') {
                column += 1;
            }
            builder.appendCharacter(c);
            return c;
        }
        return null;
    }

    shared void ignore() {
        builder.clear();
        startPosition = position;
        startLine = line;
        startColumn = column;
    }

    shared Character? peek()
        =>  if (!is Finished p = iterator.peek()) then p else null;

    Boolean check(Character c, String | Character | Boolean(Character) valid)
        =>  switch (valid)
            case (is String) c in valid
            case (is Character) c == valid
            else valid(c);

    shared Boolean accept(String | Character | Boolean(Character) valid) {
        if (exists c = peek(), check(c, valid)) {
            advance();
            return true;
        }
        return false;
    }

    shared Integer acceptRun(String | Character | Boolean(Character) valid) {
        variable value count = 0;
        while (accept(valid)) {
            count++;
        }
        return count;
    }

    shared String read(
            String | Character | Boolean(Character) valid,
            Integer maxLength = runtime.maxIntegerValue) {
        value sb = StringBuilder();
        variable value count = 0;
        while (count++ < maxLength, exists c = peek(), check(c, valid)) {
            sb.appendCharacter(c);
            advance();
        }
        return sb.string;
    }

    String text()
        =>  builder.string;

    shared String newToken() {
        value result = text();
        ignore();
        return result;
    }
}
