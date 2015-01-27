# Trackchange

Track changes to websites by probing them on a regular basis. Changes
will be reported via email and/or RSS feed.


## Installation

Add this line to your application's Gemfile:

    gem 'trackchange'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install trackchange


## Usage

    # Set email
    trackchange email <email>

    # Set path to store RSS feed
    trackchange rss <path>

    # Add site
    trackchange add <url>

    # List sites
    trackchange list

    # Remove site
    trackchange remove <pos>

    # Probe
    trackchange probe

    # Install probe into crontab
    trackchange install

    # Uninstall probe from crontab
    trackchange uninstall


## Configuration

Trackchange creates its configuration file in `~/.trackchange/config.yml`.

### fetch

This is the command to fetch the tracked sites. `%url%` will be
substituted by the requested site url.

The default command is

    lynx -dump '%url%' | uniq

Here are some alternatives you might want to experiment
with. (Unfortunately pandoc only works with http, not with https and
does not follow redirects, hence the version with curl.)

    lynx -dump '%url%' | uniq | sed -e "/References/,/\s+[0-9]+\. h/d"
    
    lynx -nolist -dump '%url%' | uniq

    pandoc '%url%' -t markdown

    pandoc '%url%' -t plain

    curl -sL '%url%' | pandoc -t plain

### rss_path

...

### feed_size

...

### log_level

...


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
