class TreeNode
  attr :children, true
  attr :parent, true
  attr :value, true
  @@root = nil
  
  @@nodes = []
  
  def TreeNode::root
    @@root
  end
  
  def TreeNode::all
    @@nodes
  end
  
  def TreeNode::to_a()
    @@nodes
  end  
  
  def initialize(inValue = nil)
    @@nodes << self
    @@root = self if not @@root
    @value = inValue
    @children = []
    @parent = nil
  end
   
  def depth
    d = 1
    d += @parent.depth if @parent
    d
  end
  
  def <<(child)
    @children.push child
    child.parent = self
    child
  end

  def to_s
    @value    
  end
    
  def TreeNode::[](findVal)
    @@nodes.each {|node|
      return node if node.value == findVal
    } 
    return TreeNode.new(findVal)
  end
  
  def TreeNode::to_graph
      graph = []
      graph << "digraph g{" 
      @@nodes.each {|node|
         graph << "\t\"#{node.value.gsub("\\", "\\\\") }\"" # create the nodes
         node.children.each {|c|
            graph << "\t\"#{node.value.gsub("\\", "\\\\")}\" -> \"#{c.value.gsub("\\", "\\\\")}\""  # create the edges
         }        
      }
      
      rank = {}
      TreeNode.all.each {|node|
         d = node.depth
         rank[d] = rank[d] || []
         rank[d] << "\"" + node.value.gsub("\\", "\\\\") + "\""
      }
      rank.each {|r, n|
         graph << "{rank=same " + n.join(" ") + "};" # rank nodes with the same depth together
      }
      graph << "}"   
      graph.join("\n")
  end
end




#~ Simple tree:

# assume the value of a node is a hash
# and the path separator is backslash
# and a node's children are unordered

#~ tree = {}

#~ def tree_lookup(tree, path)
  
  #~ if path == ""
    #~ tree['__value'] = {} unless tree['__value']
    #~ return tree['__value']
  #~ end
  
  #~ path = path.split("\\")
  
  #~ tree[path.first] = {} unless tree[path.first]
  
  #~ return tree_lookup(tree[path.first], path[1,999999].join("\\"))
#~ end

#~ # testing for tree_lookup
#~ tree_lookup(tree, "") << "test1"
#~ tree_lookup(tree, "") << "test2"
#~ tree_lookup(tree, "child1") << "A"
#~ tree_lookup(tree, "child1") << "B"
#~ tree_lookup(tree, "child1") << "C"
#~ tree_lookup(tree, "child2") << "AA"
#~ tree_lookup(tree, "child2") << "BB"
#~ tree_lookup(tree, "child2") << "CC"
#~ tree_lookup(tree, "child2\\gchild3") << "AAA"
#~ tree_lookup(tree, "child2\\gchild3") << "BBB"
#~ tree_lookup(tree, "child2\\gchild3") << "CCC"

#~ puts tree.to_yaml
 