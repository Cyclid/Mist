Gem::Specification.new do |s|
  s.name        = 'mist-server'
  s.version     = '0.1.0'
  s.license     = 'Apache-2.0'
  s.summary     = 'Mist is not a Cloud'
  s.description = 'A simple LXC based container scheduler'
  s.authors     = ['Kristian Van Der Vliet']
  s.email       = 'vanders@liqwyd.com'
  s.files       = Dir["bin/*.rb", "lib/**/*.rb"]
  s.bindir      = 'bin'

  s.add_dependency('msgpack-rpc', '~> 0.5')
  s.add_dependency('ruby-lxc', '~> 1.2')
end
