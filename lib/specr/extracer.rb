# frozen_string_literal: true
module Specr
  class Extracer

    API_SPEC_FILE_NAME = ENV['API_SPEC_FILE_NAME'] || 'specification.json'

    def initialize
      @scenarios = Array.new
      @resources_create = Hash.new([])
      @resources_update = Hash.new([])
    end

    def log_request(opts = {})
      request = process_request(opts[:request_body])
      scenario = {
        name: scenario_name(opts.fetch(:step)),
        endpoint: opts.fetch(:endpoint),
        method: opts.fetch(:verb),
        multipart: opts.fetch(:multipart),
        request: request,
        response: condensed_response_body_results(opts.fetch(:response_body)),
        response_code: opts.fetch(:response_code),
        response_message: opts.fetch(:response_message)
      }
      @scenarios << scenario
      return unless scenario[:response_body]
      # TODO: make these extract from arrays when those are being used
      if scenario[:endpoint].start_with?(Specr.configuration.root_url)
        endpoint = endpoint[Specr.configuration.root_url.length..-1]
      end
      if method == 'POST'
        # the path is either /[resource_name] or /[some_other_resource]/[guid]/[resource_name]
        # and the resource is getting created
        resource = endpoint.split('/').last
        @resources_create[resource] += [scenario]
      elsif method == 'PATCH'
        # the path will be /[resource_name]/[guid]
        resource = endpoint.split('/')[1]
        @resources_update[resource] += [scenario]
      end
      # 'GET' & 'DELETE' requests are ignored, and 'PUT' can be similar to a 'PATCH' in updating
    end

    def save
      file = File.join(API_SPEC_FILE_NAME)
      json = {
        endpoints: load_endpoints,
        scenarios: @scenarios,
        resources_create: @resources_create,
        resources_update: @resources_update,
        forms: load_forms,
        errors: load_error_codes,
        filterable_attributes: load_filterable_attributes,
        schemas: load_schemas
      }
      File.open(file, 'w') { |f| f.write(JSON.pretty_generate(json)) }
    end

    def rewrite_response_for_step(new_response, step)
      scenario_name = scenario_name(step)
      scenario = @scenarios.find { |s| s[:name] == scenario_name }
      scenario[:response] = condensed_response_body_results(new_response) if scenario
    end

    private

    def process_request(request_body)
      return JSON.parse(request_body) if request_body.is_a? String

      process_hash_request(request_body) if request_body.is_a? Hash
    rescue JSON::ParserError
      nil
    end

    def process_hash_request(request_hash)
      request_hash.each do |key, value|
        request_hash[key] = value.is_a?(File) ? "@[#{key.upcase}_PATH]" : nil
      end.compact
    end

    def scenario_name(step)
      scenario = Specr.client.current_scenario
      [scenario.feature.name.underscore.parameterize(separator: '_'),
       scenario.name.underscore.parameterize(separator: '_'),
       step&.underscore&.parameterize(separator: '_')
      ].compact.join('.')
    end

    def resolve_refs(json, path)
      if json.is_a? Hash
        if json['$ref']
          path = File.join(File.dirname(path), json['$ref'])
          json.delete('$ref')
          Hash[resolve_refs(JSON.parse(File.read(path)), path).to_a + json.to_a]
        else
          Hash[json.map do |key, value|
                 [key, resolve_refs(value, path)]
               end]
        end
      elsif json.is_a? Array
        json.map do |j|
          resolve_refs j, path
        end
      else
        json
      end
    end

    def condensed_response_body_results(body)
      return body unless body&.dig('data').is_a?(Array)
      return body unless body['data'].size > 2

      body['data'].slice!(0..1)
      body
    end

    def load_schemas
      ret = {}
      path = File.join('fixtures')
      Dir.glob("#{path}/**/*.json") do |f|
        json = resolve_refs(JSON.parse(File.read(f)), f)
        ret[f] = json
      end
      ret
    end

    def load_endpoints
      JSON.parse(File.read('endpoints.json'))
    end

    def load_forms
      JSON.parse(File.read('forms.json'))
    end

    def load_error_codes
      JSON.parse(File.read('error_codes.json'))
    end

    def load_filterable_attributes
      JSON.parse(File.read('filters.json'))
    end
  end
end
