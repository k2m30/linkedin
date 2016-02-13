require 'test_helper'

class KeywordsControllerTest < ActionController::TestCase
  test "should get revert" do
    get :revert
    assert_response :success
  end

end
