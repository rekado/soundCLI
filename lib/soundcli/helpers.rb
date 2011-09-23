require 'json'
require 'curb'
require 'uri'
require "soundcli/settings"

module Helpers
  # takes a hash:
  #  - target (string)
  #  - ssl    (boolean)
  #  - params (array)
  #  - follow (boolean)
  #
  #  returns HTTP response as hash
  #  - headers
  #  - response
  def self.get(args={})
    return false if args.empty?

    host = args[:ssl] ? (Settings::API_URI_SSL) : (Settings::API_URI)
    params = URI.escape(args[:params].join("&"))
    c = Curl::Easy.new(host+'/'+args[:target]+'.json?'+params)
    c.follow_location = args[:follow]

    begin
      c.http_get
      response = JSON.parse(c.body_str)
      headers = c.header_str
      return {:response => response, :headers => headers}
    rescue
      $stderr.puts "Could not connect"
    end
  end

  def self.resolve(arg)
    unless arg
      $stderr.puts "You didn't give me a soundcloud address to resolve."
      return
    end

    # is an URI, needs resolving
    if arg[/^http/]
      params = ["url=#{arg}", "client_id=#{Settings::CLIENT_ID}"]
      res = self.get({
        :target => 'resolve',
        :ssl    => false,
        :params => params,
        :follow => false
      })
      return unless res

      # get resource id
      r = /^Location: .*\/([0-9]*).json.*/
      m = r.match(res[:headers])
      return m[1] if m

    # its a resource id already
    else
      return arg
    end
  end

  def self.info(resource, id)
    #params = ["access_token=#{AccessToken::get}","client_id=#{Settings::CLIENT_ID}"]
    params = ["client_id=#{Settings::CLIENT_ID}"]
    res = Helpers::get({
      :target => "#{resource}/#{id}",
      :ssl    => false,
      :params => params,
      :follow => true
    })

    raise "Could not get resource info of type `#{resource}' for id #{id}." unless res
    raise res[:response]['errors'][0]['error_message'] if res[:response].has_key? 'errors'
    return res[:response]
  end

  def self.say(s, level)
    max = Settings::all['verbose'].to_sym
    return if max.eql? :mute

    levels = [:mute, :normal, :info, :debug]
    print s if levels.index(level) <= levels.index(max)
  end

  def self.sayn(s, level)
    say("#{s}\n", level)
  end

  def self.bye
    bye = [
      "Fare thee well, fare thee well, you that was once dear to me.\n   --- Think of me with kindness",
      "You say goodbye and I say hello.\n   --- Hello, Goodbye",
      "And in the end the love you take is equal to the love you make\n   --- The End",
      "Whisper words of wisdom, let it be.\n    --- Let it be",
      "Sugar plum fairy, sugar plum fairy.\n    --- A day in the life",
    ]
    self.sayn("\n"+bye[rand(bye.length)], :normal)
  end

  def self.split_text(text)
    words = text.split(' ')
    line_length = 0

    words.inject('') do |r,v|
      line_length+=v.length
      if line_length < Settings::all['comment-width']
        r << v << ' '
        line_length += 1
      else
        r[-1] = "\n" if r.length > 0
        r << v << ' '
        line_length = v.length + 1
      end
      r
    end
  end

  def self.comment_pp(comment)
    user = comment['user']['username']
    text = comment['body']

    puts "\n#{user}:"
    # pretty-print the comment body
    self.split_text(text).each_line {|l| puts ' '*Settings::all['comment-indent-width']+l}
    print "\n"
  end

  # pathetic pretty printer of hashes and arrays of hashes
  def self.data_pp(data, level)
    max = Settings::all['verbose'].to_sym
    return if max.eql? :mute

    levels = [:mute, :normal, :info, :debug]
    return unless levels.index(level) <= levels.index(max)

    print_hash = lambda do |hash|
      # get longets key
      longest = 0
      hash.each_key { |k| longest = k.length if k.length > longest }

      hash.each_pair do |k,v|
        next unless v
        if v.class.eql? Hash
          v.each_pair do |subkey, subvalue|
            puts "#{k.rjust(longest)} |  #{subkey}: #{subvalue}"
            k = ''
          end
        else
          # for strings
          v = self.split_text(v.to_s)
          if v.lines.count <= 1
            puts "#{k.rjust(longest)} |  #{v}"
          else
            v.lines.each_with_index do |line, index|
              puts "#{k.rjust(longest)} |  #{line}"
              k = ''
            end
          end
        end

      end
    end

    if data.class.eql? Hash
      print_hash.call(data)
    elsif data.class.eql? Array
      data.each {|d| print_hash.call(d); print "\n"}
    end
  end
end
