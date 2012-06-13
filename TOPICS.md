# Advanced Topics

## RubyBreaker Type System

RubyBreaker comes with its own type system to auto-document the type
information. Each method in a "breakable" module is dynamically instrumented
to be monitored during runtime. This monitoring code observes the types of
the arguments, block, and return value of each method. Once type information
for a method is gathered, RubyBreaker will compare it to the information
gathered so far for the method.  If these two method types are
"compatiable", RubyBreaker will choose more general type from the two.

If two method types are not "compatible", RubyBreaker will "promote" the
method type to a method list type to accommodate more than one
"incompatible" types. Let's first understand what RubyBreaker considers two
types as "compatible".

### Subtyping and Subclassing

RubyBreaker uses _subtyping_ to determine two "compatible" method types,
which holds true if one is subtype or supertype of another. It chooses
the supertype of the two for the method because the objective is to find (1)
the most general type of the two and (2) the least general type that can
handle both.  Note that, if the objective (2) is not required, we can
always use the most general method type:

    (?*) -> basic_object

A method of this type takes any number of any objects and returns a
`BasicObject`. But this is _too_ general to use for type documetation.
Instead, we want to find the most specific general type possible (and
therefore, the least upper bound of the types observed for the method). 

For simplicity (and practicality), RubyBreaker uses _subclassing_ to
determine subtyping for nominal types. For instance, `Fixnum` is considered
subtype of `Numeric` because the former is subclass of the latter. However,
keep in mind this is not necessarily true in the true subtyping theory
because some methods in the former override the counterparts in the latter,
resulting in different types that no longer hold the subtyping relationship.

If a method has some type information either from the manual documentation
or from the current documentation process, this information will be used
in addition to subclassing. For example, consider method types
`foo(class1[to_s]) -> string` and `foo(class2[to_s]) -> string`. Let's also
assume that classes `Class1` and `Class2` are being auto-documented. The
method `foo` will have the type `foo(class1[to_s])` if `Class1#to_s` is a
subtype of `Class2#to_s`. (The direction is not mistaken, it is due to the
contra-variant property of a method argument.) If these classes are neither
being auto-documented nor manaully documented, this holds only if `Class1`
is subclass of `Class2`.

## Writing a Custom Type System

_Coming soon_

