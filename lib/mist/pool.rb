require 'json'

module Mist
  class Pool
    def self.get
      @@pool ||= nil
      if @@pool.nil?
        @@pool = Pool.new(Mutex.new)
        begin
          config_file = ENV['MIST_CONFIG'] || File.join(%w(/ etc mist config))
          config = JSON.parse(File.read(config_file))

          raise 'no nodes defined' unless config.key? 'servers'

          config['servers'].each do |server|
            @@pool.add(server)
          end
        rescue StandardError => ex
          Mist.logger.error "couldn't load config file: #{ex}"
        end
      end
      @@pool
    end

    def initialize(mutex)
      @mutex = mutex

      @available = []
      @busy = []
    end

    def add(server)
      @mutex.synchronize do
        @available << server
      end
    end

    def remove(server)
      @mutex.synchronize do
        @available.delete server if @available.include? server
        @busy.delete server if @busy.include? server
      end
    end

    def acquire
      server = nil
      # Get the first available client; loop until one becomes available
      loop do
        @mutex.synchronize do
          server = @available.pop unless @available.empty?
          @busy.push server unless server.nil?
        end
        break if server
        sleep 1
      end

      return server
    end

    def release(server)
      # Put the server back in the available list; if the server was removed
      # while we were using it, don't put it back.
      @mutex.synchronize do
        @available.push server if @busy.include? server
        @busy.delete server if @busy.include? server
      end
    end
  end
end
