require "soundcli/settings"
require "soundcli/access_token"
require "soundcli/player"
require "soundcli/track"
require "soundcli/helpers"

class SoundCLI
  public

  def features
    hidden = [:usage, :features]
    return (SoundCLI.public_instance_methods - Object.methods - hidden)
  end

  def usage
    puts "Usage: #{$0} #{self.features.join('|')} [url|query]"
    print <<EOF


EXAMPLES:

   Play a track by URL:
       #{$0} stream http://soundcloud.com/rekado/the-human-song
       #{$0} http://soundcloud.com/rekado/the-human-song

   Play a track by ID:
       #{$0} stream 15966266
       #{$0} 15966266

   Stream a whole playlist:
       #{$0} set http://soundcloud.com/rekado/sets/staging/

   Stream all of your favourite tracks:
       #{$0} me favorites

   Stream all of the tracks on your dashboard:
       #{$0} me activities



UNFINISHED STUFF:

   Show my user info:
       #{$0} me

   List my tracks:
       #{$0} me tracks

   List my exclusive tracks:
       #{$0} me activities tracks exclusive

   Search for a user:
       #{$0} search_user fronx
EOF

  end

  def user(args=[])
    res = self.search_user(args[0], 1)
    id = res[0]['id']

    params = ["client_id=#{Settings::CLIENT_ID}"]
    res = Helpers::get({
      :target => "users/#{id}/tracks",
      :ssl    => true,
      :params => params,
      :follow => true
    })
    return unless res

    tracks = res[:response].map{|i|i['stream_url']}
    self.stream tracks
  end

  def me(args=[])
    token = AccessToken::get
    params = ["oauth_token=#{token}"]
    if ['favorites', 'tracks'].include? args[0]
      res = Helpers::get({
        :target => 'me/'+args[0],
        :ssl    => true,
        :params => params,
        :follow => true
      })
      tracks = res[:response].map{|i|i['stream_url']}
      self.stream tracks
    elsif ['activities'].include? args[0]
      res = Helpers::get({
        :target => 'me/'+args[0],
        :ssl    => true,
        :params => params,
        :follow => true
      })
      tracks = res[:response]['collection'].select{|i| i['type'].eql? 'track'}
      tracks = tracks.map{|i|i['origin']['stream_url']}
      self.stream tracks
    else
      sub = (args.length > 0) ? ('/'+args.join('/')) : ('')
      res = Helpers::get({
        :target => 'me'+sub,
        :ssl    => true,
        :params => params,
        :follow => true
      })
      Helpers::data_pp(res[:response], :normal)
    end
  end

  def download(args=[])
    token = AccessToken::get
    Helpers::say("Getting track ID...", :info)
    track_id = Helpers::resolve(args[0])
    Helpers::sayn(track_id, :info)

    unless track_id
      $stderr.puts "Failed to fetch track id."
      return false
    end

    res = Helpers::info('tracks', track_id)
    downloadable = res['downloadable']

    unless downloadable
      $stderr.puts "This track cannot be downloaded."
      return false
    end

    uri = res['download_url']
    return false unless uri

    #TODO: curl this
    params = ["access_token=#{token}","client_id=#{Settings::CLIENT_ID}"]
    puts uri+'?'+params.join('&')
  end

  # Accepts a list of addresses like this:
  #   http://soundcloud.com/rekado/the-human-song
  # or this
  #   http://api.soundcloud.com/tracks/15909195/stream
  # or track IDs.
  # Gets the actual location and streams it via gstreamer
  def stream(args=[])
    player = Player.new()

    args.each do |arg|
      begin
        res = Track::info(arg)
        Helpers::data_pp(res, :info)
        comments = Track::comments(res['id'], false)
      rescue
        $stderr.puts $!
        next
      end

      begin
        params = ["client_id=#{Settings::CLIENT_ID}"]
        # TODO: token is only needed for private tracks, but private tracks fail earlier
        #params.push "access_token=#{token}" if self.authenticated?
        Helpers::sayn(res['stream_url']+'?'+params.join('&'), :debug)
        title = "Now playing: \"#{res['title']}\""
        Helpers::sayn("\n\n"+title+"\n"+"=" * title.length, :normal)
        player.set(res['stream_url']+'?'+params.join('&'), comments)
        player.play
      rescue Interrupt
      ensure
        player.quit if player
      end
    end
  end

  # Accepts a local file and an address like this
  #   "http://soundcloud.com/rekado/the-human-song"
  # or a track ID.
  # Plays the local file and shows soundcloud comments
  def play(args=[])
    if args.length < 2
      $stderr.puts "I need a local file name and a soundcloud address / track ID."
      return false
    end
    location = File.absolute_path(args[0])
    unless File.exists? location
      $stderr.puts "#{args[0]} doesn't seem to be a file."
      return false
    end

    track_id = Helpers::resolve(args[1])
    unless track_id
      $stderr.puts "I could not find this track on soundcloud: #{args[1]}."
      return false
    end

    comments = Track::comments(track_id, false)
    begin
      player = Player.new()
      player.set('file://'+location, comments)
      player.play
    rescue Interrupt
    ensure
      player.quit if player
    end
  end

  def set(args=[])
    set_id = Helpers::resolve(args[0])
    unless set_id
      $stderr.puts "Failed to fetch playlist id."
      return false
    end

    Helpers::say("Getting playlist info...", :info)
    res = Helpers::info('playlists', set_id)
    Helpers::data_pp(res['tracks'], :debug)
    tracks = res['tracks'].map{|t| t['stream_url']}
    self.stream tracks
  end

  def search_user(query, limit=5)
    params = ["client_id=#{Settings::CLIENT_ID}",
      "q=#{query}",
      "limit=#{limit}"
    ]
    res = Helpers::get({
      :target => 'users',
      :ssl    => false,
      :params => params,
      :follow => true
    })
    Helpers::data_pp(res[:response], :normal)
  end

  def revoke
    AccessToken::destroy
  end

end
