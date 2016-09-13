require 'set'
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
    first_kmer = string[i...(i + k-1)] 
    second_kmer = string[(i+1)...(i + k)]
    edges.push([first_kmer, second_kmer])

    # add kmers to graph as nodes if they don't already exist
    nodes.add first_kmer
    nodes.add second_kmer
  end
  [nodes, edges]
end
