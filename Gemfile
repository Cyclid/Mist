source 'https://rubygems.org'

ruby '2.0.0'

gem 'msgpack-rpc'

group :gce do
  gem 'fog-core'
  gem 'fog-google'
  gem 'net-ssh'
  gem 'google-api-client', '< 0.9', '>= 0.6.2'
end

group :lxc do
  gem 'ruby-lxc'
end

group :development, :test do
  gem 'rake'
  gem 'rspec'
  gem 'rubocop'
  gem 'yard'
  gem 'simplecov'
end
