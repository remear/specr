# frozen_string_literal: true
require 'httparty'
require 'json'
require 'json-schema'

require 'specr/version'
require 'specr/extracer'
require 'specr/tiny_client'
require 'specr/step_definitions/async_steps'
require 'specr/step_definitions/debugging_steps'
require 'specr/step_definitions/http_steps'
require 'specr/step_definitions/jsonapi_steps'
require 'specr/step_definitions/validation_steps'
require 'specr/step_definitions/jsonapi_validation_steps'
require 'specr/step_definitions/rewrite_response_steps'

require 'specr/features/support/initial_setup'

module Specr
  class << self
    attr_accessor :configuration, :client, :logger
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield configuration
  end

  class Configuration
    attr_accessor :root_url
    attr_accessor :default_headers
    attr_accessor :max_request_attempts
    attr_accessor :request_attempt_delay
    attr_accessor :record_specified_steps_only

    def initialize
      @root_url = 'http://localhost:3000'
      @default_headers = {
        'Accept' => 'application/json',
        'Content-Type' => 'application/json'
      }
      @max_request_attempts = 5
      @request_attempt_delay = 2
      @record_specified_steps_only = false
    end
  end
end
