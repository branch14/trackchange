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

    def slack
      config.slack_hook = args.first
      store_config!
    end

    def add
      config.sites ||= []
      config.sites |= [ { url: args.first } ]
      store_config!

      # instant probe on add
      config.sites = [ { url: args.first } ]
      Probe.new(config).probe(config.sites.last)
    end

    def list
      config.sites.each_with_index do |site, pos|
        puts "% 4s %s" % [pos+1, site[:url]]
      end
    end

    # TODO refactor to make remove code duplication
    def test
      pos = args.first.to_i - 1
      raise "Invalid position" if pos == -1
      site = config.sites[pos]
      url = site[:url]

      cmd = config.fetch
      substitutions = {
        url: url,
        queryscript: File.expand_path('../query.coffee', __FILE__),
        selector: site[:selector]
      }
      substitutions.each { |key, value| cmd = cmd.gsub("%#{key}%", value.to_s) }
      puts "% #{cmd}"
      puts %x[#{cmd}]
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

    def default_config
      {
        version: VERSION,
        fetch: "lynx -nolist -dump '%url%' | uniq"
      }
    end

    def config
      return @config if @config
      data = default_config
      data = YAML.load(File.read(config_path)) if File.exist?(config_path)

      # upgrade from <= 0.2.0
      if v(data[:version]) <= v('0.2.0')
        data[:version] = '0.2.0'
        data[:sites] = data[:sites].map do |site|
          { url: site }
        end
        @config = OpenStruct.new(data)
        store_config!
      end

      # upgrade from 0.3.0 to 0.4.0
      if v(data[:version]) < v('0.4.0')
        data[:version ] = '0.4.0'
        data[:fetch] = default_config[:fetch]
        data[:feed_size] = 20
        @config = OpenStruct.new(data)
        store_config!
      end

      @config = OpenStruct.new(data)
    end

    def store_config!
      File.open(config_path, 'w') { |f| f.print(YAML.dump(config.marshal_dump)) }
    end

    def v(version)
      Gem::Version.new(version)
    end

  end
end
