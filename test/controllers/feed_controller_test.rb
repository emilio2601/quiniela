require "test_helper"

class FeedControllerTest < ActionDispatch::IntegrationTest
  # 25 locked (kicked-off), team-resolved matches -> two pages at 20 per page.
  setup do
    25.times do |i|
      Match.create!(number: 100 + i, home_team: "Spain", away_team: "France",
                    kickoff_at: (i + 1).hours.ago, status: "finished",
                    home_score: 1, away_score: 0, outcome: "home")
    end
  end

  test "first page shows PER_PAGE matches and an Older link" do
    get feed_path
    assert_response :success
    assert_select "article.ql-feed__item", FeedController::PER_PAGE
    assert_select ".ql-pager__at", text: /Page 1 of 2/
    assert_select "a.ql-pager__link", text: /Older/
    assert_select "a.ql-pager__link", text: /Newer/, count: 0 # disabled on page 1
  end

  test "second page shows the remainder" do
    get feed_path(page: 2)
    assert_response :success
    # 26 locked, known-team matches total (25 created + the `finished` fixture).
    assert_select "article.ql-feed__item", 26 - FeedController::PER_PAGE
    assert_select "a.ql-pager__link", text: /Newer/
  end

  test "an out-of-range page clamps into bounds" do
    get feed_path(page: 99)
    assert_response :success
    assert_select ".ql-pager__at", text: /Page 2 of 2/
  end
end
