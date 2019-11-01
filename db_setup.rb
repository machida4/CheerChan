require 'active_record'
ActiveRecord::Base.establish_connection(ENV["DB_Info"])