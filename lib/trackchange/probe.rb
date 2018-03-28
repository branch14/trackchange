require 'logger'
require 'fileutils'
require 'tempfile'
require 'rss'
require 'faraday'
require 'json'

module Trackchange
  class Probe < Struct.new(:config)

    class << self
      def run(config)
        new(config).run
      end
    end

    def run
      config.sites.each { |site| probe(site) }
    end

    def faraday
      @faraday ||= Faraday.new do |f|
        f.request :url_encoded
        f.adapter Faraday.default_adapter
      end
    end

    def slack_defaults
      {
        'username' => 'trackchange',
        'icon_emoji' => ':fax:'
      }
    end

    def probe(site)
      url = site[:url]
      fname = url.sub(%r{https?://}, '').tr_s('/?&', '...')
      site_path = File.expand_path(fname, '~/.trackchange')

      # build cmd
      cmd = config.fetch  + "> #{site_path}.new"
      substitutions = {
        url: url,
        queryscript: File.expand_path('../query.coffee', __FILE__),
        selector: site[:selector]
      }
      substitutions.each { |key, value| cmd = cmd.gsub("%#{key}%", value.to_s) }
      logger.debug "% #{cmd}"
      system cmd

      unless File.exist?(site_path) # new site
        logger.warn "new site #{url}"
        FileUtils.mv("#{site_path}.new", site_path)
        return
      end

      diff = "diff -u #{site_path} #{site_path}.new"
      logger.debug "% #{diff}"
      result = %x[ #{diff} ]

      if result.empty? # same old
        logger.info "same old #{url}"
        FileUtils.rm_f("#{site_path}.new")
        return
      end

      if site[:threshold]
        diffgrepwc = "#{diff} | grep '^[-+]:' | wc -l"
        logger.debug "% #{diffgrepwc}"
        degree = %x[ #{diffgrepwc} ]
        if degree.to_i < site[:threshold].to_i
          logger.warn 'change below threshold, skipping notification'
          skip_notification = true
        end
      end

      # changed
      logger.warn "changed #{url}"
      if pat = config.archive_pattern
        time = File.ctime(site_path).strftime(pat)
        logger.info "archived #{site_path}.#{time}"
        FileUtils.mv(site_path, "#{site_path}.#{time}")
      end
      FileUtils.mv("#{site_path}.new", site_path)

      return if skip_notification

      if slack_hook = config.slack_hook
        message = slack_defaults.merge(config.slack)
        message.text = "#{url}\n\n#{result}"
        faraday.post slack_hook, payload: JSON.unparse(message)
      end

      if email = config.email # send email
        logger.info "sending notification to #{email}"
        begin
          file = Tempfile.new('changetrack')
          file.write "#{url}\n\n#{result}"
          file.close
          mail = "cat #{file.path} | mail -s 'Change detected on #{url}' #{email}"
          logger.debug mail
          system mail
        ensure
          file.unlink
        end
      end

      if file = File.expand_path(config.rss_path, ENV['HOME']) # write rss
        logger.info "update rss feed '#{file}'"

        out_rss = RSS::Maker.make('1.0') do |maker|
          maker.channel.id = %x[ whoami ].chomp
          maker.channel.author = %x[ whoami ].chomp
          maker.channel.updated = Time.now.to_s
          maker.channel.title = "Trackchange"
          maker.channel.link = "http://github.com/brnach14/trackchange"
          maker.channel.about = "Feed of detected changes"
          maker.channel.description = "Feed of detected changes"

          # new item
          maker.items.new_item do |item|
            item.link = "#{url}##{Time.now.to_i}"
            item.title = "Change detected on #{url}"
            item.date = Time.now.to_s
            item.description = "<pre>#{result}</pre>"
          end

          # read rss, keepn old items
          if File.exist?(file)
            in_rss = RSS::Parser.parse(File.read(file))
            in_rss.items.each_with_index do |in_item, index|
              break if index > config.feed_size - 1
              maker.items.new_item do |out_item|
                out_item.link = in_item.link
                out_item.title = in_item.title
                out_item.date = in_item.date
                out_item.description = in_item.description
              end
            end
          end
        end

        # write rss
        if File.exist?(file) and !File.writable?(file)
          raise "'#{file}' is not writable, skipping rss persistency"
        else
          File.open(file, 'w') { |f| f.puts(out_rss) }
        end
      end
    end

    def logger
      return @logger if @logger
      @logger = Logger.new(STDOUT).tap do |logger|
        logger.level = (config.log_level || 2).to_i
        logger.formatter = proc do |severity, datetime, progname, msg|
          "#{msg}\n"
        end
      end
    end

  end
end
