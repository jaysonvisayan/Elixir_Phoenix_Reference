defmodule Innerpeace.Db.Base.UserContext do
  @moduledoc """
  This module provides a user context.
  """

  import Ecto.{Query, Changeset}, warn: false
  alias Innerpeace.{
    Db.Repo,
    Db.Schemas.User,
    Db.Schemas.UserRole,
    Db.Schemas.UserAccount,
    Db.Schemas.Member,
    Db.Schemas.Role,
    Db.Schemas.RolePermission,
    Db.Schemas.Permission,
    Db.Schemas.RoleApplication,
    Db.Schemas.Application,
    Db.Schemas.TermsNCondition,
    Db.Schemas.UserAccessActivationLog,
    Db.Schemas.UserAccessActivationFile,
    Db.Parsers.UserAccessActivationParser,
    Db.Utilities.SMS,
    PayorLink.EmailSmtp,
    PayorLink.Mailer,
    Db.Schemas.CommonPassword,
    Db.Schemas.UserPassword,
    Db.Schemas.UserReportingTo,
    Db.Base.ApiAddressContext
  }

  alias Innerpeace.Db.Utilities.SMS
  alias Innerpeace.Db.Base.Api.UtilityContext
  alias Comeonin.Bcrypt

  def check_user_by_email(email) do
    User
    |> where([u], ilike(u.email, ^email))
    |> select([u], u.id)
    |> limit(1)
    |> Repo.one()
  end

  def check_user_by_email(email, current_email) do
    User
    |> where([u], ilike(u.email, ^email))
    |> where([u], u.email != ^current_email)
    |> select([u], u.id)
    |> limit(1)
    |> Repo.one()
  end

  def check_user_by_mobile(mobile) do
    User
    |> where([u], u.mobile == ^mobile)
    |> select([u], u.id)
    |> limit(1)
    |> Repo.one()
  end

  def check_user_by_mobile(mobile, current_mobile) do
    User
    |> where([u], u.mobile == ^mobile and u.mobile != ^current_mobile)
    |> select([u], u.id)
    |> limit(1)
    |> Repo.one()
  end

  def check_user_by_username(username) do
    User
    |> where([a], ilike(a.username, ^username))
    |> Repo.one()
  end

  def insert_or_update_user_role(params) do
    user_role = get_ur_by_user_role(params)
    if is_nil(user_role) do
      create_user_roles(params)
    else
      clear_user_roles(params.user_id)
      create_user_roles(params)
    end
  end

  def first_role(user) do
    user = user |> Repo.preload(:roles)
    case user.roles do
      [] -> nil
      roles ->
        {:ok, role} = Enum.fetch(user.roles, 0)
        role
    end
  end

  def get_user_role_by_user_id(user_id) do
    UserRole
    |> Repo.get_by(user_id: user_id)
    |> Repo.preload([:user, :role])
  end

  def get_ur_by_user_role(params) do
    UserRole
    |> Repo.get_by(user_id: params.user_id, role_id: params.role_id)
    |> Repo.preload([:user, :role])
  end

  def insert_or_update_user_account(params) do
    user_account = get_user_account(params.user_id, params.account_group_id)
    if is_nil(user_account) do
      create_user_account(params.user_id, params.account_group_id)
    else
    end
  end

  def get_user_account(user_id, account_group_id) do
    UserAccount
    |> Repo.get_by(user_id: user_id, account_group_id: account_group_id)
  end

  def create_user_account(user_id, account_group_id) do
    %UserAccount{}
    |> UserAccount.changeset(%{user_id: user_id, account_group_id: account_group_id})
    |> Repo.insert()
  end

  def insert_or_update_user(params) do
    user = get_username(params.username)
    if user != nil do
      user
      |> update_user(params)
    else
      create_admin(params)
    end
  end

  def list_users do
    User
    |> where([u], u.is_admin == false)
    |> Repo.all()
    |> Repo.preload([
      :created_by,
      :updated_by,
      [
        roles: [
          role_applications: :application
        ]
      ],
    ])
  end

  def get_username(username) do
    User
    # |> Repo.get_by(username: username)
    |> where(
      [u],
      fragment(
        "lower(?) = lower(?)",
        u.username,
        ^username
      )
    )
    |> limit(1)
    |> Repo.one()
  end

  def get_username_with_password(username) do
    User
    |> where([u], u.username == ^username
             and is_nil(u.hashed_password) == false)
    |> Repo.get_by(username: username)
  end

  def get_user(id) do
    User |> Repo.get(id) |> Repo.preload([:roles, member: :emergency_contact, user_account: :account_group])
  end

  def get_user_by_reset_token(reset_token) do
    User
    |> Repo.get_by(%{reset_token: reset_token})
  end

  def get_user!(id) do
    User
    |> Repo.get!(id)
    |> Repo.preload([
      :company,
      :facility,
      [reporting_to: :lead],
      [member: :emergency_contact],
      [user_account: :account_group],
      [
        roles: [
          role_applications: :application,
          role_permissions: :permission
        ]
      ],
    ])

    rescue
      _ -> nil
  end

  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def create_user2(attrs \\ %{}) do
    %User{}
    |> User.changeset2(attrs)
    |> Repo.insert()
  end

  def create_admin(attrs \\ %{}) do
    %User{}
    |> User.admin_changeset(attrs)
    |> Repo.insert()
  end

  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  def change_user(%User{} = user) do
    User.changeset(user, %{})
  end

  def change_admin(%User{} = user) do
    User.admin_changeset(user, %{})
  end

  def validate_password_token(token) do
    User
    |> Repo.get_by(password_token: token)
  end

  def validate_verification_code(verification_code) do
    User
    |> Repo.get_by(verification_code: verification_code)
  end

  def set_password(changeset) do
    changeset
    |> Map.put("password_token", nil)
    |> Repo.update()
  end

  def set_user_roles(user_id, role_ids) do
    for role_id <- role_ids do
      params = %{user_id: user_id, role_id: role_id}
      changeset = UserRole.changeset(%UserRole{}, params)
      Repo.insert(changeset)
    end
  end

  def create_user_roles(params) do
    changeset = UserRole.changeset(%UserRole{}, params)
    Repo.insert!(changeset)
  end

  def clear_user_roles(user_id) do
    UserRole
    |> where([ur], ur.user_id == ^user_id)
    |> Repo.delete_all()
  end

  def update_password(changeset) do
    changeset
    |> Repo.update()
  end

  def delete_verification_code(user) do
    user
    |> User.verification_code_changeset(%{verification_code: nil})
    |> Repo.update!()
  end

  def update_verification_code(user) do
    code = string_of_length()
    user
    |> User.changeset(%{verification_code: code})
    |> Repo.update!()
  end

  def string_of_length do
    100_000..999_999 |> Enum.random() |> Integer.to_string()
  end

  defp transforms_number(number) do
    number =
    number
    |> String.split
    |> Enum.at(1)
    |> String.split("-")
    |> Enum.join()

    list = ["63", number]
    Enum.join(list)
  end

  def select_user_fields do
    User
    |> select([:first_name, :last_name, :mobile, :username, :email, :middle_name])
    |> Repo.all
  end

  def list_username do
    User
    |> select([:username])
    |> Repo.all
  end

  def list_user_email_mobile do
    User
    |> select([:username, :email, :mobile])
    |> Repo.all
  end
  # Start of MemberLink
  def update_username(user, params) do
    user
    |> User.username_changeset(params)
    |> Repo.update()
  end

  def update_password(user, params) do
    user
    |> User.password_changeset(params)
    |> Repo.update()
  end

  def register_member(member, params) do
    params = if member.type == "Dependent" do
      principal = Repo.get!(Member, member.principal_id)
      dep_mobile = String.slice(params["mobile"], 1, 11)
      if Enum.any?([principal.mobile == dep_mobile, principal.mobile2 == dep_mobile]) do
        params =
          params
          |> Map.put("other_mobile", params["mobile"])
          |> Map.delete("mobile")
      else
        params
      end
    else
      params
    end
    user = User.changeset_member(%User{}, params)
    user
    |> User.password_changeset(%{"password" => params["password"], "password_confirmation" => params["password_confirmation"]})
    |> Repo.insert()
  end

  def register_member(params) do
    user = User.changeset_member_api(%User{}, params)
    user
    |> User.plain_password_changeset(%{password: params.password, password_confirmation: params.password})
    |> Repo.insert()
  end

  def register_update_member(user, params) do
    user
    |> User.changeset_member(params)
    |> Repo.update()
  end

  def register_member_seed(params) do
    user = User.changeset_member_seed(%User{}, params)
    user
    |> User.password_changeset(%{"password" => params["password"], "password_confirmation" => params["password_confirmation"]})
    |> Repo.insert()
  end

  def register_update_member_seed(user, params) do
    user
    |> User.changeset_member_seed(params)
    |> Repo.update()
  end

  def validate_user_verification_code(id, pin) do
    if is_binary(pin) do
      pin = String.to_integer(pin)
    else
      pin
    end
    User
    |> where([u], u.id == ^id and u.verification_code == ^Integer.to_string(pin))
    |> Repo.one
  end

  def check_pin_expiry(user) do
    if is_nil(user.verification_expiry) do
      false
    else
      expiry = user.verification_expiry
      date = Ecto.DateTime.from_erl(:erlang.localtime)
      date_seconds = (date.hour * 60 * 60) + (date.min * 60) + date.sec
      expiry_seconds = (expiry.hour * 60 * 60) + (expiry.min * 60) + expiry.sec
      difference = date_seconds - expiry_seconds
      difference = abs(difference)
      if expiry.year == date.year && expiry.month == date.month && expiry.day == date.day && difference <= 300   do
        true
      else
        false
      end
    end
  end

  def check_pin_expiry_forgot(user) do
    if is_nil(user.verification_expiry) do
      false
    else
      expiry = user.verification_expiry
      date = Ecto.DateTime.from_erl(:erlang.localtime)
      date_seconds = (date.hour * 60 * 60) + (date.min * 60) + date.sec
      expiry_seconds = (expiry.hour * 60 * 60) + (expiry.min * 60) + expiry.sec
      difference = date_seconds - expiry_seconds
      difference = abs(difference)
      if expiry.year == date.year && expiry.month == date.month && expiry.day == date.day && difference <= 300   do
        true
      else
        false
      end
    end
  end

  def check_user_status(id) do
    user =
      User
      |> where([u], u.id == ^id and u.status == "locked")
      |> Repo.one
    if user == nil do
      {:ok, "user"}
    else
      {:locked}
    end
  end

  def update_user_expiry(%User{} = user) do
    user
    |> User.expiry_changeset(%{"verification_expiry" => Ecto.DateTime.from_erl(:erlang.localtime)})
    |> Repo.update()
  end

  def update_user_status(%User{} = user) do
    user
    |> User.status_changeset(%{status: "locked"})
    |> Repo.update()
  end

  def update_user_status_active(%User{} = user) do
    user
    |> User.status_changeset(%{status: "active"})
    |> Repo.update()
  end

  def update_user_attempts(%User{} = user, attrs) do
    user
    |> User.attempts_changeset(attrs)
    |> Repo.update()
  end

  def update_verification(%User{} = user, attrs) do
    user
    |> User.verification_changeset(attrs)
    |> Repo.update()
  end

  def generate_verification_code do
    code = Enum.random(1000..9999)
    code
    |> Integer.to_string()
  end

  def update_verification_code_member(%User{} = user, attrs) do
    user
    |> User.changeset_member(attrs)
    |> Repo.update()
  end

  def validate_request(user) do
    if is_nil(user.member_id) do
      {:not_verified}
    else
      {:ok, user}
    end
  end

  def validate_registered_member(member_id) do
    user =
      User
      |> Repo.get_by(member_id: member_id)
      |> Repo.preload(:member)
    if is_nil(user) == false do
      {:already_registered}
    else
      member =
      Member
        |> Repo.get!(member_id)
        |> Repo.preload(:user)
      if is_nil(member.status) || member.status != "Active" do
        {:inactive_member}
      else
        {:ok, member}
      end
    end
  end

  def username_get_user_email(user_email) do
    user =
      User
      |> Repo.get_by(email: user_email)
    if is_nil(user) do
      {:user_not_found}
    else
      {:ok, user}
    end
  end

  def username_get_user_mobile(user_mobile) do
    user =
      User
      |> Repo.get_by(mobile: user_mobile)
    if is_nil(user) do
      user =
        User
        |> Repo.get_by(other_mobile: user_mobile)
        if is_nil(user) do
          {:user_not_found}
        else
          {:ok, user}
        end
    else
      {:ok, user}
    end
  end

  def get_user_by_email(username, user_email) do
    query =
      from u in User, where: u.username == ^username and u.email == ^user_email
    user = Repo.one(query)
    if is_nil(user) do
    nil
    else
      {:ok, user}
    end
  end

  def get_user_by_email2(user_email) do
    query =
      from u in User, where: u.email == ^user_email
    user = Repo.all(query)
    user =
      user
      |> Enum.uniq()
      |> List.first()
    if not is_nil(user) do
      {:ok, user}
    else
      {:user_not_found}
    end
  end

  def get_user_by_mobile(username, user_mobile) do
    query =
      from u in User, where: u.username == ^username and u.mobile == ^user_mobile
    user = Repo.one(query)
    if is_nil(user) do
      {:user_not_found}
    else
      {:ok, user}
    end
  end

 def get_user_by_mobile2(user_mobile) do
    query =
      from u in User, where: u.mobile == ^user_mobile
    user = Repo.all(query)
    user =
      user
      |> Enum.uniq()
      |> List.first()
    if not is_nil(user) do
      {:ok, user}
    else
      {:user_not_found}
    end
  end

  def insert_or_update_user_memberlink(params) do
    user = get_username(params["username"])
    if user != nil do
      user
      |> register_update_member_seed(%{"created_by_id" => user.id, "updated_by_id" => user.id})
    else
      {:ok, user} = register_member_seed(params)
      register_update_member_seed(user, %{"created_by_id" => user.id, "updated_by_id" => user.id})
    end
  end

  def get_member_username(username) do
    user =
      User
      |> Repo.get_by(username: username)
      |> Repo.preload(:member)
    if is_nil(user) do
      {:not_found}
    else
      cond do
        is_nil(user.member) ->
          {:invalid_user_member}
        is_nil(user.member.status) || user.member.status != "Active" ->
          {:inactive_member}
        user.member.status == "Active" ->
          user
        true ->
          {:inactive_member}
      end
    end
  end

  def attempts_reset(user, params) do
    user
    |> User.attempts_reset(params)
    |> Repo.update()

  end

  def validate_forgot_password(params) do
    changeset = User.changeset_forgot_password(%User{}, params)
    if changeset.valid? do
      field_validate(changeset)
    else
      {:error, changeset}
    end
  end

  def validate_forgot_username(params) do
    changeset = User.changeset_forgot_username(%User{}, params)
    if changeset.valid? do
      field_validate(changeset)
    else
      {:error, changeset}
    end
  end

  def field_validate(changeset) do
    recovery = changeset.changes.recovery
    cond do
      recovery == "email" ->
        email_validate = validate_format(changeset, :text, ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
        if email_validate.valid? do
          {:ok, email_validate}
        else
          changeset = email_validate
          {:error, changeset}
        end
      recovery == "mobile" ->
        email_validate = User.validate_mobile(changeset, :text)
        if email_validate.valid? do
          {:ok, email_validate}
        else
          changeset = email_validate
          {:error, changeset}
        end
      true ->
        {:recovery_not_found}
    end
  end

  def get_user_memberlink(id) do
    user =
      User
      |> Repo.get_by(id: id)
    if is_nil(user) do
      {:user_not_found}
    else
      user
    end
  end

  def reset_password_memberlink(user, params) do
    if Bcrypt.checkpw(params["password"], user.hashed_password) do
      {:old_password}
    else
      user =
        user
        |> User.password_changeset(params)
        |> update_password(%{"password" => params["password"], "password_confirmation" => params["password_confirmation"]})
    end
  end

  def update_contact_details(user, params)  do
    user
    |> User.contact_details_changeset(params)
    |> Repo.update()
  end
  # End of MemberLink

  # Start of AccountLink
  def create_user_accountlink(attrs \\ %{}) do
    user = User.account_changeset(%User{}, attrs)

    params = %{
      "password" => attrs["password"],
      "password_confirmation" => attrs["confirm_password"]
    }

    user
    |> User.password_changeset(params)
    |> Repo.insert()
  end

  def update_user_accountlink(user, attrs) do
    user
    |> User.account_changeset(attrs)
    |> Repo.update()
  end

  def create_user_account(attrs \\ %{}) do
    %UserAccount{}
    |> UserAccount.changeset(attrs)
    |> Repo.insert()
  end

  def get_user_by_uem(params) do
    Repo.one(
      from u in User,
      where: u.username == ^params or u.email == ^params or u.mobile == ^params
    )
  end

  def get_by_id(id) do
    User
    |> Repo.get(id)
  end

  def check_pin_expiry_in_accountlink(user) do
    if is_nil(user.verification_expiry) do
      false
    else
      expiry = user.verification_expiry
      date = Ecto.DateTime.from_erl(:erlang.localtime)
      date_seconds = (date.hour * 60 * 60) + (date.min * 60) + date.sec
      expiry_seconds = (expiry.hour * 60 * 60) + (expiry.min * 60) + expiry.sec
      difference = date_seconds - expiry_seconds
      if expiry.year == date.year && expiry.month == date.month && expiry.day == date.day && difference <= 300 do
        true
      else
        false
      end
    end
  end

  def get_users_by_account(account_group_id) do
    UserAccount
    |> where([ua], ua.account_group_id == ^account_group_id)
    |> select([ua], ua.user_id)
    |> Repo.all()
  end
  # End of AccountLink

  def get_user_role_admin(user_id) do
    UserRole
    |> join(:inner, [ur], r in Role, r.id == ur.role_id)
    |> where([ur, r], ur.user_id == ^user_id and r.name == ^"admin")
    |> Repo.all()
    |> Repo.preload([:user, :role])
  end

  def get_principal_number(member_id) do
    User
    |> where([u], u.member_id == ^member_id)
    |> select([u], u.mobile)
    |> Repo.one
  end

  #added login in memberlink
  def login_by_username_and_card_no(user, member_id) do
    if user.member_id == member_id do
      {:ok, member_id}
    else
      {:not_found}
    end
  end

  def validate_login_params(params) do
    general_types = %{
      username: :string,
      password: :string
    }

    changeset =
      {%{}, general_types}
      |> cast(params, Map.keys(general_types))
      |> validate_required([
        :username,
        :password
      ])

    result = Map.keys(params) -- ["username", "password"]

    changeset.valid? and Enum.empty?(result)
  end

  def get_user_by_email(email) do
    User
    |> Repo.get_by(email: email)
  end

  def get_user_by_mobile(mobile) do
    User
    |> Repo.get_by(mobile: mobile)
  end

  def create_activation_import(params, user_id) do
    if String.ends_with?(params["file"].filename, ["csv"]) do
      data =
        params["file"].path
        |> File.stream!()
        |> CSV.decode(headers: true)

        keys = ["Code", "Employee Name"]

        with {:ok, map} <- Enum.at(data, 1),
             {:equal} <- column_checker(keys, map)
        do
          {:ok, uaa_file} =
            UserAccessActivationParser.parse(
              data,
              params["file"].filename,
              user_id
            )
          uaa_file.id
          |> get_all_payroll_codes()
          |> Enum.into([], &(String.trim(&1)))
          |> deactivate_users()
          {:ok}
        else
          nil ->
            {:not_found}
          {:error, _message} ->
            {:not_found}
          {:not_equal} ->
            {:not_equal}
          {:not_equal, columns} ->
            {:not_equal, columns}
          {:error_user} ->
            {:error_user}
        end
    else
      {:invalid_format}
    end
  end

  defp column_checker(keys, map) do
    if Enum.sort(keys) == Enum.sort(Map.keys(map)) do
      {:equal}
    else
      keys = Enum.sort(keys) -- Enum.sort(Map.keys(map))
      if Enum.count(keys) >= 6 do
        {:not_equal}
      else
        {:not_equal, Enum.join(keys, ", ")}
      end
    end
  end

  def get_by_payroll_code_log(code, uaa_file_id) do
    Repo.get_by(UserAccessActivationLog,
      code: code,
      user_access_activation_file_id: uaa_file_id
    )
  end

  def get_by_payroll_code(code), do: Repo.get_by(User, payroll_code: code)

  def user_access_activation_log(params) do
    %UserAccessActivationLog{}
    |> UserAccessActivationLog.changeset(params)
    |> Repo.insert()
  end

  def user_access_activation_file(params) do
    %UserAccessActivationFile{}
    |> UserAccessActivationFile.changeset(params)
    |> Repo.insert()
  end

  def generate_batch_no(batch_no) do
    origin = batch_no

    case Enum.count(Integer.digits(batch_no)) do
      1 ->
        batch_no = "000#{batch_no}"
      2 ->
        batch_no = "00#{batch_no}"
      3 ->
        batch_no = "0#{batch_no}"
      4 ->
        batch_no = Integer.to_string(batch_no)
      _ ->
        batch_no = Integer.to_string(batch_no)
    end

    with nil <- Repo.get_by(UserAccessActivationFile, batch_no: batch_no),
         false <- origin == 0
    do
      batch_no
    else
      %UserAccessActivationFile{} -> # UploadFile Schema
        generate_batch_no(origin + 1)
      true ->
        "0001"
    end
  end

  #uaa - UserAccessActivation
  def get_uaa_files do
    UserAccessActivationFile
    |> Repo.all()
    |> Repo.preload([:user_access_activation_logs])
  end

  def get_uaa_logs(uaa_file_id, status) do
    UserAccessActivationLog
    |> join(:inner, [uaal], uaaf in UserAccessActivationFile, uaal.user_access_activation_file_id == uaaf.id)
    |> where([uaal, uaaf], uaaf.id == ^uaa_file_id and uaal.status == ^status)
    |> order_by([uaal, uaaf], desc: uaal.inserted_at)
    |> select([uaal, uaaf], [uaal.remarks, uaal.code, uaal.employee_name])
    |> Repo.all()
  end

  def get_all_payroll_codes(uaa_file_id) do
    UserAccessActivationLog
    |> join(:inner, [uaal], uaaf in UserAccessActivationFile, uaal.user_access_activation_file_id == uaaf.id)
    |> where([uaal, uaaf], uaaf.id == ^uaa_file_id and uaal.status == ^"success")
    |> select([uaal, uaaf], uaal.code)
    |> Repo.all()
  end

  def deactivate_users(payroll_codes) do
    User
    |> where([u], u.payroll_code in ^payroll_codes)
    |> Repo.update_all(set: [status: "Active"])
    User
    |> where([u], u.payroll_code not in ^payroll_codes)
    |> Repo.update_all(set: [status: "Deactivated"])
  end

  def disable_users_after_cutoff do
    users =
      User
      |> join(:inner, [u], ur in UserRole, u.id == ur.user_id)
      |> join(:inner, [u, ur], r in Role, ur.role_id == r.id)
      |> join(:inner, [u, ur, r], rp in RolePermission, r.id == rp.role_id)
      |> join(:inner, [u, ur, r, rp], p in Permission, rp.permission_id == p.id)
      |> where([u, ur, r, rp, p], p.keyword == ^"manage_user_access")
      |> Repo.all()
      |> Repo.preload([roles: from(ro in Role, where: ro.create_full_access == ^"payorlink", limit: 1)])

    Enum.map(users, fn(user) ->
      role = List.first(user.roles)
      [min_day, max_day] = role.cut_off_dates
      three_days = max_day + 3

      {:ok, {year, month, today}} = Ecto.Date.dump(Ecto.Date.utc())

      cond do
        max_day == today and user.is_file_uploaded == false ->
          send_sms_n_email_notifs(user)
        user.is_file_uploaded == false and three_days <= today ->
          Repo.update(Ecto.Changeset.change user, status: "Deactivated")
        true ->
          nil
      end
    end)
  end

  def send_sms_n_email_notifs(user) do
    SMS.send(%{text: "Hi #{Enum.join([user.first_name, user.middle_name, user.last_name], " ")}, #{message()}", to: user.mobile})

    message()
    |> EmailSmtp.user_activation_notif(user)
    |> Mailer.deliver_now()
  end

  def message do
    {:ok, {year, month, today}} = Ecto.Date.dump(Ecto.Date.utc())
    "Please be reminded that uploading of your company's employee list is due on #{month_name(month)} #{today}, #{year}. Failure to upload will result to user's account deactivation."
  end

  def month_name(index) do
    Enum.at([
      "None",
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ], index)
  end

  def insert_or_update_common_password(params) do
    commonpassword =
      params.password
      |> get_common_password()

    if is_nil(commonpassword) do
      create_common_password(params)
    else
      commonpassword
      |> update_common_password(params)
    end
  end

  def get_common_password(password)do
    CommonPassword
    |> Repo.get_by(password: password)
  end

  def create_common_password(params)do
    %CommonPassword{}
    |> CommonPassword.changeset(params)
    |> Repo.insert()
  end

    def update_common_password(commonpass, params)do
    commonpass
    |> CommonPassword.changeset(params)
    |> Repo.update()
    end

   def validate_common_password(password)do
    CommonPassword
    |> Repo.get_by(:password, password)
  end

  def get_all_common_password do
    CommonPassword
    |> select([cp], cp.password)
    |> Repo.all()
  end

  def get_all_user_password(id) do
    UserPassword
    |> where([up], up.user_id == ^id)
    |> select([cp], cp.hashed_password)
    |> limit(32)
    |> Repo.all()
  end

  def insert_password_history(user, params) do
    {result, _} =
      %UserPassword{}
      |> UserPassword.changeset(%{
        user_id: user.id,
        password: params["password"]
      })
      |> Repo.insert()
    {result}
  end

  def generate_reset_token(user) do
    user
    |> Ecto.Changeset.change(%{reset_token: Ecto.UUID.generate()})
    |> Repo.update!()
  end

  def remove_reset_token(user) do
    user
    |> Ecto.Changeset.change(%{reset_token: nil})
    |> Repo.update!()
  end

  def is_pnum_or_email?(params) do
    cond do
      Regex.match?(~r/^[A-Za-z0-9._,-]+@[A-Za-z0-9._,-]+\.[A-Za-z]{2,4}$/, params) == true ->
          "email"
      Regex.match?(~r/^0[0-9]{10}$/, params) == true ->
          "mobile"
      true ->
        {:error}
    end
  end

  def insert_or_update_terms(param)

  def update_user_status(user, status) do
    user
    |> Ecto.Changeset.change(%{status: status})
    |> Repo.update!()
  end

  def get_users_by_company(company_id) do
    User
    |> where([u], u.company_id == ^company_id)
    |> select([u], %{
      id: u.id,
      username: u.username,
      title: u.username
    })
    |> Repo.all()
  end

  def check_user_by_payroll(payroll_code, company_id) do
    User
    |> where([u], ilike(u.payroll_code, ^payroll_code))
    |> where([u], u.company_id == ^company_id)
    |> select([u], u.id)
    |> limit(1)
    |> Repo.one()
  end

  def check_user_by_payroll(payroll_code, current_payroll_code, company_id) do
    User
    |> where([u], ilike(u.payroll_code, ^payroll_code))
    |> where([u], u.company_id == ^company_id)
    |> where([u], u.payroll_code != ^current_payroll_code)
    |> select([u], u.id)
    |> limit(1)
    |> Repo.one()
  end

  def update_user2(%User{} = user, attrs) do
    user
    |> User.changeset2(attrs)
    |> Repo.update()
  end

  def preload_facility(%User{} = user), do: user |> Repo.preload([:facility])
  def preload_user_roles(%User{} = user) do
    user
    |> Repo.preload([
      roles: [
        role_applications: :application
        ]
      ]
    )
  end

  def clear_user_reporting_to(user_id) do
    UserReportingTo
    |> where([ur], ur.user_id == ^user_id)
    |> Repo.delete_all()
  end

  def insert_reporting_to(user_id, lead_names) do
    lead_ids = lead_names |> get_ids_by_username() |> Enum.uniq()
    Enum.map(lead_ids, fn(lead_id) ->
      %UserReportingTo{}
      |> UserReportingTo.changeset(%{user_id: user_id, lead_id: lead_id})
      |> Repo.insert()
    end)
  end

  def get_ids_by_username(usernames) do
    User
    |> where([u], u.username in ^usernames)
    |> select([u], u.id)
    |> Repo.all()
  end

  def generate_temp_password(user) do
    temp_password = UtilityContext.randomizer(4)
    SMS.send(%{
      text: "Your temporary password is #{temp_password}",
      to: transforms_number2(user.mobile)
    })

    user
    |> User.password_changeset_temp(%{password: temp_password})
    |> Repo.update!()
    |> preload_facility()
    |> preload_user_roles()
  end

  defp transforms_number2(number) do
    number =
      number
      |> String.slice(1..11)
    "63#{number}"
  end

  # def validate_acu_schedule(acu_schedule_notification)do
  #   if acu_schedule_notification =
  # end

  def match_user_providerlink_api(user, role_id, action) do
    user_params = %{
      # User
      username: user.username,
      hashed_password: user.hashed_password,
      status: user.status,
      action: action,
      role_id: role_id,
      acu_schedule_notification: user.acu_schedule_notification,
      pin: "validated",

      # Agent
      first_name: user.first_name,
      middle_name: user.middle_name,
      last_name: user.last_name,
      extension: user.suffix,
      mobile: user.mobile,
      email: user.email,

      # Provider
      payorlink_facility_id: user.facility_id,
      name: user.facility.name,
      code: user.facility.code,
      phone_no: user.facility.phone_no,
      email_address: user.facility.email_address,
      line_1: user.facility.line_1,
      line_2: user.facility.line_2,
      city: user.facility.city,
      province: user.facility.province,
      region: user.facility.region,
      country: user.facility.country,
      postal_code: user.facility.postal_code,
      prescription_term: user.facility.prescription_term
    }

    with {:ok, token} <- providerlink_sign_in_v2(),
         {:ok, response} <- match_user_provider(user_params, token)
    do
      true
    else
      {:error, response} ->
        {:error, response}
      {:error_api_role} ->
        {:error, "Error creating providerlink role"}
      _ ->
        {:error, 500}
    end
  end

  defp match_user_provider(params, token) do
    api_address = ApiAddressContext.get_api_address_by_name("PROVIDERLINK_2")
    api_method = Enum.join([api_address.address, "/api/v1/user/match_user_payorlink"], "")
    headers = [{"Content-type", "application/json"}, {"authorization", "Bearer #{token}"}]
    body = Poison.encode!(params)

    with {:ok, response} <- HTTPoison.post(api_method, body, headers, []),
         200 <- response.status_code
    do
      {:ok, response}
    else
      {:error, response} ->
        {:error, response}
      _ ->
        {:error_api_user}
    end
  end

  def providerlink_sign_in_v2() do
    api_address = ApiAddressContext.get_api_address_by_name("PROVIDERLINK_2")
    providerlink_sign_in_url = "#{api_address.address}/api/v1/sign_in"
    headers = [{"Content-type", "application/json"}]
    body = Poison.encode!(%{"username": api_address.username, "password": api_address.password})

    with {:ok, response} <- HTTPoison.post(providerlink_sign_in_url, body, headers, []),
         200 <- response.status_code
    do
      decoded =
        response.body
        |> Poison.decode!()

      {:ok, decoded["token"]}
    else
      {:error, response} ->
        {:unable_to_login, response}
      _ ->
        {:unable_to_login, "Error occurs when attempting to login in Providerlink"}
    end
  end

  def get_default_user do
    User
    |> Repo.get_by(username: "masteradmin")
  end

end
