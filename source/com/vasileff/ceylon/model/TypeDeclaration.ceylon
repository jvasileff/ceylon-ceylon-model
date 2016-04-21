import ceylon.collection {
    MutableSet,
    HashSet
}
import com.vasileff.ceylon.model.internal {
    eq
}

shared abstract
class TypeDeclaration()
        of ClassOrInterface | Constructor | IntersectionType | NothingDeclaration
            | TypeAlias | TypeParameter | UnionType | UnknownType
        extends Declaration()
        satisfies Generic {

    "The class or constructor extended by a class, the
     type aliased by a class or interface alias, or the
     class Anything for any other type."
    shared formal Type? extendedType;

    shared formal [Type*] satisfiedTypes;
    shared formal [Type*] caseTypes;
    shared formal [Value*] caseValues;
    shared formal Type? selfType;
    shared formal Boolean isSealed;
    shared formal Boolean isFinal;
    shared formal Boolean inherits(TypeDeclaration that);

    shared default
    Boolean isSelfType => false;

    shared default
    Boolean isAlias => false;

    shared actual default
    {TypeParameter*} typeParameters
        =>  { for (member in members.items)
                if (is TypeParameter member)
                  member };

     "The type of the declaration as seen from within the  body of the declaration itself.

      Note that for certain special types which we happen to know don't have type
      arguments, we use this as a convenience method to quickly get a produced type for
      use outside the body of the declaration, but this is
      not really correct!"
    shared default
    Type type
        =>  createType {
                declaration = this;
                qualifyingType = memberContainerType;
                typeArguments = typeParametersAsArguments;
            };

    shared
    Type appliedType(
            Type? qualifyingType,
            {Type?*} typeArguments,
            Map<TypeParameter, Variance> varianceOverrides = emptyMap)
        =>  createType {
                declaration = this;
                qualifyingType = qualifyingType;
                typeArguments = aggregateTypeArguments {
                    qualifyingType;
                    this;
                    typeArguments;
                };
                varianceOverrides = varianceOverrides;
            };

    shared
    {TypeDeclaration*} supertypeDeclarations
        =>  collectSupertypeDeclarations {
                HashSet<TypeDeclaration> { unit.anythingDeclaration };
            };

    MutableSet<TypeDeclaration> collectSupertypeDeclarations
            (results = HashSet<TypeDeclaration>()) {

        MutableSet<TypeDeclaration> results;
        switch (self = this)
        case (is ClassDefinition | InterfaceDefinition) {
            if (!results.contains(this)) {
                results.add(this);
                extendedType?.declaration?.collectSupertypeDeclarations(results);
                satisfiedTypes.map(Type.declaration).each((d)
                    =>  d.collectSupertypeDeclarations(results));
            }
        }
        case (is TypeParameter | IntersectionType) {
            satisfiedTypes.map(Type.declaration).each((d)
                =>  d.collectSupertypeDeclarations(results));
        }
        case (is UnionType) {
            // Copied note: actually the loop is unnecessary, we only need to consider
            // the first case
            if (exists first = caseTypes.first) {
                value candidates
                    =   first.declaration.collectSupertypeDeclarations(results);
                results.addAll(candidates.filter(not(results.contains)).filter(inherits));
            }
        }
        case (is Constructor | ClassAlias | InterfaceAlias | TypeAlias) {
            extendedType?.declaration?.collectSupertypeDeclarations(results);
        }
        case (is NothingDeclaration) {
            throw AssertionError("supertypeDeclarations not supported for Nothing type");
        }
        case (is UnknownType) {
            // ignore
        }
        return results;
    }

    shared
    {Type*} extendedAndSatisfiedTypes
        =>  if (exists et = extendedType)
            then satisfiedTypes.follow(et)
            else satisfiedTypes;

    "The intersection of the types inherited by this declaration. No need to worry
     about canonicalization because:

     1. an inherited type can't be a union, and
     2. they are prevented from being disjoint types."
    shared
    Type intersectionOfSupertypes
        =>  IntersectionType {
                extendedAndSatisfiedTypes.sequence();
                unit;
            }.type;

    "implement the rule that `Foo & Bar == Nothing` if
     here exists some enumerated type `Baz` with

         Baz of Foo | Bar

     (the intersection of disjoint types is empty)"
    shared
    Boolean isDisjoint(TypeDeclaration that) {
        function isDisjointFrom(TypeDeclaration satisfiedDeclaration) {
            // for all the cases of a type we satisfy
            for (i->caseType in satisfiedDeclaration.caseTypes.indexed) {
                // if there is a case that matches this
                if (caseType.declaration == this) {
                    for (j->otherCaseType in satisfiedDeclaration.caseTypes.indexed) {
                        // if it inherits one of the others, it's disjoint
                        if (i != j && that.inherits(otherCaseType.declaration)) {
                            return true;
                        }
                    }
                    break;
                }
            }
            // if 'this' satisfies a type that is disjoint from 'that', 'this' and
            // 'that' are disjoint
            return satisfiedDeclaration.isDisjoint(that);
        }

        if (this is ClassOrInterface
                && that is ClassOrInterface
                && this == that) {
            return false;
        }
        if (this is TypeParameter
                && that is TypeParameter
                && this == that) {
            return false;
        }
        if (extendedAndSatisfiedTypes
                .map(Type.declaration)
                .any(isDisjointFrom)) {
            return true;
        }
        return false;
    }

    ///////////////////////////////////
    //
    // Utilities
    //
    ///////////////////////////////////

    shared
    Boolean isAnything
        =>  eq(qualifiedName, "ceylon.language::Anything");

    shared
    Boolean isEntry
        =>  eq(qualifiedName, "ceylon.language::Entry");

    shared
    Boolean isNothing
        =>  eq(qualifiedName, "ceylon.language::Nothing");

    shared
    Boolean isNull
        =>  eq(qualifiedName, "ceylon.language::Null");

    shared
    Boolean isNullValue
        =>  eq(qualifiedName, "ceylon.language::null");

    shared
    Boolean isObject
        =>  eq(qualifiedName, "ceylon.language::Object");

    // TODO Look at model's isTupleType and isTuple, and all refinements.
    //      Make sure we're using the right methods everywhere.
    shared
    Boolean isTuple
        =>  eq(qualifiedName, "ceylon.language::Tuple");
}
