source 'https://rubygems.org'

gemspec name: 'mist-server'
gemspec name: 'mist-client'

group :gce do
  gem 'fog-core', '~> 1.37'
  gem 'fog-google', '~> 0.1'
  gem 'google-api-client', '< 0.9', '>= 0.6.2'
end

group :lxc do
  gem 'ruby-lxc', '~> 1.2'
end

group :development, :test do
  gem 'rake'
  gem 'rspec'
  gem 'rubocop'
  gem 'yard'
  gem 'simplecov'
  gem 'rubygems-tasks'
end
