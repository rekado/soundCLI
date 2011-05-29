require 'json'
require 'curb'
require 'uri'

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
	def Helpers::get(args={})
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

	def Helpers::resolve(uri)
		params = ["url=#{uri}", "client_id=#{Settings::CLIENT_ID}"]
		return Helpers::get({
			:target => 'resolve',
			:ssl    => false,
			:params => params,
			:follow => false
		})
	end

end
