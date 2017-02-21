require "thor"
require "thor/aws"

module AMIRotate
  class CLI < Thor
    include Thor::Aws

    class_option :verbose, type: :boolean, default: false, aliases: [:v]

    desc :version, "Puts Gem version."

    def version
      puts "AMIRotate #{VERSION}"
    end

    desc :setup, "Create EC2 tags with given profile name and options."
    method_option :profile_name,                     default: "default"
    method_option :retention_period,                 default: "7 days"
    method_option :overwrite,        type: :boolean, default: false
    method_option :dry_run,          type: :boolean, default: false
    method_option :filter_tags

    def setup
      client.setup
    end

    desc :preserve, "Create AMIs with given option by profile name."
    method_option :profile_name,                 default: "default"
    method_option :reboot,       type: :boolean, default: false
    method_option :dry_run,      type: :boolean, default: false
    method_option :filter_tags

    def preserve
      client.preserve
    end

    desc :invalidate, "Delete expired AMIs by profile name."
    method_option :profile_name,                      default: "default"
    method_option :expiration_offset,                 default: "-5 minutes"
    method_option :retain_snapshot,   type: :boolean, default: false
    method_option :dry_run,           type: :boolean, default: false
    method_option :filter_tags

    def invalidate
      client.invalidate
    end

    desc :rotate, "Execute :preserve and :invalidate at a time."
    method_option :profile_name,                      default: "default"
    method_option :reboot,            type: :boolean, default: false
    method_option :expiration_offset,                 default: "-5 minutes"
    method_option :retain_snapshot,   type: :boolean, default: false
    method_option :dry_run,           type: :boolean, default: false
    method_option :filter_tags

    def rotate
      preserve
      invalidate
    end

    private

    def client
      @client ||= Client.new options, aws_configuration
    end
  end
end
