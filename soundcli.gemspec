Gem::Specification.new do |s|
  s.name          = 'soundcli'
  s.version       = '0.0.5'
  s.date          = '2011-09-24'
  s.summary       = "CLI client for soundcloud"
  s.description   = "Stream music from soundcloud on the command line and read timed comments."
  s.authors       = ["Ricardo Wurmus"]
  s.email         = 'ricardo.wurmus@gmail.com'
  s.homepage      = 'http://soundcli.elephly.net'
  s.files         = [ "bin/soundcli",
                      "conf/soundcli.conf",
                      "man/man1/soundcli.1.gz",
                      "lib/soundcli.rb",
                      "lib/soundcli/track.rb",
                      "lib/soundcli/helpers.rb",
                      "lib/soundcli/player.rb",
                      "lib/soundcli/access_token.rb",
                      "lib/soundcli/settings.rb" ]

  s.executables   = ["soundcli"]

  s.add_dependency('gstreamer', '~> 1.0.0')
  s.add_dependency('curb', '>= 0.7.15')
  s.add_dependency('json', '>= 1.5.3')
end
