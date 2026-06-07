# Recurring job: pull World Cup results from football-data.org and write through
# finished scores and resolved knockout teams. Scheduled in config/recurring.yml.
class PollResultsJob < ApplicationJob
  queue_as :default

  def perform(client: FootballData::Client.new, importer: FootballData::ResultsImporter.new)
    summary = importer.import(client.matches)
    Rails.logger.info("[PollResultsJob] #{summary}")
    summary
  rescue FootballData::Client::Error => e
    # A bad response or hiccup shouldn't crash the recurring schedule; the next
    # run will catch up.
    Rails.logger.warn("[PollResultsJob] skipped: #{e.message}")
  end
end
