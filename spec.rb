require 'minitest/autorun'
require 'pry'
require_relative 'de_bruijn'

describe Graph do
  before do
    @graph = Graph.new(5, test: true)
  end

  describe '#chop' do
    it 'responds to #chop' do
      assert @graph.respond_to?(:chop)
    end

    it 'returns kmers covering the entire string' do
      kmers = []
      string = "thequicklazydog"
      iterator = @graph.chop(string) do |kmer, _km1L, _km1R|
        kmers << kmer
      end

      first_kmer = kmers.shift
      final_letters = kmers.map{ |kmer| kmer[-1]}
      reassembled_result = first_kmer + final_letters.join('')

      assert_equal reassembled_result, string
    end

    it 'returns correct left and right km-1ers' do
      string = "thequicklazydog"
      km1Ls = []
      km1Rs = []
      kmers = []
      @graph.chop(string) do |kmer, km1L, km1R|
        kmers << kmer
        km1Ls << km1L
        km1Rs << km1R
      end

      assert_equal kmers.first, 'thequ'
      assert_equal km1Ls.first, 'theq'
      assert_equal km1Rs.first, 'hequ'

      assert_equal kmers.last, 'zydog'
      assert_equal km1Ls.last, 'zydo'
      assert_equal km1Rs.last, 'ydog'
    end
  end
end
