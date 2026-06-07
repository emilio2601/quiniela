require "test_helper"

class PollResultsJobTest < ActiveJob::TestCase
  test "fetches matches and imports results" do
    kickoff = Time.utc(2030, 6, 11, 19)
    match = Match.create!(number: 911, home_team: "Mexico", away_team: "South Africa", kickoff_at: kickoff)
    payload = [ {
      "id" => 1, "utcDate" => kickoff.iso8601, "status" => "FINISHED", "stage" => "GROUP_STAGE",
      "homeTeam" => { "name" => "Mexico" }, "awayTeam" => { "name" => "South Africa" },
      "score" => { "fullTime" => { "home" => 0, "away" => 1 } }
    } ]

    PollResultsJob.new.perform(client: Struct.new(:matches).new(payload))

    assert match.reload.finished?
    assert_equal [ 0, 1 ], [ match.home_score, match.away_score ]
  end

  test "a client error is swallowed so the schedule keeps running" do
    failing = Object.new
    def failing.matches = raise(FootballData::Client::Error, "rate limited")

    assert_nothing_raised { PollResultsJob.new.perform(client: failing) }
  end
end
