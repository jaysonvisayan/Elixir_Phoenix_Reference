defmodule Innerpeace.Db.Schemas.LocationGroup do
  @moduledoc false
  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only: [
    :id,
    :name
  ]}

  schema "location_groups" do
    field :name, :string
    field :description, :string
    field :step, :string
    field :code, :string
    field :selecting_type, :string
    field :version, :string
    field :status, :string

    # Relationship
    belongs_to :created_by,
      Innerpeace.Db.Schemas.User, foreign_key: :created_by_id
    belongs_to :updated_by,
      Innerpeace.Db.Schemas.User, foreign_key: :updated_by_id
    has_many :location_group_region, Innerpeace.Db.Schemas.LocationGroupRegion
    has_many :facility_location_group, Innerpeace.Db.Schemas.FacilityLocationGroup

    # For Dental Plan
    has_many :product_coverage_location_groups, Innerpeace.Db.Schemas.ProductCoverageLocationGroup

    timestamps()
  end

  # def changeset(struct, params \\ %{}) do
  #   struct
  #   |> cast(params, [
  #     :name,
  #     :description,
  #     :step,
  #     :created_by_id,
  #     :updated_by_id
  #   ])
  #   |> validate_required([
  #     :name,
  #     :description,
  #     :step,
  #     :created_by_id,
  #     :updated_by_id
  #   ])
  # end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :name,
      :description,
      :step,
      :created_by_id,
      :updated_by_id,
      :selecting_type,
      :status
    ])
    |> unique_constraint(:name, message: "Location Group Name already exist!")
    |> validate_length(:name, min: 1, max: 80, message: "Must be allowed up to 80 alphanumeric characters.")
    |> validate_length(:description, min: 1, max: 80, message: "Must be allowed up to 80 alphanumeric characters.")
    |> validate_format(:name, ~r/^[A-Za-z0-9-:() ]*$/, message: "Only Hyphen (-), Colon (:), and Parentheses (()) are the special characters allowed")
    |> validate_format(:description, ~r/^[A-Za-z0-9-:() ]*$/, message: "Only Hyphen (-), Colon (:), and Parentheses (()) are the special characters allowed")
    |> validate_required([
      :name,
      # :created_by_id,
      # :updated_by_id,
    ], message: "Enter Facility  Group Name")
    |> validate_required([:description], message: "Enter Facility  Group Description")
    |> validate_required([:selecting_type], message: "Select selecting type")
    |> put_change(:code, random_pcode())
    |> put_change(:version, create_version())
  end

  def changeset_update(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :name,
      :description,
      :step,
      :created_by_id,
      :updated_by_id,
      :selecting_type,
      :status
    ])
    |> unique_constraint(:name, message: "Location Group Name already exist!")
    |> validate_length(:name, min: 1, max: 80, message: "Must be allowed up to 80 alphanumeric characters.")
    |> validate_length(:description, min: 1, max: 80, message: "Must be allowed up to 80 alphanumeric characters.")
    |> validate_format(:name, ~r/^[A-Za-z0-9-:() ]*$/, message: "Only Hyphen (-), Colon (:), and Parentheses (()) are the special characters allowed")
    |> validate_format(:description, ~r/^[A-Za-z0-9-:() ]*$/, message: "Only Hyphen (-), Colon (:), and Parentheses (()) are the special characters allowed")
    |> validate_required([
      :name,
      # :created_by_id,
      # :updated_by_id,
    ], message: "Enter Facility  Group Name")
    |> validate_required([:description], message: "Enter Facility  Group Description")
    |> validate_required([:selecting_type], message: "Select selecting type")
  end

  def create_version do
    "1.0"
  end

  def random_pcode do
    query = from p in Innerpeace.Db.Schemas.LocationGroup, select: p.code
    list_of_location_group = Repo.all query
    result_generated = generate_random()
    case check_if_exists(list_of_location_group, result_generated) do
      true  ->
        random_pcode()
      false ->
        result_generated
    end
  end

  def check_if_exists(list, generated) do
    Enum.member?(list, generated)
  end

  def generate_random do
    prefix = "FG-"
    random = Enum.random(100_000..999_999)
    concatresult = "#{prefix}#{random}"
  end

  def changeset_update_step2(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :step,
    ])
    |> validate_required([
      :step,
    ])
  end

  def changeset_update_step3(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :step,
    ])
    |> validate_required([
      :step,
    ])
  end
end
