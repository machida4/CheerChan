require 'discordrb'
require 'dotenv'
require 'steam-api'

Dotenv.load

pp ENV["TOKEN"]
pp ENV["CLIENT_ID"]

bot = Discordrb::Commands::CommandBot.new(
  token: ENV["TOKEN"],
  client_id: ENV["CLIENT_ID"],
  prefix:'#',
)

bot.command :hello do |event|
  event.send_message("hello,world.#{event.user.name}")
end

bot.command :two do |event|
  Steam.apikey = ENV["STEAM_API_KEY"]
  data = Steam::Player.recently_played_games(ENV["STEAM_ID"])["games"]
  sum_of_playtime_2weeks = data.inject(0){ |sum, d| sum + d["playtime_2weeks"]}
  hour, minute = sum_of_playtime_2weeks.divmod(60)
  event.send_message("#{hour}時間#{minute}分")
end

bot.run