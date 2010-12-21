require 'helper'

module SequelTreeTest
  DB = Sequel.sqlite

  DB.create_table :nodes do
    primary_key :id
    String :name
    Integer :parent_id
    Integer :position 
  end

  NODES = [
    {:id => 1, :name => 'one', :parent_id => nil, :position => 1}, 
    {:id => 2, :name => 'two', :parent_id => nil, :position => 2}, 
    {:id => 3, :name => 'three', :parent_id => nil, :position => 3}, 
    {:id => 4, :name => "two.one", :parent_id => 2, :position => 1},
    {:id => 5, :name => "two.two", :parent_id => 2, :position => 2},
    {:id => 6, :name => "two.two.one", :parent_id => 5, :position => 1},
    {:id => 7, :name => "one.two", :parent_id => 1, :position => 2},
    {:id => 8, :name => "one.one", :parent_id => 1, :position => 1},
    {:id => 9, :name => "five", :parent_id => nil, :position => 5},
    {:id => 10, :name => "four", :parent_id => nil, :position => 4},
    {:id => 11, :name => "five.one", :parent_id => 9, :position => 1},
    {:id => 12, :name => "two.three", :parent_id => 2, :position => 3},
  ]

  DB.create_table :lorems do
    primary_key :id
    String :name
    Integer :ipsum_id
    Integer :neque
  end

  LOREMS = [
    {:id => 1, :name => 'Lorem', :ipsum_id => nil, :neque => 4}, 
    {:id => 2, :name => 'Ipsum', :ipsum_id => nil, :neque => 3}, 
    {:id => 4, :name => "Neque", :ipsum_id => 2, :neque => 2},
    {:id => 5, :name => "Porro", :ipsum_id => 2, :neque => 1},
  ]  

  NODES.each{|node| DB[:nodes].insert(node)}
  LOREMS.each{|lorem| DB[:lorems].insert(lorem)}

  class Node < Sequel::Model
    plugin :tree
  end

  class NaturalNode < Sequel::Model(:nodes)
    plugin :tree
  end

  class OrderedNode < Sequel::Model(:nodes)
    plugin :tree, :order => :position
  end

  class Lorem < Sequel::Model
    plugin :tree, :key => :ipsum_id, :order => :neque
  end

  describe Sequel::Plugins::Tree do
  
    it "should instantiate" do
      Node.all.size.should == 12
    end
  
    it "should find top level nodes" do
      Node.roots.count.should == 5
    end
  
    it "should find all descendants of a node" do 
      two = Node.find(:id => 2)
      two.name.should == "two"
      two.descendants.map{|m| m[:id]}.should == [4, 5, 12, 6]
    end
  
    it "should find all ancestors of a node" do 
      twotwoone = Node.find(:id => 6)
      twotwoone.name.should == "two.two.one"
      twotwoone.ancestors.map{|m| m[:id]}.should == [5, 2]
    end
    
    it "should find all siblings of a node, excepting self" do 
      twoone = Node.find(:id => 4)
      twoone.name.should == "two.one"
      twoone.siblings.map{|m| m[:id]}.should == [5, 12]
    end
  
    it "should find all siblings of a node, including self" do 
      twoone = Node.find(:id => 4)
      twoone.name.should == "two.one"
      twoone.self_and_siblings.map{|m| m[:id]}.should == [4, 5, 12]
    end
  
    it "should find siblings for root nodes" do 
      three = Node.find(:id => 3)
      three.name.should == "three"
      three.self_and_siblings.map{|m| m[:id]}.should == [1, 2, 3, 9, 10]
    end
  
    it "should find correct root for a node" do
      twotwoone = Node.find(:id => 6)
      twotwoone.name.should == "two.two.one"
      twotwoone.root[:id].should == 2
    
      three = Node.find(:id => 3)
      three.name.should == "three"
      three.root[:id].should == 3
    
      fiveone = Node.find(:id => 11)
      fiveone.name.should == "five.one"
      fiveone.root[:id].should == 9
    end
  
    describe "Nodes in natural database order" do
      it "iterate top-level nodes in natural database order" do
        NaturalNode.roots.count.should == 5
        NaturalNode.roots.inject([]){|ids, p| ids << p.position}.should == [1, 2, 3, 5, 4]
      end
    
      it "should have children" do
        one = NaturalNode.find(:id => 1)
        one.name.should == "one"
        one.children.count.should == 2
      end
    
      it "children should be natural database order" do 
        one = NaturalNode.find(:id => 1)
        one.name.should == "one"
        one.children.map{|m| m[:position]}.should == [2, 1]
      end
    end

    describe "Nodes in specified order" do
      it "iterate top-level nodes in order by position" do
        OrderedNode.roots.count.should == 5
        OrderedNode.roots.inject([]){|ids, p| ids << p.position}.should == [1, 2, 3, 4, 5]
      end

      it "children should be in specified order" do 
        one = OrderedNode.find(:id => 1)
        one.name.should == "one"
        one.children.map{|m| m[:position]}.should == [1, 2]
      end
    end
  
    describe "Lorems in specified order" do
      it "iterate top-level nodes in order by position" do
        Lorem.roots.count.should == 2
        Lorem.roots.inject([]){|ids, p| ids << p.neque}.should == [3, 4]
      end

      it "children should be specified order" do 
        one = Lorem.find(:id => 2)
        one.children.map{|m| m[:neque]}.should == [1, 2]
      end
    end
  end
end