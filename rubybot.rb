require 'slack-ruby-bot'
class RubyBot < SlackRubyBot::Bot
  command 'ping' do |client, data, match|
    client.say(text: 'pong', channel: data.channel)
  end
end

RubyBot.run

