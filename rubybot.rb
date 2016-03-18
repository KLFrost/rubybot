require 'slack-ruby-bot'
require 'redis'

module SlackRubyBot
  module Commands
    class Help < Base
      HELP = <<EOM
```
ruby sadd set_number_9 foo bar baz        add elements to a set
ruby srem set_foo_bar  baz qux zip        remove elements from a set
ruby sample set_zippy  10                 sample elements without replacement
ruby sample set_zippy -10                 sample elements with replacement
ruby hi                                   say hi, get a gif
ruby ping                                 says pong
...                                       ?
```
EOM
      def self.call(client, data, _match)
        client.say(channel: data.channel, text: HELP)
      end
    end

    class Unknown < Base
      def self.call(client, data, _match)
        msg = $redis.srandmember('rb-set:unknown')
        return unless msg
        msg.gsub!('~',' ')
        client.say(channel: data.channel, text: "<@#{data.user}> #{msg}")
      end
    end
  end
end

$redis = Redis.new(url: 'redis://127.0.0.1:6379')
class RubyBot < SlackRubyBot::Bot
  command 'ping' do |client, data, match|
    pong = "<@#{data.user}> #{Time.now.utc} :pingpong: pong"
    client.say(text: pong, channel: data.channel)
  end
  SADD = %r{^ruby +sadd +(?<set>\w+) +(?<members>([[:graph:]]+ *)+)$}
  SREM = %r{^ruby +srem +(?<set>\w+) +(?<members>([[:graph:]]+ *)+)$}
  
  match(SADD) do |client, data, match|
    members = match[:members].split(/\s+/)
    n = $redis.sadd("rb-set:#{match[:set]}", members)
    if n && (1 == members.size || n > 0)
      client.say(text: n.to_s, channel: data.channel)
    end
  end

  match(SREM) do |client, data, match|
    members = match[:members].split(/\s+/)
    n = $redis.srem("rb-set:#{match[:set]}", members)
    if n && (1 == members.size || n > 0)
      client.say(text: n.to_s, channel: data.channel)
    end
  end

  match(/^ruby +scard +(?<set>\w+) *$/i) do |client, data, match|
    n = $redis.scard("rb-set:#{match[:set]}")
    client.say(text: n.to_s, channel: data.channel) if n > 0
  end

  match(/^ruby +sample +(?<set>\w+) *(?<count>-?\d+)?$/i) do |client, data, match|
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
      client.say(text: members.join(' '), channel: data.channel)
    end
  end
end

RubyBot.run

