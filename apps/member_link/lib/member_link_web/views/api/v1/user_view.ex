defmodule MemberLinkWeb.Api.V1.UserView do
  use MemberLinkWeb, :view

  defp age_calc(birthdate) do
    today = Ecto.Date.utc()

    birthday = birthdate
               |> Ecto.Date.to_string()
               |> String.split("-")
               |> Enum.at(0)
               |> String.to_integer()

    today = today
            |> Ecto.Date.to_string()
            |> String.split("-")
            |> Enum.at(0)
            |> String.to_integer()

    today - birthday
  end

  def render("request_pin.json", %{message: message, code: code, exp: exp}) do
    {{y, m, d}, {h, min, s}} = Ecto.DateTime.to_erl(exp)
    expiry_date = {{y, m, d}, {h, min + 5, s}}
                  |> Ecto.DateTime.from_erl()
    %{
      message: message,
      pin_expiry: expiry_date,
      code: code
    }
  end

  def render("login.json", %{user_id: user_id, token: token, exp: exp, verified: verified}) do
    %{
      "user_id": user_id,
      "token": token,
      "expiry": Ecto.DateTime.from_unix!(exp, :second),
      "verified": verified
    }
  end

  def render("update_username_password.json", %{message: message, code: code}) do
    %{
      "message": message,
      "code": code
    }
  end

  def render("register.json", %{account: account}) do
    %{
      username: account.username,
      email: account.email,
      mobile: account.mobile,
      password_token: account.password_token
    }
  end

  def render("sms_verification.json", %{user: user, token: token, exp: exp}) do
    %{
      user_id: user.id,
      token: token,
      expiry: Ecto.DateTime.from_unix!(exp, :second),
      verified: user.verification
    }
  end

  def render("user.json", %{member: member}) do
    %{
      id: member.id,
      birthdate: member.birthdate,
      first_name: member.first_name,
      middle_name: member.middle_name,
      last_name: member.last_name,
      gender: member.gender,
      age: age_calc(member.birthdate),
      card: %{
        number: member.card_no
      }
    }
  end

  def render("forgot_credential.json", %{message: message, code: code}) do
    %{
      message: message,
      code: code
    }
  end

  def render("forgot_password_confirm.json", %{user: user, message: message, code: code}) do
    %{
      user_id: user.id,
      verified: user.verification,
      message: message,
      code: code
    }
  end

  def render("forgot_credential_password.json", %{message: message, code: code, user: user}) do
    {{y, m, d}, {h, min, s}} = Ecto.DateTime.to_erl(user.verification_expiry)
    expiry_date = {{y, m, d}, {h, min + 15, s}}
                  |> Ecto.DateTime.from_erl()
    %{
      user_id: user.id,
      pin_expiry: expiry_date,
      message: message,
      code: code
    }
  end

  def render("login_card.json", %{member_id: member_id,
    user_id: user_id, token: token, exp: exp, verified: verified}) do
    %{
      member_id: member_id,
      user_id: user_id,
      token: token,
      expiry: Ecto.DateTime.from_unix!(exp, :second),
      verified: verified
    }
  end

  def render("change_password_return.json",
    %{
      is_success: is_success,
      remarks: remarks
    }
  ) do
    %{
      is_success: is_success,
      remarks: remarks
    }
  end
end
