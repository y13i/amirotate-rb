require "aws-sdk"
require "time"

module AMIRotate
  class Client
    attr_reader :logger

    def initialize(cli_options = {}, aws_configuration = {})
      @cli_options = cli_options
      @logger ||= Logger.new STDOUT

      aws_configuration[:logger] = Logger.new STDOUT if @cli_options.verbose

      logger.info "Started."

      at_exit do
        logger.info "Exiting."
      end

      @ec2 = Aws::EC2::Resource.new aws_configuration
    end

    def setup
      instances.each do |instance|
        tag_key   = "amirotate:#{@cli_options[:profile_name]}:retention_period"
        tag_value = @cli_options[:retention_period]
        tag       = instance.tags.find {|tag| tag.key == tag_key}

        if tag.nil? or @cli_options[:overwrite]
          logger.info "Create tag `#{tag_key} => #{tag_value}` on instance #{instance.instance_id}."

          begin
            instance.create_tags(
              dry_run: @cli_options[:dry_run],

              tags: [
                key:   tag_key,
                value: tag_value,
              ],
            )
          rescue Aws::EC2::Errors::DryRunOperation
            logger.info "Did nothing due to dry run."
          end
        else
          logger.info "Tag `#{tag_key}` is already exist on instance #{instance.instance_id}."
        end
      end
    end

    def preserve
      instances.each do |instance|
        tag_key = "amirotate:#{@cli_options[:profile_name]}:retention_period"
        tag     = instance.tags.find {|tag| tag.key == tag_key}

        name = begin
          instance.tags.find {|tag| tag.key == "Name"}.value
        rescue
          ""
        end

        if tag.nil?
          logger.info "Tag `#{tag_key}` is not set on instance #{instance.instance_id} (#{name}). Skipping."
          next
        end

        logger.info "Create image from instance #{instance.instance_id} (#{name}). Retention period is #{tag.value}."

        begin
          image = instance.create_image(
            dry_run:   @cli_options[:dry_run],
            no_reboot: !@cli_options[:reboot],

            name: [
              instance.instance_id,
              Time.now.strftime("%Y-%m-%d %H.%M.%S"),
            ].join(" - ")
          )

          image.wait_until {|image| image.state.match /available|pending/}

          image.create_tags(
            dry_run: @cli_options[:dry_run],

            tags: [
              {
                key:   tag.key,
                value: tag.value,
              },

              {
                key:   "Name",
                value: name,
              },
            ],
          )

          image.wait_until {|image| image.state.match /available/}

          logger.info "block devices: #{image.block_device_mappings.size}"
          image.block_device_mappings.map do |block_device|
            logger.info "Tag to snapshot #{block_device.ebs.snapshot_id}"
            snapshot = @ec2.snapshot(block_device.ebs.snapshot_id.to_s)
            snapshot.create_tags(
              dry_run: @cli_options[:dry_run],
              tags: [
                {
                  key: tag.key,
                  value: tag.value,
                },

                {
                  key:   "Name",
                  value: [name, block_device.device_name].join('-')
                },
              ],
            )
          end
        rescue Aws::EC2::Errors::DryRunOperation
          logger.info "Did nothing due to dry run."
        end
      end
    end

    def invalidate
      images.each do |image|
        tag_key = "amirotate:#{@cli_options[:profile_name]}:retention_period"
        tag     = image.tags.find {|tag| tag.key == tag_key}

        if tag.nil?
          logger.info "Tag `#{tag_key}` is not set on image #{image.id} (#{image.name}). Skipping."
          next
        end

        expiration_time = Time.parse(image.creation_date) + parse_time(tag.value) + parse_time(@cli_options[:expiration_offset])

        if Time.now > expiration_time
          logger.info "Image #{image.id} (#{image.name}) is expired at #{expiration_time}. Deregister AMI."

          begin
            snapshot_ids = image.block_device_mappings.map do |block_device|
              begin
                block_device.ebs.snapshot_id
              rescue
                nil
              end
            end

            image.deregister(
              dry_run: @cli_options[:dry_run],
            )

            unless @cli_options[:retain_snapshot]
              snapshot_ids.compact.each do |snapshot_id|
                logger.info "Delete snapshot #{snapshot_id}."

                @ec2.snapshot(snapshot_id).delete(
                  dry_run: @cli_options[:dry_run],
                )
              end
            end
          rescue Aws::EC2::Errors::DryRunOperation
            logger.info "Did nothing due to dry run."
          end
        else
          logger.info "Image #{image.id} (#{image.name}) is not yet expired (Expire at #{expiration_time}). Skipping."
        end
      end
    end

    private

    def instances
      return @instances if @instances

      @instances = @ec2.instances.to_a

      filter! @instances if @cli_options.filter_tags

      logger.info "Found #{@instances.size} instance(s)."

      @instances
    end

    def images
      return @images if @images

      @images = @ec2.images(
        owners: ["self"],

        filters: [
          {
            name:   "state",
            values: ["available"]
          },
        ],
      ).to_a

      filter! @images if @cli_options.filter_tags

      logger.info "Found #{@images.size} image(s)."

      @images
    end

    def filter!(array)
      filter = @cli_options.filter_tags.split(/,/).inject Hash.new do |hash, keyvalue|
        key, value = keyvalue.split(/:/)
        hash.merge key => value
      end

      array.select! do |object|
        filter.all? do |filter_key, filter_value|
          object.tags.any? do |tag|
            [
              (tag.key == filter_key),
              (tag.value.match Regexp.compile(filter_value)),
            ].all?
          end
        end
      end
    end

    def parse_time(string)
      integer = string.to_i

      multiplier = case string
      when /minutes?/
        60
      when /hours?/
        60 * 60
      when /days?/
        60 * 60 * 24
      when /weeks?/
        60 * 60 * 24 * 7
      else
        1
      end

      integer * multiplier
    end
  end
end
