# frozen_string_literal: true

source "https://rubygems.org"

# gem "rails"

gem "fastlane", "~> 2.216.0"

gem "dotenv", "~> 2.8"

gem "xcode-install"

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
