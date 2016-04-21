shared abstract
class Class()
        of ClassDefinition | ClassAlias
        extends ClassOrInterface()
        satisfies Functional {

    shared formal Boolean isAbstract;

    shared actual
    String string
        =>  "class ``partiallyQualifiedNameWithTypeParameters````valueParametersAsString``";
}
