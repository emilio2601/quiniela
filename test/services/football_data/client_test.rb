require "test_helper"

class FootballData::ClientTest < ActiveSupport::TestCase
  # Fake credentials so the client takes the proxy path with a present token.
  CREDS = Struct.new(:football_data_proxy_url, :football_data_proxy_key) do
    def football_data_api_token = nil
  end.new("https://proxy.test/v4", "shhh")

  Resp = Struct.new(:code, :body)

  # A client whose HTTP layer replays a scripted list of responses/exceptions,
  # and whose backoff sleeps are no-ops so the suite stays fast.
  def client_yielding(*scripted)
    queue = scripted.dup
    client = FootballData::Client.new(credentials: CREDS, sleeper: ->(_) {})
    client.define_singleton_method(:perform_request) do |_uri|
      item = queue.shift
      raise item if item.is_a?(Exception)
      item
    end
    client
  end

  test "returns parsed matches on a clean 200" do
    client = client_yielding(Resp.new("200", { "matches" => [ { "id" => 1 } ] }.to_json))
    assert_equal [ { "id" => 1 } ], client.matches
  end

  test "retries through a transient 525 and then succeeds" do
    client = client_yielding(
      Resp.new("525", "error code: 525"),
      Resp.new("200", { "matches" => [] }.to_json)
    )
    assert_equal [], client.matches
  end

  test "retries a network/TLS error then succeeds" do
    client = client_yielding(
      OpenSSL::SSL::SSLError.new("handshake failure"),
      Resp.new("200", { "matches" => [] }.to_json)
    )
    assert_equal [], client.matches
  end

  test "gives up after MAX_ATTEMPTS on a persistent 525 and reports the count" do
    client = client_yielding(
      Resp.new("525", "error code: 525"),
      Resp.new("525", "error code: 525"),
      Resp.new("525", "error code: 525")
    )
    error = assert_raises(FootballData::Client::Error) { client.matches }
    assert_match "525", error.message
    assert_match "after 3 attempts", error.message
  end

  test "does not retry a permanent error like 404" do
    calls = 0
    client = FootballData::Client.new(credentials: CREDS, sleeper: ->(_) {})
    client.define_singleton_method(:perform_request) do |_uri|
      calls += 1
      Resp.new("404", "not found")
    end

    error = assert_raises(FootballData::Client::Error) { client.matches }
    assert_equal 1, calls, "404 is permanent — should fail on the first try"
    assert_match "404", error.message
    assert_no_match(/after \d+ attempts/, error.message)
  end

  test "raises immediately when the token is missing" do
    blank = Struct.new(:football_data_proxy_url, :football_data_proxy_key) do
      def football_data_api_token = nil
    end.new(nil, nil)
    client = FootballData::Client.new(credentials: blank, sleeper: ->(_) {})
    assert_raises(FootballData::Client::Error) { client.matches }
  end
end
