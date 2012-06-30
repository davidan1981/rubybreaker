require "test/unit"
require_relative "../../lib/rubybreaker"

class IntegratedSimpleAlgorithmsTest < Test::Unit::TestCase
  include RubyBreaker

  #
  # This class contains the Ruby code from Program 2.x of
  # "Data Structures and Algorithms
  # with Object-Oriented Design Patterns in Ruby"
  # by Bruno R. Preiss.
  #
  # Copyright (c) 2004 by Bruno R. Preiss, P.Eng.  All rights reserved.
  #
  # http://www.brpreiss.com/books/opus8/
  #
  class Opus8
    def sum(n)
        result = 0
        i = 1
        while i <= n
            result += i
            i += 1
        end
        return result
    end

    def horner(a, n, x)
      result = a[n]
      i = n - 1
      while i >= 0
        result = result * x + a[i]
        i -= 1
      end
      return result
    end

    def findMaximum(a, n)
      result = a[0]
      i = 1
      while i < n
        if a[i] > result
            result = a[i]
        end
        i += 1
      end
      return result
    end

    def fibonacci(n)
      if n == 0 or n == 1
          return n
      else
          return fibonacci(n - 1) + fibonacci(n - 2)
      end
    end

    def bucketSort(a, n, buckets, m)
      for j in 0 ... m
          buckets[j] = 0
      end
      for i in 0 ... n
          buckets[a[i]] += 1
      end
      i = 0
      for j in 0 ... m
          for k in 0 ... buckets[j]
              a[i] = j
              i += 1
          end
      end
    end
  end

  class Ref
    typesig("fibonacci(fixnum[==]) -> fixnum")
    typesig("fibonacci(fixnum[==,-]) -> fixnum")
    def fibonacci(n); n end
  end

  def setup()
    Runtime.break(Opus8)
  end

  def test_sum
    opus8 = Opus8.new
    result = opus8.sum(5)
    sum_meth_type = Runtime::Inspector.inspect_meth(Opus8, :sum)
    str = sum_meth_type.unparse()
    assert_equal("sum(fixnum[]) -> fixnum", str)
    assert_equal(15, result)
  end

  def test_horner()
    opus8 = Opus8.new
    result = opus8.horner([1,2,3],2,2)
    horner_meth_type = Runtime::Inspector.inspect_meth(Opus8, :horner)
    str = horner_meth_type.unparse()
    assert_equal("horner(array[[]], fixnum[-], fixnum[]) -> fixnum", str)
    assert_equal(1 + 4 + 12, result)
  end

  def test_findMaximum()
    opus8 = Opus8.new
    result = opus8.findMaximum([1,4,3,2], 4)
    max_meth_type = Runtime::Inspector.inspect_meth(Opus8, :findMaximum)
    str = max_meth_type.unparse()
    assert_equal("findMaximum(array[[]], fixnum[]) -> fixnum", str)
    assert_equal(4, result)
  end

  def test_fibonacci()
    opus8 = Opus8.new
    result = opus8.fibonacci(4)
    fib_meth_type = Runtime::Inspector.inspect_meth(Opus8, :fibonacci)
    fib_ref_meth_type = Runtime::Inspector.inspect_meth(Ref, :fibonacci)
    str = fib_meth_type.unparse()
    # puts fib_meth_type.class
    assert_equal("fibonacci(fixnum[-, ==]) -> fixnum", str)
    assert_equal(3, result)
  end

  def test_bucket_sort()
    opus8 = Opus8.new
    array = [5, 1, 3, 7, 11, 9]
    bucket = []
    opus8.bucketSort(array, 6, bucket, 12)
    sort_meth_type = Runtime::Inspector.inspect_meth(Opus8, :bucketSort)
    str = sort_meth_type.unparse()
    assert_equal("bucketSort(array[[], []=], fixnum[], array[[], []=], fixnum[]) -> range", str)
    assert_equal([1, 3, 5, 7, 9, 11], array)
  end

end
