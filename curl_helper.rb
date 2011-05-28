require 'curb'
require 'uri'

module CurlHelper
	def CurlHelper::location(uri, params)
		c = Curl::Easy.new(uri)
		params = URI.escape(params.join("&"))
		c.url = c.url + '?' + params
		c.follow_location = false

		begin
			c.http_get
			r = /^Location: (.*)/
			m = r.match c.header_str
			if m
				return m[1]
			else
				return nil
			end
		rescue
			$stderr.puts "Could not connect"
			return nil
		end
	end
end
