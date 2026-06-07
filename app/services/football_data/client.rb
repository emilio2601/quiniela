require "net/http"
require "json"

# Thin client for football-data.org's REST API (v4). Free tier: 10 req/min, so
# we make a single call per poll.
#
# football-data is IPv4-only and our production host is IPv6-only, so in
# production we go through an IPv6-reachable Cloudflare Worker proxy that holds
# the real token. When no proxy is configured (e.g. local dev, which has IPv4)
# we call the API directly. Both modes are driven by Rails credentials.
module FootballData
  class Client
    DIRECT_BASE = "https://api.football-data.org/v4".freeze
    COMPETITION = "WC".freeze # FIFA World Cup

    class Error < StandardError; end

    def initialize(credentials: Rails.application.credentials)
      if credentials.football_data_proxy_url.present?
        @base = credentials.football_data_proxy_url
        @auth_header = "X-Proxy-Key"
        @auth_value = credentials.football_data_proxy_key
      else
        @base = DIRECT_BASE
        @auth_header = "X-Auth-Token"
        @auth_value = credentials.football_data_api_token
      end
    end

    # All World Cup matches as an array of raw hashes (group + knockout).
    def matches
      get("/competitions/#{COMPETITION}/matches").fetch("matches")
    end

    private

    def get(path)
      raise Error, "missing football-data credentials" if @auth_value.blank?

      uri = URI("#{@base}#{path}")
      request = Net::HTTP::Get.new(uri)
      request[@auth_header] = @auth_value
      request["Accept"] = "application/json"

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout: 20) do |http|
        http.request(request)
      end

      unless response.code == "200"
        raise Error, "football-data responded #{response.code}: #{response.body.to_s[0, 200]}"
      end

      JSON.parse(response.body)
    rescue SocketError, SystemCallError, Net::OpenTimeout, Net::ReadTimeout, OpenSSL::SSL::SSLError => e
      # DNS/connection/timeout/TLS failures surface as our Error so the job can
      # skip a run rather than crash.
      raise Error, "request failed: #{e.class}: #{e.message}"
    end
  end
end
