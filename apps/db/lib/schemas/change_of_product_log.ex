defmodule Innerpeace.Db.Schemas.ChangeOfProductLog do
    @moduledoc false

    use Innerpeace.Db.Schema

    schema "change_of_product_logs" do
      field :change_of_product_effective_date, :date
      field :reason, :string

      has_many :changed_member_products, Innerpeace.Db.Schemas.ChangedMemberProduct, on_delete: :delete_all

      belongs_to :members, Innerpeace.Db.Schemas.Member, foreign_key: :member_id
      belongs_to :created_by, Innerpeace.Db.Schemas.User, foreign_key: :created_by_id

      timestamps()
    end

    def changeset(struct, params \\ %{}) do
        struct
        |> cast(params, [
            :change_of_product_effective_date,
            :reason,
            :member_id,
            :created_by_id
        ])
        |> validate_required([
            :change_of_product_effective_date,
            :reason,
            :member_id,
            :created_by_id
        ])
    end

  end
