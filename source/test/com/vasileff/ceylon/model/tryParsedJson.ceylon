shared
void tryParsedJson() {

    assert (exists unit
        =   modCeylonLanguage.findDirectPackage("ceylon.language")?.defaultUnit);

    value ceylonLanguagePackage
        =   unit.ceylonLanguagePackage;

    // print(ceylonLanguagePackage.members);
    print(ceylonLanguagePackage.getDirectMember("identity"));
    print(ceylonLanguagePackage.getDirectMember("sum"));
    print(ceylonLanguagePackage.getDirectMember("map"));
    for (name->member in ceylonLanguagePackage
            .getDirectMember("Iterable")?.members else []) {
        print(member);
    }
}