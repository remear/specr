# frozen_string_literal: true
require 'pp'

module Specr
  class TinyClient
    attr_accessor :headers, :current_scenario
    attr_reader :extracer, :responses, :storage

    def initialize(extracer)
      @extracer = extracer
      @root_url = Specr.configuration.root_url
      @headers = Specr.configuration.default_headers
      @responses = []
      @storage = {}
    end

    def clear_storage
      @storage = {}
    end

    def build_options(opts)
      multipart = opts.delete(:multipart)
      body = opts.delete(:body)
      body = JSON.parse(body) unless [Hash, NilClass].include? body.class # TODO: is this necessary?
      body = hydrater(JSON.dump(body)) if body
      options = {
        headers: headers
      }.tap do |o|
        o[:body] = body if body
        if multipart
          file = opts.delete(:file)
          field = opts.delete(:field)
          o[:body] = {} unless o[:body]
          o[:body][field] = file
        end
      end
    end

    def build_url(endpoint)
      endpoint = hydrater(endpoint)
      url = endpoint =~ /https?:\/\// ? endpoint : "#{@root_url}#{endpoint}"
    end

    def refine_endpoint(ep)
      ep =~ /^\/\S*\/:\S*_id$/ ? ep.sub(/:(\S*_)id/, ':id') : ep
    end

    def request(verb, endpoint, opts = {})
      raise 'HTTP Verb must be a symbol' unless verb.is_a? Symbol
      url = build_url(endpoint)
      multipart = opts.fetch(:multipart, false)
      step = opts.delete(:step)
      options = build_options(opts)

      request_info = {
        verb: verb.to_s.upcase,
        url: url,
        endpoint: refine_endpoint(endpoint),
        step: step,
        multipart: multipart,
        request_body: options.fetch(:body, nil)
      }
      Specr.logger.debug("REQUEST_INFO:\n#{request_info.pretty_inspect}")

      response = HTTParty.send(verb, url, options)
      responses << response
      response_info = {
        response_body: last_body,
        response_code: response.code,
        response_message: response.message
      }
      Specr.logger.debug("RESPONSE_INFO:\n#{response_info.pretty_inspect}")
      extracer.log_request(**request_info, **response_info) if log_request?(step)
      response
    end

    def log_request?(step)
      last_code < 400 && (Specr.configuration.record_specified_steps_only ? step : true)
    end

    def post(endpoint, body = nil, opts = {})
      request(:post, endpoint, opts.merge!(body: body))
    end

    def post_multipart(endpoint, file, field, _body, opts = {})
      multipart_for(:post, endpoint, file, field, opts)
    end

    def patch_multipart(endpoint, file, field, _body, opts = {})
      multipart_for(:patch, endpoint, file, field, opts)
    end

    def put(endpoint, body, opts = {})
      request(:put, endpoint, opts.merge!(body: body))
    end

    def patch(endpoint, body, opts = {})
      request(:patch, endpoint, opts.merge!(body: body))
    end

    def get(endpoint, _body = nil, opts = {})
      request(:get, endpoint, opts)
    end

    def delete(endpoint, body = nil, opts = {})
      request(:delete, endpoint, body ? opts.merge!(body: body) : opts)
    end

    def add_response(response)
      responses << response
    end

    def last_code
      responses.last.code
    end

    def last_body
      JSON.parse(responses.last.body) if responses.last.body
    end

    def get_link(keys)
      last_body.dig(*keys.split('.'))
    end

    def hydrater(what)
      return unless what
      what.gsub(/:\w+/) do |match|
        key = match.tr(':', '')
        hydrated_value = storage[key] ? storage[key] : storage[key.to_sym]
        hydrated_value ? hydrated_value : match
      end
    end

    def validate(against)
      file_name = File.join('fixtures', "#{against}.json")
      if File.exist?(file_name) && (!against.is_a? Hash)
        JSON::Validator.validate!(file_name, last_body)
      else
        JSON::Validator.validate!(against, last_body)
      end
    end

    def [](name)
      if last_body.key? name
        last_body[name]
      else
        last_body.select { |x| x != 'links' && x != 'meta' }.values.first[name]
      end
    end

    private

    def multipart_for(verb, endpoint, file, field, opts)
      file_name = File.join('fixtures', 'files', file)
      options = opts.merge!(multipart: true,
                            file: File.new(file_name),
                            field: field)
      request(verb, endpoint, options)
    end
  end
end
