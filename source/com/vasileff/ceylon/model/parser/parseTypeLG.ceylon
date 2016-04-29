import com.vasileff.ceylon.model {
    Type,
    Scope
}

shared
Type parseTypeLG(String type)(Scope scope)
    =>  parseType(scope.unit, type);
