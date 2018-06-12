require 'test_helper'

class StoresControllerTest < ActionDispatch::IntegrationTest
  test "should get edit" do
    get stores_edit_url
    assert_response :success
  end

end
