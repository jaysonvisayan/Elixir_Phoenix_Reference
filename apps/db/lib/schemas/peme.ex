defmodule Innerpeace.Db.Schemas.Peme do
  @moduledoc """
  """

  use Innerpeace.Db.Schema

  schema "pemes" do
    field :peme_id, :string
    field :type, :string
    field :status, :string
    field :request_date, Ecto.DateTime
    field :availment_date, Ecto.DateTime
    field :date_from, Ecto.Date
    field :date_to, Ecto.Date
    field :evoucher_number, :string
    field :evoucher_qrcode, :string
    field :registration_date, Ecto.DateTime
    field :cancel_reason, :string
    field :mobile_number, :string
    field :email_address, :string
    belongs_to :package, Innerpeace.Db.Schemas.Package
    belongs_to :facility, Innerpeace.Db.Schemas.Facility
    belongs_to :member, Innerpeace.Db.Schemas.Member
    belongs_to :account_group, Innerpeace.Db.Schemas.AccountGroup
    belongs_to :authorization, Innerpeace.Db.Schemas.Authorization
    belongs_to :created_by, Innerpeace.Db.Schemas.User, foreign_key: :created_by_id
    belongs_to :updated_by, Innerpeace.Db.Schemas.User, foreign_key: :updated_by_id
    has_many :peme_members, Innerpeace.Db.Schemas.PemeMember
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :peme_id,
      :type,
      :request_date,
      :availment_date,
      :date_from,
      :date_to,
      :package_id,
      :facility_id,
      :status,
      :member_id,
      :evoucher_number,
      :evoucher_qrcode,
      :account_group_id,
      :cancel_reason,
      :created_by_id,
      :updated_by_id,
      :mobile_number,
      :email_address
    ])
    |> validate_required([
      :date_from,
      :date_to,
      :package_id,
      :evoucher_number,
      :evoucher_qrcode,
      :account_group_id
    ])
  end

  def changeset_member(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :member_id
    ])
  end

  def changeset_facility(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :facility_id
    ])
  end

  def changeset_authorization(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :authorization_id
    ])
  end

  def status_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :status,
      :registration_date,
      :availment_date,
      :cancel_reason,
    ])
    |> validate_required([
      :status
    ])
  end

end
