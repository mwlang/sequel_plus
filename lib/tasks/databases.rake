namespace :db do
  task :SEQUEL_PLUS_APP_ROOT do
    SEQUEL_PLUS_APP_ROOT = File.dirname File.expand_path Rake.application.rakefile
    Rake::Task["environment"].invoke if Rake::Task.task_defined?("environment") 
  end
  
  task :load_config => [:SEQUEL_PLUS_APP_ROOT] do
    raise "no DB has been defined.\n Assign DB in your Rakefile or declare an :environment task and connect to your database." unless defined? DB
    Sequel.extension :migration
    Sequel.extension :schema_dumper
    Sequel.extension :pretty_table
  end

  desc "Displays a list of tables in the database"
  task :tables => :load_config do 
    puts "No tables in this database" if DB.tables.empty?
    DB.tables.each_with_index do |table_name, i|
      puts "#{'%3d' % (i+1)}: #{table_name}"
    end
  end

  desc "Displays content of table or lists all tables"
  task :show, [:table] => :load_config do |t, args|
    args.table ? DB[args.table.to_sym].print : Rake::Task["db:tables"].invoke
  end
  
  desc "Displays simple list of fields of table in sorted order"
  task :fields, [:table] => :load_config do |t, args|
    raise "no table name given" unless args[:table]
    
    puts '==[' << args.table << ']' << '=' * (80 - args.table.size - 4)
    DB.schema(args.table.to_sym).sort{|a, b| a[0].to_s <=> b[0].to_s}.each{|col| puts col[0]}
    puts '=' * 80
  end

  desc "Displays a list of tables" 
  task :list_tables => :load_config do 
    DB.tables.sort{|a,b| a.to_s <=> b.to_s}.each_with_index{|table, i| puts ("%-2d" % (i + 1)) + table.to_s}
  end
  
  desc "Displays schema of table"
  task :desc, [:table] => :load_config do |t, args|
    def o(value, size = 25)
      "%#{-1*size}s" % value.to_s
    end
    unless args[:table]
      Rake::Task["db:list_tables"].invoke
    else
      puts '==[' << args.table << ']' << '=' * (80 - args.table.size - 4)
      DB.schema(args.table.to_sym).each_with_index do |col, i|
       name, info = col
       puts "#{o i+1, -3}: #{o name}:#{o info[:type], 15}:#{o info[:db_type], 15}:#{' not null ' unless info[:allow_null]} #{' pk ' if info[:primary_key]} #{' default: ' << info[:default].to_s if info[:default]}"
      end
      puts '-' * 80
      indexes = DB.indexes(args.table.to_sym)
      if indexes.size == 0
        puts "  No indexes defined"
      else
        indexes.each_with_index do |idx, i|
          name, attrs = idx
          puts '  ' << o(name, 28) << ": unique? " << o(attrs[:unique] ? 'yes' : 'no', 6) << ': ' << attrs[:columns].join(', ')
        end
      end
      puts '=' * 80
    end
  end

  namespace :schema do
    task :ensure_db_dir do
      FileUtils.mkdir_p File.join(SEQUEL_PLUS_APP_ROOT, 'db', 'migrate')
    end
    
    desc "Dumps the schema to db/schema.db"
    task :dump => [:load_config, :ensure_db_dir] do
      schema = DB.dump_schema_migration
      schema_file = File.open(File.join(SEQUEL_PLUS_APP_ROOT, 'db', 'schema.rb'), "w"){|f| f.write(schema)}
    end
    
    desc "drops the schema, using schema.rb"
    task :drop => [:load_config, :dump] do
      eval(File.read(File.join(SEQUEL_PLUS_APP_ROOT, 'db', 'schema.rb'))).apply(DB, :down)
    end
    
    desc "loads the schema from db/schema.rb"
    task :load => :load_config do
      eval(File.read(File.join(SEQUEL_PLUS_APP_ROOT, 'db', 'schema.rb'))).apply(DB, :up)
      latest_version = Sequel::Migrator.latest_migration_version(File.join(SEQUEL_PLUS_APP_ROOT, 'db', 'migrate'))
      Sequel::Migrator.set_current_migration_version(DB, latest_version)
      puts "Database schema loaded version #{latest_version}"
    end
    
    desc "Returns current schema version"
    task :version => :load_config do
      puts "Current Schema Version: #{Sequel::Migrator.get_current_migration_version(DB)}"
    end
  end
  
  desc "Migrate the database through scripts in db/migrate and update db/schema.rb by invoking db:schema:dump."
  task :migrate => :load_config do
    Sequel::Migrator.apply(DB, File.join(SEQUEL_PLUS_APP_ROOT, 'db', 'migrate'))
    Rake::Task["db:schema:dump"].invoke
    Rake::Task["db:schema:version"].invoke
  end

  namespace :migrate do
    desc  'Rollbacks the database one migration and re-migrates up.'
    task :redo => :load_config do
      Rake::Task["db:rollback"].invoke
      Rake::Task["db:migrate"].invoke
      Rake::Task["db:schema:dump"].invoke
    end

    desc 'Runs the "up" for a given migration VERSION.'
    task :up, [:version] => :load_config do |t, args|
      raise "VERSION is required" unless args[:version]

      puts "migrating up to version #{args.version}"
      Sequel::Migrator.apply(DB, File.join(SEQUEL_PLUS_APP_ROOT, 'db', 'migrate'), args.version)
      Rake::Task["db:schema:dump"].invoke 
    end

    desc 'Reverts to previous schema version.  Specify the number of steps with STEP=n'
    task :down, [:step] => :load_config do |t, args|
      step = args[:step] ? args.step.to_i : 1
      current_version = Sequel::Migrator.get_current_migration_version(DB)
      down_version = current_version - step
      down_version = 0 if down_version < 0

      puts "migrating down to version #{down_version}"
      Sequel::Migrator.apply(DB, File.join(SEQUEL_PLUS_APP_ROOT, 'db', 'migrate'), down_version)
      Rake::Task["db:schema:dump"].invoke
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
    Rake::Task["db:migrate:down"].invoke
  end

  desc 'Drops all tables and recreates the schema from db/schema.rb'
  task :reset => ['db:schema:drop', 'db:schema:load']
end
