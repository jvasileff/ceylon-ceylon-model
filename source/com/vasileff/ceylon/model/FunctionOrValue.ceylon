shared abstract
class FunctionOrValue()
        of Function | Value | Setter
        extends TypedDeclaration() {

    shared actual formal FunctionOrValue? refinedDeclaration;
}
