module Mist
  class Config
    attr_reader :default_distro, :default_release
    attr_reader :username, :ssh_public_key, :ssh_private_key
    attr_reader :network, :zone, :machine_type, :instance_name, :startup_script

    def initialize(path)
      begin
        config = YAML.load(File.read(path))

        @default_distro = config['default_distro'] || 'ubuntu'
        @default_release = config['default_release'] || 'trusty'
        @username = config['username'] || 'mist'
        @ssh_public_key = config['ssh_public_key'] || File.expand_path('~/.ssh/id_rsa.pub')
        @ssh_private_key = config['ssh_private_key'] || File.expand_path('~/.ssh/id_rsa')
        @network = config['network'] || 'default'
        @zone = config['zone'] || 'us-central1-a'
        @machine_type = config['machine_type'] || 'f1-micro'
        @instance_name = config['instance_name'] || 'mist'
        @startup_script = config['startup_script'] || File.join(%w(/ etc mist startup-script))
      rescue StandardError => ex
        Mist.logger.error "Failed to load configuration file #{path}: #{ex}"
        abort 'could not load configuration file'
      end
    end
  end
end
