require 'json'

module Settings
  PRG_NAME      = "soundCLI"
  CLIENT_ID     = "a0f81a06bbce9c2995ef16b87eb87820"
  CLIENT_SECRET = "1871359cfbc4bb8da074de5005adbac8"
  REDIRECT_URI  = "http://soundcli.elephly.net/oauth-callback"
  CONNECT_URI   = "https://soundcloud.com/connect?client_id=#{CLIENT_ID}&response_type=code&redirect_uri=#{REDIRECT_URI}"
  TOKEN_URI     = "https://api.soundcloud.com/oauth2/token"
  API_URI_SSL   = "https://api.soundcloud.com"
  API_URI       = "http://api.soundcloud.com"

  @config = {}

  def self.all
    @config
  end

  def self.init(arguments)
    if arguments
      # TODO: build config from arguments
    end
    $stderr.puts "No config file found or error parsing it. Ignoring." unless parse_config

    return true if all['auth-type'] == 'login'

    # check if an auth code exists
    unless all.has_key? 'code'
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

  def self.parse_config
    config_file = "#{PRG_NAME.downcase}.conf"
    config_path = ENV['XDG_CONFIG_HOME'] or ENV['HOME']+'/.config'
    config_path = config_path + "/#{PRG_NAME.downcase}"
    cf = "#{config_path}/#{config_file}"
    @config['path'] = config_path

    # defaults
    @config['auth-type'] = 'login'
    @config['verbose'] = 'normal'
    @config['buffer-size'] = 512_000
    @config['comment-width'] = 50
    @config['comment-indent-width'] = 4

    Helpers::sayn(config_path, :debug)

    return false unless File.exists? cf

    # overwrite from config file
    begin
      json = File.read(cf)
      # strip comments and empty lines
      json.gsub!(/^ *#.*\n/,"")
      json.gsub!(/^ *\n/,"")
      # jsonify keys
      json.gsub!(/^([^ :]*)/, "\"\\1\"")
      # add commas at the end of lines and wrap in braces
      json.gsub!(/\n/,",")
      json = "{" << json
      json[-1] = "}"
      Helpers::sayn(json, :debug)

      @config.merge!(JSON.parse(json))
      return true
    rescue
      $stderr.puts "Your configuration file contains errors."
      return false
    end
  end
end
