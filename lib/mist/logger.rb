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
