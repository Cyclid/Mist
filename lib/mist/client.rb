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

      client = MessagePack::RPC::Client.new(server, 18_800)
      client.timeout = timeout
      result = client.call(method, args)

      @pool.release server

      return result
    end
  end
end
