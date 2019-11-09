require 'discordrb'
require 'dotenv'
require 'steam-api'
require 'active_record'
require 'date'

require_relative 'user'
require_relative 'playtime'
require_relative 'meubot'

Dotenv.load

Steam.apikey = ENV["STEAM_API_KEY"]

command_bot = Discordrb::Commands::CommandBot.new(
  token: ENV["TOKEN"],
  client_id: ENV["CLIENT_ID"],
  prefix:'meu ',
)

bot = MeuBot.new(command_bot)

bot.command :hello do |event|
  "hello, #{event.user.id}!"
end

bot.command :setid do |event, steam_id|
  if user = User.find_by(discordid: event.user.id)
    User.update!(steamid: steam_id, name: event.user.name)
  else
    user = User.new(discordid: event.user.id, steamid: steam_id, name: event.user.name)
    user.save!
  end
  "hello, #{event.user.name}!"
end

bot.command :rand do |event, *args|
  sleep(2)
  args.uniq!
  result = args.sample.to_s
  event.send_message("👉" + result)
end

bot.run


# bot.command :two do |event|
#   user = User.find_by(discordid: event.user.id)
#   data = Steam::Player.recently_played_games(user.steamid)["games"]
#   sum_of_playtime = data.inject(0){ |sum, d| sum + d["playtime_2weeks"]}
#   hour, minute = sum_of_playtime.divmod(60)
#   event.send_message("#{hour}時間#{minute}分")
# end

# TODO:1日おきにDBに保存するなりなんなりしてdiffをとれるようにする, emojiで増減がわかりやすくする
# :arrow_up:
# :arrow_upper_right:
# :arrow_right:
# :arrow_lower_right:
# :arrow_down:
# TODO:リファクタリング