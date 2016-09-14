require 'set'
require 'pry'

class Graph
  attr_accessor :nodes, :graph,:number_of_balanced_nodes,
    :number_of_semi_balanced_nodes, :number_of_unbalanced_nodes, :head, :tail

  def initialize k, test: false
    # multimap from Nodes to neighbors

    # fixes empty self.graph:
    # http://stackoverflow.com/questions/2698460/strange-
    # behavior-when-using-hash-default-value-e-g-hash-new
    self.graph = Hash.new { |h, k| h[k] = [] }

    # maps k1mers to Node objects
    self.nodes = {}
    @k = k
    @test = test
  end

  def execute
    fill
    tally
  end

  def find_working_k_value
    starting_k = @k

    until @k > 1000 do
      @k += 1
      initialize(@k)
      puts "testing k=#{@k}"
      fill
      tally
      if is_eulerian?
        binding.pry
      else
        puts stats
      end
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
        nodeL.number_of_outgoing_edges += 1
        nodeR.number_of_incoming_edges += 1

        self.graph[nodeL] << nodeR

        # set default value of self.graph hash/dictionary?
        # self.G.setdefault(nodeL, []).append(nodeR)
      end
    end
  end

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
      if node.is_balanced?
        self.number_of_balanced_nodes += 1
      elsif node.is_semi_balanced?
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

  def eulerian_path
    # return eulerian path or cycle
    raise 'not eulerian' if !is_eulerian?
    
    # skipping eulerian path implementation for now since I know there's a cycle
    @tour = []
    @graph = self.graph
    # select random starting node
    source = @graph.keys.sample
    visit source

    # not sure why reversing and dropping the beginning
    @tour.reverse!.shift

    @tour
  end

  def visit node
    connected_nodes = @graph[node]

    while connected_nodes.length > 0 do
      destination = connected_nodes.pop
      visit destination
    end

    @tour.push node
  end

  def chop string
   final_index = string.length - @k
   for i in 0..final_index do
     kmer = string[i...(i + @k)]
     km1L = string[i...(i + @k-1)]
     km1R = string[(i + 1)...(i + @k)]
     yield kmer, km1L, km1R
   end
  end

  def reads
    if @test
      contents = File.read('sample_data.txt')
      # drop 1 because the first element will be ""
      contents.delete("\r\n").split(/>Frag_\d{2}/).drop(1)
    else
      contents = File.read('coding_challenge_data_set.txt')
      # drop 1 because the first element will be ""
      contents.delete("\r\n").split(/>Rosalind_\d{4}/).drop(1)
    end
  end
  def number_of_nodes
    self.nodes.length
  end

  def number_of_edges
    self.graph.length
  end

  def has_eulerian_path?
    self.number_of_unbalanced_nodes == 0 && self.number_of_semi_balanced_nodes == 2
  end

  def has_eulerian_cycle?
    self.number_of_unbalanced_nodes == 0 && self.number_of_semi_balanced_nodes == 0
  end

  def is_eulerian?
    has_eulerian_path? || has_eulerian_cycle?
  end

  def stats
    puts "eulerian? #{is_eulerian?}"
    percent_semi = number_of_semi_balanced_nodes.to_f / number_of_balanced_nodes.to_f
    puts "#{percent_semi} percent semi balanced (#{number_of_semi_balanced_nodes})"
    puts "number of edges: #{number_of_edges}"
  end
end

class Node
  attr_accessor :km1mer, :number_of_incoming_edges, :number_of_outgoing_edges

  def initialize km1mer
    self.km1mer = km1mer
    self.number_of_incoming_edges = 0
    self.number_of_outgoing_edges = 0
  end

  def is_semi_balanced?
    (self.number_of_incoming_edges - self.number_of_outgoing_edges).abs == 1
  end

  def is_balanced?
    self.number_of_incoming_edges == self.number_of_outgoing_edges
  end

  def hash
    self.km1mer.hash
  end

  def eql? b
    self.hash == b.hash
  end

  def string
    self.km1mer
  end
end

# test
g = Graph.new 5, test: true

# real
# g = Graph.new 500

g.fill
g.tally

path = g.eulerian_path; nil

binding.pry
