import com.vasileff.ceylon.model {
    Scope,
    Type,
    Declaration,
    TypeParameter,
    Variance,
    TypeDeclaration,
    covariant,
    contravariant
}
import com.vasileff.ceylon.model.internal {
    assertedTypeDeclaration
}

shared
object jsonModelUtil {

    function getString(JsonObject json, String key) {
        assert (is String string = json[key]);
        return string;
    }

    suppressWarnings("unusedDeclaration")
    function getArrayOrNull(JsonObject json, String key) {
        assert (is JsonArray? string = json[key]);
        return string;
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

    shared
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
                        return typeParameter -> loadType(declaration, jsonType);
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
                        return typeParameter -> loadType(declaration, jsonType);
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
    Type loadType(Scope scope, JsonObject json)
            // TODO look at JsonPackage.getTypeFromJson. It has a lot more code?
        =>  let (declaration
                =   assertedTypeDeclaration {
                        declarationFromType(scope, json);
                    })
            let ([typeArguments, overrides]
                =   typeArgumentMaps {
                        declaration;
                        getObjectOrArrayOrNull(json, keyTypeParams);
                    })
            declaration.type.substitute(typeArguments, overrides);
}
