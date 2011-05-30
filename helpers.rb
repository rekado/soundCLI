require 'json'
require 'curb'
require 'uri'
require "#{File.dirname(__FILE__)}/settings"

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

	def Helpers::comment_pp(comment)
		user = comment['user']['username']
		text = comment['body']


		puts "\n#{user}:"
		# pretty-print the comment body
		words = text.split(' ')
		line_length = 0
		formatted = words.inject('') do |r,v|
			line_length+=v.length
			if line_length < Settings::all['comment_width']
				r << v << ' '
				line_length += 1
			else
				r[-1] = "\n"
				r << v << ' '
				line_length = v.length + 1
			end
			r
		end

		formatted.each_line {|l| puts ' '*Settings::all['comment_indent_width']+l}
		print "\n"
	end
end
