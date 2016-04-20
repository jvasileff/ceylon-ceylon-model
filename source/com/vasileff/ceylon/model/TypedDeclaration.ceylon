shared abstract
class TypedDeclaration()
        of FunctionOrValue
        extends Declaration() {

    shared actual formal
    TypedDeclaration? refinedDeclaration;

    shared actual formal
    Scope container;

    shared formal
    Type type;
}
