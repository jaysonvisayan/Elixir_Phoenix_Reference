defmodule Innerpeace.Db.Schemas.Procedure do
  @moduledoc false

  alias Innerpeace.Db.Base.Api.UtilityContext

  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only: [
    :procedure_id,
    :code,
    :type,
    :description,
    :id,
    :procedure_logs
  ]}

  @timestamps_opts [usec: false]
  schema "procedures" do
    field :code, :string
    field :type, :string
    field :description, :string

    belongs_to :coverage, Innerpeace.Db.Schemas.Coverage
    belongs_to :procedure_category, Innerpeace.Db.Schemas.ProcedureCategory
    has_many :benefit_procedures, Innerpeace.Db.Schemas.BenefitProcedure, on_delete: :delete_all
    has_many :product_risk_share_facility_procedure,
      Innerpeace.Db.Schemas.ProductRiskShareFacilityProcedure,
      on_delete: :delete_all
    has_many :exclusion_procedures, Innerpeace.Db.Schemas.ExclusionProcedure, on_delete: :delete_all
    has_many :procedure_logs, Innerpeace.Db.Schemas.ProcedureLog, on_delete: :delete_all
    #has_many :rider_procedures, Innerpeace.RiderProcedure, on_delete: :delete_all

    many_to_many :benefit, Innerpeace.Db.Schemas.Benefit, join_through: "benefit_procedure"
    many_to_many :exclusion, Innerpeace.Db.Schemas.Exclusion, join_through: "exclusion_procedure"

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:code, :description, :type, :procedure_category_id])
    |> validate_required([:code, :description])
  end

  def update_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:description])
    |> validate_required([:description])
    |> validate_first_character()
  end

  def validate_first_character(changeset), do: validate_first_character(Enum.empty?(changeset.changes), changeset)
  def validate_first_character(true, changeset), do: changeset
  def validate_first_character(false, changeset), do: validate_first_character("changeset.changes_not_empty", changeset)
  def validate_first_character("changeset.changes_not_empty", changeset) do
    with {:ok, _val} <- UtilityContext.restricting_symbols_return_val_only(String.at(changeset.changes.description, 0), ["-", "=", "+", "@"], changeset.changes.description)
    do
      changeset
    else
      {:error, val} ->
        add_error(changeset, :description, "- = @ + is not allowed at the beginning of Payor CPT Description")
    end
  end
end
