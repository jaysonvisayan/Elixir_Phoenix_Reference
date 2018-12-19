defmodule Innerpeace.Db.Schemas.Role do
  use Innerpeace.Db.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @derive {Poison.Encoder, only: [:name]}

  @timestamps_opts [usec: false]
  schema "roles" do
    field :name, :string
    field :description, :string
    field :status, :string
    field :step, :integer
    field :approval_limit, :decimal
    #added fields
    field :pii, :boolean, default: false
    field :create_full_access, :string
    field :no_of_days, :integer
    field :cut_off_dates, {:array, :integer}
    field :member_permitted, :boolean, default: false

    belongs_to :created_by, Innerpeace.Db.Schemas.User, foreign_key: :created_by_id
    belongs_to :updated_by, Innerpeace.Db.Schemas.User, foreign_key: :updated_by_id
    has_many :role_permissions, Innerpeace.Db.Schemas.RolePermission, on_delete: :delete_all
    has_many :user_roles, Innerpeace.Db.Schemas.UserRole, on_delete: :delete_all
    many_to_many :users, Innerpeace.Db.Schemas.User, join_through: "user_roles"
    many_to_many :permissions, Innerpeace.Db.Schemas.Permission, join_through: "role_permissions"
    has_many :role_applications, Innerpeace.Db.Schemas.RoleApplication, on_delete: :delete_all
    many_to_many :applications, Innerpeace.Db.Schemas.Application, join_through: "role_applications"
    has_many :coverage_approval_limit_amounts, Innerpeace.Db.Schemas.CoverageApprovalLimitAmount

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :description, :status, :created_by_id, :updated_by_id, :step, :approval_limit])
    |> validate_required([:name])
    |> unique_constraint(:name, name: :roles_name_index, message: "Name already exists!")
  end

  def changeset_role(struct, params \\ %{}) do
    struct
    |> cast(params,
      [:name,
       :description,
       :status,
       :created_by_id,
       :updated_by_id,
       :pii,
       :create_full_access,
       :no_of_days,
       :cut_off_dates,
       :member_permitted
      ])
    |> validate_required([:name])
    |> unique_constraint(:name, name: :roles_name_index, message: "Name already exists!")
  end
end
