require 'thread'
require 'gst' #gem install gstreamer

class Player
	def initialize(uri, comments)
		#initialize gst
		Gst.init

		@comments = comments

		#make the playbin
		@playbin = Gst::ElementFactory.make("playbin2")
		@playbin.set_property("uri",uri)
		@playbin.set_property("buffer-size",512000)

		#watch the bus for messages
		bus = @playbin.bus
		bus.add_watch do |bus, message|
			handle_bus_message(message)
		end
	end

	# get position of the playbin
	def position
		begin
			@query_position = Gst::QueryPosition.new(Gst::Format::TIME)
			@playbin.query(@query_position)
			pos = @query_position
		rescue
			pos = 0
		end
		return pos
	end

	#set or get the volume
	def volume(v)
		@playbin.set_property("volume", v) if v and (0..1).cover? v
		return @playbin.get_property("volume")
	end

	def quit
		@playbin.stop
		@mainloop.quit
	end

	def play
		@playbin.play
		GLib::Timeout.add(1000) do 
			puts "pos: #{self.position.parse[1]}" #if self.playing?
			true
		end
		@mainloop = GLib::MainLoop.new
		@mainloop.run
	end

	def pause
		puts "--- paused ---"
		@playbin.pause
	end

	def handle_bus_message(msg)
		print "                             \r"
		$stdout.flush
		case msg.type
		when Gst::Message::Type::BUFFERING
			buffer = msg.parse
			if buffer < 90
				@playbin.set_state(Gst::State::PAUSED)
				print "Buffering: #{buffer}%  \r"
				$stdout.flush
			else
				@playbin.set_state(Gst::State::PLAYING)
			end
		when Gst::Message::Type::ERROR
			@playbin.set_state(Gst::State::NULL)
			self.quit
		when Gst::Message::Type::EOS
			@playbin.set_state(Gst::State::NULL)
			self.quit
		end
		true
	end

	def done?
		return false unless @playbin.get_state.eql? Gst::State::NULL
	end

	def playing?
		return true if @playbin.get_state.eql? Gst::State::PLAYING
	end

	def paused?
		return true if @playbin.get_state.eql? Gst::State::PAUSED
	end
end
