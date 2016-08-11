ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.

### change listen port ###
require 'rails/commands/server'

module DefaultOptions
  def default_options
    super.merge!(Port: 3000, Host: '0.0.0.0')
  end
end

Rails::Server.prepend(DefaultOptions)
### end change listen port ###
