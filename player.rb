require 'thread'
require 'gst' #gem install gstreamer

class Player
	def initialize()
		#initialize gst
		Gst.init

		#create a thread for a glib main loop
		thread = Thread.new() do
			@mainloop = GLib::MainLoop.new
			@mainloop.run
		end

		#make the playbin
		@playbin = Gst::ElementFactory.make("playbin")

		#watch the bus for messages
		bus = @playbin.bus
		bus.add_watch do |bus, message|
			handle_bus_message(message)
		end
	end

	# get position of the playbin
	def position()
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

	def set_uri(uri)
		#null the playbin state
		@playbin.set_state(Gst::State::NULL)
		#set the uri
		@playbin.set_property("uri",uri)
	end

	def play
		@playbin.play
	end

	def pause
		@playbin.pause
	end

	def handle_bus_message(msg)
		case msg.type
		when Gst::Message::Type::ERROR
			$stderr.puts msg.parse
			self.quit
		when Gst::Message::Type::EOS
			self.quit
		end
		true
	end
end
