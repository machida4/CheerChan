require 'discordrb'
require 'dotenv'
require 'steam-api'
require 'Date'

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
  sum_of_playtime = data.inject(0){ |sum, d| sum + d["playtime_2weeks"]}
  hour, minute = sum_of_playtime.divmod(60)
  event.send_message("#{hour}時間#{minute}分")
end

# bot.command :two_diff do |event|
#   previous_sum_of_playtime = 5000
#   current_sum_of_playtime = 3000
#   playtime_diff = current_sum_of_playtime - previous_sum_of_playtime
#   playtime_diff = playtime_diff.to_s
#   playtime_diff += "+" if playtime_diff.positive?
#   event.send_message("#{playtime_diff}分")
# end

bot.run