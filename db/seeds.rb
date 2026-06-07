# Seed the World Cup 2026 fixtures from openfootball's worldcup.json (public
# domain), vendored at db/seeds/worldcup.2026.json.
#
# Match numbers are the official FIFA chronological numbers (Match 1 is the
# opener, Match 28 is Mexico v Korea, …), derived by sorting fixtures by
# kickoff. openfootball lists matches grouped by group rather than by time, so
# we re-rank them here, breaking ties on simultaneous kickoffs by openfootball's
# own fixture order.
#
# Idempotent: a fixture is keyed on its match number, so re-running refreshes
# kickoff times without disturbing recorded scores or picks. Team names are only
# set when a fixture is first created — knockout placeholders (W97, 3CDFG, …) get
# resolved to real teams by the results poller, and a re-seed must never stomp
# on that.
require "json"
require "time"

FIXTURES_PATH = Rails.root.join("db/seeds/worldcup.2026.json")

# openfootball encodes kickoff as e.g. "13:00 UTC-6"; turn the local time plus
# its offset into an absolute instant (stored as UTC by Active Record).
def parse_kickoff(date, time)
  clock, zone = time.split(" ", 2)
  raw = zone.to_s.sub("UTC", "")
  sign = raw.start_with?("-") ? "-" : "+"
  hours = raw.delete("+-").to_i
  Time.parse("#{date}T#{clock}:00#{format('%s%02d:00', sign, hours)}")
end

fixtures = JSON.parse(File.read(FIXTURES_PATH)).fetch("matches")
created = 0
updated = 0

# Rank chronologically into official match numbers (ties broken by source order).
numbered = fixtures
  .each_with_index
  .map { |m, i| { data: m, kickoff: parse_kickoff(m["date"], m["time"]), source_order: i } }
  .sort_by { |f| [ f[:kickoff], f[:source_order] ] }

numbered.each_with_index do |fixture, index|
  match = Match.find_or_initialize_by(number: index + 1)
  match.kickoff_at = fixture[:kickoff]

  if match.new_record?
    match.home_team = fixture[:data]["team1"]
    match.away_team = fixture[:data]["team2"]
    created += 1
  elsif match.changed?
    updated += 1
  end
  match.save!
end

puts "World Cup 2026 fixtures seeded: #{created} created, #{updated} updated, #{Match.count} total."
