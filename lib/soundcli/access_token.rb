require 'json'
require 'curb'
require 'uri'
require 'soundcli/settings'

module AccessToken

public

  def self.get
    token_data = self.latest
    token_data = self.new unless token_data
    self.refresh if token_data and self.expired?

    if token_data and token_data.has_key? 'access_token'
      return token_data['access_token']
    else
      raise "Failed to authenticate."
    end
  end

  def self.destroy
    if File.exists?(auth_file)
      if File.unlink(auth_file)
        Helpers::sayn("Deleted authentication and refresh token", :normal)
      else
        $stderr.puts("Failed to remove authentication file.")
      end
    else
      $stderr.puts("Cowardly refusing to remove non-existing authentication file. Schroedinger's cat is dead.")
    end
  end

private

  def self.auth_file
    return Settings::all['path']+'/auth'
  end

  def self.expired?
    token = latest

    raise "cannot check token expiry: no token" unless token
    raise "cannot check token expiry: no auth file (did authorization fail?)" unless File.exists? auth_file

    # the token is considered expired when less than 30 secs validity is left
    expires = File.mtime(auth_file) + token['expires_in']
    (expires - 30) < Time.now
  end

  def self.refresh
    token = latest
    raise "There is no token to refresh." unless token
    params = ['grant_type=refresh_token',
      "refresh_token=#{token['refresh_token']}"]
    post(params)
  end

  def self.latest
    f = auth_file
    JSON.parse(File.read(f)) if File.exists?(f)
  end

  def self.new
    # If authentication_code is the preferred
    # authentication method, but no code has been specified,
    # retry authentication with user credentials
    begin

      if Settings::all['auth-type'] == 'authentication_code'
        unless Settings::all.has_key? 'code'
          # start over
          $stderr.puts "Cannot request access token without code.\nContinuing with default login."
          Settings::all['auth-type'] = 'login'
          raise "retry"
        end
        params = [
          "grant_type=authorization_code",
          "redirect_uri=#{Settings::REDIRECT_URI}",
          "code=#{Settings::all['code']}"
        ]

      elsif Settings::all['auth-type'] == 'login'
        $stdout.flush
        print "\nUsername (email): "
        username = $stdin.gets
        print "Password: "
        password = $stdin.gets

        params = [
          "grant_type=password",
          "username=#{username.chomp}",
          "password=#{password.chomp}"
        ]
      end

    rescue
      retry
    end

    post(params)
  end

  def self.post(params)
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
      raise 'no response from server' unless auth
      hash = JSON.parse(auth)
      raise hash['error'] if hash.has_key? 'error'

      File.open(auth_file, 'w') {|f| f.write(auth) }
      hash
    rescue
      $stderr.puts $!
      nil
    ensure
      File.close(auth_file) if File.exist? auth_file
    end
  end

end
