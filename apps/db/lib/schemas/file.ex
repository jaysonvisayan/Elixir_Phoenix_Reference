defmodule Innerpeace.Db.Schemas.File do
  use Innerpeace.Db.Schema
  use Arc.Ecto.Schema
  schema "files" do
    field :name, :string
    field :type, Innerpeace.FileUploader.Type
    #for Memberlink
    field :link, :string
    field :link_type, Innerpeace.FileUploader.Type
    field :image_type, Innerpeace.ImageUploader.Type
    belongs_to :kyc_bank, Innerpeace.Db.Schemas.KycBank
    belongs_to :authorization, Innerpeace.Db.Schemas.Authorization
    belongs_to :member, Innerpeace.Db.Schemas.Member
    #end
    has_many :card_files, Innerpeace.Db.Schemas.CardFile
    has_many :batch_authorization_files, Innerpeace.Db.Schemas.BatchAuthorizationFile, on_delete: :delete_all
    has_many :batch_files, Innerpeace.Db.Schemas.BatchFile, on_delete: :delete_all
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params,[:name])
  end

  def changeset_file(struct, params \\ %{}) do
    struct
    |> cast_attachments(params, [:type])
  end

  def changeset_kyc_upload(struct, params \\ %{}) do
    struct
    |> cast(params,[:link, :name, :kyc_bank_id])
    |> validate_required([:link, :name, :kyc_bank_id])
  end

  def changeset_kyc_fields(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :kyc_bank_id])
    |> validate_required([:name, :kyc_bank_id])
  end

  def changeset_kyc_upload_file(struct, params \\ %{}) do
    struct
    |> cast_attachments(params, [:type])
  end

  def changeset_kyc_upload_image(struct, params \\ %{}) do
    struct
    |> cast_attachments(params, [:image_type])
  end

  def changeset_authorization_upload(struct, params \\ %{}) do
    struct
    |> cast(params,[:link, :authorization_id])
    |> validate_required([:link, :authorization_id])
  end

  def changeset_profile_upload(struct, params \\ %{}) do
    struct
    |> cast(params, [:link, :member_id])
    |> validate_required([:link, :member_id])
  end

  def changeset_kyc_file(struct, params \\ %{}) do
    struct
    |> cast_attachments(params, [:link_type])
  end

  def changeset_kyc_image(struct, params \\ %{}) do
    struct
    |> cast_attachments(params, [:image_type])
  end

  def changeset_authorization_file(struct, params \\ %{}) do
    struct
    |> cast_attachments(params, [:link_type])
  end

  def changeset_authorization_image(struct, params \\ %{}) do
    struct
    |> cast_attachments(params, [:image_type])
  end

  def changeset_profile_file(struct, params \\ %{}) do
    struct
    |> cast_attachments(params, [:link_type])
  end

  def changeset_profile_image(struct, params \\ %{}) do
    struct
    |> cast_attachments(params, [:image_type])
  end

  def changeset_batch_authorization_file(struct, params \\ %{}) do
    struct
    |> cast_attachments(params, [:link_type])
  end

  def changeset_profile_id(struct, params \\ %{}) do
    struct
    |> cast(params,[:link, :name, :member_id])
    |> validate_required([:link, :name, :member_id])
  end
end
