require 'logger'
require 'lxc'

module Mist
  class << self
    attr_accessor :logger

    begin
      Mist.logger = Logger.new(STDERR)
    rescue StandardError => ex
      abort "Failed to initialize: #{ex}"
    end
  end
end

require 'mist/lxc_template'
require 'mist/lxc_container'
