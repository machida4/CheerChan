require 'discordrb'
require 'dotenv'

Dotenv.load

pp ENV["TOKEN"]
pp ENV["CLIENT_ID"]

bot = Discordrb::Commands::CommandBot.new(
  token: ENV["TOKEN"],
  client_id: ENV["CLIENT_ID"],
  prefix:'/',
)

bot.command :hello do |event|
  event.send_message("hello,world.#{event.user.name}")
end

bot.run