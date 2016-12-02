import com.vasileff.ceylon.model.internal {
    toType
}

shared abstract
class Class(extendedTypeLG, satisfiedTypesLG = [])
        of ClassDefinition | ClassAlias
        extends ClassOrInterface()
        satisfies Functional {

    Type | Type(Scope) | Null extendedTypeLG;
    {Type | Type(Scope)*} satisfiedTypesLG;

    variable Type? extendedTypeMemo = null;
    variable [Type*]? satisfiesTypesMemo = null;

    "Used to avoid circularities, particularly with Scope.getBase() attempting to search
     inherited members while lazily generating the supertypes that define inheritance.

     When `true`, supertype members will be effectively not in scope."
    variable value definingInheritance = false;

    shared actual default
    Type? extendedType {
        if (exists result = extendedTypeMemo) {
            return result;
        }
        else if (definingInheritance) {
            return null;
        }
        else {
            try {
                definingInheritance = true;
                return extendedTypeMemo
                    =   switch (extendedTypeLG)
                        case (is Null) null
                        case (is Type) (extendedTypeMemo = extendedTypeLG)
                        else (extendedTypeMemo = extendedTypeLG(this));
            }
            finally {
                definingInheritance = false;
            }
        }
    }

    shared actual default
    Type[] satisfiedTypes {
        if (exists result = satisfiesTypesMemo) {
            return result;
        }
        else if (definingInheritance) {
            return [];
        }
        else {
            try {
                definingInheritance = true;
                return satisfiesTypesMemo
                    =   satisfiedTypesLG.collect(toType(this));
            }
            finally {
                definingInheritance = false;
            }
        }
    }

    shared formal Boolean isAbstract;

    shared actual default Class refinedDeclaration {
        assert(is Class f = super.refinedDeclaration);
        return f;
    }

    shared actual
    String string
        =>  "class ``partiallyQualifiedNameWithTypeParameters````valueParametersAsString``";
}
