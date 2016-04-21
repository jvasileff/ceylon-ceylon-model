shared
class Value(container, name, typeLG, refinedDeclaration = null, isShared = false,
        isFormal = false, isActual = false, isDefault = false, isDeprecated = false,
        isStatic = false, unit = container.pkg.defaultUnit)
        extends FunctionOrValue() {

    Type | Type(Scope) typeLG;

    variable Type? typeMemo = null;

    shared actual
    Type type
        =>  typeMemo else (
                switch (typeLG)
                case (is Type) (typeMemo = typeLG)
                else (typeMemo = typeLG(this)));

    shared actual Scope container;
    shared actual String name;
    shared actual Value? refinedDeclaration;
    shared actual Unit unit;

    shared actual Boolean isActual;
    shared actual Boolean isDefault;
    shared actual Boolean isDeprecated;
    shared actual Boolean isFormal;
    shared actual Boolean isShared;
    shared actual Boolean isStatic;

    shared actual Null qualifier => null;

    shared actual Boolean isAnnotation => false;
    shared actual Boolean isAnonymous => false;
    shared actual Boolean isNamed => true;

    shared
    Setter? setter
        =>  container.members.get(name).map((d)
            =>  if (is Setter d) then d else null).coalesced.first;

    shared actual
    Boolean canEqual(Object other) => other is Value;

    shared actual
    String string
        =>  "value ``partiallyQualifiedNameWithTypeParameters`` => \
             ``type.formatted``";
}
