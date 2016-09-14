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
  end
end
