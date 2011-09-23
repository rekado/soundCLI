# SOUNDCLI

soundCLI is a command line client for streaming music from soundcloud. Timed
comments are displayed on the command line as the playback reaches their
respective positions.

## Examples

- Stream 'Chroma' from soundcloud (the keyword 'stream' is optional):


    soundcli stream http://soundcloud.com/rekado/chroma


- Stream three songs from soundcloud:


    soundcli stream http://soundcloud.com/rekado/{chroma,the-human-song,faded}


- Stream all songs in rekado's playlist 'staging':


    soundcli set http://soundcloud.com/rekado/sets/staging/


- Playback all of your favourites:


    soundcli me favorites


- Playback all of your own tracks:


    soundcli me tracks


- Play the local file 'faded.ogg' and display timed comments for the same song
  on soundcloud:


    soundcli play faded.ogg http://soundcloud.com/rekado/faded


## Installation

You can either install this as a gem from RubyGems.org, build the gem yourself,
or execute it without installation. To simply run soundcli, issue the following
command from within the soundcli directory.

    ruby -Ilib ./bin/soundcli http://soundcloud.com/rekado/chroma

Here's how to build and install this gem manually.

    gem build soundcli.gemspec
    gem install ./soundcli-0.0.4.gem

Then you can use this simpler command to stream a song:

    ./bin/soundcli http://soundcloud.com/rekado/chroma

You probably should configure rubygems to install to `/usr/local/bin` or some
other directory that's in your PATH to execute it from any directory.


## Packaging

The preferred way is, of course, to install soundCLI through your
distribution's package manager (pretend you didn't read this if you are using
MacOS). SoundCLI has been packaged for the following GNU/Linux distributions:

- Archlinux (https://aur.archlinux.org/packages.php?ID=51472)

You can inspect the package file descriptions in the directory `pkgdesc`.
Feel free to submit package descriptions for other systems.



## Setup

soundCLI will save your authentication/refresh tokens (not your credentials)
in a file, so you only need to provide your credentials once. The token file
will be saved to $XDG_CONFIG_HOME/soundcli/auth.

    mkdir ~/.config/soundcli


## Dependencies

- ruby (I'm using 1.9.2, but lower versions might work, too)

- gstreamer bindings for ruby (gstreamer)

- cURL bindings for ruby (curb)

- the JSON gem (json)


## Bugs

- download only returns the download url but does not download yet


## Troubleshooting

  **Q:** I get a weird error message when attempting to stream a file:

    No URI handler implemented for "http"
    gsturidecodebin.c(1065): gen_source_element (): /GstPlayBin2:playbin20/GstURIDecodeBin:uridecodebin0

  **A:** You are probably missing some gstreamer plugins. Install a bunch of them through your package management system and see if the error disappears.

  **Q:** When attempting to run soundCLI I get an error:

    no such file to load -- json/gst/curb in ...

  **A:** You need to install the gems listed in the section DEPENDENCIES


## License

This code is licensed under the GPL v3.
