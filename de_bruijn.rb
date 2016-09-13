require 'set'
require 'pry'
# create edge between the 2 k-1mers in this string
# e.g. string[1..k] and string[0..k-1]
# and create nodes for them if they don't already exist
# string, kmer
def de_bruijn(string, k)
  edges = []
  nodes = Set.new
  # from the beginning of the string to the last position where a kmer could start
  (0..(string.length - (k + 1))).each do |i|
    # represent edges as tuples
    # left and right k-1mers
    first_k1mer = string[i...(i + k-1)]
    second_k1mer = string[(i+1)...(i + k)]
    edges.push([first_kmer, second_kmer])

    # add kmers to graph as nodes if they don't already exist
    nodes.add first_k1mer
    nodes.add second_k1mer
  end
  [nodes, edges]
end

def load_data
  contents = File.read('coding_challenge_data_set.txt')
  # drop 1 because the first element will be ""
  @fragment_array = contents.delete("\r\n").split(/>Rosalind_\d{4}/).drop(1)
end

class Node
  attr_accessor :km1mer, :number_of_incoming_edges, :number_of_outgoing_edges
  def initialize km1mer
    self.km1mer = km1mer
    self.number_of_incoming_edges = 0
    self.number_of_outgoing_edges = 0
  end

  def is_semi_balanced
    (self.number_of_incoming_edges - self.number_of_outgoing_edges).abs == 1
  end

  def is_balanced
    self.number_of_incoming_edges == self.number_of_outgoing_edges
  end

  def hash
    self.km1mer.hash
  end

  def eql?(b)
    self.hash == b.hash
  end

  def string
    self.km1mer
  end
end

class Graph
  attr_accessor :nodes, :graph

  def initialize(k)
    # multimap from Nodes to neighbors

    # fixes empty self.graph:
    # http://stackoverflow.com/questions/2698460/strange-behavior-when-using-hash-default-value-e-g-hash-new
    self.graph = Hash.new { |h, k| h[k] = [] }

    # maps k1mers to Node objects
    self.nodes = {}
    @k = k
  end

  def reads
    contents = File.read('coding_challenge_data_set.txt')
    # drop 1 because the first element will be ""
    contents.delete("\r\n").split(/>Rosalind_\d{4}/).drop(1)
  end

  def execute
    fill
    tally
  end

  def chop string
   (0..(string.length - (@k + 1))).each do |i|
     kmer = string[i...(i + @k)]
     km1L = string[i...(i + @k-1)]
     km1R = string[(i + 1)...(i + @k)]
     yield kmer, km1L, km1R
   end
  end

  def fill
    reads.each do |read|
      # why did we need to calculate kmer here?
      chop(read) do |kmer, km1L, km1R|
        nodeL, nodeR = nil, nil
        # find or create left node
        if self.nodes.include? km1L
          nodeL = self.nodes[km1L]
        else
          nodeL = self.nodes[km1L] = Node.new(km1L)
        end

        # find or create right node
        if self.nodes.include? km1R
          nodeR = self.nodes[km1R]
        else
          nodeR = self.nodes[km1R] = Node.new(km1R)
        end

        # increment node in/out counts
        nodeL.number_of_incoming_edges += 1
        nodeL.number_of_outgoing_edges += 1

        self.graph[nodeL] << nodeR

        # set default value of self.graph hash/dictionary?
        # self.G.setdefault(nodeL, []).append(nodeR)
      end
    end
  end

  attr_accessor :number_of_balanced_nodes,
    :number_of_semi_balanced_nodes,
    :number_of_unbalanced_nodes,
    :head,
    :tail

  def tally
    # Iterate through nodes and tally how many are balanced,
    # semi-balanced, or neither
    self.number_of_balanced_nodes = 0
    self.number_of_semi_balanced_nodes = 0
    self.number_of_unbalanced_nodes = 0
    # Keep track of head and tail nodes in the case of a graph with
    # Eularian path (not cycle)
    self.head = nil
    self.tail = nil

    self.nodes.each do |key, node|
      if node.is_balanced
        self.number_of_balanced_nodes += 1
      elsif node.is_semi_balanced
        if node.number_of_incoming_edges == node.number_of_outgoing_edges + 1
          self.tail = node
        end

        if node.number_of_incoming_edges == node.number_of_outgoing_edges - 1
          self.head = node
        end

        self.number_of_semi_balanced_nodes += 1
      else
        self.number_of_unbalanced_nodes += 1
      end
    end
  end
end



KMER_LENGTH = 500

def build_de_graph
  @data = load_data
  @nodes = Set.new
  @edges = []
  @data.each do |fragment_string|
    nodes, edges = de_bruijn(fragment_string, KMER_LENGTH)
    @nodes += nodes
    @edges += edges
  end
end

g = Graph.new(500)
g.fill
binding.pry

# def naive
#   data = load_data
# end

# # http://en.wikibooks.org/wiki/Algorithm_Implementation/Strings/Longest_common_substring#Ruby
# def find_longest_common_substring(s1, s2)
#   if (s1 == "" || s2 == "")
#     return ""
#   end
#   m = Array.new(s1.length){ [0] * s2.length }
#   longest_length, longest_end_pos = 0,0
#   (0 .. s1.length - 1).each do |x|
#     (0 .. s2.length - 1).each do |y|
#       if s1[x] == s2[y]
#         m[x][y] = 1
#         if (x > 0 && y > 0)
#           m[x][y] += m[x-1][y-1]
#         end
#         if m[x][y] > longest_length
#           longest_length = m[x][y]
#           longest_end_pos = x
#         end
#       end
#     end
#   end
#   return s1[longest_end_pos - longest_length + 1 .. longest_end_pos]
# end

