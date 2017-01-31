import com.vasileff.ceylon.model {
    Module,
    ModuleImport
}
import ceylon.json {
    Object,
    parse
}
import com.vasileff.ceylon.model.json {
    JsonObject,
    LazyJsonModule
}
import com.vasileff.ceylon.model.runtime {
    LazyTypeDescriptor
}

shared
void tryLazyTypeDescriptors() {

    assert (exists unit
        =   modCeylonInteropDart.findDirectPackage("ceylon.interop.dart")?.defaultUnit);

    value td1
        =   LazyTypeDescriptor {
                modCeylonInteropDart;
                "ceylon.language::Entry<ceylon.language::String,ceylon.language::String>";
                [];
            };

    print("---------------");
    print(td1);
    print(td1.type);
    print(td1.type);

    value td2
        =   LazyTypeDescriptor {
                modCeylonInteropDart;
                "ceylon.language::Entry<ceylon.language::String,ceylon.language::String>";
                [];
            };

    print("---------------");
    print(td2);
    print(td2.type);
    print(td2.type);

    value td3
        =   LazyTypeDescriptor {
                modCeylonInteropDart;
                "ceylon.language::Entry<ceylon.language::String,ceylon.language::Float>";
                [];
            };

    print("---------------");
    print(td3);
    print(td3.type);
    print(td3.type);

    value tdString
        =   LazyTypeDescriptor {
                modCeylonInteropDart;
                "ceylon.language::String";
                [];
            };

    value tdFloat
        =   LazyTypeDescriptor {
                modCeylonInteropDart;
                "ceylon.language::Float";
                [];
            };

    value tdEntryWithSubstitutions1
        =   LazyTypeDescriptor {
                modCeylonInteropDart;
                "ceylon.language::Entry<^,^>";
                [tdString, tdFloat];
            };

    print("---------------");
    print(tdEntryWithSubstitutions1);
    print(tdEntryWithSubstitutions1.type);
    print(tdEntryWithSubstitutions1.type);

    value tdString2
        =   LazyTypeDescriptor {
                modCeylonInteropDart;
                "ceylon.language::String";
                [];
            };

    value tdFloat2
        =   LazyTypeDescriptor {
                modCeylonInteropDart;
                "ceylon.language::Float";
                [];
            };

    value tdEntryWithSubstitutions2
        =   LazyTypeDescriptor {
                modCeylonInteropDart;
                "^->^";
                [tdString2, tdFloat2];
            };

    print("---------------");
    print(tdEntryWithSubstitutions2);
    print(tdEntryWithSubstitutions2.type);
    print(tdEntryWithSubstitutions2.type);

    value myModule = modCeylonInteropDart;

    value argT = LazyTypeDescriptor(myModule, "ceylon.language::Float?");
    value argU = LazyTypeDescriptor(myModule, "ceylon.language::Boolean");

    print("---------------");
    print {
        LazyTypeDescriptor {
            myModule;
            "<ceylon.language::String -> ^> | ^";
            [argT, argU];
        }.type; // <Entry<String, Float|Null>>|Boolean (type)
    };
}

JsonObject loadJson(String name) {
   assert (exists jsonString
        =   `module`.resourceByPath(name)?.textContent());

    assert (is Object jsonObject
        =   parse(jsonString));

    return jsonObject;
}

JsonObject _modCeylonLanguageJson
    =>  loadJson("ceylon.language-1.3.1-DP5-SNAPSHOT-dartmodel.json");

JsonObject _modCeylonInteropDartJson
    =>  loadJson("ceylon.interop.dart-1.3.1-SNAPSHOT-dartmodel.json");

variable Module? _modCeylonLanguage = null;
variable Module? _modCeylonInteropDart = null;

Module modCeylonLanguage {
    if (exists m = _modCeylonLanguage) {
        // m may be partially initialized if there is a circular dependency
        return m;
    }
    value m = _modCeylonLanguage = LazyJsonModule(_modCeylonLanguageJson);
    m.moduleImports.add {
        ModuleImport {
            mod = modCeylonInteropDart;
            isShared = false;
        };
    };
    return m;
}

Module modCeylonInteropDart {
    if (exists m = _modCeylonInteropDart) {
        // m may be partially initialized if there is a circular dependency
        return m;
    }
    value m = _modCeylonInteropDart = LazyJsonModule(_modCeylonInteropDartJson);
    m.moduleImports.add {
        ModuleImport {
            mod = modCeylonLanguage;
            isShared = false;
        };
    };
    return m;
}
