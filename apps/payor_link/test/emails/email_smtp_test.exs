defmodule Innerpeace.PayorLink.Web.EmailSmtpTest do
  use Innerpeace.PayorLink.Web.ConnCase
  alias Innerpeace.Db.Schemas.User

  test "invite user" do
    user = %User{email: "a@a.com", first_name: "anton"}
    user =
      user
      |> Map.put(:link, "https://payorlink.com.ph/create?password_token=")

    email = Innerpeace.PayorLink.EmailSmtp.invite_user(user)

    assert email.to == user.email
    assert email.subject == "User invite"
  end

  # test "reset password" do
  #   user = %User{email: "a@a.com", first_name: "anton"}
  #   email = Innerpeace.PayorLink.EmailSmtp.reset_password(user)

  #   assert email.to == user.email
  #   assert email.subject == "Reset Password"
  # end

  test "error logs email" do
    l = %{
      id: Ecto.UUID.generate(),
      job_name: "test1",
      job_params: "test2",
      module_name: "test3",
      function_name: "test4",
      error_description: "test5"
    }
    e = "test@test.com"

    email = Innerpeace.PayorLink.EmailSmtp.error_logs_email([l], e)
    assert email.to == e
    assert email.subject == "Error Log"
  end
end
