require 'securerandom'
require 'lxc'

module Mist
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
      Mist.logger.info "Creating #{@template_name}..."

      # Create our own user with a known key & strong random password
      username = 'build' # XXX This should be configurable
      pubkey = "id_rsa_#{username}.pub" # XXX The path to this key should be configurable
      password = SecureRandom.urlsafe_base64(32)

      @template.create(@distro, nil, {}, 0, ['--release', @release,
                                             '--user', username,
                                             '--auth-key', pubkey,
                                             '--password', password])
    rescue StandardError => ex
      Mist.logger.error "Failed to create template #{@template_name}: #{ex}"
      raise
    end

    def clone(name)
      container = @template.clone(name, flags: LXC::LXC_CLONE_SNAPSHOT, bdev_type: 'overlayfs')
      container.wait(:stopped, 10)
      return container
    rescue StandardError => ex
      Mist.logger.error "Failed to clone template #{@template_name}: #{ex}"
      raise
    end
  end
end
