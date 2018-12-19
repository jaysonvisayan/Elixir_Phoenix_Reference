defmodule Innerpeace.Db.Schemas.CaseRate do
  @moduledoc false

  use Innerpeace.Db.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @derive {Poison.Encoder,
    only: [
      :id,
      :type,
      :hierarchy,
      :description,
      :discount_percentage,
      :diagnosis_ruv_id,
      :hierarchy1,
      :hierarchy2,
      :discount_percentage1,
      :discount_percentage2,
      :amount_up_to
    ]}

  @timestamps_opts [usec: false]
  schema "case_rates" do
    field :type, :string
    field :description, :string
    field :hierarchy, :integer
    field :discount_percentage, :integer
    field :hierarchy1, :integer
    field :discount_percentage1, :integer
    field :hierarchy2, :integer
    field :discount_percentage2, :integer
    field :amount_up_to, :decimal

    field :created_by_id, :binary_id
    field :updated_by_id, :binary_id

    has_many :case_rate_log, Innerpeace.Db.Schemas.CaseRateLog, on_delete: :delete_all
    belongs_to :diagnosis, Innerpeace.Db.Schemas.Diagnosis
    belongs_to :ruv, Innerpeace.Db.Schemas.RUV

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params,
            [
              :type,
              :description,
              :hierarchy,
              :hierarchy1,
              :hierarchy2,
              :discount_percentage,
              :discount_percentage1,
              :discount_percentage2,
              :created_by_id,
              :updated_by_id,
              :diagnosis_id,
              :ruv_id,
              :amount_up_to
            ])
            |> validate_required([:type, :description])
  end

end
