# Copyright 2016 Liqwyd Ltd.
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.

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
