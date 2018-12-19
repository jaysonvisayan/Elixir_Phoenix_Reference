defmodule Innerpeace.Db.Schemas.MemberUploadLog do
  use Innerpeace.Db.Schema

  schema "member_upload_logs" do
    field :filename, :string
    field :account_code, :string
    field :type, :string
    field :effectivity_date, :string
    field :expiry_date, :string
    field :first_name, :string
    field :middle_name, :string
    field :last_name, :string
    field :suffix, :string
    field :gender, :string
    field :civil_status, :string
    field :birthdate, :string
    field :employee_no, :string
    field :date_hired, :string
    field :regularization_date, :string
    field :for_card_issuance, :string
    field :email, :string
    field :mobile, :string
    field :city, :string
    field :address, :string
    field :relationship, :string
    field :product_code, :string
    field :status, :string
    field :remarks, :string
    field :tin_no, :string
    field :philhealth, :string
    field :philhealth_no, :string
    field :card_no, :string
    field :policy_no, :string
    #added_field
    field :upload_status, :string

    #Relationships
    belongs_to :created_by, Innerpeace.Db.Schemas.User, foreign_key: :created_by_id
    belongs_to :member_upload_file, Innerpeace.Db.Schemas.MemberUploadFile

    belongs_to :member, Innerpeace.Db.Schemas.Member

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :member_upload_file_id,
      :member_id,
      :filename,
      :account_code,
      :type,
      :effectivity_date,
      :expiry_date,
      :first_name,
      :middle_name,
      :last_name,
      :suffix,
      :gender,
      :civil_status,
      :birthdate,
      :employee_no,
      :date_hired,
      :regularization_date,
      :for_card_issuance,
      :email,
      :mobile,
      :city,
      :relationship,
      :product_code,
      :address,
      :status,
      :remarks,
      :created_by_id,
      :tin_no,
      :philhealth,
      :philhealth_no,
      :card_no,
      :policy_no,
      :upload_status
    ])
  end

end
