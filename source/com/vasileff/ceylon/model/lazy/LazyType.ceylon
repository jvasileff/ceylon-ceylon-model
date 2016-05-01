import com.vasileff.ceylon.model {
    Type,
    Package
}
import com.vasileff.ceylon.model.parser {
    parseType
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

// shared // just an idea; not as fast or safe as parseTypeLG
Type parseTypeLazy(Package pkg, String scope, String type)
    =>  LazyType(() {
            assert (exists scope = pkg.findDeclaration(scope.split(".".equals)));
            return parseType(type, scope);
        });
