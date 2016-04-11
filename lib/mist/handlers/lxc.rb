require 'socket'
require 'mist/lxc_container'
require 'mist/lxc_template'

module Mist
  class LxcHandler
    def initialize(config)
      @config = config
    end

    def create(args)
      Mist.logger.debug "create: args=#{args}"

      hostname = Socket.gethostname

      distro = args['distro'] || @config.default_distro
      release = args['release'] || @config.default_release
      name = args['name'] || create_name

      begin
        Mist.logger.info "creating container #{name} with #{distro}-#{release}"

        container = Mist::LXCContainer.new(name, distro, release)
        raise "container with the name #{name} already exists!" if container.exists?

        startup_script = File.join(@config.startup_script_path, 'lxc', distro)

        container.create(startup_script)
        ip = container.ips.first
      rescue StandardError => ex
        Mist.logger.error "Create request failed: #{ex}"
        return { status: false, server: hostname, message: "create request failed: #{ex}" }
      end

      return { status: true,
               server: hostname,
               message: 'created new container',
               name: name,
               ip: ip,
               username: @config.username }
    end

    def destroy(args)
      Mist.logger.debug "destroy: args=#{args}"

      begin
        name = args['name']
        container = Mist::LXCContainer.new(name)

        Mist.logger.info "destroying #{name}"
        container.destroy
      rescue StandardError => ex
        Mist.logger.error "Destroy request failed: #{ex}"
        return { status: false, message: "destroy request failed: #{ex}" }
      end

      return { status: true, message: 'destroyed container', name: name }
    end

    private

    def create_name
      base = @config.instance_name
      "#{base}-#{SecureRandom.hex(16)}"
    end
  end

  class LxcServer
    def initialize(config, id = 0)
      port = 18_800 + id

      @server = MessagePack::RPC::Server.new
      @server.listen('0.0.0.0', port, LxcHandler.new(config))
    end

    def run
      @server.run
    end
  end
end
