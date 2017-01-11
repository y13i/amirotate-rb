**Not maintained. Use [y13i/amirotate](https://github.com/y13i/amirotate) instead.**

# Amirotate

Back up EC2 instances by Snapshot/AMI. Capable of managing backup retention period.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'amirotate'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install amirotate

## Usage

`amirotate help` shows subcommands and options.

### 1. Set the tag on EC2 instances

Amirotate use tags attached to EC2 instance to determine instances that should be backed-up.

You can set the tag by `amirotate setup`.

### 2. Create image

`amirotate preserve` to find all your EC2 instances tagged with `amirotate:<profile name>:retention_period` and `CreateImage` them.

### 3. Delete image/snapshot

`amirotate invalidate` to find all your outdated AMIs. Deregister them, then delete all snapshots associated with the AMI..

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment. Run `bundle exec amirotate` to use the code located in this directory, ignoring other installed copies of this gem.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## TODO

* Write spec.
* etc.

## Contributing

1. Fork it ( https://github.com/y13i/amirotate/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
