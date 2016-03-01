module Mist
  class Pool
    def self.get
      @@pool ||= Pool.new(Mutex.new)
    end

    def initialize(mutex)
      @mutex = mutex

      @available = []
      @busy = []
    end

    def add(server)
      @mutex.synchronize {
        @available << server
      }
    end

    def remove(server)
      @mutex.synchronize {
        @available.delete server if @available.include? server
        @busy.delete server if @busy.include? server
      }
    end

    def acquire
      server = nil
      # Get the first available client; loop until one becomes available
      loop do
        @mutex.synchronize {
          server = @available.pop unless @available.empty?
          @busy.push server unless server.nil? 
        }
        break if server
        sleep 1
      end

      return server
    end

    def release(server)
      # Put the server back in the available list; if the server was removed
      # while we were using it, don't put it back.
      @mutex.synchronize {
        @available.push server if @busy.include? server
        @busy.delete server if @busy.include? server
      }
    end
  end
end
