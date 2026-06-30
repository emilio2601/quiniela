require "test_helper"

class FootballData::ResultsImporterTest < ActiveSupport::TestCase
  def fd(id:, utc:, home:, away:, status: "TIMED", hs: nil, as: nil, winner: nil, stage: "GROUP_STAGE",
         duration: "REGULAR", regular: nil, extra: nil, pens: nil)
    score = { "winner" => winner, "duration" => duration, "fullTime" => { "home" => hs, "away" => as } }
    score["regularTime"] = { "home" => regular[0], "away" => regular[1] } if regular
    score["extraTime"] = { "home" => extra[0], "away" => extra[1] } if extra
    score["penalties"] = { "home" => pens[0], "away" => pens[1] } if pens
    {
      "id" => id, "utcDate" => utc.utc.iso8601, "status" => status, "stage" => stage,
      "homeTeam" => { "name" => home }, "awayTeam" => { "name" => away },
      "score" => score
    }
  end

  test "writes a finished score and stores external_id, matched by kickoff" do
    kickoff = Time.utc(2030, 6, 11, 19)
    match = Match.create!(number: 901, home_team: "Mexico", away_team: "South Africa", kickoff_at: kickoff)

    summary = FootballData::ResultsImporter.new.import(
      [ fd(id: 537327, utc: kickoff, home: "Mexico", away: "South Africa", status: "FINISHED", hs: 2, as: 1, winner: "HOME_TEAM") ]
    )

    match.reload
    assert match.finished?
    assert_equal [ 2, 1 ], [ match.home_score, match.away_score ]
    assert_equal "home", match.outcome
    assert_equal :home, match.result
    assert_equal 537327, match.external_id
    assert_equal 1, summary.scored
  end

  test "a knockout decided on penalties records the level score and the shootout" do
    kickoff = Time.utc(2030, 7, 5, 19)
    knockout = Match.create!(number: 990, home_team: "Spain", away_team: "France", kickoff_at: kickoff)

    # football-data's fullTime is cumulative (regulation + extra time + pens);
    # the match stood 1-1 and France won the shootout 4-5.
    FootballData::ResultsImporter.new.import(
      [ fd(id: 4040, utc: kickoff, home: "Spain", away: "France", status: "FINISHED",
           hs: 5, as: 6, winner: "AWAY_TEAM", stage: "QUARTER_FINALS",
           duration: "PENALTY_SHOOTOUT", regular: [ 1, 1 ], extra: [ 0, 0 ], pens: [ 4, 5 ]) ]
    )

    knockout.reload
    assert_equal [ 1, 1 ], [ knockout.home_score, knockout.away_score ] # the level score, not 5-6
    assert_equal [ 4, 5 ], [ knockout.home_penalties, knockout.away_penalties ]
    assert_equal "away", knockout.outcome
    assert_equal :away, knockout.result # France went through despite 1-1
    assert knockout.decided_on_penalties?
  end

  test "an extra-time winner keeps its full-time score and no penalties" do
    kickoff = Time.utc(2030, 7, 6, 19)
    knockout = Match.create!(number: 991, home_team: "Brazil", away_team: "Croatia", kickoff_at: kickoff)

    FootballData::ResultsImporter.new.import(
      [ fd(id: 4041, utc: kickoff, home: "Brazil", away: "Croatia", status: "FINISHED",
           hs: 2, as: 1, winner: "HOME_TEAM", stage: "QUARTER_FINALS",
           duration: "EXTRA_TIME", regular: [ 1, 1 ], extra: [ 1, 0 ]) ]
    )

    knockout.reload
    assert_equal [ 2, 1 ], [ knockout.home_score, knockout.away_score ]
    assert_nil knockout.home_penalties
    assert_not knockout.decided_on_penalties?
  end

  test "disambiguates a simultaneous group-stage slot by normalized team name" do
    slot = Time.utc(2030, 6, 24, 19)
    czr = Match.create!(number: 902, home_team: "Czech Republic", away_team: "Mexico", kickoff_at: slot)
    other = Match.create!(number: 903, home_team: "South Africa", away_team: "South Korea", kickoff_at: slot)

    # football-data spells it "Czechia"
    FootballData::ResultsImporter.new.import(
      [ fd(id: 1001, utc: slot, home: "Czechia", away: "Mexico", status: "FINISHED", hs: 1, as: 0) ]
    )

    assert czr.reload.finished?
    assert_equal 1001, czr.external_id
    assert_not other.reload.finished?
  end

  test "resolves a knockout's placeholder teams once football-data knows them" do
    kickoff = Time.utc(2030, 7, 5, 19)
    knockout = Match.create!(number: 980, home_team: "W97", away_team: "W98", kickoff_at: kickoff)

    summary = FootballData::ResultsImporter.new.import(
      [ fd(id: 2002, utc: kickoff, home: "United States", away: "France", stage: "SEMI_FINALS") ]
    )

    knockout.reload
    assert_equal [ "USA", "France" ], [ knockout.home_team, knockout.away_team ] # alias normalized
    assert_equal 2002, knockout.external_id
    assert_not knockout.finished?
    assert_equal 1, summary.resolved
  end

  test "matches by external_id even when the kickoff has shifted" do
    match = Match.create!(number: 904, home_team: "Brazil", away_team: "Morocco",
                          kickoff_at: Time.utc(2030, 6, 13, 22), external_id: 3003)

    FootballData::ResultsImporter.new.import(
      [ fd(id: 3003, utc: Time.utc(2030, 6, 13, 20), home: "Brazil", away: "Morocco", status: "FINISHED", hs: 3, as: 0) ]
    )

    assert match.reload.finished?
    assert_equal [ 3, 0 ], [ match.home_score, match.away_score ]
  end

  test "re-importing a finished match does not double count" do
    kickoff = Time.utc(2030, 6, 11, 19)
    Match.create!(number: 905, home_team: "Mexico", away_team: "South Africa", kickoff_at: kickoff)
    payload = [ fd(id: 5005, utc: kickoff, home: "Mexico", away: "South Africa", status: "FINISHED", hs: 2, as: 1) ]
    importer = FootballData::ResultsImporter.new

    assert_equal 1, importer.import(payload).scored
    assert_equal 0, importer.import(payload).scored
  end

  test "a FINISHED match with no score yet is left unsettled, then heals" do
    kickoff = Time.utc(2030, 6, 11, 19)
    match = Match.create!(number: 906, home_team: "Mexico", away_team: "South Africa", kickoff_at: kickoff)
    importer = FootballData::ResultsImporter.new

    # football-data flipped to FINISHED but hasn't posted the score (nulls).
    summary = importer.import(
      [ fd(id: 6006, utc: kickoff, home: "Mexico", away: "South Africa", status: "FINISHED") ]
    )
    match.reload
    assert_not match.finished?, "should not settle without a score"
    assert_nil match.home_score
    assert_equal 0, summary.scored
    assert_equal 6006, match.external_id, "still records the external_id for later matching"

    # next poll, football-data has filled the score in -> now it settles.
    summary = importer.import(
      [ fd(id: 6006, utc: kickoff, home: "Mexico", away: "South Africa", status: "FINISHED", hs: 2, as: 1, winner: "HOME_TEAM") ]
    )
    match.reload
    assert match.finished?
    assert_equal [ 2, 1 ], [ match.home_score, match.away_score ]
    assert_equal 1, summary.scored
  end

  test "counts payloads it cannot place" do
    summary = FootballData::ResultsImporter.new.import(
      [ fd(id: 9999, utc: Time.utc(2031, 1, 1, 12), home: "Narnia", away: "Mordor") ]
    )
    assert_equal 1, summary.unmatched
  end
end
