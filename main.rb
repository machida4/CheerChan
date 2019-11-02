require 'discordrb'
require 'dotenv'
require 'steam-api'
require 'active_record'
require_relative 'user'
require_relative 'playtime'
require 'date'

Dotenv.load

Steam.apikey = ENV["STEAM_API_KEY"]

module Steam
  module Player
  end
end

bot = Discordrb::Commands::CommandBot.new(
  token: ENV["TOKEN"],
  client_id: ENV["CLIENT_ID"],
  prefix:'meu ',
)

bot.command :debug do |event|
  User.all.each do |user|
    data = Steam::Player.owned_games(user.steamid, params: {include_appinfo:true, include_played_free_games:true})["games"]

    current_games = {}
    data.each do |d|
      next if d["playtime_forever"] == 0
      current_games[d["appid"]] = {name: d["name"], playtime_forever: d["playtime_forever"]}
    end
    previous_games = Playtime.where(steamid: user.steamid).order(created_at: :desc).take.game_playtime_hash

    current_playtime = Playtime.new(steamid: user.steamid, game_playtime_hash: current_games)
    current_playtime.save!
    message = ""
    sum_of_playtime = 0
    current_games.each do |appid, hash|
      if !previous_games.key? appid
        diff = hash[:playtime_forever]
      else
        diff = hash[:playtime_forever] - previous_games[appid][:playtime_forever]
      end
      if diff == 0
        next
      else
        hour, minute = diff.divmod(60)[0], diff.divmod(60)[1]
        sum_of_playtime += diff
        message << "**#{hash[:name]}**\n"
        message << "#{hour.to_s.rjust(2, '0')}時間#{minute.to_s.rjust(2, '0')}分"
      end
    end
    sum_hour, sum_minute = sum_of_playtime.divmod(60)[0], sum_of_playtime.divmod(60)[1]
    message = "今日のプレイ時間: #{sum_hour.to_s.rjust(2, '0')}時間#{sum_minute.to_s.rjust(2, '0')}分" + message
    event.send_message(message)
  end
  return nil
end

bot.command :hello do |event|
  "hello, #{event.user.id}!"
end

bot.command :two do |event|
  user = User.find_by(discordid: event.user.id)
  data = Steam::Player.recently_played_games(user.steamid)["games"]
  sum_of_playtime = data.inject(0){ |sum, d| sum + d["playtime_2weeks"]}
  hour, minute = sum_of_playtime.divmod(60)
  event.send_message("#{hour}時間#{minute}分")
end

bot.command :diff do |event|
  user = User.find_by(discordid: event.user.id)
  if user.nil?
    event << "まず「meu setid (steamid)」コマンドでSteamのIDを登録してね！"
    return nil
  end

  data = Steam::Player.recently_played_games(user.steamid)["games"]
  current_games = {}
  data.each { |d| current_games[d["appid"]] = {name: d["name"], playtime_2weeks: d["playtime_2weeks"]} }
  previous_games = Playtime.order(created_at: :desc).take.game_playtime_hash
  current_games.each do |appid, hash|
    game_name = hash[:name]
    hour = hash[:playtime_2weeks].divmod(60)[0]
    minute = hash[:playtime_2weeks].divmod(60)[1]
    if !previous_games.key? appid
      emoji = ":arrow_up"
    else
      diff = hash[:playtime_2weeks] - previous_games[appid][:playtime_2weeks]
      if diff > 0
        diff = "＋" + diff.to_s
        emoji = ":arrow_upper_right:"
      elsif diff = 0
        emoji = ":arrow_right:"
        diff = "±" + diff.to_s
      else
        emoji = ":arrow_lower_right:"
        diff = "－" + diff.to_s
      end
    end
    event << "**#{game_name}**"
    event << " #{emoji} #{hour.to_s.rjust(2, '0')}時間#{minute.to_s.rjust(2, '0')}分(#{diff}分)"
  end
  return nil
end

bot.command :setid do |event, steam_id|
  if user = User.find_by(discordid: event.user.id)
    User.update!(steamid: steam_id)
  else
    user = User.new(discordid: event.user.id, steamid: steam_id)
    user.save!
  end
  "hello, #{event.user.name}!"
end

# bot.heartbeat do |event|
#   users = User.all
#   users.each do |user|
#     data = Steam::Player.recently_played_games(user.steamid)["games"]
#     games = {}
#     data.each { |d| games[d["appid"]] = {name: d["name"], playtime_2weeks: d["playtime_2weeks"]} }
#     playtime = Playtime.new(steamid: user.steamid, game_playtime_hash: games)
#     current_sum_of_playtime = data.inject(0){ |sum, d| sum + d["playtime_2weeks"]}
#     previous_games = Playtime.order(created_at: :desc).take.game_playtime_hash
#     playtime.save!

#     message = ""
#     message << current_sum_of_playtime
#     message << "\n"
#     message << 

#     current_games.each do |appid, hash|
#       game_name = hash[:name]
#       hour = hash[:playtime_2weeks].divmod(60)[0]
#       minute = hash[:playtime_2weeks].divmod(60)[1]
#       if !previous_games.key? appid
#         diff = "＋" + hash[:playtime_2weeks].to_s
#       else
#         diff = hash[:playtime_2weeks] - previous_games[appid][:playtime_2weeks]
#         if diff > 0
#           diff = "＋" + diff.to_s
#         elsif diff = 0
#           diff = "±" + diff.to_s
#         else
#           next
#         end
#       end
#       message << "**#{game_name}**"
#       message << " #{emoji} #{hour.to_s.rjust(2, '0')}時間#{minute.to_s.rjust(2, '0')}分(#{diff}分)"
#     end
      
#   end
#   bot.send_message(ENV["CHANNEL_ID"], "てすと")
# end

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
