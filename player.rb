require 'gst'

class Player
	def initialize(uri, comments)
		@comments = comments
		@comment_ptr = 0

		Gst.init
		# create the playbin
		@playbin = Gst::ElementFactory.make("playbin2")

		# TODO: buffer still runs out
		@playbin.set_property("buffer-size", 512_000)
		@playbin.set_property("buffer-duration", 5_000_000_000)

		@playbin.set_property("uri",uri)

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
		GLib::Timeout.add(100) do 
			timestamp = self.position.parse[1]/1000000

			if self.playing? and @comment_ptr < @comments.length
				c = @comments[@comment_ptr]

				if timestamp > c['timestamp']
					$stdout.flush
					puts "\n#{c['user']['username']}:"
					# TODO: pretty print the comment body
					puts "   #{c['body']}"
					@comment_ptr+=1
				end
			end
			true
		end
		@mainloop = GLib::MainLoop.new
		@mainloop.run
	end

	def resume
		@playbin.set_state(Gst::State::PLAYING)
		@playbin.play
	end

	def pause
		@playbin.set_state(Gst::State::PAUSED)
		@playbin.pause
	end

	def handle_bus_message(msg)
		case msg.type
		when Gst::Message::Type::BUFFERING
			buffer = msg.parse
			if buffer < 100
				self.pause if self.playing?
				print "Buffering: #{buffer}%  \r"
			else
				print "                       \r"
				self.resume if self.paused?
			end
			$stdout.flush
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
		return (@playbin.get_state[1] == Gst::State::NULL)
	end

	def playing?
		return (@playbin.get_state[1] == Gst::State::PLAYING)
	end

	def paused?
		return (@playbin.get_state[1] == Gst::State::PAUSED)
	end
end
