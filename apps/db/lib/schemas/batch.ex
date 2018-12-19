defmodule Innerpeace.Db.Schemas.Batch do
  use Innerpeace.Db.Schema

  schema "batches" do
    field :batch_no, :string
    field :type, :string
    field :date_received, Ecto.Date
    field :date_due, Ecto.Date
    field :soa_ref_no, :string
    field :soa_amount, :string
    field :estimate_no_of_claims, :string
    field :mode_of_receiving, :string
    field :status, :string
    field :aso, :string
    field :fullrisk, :string
    field :funding_arrangement, :string
    field :coverage, :string
    field :edited_soa_amount, :string

    belongs_to :practitioner, Innerpeace.Db.Schemas.Practitioner
    belongs_to :facility, Innerpeace.Db.Schemas.Facility
    belongs_to :created_by, Innerpeace.Db.Schemas.User, foreign_key: :created_by_id
    belongs_to :updated_by, Innerpeace.Db.Schemas.User, foreign_key: :updated_by_id

    has_many :comments, Innerpeace.Db.Schemas.Comment, on_delete: :nothing
    has_many :batch_authorizations, Innerpeace.Db.Schemas.BatchAuthorization, on_delete: :delete_all
    has_many :batch_files, Innerpeace.Db.Schemas.BatchFile, on_delete: :delete_all

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
        :batch_no,
        :type,
        :date_received,
        :date_due,
        :soa_ref_no,
        :soa_amount,
        :estimate_no_of_claims,
        :mode_of_receiving,
        :status,
        :aso,
        :fullrisk,
        :funding_arrangement,
        :coverage,
        :facility_id,
        :created_by_id,
        :updated_by_id,
        :edited_soa_amount
      ])
      |> validate_required([
        :batch_no,
        :date_received,
        :date_due,
        :facility_id,
        :coverage,
        :soa_ref_no,
        :soa_amount,
        :estimate_no_of_claims,
        :mode_of_receiving
      ])
  end

  def changeset_pf(struct, params \\ %{}) do
    struct
    |> cast(params, [
        :batch_no,
        :type,
        :date_received,
        :date_due,
        :soa_ref_no,
        :soa_amount,
        :estimate_no_of_claims,
        :mode_of_receiving,
        :status,
        :aso,
        :fullrisk,
        :funding_arrangement,
        :facility_id,
        :practitioner_id,
        :coverage,
        :edited_soa_amount,
        :created_by_id,
        :updated_by_id
      ])
      |> validate_required([
        :batch_no,
        :date_received,
        :date_due,
        :facility_id,
        :practitioner_id,
        :coverage
      ])
  end

end
