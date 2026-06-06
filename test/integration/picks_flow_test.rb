require "test_helper"

class PicksFlowTest < ActionDispatch::IntegrationTest
  def join(name)
    post join_path, params: { name: name }
  end

  test "the board requires a signed-in player" do
    get picks_path
    assert_redirected_to root_path
  end

  test "lists pickable matches and not locked ones in the open section" do
    join "Nadia"
    get picks_path
    assert_response :success
    # the open section offers pick controls; matches(:finished) has kicked off
    assert_select "##{ActionView::RecordIdentifier.dom_id(matches(:upcoming), :pick)} .ql-pick__btn"
    assert_select "##{ActionView::RecordIdentifier.dom_id(matches(:finished), :pick)} .ql-pick__btn", count: 0
  end

  test "placing a prediction saves it instantly" do
    join "Nadia"
    assert_difference "Pick.count", 1 do
      post picks_path, params: { match_id: matches(:upcoming).id, prediction: "home" }
    end
    pick = User.find_by(name: "Nadia").picks.find_by(match: matches(:upcoming))
    assert_equal "home", pick.prediction
  end

  test "changing a prediction updates in place, not duplicate" do
    join "Nadia"
    post picks_path, params: { match_id: matches(:upcoming).id, prediction: "home" }
    assert_no_difference "Pick.count" do
      post picks_path, params: { match_id: matches(:upcoming).id, prediction: "away" }
    end
    assert_equal "away", User.find_by(name: "Nadia").picks.find_by(match: matches(:upcoming)).prediction
  end

  test "a pick on a match past kickoff is rejected" do
    join "Nadia"
    assert_no_difference "Pick.count" do
      post picks_path, params: { match_id: matches(:finished).id, prediction: "home" }
    end
  end
end
