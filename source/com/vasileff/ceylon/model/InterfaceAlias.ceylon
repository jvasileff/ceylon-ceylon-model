shared abstract
class InterfaceAlias(extendedType) extends Interface() {
    shared actual
    Type extendedType;

    shared actual
    Boolean inherits(TypeDeclaration that)
        =>  extendedType.declaration.inherits(that);

    shared actual
    Boolean canEqual(Object other) => other is InterfaceAlias;

    shared actual
    String string {
        // TODO include type parameters of this and all containers.
        return "interface ``qualifiedName``";
    }
}
