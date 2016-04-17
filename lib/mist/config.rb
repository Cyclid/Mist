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

require 'yaml'

module Mist
  class Config
    # Server config attributes
    attr_reader :default_distro, :default_release
    attr_reader :username, :ssh_public_key, :ssh_private_key
    attr_reader :network, :subnet, :zone, :machine_type, :instance_name, :startup_script_path
    attr_reader :use_public_ip

    # Client config attributes
    attr_reader :servers

    def initialize(path)
      config = YAML.load(File.read(path))

      server_config = config['server'] || nil
      client_config = config['client'] || nil

      if server_config
        @default_distro = server_config['default_distro'] || 'ubuntu'
        @default_release = server_config['default_release'] || 'trusty'
        @username = server_config['username'] || 'mist'
        @ssh_public_key = server_config['ssh_public_key'] || File.expand_path('~/.ssh/id_rsa.pub')
        @ssh_private_key = server_config['ssh_private_key'] || File.expand_path('~/.ssh/id_rsa')
        @network = server_config['network'] || 'default'
        @subnet = server_config['subnet'] || nil
        @zone = server_config['zone'] || 'us-central1-a'
        @machine_type = server_config['machine_type'] || 'f1-micro'
        @instance_name = server_config['instance_name'] || 'mist'
        @startup_script_path = server_config['startup_scripts'] ||
                               File.join(%w(/ etc mist startup-scripts))
        @use_public_ip = server_config['use_public_ip'] || true
      end

      if client_config
        @servers = client_config['servers']
        @ssh_private_key = client_config['ssh_private_key'] || File.expand_path('~/.ssh/id_rsa')
      end
    rescue StandardError => ex
      Mist.logger.error "Failed to load configuration file #{path}: #{ex}"
      abort 'could not load configuration file'
    end
  end
end
