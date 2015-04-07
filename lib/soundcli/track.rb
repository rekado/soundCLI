require 'json'
require "soundcli/settings"
require "soundcli/helpers"

module Track
  def self.id_from_stream(stream_url)
    m = stream_url.match(/\/([0-9]+)\/stream/)
    track_id = m[1] if m
    unless track_id
      $stderr.puts "Failed to fetch track id."
      return
    end
    track_id
  end

  def self.info(input)
    # is already a resolved resource location?
    if input[/^(http|https):\/\/api.soundcloud.com/]
      track_id = self.id_from_stream(input)
    # a normal soundcloud link
    else
      Helpers::say("Getting track ID for input #{input}...", :info)
      track_id = Helpers::resolve(input)
      Helpers::sayn(track_id, :info)
      raise "Failed to fetch track id." unless track_id
    end

    Helpers::say("Getting track info...", :info)
    res = Helpers::info('tracks', track_id)
    streamable = res['streamable']
    raise "This track is not streamable." unless streamable
    raise "Oops, no stream URL for this track." if res['stream_url'].empty?
    res
  end

  # gets the comments for a track ID
  def self.comments(arg, print=true)
    unless arg
      $stderr.puts "You didn't tell me the soundcloud address or the track ID."
      return []
    end

    comments = []

    # get comments
    track_id = arg
    params = ["client_id=#{Settings::CLIENT_ID}"]
    res = Helpers::get({
      :target => "tracks/#{track_id}/comments",
      :ssl    => false,
      :params => params,
      :follow => true
    })
    if res
      comments = res[:response]
      # only leave timed comments
      comments.reject! {|c| c['timestamp'].nil?}
      # sort by timestamp first, then by time posted
      comments.sort! do |a,b|
        comp = (a['timestamp'] <=> b['timestamp'])
        comp.zero? ? (a['created_at'] <=> b['created_at']) : comp
      end
    end

    puts comments if print
    comments
  end

end
