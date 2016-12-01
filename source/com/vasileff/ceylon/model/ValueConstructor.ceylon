shared final
class ValueConstructor(
        name, container, extendedType, isDeprecated = false, isSealed = false,
        isShared = false, unit = container.pkg.defaultUnit)
        extends Constructor() {

    shared actual Class container;
    shared actual String name;
    shared actual Type extendedType;
    shared actual Unit unit;

    shared actual Boolean isDeprecated;
    shared actual Boolean isSealed;
    shared actual Boolean isShared;

    shared actual
    ValueConstructor refinedDeclaration => this;

    shared actual
    Boolean canEqual(Object other)
        =>  other is ValueConstructor;

    shared actual
    String string
        =>  "new ``partiallyQualifiedNameWithTypeParameters``";
}
