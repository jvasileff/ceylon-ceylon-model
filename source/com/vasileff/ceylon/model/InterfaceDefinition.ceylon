import com.vasileff.ceylon.model.internal {
    toType
}

shared
class InterfaceDefinition(
        container, name,
        qualifier = null, satisfiedTypesLG = [], caseTypesLG = [], caseValues = [],
        selfType = null, isShared = false, isFormal = false, isActual = false,
        isDefault = false, isAnnotation = false, isDeprecated = false,
        isStatic = false, isSealed = false, isFinal = false,
        unit = container.pkg.defaultUnit)
        extends Interface() {

    {Type | Type(Scope)*} satisfiedTypesLG;
    {Type | Type(Scope)*} caseTypesLG;

    variable [Type*]? satisfiesTypesMemo = null;
    variable [Type*]? caseTypesMemo = null;

    shared actual Type[] satisfiedTypes
        =>  satisfiesTypesMemo else (satisfiesTypesMemo
            =   satisfiedTypesLG.collect(toType(this)));

    shared actual Type[] caseTypes
        =>  caseTypesMemo else (caseTypesMemo
            =   caseTypesLG.collect(toType(this)));

    shared actual [Value*] caseValues;
    shared actual Scope container;
    shared actual String name;
    shared actual Integer? qualifier;
    shared actual Type? selfType;
    shared actual Unit unit;

    shared actual Boolean isActual;
    shared actual Boolean isAnnotation;
    shared actual Boolean isDefault;
    shared actual Boolean isDeprecated;
    shared actual Boolean isFinal;
    shared actual Boolean isFormal;
    shared actual Boolean isSealed;
    shared actual Boolean isShared;
    shared actual Boolean isStatic;

    shared actual Type extendedType => unit.anythingDeclaration.type;
    shared actual Class? refinedDeclaration => null;

    shared actual
    Boolean canEqual(Object other)
        =>  other is InterfaceDefinition;

    shared actual
    Boolean inherits(TypeDeclaration that) {
        if (that.isAnything || that.isObject) {
            return true;
        }

        if (that is Class) {
            // interface can't inherit any other class
            return false;
        }

        if (this == that) {
            return true;
        }

        // Copied todo: optimize this to avoid walking the same supertypes multiple times
        if (is Interface that) {
            return satisfiedTypes.any((t) => t.declaration.inherits(that));
        }

        return false;
    }

    shared actual
    String string {
        // TODO include type parameters of this and all containers.
        return "interface ``qualifiedName``";
    }
}
