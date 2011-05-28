require 'json'

module Settings
	PRG_NAME      = "soundCLI"
	CLIENT_ID     = "a0f81a06bbce9c2995ef16b87eb87820"
	CLIENT_SECRET = "1871359cfbc4bb8da074de5005adbac8"
	REDIRECT_URI  = "http://soundcli.wurmus.de/oauth-callback"
	CONNECT_URI   = "https://soundcloud.com/connect?client_id=#{CLIENT_ID}&response_type=code&redirect_uri=#{REDIRECT_URI}"
	TOKEN_URI     = "https://api.soundcloud.com/oauth2/token"
	API_URI_SSL   = "https://api.soundcloud.com"
	API_URI       = "http://api.soundcloud.com"

	@@config = {}
	@@auth_code = false
		# TODO: read from config
	@@auth_type = :login #:authentication_code

	def Settings::all
		return @@config
	end

	def Settings::set_auth_type(v)
		@@auth_type = v
	end

	def Settings::auth_type
		return @@auth_type
	end

	def Settings::auth_code_available
		return @@auth_code
	end

	def Settings::init(arguments)
		if arguments
			# TODO: build config from arguments
		end
		$stderr.puts "An error occurred when parsing the configuration file." unless Settings::parse_config

		return true if Settings::auth_type == :login

		# check if an auth code exists
		if Settings::all.has_key? 'code'
			@@auth_code = true
		else
			print <<EOF
You did not specify your authorization code.
If you don't have one, you should first authorize soundCLI.

Visit this URI:
#{Settings::CONNECT_URI}

You will be given an authorization code, which you should
add to soundcli.conf in $XDG_CONFIG_HOME.

If you choose not to connect soundCLI with your soundcloud
account, you may want to change the preferred authentication
type in your configuration file to 'login'.
EOF
		end
	end

	def Settings::parse_config
		config_file = "#{PRG_NAME.downcase}.conf"
		config_path = ENV['XDG_CONFIG_HOME'] or ENV['HOME']+'/.config'
		config_path = config_path + "/#{PRG_NAME.downcase}"
		cf = "#{config_path}/#{config_file}"
		return false unless File.exists? cf

		begin
			@@config['path'] = config_path
			@@config.merge!(JSON.parse(File.read(cf)))
			return true
		rescue
			$stderr.puts "Your configuration file contains errors."
			return false
		end
	end
end
