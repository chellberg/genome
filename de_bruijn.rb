require 'set'
require 'pry'

class Graph
  attr_accessor :nodes, :graph,:number_of_balanced_nodes,
    :number_of_semi_balanced_nodes, :number_of_unbalanced_nodes, :head, :tail,
    :tour, :naked_tour, :offenders

  def initialize k, test: false
    # multimap from Nodes to neighbors

    # fixes empty @graph:
    # http://stackoverflow.com/questions/2698460/strange-
    # behavior-when-using-hash-default-value-e-g-hash-new
    @graph = Hash.new { |h, k| h[k] = [] }

    # maps k1mers to Node objects
    @nodes = {}
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
        if @nodes.include? km1L
          nodeL = @nodes[km1L]
        else
          nodeL = @nodes[km1L] = Node.new(km1L)
        end

        # find or create right node
        if @nodes.include? km1R
          nodeR = @nodes[km1R]
        else
          nodeR = @nodes[km1R] = Node.new(km1R)
        end

        # increment node in/out counts
        nodeL.number_of_outgoing_edges += 1
        nodeR.number_of_incoming_edges += 1

        @graph[nodeL] << nodeR
      end
    end
  end

  def tally
    # Iterate through nodes and tally how many are balanced,
    # semi-balanced, or neither
    @number_of_balanced_nodes = 0
    @number_of_semi_balanced_nodes = 0
    @number_of_unbalanced_nodes = 0
    # Keep track of head and tail nodes in the case of a graph with
    # Eularian path (not cycle)
    @head = nil
    @tail = nil

    @nodes.each do |key, node|
      if node.is_balanced?
        @number_of_balanced_nodes += 1
      elsif node.is_semi_balanced?
        if node.number_of_incoming_edges == node.number_of_outgoing_edges + 1
          @tail = node
        end

        if node.number_of_incoming_edges == node.number_of_outgoing_edges - 1
          @head = node
        end

        @number_of_semi_balanced_nodes += 1
      else
        @number_of_unbalanced_nodes += 1
      end
    end
  end

  def eulerian_path
    # return eulerian path or cycle
    puts 'not eulerian' if !is_eulerian?

    if true # has_eulerian_path?
      @cloned_graph = @graph.clone
      raise if @head.nil? || @tail.nil?
      @cloned_graph[@tail] << @head
    end
    @tour = []
    # select random starting node
    source = @head
    visit source

    # not sure why reversing and dropping the beginning
    @naked_tour = @tour.clone
    @tour.reverse! # .shift

    @tour
  end

  def build_string
    first = @tour.shift.km1mer
    final_letters = @tour.map{ |node| node.km1mer[-1]}
    first + final_letters.join('')
  end

  def visit node
    connected_nodes = @graph[node]

    while connected_nodes.length > 0 do
      destination = connected_nodes.pop
      visit destination
    end

    # if node == @head
    #   binding.pry
    # end
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
    @nodes.length
  end

  def number_of_edges
    @graph.length
  end

  def has_eulerian_path?
    @number_of_unbalanced_nodes == 0 && @number_of_semi_balanced_nodes == 2
  end

  def has_eulerian_cycle?
    @number_of_unbalanced_nodes == 0 && @number_of_semi_balanced_nodes == 0
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

  def number_of_overlap_edges
    count = 0
    @offenders
    @nodes.each do |node|
      if @graph[node].length > 1
        @offenders << node
        count += 1
      end
    end

    count
  end
end

class Node
  attr_accessor :km1mer, :number_of_incoming_edges, :number_of_outgoing_edges

  def initialize km1mer
    @km1mer = km1mer
    @number_of_incoming_edges = 0
    @number_of_outgoing_edges = 0
  end

  def is_semi_balanced?
    (@number_of_incoming_edges - @number_of_outgoing_edges).abs == 1
  end

  def is_balanced?
    @number_of_incoming_edges == @number_of_outgoing_edges
  end

  def hash
    @km1mer.hash
  end

  def eql? b
    @hash == b.hash
  end

  def string
    @km1mer
  end
end

# how to test: uncomment test or real initialization, uncomment the rest, run
# ruby de_bruijn.rb

# test - k value of 8 produces eulerian graph
# g = Graph.new 5, test: true

# real
g = Graph.new 500

g.fill
g.tally

# uncomment this line (and tweak the method if you want) to look for k values
# that produce eulerian graphs
# g.find_working_k_value 
#

# remove overlap
g.nodes.each do |kmer, node|
  if node.number_of_outgoing_edges == 2
    # maybe check whether they're going to the same node
    # remove one edge
    g.graph[node].pop
    node.number_of_outgoing_edges -= 1
    g.graph[node].first.number_of_incoming_edges -= 1
  end
end

g.tally

binding.pry
# path = g.eulerian_path; nil
