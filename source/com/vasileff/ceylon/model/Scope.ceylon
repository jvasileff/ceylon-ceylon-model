import com.vasileff.ceylon.structures {
    ListMultimap
}

shared
interface Scope of Package | Element {

    shared formal
    String qualifiedName;

    "The 'real' scope of the element, ignoring that conditions (in an assert, if, or
     while) each have their own 'fake' scope."
    shared formal
    Scope? container;

    shared formal
    Unit unit;

    shared default
    Package pkg => unit.pkg;

    shared default
    Module mod => pkg.mod;

    shared formal
    ListMultimap<String, Declaration> members;

    function isResolvable(Declaration d)
        =>  !d is Setter        // return getters, not setters
            && !d.isAnonymous;  // don't return types for 'object's

    "Return the first resolvable member found matching the given [[name]]. Resolvable
     members are members that are not [[Setter]]s and not [[Declaration.isAnonymous]]."
    shared default
    Declaration? getMember(String name)
        =>  members.get(name).find(isResolvable);

    "Find a declaration by name.

     The package in which to search will be determined as follows:

     If [[moduleName]] is not null, search for [[packageName]] within a visible
     module with the name [[moduleName]], if any. If [[packageName]] is null, use the
     current package. If [[packageName]] is null and [[moduleName]] is not null,
     [[moduleName]] will be ignored (the current package will be used)."
    shared
    Declaration? findDeclaration(
            "The name parts of the declaration to find."
            {String+} declarationName,
            "The name of the package to search, or `null` for this Scope's package."
            String? packageName = null,
            "The name of the module to search, or `null` for this Scope's module."
            String? moduleName = null) {

        // TODO declarationName won't be enough if we start relying on `qualifier` to
        //      distinguish declarations that have the same name and nearest ancestor
        //      declaration.

        "The package to search."
        value p
            =   if (exists packageName) then
                    let (m = if (exists moduleName)
                             then mod.findModule(moduleName)
                             else mod)
                    m?.findDirectPackage(packageName)
                else
                    pkg;

        if (!exists p) {
            return null;
        }

        return declarationName.rest.fold
                (p.getMember(declarationName.first)) // start with declarationName[0]
                ((d, name) => d?.getMember(name));   // resolve subsequent parts
    }

    shared actual formal
    String string;
}
