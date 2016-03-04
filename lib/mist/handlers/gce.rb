require 'securerandom'
require 'fog/google'
require 'socket'

module Mist
  class GceHandler
    def initialize(config)
      @api = Fog::Compute.new(provider: 'Google')
      @config = config
    end

    def create(args)
      Mist.logger.debug "create: args=#{args}"

      #hostname = Socket.gethostname
      hostname = '104.155.84.154'

      distro = args['distro'] || @config.default_distro 
      release = args['release'] || @config.default_release
      name = args['name'] || create_name

      begin
        # Map the distro & release to a source image
        Mist.logger.debug 'attempting to find source image'

        source_image = nil
        disk_size = 0

        @api.images.all.each do |image|
          next if image.deprecated

          match = image.name.match(/^#{distro}-((\d*)-(.*)-v.*$|(\d*)-v.*$)/)
          next unless match
          next unless match[2] == release or match[3] == release

          # Found one
          Mist.logger.info "found image #{image.name} for #{distro}:#{release}"
          source_image = image.name
          disk_size = image.disk_size_gb

          break
        end

        # If we didn't find a disk, we have to stop now
        raise "could not find suitable source image for #{distro}:#{release}" \
          unless source_image

        # Create a disk, create an instance with the disk attached, set the disk
        # to be auto-deleted when the instance is destroyed
        Mist.logger.info "creating disk #{name}"
        disk = @api.disks.create(name: name,
                                size_gb: disk_size,
                                zone_name: @config.zone,
                                source_image: source_image)

        Mist.logger.info 'waiting for disk...'
        disk.wait_for { disk.ready? }

        Mist.logger.info "creating instance #{name}"

        metadata = {'startup-script' => File.read(@config.startup_script),
                    'mist-user' => @config.username,
                    'mist-key' => File.read(@config.ssh_public_key)}

        instance = @api.servers.create(name: name,
                                       disks: [disk],
                                       machine_type: @config.machine_type,
                                       zone_name: @config.zone,
                                       network: @config.network,
                                       public_key_path: @config.ssh_public_key,
                                       private_key_path: @config.ssh_private_key,
                                       metadata: metadata,
                                       tags: ['build','build-host'])

        device_name = instance.disks[0]['deviceName']
        instance.set_disk_auto_delete(true, device_name)

        instance.wait_for { instance.sshable? }

        ip = instance.public_ip_address #private_ip_address

        # Give the instance a grace period while the startup script runs
        sleep(5)
      rescue StandardError => ex
        Mist.logger.error "Create request failed: #{ex}"
        return { status: false, server: hostname, message: "create request failed: #{ex}" }
      end

      return { status: true,
               server: hostname,
               message: 'created new instance',
               name: name,
               ip: ip,
               username: @config.username }
    end

    def destroy(args)
      Mist.logger.debug "destroy: args=#{args}"

      begin
        name = args['name']

        instance = @api.servers.get(name)
        raise "instance #{name} does not exist" unless instance

        Mist.logger.info "destroying #{name}"
        raise 'failed to destroy instance' unless instance.destroy
      rescue StandardError => ex
        Mist.logger.error "Destroy request failed: #{ex}"
        return { status: false, message: "destroy request failed: #{ex}" }
      end

      return { status: true, message: 'destroyed instance', name: name }
    end

    private

    def create_name
      base = @config.instance_name
      "#{base}-#{SecureRandom.hex(16)}"
    end
  end

  class GceServer
    def initialize(config)
      @server = MessagePack::RPC::Server.new
      @server.listen('0.0.0.0', 18800, GceHandler.new(config))
    end

    def run
      @server.run
    end
  end
end
