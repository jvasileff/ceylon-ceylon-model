import com.vasileff.ceylon.model.internal {
    toType
}

shared
class ClassDefinition(
        container, name, extendedTypeLG, qualifier = null, refinedDeclaration = null,
        satisfiedTypesLG = [], caseTypesLG = [], caseValues = [], selfType = null,
        isShared = false, isFormal = false, isActual = false, isDefault = false,
        isAnnotation = false, isDeprecated = false, isStatic = false, isSealed = false,
        isAbstract = false, isAnonymous = false, isNamed = true, isFinal = false,
        unit = container.pkg.defaultUnit)
        extends Class()
        satisfies Functional {

    // TODO parameterLists initialization: they hold declarations that are also members.
    //      So, make mutable, perhaps variable. Perform checks for members on assignment?

    {Type | Type(Scope)*} satisfiedTypesLG;
    {Type | Type(Scope)*} caseTypesLG;
    Type | Type(ClassDefinition) | Null extendedTypeLG;

    variable [ParameterList] _parameterLists = [ParameterList.empty];

    variable [Type*]? satisfiesTypesMemo = null;
    variable [Type*]? caseTypesMemo = null;
    variable Type? extendedTypeMemo = null;

    shared actual
    Type[] satisfiedTypes
        =>  satisfiesTypesMemo else (satisfiesTypesMemo
            =   satisfiedTypesLG.collect(toType(this)));

    shared actual
    Type[] caseTypes
        =>  caseTypesMemo else (caseTypesMemo
            =   caseTypesLG.collect(toType(this)));

    shared actual
    Type? extendedType
        =>  extendedTypeMemo else (
                switch (extendedTypeLG)
                case (is Null) null
                case (is Type) (extendedTypeMemo = extendedTypeLG)
                else (extendedTypeMemo = extendedTypeLG(this)));

    shared actual Value[] caseValues;
    shared actual Scope container;
    shared actual String name;
    shared actual Integer? qualifier;
    shared actual Class? refinedDeclaration;
    shared actual Type? selfType;
    shared actual Unit unit;

    shared actual Boolean isAbstract;
    shared actual Boolean isActual;
    shared actual Boolean isAnnotation;
    shared actual Boolean isAnonymous;
    shared actual Boolean isDefault;
    shared actual Boolean isDeprecated;
    shared actual Boolean isFinal;
    shared actual Boolean isFormal;
    shared actual Boolean isNamed;
    shared actual Boolean isSealed;
    shared actual Boolean isShared;
    shared actual Boolean isStatic;

    shared actual
    [ParameterList+] parameterLists
        =>  _parameterLists;

    shared
    ParameterList parameterList => _parameterLists.first;

    "Set the parameter list. Models (FunctionOrValues) for all parameters must already
     be members of this Class."
    throws(`class AssertionError`, "If the underlying FunctionOrValue of one of the
                                    parameters is not a member of this Class.")
    assign parameterList {
        for (member in parameterList.parameters.map(Parameter.model)) {
            "A parameter's function or value must be a member of the parameter list's \
             container."
            assert (members.contains(member.name -> member));
        }
        _parameterLists = [parameterList];
    }

    shared actual
    Boolean declaredVoid
        =>  false;

    shared actual
    Boolean inherits(TypeDeclaration that) {
        if (that.isAnything) {
            return true;
        }

        if (that.isObject) {
            return !isAnything && !isNull && !isNullValue;
        }

        if (that.isNull) {
            return isNull || isNullValue;
        }

        if (this == that) {
            return true;
        }

        if (that.isFinal) {
            // cannot possibly be true, since that is nonequal
            return false;
        }

        // Copied todo: optimize this to avoid walking the same supertypes multiple times
        if (exists et = extendedType, et.declaration.inherits(that)) {
            return true;
        }
        if (is Interface that) {
            return satisfiedTypes.any((t) => t.declaration.inherits(that));
        }

        return false;
    }

    shared actual
    Boolean canEqual(Object other)
        =>  other is ClassDefinition;
}
