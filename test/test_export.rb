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

    it "should export everything tab delimited w/o quotes" do 
      mem_stream = StringIO.new("", "w+")
      DB[:nodes].export(mem_stream)
      mem_stream.pos = 0
      mem_stream.read.should == <<-TEXT
id	name	parent_id	position
1	one		1
2	two		2
3	three		3
4	two.one	2	1
5	two.two	2	2
6	two.two.one	5	1
7	one.two	1	2
8	one.one	1	1
9	five		5
10	four		4
11	five.one	9	1
12	two.three	2	3
      TEXT
    end

    it "should export tab delimited with quotes" do 
      mem_stream = StringIO.new("", "w+")
      DB[:nodes].export(mem_stream, :quote_char => '"')
      mem_stream.pos = 0
      mem_stream.read.should == <<-TEXT
"id"	"name"	"parent_id"	"position"
1	"one"	""	1
2	"two"	""	2
3	"three"	""	3
4	"two.one"	2	1
5	"two.two"	2	2
6	"two.two.one"	5	1
7	"one.two"	1	2
8	"one.one"	1	1
9	"five"	""	5
10	"four"	""	4
11	"five.one"	9	1
12	"two.three"	2	3
      TEXT
    end

    it "should export everything with comma delimiter" do 
      mem_stream = StringIO.new("", "w+")
      DB[:nodes].export(mem_stream, :quote_char => '"', :delimiter => ',')
      mem_stream.pos = 0
      mem_stream.read.should == <<-TEXT
"id","name","parent_id","position"
1,"one","",1
2,"two","",2
3,"three","",3
4,"two.one",2,1
5,"two.two",2,2
6,"two.two.one",5,1
7,"one.two",1,2
8,"one.one",1,1
9,"five","",5
10,"four","",4
11,"five.one",9,1
12,"two.three",2,3
      TEXT
    end
      
    it "should export everything with comma delimiter and no quote characters" do 
      mem_stream = StringIO.new("", "w+")
      DB[:nodes].export(mem_stream, :delimiter => ',')
      mem_stream.pos = 0
      mem_stream.read.should == <<-TEXT
id,name,parent_id,position
1,one,,1
2,two,,2
3,three,,3
4,two.one,2,1
5,two.two,2,2
6,two.two.one,5,1
7,one.two,1,2
8,one.one,1,1
9,five,,5
10,four,,4
11,five.one,9,1
12,two.three,2,3
      TEXT
    end
    
    it "should export selected" do 
      mem_stream = StringIO.new("", "w+")
      DB[:nodes].filter(:id < 3).select(:id, :name).export(mem_stream)
      mem_stream.pos = 0
      mem_stream.read.should == "id\tname\n1\tone\n2\ttwo\n"
    end

    it "should not export headers" do 
      mem_stream = StringIO.new("", "w+")
      DB[:nodes].export(mem_stream, :headers => false)
      mem_stream.pos = 0
      mem_stream.read.should == <<-TEXT
1	one		1
2	two		2
3	three		3
4	two.one	2	1
5	two.two	2	2
6	two.two.one	5	1
7	one.two	1	2
8	one.one	1	1
9	five		5
10	four		4
11	five.one	9	1
12	two.three	2	3
      TEXT
    end
    
    it "should explicitly export headers" do 
      mem_stream = StringIO.new("", "w+")
      DB[:nodes].export(mem_stream, :headers => true)
      mem_stream.pos = 0
      mem_stream.read.should == <<-TEXT
id	name	parent_id	position
1	one		1
2	two		2
3	three		3
4	two.one	2	1
5	two.two	2	2
6	two.two.one	5	1
7	one.two	1	2
8	one.one	1	1
9	five		5
10	four		4
11	five.one	9	1
12	two.three	2	3
      TEXT
    end
  end
end