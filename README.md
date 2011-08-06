# SOUNDCLI

soundCLI is a command line client for streaming music from soundcloud. Timed
comments are displayed on the command line as the playback reaches their
respective positions.

## Examples

- Stream 'Chroma' from soundcloud (the keyword 'stream' is optional):


    ./soundcli.rb stream http://soundcloud.com/rekado/chroma


- Play the local file 'faded.ogg' and display timed comments for the same song on soundcloud:


    ./soundcli.rb play faded.ogg http://soundcloud.com/rekado/faded


## Setup

soundCLI will save your authentication/refresh tokens (not your credentials)
in a file, so you only need to provide your credentials once. The token file
will be saved to $XDG_CONFIG_HOME/soundcli.

    mkdir ~/.config/soundcli


## Dependencies

- ruby (I'm using 1.9.2, but lower versions might work, too)

- gstreamer bindings for ruby (gst)

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
