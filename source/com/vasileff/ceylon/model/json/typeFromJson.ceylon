import com.vasileff.ceylon.model {
    Scope,
    Type
}

shared
Type typeFromJson(JsonObject json)(Scope scope)
    =>  jsonModelUtil.loadType(scope, json);
