require 'minitest/autorun'
require_relative 'de_bruijn'

class DnaTest < Minitest::Test
  def setup
    dna = "ACGCGTCG"
    kmer = 3
    @nodes, @edges = de_bruijn(dna, kmer)
  end

  def test_that_it_returns_correct_datatypes
    assert_equal @nodes.class, Set
    assert_equal @edges.class, Array
  end

  def test_that_it_generates_tuples
    assert_equal 2, @nodes.first.length
  end
end
