shared final
class CallableConstructor(
        String name, Class container, Type extendedType, Boolean isDeprecated = false,
        Boolean isSealed = false, Boolean isShared = false,
        Unit unit = container.pkg.defaultUnit)
        extends Constructor(
            name, container, extendedType, isDeprecated, isSealed, isShared, unit)
        satisfies Functional {

    variable [ParameterList] _parameterLists = [ParameterList.empty];

    shared actual
    [ParameterList] parameterLists
        =>  _parameterLists;

    shared
    ParameterList parameterList => _parameterLists.first;

    "Set the parameter list. Models (FunctionOrValues) for all parameters must already
     be members of this element."
    throws(`class AssertionError`, "If the underlying FunctionOrValue of one of the
                                    parameters is not a member of this element.")
    assign parameterList {
        for (member in parameterList.parameters.map(Parameter.model)) {
            "A parameter's function or value must be a member of the parameter list's \
             container."
            assert (members.contains(member.name -> member));
        }
        _parameterLists = [parameterList];
    }

    shared actual
    Boolean declaredVoid => false;

    shared actual
    CallableConstructor refinedDeclaration => this;

    shared actual
    Boolean canEqual(Object other)
        =>  other is CallableConstructor;

    shared actual
    String string
        =>  "new ``partiallyQualifiedNameWithTypeParameters````valueParametersAsString``";
}
