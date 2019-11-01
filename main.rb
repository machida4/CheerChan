require 'discordrb'
require 'dotenv'
require 'steam-api'
require 'active_record'
require_relative 'user'
require_relative 'playtime'
Dotenv.load

Steam.apikey = ENV["STEAM_API_KEY"]

bot = Discordrb::Commands::CommandBot.new(
  token: ENV["TOKEN"],
  client_id: ENV["CLIENT_ID"],
  prefix:'meu ',
)

bot.command :hello do |event|
  "hello, #{event.user.id}!"
end

bot.command :two do |event|
  data = Steam::Player.recently_played_games(ENV["STEAM_ID"])["games"]
  sum_of_playtime = data.inject(0){ |sum, d| sum + d["playtime_2weeks"]}
  hour, minute = sum_of_playtime.divmod(60)
  event.send_message("#{hour}時間#{minute}分")
end

bot.command :detail do |event|
  user = User.find_by(discordid: event.user.id)
  if user.nil?
    event << "まず「meu setid (steamid)」コマンドでSteamのIDを登録してね！"
    return nil
  end
  data = Steam::Player.recently_played_games(user.steamid)["games"]
  games = []
  games = data.map { |d| {name: d["name"], appid: d["appid"], playtime_2weeks: d["playtime_2weeks"]} }
  playtime = Playtime.new(steamid: user.steamid, game_playtime_hash: games)
  playtime.save!
  games.each do |game|
    game_name = game[:name]
    hour = game[:playtime_2weeks].divmod(60)[0]
    minute = game[:playtime_2weeks].divmod(60)[1]
    event << "**#{game_name}**"
    event << ":arrow_upper_right: #{hour.to_s.rjust(2, '0')}時間#{minute.to_s.rjust(2, '0')}分"
  end
  return nil
end

bot.command :diff do |event|
  user = User.find_by(discordid: event.user.id)
  if user.nil?
    event << "まず「meu setid (steamid)」コマンドでSteamのIDを登録してね！"
    return nil
  end
  data = Steam::Player.recently_played_games(user.steamid)["games"]
  games = {}
  data.each { |d| games[d["appid"]] = {name: d["name"], playtime_2weeks: d["playtime_2weeks"]} }
  playtime = Playtime.new(steamid: user.steamid, game_playtime_hash: games)
  playtime.save!
  event << Playtime..order(created_at: :desc).take.game_playtime_hash
  return nil
end

bot.command :setid do |event, steam_id|
  if user = User.find_by(discordid: event.user.id)
    User.update!(steamid: steam_id)
  else
    user = User.new(discordid: event.user.id, steamid: steam_id)
    user.save!
  end
end

bot.run

# TODO:1日おきにDBに保存するなりなんなりしてdiffをとれるようにする, emojiで増減がわかりやすくする
# :arrow_up:
# :arrow_upper_right:
# :arrow_right:
# :arrow_lower_right:
# :arrow_down:
# TODO:リファクタリング


# bot.command :two_diff do |event|
#   previous_sum_of_playtime = 5000
#   current_sum_of_playtime = 3000
#   playtime_diff = current_sum_of_playtime - previous_sum_of_playtime
#   playtime_diff = playtime_diff.to_s
#   playtime_diff += "+" if playtime_diff.positive?
#   event.send_message("#{playtime_diff}分")
# end
