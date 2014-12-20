require 'fileutils'
require 'ostruct'
require 'yaml'

require 'cronedit'

module Trackchange
  class Exec < Struct.new(:args)

    CRON_LINE = '0 7 * * * trackchange probe >/dev/null'

    class << self
      def run(args)
        new(args).run
      end
    end

    def run
      FileUtils.mkdir_p(path) unless File.exist?(path)
      cmd = args.shift
      raise "No command" unless cmd
      return send(cmd) if respond_to?(cmd)
      raise "Unknown command #{cmd}"
    end

    # commands

    def probe
      Probe.run(config)
    end

    def email
      config.email = args.first
      store_config!
    end

    def rss
      config.rss_path = args.first
      store_config!
    end

    def add
      config.sites ||= []
      config.sites |= [ args.first ]
      store_config!
    end

    def list
      config.sites.each_with_index do |url, pos|
        puts "% 4s %s" % [pos+1, url]
      end
    end

    def remove
      pos = args.first.to_i - 1
      raise "Invalid position" if pos == -1
      config.sites.delete_at(pos)
      store_config!
    end

    def install
      CronEdit::Crontab.Add('trackchange', CRON_LINE)
    end

    def uninstall
      CronEdit::Crontab.Remove('trackchange')
    end

    private

    def path
      File.expand_path('~/.trackchange')
    end

    def config_path
      File.join(path, 'config.yml')
    end

    def config
      return @config if @config
      data = { version: VERSION }
      data = YAML.load(File.read(config_path)) if File.exist?(config_path)
      @config = OpenStruct.new(data)
    end

    def store_config!
      File.open(config_path, 'w') { |f| f.print(YAML.dump(config.marshal_dump)) }
    end

  end
end
