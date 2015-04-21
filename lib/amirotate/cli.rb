require "thor"
require "thor/aws"

module AMIRotate
  class CLI < Thor
    include Thor::Aws

    desc :version, "Puts Gem version."

    def version
      puts "AMIRotate #{VERSION}"
    end

    desc :init, "Initialize EC2 tags"

    def init
      puts client
    end

    private

    def client
      @client ||= Client.new
    end
  end
end
