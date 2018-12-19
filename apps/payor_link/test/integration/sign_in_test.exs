defmodule Innerpeace.PayorLink.Web.SignInTest do
  use Innerpeace.PayorLink.Web.IntegrationCase

  defp login_index do
    "http://payorlink-ip-staging.medilink.com.ph/sign_in"
  end

  defp payorlink_index do
    "http://payorlink-ip-staging.medilink.com.ph/"
  end

  @tag integration: true
  test "invalid username and/or password" do
    #Navigate to sign in page
    login_index() |> navigate_to()

    #Finds the element required
    form = find_element(:name, "LoginValidation")
    username = find_within_element(form, :name, "session[username]")
    password = find_within_element(form, :name, "session[password]")
    submit = find_within_element(form, :tag, "button")

    #Submits input
    username |> fill_field("john")
    password |> fill_field("john")
    submit |> click()

    #Finds alert message on submit
    alert = find_element(:id, "message")
    alert_text = visible_text(alert)

    #Asserts message and redirects to same page on error
    assert alert_text == "Invalid Login! Please try again."
    assert current_url() == login_index()
  end

  @tag integration: true
  test "submits without username and password" do
    login_index() |> navigate_to()

    form = find_element(:name, "LoginValidation")
    username = find_within_element(form, :name, "session[username]")
    password = find_within_element(form, :name, "session[password]")
    submit = find_within_element(form, :tag, "button")

    username |> fill_field("")
    password |> fill_field("")
    submit |> click()

    alert = find_element(:id, "message")
    alert_text = visible_text(alert)

    assert alert_text == "Enter your username and password"
    assert current_url() == login_index()
  end

  @tag integration: true
  test "submits without password" do
    login_index() |> navigate_to()

    form = find_element(:name, "LoginValidation")
    username = find_within_element(form, :name, "session[username]")
    password = find_within_element(form, :name, "session[password]")
    submit = find_within_element(form, :tag, "button")

    username |> fill_field("masteradmin")
    password |> fill_field("")
    submit |> click()

    alert = find_element(:id, "message")
    alert_text = visible_text(alert)

    assert alert_text == "Enter your password"
    assert current_url() == login_index()
  end

  @tag integration: true
  test "submits without username" do
    login_index() |> navigate_to()

    form = find_element(:name, "LoginValidation")
    username = find_within_element(form, :name, "session[username]")
    password = find_within_element(form, :name, "session[password]")
    submit = find_within_element(form, :tag, "button")

    username |> fill_field("")
    password |> fill_field("P@ssw0rd")
    submit |> click()

    alert = find_element(:id, "message")
    alert_text = visible_text(alert)

    assert alert_text == "Enter your username"
    assert current_url() == login_index()
  end

  @tag integration: true
  test "successfully signed in" do
    login_index() |> navigate_to()

    form = find_element(:name, "LoginValidation")
    username = find_within_element(form, :name, "session[username]")
    password = find_within_element(form, :name, "session[password]")
    submit = find_within_element(form, :tag, "button")

    username |> fill_field("masteradmin")
    password |> fill_field("P@ssw0rd")
    submit |> click()

    alert = find_element(:class, "ajs-message")
    alert_text = visible_text(alert)

    assert alert_text == "You’re now signed in!"
    assert current_url() == payorlink_index()
  end
end
