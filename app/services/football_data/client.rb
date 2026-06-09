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

    # Transient upstream failures worth retrying within a single poll: gateway
    # errors plus the 52x family football-data's own Cloudflare emits when its
    # origin SSL/handshake flaps (the recurring "525" we kept seeing).
    RETRYABLE_STATUSES = %w[502 503 504 520 521 522 523 524 525 526 527 530].freeze
    MAX_ATTEMPTS = 3

    class Error < StandardError; end

    def initialize(credentials: Rails.application.credentials, max_attempts: MAX_ATTEMPTS, sleeper: method(:sleep))
      @max_attempts = max_attempts
      @sleeper = sleeper
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

    # GET with bounded retry on transient upstream failures (network/TLS errors
    # and gateway/Cloudflare 5xx). On a permanent failure (e.g. 401/404) it
    # gives up immediately. Raises Error once attempts are exhausted, so the job
    # still records exactly one run per cron tick — a failure only when every
    # attempt failed, which keeps single flaps out of the admin log.
    def get(path)
      raise Error, "missing football-data credentials" if @auth_value.blank?

      uri = URI("#{@base}#{path}")
      last_error = nil
      attempts = 0

      @max_attempts.times do |i|
        @sleeper.call(2.0 * i) if i.positive? # 0s, 2s, 4s between tries
        attempts += 1

        begin
          response = perform_request(uri)
        rescue SocketError, SystemCallError, Net::OpenTimeout, Net::ReadTimeout, OpenSSL::SSL::SSLError => e
          last_error = "request failed: #{e.class}: #{e.message}"
          next
        end

        return JSON.parse(response.body) if response.code == "200"

        last_error = "football-data responded #{response.code}: #{response.body.to_s[0, 200]}"
        break unless RETRYABLE_STATUSES.include?(response.code)
      end

      raise Error, attempts > 1 ? "#{last_error} (after #{attempts} attempts)" : last_error
    end

    def perform_request(uri)
      request = Net::HTTP::Get.new(uri)
      request[@auth_header] = @auth_value
      request["Accept"] = "application/json"

      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout: 20) do |http|
        http.request(request)
      end
    end
  end
end
