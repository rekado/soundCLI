require 'gst'
require "soundcli/settings"
require "soundcli/helpers"

class Player
  def initialize
    # create the playbin
    @playbin = Gst::ElementFactory.make("playbin2")
    #watch the bus for messages
    bus = @playbin.bus
    bus.add_watch do |bus, message|
      handle_bus_message(message)
    end
  end

  def set(uri, comments)
    @comments = comments
    @comment_ptr = 0

    @playbin.set_property("buffer-size", Settings::all['buffer-size'])
    @playbin.set_property("uri",uri)
  end

  protected
  def ns_to_str(ns)
    return nil if ns < 0
    time = ns/1_000_000_000
    hours = time/3600.to_i
    minutes = (time/60 - hours * 60).to_i
    seconds = (time - (minutes * 60 + hours * 3600))
    if hours > 0
      return "%02d:%02d:%02d" % [hours, minutes, seconds]
    else
      return "%02d:%02d" % [minutes, seconds]
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

  # get song duration
  def duration
    begin
      @query_duration = Gst::QueryDuration.new(Gst::Format::TIME)
      @playbin.query(@query_duration)
      pos = @query_duration
    rescue
      pos = 0
    end
    return pos
  end

  public
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
      @duration = self.ns_to_str(self.duration.parse[1]) if (@duration.nil?)
      @position = self.ns_to_str(self.position.parse[1])
      timestamp = self.position.parse[1]/1000000

      if self.playing?
        Helpers::say("#{@position}/#{@duration}  \r", :normal)
        $stdout.flush
      end

      if (not Settings::all['verbose'].eql? 'mute') and
        self.playing? and
        @comment_ptr < @comments.length

        c = @comments[@comment_ptr]

        if timestamp > c['timestamp']
          $stdout.flush
          Helpers::comment_pp(c)
          @comment_ptr+=1
        end
      end
      true
    end
    @mainloop = GLib::MainLoop.new
    iochannel = GLib::IOChannel.new(1)
    iochannel.add_watch(GLib::IOChannel::IN) {|channel, condition|
      input = channel.readline
      if input["\n"]
        if playing?
          self.pause
        else
          self.resume
        end
      end
      true
    }
    @mainloop.run
  end

  def resume
    @playbin.set_state(Gst::State::PLAYING)
    @playbin.play
  end

  def pause
    @playbin.set_state(Gst::State::PAUSED)
    @playbin.pause
    Helpers::say("--- PAUSED ---\r", :normal)
  end

  def handle_bus_message(msg)
    case msg.type
    when Gst::Message::Type::BUFFERING
      buffer = msg.parse
      if buffer < 100
        Helpers::say("Buffering: #{buffer}%  \r", :normal)
        self.pause if self.playing?
      else
        Helpers::say("                       \r", :normal)
        self.resume if self.paused?
      end

      $stdout.flush
    when Gst::Message::Type::ERROR
      @playbin.set_state(Gst::State::NULL)
      $stderr.puts msg.parse
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
