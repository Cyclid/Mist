# Copyright (C) 2016 Liqwyd Ltd.
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; version 2.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc., 51 Franklin
# Street, Fifth Floor, Boston, MA 02110-1301, USA.

require 'lxc'

module Mist
  class LXCContainer
    attr_reader :name, :distro, :release, :ips

    def initialize(name, distro = nil, release = nil)
      @name = name
      @distro = distro
      @release = release

      @container = LXC::Container.new(@name)
      @ips = []
    end

    def exists?
      @container.defined?
    end

    def create(startup_script)
      raise "Container #{@name} already exists!" if exists?

      # Find the template for this container; if one does not exist on the host,
      # create it.
      template = LXCTemplate.new(distro, release)
      unless template.exists?
        Mist.logger.info "Template for #{distro}-#{release} does not exist"
        template.create
      end

      # Fast-clone a new container from the template
      Mist.logger.info 'Cloning template...'
      container = template.clone(@name)

      begin
        # Start the container
        Mist.logger.info "Starting #{@name}"

        container.start
        container.wait(:running, 30)

        # Wait for the network to start
        Mist.logger.info 'Waiting for network...'

        @ips = []
        start = Time.now
        loop do
          @ips = container.ip_addresses
          break unless @ips.empty?

          sleep 1

          raise 'timed out waiting for network' \
            if (Time.now - start) >= 30
        end

        # Give the container a few more seconds to allow SSH to start
        socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
        sockaddr = Socket.sockaddr_in(22, @ips.first)
        start = Time.now
        loop do
          begin
            if socket.connect_nonblock(sockaddr) == 0
              Mist.logger.info 'SSH started'
              socket.close
              break
            else
              sleep 0.5
            end

            raise 'timed out waiting for SSH' \
              if (Time.now - start) >= 30
          rescue Errno::ECONNREFUSED, Errno::EWOULDBLOCK, Errno::EINPROGRESS
            # Ignored
          end
        end

        # Find the rootfs on the host so that we can copy in the startup-script
        rootfs = container.config_item('lxc.rootfs')
        match = rootfs.match(/\Aoverlayfs:(.*):(.*)\Z/)
        rootfs = match[2] if match

        Mist.logger.debug "rootfs=#{rootfs}"

        internal_path = File.join('/', 'var', 'lib', 'mist')
        internal_file = File.join(internal_path, 'startup')
        external_path = File.join(rootfs, internal_path)
        external_file = File.join(external_path, 'startup')

        begin
          FileUtils.mkdir_p(external_path)
          FileUtils.cp startup_script, external_file
        rescue StandardError => ex
          Mist.logger.error "failed to copy startup script: #{ex}"
          raise 'could not copy startup script to container'
        end

        # Run the startup script
        Mist.logger.debug 'running startup script'
        container.attach(wait: true, stdin: File.open('/dev/null')) do
          LXC.run_command("/bin/bash #{internal_file}")
        end
      rescue StandardError => ex
        Mist.logger.error "Failed to start container #{@name}: #{ex}"

        # Attempt to clean up
        container.stop if container.running?
        container.destroy if container.defined?

        raise
      end

      @container = container
    end

    def destroy
      raise "Container #{@name} does not exist!" unless exists?

      begin
        @container.stop
        @container.wait(:stopped, 60)
        @container.destroy

        @container = nil
        @ips = []
      rescue StandardError => ex
        Mist.logger.error "Failed to destroy container #{@name}: #{ex}"
        raise
      end
    end
  end
end
