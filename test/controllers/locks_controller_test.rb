require 'test_helper'

class LocksControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get :index
    assert_response :success
  end
end
