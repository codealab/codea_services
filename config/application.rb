require File.expand_path('../boot', __FILE__)

require 'rails/all'
require 'pp'

Bundler.require(*Rails.groups)

module Codeaservices
  class Application < Rails::Application
    config.time_zone = "Mexico City"
    # Allow GET petitions CORS
    config.middleware.insert_before 0, "Rack::Cors" do
      allow do
        origins '*'
        resource '*', :headers => :any, :methods => [:get,:post]
      end
    end
    # Loading ENV variables via YAML
    config.before_configuration do
      env_file = File.join(Rails.root, 'config', 'zoho.yml')
      YAML.load(File.open(env_file)).each do |key, value|
        ENV[key.to_s] = value
      end if File.exists?(env_file)
    end
    config.active_record.raise_in_transactional_callbacks = true
  end
end
