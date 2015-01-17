require 'logger'
require 'fileutils'
require 'tempfile'
require 'rss/maker'
require 'pry'

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

    def probe(site)
      url = site[:url]
      fname = url.sub(%r{https?://}, '').tr_s('/?&', '...')
      site_path = File.expand_path(fname, '~/.trackchange')
      lynx = "lynx -dump '#{url}' | uniq > #{site_path}.new"
      logger.debug "% #{lynx}"
      system lynx

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

      if rss_path = config.rss_path # write rss
        logger.info "update feed #{rss_path}"
        rss = RSS::Maker.make('1.0') do |m|
          m.channel.title='Trackchange'; 
          m.channel.about='Trackchange'; 
          m.channel.link='http://localhost'; 
          m.channel.description='Trackchanges of websites - see github.com/branch14/trackchange';
          i = m.items.new_item;
          i.title=
          i.link=url
          i.description="<pre>#{result}</pre>"
          i.date=Time.now()
        end
        if (!File.writable?(config.rss_path)) 
          logger.warn "'#{config.rss_path}' is not writable, skipping rss persistency"
        else
          file = File.new(config.rss_path,"w")
          file.write rss
          file.close
       end

      end
    end

    def logger
      return @logger if @logger
      @logger = Logger.new(STDOUT).tap do |logger|
        logger.level = (config.log_level || 2).to_i
      end
    end

  end
end
