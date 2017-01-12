import com.vasileff.ceylon.model.parser {
    parseType
}

shared void printSomeTypes() {
    value languageModule = loadLanguageModule();
    value scope = languageModule.ceylonLanguagePackage;

    print(parseType("{String?[]*}", scope));
    print(parseType("{String?[]+}", scope));
    print(parseType("String -> Basic", scope));
    print(parseType("String -> Nothing", scope));
    print(parseType("ceylon.language::String", scope));
    print(parseType("ceylon.language::Entry<ceylon.language::String,ceylon.language::String>", scope));
    print(parseType("Entry<String, String>", scope));
    print(parseType("Entry<String, Entry<String, String>>", scope));
    value t1 = parseType("Entry<String, String>", scope);
    value t2 = parseType("Entry<String, Anything>", scope);
    print(t1.isSubtypeOf(t2));
    print(t2.isSubtypeOf(t1));

    print(parseType("Entry", scope));

    print(parseType("[String, Basic, Object -> Anything]", scope));
    print(parseType("[String, Basic=, Object -> Anything*]", scope));

    print(parseType("String(String, Basic, Object -> Anything)", scope));
    print(parseType("String(*[String])", scope));
    print(parseType("String(*[])", scope));
}
