# sequel_plus

This library contains a growing collection of plugins and extensions I have assembled for the Ruby Sequel library.  
The library is in its infancy stage with new things being added and updated semi-frequently.  Even so, 
what's here is fully covered in specs and tested and used in production-level deployments already.

### Currently, sequel_plus contains:
* plugin for Trees to mimic the Rails acts_as_tree plugin.
* extension for exporting data using Dataset#export. 
* rake tasks to handle basic migrations and schema inspections (similar to Rails projects)

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

	# Using pagination extension (for very large datasets)
    File.open("nodes.txt", "w"){|file| DB[:nodes].export(file, :paginate => true, :page_size => 1000)}
	
## Use Rake Tasks

Several rake tasks are made available simply by requiring "tasks/sequel" in your Rakefile 
(or loaded rake scripts) per below: 

	require 'sequel'
	require 'tasks/sequel'

	task :environment do
	  DB = Sequel.sqlite
	end

	# Establish DB somewhere in your Rakefile or elsewhere before invoking the DB dependent tasks
	# If you define in :environment, the sequel tasks will invoke :environment as needed.

	task :environment do
	  DB = Sequel.sqlite
	end

Example tasks that are available:

* rake sq:desc[table]              # Displays schema of table
* rake sq:fields[table]            # Displays simple list of fields of table in sorted order
* rake sq:migrate                  # Migrate the database through scripts in db/migrate and update db/schema.rb by in...
* rake sq:migrate:down[step]       # Reverts to previous schema version.
* rake sq:migrate:new[table,verb]  # Creates a new migrate script.
* rake sq:migrate:redo             # Rollbacks the database one migration and re-migrates up.
* rake sq:migrate:up[version]      # Runs the "up" for a given migration VERSION.
* rake sq:reset                    # Drops all tables and recreates the schema from db/schema.rb
* rake sq:rollback                 # Rolls the schema back to the previous version.
* rake sq:schema:drop              # drops the schema, using schema.rb
* rake sq:schema:dump              # Dumps the schema to db/schema.db
* rake sq:schema:load              # loads the schema from db/schema.rb
* rake sq:schema:version           # Returns current schema version
* rake sq:show[table]              # Displays content of table or lists all tables
* rake sq:tables                   # Displays a list of tables in the database

These tasks will expect migrations to be in db/migration that is based off the folder your Rakefile resides in.  If you wish to change the location of the "db" folder, simply declare :environment task and set SEQUEL_PLUS_APP_ROOT constant to be something other than the folder the Rakefile is residing in.

The rake tasks were constructed to fairly independent of the project environment they're injected into.  To avoid name space collision, 
the "db" namespace has been deprecated and the "sq" namespace adopted as of 0.2.0.

# Note on Patches/Pull Requests
 
0.2.0
* top-level namespace changed from "db" to "sq"
* designed and tested to work seamlessly with Padrino and Ramaze projects
	
0.1.5
* This release adds rake tasks
* last release adds an export facility to the Sequel::Dataset

# Copyright

Copyright 2009 Michael Lang.  All rights reserved.
Released under MIT license.  See LICENSE for details.
