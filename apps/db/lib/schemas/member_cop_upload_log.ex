defmodule Innerpeace.Db.Schemas.MemberCOPUploadLog do
    @moduledoc """
        Schema File for Member Change of Product Upload Log
    """
    use Innerpeace.Db.Schema

    schema "member_cop_upload_logs" do
      field :change_of_product_effective_date, :string
      field :old_product_code, :string
      field :new_product_code, :string
      field :reason, :string
      field :status, :string
      field :upload_status, :string
      field :member_id

      #Relationships
      belongs_to :created_by, Innerpeace.Db.Schemas.User, foreign_key: :created_by_id
      belongs_to :member_upload_file, Innerpeace.Db.Schemas.MemberUploadFile

      timestamps()
    end

    def changeset(struct, params \\ %{}) do
      struct
      |> cast(params, [
        :member_upload_file_id,
        :member_id,
        :created_by_id,
        :change_of_product_effective_date,
        :old_product_code,
        :new_product_code,
        :reason,
        :status,
        :upload_status
      ])
    end

  end
