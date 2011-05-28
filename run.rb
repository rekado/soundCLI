#!/usr/bin/env ruby

require "#{File.dirname(__FILE__)}/soundcli"
require "#{File.dirname(__FILE__)}/settings"

Settings::init(ARGV)
app = SoundCLI.new

if ARGV.length < 1
	puts app.usage
	Process.exit 1
end

if app.features.include? ARGV[0].to_sym
	if ARGV[1]
		app.method(ARGV[0]).call(ARGV[1]) 
	else
		app.method(ARGV[0]).call
	end
else
	$stderr.puts "No such action: #{ARGV[0]}"
	$stderr.puts app.usage and Process.exit(1)
end
