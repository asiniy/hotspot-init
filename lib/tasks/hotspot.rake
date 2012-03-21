namespace :db do
  desc 'copy database, require FROM, TO. Else I want RAILS_ENV'
  task :copy do
    puts "Hello, world!"
    puts Rails.env
    db_config = Rails.application.config.database_configuration[Rails.env]
    puts "-u#{db_config['username']} -p#{db_config['password']} #{db_config['database']} --default-character-set=utf8"
    #  --local <path_to_your_file>

  end
end
