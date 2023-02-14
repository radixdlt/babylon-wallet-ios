# frozen_string_literal: true

source "https://rubygems.org"

# gem "rails"

gem "fastlane", "~> 2.210.1"

gem "dotenv", "~> 2.8"

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
