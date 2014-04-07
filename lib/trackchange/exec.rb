require 'fileutils'
require 'ostruct'
require 'yaml'

module Trackchange
  class Exec < Struct.new(:args)

    class << self
      def run(args)
        new(args).run
      end
    end

    def run
      FileUtils.mkdir_p(path) unless File.exist?(path)
      cmd = args.shift
      return send(cmd) if respond_to?(cmd)
      raise "Unknown command #{cmd}"
    end

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
