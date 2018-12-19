defmodule Innerpeace.PayorLink.Web.UserIntegrationTest do
  use Innerpeace.PayorLink.Web.IntegrationCase

  defp navigate_to_users do

    #maximizes browser window
    maximize_window(current_window_handle())

    #variable declaration
    sign_in_url = "http://payorlink-ip-staging.medilink.com.ph/sign_in"
    payorlink_url = "http://payorlink-ip-staging.medilink.com.ph/"
    _users_url = "http://payorlink-ip-staging.medilink.com.ph/users"

    #sign in function
    sign_in(sign_in_url)

    # Navigates to payorlink page upon successful sign in
    navigate_to(payorlink_url)

    #finds and selects the user module in the menu
    menu = find_element(:class, "toc")
    list = find_within_element(menu, :css, ".ui.visible.left.vertical.sidebar.menu.sidemenu")
    user = find_within_element(list, :css, ".users.icon")

    #clicks the user module in the menu
    user |> click()

    #asserts if the current url is in the users module
  end

  @tag integration: true
  test "user should be able to redirect to user module" do
    users_url = "http://payorlink-ip-staging.medilink.com.ph/users"

    navigate_to_users()

    #asserts if the current url is in the users module
    assert users_url == current_url()
  end

  @tag integration: true
  test "user should be able to navigate to create user page" do
    add_users_url = "http://payorlink-ip-staging.medilink.com.ph/users/new"

    navigate_to_users()

    add_user_button = find_element(:css, ".plus.icon")
    add_user_button |> click()

    assert add_users_url == current_url()
  end

end
