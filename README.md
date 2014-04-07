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


## Usage (CLI)

### Probe

    trackchange probe

### Set email

    trackchange email <email>

### Set path to store RSS feed

    trackchange rss <path>

### Add site

    trackchange add <url>


## Usage (as library)

    TODO


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
