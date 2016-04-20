import ceylon.json {
    parse
}

import com.vasileff.ceylon.model {
    Class,
    Value,
    TypeDeclaration,
    Declaration,
    Interface,
    Scope,
    TypeParameter
}
import com.vasileff.ceylon.model.json {
    JsonObject
}

JsonObject parseObject(String json) {
    assert (is JsonObject map = parse(json));
    return map;
}

Class assertedClass(Declaration? d) {
    assert (is Class d);
    return d;
}

Interface assertedInterface(Declaration? d) {
    assert (is Interface d);
    return d;
}

TypeDeclaration assertedTypeDeclaration(Scope? declaration) {
    assert (is TypeDeclaration declaration);
    return declaration;
}

TypeParameter assertedTypeParameter(Declaration? d) {
    assert (is TypeParameter d);
    return d;
}

Value assertedValue(Declaration? d) {
    assert (is Value d);
    return d;
}
