import com.vasileff.ceylon.model {
    Type
}

// shared // not currently used
class LazyType(initializeType) extends Type() {
    shared Type initializeType();

    variable Type? typeMemo = null;

    value type => typeMemo else (typeMemo = initializeType());

    declaration => type.declaration;
    specifiedTypeArguments => type.specifiedTypeArguments;
    qualifyingType => type.qualifyingType;
    varianceOverrides => type.varianceOverrides;
    isTypeConstructor => type.isTypeConstructor;
    typeConstructorParameter => type.typeConstructorParameter;
}
