import ceylon.test {
    test,
    assertEquals
}
import com.vasileff.ceylon.model.parser {
    parseType
}

shared test
void typePrinterTests() {
    //value languageModule = modCeylonLanguage;
    value languageModule = loadLanguageModule();
    value scope = languageModule.ceylonLanguagePackage;

    function pf(String s) => parseType(s, scope).format();

    assertEquals(pf("{String?[]*}"), "{String?[]*}");
    assertEquals(pf("{String?[]+}"), "{String?[]+}");
    assertEquals(pf("String -> Basic"), "String->Basic");
    assertEquals(pf("String -> Nothing"), "String->Nothing");
    assertEquals(pf("ceylon.language::String"), "String");
    assertEquals(pf("ceylon.language::Entry<ceylon.language::String,ceylon.language::String>"), "String->String");
    assertEquals(pf("Entry<String, String>"), "String->String");
    assertEquals(pf("Entry<String, Entry<String, String>>"), "Entry<String, String->String>");
    assertEquals(pf("Entry"), "unknown->unknown");

    assertEquals(pf("[String, String]"), "String[2]");
    assertEquals(pf("[String, Basic, Object]"), "[String, Basic, Object]");
    assertEquals(pf("[String, Basic, Object -> Anything]"), "[String, Basic, Object->Anything]");
    assertEquals(pf("[String, String=, String=]"), "[String, String=, String=]");

    assertEquals(pf("[String, Basic=, Object -> Anything*]"), "[String, Basic=, <Object->Anything>*]");
    assertEquals(pf("[String, Basic=, Object*]"), "[String, Basic=, Object*]");

    // don't abbreviate the next two:
    assertEquals(pf("Tuple<String, String, Tuple<String, String, [String]>|[]>"), "Tuple<String, String, String[2]|[]>");
    assertEquals(pf("Tuple<String, String, Tuple<String, String, Anything>>"), "Tuple<String, String, Tuple<String, String, Anything>>");

    assertEquals(pf("String(String, Basic, Object -> Anything)"), "String(String, Basic, Object->Anything)");
    assertEquals(pf("String(*[String])"), "String(String)");
    assertEquals(pf("String(*[])"), "String()");
    assertEquals(pf("String(String=)"), "String(String=)");
    assertEquals(pf("String(String*)"), "String(String*)");
    assertEquals(pf("String(String+)"), "String(String+)");
}
