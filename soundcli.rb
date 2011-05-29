require 'json'

require "#{File.dirname(__FILE__)}/settings"
require "#{File.dirname(__FILE__)}/access_token"
require "#{File.dirname(__FILE__)}/curl_helper"
require "#{File.dirname(__FILE__)}/player"

class SoundCLI
	protected
	def authenticate
		token_data = AccessToken::latest
		token_data = AccessToken::new unless token_data
		
		#TODO: only refresh when 401/403
		AccessToken::refresh if token_data
		if token_data and token_data.has_key? 'access_token'
			return token_data['access_token']
		end
		$stderr.puts "Could not authenticate."
		return
	end

	def resolve(uri)
		token = self.authenticate
		return unless token

		params = ["url=#{uri}",
			"client_id=#{Settings::CLIENT_ID}", 
			"access_token=#{token}"
		]

		return self.get('resolve', false, params)
	end

	def get(target, ssl, params)
		uri = ssl ? (Settings::API_URI_SSL) : (Settings::API_URI)
		c = Curl::Easy.new(uri+'/'+target+'.json')
		params = URI.escape(params.join("&"))
		c.url = c.url + '?' + params
		c.follow_location = true

		begin
			c.http_get
			response = JSON.parse(c.body_str)
			headers = c.header_str
			res = {:response => response, :headers => headers}
			return res
		rescue
			$stderr.puts "Could not connect"
			return
		end
	end

	def get_stream_uri(res)
		streamable = res[:response]['streamable']

		unless streamable
			$stderr.puts "This track is not streamable."
			return
		end

		stream = res[:response]['stream_url']

		token = self.authenticate
		return unless token

		params = ["access_token=#{token}","client_id=#{Settings::CLIENT_ID}"]
		return CurlHelper::location(stream, params)
	end



	public
	def features
		hidden = [:usage, :features]
		return (SoundCLI.public_instance_methods - Object.methods - hidden)
	end

	def usage
		"usage: #{$0} #{self.features.join('|')} [url|query]"
	end

	def me
		token = self.authenticate
		return unless token

		params = ["oauth_token=#{token}"]
		res = self.get('me', true, params)
		puts res[:response]
	end

	def download(uri)
		res = self.resolve(uri)
		return false unless res

		downloadable = res[:response]['downloadable']

		unless downloadable
			$stderr.puts "This track cannot be downloaded."
			return false
		end

		#TODO: curl this
		puts res[:response]['download_url']
	end

	# Accepts an address like this:
	#   "http://soundcloud.com/rekado/the-human-song"
	# Gets the actual location and streams it via gstreamer
	def stream(uri)
		print "Resolving target..."

		# get the actual track uri
		res = self.resolve(uri)
		return unless res

		stream = self.get_stream_uri(res)
		puts "FAIL" and return unless stream
		puts "DONE"

		# get comments
		track_id = res[:response]['id']
		params = ["client_id=#{Settings::CLIENT_ID}"]
		res = self.get("tracks/#{track_id}/comments", false, params)
		if res
			comments = res[:response]
			comments.sort! {|a,b| a['created_at'] <=> b['created_at']}
			
			# only leave timed comments
			comments.reject! {|c| c['timestamp'].nil?}
		else
			comments = []
		end

		# TODO: make pausing possible
		begin
			player = Player.new(stream, comments)
			player.play
		rescue Interrupt
		ensure
			player.quit if player
		end
	end

	def search_user(query, limit=5)
		params = ["client_id=#{Settings::CLIENT_ID}",
			"q=#{query}",
			"limit=#{limit}"
		]
		res = self.get('users', false, params)
		puts res[:response]
	end
end
