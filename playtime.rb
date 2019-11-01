require_relative 'db_setup'

class Playtime < ActiveRecord::Base
  serialize :game_playtime_hash
end