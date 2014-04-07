require 'logger'
require 'fileutils'
require 'tempfile'
require 'rss'

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
      fname = site.sub(%r{https?://}, '').tr_s('/?&', '...')
      site_path = File.expand_path(fname, '~/.trackchange')
      lynx = "lynx -dump '#{site}' | uniq > #{site_path}.new"
      logger.debug "% #{lynx}"
      system lynx

      unless File.exist?(site_path) # new site
        logger.warn "new site #{site}"
        FileUtils.mv("#{site_path}.new", site_path)
        return
      end

      diff = "diff -u #{site_path} #{site_path}.new"
      logger.debug "% #{diff}"
      result = %x[ #{diff} ]

      if result.empty? # same old
        logger.info "same old #{site}"
        FileUtils.rm_f("#{site_path}.new")
        return
      end

      # changed
      logger.warn "changed #{site}"
      if pat = config.archive_pattern
        time = File.ctime(site_path).strftime(pat)
        logger.info "archived #{site_path}.#{time}"
        FileUtils.mv(site_path, "#{site_path}.#{time}")
      end
      FileUtils.mv("#{site_path}.new", site_path)

      if email = config.email # send email
        logger.info "sending notification to #{email}"
        begin
          file = Tempfile.new('changetrack')
          file.write(result)
          file.close
          mail = "cat #{file.path} | mail -s 'Trackchange: #{site}' #{email}"
          logger.debug mail
          system mail
        ensure
          file.unlink
        end
      end

      if rss_path = config.rss_path # write rss
        logger.info "update feed #{rss_path} (not realy, yet)"
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
