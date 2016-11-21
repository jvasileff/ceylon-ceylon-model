import ceylon.test {
    assertTrue,
    test,
    assertFalse,
    assertEquals
}

import com.vasileff.ceylon.model {
    ParameterList,
    TypeParameter,
    covariant,
    Module,
    Package,
    ClassDefinition,
    NothingDeclaration,
    InterfaceDefinition,
    Type,
    ModuleImport,
    Value,
    Parameter,
    Function,
    TypedReference,
    contravariant
}
import com.vasileff.ceylon.model.json {
    jsonModelUtil,
    keyName,
    keyPackage,
    keyTypeParams,
    keyModule,
    keyMetatype,
    keyTypeArgs,
    metatypeTypeParameter,
    metatypeInterface,
    typeFromJson
}
import com.vasileff.ceylon.model.parser {
    parseTypeLG
}

shared
Module loadLanguageModule() {

    value ceylonLanguageModule
        =   Module(["ceylon", "language"], "0.0.0");

    value ceylonLanguagePackage
        =   Package(["ceylon", "language"], ceylonLanguageModule);

    ceylonLanguageModule.packages.add(ceylonLanguagePackage);

    // ceylon.language::Nothing
    ceylonLanguagePackage.defaultUnit.addDeclaration {
        NothingDeclaration(ceylonLanguagePackage.defaultUnit);
    };

    // ceylon.language::Anything
    ceylonLanguagePackage.defaultUnit.addDeclaration {
        ClassDefinition {
            container = ceylonLanguagePackage;
            unit = ceylonLanguagePackage.defaultUnit;
            name = "Anything";
            extendedTypeLG = null;
            caseTypesLG = [
                parseTypeLG("Object"),
                parseTypeLG("Null")
            ];
        };
    };

    // ceylon.language::Object
    ceylonLanguagePackage.defaultUnit.addDeclaration {
        ClassDefinition {
            container = ceylonLanguagePackage;
            name = "Object";
            extendedTypeLG = parseTypeLG("Anything");
            isAbstract = true;
        };
    };

    // ceylon.language::Identifiable
    ceylonLanguagePackage.defaultUnit.addDeclaration {
        InterfaceDefinition {
            container = ceylonLanguagePackage;
            name = "Identifiable";
        };
    };

    // ceylon.language::Basic satisfies Identifiable
    ceylonLanguagePackage.defaultUnit.addDeclaration {
        ClassDefinition {
            container = ceylonLanguagePackage;
            name = "Basic";
            extendedTypeLG = parseTypeLG("Object");
            satisfiedTypesLG = [parseTypeLG("Identifiable")];
            isAbstract = true;
        };
    };

    // ceylon.language::Null
    ceylonLanguagePackage.defaultUnit.addDeclaration {
        ClassDefinition {
            container = ceylonLanguagePackage;
            name = "Null";
            extendedTypeLG = parseTypeLG("Anything");
        };
    };

    // ceylon.language::Character
    ceylonLanguagePackage.defaultUnit.addDeclaration {
        ClassDefinition {
            container = ceylonLanguagePackage;
            name = "Character";
            extendedTypeLG = parseTypeLG("Object");
        };
    };

    // ceylon.language::String(List<Character>)
    value stringDefinition = ClassDefinition {
        container = ceylonLanguagePackage;
        name = "String";
        extendedTypeLG = parseTypeLG("Object");
    };

    ceylonLanguagePackage.defaultUnit.addDeclaration(stringDefinition);

    value stringArg = Value {
        container = stringDefinition;
        name = "characters";
        typeLG = parseTypeLG("{Character*}");
    };

    stringDefinition.addMembers { stringArg };

    stringDefinition.parameterList
        =   ParameterList([Parameter(stringArg)]);

    // ceylon.language::Entry
    value entryDeclaration
        =   ClassDefinition {
                container = ceylonLanguagePackage;
                name = "Entry";
                extendedTypeLG = parseTypeLG("Object");
                //parameterLists = [ParameterList.empty]; // TODO key, item
            };

    ceylonLanguagePackage.defaultUnit.addDeclaration(entryDeclaration);

    entryDeclaration.addMembers {
        TypeParameter {
            container = entryDeclaration;
            name = "Key";
            satisfiedTypesLG = [parseTypeLG("Object")];
            variance = covariant;
            selfTypeDeclaration = null;
        },
        TypeParameter {
            container = entryDeclaration;
            name = "Item";
            variance = covariant;
            selfTypeDeclaration = null;
        }
    };

    // ceylon.language::Iterable
    value iterableDeclaration
        =   InterfaceDefinition {
                container = ceylonLanguagePackage;
                name = "Iterable";
                // TODO satisfies Category
            };

    ceylonLanguagePackage.defaultUnit.addDeclaration(iterableDeclaration);

    iterableDeclaration.addMembers {
       TypeParameter {
            container = iterableDeclaration;
            name = "Element";
            variance = covariant;
            selfTypeDeclaration = null;
            defaultTypeArgumentLG = parseTypeLG("Anything");
        },
        TypeParameter {
            container = iterableDeclaration;
            name = "Absent";
            variance = covariant;
            selfTypeDeclaration = null;
            satisfiedTypesLG = [parseTypeLG("Null")];
            defaultTypeArgumentLG = parseTypeLG("Null");
        }
    };

    // ceylon.language::Sequential
    value sequentialDeclaration
        =   InterfaceDefinition {
                container = ceylonLanguagePackage;
                name = "Sequential";
                satisfiedTypesLG = [
                    parseTypeLG("{Element*}")
                ];
                // TODO satisfies List & Ranged, not iterable
                // TODO cases Empty & Sequence
            };

    ceylonLanguagePackage.defaultUnit.addDeclaration(sequentialDeclaration);

    sequentialDeclaration.addMembers {
       TypeParameter {
            container = sequentialDeclaration;
            name = "Element";
            variance = covariant;
            selfTypeDeclaration = null;
        }
    };

    // ceylon.language::Sequence
    value sequenceDeclaration
        =   InterfaceDefinition {
                container = ceylonLanguagePackage;
                name = "Sequence";
                // TODO case types
                satisfiedTypesLG = [
                    parseTypeLG("[Element*]"),
                    parseTypeLG("{Element+}")
                ];
            };

    ceylonLanguagePackage.defaultUnit.addDeclaration(sequenceDeclaration);

    sequenceDeclaration.addMembers {
       TypeParameter {
            container = sequenceDeclaration;
            name = "Element";
            variance = covariant;
            selfTypeDeclaration = null;
        }
    };

    // ceylon.language::Empty
    value emptyDeclaration
        =   InterfaceDefinition {
                container = ceylonLanguagePackage;
                name = "Empty";
                // TODO case types
                satisfiedTypesLG = [parseTypeLG("[Nothing*]")];
            };

    ceylonLanguagePackage.defaultUnit.addDeclaration(emptyDeclaration);

    // ceylon.language::Tuple
    value tupleDeclaration
        =   ClassDefinition {
                container = ceylonLanguagePackage;
                name = "Tuple";
                extendedTypeLG = parseTypeLG("Object");
                satisfiedTypesLG = [parseTypeLG("[Element+]")];
            };

    ceylonLanguagePackage.defaultUnit.addDeclaration(tupleDeclaration);

    tupleDeclaration.addMembers {
        TypeParameter {
            container = tupleDeclaration;
            name = "Element";
            variance = covariant;
            selfTypeDeclaration = null;
        },
        TypeParameter {
            container = tupleDeclaration;
            name = "First";
            variance = covariant;
            selfTypeDeclaration = null;
        },
        TypeParameter {
            container = tupleDeclaration;
            name = "Rest";
            variance = covariant;
            selfTypeDeclaration = null;
        }
    };

    // ceylon.language::Callable
    value callableDeclaration
        =   InterfaceDefinition {
                container = ceylonLanguagePackage;
                name = "Callable";
            };

    ceylonLanguagePackage.defaultUnit.addDeclaration(callableDeclaration);

    callableDeclaration.addMembers {
        TypeParameter {
            container = callableDeclaration;
            name = "Return";
            variance = covariant;
            selfTypeDeclaration = null;
        },
        TypeParameter {
            container = callableDeclaration;
            name = "Arguments";
            variance = contravariant;
            selfTypeDeclaration = null;
        }
    };

    // ceylon.language::Identity
    value identityDeclaration
        =   Function {
                container = ceylonLanguagePackage;
                name = "identity";
                typeLG = parseTypeLG("Value");
            };

    ceylonLanguagePackage.defaultUnit.addDeclaration(identityDeclaration);

    value valueTP
        =   TypeParameter {
                container = identityDeclaration;
                name = "Value";
            };

    value identityParam
        =   Value {
                container = identityDeclaration;
                name = "argument";
                typeLG = valueTP.type;
            };

    identityDeclaration.addMembers {
        valueTP,
        identityParam
    };

    identityDeclaration.parameterLists
        =   [ParameterList {
                [Parameter {
                    identityParam;
                }];
            }];

    return ceylonLanguageModule;
}

shared test
void subtypesObjectNullAnything() {
    value languageModule = loadLanguageModule();
    value ceylonLanguagePackage = languageModule.ceylonLanguagePackage;
    value unit = ceylonLanguagePackage.defaultUnit;

    value anythingType = unit.anythingDeclaration.type;
    value objectType = unit.objectDeclaration.type;
    value nullType = unit.nullDeclaration.type;

    assertTrue(anythingType.isSupertypeOf(anythingType));
    assertTrue(anythingType.isSupertypeOf(objectType));
    assertTrue(anythingType.isSupertypeOf(unit.nullDeclaration.type));

    assertFalse(anythingType.isSubtypeOf(objectType));
    assertFalse(anythingType.isSubtypeOf(nullType));

    assertFalse(objectType.isSupertypeOf(nullType));
    assertFalse(objectType.isSubtypeOf(nullType));
}

shared test
void subtypesSimpleEntries() {
    value languageModule = loadLanguageModule();
    value ceylonLanguagePackage = languageModule.ceylonLanguagePackage;
    value unit = ceylonLanguagePackage.defaultUnit;

    value anythingType = unit.anythingDeclaration.type;
    value objectType = unit.objectDeclaration.type;

    function newEntry(Type key, Type item)
        =>  ceylonLanguagePackage.unit.entryDeclaration.appliedType(null, [key, item]);

    value objectAnything = newEntry(objectType, anythingType);
    value objectObject = newEntry(objectType, objectType);
    value stringObject
        =   typeFromJson {
                parseObject {
                    """{"md":"$", "nm":"Entry", "pk":"$", "tp":[
                            {"md":"$", "mt":"tp", "nm":"String", "pk":"$"},
                            {"md":"$", "mt":"tp", "nm":"Object", "pk":"$"}]}""";
                };
                ceylonLanguagePackage;
            };

    assertTrue(objectAnything.isSupertypeOf(objectObject));
    assertTrue(objectAnything.isSupertypeOf(stringObject));
    assertTrue(objectObject.isSupertypeOf(stringObject));

    assertFalse(objectAnything.isSubtypeOf(objectObject));
    assertFalse(objectAnything.isSubtypeOf(stringObject));
    assertFalse(objectObject.isSubtypeOf(stringObject));

    value objectObjectAnything = newEntry(objectType, objectAnything);
    value objectObjectObject = newEntry(objectType, objectObject);
    value objectStringObject = newEntry(objectType, stringObject);

    assertTrue(objectObject.isSupertypeOf(objectStringObject));
    assertFalse(objectObject.isSubtypeOf(objectStringObject));

    assertTrue(objectObjectAnything.isSupertypeOf(objectObjectObject));
    assertTrue(objectObjectAnything.isSupertypeOf(objectStringObject));
    assertTrue(objectObjectObject.isSupertypeOf(objectStringObject));

    assertFalse(objectObjectAnything.isSubtypeOf(objectObjectObject));
    assertFalse(objectObjectAnything.isSubtypeOf(objectStringObject));
    assertFalse(objectObjectObject.isSubtypeOf(objectStringObject));
}

shared test
void substitutionsSimple() {

    value mod = Module(["com", "example"], "0.0.0");
    mod.moduleImports.add(ModuleImport(loadLanguageModule(), true));

    value pkg = Package(["com", "example"], mod);
    mod.packages.add(pkg);

    value unit = pkg.defaultUnit;

    // Outer<T>
    value outerDeclaration
        =   ClassDefinition {
                container = pkg;
                name = "Outer";
                extendedTypeLG = unit.basicDeclaration.type;
            };

    outerDeclaration.addMembers {
        TypeParameter {
            container = outerDeclaration;
            name = "T";
        }
    };

    // Inner<U>
    value innerDeclaration
        =   ClassDefinition {
                container = outerDeclaration;
                name = "Inner";
                extendedTypeLG = unit.basicDeclaration.type;
            };

    innerDeclaration.addMembers {
        TypeParameter {
            container = innerDeclaration;
            name = "U";
        }
    };

    value tDeclaration
        =   assertedTypeParameter(outerDeclaration.getMember("T"));

    value uDeclaration
        =   assertedTypeParameter(innerDeclaration.getMember("U"));

    value innerType
        =   innerDeclaration.type;

    value substitutions
        =   map {
                tDeclaration -> unit.basicDeclaration.type,
                uDeclaration -> unit.objectDeclaration.type
            };

    value innerTypeSubstituted
        =   innerType.substitute(substitutions, emptyMap);

    //print(innerType.typeArguments);
    //print(innerType.qualifyingType?.typeArguments);

    //print(innerTypeSubstituted.typeArguments);
    //print(innerTypeSubstituted.qualifyingType?.typeArguments);

    assertEquals {
        expected = substitutions;
        actual = innerTypeSubstituted.typeArguments;
    };

    assertEquals {
        expected = map { tDeclaration->unit.basicDeclaration.type };
        actual = innerTypeSubstituted.qualifyingType?.typeArguments;
    };
}

shared test
void memberGenericTypesJson() {

    value mod = Module(["com", "example"], "0.0.0");
    mod.moduleImports.add(ModuleImport(loadLanguageModule(), true));

    value pkg = Package(["com", "example"], mod);
    mod.packages.add(pkg);

    value unit = pkg.defaultUnit;

    // Outer<T>
    value outerDeclaration
        =   ClassDefinition {
                container = pkg;
                name = "Outer";
                extendedTypeLG = unit.basicDeclaration.type;
            };

    unit.addDeclaration(outerDeclaration);

    outerDeclaration.addMembers {
        TypeParameter {
            container = outerDeclaration;
            name = "T";
        }
    };

    // Inner<U>
    value innerDeclaration
        =   ClassDefinition {
                container = outerDeclaration;
                name = "Inner";
                extendedTypeLG = unit.basicDeclaration.type;
            };

    outerDeclaration.addMembers { innerDeclaration };

    innerDeclaration.addMembers {
        TypeParameter {
            container = innerDeclaration;
            name = "U";
        }
    };

    value tDeclaration
        =   assertedTypeParameter(outerDeclaration.getMember("T"));

    value uDeclaration
        =   assertedTypeParameter(innerDeclaration.getMember("U"));

    "JSON for `Inner<Object>`"
    value jsonType1
        =   parseObject {
                 """
                    {"nm":"Outer.Inner",
                     "pk":".",
                     "tp":[{"md":"$",
                            "mt":"tp",
                            "nm":"Object",
                            "pk":"$"}]
                    }
                 """;
            };

    value loadedType1 = jsonModelUtil.parseType(pkg, jsonType1);

    assertEquals {
        expected = map {
            tDeclaration -> tDeclaration.type,
            uDeclaration -> unit.objectDeclaration.type
        };
        actual = loadedType1.typeArguments;
        "type arguments for Outer<T>.Inner<Object>";
    };

    "JSON for `Outer<String>.Inner<Object>`"
    value jsonType2
        =   map {
                keyName -> "Outer.Inner",
                keyPackage -> ".",
                keyTypeParams -> map {
                    "Outer.T" -> map {
                        keyModule -> "$",
                        keyMetatype -> metatypeTypeParameter,
                        keyName -> "String",
                        keyPackage -> "$"},
                    "Outer.Inner.U" -> map {
                        keyModule -> "$",
                        keyMetatype -> metatypeTypeParameter,
                        keyName -> "Object",
                        keyPackage -> "$"
                    }
                }
            };

    value loadedType2 = jsonModelUtil.parseType(pkg, jsonType2);

    assertEquals {
        expected = map {
            tDeclaration -> unit.stringDeclaration.type,
            uDeclaration -> unit.objectDeclaration.type
        };
        actual = loadedType2.typeArguments;
        "type arguments for Outer<String>.Inner<Object>";
    };

    assertEquals {
        expected = map {
            tDeclaration -> unit.stringDeclaration.type
        };
        actual = loadedType2.qualifyingType?.typeArguments;
        "type arguments for Outer<String>";
    };
}

shared test
void stringParameterType() {
    value languageModule = loadLanguageModule();
    value unit = languageModule.unit;

    assert (exists parameterType
        =   unit.stringDeclaration.parameterLists[0].parameters.first?.model?.type);

    value iterableCharacter
        =   unit.getIterableType(unit.characterDeclaration.type);

    value iterableObject
        =   unit.getIterableType(unit.objectDeclaration.type);

    assertTrue(parameterType.isSubtypeOf(iterableCharacter));
    assertTrue(parameterType.isSupertypeOf(iterableCharacter));

    assertTrue(parameterType.isSubtypeOf(iterableObject));
    assertFalse(parameterType.isSupertypeOf(iterableObject));
}

shared test
void selfType() {
    value mod = Module(["com", "example"], "0.0.0");
    mod.moduleImports.add(ModuleImport(loadLanguageModule(), true));

    value pkg = Package(["com", "example"], mod);
    mod.packages.add(pkg);

    value unit = pkg.defaultUnit;

    value x = InterfaceDefinition {
        container = pkg;
        name = "X";
        caseTypesLG = [parseTypeLG("Other")];
    };
    unit.addDeclaration(x);
    x.addMember {
        TypeParameter {
            container = x;
            name = "Other";
            selfTypeDeclaration = x;
            satisfiedTypesLG = [ 
                parseTypeLG("X<Other>")
            ];
        };
    };

    assertEquals(x.type.string, "X<Other> (type)");
    assertTrue(x.caseTypes.any((ct) => ct.string == "Other (type)"));
}

shared test
void jsonTypeParameters() {

    value mod = Module(["com", "example"], "0.0.0");
    mod.moduleImports.add(ModuleImport(loadLanguageModule(), true));

    value pkg = Package(["com", "example"], mod);
    mod.packages.add(pkg);

    value unit = pkg.defaultUnit;

    "JSON for `interface I<Element> given Element satisfies Object {}`"
    value genericInterface
        =   map {
                keyMetatype -> metatypeInterface,
                keyName -> "I",
                keyPackage -> ".",
                keyTypeParams -> [
                    map {
                        keyName -> "Element"
                    }
                ]
            };

    value i = jsonModelUtil.parseInterface(pkg, genericInterface);
    unit.addDeclaration(i);

    value jsonType
        =   map {
                keyName -> "I",
                keyPackage -> ".",
                keyTypeArgs -> map {
                    // type param must be partially qualified
                    "I.Element" -> map {
                        keyModule -> "$",
                        keyPackage -> "$",
                        keyName -> "String"}
                }
            };

    value t = jsonModelUtil.parseType(pkg, jsonType);

    assertEquals (t.string, "I<String> (type)");
}

shared test
void identityFunction() {
    value languageModule = loadLanguageModule();
    value unit = languageModule.unit;

    assert (is Function identityFunction
        =   unit.ceylonLanguagePackage.getMember("identity"));

    assert (exists valueTP
        =   identityFunction.typeParameters.first);

    value identityStringTypedReference
        =   TypedReference {
                identityFunction;
                map { valueTP -> unit.stringDeclaration.type };
                null;
            };
    
    assertTrue {
        identityStringTypedReference.type.isExactly {
            unit.stringDeclaration.type;
        };
    };

    // add tests for fullType and parameter types of identityStringTypedReference
    // when possible.

    assertEquals {
        identityFunction.string;
        "function identity<Value>(Value argument) => Value";
    };
}
