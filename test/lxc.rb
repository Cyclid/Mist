#!/usr/bin/env ruby2.0

require 'logger'
require 'securerandom'
require 'lxc'

$logger = Logger.new(STDERR)

class LXCTemplate
  def initialize(distro, release)
    @distro = distro
    @release = release
    @template_name = "template-#{distro}-#{release}"

    @template = LXC::Container.new(@template_name)
  end

  def exists?
    @template.defined?
  end

  def create
    begin
      $logger.info "Creating #{@template_name}..."

      # Create our own user with a known key & strong random password
      username='build'
      pubkey="id_rsa_#{username}.pub"
      password=SecureRandom.urlsafe_base64(32)

      @template.create(@distro, nil, {}, 0, ['--release', @release,
                                             '--user', username,
                                             '--auth-key', pubkey,
                                             '--password', password])
    rescue StandardError => ex
      $logger.error "Failed to create template #{@template_name}: #{ex}"
      abort
    end
  end

  def clone(name)
    begin
      container = @template.clone(name, {flags: LXC::LXC_CLONE_SNAPSHOT, bdev_type: 'overlayfs'})
      container.wait(:stopped, 10)
      return container
    rescue StandardError => ex
      $logger.error "Failed to clone template #{@template_name}: #{ex}"
      abort
    end
  end
end

class LXCContainer
  attr_reader :name, :distro, :release, :ips

  def initialize(name, distro, release)
    @name = name
    @distro = distro
    @release = release

    @container = LXC::Container.new(@name)
    @ips = []
  end

  def exists?
    @container.defined?
  end

  def create
    raise "Container #{@name} already exists!" if exists?

    # Find the template for this container; if one does not exist on the host,
    # create it.
    template = LXCTemplate.new(distro, release)
    if not template.exists?
      $logger.info "Template for #{distro}-#{release} does not exist"
      template.create
    end

    # Fast-clone a new container from the template
    $logger.info "Cloning template..."
    container = template.clone(@name)

    begin
      # Start the container
      $logger.info "Starting #{@name}"

      container.start
      container.wait(:running, 30)

      # Wait for the network to start
      $logger.info "Waiting for network..."

      @ips=[]
      loop do
        @ips = container.ip_addresses
        sleep 0.5

        break unless @ips.empty?
      end
    rescue StandardError => ex
      $logger.error "Failed to start container #{@name}: #{ex}"
      abort
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
      $logger.error "Failed to destroy container #{@name}: #{ex}"
      abort
    end
  end
end

name='test'
distro='ubuntu'
release='trusty'

container = LXCContainer.new(name, distro, release)
begin
  container.create
  $logger.info "Container #{name} created with address #{container.ips.first}"
rescue StandardError => ex
  $logger.error "Failed to create new container #{name}: #{ex}"
  abort
end
