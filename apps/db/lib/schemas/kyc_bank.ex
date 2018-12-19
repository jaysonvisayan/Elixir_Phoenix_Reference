defmodule Innerpeace.Db.Schemas.KycBank do
  use Innerpeace.Db.Schema

  @timestamps_opts [usec: false]
  schema "kyc_banks" do
    field :country, :string
    field :city, :string
    field :citizenship, :string
    field :civil_status, :string
    field :mother_maiden, :string
    field :tin, :string
    field :sss_number, :string
    field :unified_id_number, :string
    field :educational_attainment, :string
    field :position_title, :string
    field :occupation, :string
    field :source_of_fund, :string
    field :others, :string
    field :company_name, :string
    field :company_branch, :string
    field :nature_of_work, :string
    field :mm_first_name, :string
    field :mm_middle_name, :string
    field :mm_last_name, :string
    field :country_of_birth, :string
    field :city_of_birth, :string
    field :street_no, :string
    field :subd_dist_town, :string
    field :residential_line, :string
    field :zip_code, :string
    field :id_card, :string  # identification card

    field :email1, :string
    field :email2, :string
    field :mobile1, :string
    field :mobile2, :string

    field :step, :integer

    belongs_to :member, Innerpeace.Db.Schemas.Member
    has_many :phone, Innerpeace.Db.Schemas.Phone
    has_many :email, Innerpeace.Db.Schemas.Email
    has_many :address, Innerpeace.Db.Schemas.Address
    has_many :file, Innerpeace.Db.Schemas.File
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :country,
      :city,
      :citizenship,
      :civil_status,
      :mother_maiden,
      :tin,
      :sss_number,
      :unified_id_number,
      :educational_attainment,
      :position_title,
      :occupation,
      :source_of_fund,
      :company_name,
      :nature_of_work,
      :member_id,
      :email1,
      :email2,
      :mobile1,
      :mobile2,
      :id_card,
      :mm_first_name,
      :mm_middle_name,
      :mm_last_name

    ])
    |> validate_length(:tin, min: 12, max: 12)
    |> validate_length(:sss_number, min: 12, max: 12)
    |> validate_length(:unified_id_number, min: 12, max: 12)
    |> validate_required([
      :country,
      :city,
      :citizenship,
      :civil_status,
      #:mother_maiden,
      # :tin,
      # :sss_number,
      # :unified_id_number,
      :educational_attainment,
      :position_title,
      :occupation,
      :source_of_fund,
      :company_name,
      :nature_of_work,
      :id_card,
      :mm_first_name,
      :mm_middle_name,
      :mm_last_name
    ])
  end


  def changeset_step1(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :country_of_birth,
      :city_of_birth,
      :citizenship,
      :civil_status,
      :tin,
      :sss_number,
      :unified_id_number,
      :educational_attainment,
      :position_title,
      :occupation,
      :source_of_fund,
      :company_name,
      :company_branch,
      :nature_of_work,
      :mm_first_name,
      :mm_middle_name,
      :mm_last_name,
      :others,
      :step,
      :member_id
    ])
    |> validate_required([
      :country_of_birth,
      :city_of_birth,
      :citizenship,
      :civil_status,
      :educational_attainment,
      :position_title,
      :occupation,
      :source_of_fund,
      :company_name,
      :nature_of_work,
      :mm_first_name,
      :mm_middle_name,
      :mm_last_name,
      :step,
      :member_id
    ])
  end

  def changeset_step2(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :street_no,
      :subd_dist_town,
      :country,
      :city,
      :zip_code,
      :residential_line,
      :email1,
      :email2,
      :mobile1,
      :mobile2,
      :step
    ])
    |> validate_required([
      :country,
      :street_no,
      :step
    ])
  end

  def changeset_step3(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :tin,
      :sss_number,
      :unified_id_number,
      :id_card,
      :step
    ])
    |> validate_required([
      # :tin,
      # :sss_number,
      # :unified_id_number,
      :id_card,
      :step
    ])
  end

  def changeset_summary_step(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :step
    ])
    |> validate_required([
      :step
    ])
  end

end
