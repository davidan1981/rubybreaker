* * *

# Introduction

RubyBreaker is a dynamic type documentation tool written purely in Ruby. It
provides the framework for dynamically instrumenting a Ruby program to
monitor objects during executions and document the observed type
information. The type documentation generated by RubyBreaker is also an
executable Ruby code. It contains type signatures that can be interpreted by
RubyBreaker Runtime Library and can be used in future documentation of the
program.

The primary goal of RubyBreaker is to assign a type signature to every
method in designated modules and classes.  A type signature is written in
the RubyBreaker Type Annotation Language which resembles the documentation
style used in RubyDoc. Overall, this tool should help Ruby programmers
document their code more rigorously and effectively.  Currently, manual
modification of the user program is required to run RubyBreaker, but this is
kept minimal. 

## Limitations

* It only works on toy Ruby programs so far :)
* Block argument cannot be auto-documented. (Inherent)
* Manual modification (minimal) of code is required.
* No parametric polymorphic types are supported. 

## Requirements

Ruby 1.9.x and TreeTop 1.x

If the most recent Ruby 1.9 is installed on the computer, it will probably
work. If TreeTop is not installed, use RubyGems or download from the
following URL: [TreeTop](http://treetop.rubyforge.org/)

## Installation

It is as simple as running the following:

    $ gem install rubybreaker

You probably want to test out your installation by running
`rake test` in your RubyBreaker directory:

    $ rake test

* * *

# Tutorial

This tutorial will describe the basic usage of the tool, the RubyBreaker
Type Annotation Language, and the RubyBreaker Type System.

## Usage

There are two ways to use RubyBreaker:

    $ rubybreaker prog.rb
   
Or, use it as a Ruby library and just run the program on Ruby.

    $ ruby prog.rb

Both methods require manual modification of the code, but the former will
generate the output into a separate `.rubybreaker` file whereas the latter
will display the output on the screen. The former will also automatically
import the `.rubybreaker` file for the user program of which the output is
appended at the end. Consequently, this output/input file will grow as more
analysis is done on the program. 

For example, let us assume `prog.rb` as the following:

    require "rubybreaker"
    class A
      include RubyBreaker::Breakable
      def foo(x)
        x.to_s
      end
    end
    class B
      # include RubyBreaker::Breakable
      def bar(y,z)
        y.foo(z)
      end
    end
    RubyBreaker.monitor()
    A.new.foo(1)

Do not worry about other parts of the code for now. This example is to show
how `foo` method is *typed* by RubyBreaker.  After running `rubybreaker
prog.rb`, the following output will be generated and saved into
`prog.rubybreaker`.

    require "rubybreaker"
    class A
      include RubyBreaker::Broken
      typesig("foo(fixnum[to_s]) -> string")
    end

Now, assume that the last line of `prog.rb` is changed to
`B.new.bar(A.new,1)` and the `include` command in class `B` is uncommented.
The subsequent analysis will generate the following result:

    # This is auto-generated by RubyBreaker
    require "rubybreaker"
    class A
      include RubyBreaker::Broken
      typesig("foo(fixnum[to_s]) -> string")
    end
    class B
      include RubyBreaker::Broken
      typesig("bar(a[foo], fixnum[to_s]) -> string")
    end

RubyBreaker is designed to gather type information based on the actual
execution of a program. This means the program should be equipped with
test suites that cover a reasonable number of program paths for accurate
results. Additionally, RubyBreaker assumes that test runs are correct
and the program behaves correctly (for the test runs) as intended by
the programmer. This assumption is not a strong requirement, but is
necessary to obtain precise type information. 

In order to use RubyBreaker, there needs two kinds of manual code changes.
First, the user must indicate which modules are subject to analysis and
which modules can be used for the analysis. Next, the user has to indicate
where the entry point of the program is. Alternatively, he has to make a
small change to the test cases to use RubyBreaker's testing framework.

### Breakable and Broken

In order to indicate modules and classes that already have type information
or to designate those that need to be auto-documented, the user must be
familiar with the two most important modules of RubyBreaker--`Breakable` and
`Broken`. The former refers to a module (or a class) that needs dynamic
instrumentation and monitoring for getting type information. The latter
refers to a module that have type information already documented in type
signature form.

For example, consider the following Ruby code:

    require "rubybreaker"
    class A
      include RubyBreaker::Breakable
      def foo(x)
        x.to_s
      end
    end

By including `Breakable`, class `A` is subject to dynamic instrumentation
and monitoring. On the other hand, the following class is a `Broken` module.
(Yes, like a crazy wild horse that has been _broken_!)

    require "rubybreaker"
    class B
      include RubyBreaker::Broken
      typesig("bar(fixnum[to_s]) -> string")
      def foo(x)
        x.to_s
      end
    end

This tells RubyBreaker that class `B` has type information in place, and
therefore, it will use the information for analyzing `Breakable` modules
elsewhere (if applicable). In this example, a method `foo` has a type
signature `bar(fixnum[to_s]) -> string`, which means it takes an object that
has `Fixnum`'s `to_s` method and returns a string. More detail on the type
annotation language will be explained in later section.

Currently, both `Breakable` and `Broken` only support instance methods.
Furthermore, class and module methods can neither be monitored nor used for
analysis. It is important to keep in mind that `Broken` module always wins.
In other words, if a module is declared as both `Broken` and `Breakable`, it
is treated as `Broken`.

### Program Entry Point

In Ruby, as soon as a file is `require`d, the execution of that file begins.
For RubyBreaker, however, it is not trivial to find the actual starting
point of the program because there *has* to be a clear point in time at
which monitoring of `Breakable` modules begins. *This is necessary as
attempting to instrument and monitor at the same time will cause an infinite
loop!* 

Indicating the program entry point is simply done by inserting the following
line at the code (assuming "`require 'rubybreaker'`" is already placed at
the top of the file):

    RubyBreaker.monitor()

It basically tells RubyBreaker to start monitoring. What really happens at
this point is that all `Breakable` modules are dynamically instrumented so
that they are ready to be monitored. Any execution after this point will
run the instrumented code (for `Breakable` modules) which will gather type
information for methods.

Although this seems simple and easy, this is not the recommended way for
analyzing a program. Why? Because RubyBreaker has a built-in testing
framework that (supposedly :)) works seemlessly with the existing tests of
the program.

### Using RubyBreaker Testing Framework

Instead of manually inserting the entry point indicator into the program,
the user can take advantage of the Ruby Unit Test framework. This is the
recommended way of using RubyBreaker, especially for a long term program
maintainability. But no worries! This method is as simple as the previous
one.

    require "rubybreaker"
    require "test/unit"
    class TestClassA < Test::Unit::TestCase
      include RubyBreaker::TestCase
      # ...tests!...
    end

That's it! 

Currently, RubyBreaker only supports the standard unit test framework.
Other testing frameworks such as RSpec and Cucumber are not supported at the
moment (but will be in future/hopefully).

## Type Annotation

The annotation language used in RubyBreaker resembles the method
documentation used by Ruby Standard Library Doc. Each type signature
defines a method type using the name, argument types, block type, and return
type. But, let us consider a simple case where there is one argument type
and a return type. 

    class A
      ...
      typesig("foo(fixnum) -> string")
    end

In RubyBreaker, a type signature is recognized by the meta-class level
method `typesig` which takes a string as an argument. This string is the
actual type signature written in the Ruby Type Annotation Language. This
language is designed to reflect the common documentation practice used by
RubyDoc. It starts with the name of the method. In the above example, `foo`
is currently being given a type. The rest of the signature takes a typical
method type symbol, `(x) -> y` where `x` is the argument type and `y` is the
return type. In the example shown above, the method takes a `Fixnum` object
and returns a `String` object. Note that these types are in lowercase,
indicating they are objects and not modules or classes themselves.

There are several types that represent an object: nominal, duck, fusion,
nil, 'any', and block. Each type signature itself represents a method type
or a method list type (explained below). 

### Nominal Type

This is the simplest and most intuitive way to represent an object. For
instance, `fixnum` is an object of type `Fixnum`. Use lower-case letters and
underscores instead of _camelized_ name. `MyClass`, for example would be
`my_class` in RubyBreaker type signatures. There is no particular
reason for this convention other than it is the common practice used in
RubyDoc. 

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
characteristic. Please kefer to the section *Subtyping*.

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

### Optional Argument Type and Variable-Length Argument Type

Another useful features of Ruby are the optional argument type and the
variable-length argument type. The former represents an argument that has a
default value (and therefore does not have to be provided). The latter
represents zero or more arguments of the same type. These are denoted by
suffices, `?` and `*`, respectively.

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

## Type System

RubyBreaker comes with its own type system that is used to document type
information. This section describes how RubyBreaker determines which type(s)
to document. *More documentation coming soon...*

### Subtyping

*Documentation coming soon...*

### Subtyping vs. Subclassing

*Documentation coming soon...*

### Pluggable Type System (Advanced)

Yes, RubyBreaker was designed with the replaceable type system in mind. In
other words, anyone can write his own type system and plug it into
RubyBreaker.

*Documentation coming soon...*

* * *

# Acknowledgment

The term, "Fusion Type," is first coined by Professor Michael W. Hicks at
University of Maryland and represents an object using a structural type with
respect to a nominal type. 

* * *

# Copyright
Copyright (c) 2012 Jong-hoon (David) An. All Rights Reserved.
