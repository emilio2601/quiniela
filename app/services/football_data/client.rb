require "net/http"
require "json"

# Thin client for football-data.org's REST API (v4). Free tier: 10 req/min, so
# we make a single call per poll. Auth is the token in Rails credentials.
module FootballData
  class Client
    BASE = "https://api.football-data.org/v4".freeze
    COMPETITION = "WC".freeze # FIFA World Cup

    class Error < StandardError; end

    def initialize(token: Rails.application.credentials.football_data_api_token)
      @token = token
    end

    # All World Cup matches as an array of raw hashes (group + knockout).
    def matches
      get("/competitions/#{COMPETITION}/matches").fetch("matches")
    end

    private

    def get(path)
      raise Error, "missing football_data_api_token credential" if @token.blank?

      uri = URI("#{BASE}#{path}")
      request = Net::HTTP::Get.new(uri)
      request["X-Auth-Token"] = @token

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 20) do |http|
        http.request(request)
      end

      unless response.code == "200"
        raise Error, "football-data.org responded #{response.code}: #{response.body.to_s[0, 200]}"
      end

      JSON.parse(response.body)
    end
  end
end
