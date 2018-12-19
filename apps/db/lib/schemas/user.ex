defmodule Innerpeace.Db.Schemas.User do
  @moduledoc false

  use Innerpeace.Db.Schema

  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]
  alias Ecto.Changeset

  @derive {Poison.Encoder, only: [
    :first_name,
    :last_name,
    :middle_name,
    :mobile,
    :username,
    :email
  ]}

  @timestamps_opts [usec: false]
  schema "users" do
    field :username, :string
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true
    field :old_password, :string, virtual: true
    field :hashed_password, :string
    field :email, :string
    field :email_confirmation, :string, virtual: true
    field :mobile, :string
    field :mobile_confirmation, :string, virtual: true
    field :first_name, :string
    field :last_name, :string
    field :middle_name, :string
    field :birthday, Ecto.Date
    field :title, :string
    field :suffix, :string
    field :gender, :string
    field :notify_through, :string
    # field :profile_image, Innerpeace.ImageUploader.Type
    field :status, :string
    field :reset_token, :string
    field :password_token, :string
    field :step, :integer
    field :is_admin, :boolean, default: false
    field :verification_code, :string
    field :payroll_code, :string
    field :first_time, :boolean
    field :temporary_password, :string

    # field :approval_limit, :integer
    # membelink
    field :verification, :boolean
    field :verification_expiry, Ecto.DateTime
    field :attempts, :integer
    field :recovery, :string, virtual: true
    field :text, :string, virtual: true
    field :other_mobile, :string
    field :is_file_uploaded, :boolean, default: false
    field :acu_schedule_notification, :boolean, default: false
    # end memberlink

    # has_one :member, Innerpeace.Member, on_delete: :delete_all
    has_many :user_roles, Innerpeace.Db.Schemas.UserRole, on_delete: :delete_all
    many_to_many :roles, Innerpeace.Db.Schemas.Role, join_through: "user_roles"
    #has_many :agents, Innerpeace.Db.Schemas.Agent, on_delete: :delete_all
    # has_many :notifications, Innerpeace.Notification
    has_many :account_comment, Innerpeace.Db.Schemas.AccountComment, on_delete: :delete_all
    belongs_to :created_by, Innerpeace.Db.Schemas.User, foreign_key: :created_by_id
    belongs_to :updated_by, Innerpeace.Db.Schemas.User, foreign_key: :updated_by_id
    belongs_to :member, Innerpeace.Db.Schemas.Member
    belongs_to :company, Innerpeace.Db.Schemas.Company
    has_one :user_account, Innerpeace.Db.Schemas.UserAccount
    has_many :reporting_to, Innerpeace.Db.Schemas.UserReportingTo

    # For ProviderLink User
    belongs_to :facility, Innerpeace.Db.Schemas.Facility

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :username,
      :email,
      :mobile,
      :first_name,
      :last_name,
      :middle_name,
      #:birthday,
      #:title,
      :suffix,
      :gender,
      #:status,
      #:notify_through,
      :is_admin,
      :created_by_id,
      :step,
      :updated_by_id,
      :verification_code,
      :verification,
      :member_id,
      :first_time,
      :payroll_code
    ])
    |> validate_required([
      :username,
      :email,
      :first_name,
      :last_name,
      #:birthday,
      #:title,
      :gender,
      #:status,
      #:notify_through,
      :is_admin
    ], message: "is a required field!")
    |> put_change(:password_token, Ecto.UUID.generate())
    |> unique_constraint(:username, message: "Username is already being used by another user!")
    |> unique_constraint(:email, message: "Email is already being used by another user!")
    |> unique_constraint(:mobile, message: "Mobile Number is already being used by another user!")
    |> validate_mobile(:mobile)
    |> validate_format(:email, ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
    |> validate_email(:email)
    |> validate_length(:username, min: 5, max: 50)
    |> validate_length(:first_name, min: 2, max: 50)
    |> validate_length(:last_name, min: 2, max: 50)
    |> validate_length(:email, max: 50)
  end

  def changeset2(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :temporary_password,
      :username,
      :email,
      :mobile,
      :first_name,
      :last_name,
      :middle_name,
      :suffix,
      :gender,
      :is_admin,
      :created_by_id,
      :step,
      :updated_by_id,
      :verification_code,
      :verification,
      :member_id,
      :payroll_code,
      :company_id,
      :status,
      :acu_schedule_notification,
      :facility_id
    ])
    |> validate_required([
      :username,
      :email,
      :first_name,
      :last_name,
      :gender,
      :is_admin
    ], message: "is a required field!")
    |> put_change(:password_token, Ecto.UUID.generate())
    |> unique_constraint(:username, message: "Username is already being used by another user!")
    |> unique_constraint(:email, message: "Email is already being used by another user!")
    |> unique_constraint(:mobile, message: "Mobile Number is already being used by another user!")
  end

  def admin_changeset(user, attrs \\ %{}) do
    user
    |> cast(attrs, [
      :username,
      :password,
      :is_admin,
      :verification_code,
      :email,
      :mobile,
      :first_name,
      :middle_name,
      :last_name,
      :gender,
      :verification_expiry,
      :first_time,
      :payroll_code
      ])

    |> validate_required([:username, :password, :is_admin])
    |> hash_password()
  end

  def register_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:username, :password])
    |> validate_required([:username, :password])
    |> hash_password()
  end

  def password_changeset(user, attrs \\ %{}) do
    user
    |> cast(attrs, [:password, :password_confirmation, :first_time])
    |> validate_required([:password, :password_confirmation])
    |> validate_format(:password, ~r/^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^&*-]).{8,20}$/)
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_length(:password, min: 8, max: 128)
    |> put_change(:reset_token, Ecto.UUID.generate())
    |> put_change(:password_token, nil)
    |> hash_password()
  end

  def password_changeset_temp(user, attrs \\ %{}) do
    user
    |> cast(attrs, [:password])
    |> put_change(:password_token, nil)
    |> hash_password()
  end

  def plain_password_changeset(user, attrs \\ %{}) do
    user
    |> cast(attrs, [:password, :password_confirmation])
    |> validate_required([:password, :password_confirmation])
    |> put_change(:reset_token, Ecto.UUID.generate())
    |> put_change(:password_token, nil)
    |> hash_password()
  end

  defp hash_password(%{valid?: false} = changeset), do: changeset
  defp hash_password(%{valid?: true} = changeset) do
    hashedpw = Comeonin.Bcrypt.hashpwsalt(Ecto.Changeset.get_field(changeset, :password))
    Ecto.Changeset.put_change(changeset, :hashed_password, hashedpw)
  end

  def validate_mobile(changeset, field) do
    mobile = get_field(changeset, field)
    if mobile != nil && String.length(mobile) != 11 do
      add_error(changeset, field, "must be 11 digits")
    else
      changeset
    end
  end

  # def validate_mobile_accountlink(changeset, field) do
  #   mobile = get_field(changeset, field)
  #   if mobile != nil && String.length(mobile) != 10 do
  #     add_error(changeset, field, "must be 10 digits")
  #   else
  #     changeset
  #   end
  # end

  def validate_email(changeset, field) do
    email = get_field(changeset, field)
    if email != nil && String.contains?(email, ["..", "@."]) do
      add_error(changeset, field, "has invalid format!")
    else
      changeset
    end
  end

  # Start of MemberLink
  def username_changeset(user, attrs \\ %{}) do
    user
    |> cast(attrs, [:username])
    |> validate_required([:username])
    |> unique_constraint(:username)
  end

  def verification_changeset(user, attrs \\ %{}) do
    user
    |> cast(attrs, [:verification])
    |> validate_required([:verification])
  end

  def status_changeset(user, attrs \\ %{}) do
    user
    |> cast(attrs, [:status])
    |> validate_required([:status])
  end

  def verification_code_changeset(user, attrs \\ %{}) do
    user
    |> cast(attrs, [:verification_code])
  end

  def attempts_changeset(user, attrs \\ %{}) do
    user
    |> cast(attrs, [:attempts])
    |> validate_required([:attempts])
  end

  def expiry_changeset(user, attrs \\ %{}) do
    user
    |> cast(attrs, [:verification_expiry])
    |> validate_required([:verification_expiry])
  end

  def changeset_member(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :member_id,
      :username,
      :email,
      :mobile,
      :first_name,
      :last_name,
      :middle_name,
      :suffix,
      :birthday,
      :gender,
      :verification_code,
      :verification,
      :created_by_id,
      :updated_by_id,
      :other_mobile
    ])
    |> validate_required([
      :member_id,
      :username
      # :email
    ])
    |> unique_constraint(:username, message: "Username is already being used by another user!")
    |> unique_constraint(:email, message: "Email is already being used by another user!")
    |> unique_constraint(:mobile, message: "Mobile Number is already being used by another user!")
    |> validate_mobile(:mobile)
    |> validate_format(:email, ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
    # |> validate_email(:email
    |> validate_length(:username, min: 5, max: 50)
    |> validate_length(:email, max: 50)
    |> put_change(:password_token, Ecto.UUID.generate())
    |> put_change(:verification, false)
  end

  def changeset_member_api(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :member_id,
      :username,
      :email,
      :mobile,
      :first_name,
      :last_name,
      :middle_name,
      :suffix,
      :birthday,
      :gender,
      :created_by_id,
      :updated_by_id,
      :other_mobile
    ])
    |> validate_required([
      :member_id,
      :username,
      # :email
    ])
    |> put_change(:password_token, Ecto.UUID.generate())
    |> put_change(:verification, true)
  end

  def changeset_member_seed(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :member_id,
      :username,
      :email,
      :mobile,
      :first_name,
      :last_name,
      :middle_name,
      :suffix,
      :birthday,
      :gender,
      :verification_code,
      :verification,
      :created_by_id,
      :updated_by_id
    ])
    |> validate_required([
      :member_id,
      :username,
      # :email,
      # :mobile
    ])
    |> unique_constraint(:username, message: "Username is already being used by another user!")
    |> unique_constraint(:email, message: "Email is already being used by another user!")
    |> unique_constraint(:mobile, message: "Mobile Number is already being used by another user!")
    |> validate_mobile(:mobile)
    |> validate_format(:email, ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
    |> validate_email(:email)
    |> validate_length(:username, min: 5, max: 50)
    |> validate_length(:email, max: 50)
    |> put_change(:password_token, Ecto.UUID.generate())
    |> put_change(:verification, true)
  end
  def changeset_forgot_password(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :recovery,
      :username,
      :text
    ])
    |> validate_required([
      :recovery,
      :username,
      :text
    ])
  end

  def changeset_forgot_username(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :recovery,
      :text
    ])
    |> validate_required([
      :recovery,
      :text
    ])
  end

  def update_account_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [
      :id,
      :username,
      :password,
      :password_confirmation,
      :old_password
    ])
    |> validate_required([
      :id,
      :username,
      :password,
      :password_confirmation,
      :old_password
    ])
    |> validate_format(
      :password,
      ~r/(?=.*\d)(?=.*[a-z])(?=.*[A-Z]).{8,}/,
      message: "Password must be at least 8 characters and should contain alpha-numeric, special-character, atleast 1 capital letter"
    )
    |> validate_confirmation(
      :password,
      message: "Password doesn't match"
    )
    |> validate_old_password(struct)
    |> hash_password()
  end

  def validate_old_pass_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [
      :old_password
    ])
    |> validate_required([
      :old_password
    ])
    |> validate_old_password(struct)
  end

  def contact_details_changeset(struct, params \\ %{})  do
    struct
    |> cast(params, [
      :email,
      :mobile,
      :email_confirmation,
      :mobile_confirmation
    ])
    # |> validate_required([
      # :email,
      # :mobile,
      # :email_confirmation,
      # :mobile_confirmation],
      # message: "This is a required field")
    |> unique_constraint(
      :email,
      message: "Email is already being used by another user!")
    |> unique_constraint(
      :mobile,
      message: "Mobile Number is already being used by another user!")
    |> validate_mobile(:mobile)
    |> validate_format(
      :mobile,
      ~r/^0[0-9]{10}$/,
      message: "The Mobile number you have entered is invalid")
    |> validate_format(
      :email,
      ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/,
      message: "The email you have entered is invalid")
    |> validate_email(:email)
    |> validate_length(:email, max: 50)
    |> validate_confirmation(
      :mobile,
      message: "Mobile number doesn't match"
    )
    |> validate_confirmation(
      :email,
      message: "Email address doesn't match"
    )
  end

  def attempts_reset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [
      :attempts
    ])
  end
  # End of MemberLink

  # Start of AccountLink
  def account_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :username,
      :email,
      :mobile,
      :first_name,
      :last_name,
      :gender,
      :middle_name,
      :verification,
      :verification_code,
      :created_by_id,
      :updated_by_id
    ])
    |> validate_required([
      :username,
      :first_name,
      :last_name,
      :gender
      # :email,
      # :mobile
    ])
    |> unique_constraint(:username, message: "Username is already being used by another user!")
    |> unique_constraint(:email, message: "Email is already being used by another user!")
    |> unique_constraint(:mobile, message: "Mobile Number is already being used by another user!")
    |> validate_mobile(:mobile)
    |> validate_format(:email, ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
    |> validate_email(:email)
    |> validate_length(:username, min: 8, max: 24)
    |> validate_length(:email, max: 50)
    |> put_change(:password_token, Ecto.UUID.generate())
    |> put_change(:verification, false)
  end
  # End of AccountLink

  defp validate_old_password(changeset, user) do
    old_password =
      changeset
      |> Changeset.get_change(:old_password)

    if is_nil(old_password) do
      dummy_checkpw
      changeset
    else
      cond do
        user && checkpw(old_password, user.hashed_password) ->
          changeset
        user ->
          changeset
          |> Changeset.add_error(
            :old_password,
            "Invalid password",
            additional: :invalid_password)
        true ->
          dummy_checkpw
          changeset
      end
    end
  end
end
