require 'helper'
require 'sequel_plus'

module ExportTest
  
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

  describe Sequel::Export do
  
    it "should instantiate" do
      DB[:nodes].all.size.should == 12
    end

    it "should export everything" do 
      DB[:nodes].export.should == "id\tname\tparent_id\tposition\n1\tone\t\t1\n2\ttwo\t\t2\n3\tthree\t\t3\n4\ttwo.one\t2\t1\n5\ttwo.two\t2\t2\n6\ttwo.two.one\t5\t1\n7\tone.two\t1\t2\n8\tone.one\t1\t1\n9\tfive\t\t5\n10\tfour\t\t4\n11\tfive.one\t9\t1\n12\ttwo.three\t2\t3"
    end
  
    it "should export selected" do 
      DB[:nodes].filter(:id < 3).select(:id, :name).export.should == "id\tname\n1\tone\n2\ttwo"
    end
  end
end