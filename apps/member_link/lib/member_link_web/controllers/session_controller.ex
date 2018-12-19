defmodule MemberLinkWeb.SessionController do
  use MemberLinkWeb, :controller
  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]

  alias MemberLinkWeb.Auth
  alias Innerpeace.MemberLink.{
    EmailSmtp,
    Mailer
  }
  alias Innerpeace.Db.Utilities.SMS
  alias Innerpeace.Db.Base.{
    UserContext,
    LoginIpAddressContext,
    Api.UtilityContext
  }
  alias Innerpeace.Db.Schemas.{
    User,
    LoginIpAddress
  }

  def sign_in(conn, _) do
    ip = UtilityContext.get_ip(conn)
    with %LoginIpAddress{} = ip_address <- LoginIpAddressContext.get_ip_address(ip)
    do
      conn
      |> render("sign_in.html", attempts: ip_address.attempts)
    else
      _ ->
        {:ok, ip_address} = LoginIpAddressContext.create_ip_address(ip)
        conn
        |> render("sign_in.html", attempts: ip_address.attempts)
    end
  end

  def login(conn, %{"session" => user_params}) do
    username = user_params["username"]
    password = user_params["password"]
    captcha = user_params["captcha"]

    ip = UtilityContext.get_ip(conn)
    ip_address = LoginIpAddressContext.get_ip_address(ip)

    if is_nil(ip_address) do
      {:ok, ip_address} = LoginIpAddressContext.create_ip_address(ip)
    end

    with false <- UtilityContext.validate_string(username),
         {:ok, conn} <- Auth.username_and_pass(conn, username, password),
         user = %User{} <- UserContext.get_member_username(username),
         false <- is_nil(user.hashed_password),
         {:valid} <- validate_captcha(ip_address, captcha),
         true <- user && checkpw(password, user.hashed_password)
    do
      if user.status == "locked" do
        conn
        |> put_flash(:error, "Your account has been locked, you are advised to reset your password.")
        |> render("sign_in.html", attempts: ip_address.attempts, info: "")
      else
        LoginIpAddressContext.remove_attempt(ip_address)
        if user.verification == true do
          conn = Auth.login(conn, user)
          _user = conn.private[:guardian_default_resource]

          UserContext.attempts_reset(user, %{attempts: nil})

          conn
          |> put_flash(:info, "You’re now signed in!")
          |> redirect(to: page_path(conn, :index, conn.assigns.locale))
        else
          params = %{"verification_code" => UserContext.generate_verification_code()}
          user = UserContext.delete_verification_code(user)

          with {:ok, user} <- UserContext.update_user(user, params)
          do
            if Application.get_env(:member_link, :env) != :test do
              UserContext.update_user_expiry(user)
              if not is_nil(user.mobile) do
                user_mobile = transforms_number(user.mobile)
              else
                user_mobile = transforms_number(user.other_mobile)
              end
              SMS.send(%{text: "Your verification code is #{user.verification_code}", to: user_mobile})
            end

            conn
            |> put_flash(:info, "Verification Code has been sent to your mobile number")
            |> redirect(to: session_path(conn, :verify_code_login, conn.assigns.locale, user))
          else
            {:error, _changeset} ->
              {:ok, ip_address} = LoginIpAddressContext.add_attempt(ip_address)
              conn
              |> put_flash(:error, "Error in user login. Please try again.")
              |> render("sign_in.html", attempts: ip_address.attempts, info: "")
          end
        end
      end
    else
      {:not_found} ->
        {:ok, ip_address} = LoginIpAddressContext.add_attempt(ip_address)
        conn
        |> put_flash(:error, "The username or password you have entered is invalid")
        |> render("sign_in.html", attempts: ip_address.attempts, info: "")
      {:inactive_member} ->
        conn
        |> put_flash(:error, "The Member you have entered is not active")
        |> render("sign_in.html", attempts: ip_address.attempts, info: "")
      nil ->
        dummy_checkpw()
        {:ok, ip_address} = LoginIpAddressContext.add_attempt(ip_address)
        conn
        |> put_flash(:error, "Invalid User!")
        |> render("sign_in.html", attempts: ip_address.attempts, info: "")
      true ->
        {:ok, ip_address} = LoginIpAddressContext.add_attempt(ip_address)
        conn
        |> put_flash(:error, "Invalid Login! Please try again.")
        |> render("sign_in.html", attempts: ip_address.attempts, info: "")
      {:error, :unauthorized, conn} ->
          {:ok, ip_address} = LoginIpAddressContext.add_attempt(ip_address)
          conn
          |> put_flash(:error, "Invalid Login! Please try again.")
          |> render("sign_in.html", attempts: ip_address.attempts)
      false ->
        user = UserContext.get_member_username(username)

        att =
          if is_nil(user.attempts) do
            1
          else
            if user.attempts < 3 do
              user.attempts + 1
            else
              user.attempts
            end
          end

        {:ok, user} = UserContext.update_user_attempts(user, %{attempts: att})

        error =
          if att == 3 do
            UserContext.update_user_status(user)
            "Your account has been locked, you are advised to reset your password."
          else
            "Invalid Login! Please try again."
          end

        conn
        |> put_flash(:error, error)
        |> render("sign_in.html", attempts: ip_address.attempts, info: "")
      {:invalid, message} ->
        conn
        |> put_flash(:error, message)
        |> render("sign_in.html", attempts: ip_address.attempts, info: "")
      _ ->
        {:ok, ip_address} = LoginIpAddressContext.add_attempt(ip_address)
        conn
        |> put_flash(:error, "Error in user login. Please try again.")
        |> render("sign_in.html", attempts: ip_address.attempts, info: "")
    end
  end

  defp validate_captcha(ip_address, captcha) do
    if ip_address.attempts >= 3 and captcha == "" do
      {:invalid, "Captcha is required."}
    else
      {:valid}
    end
  end

  def verify_code_login(conn, %{"id" => id}) do
    user = UserContext.get_user!(id)
    user_mobile  = if not is_nil(user.mobile) do
      user.mobile
    else
      user.other_mobile
    end

    mobile =
      user_mobile
      |> String.split("09")
      |> Enum.at(1)
      |> String.split("")
    ast = for _x <- mobile, do: "*"
    ast = ast -- ["*"]
    a =
      user_mobile
      |> String.split("")
      |> Enum.chunk(3)
      |> List.last()

    mobile = Enum.join(ast ++ [a])
    changeset = UserContext.change_user(%User{})
    render(conn, "verify_code_login.html", changeset: changeset, mobile: mobile,
           user: user, action: session_path(conn, :login_verification, conn.assigns.locale, user))
  end

  def login_verification(conn, %{"id" => id, "user" => user_params})do
    input_code = user_params["verification_code"]
    user = UserContext.get_user!(id)
    _changeset = UserContext.change_user(user)

    att =
      if input_code != user.verification_code do
        if is_nil(user.attempts) do
          1
        else
          if user.attempts < 3 do
            user.attempts + 1
          else
            user.attempts
          end
        end
      end

    if input_code != user.verification_code do
      {:ok, user} = UserContext.update_user_attempts(user, %{attempts: att})

      if att == 3 do
        UserContext.update_user_status(user)
        conn
        |> put_flash(:error, "Your account has been locked, you are advised to reset your password.")
        |> redirect(to: session_path(conn, :sign_in, conn.assigns.locale))
      else
        conn
        |> put_flash(:error, "Error authenticating PIN Code.")
        |> redirect(to: session_path(conn, :verify_code_login, conn.assigns.locale, id))
      end
    else
      with true <- UserContext.check_pin_expiry(user)
      do
        UserContext.delete_verification_code(user)
        UserContext.update_verification(user, %{verification: true})
        conn = Auth.login(conn, user)
        _user = conn.private[:guardian_default_resource]
        conn
        |> put_flash(:info, "Authentication Successful!")
        |> redirect(to: search_path(conn, :search_doctors, conn.assigns.locale))
    else
        false ->
          conn
          |> put_flash(:error, "The 4-Digit PIN Code that you have entered has already expired.")
          |> redirect(to: session_path(conn, :verify_code_login, conn.assigns.locale, id))
      end
    end
  end

  def new_code(conn, %{"id" => id}) do
    user = UserContext.get_user!(id)
    user = UserContext.delete_verification_code(user)
    _changeset = UserContext.change_user(user)

    params = %{"verification_code" => UserContext.generate_verification_code()}

    with {:ok, user} <- UserContext.update_user(user, params)
    do
      if Application.get_env(:member_link, :env) != :test do
        UserContext.update_user_expiry(user)
        if not is_nil(user.mobile) do
          user_mobile = transforms_number(user.mobile)
        else
          user_mobile = transforms_number(user.other_mobile)
        end
        SMS.send(%{text: "Your verification code is #{user.verification_code}", to: user_mobile})
      end

      conn
      |> put_flash(:info, "Verification Code has been sent to your mobile number")
      |> redirect(to: session_path(conn, :verify_code_login, conn.assigns.locale, user))
    else
      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Error in login verification. Please try again.")
        |> redirect(to: session_path(conn, :verify_code_login, conn.assigns.locale, user))
    end
  end

  def logout(conn, _) do
    conn
    |> Auth.logout
    |> put_flash(:info, "See you later!")
    |> redirect(to: session_path(conn, :sign_in, conn.assigns.locale))
  end

  def forgot_password(conn, _) do
    render(conn, "forgot_password.html")
  end

  def forgot(conn, %{"session" => user_params}) do
    channel = user_params["channel"]
    username = user_params["username"]
    text = user_params["text"]

    with %User{} = user <- UserContext.get_username_with_password(username)
    do
      valid =
        if channel == "Email" do
          if user.email != text do
            false
          else
            true
          end
        else
          if user.mobile != text do
            false
          else
            true
          end
        end
      if channel == "Email" do
        if user.email != text do
          conn
          |> put_flash(:error, "The username or email address you have entered is invalid")
          |> redirect(to: session_path(conn, :forgot_password, conn.assigns.locale))
        end
      else
        if user.mobile != text do
          conn
          |> put_flash(:error, "The username or mobile number you have entered is invalid")
          |> redirect(to: session_path(conn, :forgot_password, conn.assigns.locale))
        end
      end

      if valid do
        user = UserContext.delete_verification_code(user)
        _changeset = UserContext.change_user(user)
        params = Map.merge(user_params, %{
          "verification_code" => UserContext.generate_verification_code()
        })

        {:ok, user} = UserContext.update_user(user, params)

        UserContext.update_user_expiry(user)

        if channel == "Email" do
          email = EmailSmtp.reset_password(user)
          email
          |> Mailer.deliver_now

          conn
          |> put_flash(:info, "Verification Code has been sent to your email")
          |> redirect(to: session_path(conn, :verify_code, conn.assigns.locale, user))
        else
          if not is_nil(user.mobile) do
            user_mobile = transforms_number(user.mobile)
          else
            user_mobile = transforms_number(user.other_mobile)
          end
          SMS.send(%{text: "Your verification code is #{user.verification_code}", to: user_mobile})

          conn
          |> put_flash(:info, "Verification Code has been sent to your mobile number")
          |> redirect(to: session_path(conn, :verify_code_sms, conn.assigns.locale, user))
        end
      end
    else
      nil ->
        conn
        |> put_flash(:error, "Username is invalid")
        |> redirect(to: "/forgot_password")
    end
  end

  def verify_code(conn, %{"id" => id}) do
    user = UserContext.get_user!(id)
    email =
      user.email
      |> String.split("@")
      |> Enum.at(0)
      |> String.split("")
    ast = for _x <- email, do: "*"
    a =
      user.email
      |> String.split("@")
      |> Enum.at(1)

    email =  Enum.join(ast ++ ["@"] ++ [a])
    changeset = UserContext.change_user(%User{})
    render(conn, "verify_code_email.html", changeset: changeset, user: user,
           email: email, action: session_path(conn, :code_verification, conn.assigns.locale, user))
  end

  def verify_code_sms(conn, %{"id" => id}) do
    user = UserContext.get_user!(id)
    mobile =
      user.mobile
      |> String.split("09")
      |> Enum.at(1)
      |> String.split("")
    ast = for _x <- mobile, do: "*"
    ast = ast -- ["*"]
    a =
      user.mobile
      |> String.split("")
      |> Enum.chunk(3)
      |> List.last()

    mobile = Enum.join(ast ++ [a])
    changeset = UserContext.change_user(%User{})
    render(conn, "verify_code_sms.html", changeset: changeset, mobile: mobile,
           user: user, action: session_path(conn, :code_verification, conn.assigns.locale, user))
  end

  def code_verification(conn, %{"id" => id, "user" => user_params})do
    input_code = user_params["verification_code"] |> List.to_string
    user = UserContext.get_user!(id)
    _changeset = UserContext.change_user(user)

    if input_code != user.verification_code do
      if is_nil(user_params["email"]) == false do
        conn
        |> put_flash(:error, "The verification code you entered is incorrect.")
        |> redirect(to: session_path(conn, :verify_code, conn.assigns.locale, id))
      else
        conn
        |> put_flash(:error, "The verification code you entered is incorrect.")
        |> redirect(to: session_path(conn, :verify_code_sms, conn.assigns.locale, id))
      end
    else
      with true <- UserContext.check_pin_expiry(user)
      do
        UserContext.delete_verification_code(user)
        conn
        |> put_flash(:info, "Code Verified!")
        |> redirect(to: session_path(conn, :reset_password, conn.assigns.locale, id))
      else
        false ->
          if is_nil(user_params["email"]) == false do
            conn
            |> put_flash(:error, "The 4-Digit PIN Code that you have entered has already expired.")
            |> redirect(to: session_path(conn, :verify_code, conn.assigns.locale, id))
          else
            conn
            |> put_flash(:error, "The 4-Digit PIN Code that you have entered has already expired.")
            |> redirect(to: session_path(conn, :verify_code_sms, conn.assigns.locale, id))
          end
      end
    end
  end

  def resend_code(conn, %{"id" => id}) do
    user = UserContext.get_user!(id)
    user
    |> UserContext.delete_verification_code()
    changeset = UserContext.change_user(user)

    render(conn, "resend_code.html", changeset: changeset, user: user,
           action: session_path(conn, :update_code, conn.assigns.locale, user))
  end

  def update_code(conn, %{"id" => id, "session" => user_params}) do
    user = UserContext.get_user!(id)
    _changeset = UserContext.change_user(user)
    channel = user_params["channel"]
    username = user_params["username"]
    text = user_params["text"]

    with %User{} = user <- UserContext.get_username_with_password(username)
    do

      valid =
        if channel == "Email" do
          if user.email != text do
            false
          else
            true
          end
        else
          if user.mobile != text do
            false
          else
            true
          end
        end
      if channel == "Email" do
        if user.email != text do
          conn
          |> put_flash(:error, "The email address you have entered is invalid")
          |> redirect(to: session_path(conn, :resend_code, conn.assigns.locale, user))
        end
      else
        if user.mobile != text do
          conn
          |> put_flash(:error, "The mobile number you have entered is invalid")
          |> redirect(to: session_path(conn, :resend_code, conn.assigns.locale, user))
        end
      end

      if valid do
        user = UserContext.delete_verification_code(user)
        _changeset = UserContext.change_user(user)
        params = Map.merge(user_params, %{
          "verification_code" => UserContext.generate_verification_code()
        })

        {:ok, user} = UserContext.update_user(user, params)

        UserContext.update_user_expiry(user)

        if channel == "Email" do
          email = EmailSmtp.reset_password(user)
          email
          |> Mailer.deliver_now

          conn
          |> put_flash(:info, "Verification Code has been sent to your email")
          |> redirect(to: session_path(conn, :verify_code, conn.assigns.locale, user))
        else
          if not is_nil(user.mobile) do
            user_mobile = transforms_number(user.mobile)
          else
            user_mobile = transforms_number(user.other_mobile)
          end
          SMS.send(%{text: "Your verification code is #{user.verification_code}", to: user_mobile})

          conn
          |> put_flash(:info, "Verification Code has been sent to your mobile number")
          |> redirect(to: session_path(conn, :verify_code_sms, conn.assigns.locale, user))
        end
      end
    else
      nil ->
        conn
        |> put_flash(:error, "Username is invalid")
        |> redirect(to: session_path(conn, :resend_code, conn.assigns.locale, user))
    end
  end

  def resend_code_email(conn, %{"id" => id}) do
    user = UserContext.get_user!(id)
    user
    |> UserContext.delete_verification_code()

    params = %{
      "verification_code" => UserContext.generate_verification_code()
    }

    {:ok, user} = UserContext.update_user(user, params)

    UserContext.update_user_expiry(user)
    email = EmailSmtp.reset_password(user)
    email
    |> Mailer.deliver_now

    conn
    |> put_flash(:info, "Verification Code has been sent to your email")
    |> redirect(to: session_path(conn, :verify_code, conn.assigns.locale, user))
  end

  def resend_code_sms(conn, %{"id" => id}) do
    user = UserContext.get_user!(id)
    user
    |> UserContext.delete_verification_code()

    params = %{
      "verification_code" => UserContext.generate_verification_code()
    }

    {:ok, user} = UserContext.update_user(user, params)

    UserContext.update_user_expiry(user)
    if not is_nil(user.mobile) do
      user_mobile = transforms_number(user.mobile)
    else
      user_mobile = transforms_number(user.other_mobile)
    end
    SMS.send(%{text: "Your verification code is #{user.verification_code}", to: user_mobile})

    conn
    |> put_flash(:info, "Verification Code has been sent to your mobile number")
    |> redirect(to: session_path(conn, :verify_code_sms, conn.assigns.locale, user))
  end

  def reset_password(conn, %{"id" => id}) do
    user = UserContext.get_user!(id)
    changeset = User.password_changeset(user)
    render(conn, "reset_password.html", changeset: changeset, user: user,
           action: session_path(conn, :update_password, conn.assigns.locale, user))
  end

  def update_password(conn, %{"id" => id, "user" => user_params}) do
    user = UserContext.get_user!(id)
    changeset = User.password_changeset(user, user_params)

    if checkpw(user_params["password"], user.hashed_password) do
      changeset =
        changeset
        |> Map.delete(:action)
        |> Map.put(:action, "test")

      conn
      |> put_flash(:error, "Cannot use old Password!")
      |> render("reset_password.html", changeset: changeset, user: user,
                action: session_path(conn, :update_password, conn.assigns.locale, id))
    else
      if user_params["password"] != user_params["password_confirmation"] do
        changeset =
          changeset
          |> Map.delete(:action)
          |> Map.put(:action, "test")
          conn
          |> put_flash(:error, "Password and Password Confirmation doesn't match!")
          |> render("reset_password.html", changeset: changeset, user: user,
                    action: session_path(conn, :update_password, conn.assigns.locale, id))
      else
        case UserContext.update_password(changeset) do
          {:ok, user} ->
            {:ok, user} = UserContext.update_user_status_active(user)
            {:ok, user} = UserContext.update_user_attempts(user, %{attempts: 0})
            conn
            |> Auth.login(user)
            |> put_flash(:info, "Your password has been successfully changed.")
            |> redirect(to: session_path(conn, :sign_in, conn.assigns.locale))
          {:error, changeset} ->
            conn
            |> put_flash(:error, "Password must be at least 8 characters long and must contain at least one lower case character, one upper case character, and one special character(!@#$)")
            |> render("reset_password.html", changeset: changeset, user: user,
                      action: session_path(conn, :update_password, conn.assigns.locale, id))
        end
      end
    end
  end

  defp transforms_number(number) do
    number =
      number
      |> String.slice(1..11)
    "63#{number}"
  end

  def load_all_username(conn, _params) do
    users = UserContext.list_username()
    json conn, Poison.encode!(users)
  end

  def load_all_user_email_mobile(conn, _params) do
    users = UserContext.list_user_email_mobile()
    json conn, Poison.encode!(users)
  end
end
