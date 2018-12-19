defmodule Innerpeace.Db.Schemas.LoginIpAddress do
  use Innerpeace.Db.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [usec: false]
  schema "login_ip_addresses" do
    field :ip_address, :string
    field :attempts, :integer
    field :verify_attempts, :integer, default: 0

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :ip_address,
      :attempts
    ])
    |> validate_required([
      :ip_address,
      :attempts
    ])
  end

  def changeset_verify(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :ip_address,
      :verify_attempts
    ])
    |> validate_required([
      :ip_address,
      :verify_attempts
    ])
  end
end
