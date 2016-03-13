require 'slack-ruby-bot'
require 'redis'

$redis = Redis.new(url: 'redis://127.0.0.1:6379')
class RubyBot < SlackRubyBot::Bot
  command 'ping' do |client, data, match|
    client.say(text: 'pong', channel: data.channel)
  end
  
  match(/^ruby +sadd +(?<set>\w+) +(?<member>\w+)$/i) do |client, data, match|
    n = $redis.sadd("rb-set:#{match[:set]}", match[:member])
    client.say(text: n.to_s, channel: data.channel)
  end

  match(/^ruby +srem +(?<set>\w+) +(?<member>\w+)$/i) do |client, data, match|
    n = $redis.srem("rb-set:#{match[:set]}", match[:member])
    client.say(text: n.to_s, channel: data.channel)
  end

  match(/^ruby scard (?<set>\w+)$/i) do |client, data, match|
    n = $redis.scard("rb-set:#{match[:set]}")
    client.say(text: n.to_s, channel: data.channel)
  end

  match(/^ruby sample (?<set>\w+) *(?<count>-?\d+)?$/i) do |client, data, match|
    count = match[:count].to_i
    set = "rb-set:#{match[:set]}"
    members =
      if count.abs > 1
        $redis.srandmember(set, count)
      elsif (member = $redis.srandmember(set))
        [member]
      else
        []
      end
    unless members.empty?
      client.say(text: members.join(', '), channel: data.channel)
    end
  end
end

RubyBot.run

