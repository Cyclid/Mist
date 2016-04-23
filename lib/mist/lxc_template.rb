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

    def create(config)
      Mist.logger.info "Creating #{@template_name}..."

      # Create our own user with a known key & strong random password
      username = config.username
      pubkey = config.ssh_public_key
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
