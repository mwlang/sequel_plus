# sequel_plus

This library starts the collection of plugins and extensions I have assembled for the Ruby Sequel library.  
The library is in very early infancy stage, so there's not much presently, but what's here is fully covered
in specs and tested and used in production-level deployments already.
  

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

## Use Rake Tasks

Several rake tasks are made available simply by including the "tasks/sequel" per below: 

	require 'sequel'
	require 'sequel_plus'
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

* rake db:desc[table]              # Displays schema of table
* rake db:fields[table]            # Displays simple list of fields of table in sorted order
* rake db:migrate                  # Migrate the database through scripts in db/migrate and update db/schema.rb by in...
* rake db:migrate:down[step]       # Reverts to previous schema version.
* rake db:migrate:new[table,verb]  # Creates a new migrate script.
* rake db:migrate:redo             # Rollbacks the database one migration and re-migrates up.
* rake db:migrate:up[version]      # Runs the "up" for a given migration VERSION.
* rake db:reset                    # Drops all tables and recreates the schema from db/schema.rb
* rake db:rollback                 # Rolls the schema back to the previous version.
* rake db:schema:drop              # drops the schema, using schema.rb
* rake db:schema:dump              # Dumps the schema to db/schema.db
* rake db:schema:load              # loads the schema from db/schema.rb
* rake db:schema:version           # Returns current schema version
* rake db:show[table]              # Displays content of table or lists all tables
* rake db:tables                   # Displays a list of tables in the database

These tasks will expect migrations to be in db/migration that is based off the folder your Rakefile resides in.  If you wish to change the location of the "db" folder, simply declare :environment task and set APP_ROOT folder to be something other than the folder the Rakefile is residing in.

# Note on Patches/Pull Requests
 
* This release adds rake tasks
* last release adds an export facility to the Sequel::Dataset

# Copyright

Copyright 2009 Michael Lang.  All rights reserved.
Released under MIT license.  See LICENSE for details.
