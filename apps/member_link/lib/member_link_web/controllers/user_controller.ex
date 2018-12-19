defmodule MemberLinkWeb.UserController do
  use MemberLinkWeb, :controller
  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]
  import Logger

  # alias Ecto.Changeset
  alias Innerpeace.Db.Repo
  alias Innerpeace.Db.{
    Utilities.SMS,
    Schemas.User,
    Schemas.Member,
    Schemas.ProfileCorrection,
    Base.UserContext,
    Base.MemberContext,
    Base.Api.UtilityContext,
    Base.ProfileCorrectionContext
  }
  alias Innerpeace.MemberLink.{
    EmailSmtp,
    Mailer
  }
  alias MemberLink.Guardian, as: MG

  def register_card_verification(conn, _params) do
    render conn, "card_verification.html"
  end

  def register_verify_member(conn, %{"user" => user}) do
    cardnumber = Enum.join(user["card_number"], "")
    if Enum.all?([user["date"], user["month"], user["year"], cardnumber], fn(x) -> x == "" end) || Enum.any?([user["date"], user["month"], user["year"], cardnumber], fn(x) -> x == "" end) || String.length(cardnumber) != 16 do
      conn
      |> put_flash(:error, "Please fill up all the fields")
      |> render("card_verification.html")
    else
      date_to_int = String.to_integer(user["date"])
      date_to_int =
        if date_to_int <= 9 do
          date_to_int
          |> Integer.to_string()
          |> (&("0" <> &1)).()
        else
          date_to_int
          |> Integer.to_string()
        end
      birthday = Enum.join([user["month"], date_to_int, user["year"]], "/")

      user = %{"birthday" => birthday, "cardnumber" => cardnumber}
      with {:ok, _date} <- UtilityContext.birth_date_transform(birthday),
        %Member{} <- MemberContext.card_number_verification(cardnumber),
        {:ok, member} <- MemberContext.member_card_verification(user),
        {:ok, member} <- UserContext.validate_registered_member(member.id)
      do
        conn
        |> put_flash(:info, "Member is validated!")
        |> redirect(to: "/#{conn.assigns.locale}/register/#{member.id}/new")
      else
        {:already_registered} ->
        conn
        |> put_flash(:error, "Member is already registered!")
        |> render("card_verification.html")
        {:empty_birthday} ->
        conn
        |> put_flash(:error, "Birthday can't be blank!")
        |> render("card_verification.html")
        {:invalid_datetime_format} ->
        conn
        |> put_flash(:error, "Invalid date Format!")
        |> render("card_verification.html")
        {:cardnumber_is_invalid} ->
        conn
        |> put_flash(:error, "Card Number can't be blank!")
        |> render("card_verification.html")
        {:card_number_not_found} ->
        conn
        |> put_flash(:error, "The details you have entered are invalid")
        |> render("card_verification.html")
        {:member_not_found} ->
        conn
        |> put_flash(:error, "Member not found")
        |> render("card_verification.html")
        {:inactive_member} ->
        conn
        |> put_flash(:error, "The Member you have entered is not Active")
        |> render("card_verification.html")
        _ ->
        conn
        |> put_flash(:error, "Server error")
        |> render("card_verification.html")
      end
    end
  end

  def register_setup_registration(conn, %{"id" => id, "locale" => locale}) do
    member = MemberContext.get_member!(id)
    changeset = User.changeset_member(%User{})
    principal_number =
      if member.type == "Dependent" do
       "0#{member.principal.mobile}"
      else
        "not_dependent"
      end
    render(conn, "step_1_form.html", member: member, locale: locale, changeset: changeset, principal_number: principal_number)
  end

  def register_setup_contacts(conn, %{"member_id" => member_id, "locale" => locale, "user_id" => _user_id}) do
    member = MemberContext.get_member!(member_id)
    changeset = User.changeset_member(%User{})
    render(conn, "step_2_form.html", member: member, locale: locale, changeset: changeset)
  end

  def register_member(conn, %{"user" => params}) do
    member = MemberContext.get_member!(params["member_id"])
    params = Map.merge(params, %{
      "first_name" => member.first_name, "last_name" => member.last_name,
      "middle_name" => member.middle_name, "suffix" => member.suffix,
      "birthday" =>  member.birthdate, "gender" => member.gender,
      "verification_code" => UserContext.generate_verification_code()
    })
    case UserContext.register_member(member, params) do
      {:ok, user} ->
        UserContext.update_user_expiry(user)
        {:ok, user} = UserContext.register_update_member(user, %{
          "created_by_id" => user.id,
          "updated_by_id" => user.id
        })
        if not is_nil(user.mobile) do
          user_mobile = transforms_number(user.mobile)
        else
          user_mobile = transforms_number(user.other_mobile)
        end
        SMS.send(%{text: "Your verification code is #{user.verification_code}", to: user_mobile})
        _email =
          user
          |> EmailSmtp.invite_user()
          |> Mailer.deliver_now

        conn
        |> put_flash(:info, "Personal details added successfully!")
        |> redirect(to: "/#{conn.assigns.locale}/register/#{member.id}/#{user.id}/success")
      {:error, changeset} ->
        principal_number =
          member.principal.id
          |> UserContext.get_principal_number

        raise changeset
        conn
        |> put_flash(:error, "Error creating User! Please check the errors below.")
        |> render("step_1_form.html", member: member, changeset: changeset, principal_number: principal_number)
    end
  end

  def step_1(conn, _user) do
    render conn, "step_1_form.html"
  end

  def step_2(conn, _user) do
    render conn, "step_2_form.html"
  end

  def register_setup(conn, %{"step" => step, "id" => id}) do
    user = UserContext.get_user!(id)
    #validate_step(conn, user, step)
    case step do
      "1" ->
        step_1(conn, user)
      "2" ->
        step_2(conn, user)
      _ ->
        conn
        |> redirect(to: user_path(conn, :card_verification))
    end
  end

  def register_validate_step(conn, user, step) do
    if user.step < String.to_integer(step) do
      conn
      |> put_flash(:error, "Not allowed!")
      |> redirect(to: user_path(conn, :card_verification))
    end
  end

  def register_user_validate(conn, _params) do
    users = UserContext.select_user_fields()
    json conn, Poison.encode!(users)
  end


  def register_success(conn, %{"member_id" => member_id, "user_id" => user_id}) do
    member = MemberContext.get_member!(member_id)
    user = UserContext.get_user!(user_id)
    render(conn, "sign_up_success.html", member: member, user: user, locale: conn.assigns.locale)
  end

  def register_verify_account(conn, %{"member_id" => member_id, "user_id" => user_id}) do
    member = MemberContext.get_member!(member_id)
    user = UserContext.get_user!(user_id)
    user_mobile = if not is_nil(user.mobile) do
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
    render(conn, "account_verification.html", mobile: mobile, user: user, changeset: changeset, action: user_path(conn, :register_account_verification, conn.assigns.locale, member, user, 3))
  end

  def register_account_verification(conn, %{"user" => params, "member_id" => member_id, "user_id" => user_id, "attempts" => attempts}) do

    user = UserContext.get_user!(user_id)
    _changeset = UserContext.change_user(%User{})
    member = MemberContext.get_member!(member_id)
    if Enum.any?([params["verification_code"] == nil, params["verification_code"] == ""]) do
      conn
      |> put_flash(:error, "Verification Code can't be blank!")
      |> redirect(to: user_path(conn, :register_verify_account, conn.assigns.locale, member, user))
    else
      pin = if is_binary(params["verification_code"]) do
        String.to_integer(params["verification_code"])
      else
        params["verification_code"]
      end
      with true <- UserContext.check_pin_expiry(user),
           {:ok, "user"} <- UserContext.check_user_status(user.id),
           user = %User{} <- UserContext.validate_user_verification_code(
             user.id, pin),
           {:ok, user} <- UserContext.update_verification(
             user, %{verification: true})
      do
        UserContext.delete_verification_code(user)
        conn
        |> put_flash(:info, "Code Verified!")
        |> redirect(to: user_path(conn, :register_bank_kyc_1, conn.assigns.locale, member, user))
      else
        false ->
          UserContext.update_user_expiry(user)
          conn
          |> put_flash(:error, "The 4-Digit PIN Code that you have entered is already expired")
          |> redirect(to: user_path(conn, :register_verify_account, conn.assigns.locale, member, user))
        {:locked} ->
          conn
          |> put_flash(:error, "Your account has been locked, please reset your password")
          |> redirect(to: session_path(conn, :forgot_password, conn.assigns.locale))
        nil ->
          attempts =
            if user.attempts == nil do
              1
            else
              user.attempts + 1
            end
          if attempts == 3 do
            UserContext.update_user_status(user)
            conn
            |> put_flash(:error, "Your account has been locked, please reset your password")
            |> redirect(to: session_path(conn, :forgot_password, conn.assigns.locale))
          else
            UserContext.update_user_attempts(user, %{attempts: attempts})
          end
            conn
            |> put_flash(:error, "Verification failed!")
            |> redirect(to: user_path(conn, :register_verify_account_failed, conn.assigns.locale, member, user, attempts))
        _ ->
        conn
        |> put_flash(:error, "Verification failed!")
        |> redirect(to: user_path(conn, :register_verify_account_failed, conn.assigns.locale, member, user, attempts))
      end
    end
  end

  def register_verify_account_failed(conn, %{"member_id" => member_id, "user_id" => user_id, "attempts" => attempts}) do
    member = MemberContext.get_member!(member_id)
    user = UserContext.get_user!(user_id)
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
    render(conn, "account_verification_failed.html", mobile: mobile, user: user, changeset: changeset, attempts: attempts, action: user_path(conn, :register_account_verification, conn.assigns.locale, member, user, attempts))
  end

  def register_resend_code(conn, %{"user_id" => id}) do
    user = UserContext.get_user!(id)
    member = MemberContext.get_member!(user.member_id)
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
    _email =
      user
      |> EmailSmtp.invite_user()
      |> Mailer.deliver_now

    conn
    |> put_flash(:info, "Verification Code has been sent to your mobile number and email")
    |> redirect(to: user_path(conn, :register_verify_account, conn.assigns.locale, member, user))
  end

  def register_bank_kyc_1(conn, %{"member_id" => member_id, "user_id" => user_id}) do
    member = MemberContext.get_member!(member_id)
    user = UserContext.get_user!(user_id)
    render conn, "register_bank_kyc_details.html", member: member, user: user
  end

  def register_bank_kyc_2(conn, %{"member_id" => member_id, "user_id" => user_id}) do
    member = MemberContext.get_member!(member_id)
    user = UserContext.get_user!(user_id)
    render conn, "register_bank_kyc_contact.html", member: member, user: user
  end

  def register_bank_kyc_3(conn, %{"member_id" => member_id, "user_id" => user_id}) do
    member = MemberContext.get_member!(member_id)
    user = UserContext.get_user!(user_id)
    render conn, "register_bank_kyc_submit.html", member: member, user: user
  end

  defp transforms_number(number) do
    number =
      number
      |> String.slice(1..11)
    "63#{number}"
  end

  def view_account(conn, _params) do
    user =
      MG.current_resource(conn).id
      |> UserContext.get_user!()

    conn
    |> render(
      "show_account.html",
      user: user
    )
  end

  def edit_account(conn, _params) do
    user =
      MG.current_resource(conn).id
      |> UserContext.get_user!()

    changeset =
      user
      |> User.update_account_changeset()

    conn
    |> render(
      "edit_account.html",
      user: user,
      changeset: changeset
    )
  end

  def update_account(conn, %{"user" => user_params}) do
    user =
      MG.current_resource(conn).id
      |> UserContext.get_user!()

    changeset =
      user
      |> User.update_account_changeset(user_params)

    with true <- changeset.valid?,
         {:ok, _user} <- UserContext.update_password(changeset)
    do
      conn
      |> put_flash(:info, "Password successfully updated.")
      |> redirect(to: user_path(conn, :view_account, conn.assigns.locale))
    else
      false ->
        error_msg =
          cond do
            not is_nil(Keyword.get(changeset.errors, :old_password)) ->
              {message, validation} =
                Keyword.get(changeset.errors, :old_password)

                if Keyword.get(validation, :validation) == :required do
                  "Please enter old password"
                else
                  message
                end
            not is_nil(Keyword.get(changeset.errors, :password)) ->
              {message, validation} =
                Keyword.get(changeset.errors, :password)

                if Keyword.get(validation, :validation) == :required do
                  "Please enter new password"
                else
                  message
                end
            not is_nil(Keyword.get(changeset.errors, :password_confirmation)) ->
              {message, validation} =
                Keyword.get(changeset.errors, :password_confirmation)

                if Keyword.get(validation, :validation) == :required do
                  "Please enter confirm new password"
                else
                  message
                end
            true ->
              {"error", "error"}
          end

          if error_msg == "Invalid password" do

            conn
            |> render(
              "edit_account.html",
              user: user,
              changeset: changeset,
              invalid_password: true
            )
          else

            conn
            |> put_flash(:error, error_msg)
            |> render(
              "edit_account.html",
              user: user,
              changeset: changeset
            )
          end

    end
  end

  def validate_old_password(conn, %{"user" => user_params}) do
    user =
      MG.current_resource(conn).id
      |> UserContext.get_user!()

    changeset =
      user
      |> User.validate_old_pass_changeset(%{
        old_password: user_params["old_password"]
      })

    message =
      if is_nil(Keyword.get(changeset.errors, :old_password)) do
      else
        {message, validation} =
          changeset.errors
          |> Keyword.get(:old_password)

          if Keyword.get(validation, :additional) == :invalid_password do
            message
          end
      end

    json conn, message
  end

  def edit_profile(conn, _params) do
    user =
      MG.current_resource(conn).id
      |> UserContext.get_user!()
      |> Repo.preload(member: [
        :account_group
      ])

    changeset =
      %Member{}
      |> Member.changeset_photo()

    conn
    |> render(
      "show_profile.html",
      user: user,
      changeset: changeset
    )
  end

  def update_profile(conn, %{"member" => member_params}) do
    user =
      MG.current_resource(conn).id
      |> UserContext.get_user!()
      |> Repo.preload(member: [
        :account_group
      ])

    with {:ok, %Member{} = _member} <-
      MemberContext.update_member_photo(user.member, member_params)
    do
      conn
      |> put_flash(:info, "Photo successfully uploaded.")
      |> redirect(
        to: user_path(
          conn,
          :edit_profile,
          conn.assigns.locale)
      )
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Error was encountered while uploading the photo")
        |> render(
          "show_profile.html",
          user: user,
          changeset: changeset
        )
    end
  end

  def request_profile_correction(conn, _params) do
    user =
      MG.current_resource(conn).id
      |> UserContext.get_user!()
      |> Repo.preload(member: [
        :account_group
      ])

    changeset =
      %ProfileCorrection{}
      |> ProfileCorrection.changeset()

    conn
    |> render(
      "request_profile_correction.html",
      user: user,
      changeset: changeset
    )
  end

  def send_request_prof_cor(conn, %{"profile_correction" => prof_cor_params}) do

    user =
      MG.current_resource(conn).id
      |> UserContext.get_user!()
      |> Repo.preload(member: [
        :account_group
      ])

    with {:ok, %ProfileCorrection{} = _prof_cor} <-
      ProfileCorrectionContext.create_request_prof_cor(
      MG.current_resource(conn).id,
        prof_cor_params)
    do
      conn
      |> put_flash(
        :info,
        "Your personal information correction request has been sent"
      )
      |> redirect(
        to: user_path(
          conn,
          :edit_profile,
          conn.assigns.locale)
      )
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> render(
          "request_profile_correction.html",
          user: user,
          changeset: changeset
        )
      {:atleast_one} ->
        changeset =
          %ProfileCorrection{}
          |> ProfileCorrection.changeset(prof_cor_params)

        conn
        |> render(
          "request_profile_correction.html",
          user: user,
          changeset: changeset,
          atleast_one: "One of these fields must be present: [Name, Birth Date, Gender]"
        )
    end
  end

  def edit_contact_details(conn, _params) do
    user =
      MG.current_resource(conn).id
      |> UserContext.get_user!()

    changeset =
      %User{}
      |> User.contact_details_changeset()

    conn
    |> render(
      "show_contact_details.html",
      user: user,
      changeset: changeset
    )
  end

  def update_contact_details(conn, %{"contact" => contact_params}) do
    user =
      MG.current_resource(conn).id
      |> UserContext.get_user!()

    contact_params =
      contact_params
      |> Map.put("mobile", String.replace(contact_params["mobile"], "-", ""))
      |> Map.put("mobile_confirmation", String.replace(contact_params["mobile_confirmation"], "-", ""))

    with {:ok, %User{} = _user} <-
      UserContext.update_contact_details(
        user,
        contact_params)
    do
      conn
      |> put_flash(:info, "Contact Details successfully updated.")
      |> redirect(
        to: user_path(
          conn,
          :edit_contact_details,
          conn.assigns.locale)
      )
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> render(
          "show_contact_details.html",
          user: user,
          changeset: changeset
        )
    end
  end
end
