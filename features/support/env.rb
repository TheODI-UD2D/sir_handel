ENV['RACK_ENV'] = 'cucumber'
ENV['TUBE_USERNAME'] = 'thomas'
ENV['TUBE_PASSWORD'] = 'tank_engine'

require File.join(File.dirname(__FILE__), '..', '..', 'lib/sir_handel.rb')

require 'capybara'
require 'capybara/cucumber'
require 'rspec'
require 'cucumber/rspec/doubles'

require 'cucumber/api_steps'
require 'active_support/core_ext/object/blank'
require 'coveralls'

Coveralls.wear_merged!

Capybara.app = SirHandel::App

class SirHandelWorld
  include Capybara::DSL
  include RSpec::Expectations
  include RSpec::Matchers

  def app
    SirHandel::App
  end
end

World do
  SirHandelWorld.new
end
