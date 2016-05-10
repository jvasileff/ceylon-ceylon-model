import com.vasileff.ceylon.model {
    Scope,
    Type,
    Declaration,
    TypeParameter,
    Variance,
    TypeDeclaration,
    covariant,
    contravariant,
    ClassDefinition,
    Package,
    invariant,
    InterfaceDefinition,
    Class,
    Interface
}
import com.vasileff.ceylon.model.internal {
    assertedTypeDeclaration
}

shared
object jsonModelUtil {

    function getString(JsonObject json, String key) {
        assert (is String result = json[key]);
        return result;
    }

    function getStringOrNull(JsonObject json, String key) {
        assert (is String? result = json[key]);
        return result;
    }

    suppressWarnings("unusedDeclaration")
    function getInteger(JsonObject json, String key) {
        assert (is Integer result = json[key]);
        return result;
    }

    function getIntegerOrNull(JsonObject json, String key) {
        assert (is Integer? result = json[key]);
        return result;
    }

    suppressWarnings("unusedDeclaration")
    function getArrayOrNull(JsonObject json, String key) {
        assert (is JsonArray? result = json[key]);
        return result;
    }

    function getArrayOrEmpty(JsonObject json, String key) {
        assert (is JsonArray? result = json[key]);
        return result else [];
    }

    function getObjectOrNull(JsonObject json, String key) {
        assert (is JsonObject? result = json[key]);
        return result;
    }

    function getObjectOrEmpty(JsonObject json, String key) {
        assert (is JsonObject? result = json[key]);
        return result else emptyMap;
    }

    function getObjectOrArrayOrNull(JsonObject json, String key) {
        assert (is JsonObject | JsonArray | Null result = json[key]);
        return result;
    }

    function getModuleName(JsonObject json)
        =>  if (is String m = json[keyModule])
            then if (m == "$")
                 then "ceylon.language"
                 else m
            else null;

    function getPackageName(Scope scope, JsonObject json)
        =>  if (is String m = json[keyPackage])
            then if (m == "$") then
                    "ceylon.language"
                 else if (m == ".") then
                    // TODO building a name just to tear it down, and then
                    //      rebuild it...
                    ".".join(scope.pkg.name)
                 else m
            else null;

    Declaration? declarationFromType(Scope scope, JsonObject json)
        =>  scope.findDeclaration {
                declarationName = getString(json, keyName).split('.'.equals);
                packageName = getPackageName(scope, json);
                moduleName = getModuleName(json);
            };

    "The input map be:

     - A [[JsonArray]], with each element being a [[JsonObject]] representing a type
       argument, in order of the type's type parameters, or

     - a [[JsonObject]], mapping qualified type parameter names to types.

     - or [[null]], in which case `null` will be returned."
    [Map<TypeParameter, Type>, Map<TypeParameter, Variance>]
    typeArgumentMaps(TypeDeclaration declaration, JsonArray | JsonObject | Null json) {

        function useSiteOverrideEntry(
                TypeParameter typeParameter, JsonObject typeArgumentJson) {

            switch (override = typeArgumentJson.get(keyUsVariance))
                case (is Null) {
                    return null;
                }
                case (0) {
                    return typeParameter -> covariant;
                }
                case (1) {
                    return typeParameter -> contravariant;
                }
                else {
                    throw Exception(
                        "Invalid use site variance value ``override``");
            }
        }

        switch (json)
        case (is Null) {
            return [emptyMap, emptyMap];
        }
        case (is JsonArray) {
            value typeArgs
                =   map(mapPairs((TypeParameter typeParameter, Anything jsonType) {
                        assert (is JsonObject jsonType);
                        return typeParameter -> parseType(declaration, jsonType);
                    }, declaration.typeParameters, json));

            value overrides
                =   map(mapPairs((TypeParameter typeParameter, Anything jsonTypeArgument) {
                        assert (is JsonObject jsonTypeArgument);
                        return useSiteOverrideEntry(typeParameter, jsonTypeArgument);
                    }, declaration.typeParameters, json).coalesced);

            return [typeArgs, overrides];
        }
        else { // is JsonObject
            value typeParametersToJson
                =   json.map((nameAndType) {
                        value name -> jsonType
                            =   nameAndType;

                        value typeParameter
                            =   declaration.findDeclaration(name.split('.'.equals));

                        if (!is TypeParameter typeParameter) {
                            throw Exception("cannot find type parameter for name ``name``");
                        }
                        return typeParameter -> jsonType;
                    });

            value typeArgs
                =   map(typeParametersToJson.map((entry) {
                        value typeParameter -> jsonType = entry;
                        assert (is JsonObject jsonType);
                        return typeParameter -> parseType(declaration, jsonType);
                    }));

            value overrides
                =   map(typeParametersToJson.map((entry) {
                        value typeParameter -> jsonTypeArgument = entry;
                        assert (is JsonObject jsonTypeArgument);
                        return useSiteOverrideEntry(typeParameter, jsonTypeArgument);
                    }).coalesced);

            return [typeArgs, overrides];
        }
    }

    shared
    Type parseType(Scope scope, JsonObject json)
            // TODO look at JsonPackage.getTypeFromJson. It has a lot more code?
        =>  if (getString(json, keyName) == "$U")
            then scope.unit.unknownType
            else let (declaration
                    =   assertedTypeDeclaration {
                            declarationFromType(scope, json);
                        })
                let ([typeArguments, overrides]
                    =   typeArgumentMaps {
                            declaration;
                            getObjectOrArrayOrNull(json, keyTypeParams);
                        })
                declaration.type.substitute(typeArguments, overrides);

    Variance parseDsVariance(JsonObject json) {
        if (is String dv = json[keyDsVariance]) {
            switch (dv)
            case ("out") {
                return covariant;
            }
            case ("in") {
                return contravariant;
            }
            else {
                throw Exception("invalid variance ``dv``");
            }
        }
        return invariant;
    }

    shared
    TypeParameter parseTypeParameter(Scope scope, JsonObject json)
        =>  TypeParameter {
                container = scope;
                name = getString(json, keyName);
                variance = parseDsVariance(json);
                isTypeConstructor = false; // TODO

                defaultTypeArgumentLG
                    =   if (exists da = getObjectOrNull(json, keyDefault))
                        then typeFromJsonLG(da)
                        else null;

                caseTypesLG
                    =   getArrayOrEmpty(json, keyCases).map((s) {
                            assert (is JsonObject s);
                            return typeFromJsonLG(s);
                        });

                satisfiedTypesLG
                    =   getArrayOrEmpty(json, keySatisfies).map((s) {
                            assert (is JsonObject s);
                            return typeFromJsonLG(s);
                        });
            };

    shared
    Interface parseInterface(Scope scope, JsonObject json) {

        value packedAnnotations
            =   getIntegerOrNull(json, keyPackedAnnotations) else 0;

        value declaration
            =   InterfaceDefinition {
                    container = scope;
                    unit = scope.pkg.defaultUnit;
                    name = getString(json, keyName);

                    satisfiedTypesLG
                        =   getArrayOrEmpty(json, keySatisfies).map((s) {
                                assert (is JsonObject s);
                                return typeFromJsonLG(s);
                            });

                    isShared = packedAnnotations.get(sharedBit);
                    isActual = packedAnnotations.get(actualBit);
                    isFormal = packedAnnotations.get(formalBit);
                    isDefault = packedAnnotations.get(defaultBit);
                    isSealed = packedAnnotations.get(sealedBit);
                    isFinal = packedAnnotations.get(finalBit);
                    isAnnotation = packedAnnotations.get(annotationBit);
                };

        for (tpJson in getArrayOrEmpty(json, keyTypeParams)) {
            assert (is JsonObject tpJson);
            declaration.addMember(parseTypeParameter(declaration, tpJson));
        }

        for (classJson in getObjectOrEmpty(json, keyClasses).items) {
            assert (is JsonObject classJson);
            declaration.addMember(parseClass(declaration, classJson));
        }

        for (interfaceJson in getObjectOrEmpty(json, keyClasses).items) {
            assert (is JsonObject interfaceJson);
            declaration.addMember(parseInterface(declaration, interfaceJson));
        }

        return declaration;
    }

    shared
    Class parseClass(Scope scope, JsonObject json) {

        value packedAnnotations
            =   getIntegerOrNull(json, keyPackedAnnotations) else 0;

        value declaration
            =   ClassDefinition {
                    container = scope;
                    name = getString(json, keyName);
                    unit = scope.pkg.defaultUnit;

                    satisfiedTypesLG
                        =   getArrayOrEmpty(json, keySatisfies).map((s) {
                                assert (is JsonObject s);
                                return typeFromJsonLG(s);
                            });

                    extendedTypeLG
                        =   if (is JsonObject et = json[keyExtendedType])
                            then typeFromJsonLG(et)
                            else null;

                    isShared = packedAnnotations.get(sharedBit);
                    isActual = packedAnnotations.get(actualBit);
                    isFormal = packedAnnotations.get(formalBit);
                    isDefault = packedAnnotations.get(defaultBit);
                    isSealed = packedAnnotations.get(sealedBit);
                    isFinal = packedAnnotations.get(finalBit);
                    isAnnotation = packedAnnotations.get(annotationBit);
                    isAbstract = packedAnnotations.get(abstractBit);
                };

        for (tpJson in getArrayOrEmpty(json, keyTypeParams)) {
            assert (is JsonObject tpJson);
            declaration.addMember(parseTypeParameter(declaration, tpJson));
        }

        for (classJson in getObjectOrEmpty(json, keyClasses).items) {
            assert (is JsonObject classJson);
            declaration.addMember(parseClass(declaration, classJson));
        }

        for (interfaceJson in getObjectOrEmpty(json, keyClasses).items) {
            assert (is JsonObject interfaceJson);
            declaration.addMember(parseInterface(declaration, interfaceJson));
        }

        return declaration;
    }

    void loadToplevel(Package pkg, JsonObject item) {
        assert (exists metaType = getStringOrNull(item, keyMetatype));

        if (metaType == metatypeClass) {
            pkg.defaultUnit.addDeclaration(parseClass(pkg, item));
        }
        else if (metaType == metatypeInterface) {
            pkg.defaultUnit.addDeclaration(parseInterface(pkg, item));
        }

        // attribute
        // getter
        // method
        // object
        // alias
    }

    shared
    void loadToplevelDeclarations(Package pkg, JsonObject json) {
        for (key -> item in json) {
            if (key.startsWith("$pkg-")) {
                continue;
            }

            assert (is JsonObject item);
            loadToplevel(pkg, item);
        }
    }

    "Returns `true` if the toplevel declaration was found."
    shared
    Boolean loadToplevelDeclaration(Package pkg, String name, JsonObject packageJson) {
        if (name.startsWith("$pkg-")) {
            return false;
        }

        value item = getObjectOrNull(packageJson, name);

        if (!exists item) {
            return false;
        }

        loadToplevel(pkg, item);
        return true;
    }
}
