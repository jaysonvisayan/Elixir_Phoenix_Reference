defmodule Innerpeace.Db.Schemas.LocationGroupRegion do
  @moduledoc false
  use Innerpeace.Db.Schema

  schema "location_group_regions" do
    field :region_name, :string
    field :island_group, :string
    # Relationship
    belongs_to :location_group, Innerpeace.Db.Schemas.LocationGroup
    belongs_to :region, Innerpeace.Db.Schemas.Region
    belongs_to :created_by, Innerpeace.Db.Schemas.User, foreign_key: :created_by_id
    belongs_to :updated_by, Innerpeace.Db.Schemas.User, foreign_key: :updated_by_id
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      # :region_name,
      :location_group_id,
      :region_id,
      :created_by_id,
      :updated_by_id,
      # :island_group

    ])
    |> validate_required([
      :region_id,
      :location_group_id,
      :created_by_id,
      :updated_by_id
    ])
  end

  # def changeset_create(struct, params \\ %{}) do
  #   struct
  #   |> cast(params, [
  #     :region_name,
  #     :location_group_id,
  #     :created_by_id,
  #     :updated_by_id,
  #     :island_group

  #   ])
  #   |> validate_required([
  #     :region_id,
  #     :location_group_id,
  #     :created_by_id,
  #     :updated_by_id
  #   ])
  # end

end
