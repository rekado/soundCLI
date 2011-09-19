require 'json'
require "soundcli/settings"
require "soundcli/helpers"

module Track
  def self.info(track_id)
    params = ["access_token=#{@token}","client_id=#{Settings::CLIENT_ID}"]
    res = Helpers::get({
      :target => "tracks/#{track_id}",
      :ssl    => false,
      :params => params,
      :follow => true
    })

    unless res
      $stderr.puts "Could not get track info for track id #{track_id}."
      return nil
    end

    return res[:response]
  end

  # gets the comments for a track ID
  def self.comments(args=[], print=true)
    arg = args.shift # only take one argument
    unless arg
      $stderr.puts "You didn't tell me the soundcloud address or the track ID."
      return
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
    return comments
  end

end
