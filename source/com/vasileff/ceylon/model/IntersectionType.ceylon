import ceylon.collection {
    HashSet
}

shared
class IntersectionType(satisfiedTypes, unit) extends TypeDeclaration() {

    shared actual Type[] satisfiedTypes;
    shared actual Unit unit;

    shared actual Type[] caseTypes => [];
    shared actual Value[] caseValues => [];
    shared actual Type? extendedType => unit.anythingDeclaration.type;
    shared actual String name => type.string;
    shared actual Integer? qualifier => null;
    shared actual String qualifiedName => type.qualifiedString;
    shared actual Declaration? refinedDeclaration => null;
    shared actual Type? selfType => null;

    shared actual Boolean isActual => false;
    shared actual Boolean isAnnotation => false;
    shared actual Boolean isAnonymous => false;
    shared actual Boolean isDefault => false;
    shared actual Boolean isDeprecated => false;
    shared actual Boolean isFinal => false;
    shared actual Boolean isFormal => false;
    shared actual Boolean isNamed => true;
    shared actual Boolean isSealed => false;
    shared actual Boolean isShared => false;
    shared actual Boolean isStatic => false;

    shared actual
    Nothing canEqual(Object other) {
        throw AssertionError("intersection types don't have well-defined equality");
    }

    shared actual
    Nothing container {
        throw AssertionError("intersection types don't have containers.");
    }

    shared actual
    Boolean inherits(TypeDeclaration that)
        =>  that.isAnything || satisfiedTypes.any((st) => st.declaration.inherits(that));

    shared actual
    Type type
        =>  if (!nonempty satisfiedTypes) then
                unit.anythingDeclaration.type
            else if (satisfiedTypes.size == 1) then
                satisfiedTypes[0]
            else super.type;

    "Apply the distributive rule X&(Y|Z) == X&Y|X&Z to simplify the intersection to a
     canonical form with no parens. The result is a union of intersections, instead of
     an intersection of unions."
    shared
    TypeDeclaration canonicalized {
        if (!nonempty satisfiedTypes) {
            return unit.anythingDeclaration;
        }
        // JV: what's the purpose of this? Why do we care about the size?
        if (satisfiedTypes.size == 1 && satisfiedTypes[0].isExactlyNothing) {
            return unit.nothingDeclaration;
        }

        if (exists satisfiedUnion = satisfiedTypes.find(Type.isUnion)) {
            value unionSet = HashSet<Type>();
            for (caseType in satisfiedUnion.caseTypes) {
                value intersectionSet = HashSet<Type>();
                for (satisfiedType in satisfiedTypes) {
                    if (satisfiedType == satisfiedUnion) {
                        addToIntersection(intersectionSet, caseType, unit);
                    }
                    else {
                        addToIntersection(intersectionSet, satisfiedType, unit);
                    }
                }
                value it = canonicalIntersection(intersectionSet, unit);
                addToUnion(unionSet, it);
            }
            return UnionType {
                unionSet.sequence();
                unit;
            };
        }
        return this;
    }

    shared actual
    String string
        =>  name;
}
