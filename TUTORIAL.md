# Tutorial

This tutorial will describe the basic usage of the tool, the RubyBreaker
Type Annotation Language, and the RubyBreaker Type System.

## Usage

RubyBreaker takes advantage of test cases that already come with the source
program.  It is recommended that RubyBreaker is run as a Rake task, which
does require a minimum change in the Rakefile (but no code change in the
source program) but is better for a long-term maintenance. Regardless of the
mode you choose to run, no source code change is required. 

Let us briefly see how RubyBreaker can be run directly as a command-line
program to understand the overall concept of the tool. We will explain how
to use RubyBreaker in a Rakefile later.

    $ rubybreaker -v -s -l lib.rb -b A,B prog.rb

The above command runs RubyBreaker in verbose mode (`-v`) and will display
the output on the screen (`-s`). Before RubyBreaker runs `prog.rb`, it will
import (`-l`) `lib.rb` and instrument (`-b`) classes `A` and `B`.
Here is `lib.rb`:

    class A
      def foo(x)
        x.to_s
      end
    end
    class B
      def bar(y,z)
        y.foo(z)
      end
    end

And, `prog.rb` simply imports the library file and executes it:

    require "lib"
    A.new.foo(1)

This example will show how `A#foo` method is given a type by RubyBreaker.
After running the command shown above, the following output will be
generated and displayed on the screen:

    class A
      typesig("foo(fixnum[to_s]) -> string")
    end

Here, the `typesig` method call registers `foo` as a method type that takes
an object that has `Fixnum#to_s` method and returns a `String`. This
method is made available simply by importing `rubybreaker`.  Now, assume
that an additional code, `B.new.bar(A.new,1)`, is added at the end of
`prog.rb`. The subsequent run will generate the following result:

    class A
      typesig("foo(fixnum[to_s]) -> string")
    end
    class B
      typesig("bar(a[foo], fixnum[to_s]) -> string")
    end

Keep in mind that RubyBreaker is designed to gather type information based
on the _actual_ execution of the source program. This means the program
should be equipped with test cases that have a reasonable program path
coverage.  Additionally, RubyBreaker assumes that test runs are correct and
the program behaves correctly (for those test runs) as intended by the
programmer. This assumption is not a strong requirement, but is necessary to
obtain precise and accurate type information. 

### Using Ruby Unit Testing Framework

Instead of manually inserting the entry point indicator in the source
program, you can take advantage of Ruby's built-in testing framework. This
is preferred to modifying the source program directly, especially for the
long term program maintainability. But no worries! This method is as simple
as the previous one.

    require "test/unit"
    require "rubybreaker" # This should come after test/unit.
    class TestClassA < Test::Unit::TestCase
      def setup()
         RubyBreaker.break(Class1, Class2, ...)
         ...
      end
      # ...tests!...
    end

That's it! The only requirements are to indicate to RubyBreaker which modules
and classes to "break" and to place `require rubybreaker` _after_
`require test/unit`.

### Using RSpec

The requirement is same for RSpec but use `before` instead of `setup` to
specify which modules and classes to "break".

    require "rspec"
    require "rubybreaker"

    describe "TestClassA Test"
      before { RubyBreaker.break(Class1, Class2, ...) }
      ...
      # ...tests!...
    end

### Using Rakefile

By running RubyBreaker along with the Rakefile, you can avoid modifying the
source program at all. (You no longer need to import `rubybreaker` in the
test cases neither.) Therefore, this is the recommended way to use
RubyBreaker.  The following code snippet describes how it can be done:

    require "rubybreaker/task"
    ...
    desc "Run RubyBreaker"
    Rake::RubyBreakerTestTask.new(:"rubybreaker") do |t|
      t.libs << "lib" 
      t.test_files = ["test/foo/tc_foo1.rb"]
      # ...Other test task options..
      t.rubybreaker_opts << "-v"               # run in verbose mode
      t.break = ["Class1", "Class2", ...]  # specify what to monitor
    end

Note that `RubyBrakerTestTask` can simply replace your `TestTask` block in
Rakefile. In fact, the former is a subclass of the latter and includes all
features supported by the latter. The only additional options are
`rubybreaker_opts` which is RubyBreaker's command-line options and
`break` which specifies which modules and classes to monitor.  Since
`Class1` and `Class2` are not _recognized_ by this Rakefile, you must use
string literals to specify modules and classes (and with full namespace). 

If this is the route you are taking, there needs no editing of the source
program whatsoever. This task will take care of instrumenting the specified
modules and classes at proper moments.

## Type Annotation

The annotation language used in RubyBreaker resembles the method
documentation used by Ruby Core Library Doc. Each type signature
defines a method type using the name, argument types, block type, and return
type. But, let us consider a simple case where there is one argument type
and a return type. 

    class A
      ...
      typesig("foo(fixnum) -> string")
    end

In RubyBreaker, a type signature is recognized by the meta-class level
method `typesig` which takes a string as an argument.  This string is the
actual type signature written in the Ruby Type Annotation Language. This
language is designed to reflect the common documentation practice used by
Ruby Core Library Doc. It starts with the name of the method. In the
above example, `foo` is currently being given a type. The rest of the
signature takes a typical method type symbol, `(x) -> y` where `x` is the
argument type and `y` is the return type. In the example shown above, the
method takes a `Fixnum` object and returns a `String` object. Note that
these types are in lowercase, indicating they are objects and not modules or
classes themselves.

There are several types that represent an object: nominal, duck, fusion,
nil, 'any', 'or', optional, variable-length, and block. Each type signature
itself represents a method type or a method list type (explained below). 

### Nominal Type

This is the simplest and most intuitive way to represent an object. For
instance, `fixnum` is an object of type `Fixnum`. Use lower-case letters and
underscores instead of _camelized_ name. `MyClass`, for example would be
`my_class` in RubyBreaker type signatures. There is no particular
reason for this convention other than it is the common practice used in
RubyDoc. Use `/` to indicate the namespace delimiter `::`. For example,
`NamspaceA::ClassB` would be represented by `namespace_a/class_b` in
a RubyBreaker type signature.

### Self Type

This type is similar to the nominal type but is referring to the current
object--that is, the receiver of the method being typed. RubyBreaker will
auto-document the return type as a self type if the return value is the same
as the receiver of that call. It is also recommended to use this type over
a nominal type (if the return value is `self`) since it depicts more
precise return type.

### Duck Type

This type is inspired by the Ruby Language's duck typing, _"if it
walks like a duck and quacks like a duck, it must be a duck."_ Using this
type, an object can be represented simply by a list of method names. For
example `[walks, quacks]` is an object that has `walks` and `quacks`
methods. Note that these method names do *not* reveal any type
information for themselves.

### Fusion Type

Duck type is very flexible but can be too lenient when trying to restrict
the type of an object. RubyBreaker provides a type called *the fusion type*
which lists method names but with respect to a nominal type. For
example, `fixnum[to_f, to_s]` represents an object that has methods `to_f`
and `to_s` whose types are same as those of `Fixnum`. This is more
restrictive (precise) than `[to_f, to_s]` because the two methods must have
the same types as `to_f` and `to_s` methods, respectively, in `Fixnum`.

### Nil Type

A nil type represents a value of nil and is denoted by `nil`.

### Any Type

RubyBreaker also provides a way to represent an object that is compatible with
any type. This type is denoted by `?`. Use caution with this type because
it should be only used for an object that requires an arbitrary yet most
specific type--that is, `?` is a subtype of any other type, but any
other type is not a subtype of `?`. This becomes a bit complicated for
method or block argument types because of their contra-variance
characteristic. Please refer to the section *Subtyping*.

### Or Type

Any above types can be "or"ed together, using `||`, to represent an object
that can be either one or the other. It _does_ not represent an object that
has to be both (which is not supported by RubyBreaker).

### Optional Argument Type and Variable-Length Argument Type

Another useful features of Ruby are the optional argument type and the
variable-length argument type. The former represents an argument that has a
default value (and therefore does not have to be provided). The latter
represents zero or more arguments of the same type. These are denoted by
suffices, `?` and `*`, respectively.

### Block Type

One of the Ruby's prominent features is the block argument. It allows
the caller to pass in a piece of code to be executed inside the callee. This
code block can be executed by the Ruby construct, `yield`, or by directly
calling the `call` method of the block object. In RubyBreaker, this type can
be respresented by curly brackets. For instance, `{|fixnum,string| ->
string}` represents a block that takes two arguments--one `Fixnum` and one
`String`--and returns a `String`. 

RubyBreaker does supports nested blocks as Ruby 1.9 finally allows them.
However, *keep in mind* that RubyBreaker *cannot* automatically document the
block types due to `yield` being a language construct rather than a method,
which means it cannot be captured by meta-programming!

### Method Type and Method List Types

Method type is similar to the block type, but it represents an actual method
and not a block object. It is the "root" type that the type annotation
language supports, along with method list types. Method _list_ type is a
collection of method types to represent more than one type information for
the given method. Why would this type be needed? Consider the following Ruby
code:

    def foo(x)
      case x
      when Fixnum
        1
      when String
        "1"
      end
    end

There is no way to document the type of `foo` without using a method list
type. Let's try to give a method type to `foo` without a method list. The
closest we can come up with would be `foo(fixnum or string) -> fixnum and
string`. But RubyBreaker does not have the "and" type in the type annotation
language because it gives me an headache! (By the way, it needs to be an
"and" type because the caller must handle both `Fixnum` and `String` return
values.) 

It is a dilemma because Ruby programmers actually enjoy using this kind of
dynamic type checks in their code. To alleviate this headache, RubyBreaker
supports the method list type to represent different scenarios depending on
the argument types. Thus, the `foo` method shown above can be given the
following method list type:

    typesig("foo(fixnum) -> fixnum")
    typesig("foo(string) -> string")

These two type signatures simply tell RubyBreaker that `foo` has two method
types--one for a `Fixnum` argument and another for a `String` argument.
Depending on the argument type, the return type is determined. In this
example, a `Fixnum` is returned when the argument is also a `Fixnum` and a
`String` is returned when the argument is also a `String`. When
automatically documenting such a type, RubyBreaker looks for the (subtyping)
compatibility between the return types and "promote" the method type to a
method list type by spliting the type signature into two (or more in
subsequent "promotions").

