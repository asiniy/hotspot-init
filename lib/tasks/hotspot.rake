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
    

    
    skip_tables = ["schema_info", "schema_migrations"]
    ActiveRecord::Base.establish_connection(
      :adapter  => from['adapter'],
      :host     => from['host'],
      :username => from['username'],
      :password => from['password'],
      :database => from['database']
    )
    

    
    (ActiveRecord::Base.connection.tables - skip_tables).each do |table_name|
    
      FromModelClass.table_name = table_name
      ToModelClass.table_name = table_name
      ToModelClass.establish_connection(
        :adapter  => to['adapter'],
        :host     => to['host'],
        :username => to['username'],
        :password => to['password'],
        :database => to['database']
      )
      ToModelClass.record_timestamps = false
    
      
    
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
