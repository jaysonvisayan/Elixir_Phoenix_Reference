defmodule Innerpeace.PayorLink.Web.MultipleBrowserSessionTest do
  use Innerpeace.PayorLink.Web.IntegrationCase

  setup do
    url1 = "http://payorlink-ip-staging.medilink.com.ph/sign_in"
    url2 = "http://payorlink-ip-staging.medilink.com.ph/forgot_password"
    url3 = "http://payorlink-ip-staging.medilink.com.ph/"
    {:ok, %{url1: url1, url2: url2, url3: url3}}
  end

  @tag integration: true
  test "should be able to run multiple sessions", %{url2: url2, url3: url3} do
    # Navigate to a url
    navigate_to(url2)

    # Change to another session
    change_session_to :another_session

    # Navigate to a url in the second session
    sign_in(url3)
    assert url3 == current_url()

    # Now go back to the default session
    change_to_default_session()

    # Assert if the url is the one we visited
    assert url2 == current_url()
  end

  @tag integration: true
  test "should be able to run multiple sessions using in_browser_session", %{url1: url1, url2: url2} do

    # Navigate to a url
    navigate_to(url1)

    # In another session...
    in_browser_session :another_session, fn ->
      navigate_to(url2)
      assert url2 == current_url()
    end

    # Assert if the url is the one we visited
    assert url1 == current_url()
  end

  @tag integration: true
  test "should preserve session after using in_browser_session", %{url1: url1, url2: url2, url3: url3} do
    # Navigate to url1 in default session
    navigate_to(url1)

    # Change to a second session and navigate to url2
    change_session_to :session_a
    navigate_to(url2)

    # In a third session...
    in_browser_session :session_b, fn ->
      sign_in(url3)
    end

    # Assert the current url is the url we visited in :session_a
    assert url2 == current_url()

    # Switch back to the default session
    change_session_to :default

    # Assert the current url is the one we visited in the default session
    assert url1 == current_url()
  end

  @tag integration: true
  test "in_browser_session should return the result of the given function", %{url1: url1} do

    # In another session, navigate to url1 and return the current url
    result =
      in_browser_session :another_session, fn ->
        navigate_to(url1)
        current_url()
      end

    assert result == url1
  end
end
