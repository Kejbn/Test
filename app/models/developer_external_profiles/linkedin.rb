require "faraday"
require "json"

module DeveloperExternalProfiles
  class Linkedin
    def initialize
      @api_key = api_key
      @endpoint = endpoint
    end

    def get_profile(url)
      params = {
        "url" => url,
        "fallback_to_cache" => "on-error",
        "use_cache" => "if-present"
      }

      conn = Faraday.new(@endpoint) do |faraday|
        faraday.headers["Authorization"] = "Bearer #{@api_key}"
        faraday.adapter Faraday.default_adapter
      end

      begin
        response = conn.get("", params)

        if response.status.to_i == 200
          parse_json_response(response.body)
        else
          {error: "API Error: #{response.code} - #{response.body}"}
        end
      rescue Faraday::Error => e
        {error: "Exception occurred: #{e.message}"}
      end
    end

    private

    def parse_json_response(response_body)
      response_hash = JSON.parse(response_body)
      begin
        # Attempt to access the first company name in the experiences array
        {data: response_hash["experiences"][0]}
      rescue NoMethodError
        {error: "JSON Parsing Error: #{e.message}"}
      end
    rescue JSON::ParserError => e
      {error: "JSON Parsing Error: #{e.message}"}
    end

    def api_key
      Rails.application.credentials.proxycurl_api_key
    end

    def endpoint
      "https://nubela.co/proxycurl/api/v2/linkedin"
    end
  end
end
