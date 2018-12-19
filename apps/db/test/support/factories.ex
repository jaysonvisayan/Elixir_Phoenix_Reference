defmodule Innerpeace.Db.Factories do
  @moduledoc """
  """

  use ExMachina.Ecto, repo: Innerpeace.Db.Repo
  alias Innerpeace.Db.Schemas.{
    Account, Sequence,
    AccountGroupAddress,
    AccountGroup,
    AccountGroupApproval,
    Authorization,
    AuthorizationAmount,
    User,
    RolePermission,
    Role,
    Permission,
    Application,
    Payor,
    Benefit,
    Coverage,
    Procedure,
    Industry,
    PaymentAccount,
    Contact,
    AccountGroupContact,
    Phone,
    Email,
    UserRole,
    Bank,
    Organization,
    Diagnosis,
    BenefitCoverage,
    BenefitProcedure,
    BenefitDiagnosis,
    BenefitLimit,
    Facility,
    FacilityPayorProcedure,
    ProductFacility,
    Exclusion,
    ExclusionDisease,
    ExclusionProcedure,
    AccountProduct,
    Product,
    ProductBenefit,
    AccountProductBenefit,
    Cluster,
    AccountGroupCluster,
    ProcedureCategory,
    PayorProcedure,
    Product,
    ProductBenefit,
    ProductBenefitLimit,
    ProductExclusion,
    Practitioner,
    Room,
    AccountComment,
    FacilityRoomRate,
    Member,
    Dropdown,
    FacilityContact,
    Specialization,
    PractitionerSpecialization,
    PractitionerContact,
    BankBranch,
    FulfillmentCard,
    AccountGroupFulfillment,
    Package,
    PackagePayorProcedure,
    PractitionerAccount,
    PractitionerAccountContact,
    PractitionerSchedule,
    PractitionerFacility,
    Authorization,
    DiagnosisCoverage,
    MemberProduct,
    ProductCoverage,
    PackageFacility,
    PractitionerFacilityPractitionerType,
    ProductCoverageRiskShare,
    ProductCoverageRiskShareFacility,
    ProductCoverageRiskShareFacilityPayorProcedure,
    File,
    CardFile,
    ExclusionDuration,
    ProductCoverageFacility,
    ClusterLog,
    DiagnosisLog,
    FacilityPayorProcedureUploadFile,
    FacilityPayorProcedureUploadLog,
    FacilityPayorProcedureRoom,
    CaseRate,
    File,
    FacilityFile,
    RUV,
    RUVLog,
    CaseRateLog,
    FacilityRUV,
    BenefitRUV,
    BenefitPackage,
    KycBank,
    MemberContact,
    FacilityRUVUploadFile,
    FacilityRUVUploadLog,
    ExclusionDisease,
    UserAccount,
    MemberUploadLog,
    MemberUploadFile,
    PayorCardBin,
    AccountHierarchyOfEligibleDependent,
    ApiAddress,
    Role,
    AuthorizationDiagnosis,
    AuthorizationProcedureDiagnosis,
    AuthorizationBenefitPackage,
    Batch,
    BatchAuthorization,
    ProfileCorrection,
    Comment,
    PractitionerFacilityConsultationFee,
    LocationGroup,
    LocationGroupRegion,
    FacilityLocationGroup,
    Miscellaneous,
    Pharmacy,
    ProductCoverageRoomAndBoard,
    AuthorizationLog,
    RoleApplication,
    AcuSchedule,
    AcuScheduleProduct,
    AcuScheduleMember,
    AcuSchedulePackage,
    Peme,
    Company,
    UserAccessActivationLog,
    UserAccessActivationFile,
    LoginIpAddress,
    AuthorizationPractitionerSpecialization,
    WorkerErrorLog,
    Migration,
    MigrationNotification,
    ProductCoverageLimitThreshold,
    ProductCoverageLocationGroup,
    Region,
    ProductCoverageDentalRiskShare,
    ProductCoverageDentalRiskShareFacility
  }

  def login_ip_address_factory do
    %LoginIpAddress{
      ip_address: "1.1.1.1",
      attempts: 1
    }
  end

  def user_factory do
    %User{
      email: sequence(:email, &"user-#{&1}@demo.com"),
      username: sequence(:username, &"user-#{&1}"),
      first_name: "John",
      last_name: "Doe",
      middle_name: "Joe",
      gender: "Male",
      first_time: false,
      payroll_code: "1"
    }
  end

  def user_account_factory do
    %UserAccount{
    }
  end

  def role_factory do
    %Role{
      step: 1,
      approval_limit: 10_000,
    }
  end

  def product_coverage_dental_risk_shares_factory do
    %ProductCoverageDentalRiskShare{}
  end


  def bank_branch_factory do
    %BankBranch{}
  end

  def application_factory do
    %Application{}
  end

  def permission_factory do
    %Permission{
      name: "Manage"
    }
  end

  def role_permission_factory do
    %RolePermission{
      role: build(:role),
      permission: build(:permission)
    }
  end

  def payor_factory do
    %Payor{
      name: "Maxicare"
    }
  end

  def dropdown_factory do
    %Dropdown{}
  end

  def facility_factory do
    %Facility{
      type: build(:dropdown),
      category: build(:dropdown),
      vat_status: build(:dropdown),
      prescription_clause: build(:dropdown),
      payment_mode: build(:dropdown),
      releasing_mode: build(:dropdown),
      loa_condition: true
    }
  end

  def facility_contact_factory do
    %FacilityContact{
      facility: build(:facility),
      contact: build(:contact)
    }
  end

  def room_factory do
    %Room{}
  end

  def account_comment_factory do
    %AccountComment{}
  end

  def product_facility_factory do
    %ProductFacility{
      product: build(:product),
      facility: build(:facility),
      coverage_id: "943a9bbc-356c-469c-a7b3-03b6ba96cb44"
    }
  end

  def benefit_factory do
    %Benefit{
      name: "test_name",
      code: sequence(:code, &"code-#{&1}"),
      category: "health"
    }
  end

  def product_factory do
    %Product{
      name: "produkto el dorado",
      description: "test desc",
      limit_applicability: "Individual",
      type: "Platinum",
      limit_type: "ABL",
      limit_amount: "2000",
      phic_status: "Optional to File",
      standard_product: "Yes",
      payor: build(:payor),
      peme_fee_for_service: false,
      peme_funding_arrangement: "ASO"
    }
  end

  def product_benefit_factory do
    %ProductBenefit{
      product: build(:product),
      benefit: build(:benefit)
    }
  end

  def product_coverage_factory do
    %ProductCoverage{
      product: build(:product),
      coverage: build(:coverage),
      type: "inclusion",
      funding_arrangement: "ASO"
    }
  end

  def product_coverage_room_and_board_factory do
    %ProductCoverageRoomAndBoard{
      product_coverage: build(:product_coverage)
    }
  end

  def product_coverage_risk_share_factory do
    %ProductCoverageRiskShare{
      product_coverage: build(:product_coverage)
    }
  end

  def product_coverage_risk_share_facility_factory do
    %ProductCoverageRiskShareFacility{
      product_coverage_risk_share: build(:product_coverage_risk_share),
      facility: build(:facility)
    }
  end

  def product_coverage_risk_share_facility_payor_procedure_factory do
    %ProductCoverageRiskShareFacilityPayorProcedure{
      product_coverage_risk_share_facility: build(
        :product_coverage_risk_share_facility),
      facility_payor_procedure: build(:facility_payor_procedure)
    }
  end

  def product_benefit_limit_factory do
    %ProductBenefitLimit{
      product_benefit: build(:product_benefit),
      benefit_limit: build(:benefit_limit)
    }
  end

  def cluster_factory do
    %Cluster{}
  end

  def roles_factory do
    %Role{}
  end

  def coverage_factory do
    %Coverage{
      name: "test_name",
      description: "test_desc" ,
      status: "test_status",
      type: "test_type"
    }
  end

  def procedure_factory do
    %Procedure{
      code: "test_code",
      description: "test_name" ,
      type: "test_type",
      procedure_category: build(:procedure_category)
    }
  end

  def account_factory do
    %Account{}
  end

  def account_group_address_factory do
    %AccountGroupAddress{
      account_group: build(:account_group)
    }
  end

  def exclusion_factory do
    %Exclusion{
      coverage: "General Exclusion"
    }
  end

  def exclusion_procedure_factory do
    %ExclusionProcedure{
      exclusion: build(:exclusion),
      procedure: build(:procedure)
    }
  end

  def exclusion_diseases_factory do
    %ExclusionDisease{
      exclusion: build(:exclusion),
      disease: build(:diagnosis)
    }
  end

  def exclusion_duration_factory do
    %ExclusionDuration{
      exclusion: build(:exclusion),
    }
  end

  def industry_factory do
    %Industry{}
  end

  def payment_account_factory do
    %PaymentAccount{
      account_group: build(:account_group)
    }
  end

  def contact_factory do
    %Contact{}
  end

  def account_group_contact_factory do
    %AccountGroupContact{
      account_group: build(:account_group),
      contact: build(:contact)
    }
  end

  def phone_factory do
    %Phone{
      contact: build(:contact)
    }
  end

  def email_factory do
    %Email{}
  end

  def user_role_factory do
    %UserRole{
      user: build(:user),
      role: build(:role)
    }
  end

  def bank_factory do
    %Bank{
      account_group: build(:account_group)
    }
  end

  def organization_factory do
    %Organization{
      account: build(:account)
    }
  end

  def diagnosis_factory do
    %Diagnosis{
      name: "name",
      classification: "class",
      type: "type",
      group_description: "group_desc",
      description: "test"
    }
  end

  def benefit_coverage_factory do
    %BenefitCoverage{
      benefit: build(:benefit),
      coverage: build(:coverage)
    }
  end

  def benefit_procedure_factory do
    %BenefitProcedure{
      benefit: build(:benefit),
      procedure: build(:payor_procedure)
    }
  end

  def benefit_diagnosis_factory do
    %BenefitDiagnosis{
      benefit: build(:benefit),
      diagnosis: build(:diagnosis)
    }
  end

  def benefit_limit_factory do
    %BenefitLimit{
      benefit: build(:benefit)
    }
  end

  def benefit_ruv_factory do
    %BenefitRUV{
      benefit: build(:benefit),
      ruv: build(:ruv)
    }
  end

  def benefit_package_factory do
    %BenefitPackage{
      benefit: build(:benefit),
      package: build(:package),
      payor_procedure_code: "A001"
    }
  end

  def account_group_factory do
    %AccountGroup{
      code: sequence(:code, &"code-#{&1}")
    }
  end

  def product_exclusion_factory do
    %ProductExclusion{
      product: build(:product),
      exclusion: build(:exclusion)
    }
  end

  def account_product_factory do
    %AccountProduct{
      account: build(:account),
      product: build(:product)
    }
  end

  def account_product_benefit_factory do
    %AccountProductBenefit{
      account_product: build(:account_product),
      product_benefit: build(:product_benefit)
    }
  end

  def account_group_cluster_factory do
    %AccountGroupCluster{}
  end

  def procedure_category_factory do
    %ProcedureCategory{}
  end

  def payor_procedure_factory do
    %PayorProcedure{
      is_active: true
    }
  end

  def practitioner_factory do
    %Practitioner{}
  end

  def facility_room_rate_factory do
    %FacilityRoomRate{
    }
  end

  def member_factory do
    %Member{
      birthdate: Ecto.Date.cast!("2017-01-05")
    }
  end

  def account_group_approval_factory do
    %AccountGroupApproval{
      account_group: build(:account_group)
    }
  end

  def specialization_factory do
    %Specialization{}
  end

  def practitioner_specialization_factory do
    %PractitionerSpecialization{
    }
  end

  def facility_payor_procedure_factory do
    %FacilityPayorProcedure{
      facility: build(:facility),
      payor_procedure: build(:payor_procedure)
    }
  end

  def practitioner_contact_factory do
    %PractitionerContact{
      practitioner: build(:practitioner),
      contact: build(:contact)
    }
  end

  def fulfillment_card_factory do
    %FulfillmentCard{}
  end

  def account_group_fulfillment_factory do
    %AccountGroupFulfillment{}
  end

  def practitioner_account_factory do
    %PractitionerAccount{
      practitioner: build(:practitioner),
      account_group: build(:account_group)
    }
  end

  def practitioner_account_contact_factory do
    %PractitionerAccountContact{
      practitioner_account: build(:practitioner_account),
      contact: build(:contact)
    }
  end

  def practitioner_schedule_factory do
    %PractitionerSchedule{
      practitioner_account: build(:practitioner_account),
      practitioner_facility: build(:practitioner_facility)
    }
  end

  def practitioner_facility_factory do
    %PractitionerFacility{
      cp_clearance: build(:dropdown),
      practitioner_status: build(:dropdown)
    }
  end

  def practitioner_facility_consultation_fee_factory do
    %PractitionerFacilityConsultationFee{
    }
  end

  def package_payor_procedure_factory do
    %PackagePayorProcedure{
      package: build(:package),
      payor_procedure: build(:payor_procedure)
    }
  end

  def package_facility_factory do
    %PackageFacility{
      package: build(:package),
      facility: build(:facility)
    }
  end

  def package_factory do
    %Package{
    }
  end

  def authorization_factory do
    %Authorization{
      coverage: build(:coverage),
      facility: build(:facility),
      member: build(:member)
    }
  end

  def authorization_amount_factory do
    %AuthorizationAmount{
      authorization: build(:authorization)
    }
  end

  def diagnosis_coverage_factory do
    %DiagnosisCoverage{}
  end

  def member_product_factory do
    %MemberProduct{
      member: build(:member),
      account_product: build(:account_product)
    }
  end

  def practitioner_facility_practitioner_type_factory do
    %PractitionerFacilityPractitionerType{
      practitioner_facility: build(:practitioner_facility)
    }
  end

  def cluster_log_factory do
    %ClusterLog{}
  end

  def card_file_factory do
    %CardFile{}
  end

  def product_coverage_facility_factory do
    %ProductCoverageFacility{
      facility: build(:facility),
      product_coverage: build(:product_coverage)
    }
  end

  def diagnosis_log_factory do
    %DiagnosisLog{
      diagnosis: build(:diagnosis),
      user: build(:user)
    }
  end

  def facility_payor_procedure_upload_file_factory do
    %FacilityPayorProcedureUploadFile{
      facility: build(:facility)
    }
  end

  def facility_payor_procedure_upload_log_factory do
    %FacilityPayorProcedureUploadLog{
      facility_payor_procedure_upload_file: build(
        :facility_payor_procedure_upload_file)
    }
  end

  def facility_payor_procedure_room_factory do
    %FacilityPayorProcedureRoom{
      facility_payor_procedure: build(:facility_payor_procedure),
      facility_room_rate: build(:facility_room_rate)
    }
  end

  def case_rate_factory do
    %CaseRate{}
  end

  def file_factory do
    %File{}
  end

  def ruv_factory do
    %RUV{}
  end

  def case_rate_log_factory do
    %CaseRateLog{}
  end

  def facility_file_factory do
    %FacilityFile{
      facility: build(:facility),
      file: build(:file),
      type: "some type"
    }
  end

  def ruv_log_factory do
    %RUVLog{
      ruv: build(:ruv),
      user: build(:user)
    }
  end

  def facility_ruv_factory do
    %FacilityRUV{
      facility: build(:facility),
      ruv: build(:ruv)
    }
  end

  def kyc_bank_factory do
    %KycBank{
    }
  end

  def member_contact_factory do
    %MemberContact{
    }
  end

  def exclusion_disease_factory do
    %ExclusionDisease{
    }
  end

  def facility_ruv_upload_file_factory do
    %FacilityRUVUploadFile{
      facility: build(:facility)
    }
  end

  def facility_ruv_upload_log_factory do
    %FacilityRUVUploadLog{
      facility_ruv_upload_file: build(:facility_ruv_upload_file)
    }
  end

  def member_upload_file_factory do
    %MemberUploadFile{}
  end

  def member_upload_log_factory do
    %MemberUploadLog{
      member_upload_file: build(:member_upload_file)
    }
  end

  def product_coverage_risk_share_facility_procedure_factory do
    %ProductCoverageRiskShareFacilityPayorProcedure{
      product_coverage_risk_share_facility: build(
        :product_coverage_risk_share_facility),
      facility_payor_procedure: build(:facility_payor_procedure)
    }
  end

  def payor_card_bin_factory do
    %PayorCardBin{
      payor: build(:payor)
    }
  end

  def account_hierarchy_of_eligible_dependent_factory do
    %AccountHierarchyOfEligibleDependent{
      account_group: build(:account_group)
    }
  end

  def api_address_factory do
    %ApiAddress{}
  end

  def authorization_diagnosis_factory do
    %AuthorizationDiagnosis{}
  end

  def authorization_procedure_diagnosis_factory do
    %AuthorizationProcedureDiagnosis{}
  end

  def authorization_benefit_package_factory do
    %AuthorizationBenefitPackage{}
  end

  def batch_factory do
    %Batch{}
  end

  def batch_authorization_factory do
    %BatchAuthorization{}
  end

  def profile_correction_factory do
    %ProfileCorrection{
      user: build(:user)
    }
  end

  def batch_comment_factory do
    %Comment{
      batch: build(:batch)
    }
  end

  def location_group_factory do
    %LocationGroup{}
  end

  def location_group_region_factory do
    %LocationGroupRegion{
      # location_group: build(:location_group)
    }
  end

  def facility_location_group_factory do
    %FacilityLocationGroup{
      facility: build(:facility),
      location_group: build(:location_group)
    }
  end

  def miscellaneous_factory do
    %Miscellaneous{}
  end

  def pharmacy_factory do
    %Pharmacy{}
  end

  def authorization_log_factory do
    %AuthorizationLog{
      user: build(:user),
      authorization: build(:authorization),
      message: "TEST LOG"
    }
  end

  def role_application_factory do
    %RoleApplication{
      role: build(:role),
      application: build(:application)
    }
  end

  def acu_schedule_factory do
    %AcuSchedule{
      date_to: Ecto.Date.cast!("2017-01-05"),
      date_from: Ecto.Date.cast!("2017-01-05"),
      # datetime: Ecto.Datetime.cast("22018-05-25 07:16:30.379503"),
      account_group: build(:account_group),
      facility: build(:facility),
      created_by: build(:user)
    }
  end

  def acu_schedule_member_factory do
    %AcuScheduleMember{
      status: "Active",
      acu_schedule: build(:acu_schedule),
      member: build(:member)
    }
  end

  def acu_schedule_product_factory do
    %AcuScheduleProduct{
      acu_schedule: build(:acu_schedule),
      product: build(:product)
    }
  end

  def acu_schedule_package_factory do
    %AcuSchedulePackage{
      acu_schedule: build(:acu_schedule),
      package: build(:package)
    }
  end

  def peme_factory do
    %Peme{}
  end

  def sequence_factory do
    %Sequence{}
  end

  def company_factory do
    %Company{}
  end

  def user_access_activation_file_factory do
    %UserAccessActivationFile{}
  end

  def user_access_activation_log_factory do
    %UserAccessActivationLog{}
  end

  def authorization_practitioner_specialization_factory do
    %AuthorizationPractitionerSpecialization{
      authorization: build(:authorization),
      practitioner_specialization: build(:practitioner_specialization)
    }
  end

  def worker_error_log_factory do
    %WorkerErrorLog{}
  end

  def migration_factory do
    %Migration{}
  end

  def migration_notification_factory do
    %MigrationNotification{
      migration: build(:migration),
    }
  end

  def product_coverage_limit_threshold_factory do
    %ProductCoverageLimitThreshold{}
  end

  def product_coverage_location_group_factory do
    %ProductCoverageLocationGroup{
      product_coverage: build(:product_coverage),
      location_group: build(:location_group)
    }
  end

  def region_factory do
    %Region{}
  end

  def product_coverage_dental_risk_share_factory do
    %ProductCoverageDentalRiskShare{
      product_coverage: build(:product_coverage),
    }
  end

  def product_coverage_dental_risk_share_facility_factory do
    %ProductCoverageDentalRiskShareFacility{
      product_coverage_dental_risk_share: build(:product_coverage_dental_risk_share),
      facility: build(:facility)
    }
  end
end


