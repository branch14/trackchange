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

    # Set slack hook
    trackchange slack <url>

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

    lynx -nolist -dump '%url%' | uniq

Here are some alternatives you might want to experiment
with. (Unfortunately pandoc only works with http, not with https and
does not follow redirects, hence the version with curl.)

    lynx -dump '%url%' | uniq | sed -e "/References/,/\s+[0-9]+\. h/d"

    lynx -nolist -dump '%url%' | uniq

    pandoc '%url%' -t markdown

    pandoc '%url%' -t plain

    curl -sL '%url%' | pandoc -t plain

    phantomjs %queryscript% '%url%' '%selector%'

### slack_hook (optional)

...

### slack (optional)

Allows to change the defaults. Example...

```
:slack:
  channel: '@user'
  username: 'change agent'
  icon_emoji: ':squirrel:'
```

### rss_path (optional)

...

### feed_size (optional)

...

### log_level (optional)

...

### sites (mandatory)

A list of sites, with the following properites.

#### url (mandatory)

The url of the site to be tracked.

#### threshold (optional)

If a threshold is given, no notification will be sent if the number of
changed lines is below or equal the given vaule.

#### selector (optional)

If a selector is given, it will be used as a CSS3 selector to reduce
the output to. The selector feature is only available if trackchange
is configured to use phantomjs to fetch the content, i.e.

    fetch: phantomjs %queryscript% '%url%' '%selector%'

The query script will return plain text. If no selector is given, the
query script will select the body tag by default.


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
