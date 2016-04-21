shared abstract
class Interface()
        of InterfaceDefinition | InterfaceAlias
        extends ClassOrInterface() {

    shared actual Boolean isAnonymous => false;
    shared actual Boolean isNamed => true;

    shared actual
    String string
        =>  "interface ``partiallyQualifiedNameWithTypeParameters``";
}
