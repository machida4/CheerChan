# デプロイ
#1 git push heroku master
#2 heroku restart bot.1
# heroku psで起動中のプロセス確認できる

require 'discordrb'
require 'dotenv'
require 'steam-api'
require 'active_record'
require_relative 'user'
require_relative 'playtime'
require 'date'

Dotenv.load

Steam.apikey = ENV["STEAM_API_KEY"]

bot = Discordrb::Commands::CommandBot.new(
  token: ENV["TOKEN"],
  client_id: ENV["CLIENT_ID"],
  prefix:'meu ',
)
previous = Date.today

bot.heartbeat do |event|
  now = Date.today
  next unless previous < now
  previous = now

  User.all.each do |user|
    data = Steam::Player.owned_games(user.steamid, params: {include_appinfo:true, include_played_free_games:true})["games"]
    current_games = {}
    data.each do |d|
      next if d["playtime_forever"] == 0
      current_games[d["appid"]] = {name: d["name"], playtime_forever: d["playtime_forever"]}
    end
    unless Playtime.where(steamid: user.steamid).present?
      current_playtime = Playtime.new(steamid: user.steamid, game_playtime_hash: current_games)
      current_playtime.save!
      next
    end
    previous_games = Playtime.where(steamid: user.steamid).order(created_at: :desc).take.game_playtime_hash
    current_playtime = Playtime.new(steamid: user.steamid, game_playtime_hash: current_games)
    current_playtime.save!
    detail = ""
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
        detail << "> **#{hash[:name]}**\n"
        detail << "> --#{hour.to_s.rjust(2, '0')}時間#{minute.to_s.rjust(2, '0')}分\n"
      end
    end
    sum_hour, sum_minute = sum_of_playtime.divmod(60)[0], sum_of_playtime.divmod(60)[1]
    message = "**#{user.name}** の今日のプレイ時間は **#{sum_hour.to_s.rjust(2, '0')}**時間**#{sum_minute.to_s.rjust(2, '0')}**分 めう！\n" + detail
    bot.send_message(ENV["CHANNEL_ID"], message)
    sleep(2)
  end
end

bot.command :hello do |event|
  "hello, #{event.user.id}!!"
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