import com.vasileff.ceylon.model {
    Scope
}

shared void run() => runAllTests();

void runTests({Anything()*} tests) {
    for (test in tests) {
        try {
            test();
        }
        catch (Exception | AssertionError e) {
            process.writeErrorLine("Test failed: ``e.message``");
        }
    }
}

shared
void printLanguageModuleMembers() {
    void printMembers(Scope declaration, Integer indent = 0) {
        print(" ".repeat(indent) + declaration.string);
        for (member in declaration.members.items) {
            printMembers(member, indent + 2);
        }
    }
    value lm = loadLanguageModule();
    lm.packages.each(printMembers);
}

shared
void runAllTests() {
    runTests {
        subtypesObjectNullAnything,
        subtypesSimpleEntries,
        substitutionsSimple,
        memberGenericTypesJson,
        stringParameterType,
        typePrinterTests
    };
    print("Tests complete.");
}
