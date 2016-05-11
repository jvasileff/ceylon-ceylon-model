import com.vasileff.ceylon.model {
    Module,
    Package,
    Unit,
    NothingDeclaration
}
import ceylon.collection {
    MutableSet
}

shared
class LazyJsonModule(
        JsonObject json,
        [String+] name = jsonModelUtil.parseModuleName(json),
        String? version = jsonModelUtil.parseModuleVersion(json),
        Unit(Package)? unitLG = null)
        extends Module(name, version, unitLG) {

    variable Boolean allLoaded = false;

    shared actual
    MutableSet<Package> packages {
        if (!allLoaded) {
            // let findDirectPackage do all the work
            json.keys.filter((n) => !n.startsWith("$mod-")).each(findDirectPackage);
            allLoaded = true;
        }
        return super.packages;
    }

    shared actual
    Package? findDirectPackage(String qualifiedName) {
        if (exists existing
                =   super.packages.find((p) => p.qualifiedName == qualifiedName)) {
            return existing;
        }

        if (allLoaded) {
            return null;
        }

        if (exists packageJson = getObjectOrNull(json, qualifiedName)) {
            assert (nonempty nameParts = qualifiedName.split('.'.equals).sequence());
            value pkg = LazyJsonPackage(nameParts, this, packageJson);
            if (qualifiedName == "ceylon.language") {
                // manually add ceylon.language::Nothing, which shouldn't be in the
                // json object
                pkg.defaultUnit.addDeclaration {
                    NothingDeclaration(pkg.defaultUnit);
                };
            }
            super.packages.add(pkg);
            return pkg;
        }

        return null;
    }
}
