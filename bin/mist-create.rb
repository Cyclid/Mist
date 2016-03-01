#!/usr/bin/env ruby2.0
$LOAD_PATH.push File.expand_path('../lib', __FILE__)

require 'mist'

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
