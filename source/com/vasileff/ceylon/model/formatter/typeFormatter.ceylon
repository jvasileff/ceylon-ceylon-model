import com.vasileff.ceylon.model {
    Type
}

shared
String formatType(Type type) {
    value declaration = type.declaration;
    if (declaration.isAlias && declaration.isAnonymous) {
        return "alias+anonymous-notYetFormattable:``declaration.name``";
    }
    else {
        return "type:``declaration.qualifiedName``";
    }
}
