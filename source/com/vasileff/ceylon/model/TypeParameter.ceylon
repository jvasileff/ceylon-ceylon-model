import com.vasileff.ceylon.model.internal {
    toType
}

shared
class TypeParameter(
        container, name, satisfiedTypesLG = [], caseTypesLG = [],
        variance = invariant, selfTypeDeclaration = null,
        defaultTypeArgumentLG = null, isTypeConstructor = false)
        extends TypeDeclaration() {

    {Type | Type(Scope)*} satisfiedTypesLG;
    {Type | Type(Scope)*} caseTypesLG;
    Type | Type(Scope) | Null defaultTypeArgumentLG;

    variable [Type*]? satisfiesTypesMemo = null;
    variable [Type*]? caseTypesMemo = null;
    variable Type? defaultTypeArgumentMemo = null;

    shared actual
    Type[] satisfiedTypes
        =>  satisfiesTypesMemo else (satisfiesTypesMemo
            =   satisfiedTypesLG.collect(toType(this)));

    shared actual
    Type[] caseTypes
        // FIXME remove types with declarations == this; see ceylon-model
        =>  caseTypesMemo else (caseTypesMemo
            =   caseTypesLG.collect(toType(this)));

    shared
    Type? defaultTypeArgument
        =>  defaultTypeArgumentMemo else (
                if (exists defaultTypeArgumentLG)
                then (defaultTypeArgumentMemo = toType(this)(defaultTypeArgumentLG))
                else null);

    // TODO lazy
    shared actual
    Value[] caseValues => nothing;

    shared actual Scope container;
    shared actual String name;
    shared TypeDeclaration? selfTypeDeclaration;
    shared Variance variance;

    shared Boolean isTypeConstructor;

    shared actual Type extendedType => unit.anythingDeclaration.type;
    shared actual Null qualifier => null;
    shared actual Null refinedDeclaration => null;
    shared actual Null selfType => null;
    shared actual Unit unit => container.unit;

    shared actual Boolean isActual => false;
    shared actual Boolean isAnnotation => false;
    shared actual Boolean isAnonymous => false;
    shared actual Boolean isDefault => false;
    shared        Boolean isDefaulted => defaultTypeArgumentLG exists;
    shared actual Boolean isDeprecated => false;
    shared actual Boolean isFinal => false;
    shared actual Boolean isFormal => false;
    shared actual Boolean isNamed => true;
    shared actual Boolean isSealed => false;
    shared actual Boolean isSelfType => selfTypeDeclaration exists;
    shared actual Boolean isShared => false;
    shared actual Boolean isStatic => false;

    shared actual
    Boolean inherits(ClassOrInterface | TypeParameter that)
        =>  that.isAnything || satisfiedTypes.any((st) => st.declaration.inherits(that));

    shared actual
    {ClassOrInterface | TypeParameter*} extendedAndSatisfiedDeclarations {
        return extendedAndSatisfiedTypes.map((t) {
            assert (is ClassOrInterface | TypeParameter d = t.declaration);
            return d;
        });
    }

    shared actual
    Type type
        =>  createType {
                declaration = this;
                qualifyingType = null; // memberContainerType would cause circularity
                typeArguments = typeParametersAsArguments;
                isTypeConstructor = isTypeConstructor;
                typeConstructorParameter = isTypeConstructor then this;
            };

    shared actual
    Boolean canEqual(Object other)
        =>  other is TypeParameter;

    shared actual
    String string
        =>  "given ``partiallyQualifiedNameWithTypeParameters``";
}
