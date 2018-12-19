defmodule Innerpeace.Db.Schemas.Product do
  @moduledoc false

  use Innerpeace.Db.Schema
  import Ecto.Query

  @derive {Poison.Encoder, only: [
    :id,
    :name,
    :step,
    :product_base,
    :limit_amount
  ]}

  schema "products" do

    # General
    field :name, :string
    field :code, :string
    field :description, :string
    field :limit_applicability, :string
    field :type, :string
    field :limit_type, :string
    field :limit_amount, :decimal
    field :phic_status, :string
    field :standard_product, :string
    field :product_category, :string
    field :member_type, {:array, :string}
    field :product_base, :string
    field :in_lieu_of_acu, :boolean, default: false

    # Conditions
    # ------------------------ Age Eligibility
    field :nem_principal, :integer
    field :nem_dependent, :integer

    field :mded_principal, :string
    field :mded_dependent, :string

    field :principal_min_age, :integer
    field :principal_min_type, :string
    field :principal_max_age, :integer
    field :principal_max_type, :string

    field :adult_dependent_min_age, :integer
    field :adult_dependent_min_type, :string
    field :adult_dependent_max_age, :integer
    field :adult_dependent_max_type, :string

    field :minor_dependent_min_age, :integer
    field :minor_dependent_min_type, :string
    field :minor_dependent_max_age, :integer
    field :minor_dependent_max_type, :string

    field :overage_dependent_min_age, :integer
    field :overage_dependent_min_type, :string
    field :overage_dependent_max_age, :integer
    field :overage_dependent_max_type, :string

    # ------------------------- Deductions
    # adnb = Annual Deduction - Network Benefits
    # adnnb = Annual Deduction - Non-Network Benefits
    field :adnb, :decimal
    field :adnnb, :decimal

    # opmnb = Out of Pocket Maximum - Network Benefits
    # opmnnb = Out of Pocket Maximum - Network Benefits
    field :opmnb, :decimal
    field :opmnnb, :decimal

    field :no_outright_denial, :boolean
    field :sop_principal, :string
    field :sop_dependent, :string

    field :loa_facilitated, :boolean
    field :reimbursement, :boolean

    # newly added fields related to Loa Condition
    field :no_days_valid, :integer
    field :is_medina, :boolean
    field :smp_limit, :decimal

    field :coverage_id, :string
    field :prsf_cov_id, :string
    field :rnb_cov_id, :string
    field :lt_cov_id, :string

    field :shared_limit_amount, :decimal
    field :hierarchy_waiver, :string

    field :step, :string
    field :include_all_facilities, :boolean

    field :peme_funding_arrangement, :string
    field :peme_fee_for_service, :boolean

    # newly added fields related to dental plan
    field :dental_funding_arrangement, :string
    field :loa_validity, :string
    field :loa_validity_type, :string
    field :special_handling_type, :string
    field :type_of_payment_type, :string

    #newly added fields for condition step (Dental Plan)
    field :mode_of_payment, :string
    field :availment_type, :string
    field :capitation_type, :string
    field :capitation_fee, :decimal

    belongs_to :created_by, Innerpeace.Db.Schemas.User, foreign_key: :created_by_id
    belongs_to :updated_by, Innerpeace.Db.Schemas.User, foreign_key: :updated_by_id

    belongs_to :payor, Innerpeace.Db.Schemas.Payor
    has_many :account_products, Innerpeace.Db.Schemas.AccountProduct, on_delete: :delete_all
    has_many :product_benefits, Innerpeace.Db.Schemas.ProductBenefit, on_delete: :delete_all
    has_many :product_risk_shares, Innerpeace.Db.Schemas.ProductRiskShare, on_delete: :delete_all
    has_many :product_coverages, Innerpeace.Db.Schemas.ProductCoverage, on_delete: :delete_all
    has_many :product_facilities, Innerpeace.Db.Schemas.ProductFacility, on_delete: :delete_all
    has_many :product_exclusions, Innerpeace.Db.Schemas.ProductExclusion, on_delete: :delete_all
    has_many :logs, Innerpeace.Db.Schemas.ProductLog, on_delete: :delete_all
    has_many :changed_member_product, Innerpeace.Db.Schemas.ChangedMemberProduct, on_delete: :delete_all
    has_many :product_condition_hierarchy_of_eligible_dependents,
    Innerpeace.Db.Schemas.ProductConditionHierarchyOfEligibleDependent,
    on_delete: :delete_all

    many_to_many :benefits, Innerpeace.Db.Schemas.Benefit, join_through: "product_benefits"
    many_to_many :accounts, Innerpeace.Db.Schemas.Account, join_through: "account_products"
    has_many :member_products, Innerpeace.Db.Schemas.MemberProduct, foreign_key: :product_code, references: :code
    timestamps()
  end

  def changeset_general(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :name,
      :description,
      :limit_applicability,
      :type,
      :limit_type,
      :limit_amount,
      :phic_status,
      :standard_product,
      :payor_id,
      :loa_facilitated,
      :created_by_id,
      :step,
      :product_category,
      :member_type,
      :product_base,
      :updated_by_id,
      :shared_limit_amount
    ])
    # |> unique_constraint(:name, message: "Product Name already exist!")
    |> validate_required([
      :name,
      :description,
      :limit_applicability,
      :type,
      :limit_type,
      :limit_amount,
      :phic_status,
      # :loa_facilitated,
      :standard_product,
      :payor_id,
      :created_by_id,
      :step,
      :member_type,
      :product_base
    ])
    |> put_change(:code, random_pcode())
  end

  def changeset_general_dental(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :name,
      :description,
      :standard_product,
      :limit_applicability,
      :type,
      :payor_id,
      :created_by_id,
      :step,
      :limit_amount,
      :updated_by_id,
      :product_category,
    ])
    |> unique_constraint(:code, name: :products_code_index, message: "Product Code already exist!")
    |> validate_required([
      :name,
      # :description,
      :standard_product,
      :limit_applicability,
      :created_by_id,
      :step,
      # :limit_amount,
      :product_category,
      :updated_by_id,
    ])
    |> put_change(:code, random_pcode())
  end

  def changeset_general_dental_edit(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :name,
      :description,
      :standard_product,
      :limit_applicability,
      :type,
      :payor_id,
      :created_by_id,
      :step,
      :limit_amount,
      :updated_by_id,
      :product_category
    ])
    |> unique_constraint(:code, name: :products_code_index, message: "Product Code already exist!")
    |> validate_required([
      :name,
      # :description,
      :type,
      :standard_product,
      :limit_applicability,
      :created_by_id,
      :step,
      # :limit_amount,
      :product_category,
      :updated_by_id,
      :limit_amount
    ])
  end

  def changeset_step1_draft(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :name,
      :description,
      :standard_product,
      :limit_applicability,
      :type,
      :payor_id,
      :created_by_id,
      :step,
      :limit_amount,
      :updated_by_id,
      :product_category
    ])
    |> unique_constraint(:code, name: :products_code_index, message: "Product Code already exist!")
    |> put_change(:code, random_pcode())
  end

  def changeset_general_peme(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :name,
      :description,
      # :limit_applicability,
      :type,
      # :limit_type,
      # :limit_amount,
      # :phic_status,
      :standard_product,
      :payor_id,
      :created_by_id,
      :step,
      :product_category,
      :member_type,
      :product_base,
      :updated_by_id,
      :in_lieu_of_acu
      # :shared_limit_amount
    ])
    # |> unique_constraint(:name, message: "Product Name already exist!")
    |> validate_required([
      :name,
      :description,
      # :limit_applicability,
      :type,
      # :limit_type,
      # :limit_amount,
      # :phic_status,
      :standard_product,
      :payor_id,
      :created_by_id,
      :step,
      :product_category,
      :member_type,
      # :product_base,
      :updated_by_id,
      :in_lieu_of_acu
      # :shared_limit_amount
    ])
    |> put_change(:code, random_pcode())
  end

  def changeset_api(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :code,
      :name,
      :description,
      :limit_applicability,
      :type,
      :limit_type,
      :limit_amount,
      :phic_status,
      :standard_product,
      :payor_id,
      :created_by_id,
      :step,
      :product_category,
      :member_type,
      :product_base,
      :updated_by_id,
      :shared_limit_amount
    ])
    # |> unique_constraint(:name, message: "Product Name already exist!")
    |> unique_constraint(:code, message: "Product Code already exist!")
    |> validate_required([
      :code,
      :name,
      :description,
      :limit_applicability,
      :type,
      :limit_type,
      :limit_amount,
      :phic_status,
      :standard_product,
      :payor_id,
      :created_by_id,
      :step,
      :member_type,
      :product_base
    ])
  end

  def changeset_general_edit(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :name,
      :description,
      :limit_applicability,
      :type,
      :limit_type,
      :limit_amount,
      :phic_status,
      :standard_product,
      :payor_id,
      :member_type,
      :product_base,
      :shared_limit_amount
    ])
    |> unique_constraint(:name, message: "Product Name already exist!")
    |> validate_required([
      :name,
      :description,
      :limit_applicability,
      :type,
      :limit_type,
      :limit_amount,
      :phic_status,
      :standard_product,
      :payor_id,
      :member_type,
      :product_base
    ])
  end

  def changeset_general_peme_edit(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :name,
      :description,
      # :limit_applicability,
      :type,
      # :limit_type,
      # :limit_amount,
      # :phic_status,
      :standard_product,
      :payor_id,
      :created_by_id,
      :step,
      :product_category,
      :member_type,
      # :product_base,
      :updated_by_id,
      :in_lieu_of_acu
      # :shared_limit_amount
    ])
    |> unique_constraint(:name, message: "Product Name already exist!")
    |> validate_required([
      :name,
      :description,
      # :limit_applicability,
      :type,
      # :limit_type,
      # :limit_amount,
      # :phic_status,
      :standard_product,
      :payor_id,
      :created_by_id,
      :step,
      :product_category,
      :member_type,
      # :product_base,
      :updated_by_id,
      :in_lieu_of_acu
      # :shared_limit_amount
    ])
    |> put_change(:code, random_pcode())
  end

  def random_pcode do
    query = from p in Innerpeace.Db.Schemas.Product, select: p.code
    list_of_products = Repo.all query
    result_generated = generate_random()
    case check_if_exists(list_of_products, result_generated) do
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
    prefix = "PRD-"
    random = Enum.random(100_000..999_999)
    concatresult = "#{prefix}#{random}"
  end

  def changeset_condition(struct, params \\ %{}) do
    struct
    |> cast(params, [
      # Age Eligibility
      :nem_principal,
      :nem_dependent,
      :mded_principal,
      :mded_dependent,
      :principal_min_age,
      :principal_min_type,
      :principal_max_age,
      :principal_max_type,
      :adult_dependent_min_age,
      :adult_dependent_min_type,
      :adult_dependent_max_age,
      :adult_dependent_max_type,
      :minor_dependent_min_age,
      :minor_dependent_min_type,
      :minor_dependent_max_age,
      :minor_dependent_max_type,
      :overage_dependent_min_age,
      :overage_dependent_min_type,
      :overage_dependent_max_age,
      :overage_dependent_max_type,
      # Deductions
      :adnb,
      :adnnb,
      :opmnb,
      :opmnnb,
      :hierarchy_waiver,
      :sop_principal,
      :sop_dependent,
      :no_outright_denial,
      :no_days_valid,
      :is_medina,
      :smp_limit,
      :loa_facilitated,
      :reimbursement,
      :peme_funding_arrangement,
      :peme_fee_for_service,
      :dental_funding_arrangement,
      :loa_validity,
      :loa_validity_type,
      :special_handling_type,
      :type_of_payment_type,
      :mode_of_payment,
      :availment_type,
      :capitation_type,
      :capitation_fee
    ])
    |> validate_required([
      # Age Eligibility
      #:principal_min_age,
      #:principal_min_type,
      #:principal_max_age,
      #:principal_max_type,
      # :loa_facilitated, ## need to comment for step 3 back button
      # :adult_dependent_min_age, ## need to comment this field because dental step3, limit_applicability Principal Only, required this param, return error catcher..
      # :adult_dependent_min_type, ## this field is now not existing in our new HTML Design 06202018
      # :adult_dependent_max_age,
      # :adult_dependent_max_type, ## this field is now not existing in our new HTML Design 06202018
      # :minor_dependent_min_age,
      # :minor_dependent_min_type, ## this field is now not existing in our new HTML Design 06202018
      # :minor_dependent_max_age,
      # :minor_dependent_max_type, ## this field is now not existing in our new HTML Design 06202018
      # :overage_dependent_min_age,
      # :overage_dependent_min_type, ## this field is now not existing in our new HTML Design 06202018
      # :overage_dependent_max_age,
      # :overage_dependent_max_type ## this field is now not existing in our new HTML Design 06202018
      # :hierarchy_waiver,
      # :no_days_valid,
      # :is_medina
    ])
    # |> validate_inclusion(:no_days_valid, 1..100, message: "should be 1 - 100 value")
  end

  def changeset_condition_for_nil(struct, params \\ %{}) do
    struct
    |> cast(params, [
      # Age Eligibility
      :nem_principal,
      :principal_min_age,
      :principal_min_type,
      :principal_max_age,
      :principal_max_type,
      :mded_principal
    ])
  end

  def changeset_step(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :step,
      :updated_by_id
    ])
    |> validate_required([
      :step,
      :updated_by_id
    ])
  end

  def changeset_facilities_included(struct, params \\ %{}) do
    struct
    |> cast(params, [:include_all_facilities])
    |> validate_required([:include_all_facilities])
  end

  def changeset_update_coverage(struct, params \\ %{}) do
    struct
    |> cast(params, [:coverage_id])
    |> validate_required([:coverage_id])
  end

  def changeset_update_prsf_coverage(struct, params \\ %{}) do
    struct
    |> cast(params, [:prsf_cov_id])
    |> validate_required([:prsf_cov_id])
  end

  def changeset_update_rnb_coverage(struct, params \\ %{}) do
    struct
    |> cast(params, [:rnb_cov_id])
    |> validate_required([:rnb_cov_id])
  end

  def changeset_update_product_limit(struct, params \\ %{}) do
    struct
    |> cast(params, [:limit_amount])
    |> validate_required([:limit_amount])
  end

  def changeset_update_lt_coverage(struct, params \\ %{}) do
    struct
    |> cast(params, [:lt_cov_id])
    |> validate_required([:lt_cov_id])
  end

  def changeset_update_sop(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :sop_dependent,
      :sop_principal])
  end

  def changeset_dental_api(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :code,
      :name,
      :description,
      :limit_amount,
      :standard_product,
      :payor_id,
      :created_by_id,
      :step,
      :product_category,
      :member_type,
      :product_base,
      :updated_by_id,
      :dental_funding_arrangement,
      :mode_of_payment,
      :availment_type,
      :capitation_type,
      :capitation_fee,
      :type_of_payment_type,
      :loa_validity_type,
      :loa_validity,
      :special_handling_type,
      :limit_applicability
    ])
    # |> unique_constraint(:name, message: "Product Name already exist!")
    |> unique_constraint(:code, name: :products_code_index, message: "Product Code already exist!")
    |> validate_required([
      :code,
      :name,
      # :description,
      # :limit_amount,
      :standard_product,
      :payor_id,
      :created_by_id,
      :step,
      :product_category,
      :member_type,
      :product_base,
      :updated_by_id,
      :dental_funding_arrangement,
      :mode_of_payment,
      :type_of_payment_type,
      :loa_validity_type,
      :loa_validity,
      :special_handling_type,
      :limit_applicability
    ])
    # |> put_change(:code, random_pcode())
  end
end
