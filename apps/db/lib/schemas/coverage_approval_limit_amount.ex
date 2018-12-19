defmodule Innerpeace.Db.Schemas.CoverageApprovalLimitAmount do
  use Innerpeace.Db.Schema

  @timestamps_opts [usec: false]
  schema "coverage_approval_limit_amounts" do
    field :approval_limit_amount, :decimal
    belongs_to :coverage, Innerpeace.Db.Schemas.Coverage
    belongs_to :role, Innerpeace.Db.Schemas.Role

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:role_id, :coverage_id, :approval_limit_amount])
  end

end
