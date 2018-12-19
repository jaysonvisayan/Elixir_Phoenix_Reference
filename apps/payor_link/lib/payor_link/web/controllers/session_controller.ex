defmodule Innerpeace.PayorLink.Web.SessionController do
  @moduledoc false

  use Innerpeace.PayorLink.Web, :controller
  use Innerpeace.Db.PayorRepo, :context

  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]
  import Ecto.Query

  alias Innerpeace.Db.Schemas.{
    User,
    UserRole,
    Role,
    RolePermission,
    Permission,
    LoginIpAddress
  }
  alias Innerpeace.{
    Auth,
    Db.Repo,
    Db.Utilities.SMS,
    Db.Base.UserContext,
    PayorLink.EmailSmtp,
    PayorLink.Mailer,
    Db.Base.Api.UtilityContext,
    Db.Base.LoginIpAddressContext,
    Db.Base.UserContext
  }

  alias PayorLink.Guardian
  alias Innerpeace.PayorLink.Web.Endpoint

  def loaderio_ist(conn, _) do
    render conn, "loaderio_ist.html"
  end

  def loaderio_uat(conn, _) do
    render conn, "loaderio_uat.html"
  end

  def new(conn, _) do
    ip = UtilityContext.get_ip(conn)
    with %LoginIpAddress{} = ip_address <- LoginIpAddressContext.get_ip_address(ip)
    do
      conn
      |> render("new.html", attempts: ip_address.attempts, info: "")
    else
      _ ->
        {:ok, ip_address} = LoginIpAddressContext.create_ip_address(ip)
        conn
        |> render("new.html", attempts: ip_address.attempts, info: "")
    end
  end

  def create(conn, %{"session" =>
      %{
        "username" => username,
        "password" => password,
        "payroll_code" => payroll_code,
        "captcha" => captcha
      }})
  do
    ip = UtilityContext.get_ip(conn)
    ip_address = LoginIpAddressContext.get_ip_address(ip)

    if is_nil(ip_address) do
      {:ok, ip_address} = LoginIpAddressContext.create_ip_address(ip)
    end

    with false <- UtilityContext.validate_string(username),
        {:ok, conn} <- Auth.username_and_pass(conn, username, password, payroll_code),
        {:valid} <- validate_captcha(ip_address, captcha),
        user <- Guardian.current_resource(conn),
        true <- user.status == "Active"
    do
      LoginIpAddressContext.remove_attempt(ip_address)
      user = Guardian.current_resource(conn)
      if user.first_time do
        user = UserContext.generate_reset_token(user)
        conn
        |> redirect(to: session_path(conn, :reset_password, user.reset_token))
      else
        conn
        |> put_flash(:info, "You’re now signed in!")
        # |> set_permissions(user)
        # |> redirect(to: main_page_path(conn, :index))
        |> redirect(to: page_path(conn, :index))
      end
    else
      {:error, _x, _y} ->
        LoginIpAddressContext.add_attempt(ip_address)
        conn
        |> put_flash(:error, "You have entered an invalid Payroll code, username or password. Try again.")
        |> redirect(to: session_path(conn, :new))
      {:invalid, message} ->
        conn
        |> put_flash(:error, message)
        |> redirect(to: session_path(conn, :new))
      _ ->
        conn
        |> put_flash(:error, "Error logging in. Please try again!")
        |> redirect(to: session_path(conn, :new))
    end
  rescue
    Elixir.Plug.Conn.CookieOverflowError ->
      conn
        |> put_flash(:error, "Error logging in. Please try again!")
        |> redirect(to: session_path(conn, :new))
  end

  defp validate_captcha(ip_address, captcha) do
    if ip_address.attempts >= 3 and captcha == "" do
      {:invalid, "Captcha is required."}
    else
      {:valid}
    end
  end

  def create(conn, params) do
    conn
    |> put_flash(:error, "Invalid Login! Please try again.")
    |> redirect(to: session_path(conn, :new))
  end

  def delete(conn, _) do
    conn
    |> Auth.logout
    |> put_flash(:info, "See you later!")
    |> redirect(to: session_path(conn, :new))
  end

  def sign_out_error_dt(conn, _) do
    conn
    |> Auth.logout
    |> put_flash(:error, "Error encountered. Please sign in again.")
    |> redirect(to: session_path(conn, :new))
  end

  def create_password(conn, %{"password_token" => password_token}) do
    if user = validate_password_token(password_token) do
      changeset = User.password_changeset(user)

      conn
      |> render(
        "create_password.html",
        changeset: changeset,
        user: user,
        action: session_path(conn, :insert_password, user.password_token)
      )
    else
      conn
      |> put_flash(:error, "Invalid invite link!")
      |> redirect(to: session_path(conn, :new))
    end
  end

  def create_password(conn, params) do
    conn
    |> put_flash(:error, "Invalid invite link!")
    |> redirect(to: session_path(conn, :new))
  end

  def insert_password(conn, %{"password_token" => password_token, "user" => user_params}) do
    user = validate_password_token(password_token)
    changeset = User.password_changeset(user, user_params)
    if user_params["password"] != user_params["password_confirmation"] do
      conn
      |> put_flash(
        :error,
        "Password and Password Confirmation doesn't match!"
      )
      |> render(
        "create_password.html",
        changeset: changeset,
        user: user,
        action: session_path(conn, :insert_password, user.password_token)
      )
    else
      case set_password(changeset) do
        {:ok, user} ->
          conn
          |> Auth.login(user)
          |> put_flash(:info, "Password created successfully!")
          |> set_permissions(user)
          |> redirect(to: page_path(conn, :index))
        {:error, changeset} ->
          conn
          |> put_flash(
            :error,
            "Password must be at least 8 characters long and must contain at least one lower case character, one upper case character, and one special character(!@#$)"
          )
          |> render(
            "create_password.html",
            changeset: changeset,
            user: user,
            action: session_path(conn, :insert_password, user.password_token)
          )
      end
    end
  end

  def forgot_password(conn, _) do
    render(conn, "forgot_password.html", error: false)
  end

  def send_verification(conn, %{"session" => user_params}) do
    channel = user_params["channel"]
    username = user_params["username"]

    with false <- UtilityContext.validate_string(username),
         user = %User{} <- UserContext.get_username_with_password(username)
    do
      user
      |> UserContext.delete_verification_code()
      _changeset = UserContext.change_user(user)
      params = Map.merge(user_params, %{"verification_code" => UserContext.string_of_length()})

      {:ok, user} = UserContext.update_user(user, params)

      if channel == "Email" do
        user
        |> EmailSmtp.reset_password()
        |> Mailer.deliver_now
        conn
        |> put_flash(:info, "Verification Code has been sent to your email!")
        |> redirect(to: session_path(conn, :verify_code, user))
      else
        user_mobile = transforms_number(user.mobile)
        SMS.send(%{text: "Your verification code is #{user.verification_code}", to: user_mobile})
        conn
        |> put_flash(:info, "Verification Code has been sent via SMS!")
        |> redirect(to: session_path(conn, :verify_code_sms, user))
      end
    else
      _ ->
      conn
      |> put_flash(:error, "Invalid username!")
      |> redirect(to: "/forgot_password")
    end
  end

  def send_verification2(conn, %{"session" => user_params}) do
    user_info = user_params["userinfo"]
    type = UserContext.is_pnum_or_email?(user_info)
    ip = UtilityContext.get_ip(conn)
    ip_address = LoginIpAddressContext.get_ip_address(ip)
    case type do
      "email" ->
        with {:ok, user} <- UserContext.get_user_by_email2(user_info)
        do

          url =
            if Application.get_env(:payor_link, :env) == :prod do
              Atom.to_string(conn.scheme) <> "://"
              <> Endpoint.struct_url.host
            else
              Endpoint.url
            end

          user = UserContext.generate_reset_token(user)
          user =
            user
            |> Map.put(:link, "#{url}/reset_password/#{user.reset_token}")
            |> EmailSmtp.reset_password()
            |> Mailer.deliver_now
          conn
          |> render("new.html", info: "We've sent you a email with instructions on how to reset your password", attempts: ip_address.attempts, url: url)
        else
          {:user_not_found} ->
            conn
            |> render("forgot_password.html", error: "We don't recognize the email address/phone number you have entered. Try entering it again.")
          _ ->
            ""
        end
      "mobile" ->
        with {:ok, user} <- user = UserContext.get_user_by_mobile2(user_info) do
          UserContext.delete_verification_code(user)
            user_mobile = transforms_number(user_info)
            params = Map.merge(user_params, %{"verification_code" => UserContext.string_of_length()})
            {:ok, user} = UserContext.update_user(user, params)
            UserContext.update_user_expiry(user)
            SMS.send(%{text: "Your verification code is #{user.verification_code}", to: user_mobile})
            conn
            |> put_flash(:info, "Verification Code has been sent via SMS!")
            |> redirect(to: session_path(conn, :verify_code_sms, user.id))
        else
          {:user_not_found} ->
            conn
            |> render("forgot_password.html", error: "We don't recognize the email address/phone number you have entered. Try entering it again.")
          _ ->
            ""
        end
        _ ->
          conn
          |> render("forgot_password.html", error: "We don't recognize the email address/phone number you have entered. Try entering it again.")
    end
  end
  def send_verification2(conn, _) do
    conn
    |> render("forgot_password.html", error: "Error has been occurred.")
  end

  def resend_code(conn, %{"id" => id}) do
    # user = get_user!(id)
    # user
    # |> UserContext.delete_verification_code()
    # |> UserContext.update_verification_code()
    # changeset = change_user(user)
    # conn
    # |> put_flash(:info, "Verification code has been resent via SMS!")
    # |> render("verify_code_sms.html", changeset: changeset, user: user, mobile: user.mobile, action: session_path(conn, :update_code, user))

    ip = UtilityContext.get_ip(conn)
    user = UserContext.get_user!(id)
    user = user
           |> UserContext.delete_verification_code()
           |> UserContext.update_verification_code()
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
    changeset = change_user(user)
    user_mobile = transforms_number(user.mobile)
    SMS.send(%{text: "Your verification code is #{user.verification_code}", to: user_mobile})

    {:system, rc_site_key} = Application.get_env(:recaptcha, :public_key)

    with %LoginIpAddress{} = ip_address <- LoginIpAddressContext.get_ip_address(ip)
    do
      UserContext.update_user_expiry(user)
      conn
      |> put_flash(:info, "Verification code has been resent via SMS!")
      |> render(
        "verify_code_sms.html",
        changeset: changeset,
        mobile: mobile,
        user: user,
        attempts: ip_address.verify_attempts,
        public_key: rc_site_key,
        action: session_path(conn, :code_verification, user))
    else
      _ ->
        {:ok, ip_address} = LoginIpAddressContext.create_verify_ip_address(ip)

        conn
        |> put_flash(:info, "Verification code has been resent via SMS!")
        |> render(
          "verify_code_sms.html",
          changeset: changeset,
          mobile: mobile,
          user: user,
          attempts: ip_address.verify_attempts,
          public_key: rc_site_key,
          action: session_path(conn, :code_verification, user))
    end
  end

  def update_code(conn, %{"id" => id, "user" => user_params}) do
    user = get_user!(id)
    _changeset = change_user(user)
    channel = user_params["channel"]
    username = user_params["username"]

    if user = UserContext.get_username_with_password(username) do
      params = Map.merge(user_params, %{"verification_code" => string_of_length()})
      {:ok, user} = UserContext.update_user(user, params)

      if channel == "Email" do

        user
        |> EmailSmtp.reset_password()
        |> Mailer.deliver_now

        conn
        |> put_flash(:info, "Verification Code has been sent to your email!")
        |> redirect(to: session_path(conn, :verify_code, user))
      else
        user_mobile = transforms_number(user.mobile)
        SMS.send(%{text: "Your verification code is #{user.verification_code}", to: user_mobile})
        conn
        |> put_flash(:info, "Verification Code has been sent via SMS!")
        |> redirect(to: session_path(conn, :verify_code_sms, user))
      end
    else
      conn
      |> put_flash(:error, "Invalid username!")
      |> redirect(to: "/forgot_password")
    end
  end

  def verify_code(conn, %{"id" => id}) do
    user = get_user!(id)
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
    changeset = change_user(%User{})

    conn
    |> render(
      "verify_code_email.html",
      changeset: changeset,
      user: user,
      email: email,
      action: session_path(conn, :code_verification, user)
    )
  end

  def verify_code_sms(conn, %{"id" => id}) do
    ip = UtilityContext.get_ip(conn)
    user = get_user!(id)
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
    changeset = change_user(%User{})

    {:system, rc_site_key} = Application.get_env(:recaptcha, :public_key)

    with %LoginIpAddress{} = ip_address <- LoginIpAddressContext.get_ip_address(ip)
    do
      conn
      |> render(
        "verify_code_sms.html",
        changeset: changeset,
        mobile: mobile,
        user: user,
        attempts: ip_address.verify_attempts,
        public_key: rc_site_key,
        action: session_path(conn, :code_verification, user))
    else
      _ ->
        {:ok, ip_address} = LoginIpAddressContext.create_verify_ip_address(ip)

        conn
        |> render(
          "verify_code_sms.html",
          changeset: changeset,
          mobile: mobile,
          user: user,
          attempts: ip_address.verify_attempts,
          public_key: rc_site_key,
          action: session_path(conn, :code_verification, user))
    end
  end

  def code_verification(conn, %{"id" => id, "user" => user_params}) do
    input_code = user_params["verification_code"] |> List.to_string
    user = get_user!(id)
    _changeset = change_user(user)

    ip = UtilityContext.get_ip(conn)
    ip_address = LoginIpAddressContext.get_ip_address(ip)
    if is_nil(ip_address) do
      {:ok, ip_address} = LoginIpAddressContext.create_verify_ip_address(ip)
    end
    cond do
      UserContext.check_pin_expiry(user) == false ->
        conn
        |> put_flash(:error, "Verification code has expired, request for a new code")
        |> redirect(to: session_path(conn, :verify_code_sms, id))
      input_code != user.verification_code ->
        LoginIpAddressContext.add_verify_attempt(ip_address)
        if is_nil(user_params["email"]) == false do
          conn
          |> put_flash(:error, "Invalid Verification Code!")
          |> redirect(to: session_path(conn, :verify_code, id))
        else
          conn
          |> put_flash(:error, "Invalid Verification Code!")
          |> redirect(to: session_path(conn, :verify_code_sms, id))
        end
      true ->
        LoginIpAddressContext.remove_verify_attempt(ip_address)
        UserContext.delete_verification_code(user)
        user = UserContext.generate_reset_token(user)
        conn
        |> put_flash(:info, "Code Verified!")
        |> redirect(to: session_path(conn, :reset_password, user.reset_token))
    end
  end

  def reset_password(conn, %{"reset_token" => reset_token}) do
    with %User{} = user <- get_user_by_reset_token(reset_token) do
      changeset = User.password_changeset(user)
      render(conn, "forgot_password_form.html", changeset: changeset, user: user, action: session_path(conn, :update_password, user.reset_token), error: false)
    else
      _ ->
      conn
      |> put_flash(:error, "User not found!")
      |> redirect(to: "/forgot_password")
    end
  end

  def update_password(conn, %{"reset_token" => reset_token, "user" => user_params}) do
    user = UserContext.get_user_by_reset_token(reset_token)
      if not is_nil(user.first_time) do
        if user.first_time do
          user_params =
          user_params
          |> Map.put("first_time", false)
          end
       end
    # password_history = UserContext.get_all_user_password(id)
    changeset = User.password_changeset(user, user_params)

    ip = UtilityContext.get_ip(conn)
    ip_address = LoginIpAddressContext.get_ip_address(ip)
    if is_nil(ip_address) do
      {:ok, ip_address} = LoginIpAddressContext.create_verify_ip_address(ip)
    end

    with {:ok, password} <- check_common_password(user_params["password"]),
         false <- checkpw(user_params["password"], user.hashed_password),
         {:ok} <-  check_password_confirmation(password, user_params["password_confirmation"])
    do
      case UserContext.update_password(changeset) do
        {:ok, user} ->
          UserContext.remove_reset_token(user)
          LoginIpAddressContext.remove_attempt(ip_address)
          conn
          |> Auth.login(user)
          |> put_flash(:info, "Your password has been successfully changed.")
          |> redirect(to: session_path(conn, :new))
        {:error, changeset} ->
          message = promt_error_message(user_params["password"])
          conn
          # |> put_flash(:error, "Password must be at least 8 characters long and must contain at least one lower case character, one upper case character, and one special character(!@#$)")
          |> render("forgot_password_form.html", error: message,
                    changeset: changeset, user: user, action: session_path(conn, :update_password, user.reset_token))
      end

    else
      {:error_password} ->
        conn
        |> render("forgot_password_form.html", error: "Password is included in the common password list, enter new one",
                  changeset: changeset, user: user, action: session_path(conn, :update_password, user.reset_token))
      true ->
        conn
        |> render("forgot_password_form.html", error: "You have used that password before, enter new one",
                  changeset: changeset, user: user, action: session_path(conn, :update_password, user.reset_token))
      {:error_confirm_password} ->
        conn
        |> render("forgot_password_form.html", error: "Password and Password Confirmation doesn't match!",
                  changeset: changeset, user: user, action: session_path(conn, :update_password, user.reset_token))
    end
  end

  defp promt_error_message(password) do
    error_message = ""
    error_message = if Regex.match?(~r/^(?=.*[#?!@$%^&*-])[a-zA-Z0-9#?!@$%^&*-]*$/, password) == false do
      Enum.join([error_message, "Password should contain at least one special character(!@#$) |||"])
    else
      error_message
    end
    error_message = if Regex.match?(~r/^(?=.*[A-Z])[a-zA-Z0-9#?!@$%^&*-]*$/, password) == false do
      Enum.join([error_message, "Password should at least one upper case character |||"])
    else
      error_message
    end
    error_message = if Regex.match?(~r/^(?=.*[a-zA-Z])(?=.*[0-9])[a-zA-Z0-9#?!@$%^&*-]*$/, password) == false do
      Enum.join([error_message, "Password should contain alpha-numeric |||"])
    else
      error_message
    end
    error_message = if String.length(password) < 8 or String.length(password) > 128  do
      Enum.join([error_message, "Password must be at least 8 characters and at most 128 character"])
    else
      error_message
    end
  end

  defp check_common_password(password) do
    common_password = UserContext.get_all_common_password()
    with false  <-  Enum.member?(common_password, password) do
      {:ok, password}
    else
      _ -> {:error_password}
    end
  end

  defp check_password_confirmation(password, confirm_password) do
    with false <- password != confirm_password do
       {:ok}
    else
      _ ->
        {:error_confirm_password}
    end
  end

  defp transforms_number(number) do
    number =
      number
      |> String.slice(1..11)
    "63#{number}"
  end

  def load_all_username(conn, _params) do
    users = list_username()
    json conn, Poison.encode!(users)
  end

  defp set_permissions(conn, user) do
    query = (
      from ur in UserRole,
      join: r in Role, on: ur.role_id == r.id,
      join: pr in RolePermission, on: r.id == pr.role_id,
      join: p in Permission, on: pr.permission_id == p.id,
      where: ur.user_id == ^user.id,
      select: p.keyword
    )
    permissions = Repo.all(query)
    conn
    |> put_session(:permissions, permissions)
  end

  def submit_change_password(conn, %{"id" => id, "user" => params})do
    user =
      id
      |> UserContext.get_user!()

    params =
      params
      |> Map.put("attempt", 0)
      |> Map.put("status", "active")

    changeset =
      %User{}
      |> User.password_changeset()

    common_password = UserContext.get_all_common_password()
    password_history = UserContext.get_all_user_password(id)

    with {:password_correct} <- Auth.verify_password(user, params["current_password"]),
         true <- not Enum.member?(common_password, params["password"]),
         {:not_in_history} <- Auth.check_user_history(password_history, params["password"]),
         {:ok, user} <- UserContext.update_password(user, params),
         {:ok}  <- UserContext.insert_password_history(user, params)
    do
      conn
      |> put_flash(:info, "Password change successful!")
      |> render(
        "change_password.html",
        changeset: changeset,
        user: user
      )
    else
      false ->
        conn
        |> put_flash(:error, "The password you enter belongs to the database common password.")
        |> render(
          "change_password.html",
          changeset: changeset,
          user: user
        )
      {:error_user, message} ->
        conn
        |> put_flash(:error, message)
        |> render(
          "change_password.html",
          changeset: changeset,
          user: user
        )
      {:error, changeset} ->
        conn
        |> put_flash(:error, "Pleae check you errors")
        |> render(
          "change_password.html",
          changeset: changeset,
          user: user
        )
      {:in_history} ->
        conn
        |> put_flash(:error, "Password is included in the common password list, enter new one")
        |> render(
          "change_password.html",
          changeset: changeset,
          user: user
        )
    end
  end

   def change_password(conn, _params) do
    # insert template here
    user =
      conn.assigns.current_user.id
      |> UserContext.get_user!()

    changeset =
      user
      |> User.update_account_changeset()

    conn
    |> render(
      "change_password.html",
      user: user,
      changeset: changeset
    )
  end

end
