require 'msgpack/rpc'
require_relative 'logger'

module Mist
  class Client
    def initialize(pool)
      @pool = pool
    end

    def call(method, args = {})
      server = args[:server] || @pool.acquire
      timeout = args[:timeout] || 300
      Mist.logger.debug "got server #{server}"

      server_info = server.split(':')
      host = server_info[0]
      port = server_info[1] || '18800'

      client = MessagePack::RPC::Client.new(host, port)
      client.timeout = timeout
      result = client.call(method, args)

      @pool.release server

      return result
    end
  end
end
