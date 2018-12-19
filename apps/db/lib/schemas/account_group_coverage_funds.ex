defmodule Innerpeace.Db.Schemas.AccountGroupCoverageFund do
  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only: [
    :id,
    :coverage,
    :replenish_threshold,
    :revolving_fund,
  ]}

  @timestamps_opts [usec: false]
  schema "account_group_coverage_funds" do
    field :revolving_fund, :decimal
    field :replenish_threshold, :decimal

    belongs_to :account_group, Innerpeace.Db.Schemas.AccountGroup
    belongs_to :coverage, Innerpeace.Db.Schemas.Coverage

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :revolving_fund,
      :replenish_threshold,
      :account_group_id,
      :coverage_id
    ])
    |> validate_required([
      :revolving_fund,
      :replenish_threshold,
      :account_group_id,
      :coverage_id
    ])
  end

end
