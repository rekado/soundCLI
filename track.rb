require 'json'
require "#{File.dirname(__FILE__)}/settings"
require "#{File.dirname(__FILE__)}/helpers"

module Track
	def Track::id(arg) 
		unless arg
			$stderr.puts "You didn't tell me the soundcloud address or the track ID."
			return nil
		end

		# is an URI, needs resolving
		if arg[/^http/]
			# get the actual track uri
			res = Helpers::resolve(arg)
			return nil unless res

			# get track id
			r = /^Location: .*\/([0-9]*).json.*/
			m = r.match(res[:headers])
			track_id = m[1] if m

		# its a track id
		else
			track_id = arg
		end
		return track_id
	end

	def Track::info(track_id)
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
	def Track::comments(args=[], print=true)
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
