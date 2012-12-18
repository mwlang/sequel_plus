Sequel.extension :migration

def get_migrator( opts = {} )
  dir = File.join( SEQUEL_PLUS_APP_ROOT, %{db}, %{migrate} )
  Sequel::Migrator.send( :migrator_class, dir ).new( DB, dir, opts )
end

def migration_dir
  File.join(SEQUEL_PLUS_APP_ROOT, 'db', 'migrate')
end

def schema_rb
  File.join(SEQUEL_PLUS_APP_ROOT, %{db}, %{schema.rb} )
end

namespace :sq do
  task :SEQUEL_PLUS_APP_ROOT do
    if defined? PADRINO_ROOT
      SEQUEL_PLUS_APP_ROOT = PADRINO_ROOT
    else
      SEQUEL_PLUS_APP_ROOT = File.dirname File.expand_path Rake.application.rakefile
    end
    Rake::Task["environment"].invoke if Rake::Task.task_defined?("environment") 
  end
  
  task :load_config => :SEQUEL_PLUS_APP_ROOT do
    raise "no DB has been defined.\n Assign DB in your Rakefile or declare an :environment task and connect to your database." unless defined? DB
    ::Sequel.extension :migration
    ::Sequel.extension :schema_dumper
    ::Sequel.extension :pretty_table
  end

  desc "Displays a list of tables in the database"
  task :tables => :load_config do 
    puts "No tables in this database" if DB.tables.empty?
    DB.tables.each_with_index do |table_name, i|
      puts "#{'%3d' % (i+1)}: #{table_name}"
    end
  end
  task :list_tables => :tables
  
  desc "Displays content of table or lists all tables"
  task :show, [:table] => :load_config do |t, args|
    args.table ? DB[args.table.to_sym].print : Rake::Task["sq:tables"].invoke
  end
  
  desc "Displays simple list of fields of table in sorted order"
  task :fields, [:table] => :load_config do |t, args|
    raise "no table name given" unless args[:table]
    
    puts '==[' << args.table << ']' << '=' * (80 - args.table.size - 4)
    DB.schema(args.table.to_sym).sort{|a, b| a[0].to_s <=> b[0].to_s}.each{|col| puts col[0]}
    puts '=' * 80
  end

  desc "Displays schema of table"
  task :desc, [:table] => :load_config do |t, args|
    unless args[:table]
      Rake::Task["sq:tables"].invoke
    else
      puts '==[' << args.table << ']' << '=' * (80 - args.table.size - 4)
      DB.schema(args.table.to_sym).each_with_index do |col, i|
        name, info = col
        values = [
          "%3s:" % (i + 1),
          (" %-12s:" % "#{info[:db_type]}#{('(' + info[:max_chars].to_s + ')') if info[:max_chars]}"),
          ("%15s:" % info[:type]),
          "%-25s: " % name,
          (' not null ' unless info[:allow_null]),
          (' pk ' if info[:primary_key]),
          (" default: %s" % info[:default] if info[:default]),
          ]
        puts values.join
      end
      puts '-' * 80
      indexes = DB.indexes(args.table.to_sym)
      if indexes.size == 0
        puts "  No indexes defined"
      else
        indexes.each_with_index do |idx, i|
          name, attrs = idx
          puts '  ' << "%-28s" % name << ": unique? " << "%-6s" % (attrs[:unique] ? 'yes' : 'no') << ': ' << attrs[:columns].join(', ')
        end
      end
      puts '=' * 80
    end
  end


  namespace :schema do

    task :ensure_db_dir do
      Rake::Task["sq:SEQUEL_PLUS_APP_ROOT"].invoke
      FileUtils.mkdir_p migration_dir()
    end
    
    desc "Dumps the schema to db/schema.db"
    task :dump => [:load_config, :ensure_db_dir] do
      schema = DB.dump_schema_migration
      File.open(File.join(SEQUEL_PLUS_APP_ROOT, 'db', 'schema.rb'), "w"){|f| f.write(schema)}
    end
    
    desc "drops the schema, using schema.rb"
    task :drop => [:load_config, :dump] do
      eval( File.read( schema_rb() )).apply(DB, :down)
    end
    
    desc "loads the schema from db/schema.rb"
    task :load => :load_config do
      # eval(File.read(File.join(SEQUEL_PLUS_APP_ROOT, 'db', 'schema.rb'))).apply(DB, :up)
      eval( File.read schema_rb ).apply(DB, :up)
      m = get_migrator()
      # XXX - Double API visibility violation
      m.send( :set_migration_version, m.send( :latest_migration_version ) )
      puts "Database schema loaded version #{ get_migrator().current }"
    end
    
    desc "Returns current schema version"
    task :version => :load_config do
      puts "Current Schema Version: #{ get_migrator().current }"
    end
  end
  
  desc "Migrate the database through scripts in db/migrate and update db/schema.rb by invoking db:schema:dump."
  task :migrate => :load_config do
    Sequel::Migrator.run( DB, migration_dir )
    Rake::Task["sq:schema:dump"].invoke
    Rake::Task["sq:schema:version"].invoke
  end

  # CURRENT
  namespace :migrate do
    desc "Perform automigration (reset your db data)"
    task :auto => :load_config do
      ::Sequel::Migrator.run DB, "db/migrate", :target => 0
      ::Sequel::Migrator.run DB, "db/migrate"
    end

    desc  'Rollbacks the database one migration and re-migrates up.'
    task :redo => :load_config do
      Rake::Task["sq:rollback"].invoke
      Rake::Task["sq:migrate"].invoke
      Rake::Task["sq:schema:dump"].invoke
    end

    desc "Perform migration up/down to VERSION"
    task :to, [:version] => :load_config do |t, args|
      version = (args.version || ENV['VERSION']).to_s.strip
      raise "No VERSION was provided" if version.empty?
      puts "Migrating to version #{args.version}"
      Sequel::Migrator.run(DB, migration_dir(), :target => version.to_i)
      puts "Migrated to version #{get_migrator().current}"
    end

    # DONE
    desc 'Runs the "up" for a given migration VERSION.'
    task :up, [:version] => :load_config do |t, args|
      raise "version is required" unless args[:version]

      m = get_migrator()
      puts "migrating up from version #{ m.current } to version #{args.version}"
      Sequel::Migrator.run( DB, migration_dir(), :current => m.current, :target => args.version.to_i )
      Rake::Task["sq:schema:dump"].invoke 
    end

    # DONE
    desc 'Reverts to previous schema version.  Specify the number of steps with STEP=n'
    task :down, [:step] => :load_config do |t, args|
      step = args[:step] ? args.step.to_i : 1
      m = get_migrator()
      current_version = m.current
      down_version = current_version - step
      down_version = 0 if down_version < 0

      puts "migrating down from version #{ current_version } to version #{down_version}"

      # Sequel::Migrator.apply( DB, migration_dir(), down_version, current_version )
      Sequel::Migrator.run( DB, migration_dir(), :current => m.current, :target => down_version )
      # ::Sequel::Migrator.apply(DB, File.join(SEQUEL_PLUS_APP_ROOT, 'db', 'migrate'), down_version)
      Rake::Task["sq:schema:dump"].invoke
    end
    
    desc "Creates a new migrate script.  The verb is optional." 
    task :new, [:table, :verb] => :load_config do |t, args|
      unless args[:table]
        puts "need to provide a table name:  rake db:migrate:new[new_table]"
      else
        table = args.table
        verb = args.verb || 'create'
        migrate_path = File.join(SEQUEL_PLUS_APP_ROOT,'db', 'migrate')
        begin
          last_file = File.basename(Dir.glob(File.join(migrate_path, '*.rb')).sort.last)
          next_value = last_file.scan(/\d+/).first.to_i + 1
        rescue
          next_value = 1
        end
        filename = '%03d' % next_value << "_" << args.table << '.rb'
        File.open(File.join(migrate_path, filename), 'w') do |file|
          file.puts "class #{verb.capitalize}#{table.capitalize} < Sequel::Migration\n"
          file.puts "\tdef up"
          file.puts "\t\t#{verb}_table :#{table} do"
          file.puts "\t\t\tprimary_key\t:id"
          file.puts "\t\tend"
          file.puts "\tend\n\n"
          file.puts "\tdef down\n"
          file.puts "\t\tdrop_table :#{table}"
          file.puts "\tend"
          file.puts "end"
        end
      end
    end
  end

  desc 'Rolls the schema back to the previous version.'
  task :rollback => :load_config do
    Rake::Task["sq:migrate:down"].invoke
  end

  desc 'Drops all tables and recreates the schema from db/schema.rb'
  task :reset => ['db:schema:drop', 'db:schema:load']
end
