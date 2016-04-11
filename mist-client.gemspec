Gem::Specification.new do |s|
  s.name        = 'mist-client'
  s.version     = '0.2.0'
  s.license     = 'Apache-2.0'
  s.summary     = 'Mist is not a Cloud'
  s.description = 'A simple LXC based container scheduler'
  s.authors     = ['Kristian Van Der Vliet']
  s.email       = 'vanders@liqwyd.com'
  s.files       = Dir['bin/mist-client.rb',
                      'lib/mist/pool.rb',
                      'lib/mist/client.rb',
                      'lib/mist/logger.rb',
                      'lib/mist/config.rb',
                      'LICENSE.client']
  s.bindir      = 'bin'

  s.add_runtime_dependency('msgpack-rpc', '~> 0.5')
end
