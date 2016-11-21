shared final
class ValueConstructor(
        String name, Class container, Type extendedType, Boolean isDeprecated = false,
        Boolean isSealed = false, Boolean isShared = false,
        Unit unit = container.pkg.defaultUnit)
        extends Constructor(
            name, container, extendedType, isDeprecated, isSealed, isShared, unit) {

    shared actual
    ValueConstructor refinedDeclaration => this;

    shared actual
    Boolean canEqual(Object other)
        =>  other is ValueConstructor;

    shared actual
    String string
        =>  "new ``partiallyQualifiedNameWithTypeParameters``";
}
