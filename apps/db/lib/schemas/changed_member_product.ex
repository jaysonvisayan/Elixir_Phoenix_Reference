defmodule Innerpeace.Db.Schemas.ChangedMemberProduct do
    @moduledoc false

    use Innerpeace.Db.Schema

    schema "changed_member_products" do
      field :type, :string

      belongs_to :change_of_product_logs, Innerpeace.Db.Schemas.ChangeOfProductLog, foreign_key: :change_of_product_log_id
      belongs_to :product, Innerpeace.Db.Schemas.Product, foreign_key: :product_id

      timestamps()
    end

    def changeset(struct, params \\ %{}) do
        struct
        |> cast(params, [
            :type,
            :product_id,
            :change_of_product_log_id
        ])
        |> validate_required([
            :type,
            :product_id,
            :change_of_product_log_id
        ])
    end

  end
