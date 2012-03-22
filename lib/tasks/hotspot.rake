require 'yaml'

namespace :db do
  desc 'copy database, require FROM, TO. Assumes both schemas already migrated'
  task :copy => :environment do
    # defining source
    from = ENV['FROM'].split(':')
    from[0] = YAML::load_file(from[0])[from[1]]
    from = from[0]
    
    # defining target
    to = ENV['TO'].split(':')
    to[0] = YAML::load_file(to[0])[to[1]]
    to = to[0]
    
    # Defining classes
    class FromModelClass < ActiveRecord::Base
    end
    class ToModelClass < ActiveRecord::Base
    end
    
    
    # creates db if not exist
    ActiveRecord::Base.establish_connection(
      :adapter  => to['adapter'],
      :host     => to['host'],
      :username => to['username'],
      :password => to['password'],
      :database => 'postgres'
    )
    ActiveRecord::Base.connection.drop_database(to['database']) rescue nil
    ActiveRecord::Base.connection.create_database(to['database'])
    ActiveRecord::Base.remove_connection


    # copying tables
    skip_tables = ["schema_info", "schema_migrations"]
    FromModelClass.establish_connection(
      :adapter  => from['adapter'],
      :host     => from['host'],
      :username => from['username'],
      :password => from['password'],
      :database => from['database']
    )
    
    
    
    ToModelClass.establish_connection(
        :adapter  => to['adapter'],
        :host     => to['host'],
        :username => to['username'],
        :password => to['password'],
        :database => to['database']
    )
    
    # delta_tables
    delta_tables = FromModelClass.connection.tables - skip_tables
    
    
    
    # creating tables
    
    delta_tables.each do |table_name|
      FromModelClass.table_name = table_name
      
      ToModelClass.connection.drop_table(table_name) rescue nil
      ToModelClass.connection.create_table(table_name)
      FromModelClass.connection.columns(table_name).each do |column|
        ToModelClass.connection.add_column(table_name, column.name, column.type.to_s) if column.name != "id"
      end
      ToModelClass.table_name = table_name
    end
    
    # assumes we already have all databases
        
    delta_tables.each do |table_name|
      
      FromModelClass.table_name = table_name
      ToModelClass.record_timestamps = false 
      ToModelClass.table_name = table_name
      
      count = 0;

      print "Converting #{table_name}..."; STDOUT.flush
      
      models = FromModelClass.find(:all)
      count += models.size
      if models.size > 0
      
        ToModelClass.transaction do
          models.each do |model|
            new_model = ToModelClass.new(model.attributes)
            new_model.id = model.id
            new_model.save
          end
        end
      end
      print "#{count} records converted\n"
    
    end


  end
end
