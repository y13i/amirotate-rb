require "thor"
require "thor/aws"

module AMIRotate
  class CLI < Thor
    include Thor::Aws

    desc :version, "Puts Gem version."

    def version
      p AMIRotate::VERSION
    end
  end
end
