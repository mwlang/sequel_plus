module Sequel
  module Plugins
    # The Tree plugin adds additional associations and methods that allow you to 
    # treat a Model as a tree.  
    #
    # A column for holding the parent key is required and is :parent_id by default.  
    # This may be overridden by passing column name via :key
    #
    # Optionally, a column to control order of nodes returned can be specified
    # by passing column name via :order.
    # 
    # Examples:
    #
    #   class Node < Sequel::Model
    #     plugin :tree
    #   end
    #  
    #   class OrderedNode < Sequel::Model(:nodes)
    #     plugin :tree, :order => :position
    #   end
    #
    module Tree
      def self.configure(model, opts = {})
        model.instance_eval do 
          @parent_column = opts[:key] || :parent_id
          @order_column = opts[:order]
          
          many_to_one :parent, :class => self, :key => @parent_column
          one_to_many :children, :class => self, :key => @parent_column, :order => @order_column
        end
      end
      
      module ClassMethods
        # Returns list of all root nodes (those with no parent nodes).
        #
        #   TreeClass.roots # => [root1, root2]
        def roots
          roots_dataset.all
        end
        
        # Returns the dataset for retrieval of all root nodes
        #
        #   TreeClass.roots_dataset => Sequel#Dataset
        def roots_dataset
          filter(@parent_column => nil).order(@order_column)
        end
      end
      
      module InstanceMethods
        # Returns list of ancestors, starting from parent until root.
        #
        #   subchild1.ancestors # => [child1, root]
        def ancestors
          node, nodes = self, []
          nodes << node = node.parent while node.parent
          nodes
        end

        # Returns list of ancestors, starting from parent until root.
        #
        #   subchild1.ancestors # => [child1, root]
        def descendants
          nodes = self.children
          self.children.each{|c| nodes + c.descendants}
          nodes 
        end

        # Returns the root node of the tree that this node descends from
        # This node is returned if it is a root node itself.
        def root
          ancestors.last || self
        end

        # Returns all siblings of the current node.
        #
        #   subchild1.siblings # => [subchild2]
        def siblings
          self_and_siblings - [self]
        end

        # Returns all siblings and a reference to the current node.
        #
        #   subchild1.self_and_siblings # => [subchild1, subchild2]
        def self_and_siblings
          parent ? parent.children : model.roots
        end
      end
    end
  end
end
