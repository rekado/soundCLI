Gem::Specification.new do |s|
  s.name        = 'soundcli'
  s.version     = '0.1'
  s.date        = '2011-08-06'
  s.summary     = "CLI client for soundcloud"
  s.description = "Stream music from soundcloud on the command line and read timed comments."
  s.authors     = ["Ricardo Wurmus"]
  s.email       = 'ricardo.wurmus@gmail.com'
  s.homepage    = 'http://soundcli.elephly.net'
  s.files       = [ "bin/soundcli",
                    "lib/soundcli.rb",
                    "lib/soundcli/track.rb",
                    "lib/soundcli/helpers.rb",
                    "lib/soundcli/player.rb",
                    "lib/soundcli/access_token.rb",
                    "lib/soundcli/settings.rb" ]
end
