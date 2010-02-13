# sequel_plus

This library starts the collection of plugins and possibly extension I assemble for the Ruby Sequel 
ORM.  

Currently, it contains:
  * plugin for Trees to mimic the Rails acts_as_tree plugin.
  * extension for Exporting data using Dataset#export. 

NOTE:  Authors of other plugins and extensions for Sequel are welcome to contact me for inclusion
of your plugin and extension to this project.

Released under MIT license.

# For the Impatient

## Install 

This gem is released to gemcutter.  Rubyforge is not utilized. 

	gem install sequel_plus

## Use Tree Plugin 

	require 'sequel'

	class Node < Sequel::Model
		plugin :tree
	end

## Use Exporter

    require 'sequel'
    require 'sequel_plus'

    DB = Sequel.sqlite

    # Every row, every column, tab delimited, unquoted...
    File.open("nodes.txt", "w"){|file| DB[:nodes].export(file)}

    # Every row, every column, comma delimited double-quotes
    File.open("nodes.txt", "w"){|file| DB[:nodes].export(file, :delimiter => ',', :quote_char => '"')}
  
    # Specific rows and columns
    File.open("nodes.txt", "w"){|file| DB[:nodes].filter(:id < 5).select(:id, :name).export(file)}

# Note on Patches/Pull Requests
 
* This release adds an export facility to the Sequel::Dataset

# Copyright

Copyright 2009 Michael Lang.  All rights reserved.
Released under MIT license.  See LICENSE for details.
