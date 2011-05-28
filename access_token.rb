require 'json'
require 'curb'
require 'uri'
require "#{File.dirname(__FILE__)}/settings"

module AccessToken
	def AccessToken::auth_file
		return Settings::all['path']+'/auth'
	end

	def AccessToken::refresh
		token = AccessToken::latest
		$stderr.puts "There is no token to refresh." and return false unless token
		params = ['grant_type=refresh_token',
			        "refresh_token=#{token['refresh_token']}"]
		return AccessToken::post(params)
	end

	def AccessToken::latest
		f = AccessToken::auth_file
		return JSON.parse(File.read(f)) if File.exists? f
		return nil
	end

	def AccessToken::new
		# If authentication_code is the preferred
		# authentication method, but no code has been specified,
		# retry authentication with user credentials
		begin

			if Settings::auth_type == :authentication_code
				unless Settings::auth_code_available
					# start over
					$stderr.puts "Cannot request access token without code.\nContinuing with default login."
					Settings::set_auth_type(:login)
					raise "retry" 
				end
				params = [
					"grant_type=authorization_code",
					"redirect_uri=#{Settings::REDIRECT_URI}",
					"code=#{Settings::all['code']}"
				]

			elsif Settings::auth_type == :login
				print "Username (email): "
				username = gets
				print "Password: "
				password = gets

				params = [
					"grant_type=password", 
					"username=#{username.chomp}",
					"password=#{password.chomp}"
				]
			end

		rescue
			retry
		end

		return AccessToken::post(params)
	end

	def AccessToken::post(params)
		c = Curl::Easy.new(Settings::TOKEN_URI)
		default_params = [
			"client_id=#{Settings::CLIENT_ID}",
			"client_secret=#{Settings::CLIENT_SECRET}"
		]

		params = default_params << params
		params = URI.escape(params.join("&"))
		begin
			c.http_post(params)
			auth = c.body_str
			File.open(AccessToken::auth_file, 'w') {|f| f.write(auth) } if auth
			return JSON.parse(auth)
		rescue
			$stderr.puts "Could not post/save access token."
			return nil
		end
	end

end
