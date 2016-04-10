require 'yaml'

module Mist
  class Config
    # Server config attributes
    attr_reader :default_distro, :default_release
    attr_reader :username, :ssh_public_key, :ssh_private_key
    attr_reader :network, :subnet, :zone, :machine_type, :instance_name, :startup_script
    attr_reader :use_public_ip

    # Client config attributes
    attr_reader :servers

    def initialize(path)
      begin
        config = YAML.load(File.read(path))

        server_config = config['server'] || nil
        client_config = config['client'] || nil

        if server_config
          @default_distro = server_config['default_distro'] || 'ubuntu'
          @default_release = server)config['default_release'] || 'trusty'
          @username = server)config['username'] || 'mist'
          @ssh_public_key = server_config['ssh_public_key'] || File.expand_path('~/.ssh/id_rsa.pub')
          @ssh_private_key = server_config['ssh_private_key'] || File.expand_path('~/.ssh/id_rsa')
          @network = server_config['network'] || 'default'
          @subnet = server_config['subnet'] || nil
          @zone = server_config['zone'] || 'us-central1-a'
          @machine_type = server_config['machine_type'] || 'f1-micro'
          @instance_name = server_config['instance_name'] || 'mist'
          @startup_script = server_config['startup_script'] || File.join(%w(/ etc mist startup-script))
          @use_public_ip = server_config['use_public_ip'] || true
        end

        if client_config
          @servers = client_config['servers']
        end
      rescue StandardError => ex
        Mist.logger.error "Failed to load configuration file #{path}: #{ex}"
        abort 'could not load configuration file'
      end
    end
  end
end
