shared abstract
class Function(name, refinedDeclaration, typeLG)
        extends FunctionOrValue()
        satisfies Functional & Generic {

    Type | Type(Scope) typeLG;

    variable Type? typeMemo = null;

    shared actual
    Type type
        =>  typeMemo else (
                switch (typeLG)
                case (is Type) (typeMemo = typeLG)
                else (typeMemo = typeLG(this)));

    shared actual String name;
    shared actual Function? refinedDeclaration;

    shared actual
    String string
        =>  "function ``partiallyQualifiedNameWithTypeParameters````valueParametersAsString`` \
             => ``type.string``";
}
