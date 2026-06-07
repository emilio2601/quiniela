# La Quiniela

A World Cup 2026 prediction pool for a handful of friends — **[quiniela.emilio2601.dev](https://quiniela.emilio2601.dev)**.

Call every match **home, draw or away**. After a match finishes, your points for a correct
call are **the number of people you beat** — so backing the upset nobody else saw is worth far
more than taking the favourite the whole room took.

![La Quiniela](public/og.png)

## How it works

- **Join** by name — no password, honour system. Six friends, one shared pool.
- **Pick** every fixture as home / draw / away on the picks board. Change your mind freely…
- **…until kickoff**, when the pick locks. That's the one hard rule, and it keeps the scoring
  denominator well-defined.
- **Score:** for each finished match, a correct pick earns `(people who picked it) − (people who
  got it right)` — the number of players you beat. The standings are computed on read; there's no
  leaderboard table.

The scoring formula lives in one place (`Leaderboard.points_for_correct`) so it's a one-line change
to switch to a "guarantee at least 1 point for any correct pick" variant.

## Stack

Server-rendered **Rails 8** with **Hotwire** (Turbo + a little Stimulus) — no API, no separate
frontend. **PostgreSQL**, **Solid Queue / Cache / Cable** (no Redis), **Propshaft**, **Puma**,
deployed as a Docker image on **Dokku**.

## Data

- **Fixtures** are seeded once from [openfootball/worldcup.json](https://github.com/openfootball/worldcup.json)
  (public domain) — all 104 matches, numbered in official FIFA chronological order.
- **Results** are pulled by a recurring job from [football-data.org](https://www.football-data.org/),
  which writes finished scores and resolves knockout teams as the bracket fills in.

## Local development

Requires Ruby (see `.ruby-version`) and PostgreSQL.

```sh
bin/setup            # install gems, prepare the database
bin/rails db:seed    # load the World Cup 2026 fixtures
bin/rails server     # http://localhost:3000
bin/rails test       # run the suite
```

To pull live results locally you need a free football-data.org API token in credentials
(`football_data_api_token`); without it the poller simply skips.

## Notes

- Match numbers are the official FIFA chronological numbers (Match 1 is the opener, Match 28 is
  Mexico v Korea), derived by ranking openfootball's group-ordered fixtures by kickoff.
- The production host is IPv6-only and football-data.org is IPv4-only, so results are fetched
  through a small Cloudflare Worker proxy (`cloudflare/fd-proxy/`).
- `/admin` is an internal, unlinked engagement + ops dashboard.
