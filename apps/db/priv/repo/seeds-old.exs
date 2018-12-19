alias Innerpeace.Db.{
  Repo,
  Schemas.Payor,
  Schemas.Role,
  Schemas.Permission,
  Schemas.Application,
  Schemas.User,
  Schemas.Procedure,
  Schemas.Industry,
  Schemas.Organization,
  Schemas.RolePermission,
  Schemas.Diagnosis,
  Schemas.Coverage,
  Schemas.RoleApplication,
  Schemas.Bank,
  Schemas.BankBranch,
  Schemas.Facility,
  Schemas.Benefit,
  Schemas.ProductBenefit,
  Schemas.BenefitCoverage,
  Schemas.BenefitProcedure,
  Schemas.BenefitLimit,
  Schemas.BenefitDiagnosis,
  Schemas.UserRole,
  Schemas.Account,
  Schemas.ProcedureCategory,
  Schemas.PayorProcedure,
  Schemas.Product,
  Schemas.FacilityCategory,
  Schemas.AccountGroup,
  Schemas.Specialization,
  Schemas.ProductBenefitLimit,
  Schemas.ProductExclusion,
  Schemas.ProductFacility,
  Schemas.ExclusionProcedure,
  Schemas.ExclusionDisease,
  Schemas.ExclusionDisease,
  Schemas.AccountGroupCluster,
  Schemas.Cluster,
  Schemas.Dropdown,
  Schemas.Member,
  Schemas.Practitioner,
  Schemas.PractitionerSpecialization,
  Base.UserContext
}

IO.puts "Deleting tables"
[
  Member,
  PayorProcedure,
  UserRole,
  AccountGroupCluster,
  ProductBenefitLimit,
  ProductFacility,
  ProductExclusion,
  ExclusionProcedure,
  ExclusionDisease,
  BenefitProcedure,
  BenefitCoverage,
  BenefitLimit,
  BenefitDiagnosis,
  RolePermission,
  RoleApplication,
  PractitionerSpecialization,
  User,
  Coverage,
  ProductBenefit,
  Product,
  Payor,
  Role,
  Permission,
  Procedure,
  BankBranch,
  Facility,
  FacilityCategory,
  Bank,
  Application,
  Account,
  Benefit,
  Diagnosis,
  ProcedureCategory,
  AccountGroup,
  Practitioner,
  Specialization,
  Cluster,
  Industry,
  Dropdown
] |> Enum.each(&Repo.delete_all(&1))

#Application
IO.puts "Adding Applications"

application_payor = Repo.insert!(%Application{name: "PayorLink"})
application_account = Repo.insert!(%Application{name: "AccountLink"})
application_facility = Repo.insert!(%Application{name: "FacilityLink"})
application_member = Repo.insert!(%Application{name: "DentalLink"})

#Permission
IO.puts "Adding Permissions"

manage_account = Repo.insert!(%Permission{
  name: "Manage Accounts",
  module: "Accounts",
  keyword: "manage_accounts",
  application: application_payor
})
manage_product = Repo.insert!(%Permission{
  name: "Manage Products",
  module: "Products",
  keyword: "manage_products",
  application: application_payor
})
manage_benefits = Repo.insert!(%Permission{
  name: "Manage Benefits",
  module: "Benefits",
  keyword: "manage_benefits",
  application: application_payor
})
manage_users = Repo.insert!(%Permission{
  name: "Manage Users",
  module: "Users",
  keyword: "manage_users",
  application: application_payor
})
manage_roles = Repo.insert!(%Permission{
  name: "Manage Roles",
  module: "Roles",
  keyword: "manage_roles",
  application: application_payor
})
manage_diseases = Repo.insert!(%Permission{
  name: "Manage Diseases",
  module: "Diseases",
  keyword: "manage_diseases",
  application: application_payor
})
manage_procedure = Repo.insert!(%Permission{
  name: "Manage Procedures",
  module: "Procedures",
  keyword: "manage_procedures",
  application: application_payor
})
manage_facilities = Repo.insert!(%Permission{
  name: "Manage Facilities",
  module: "Facilities",
  keyword: "manage_facilities",
  application: application_payor
})
manage_cluster = Repo.insert!(%Permission{
  name: "Manage Clusters",
  module: "Clusters",
  keyword: "manage_clusters",
  application: application_payor
})
manage_coverage = Repo.insert!(%Permission{
  name: "Manage Coverages",
  module: "Coverages",
  keyword: "manage_coverages",
  application: application_payor
})
manage_exclusions = Repo.insert!(%Permission{
  name: "Manage Exclusions",
  module: "Exclusions",
  keyword: "manage_exclusions",
  application: application_payor
})

access_account = Repo.insert!(%Permission{
  name: "Access Accounts",
  module: "Accounts",
  keyword: "access_accounts",
  application: application_payor
})
access_product = Repo.insert!(%Permission{
  name: "Access Products",
  module: "Products",
  keyword: "access_products",
  application: application_payor
})
access_benefits = Repo.insert!(%Permission{
  name: "Access Benefits",
  module: "Benefits",
  keyword: "access_benefits",
  application: application_payor
})
access_users = Repo.insert!(%Permission{
  name: "Access Users",
  module: "Users",
  keyword: "access_users",
  application: application_payor
})
access_roles = Repo.insert!(%Permission{
  name: "Access Roles",
  module: "Roles",
  keyword: "access_roles",
  application: application_payor
})
access_diseases = Repo.insert!(%Permission{
  name: "Access Diseases",
  module: "Diseases",
  keyword: "access_diseases",
  application: application_payor
})
access_procedure = Repo.insert!(%Permission{
  name: "Access Procedures",
  module: "Procedures",
  keyword: "access_procedures",
  application: application_payor
})
access_facilities = Repo.insert!(%Permission{
  name: "Access Facilities",
  module: "Facilities",
  keyword: "access_facilities",
  application: application_payor
})
access_cluster = Repo.insert!(%Permission{
  name: "Access Clusters",
  module: "Clusters",
  keyword: "access_clusters",
  application: application_payor
})
access_coverage = Repo.insert!(%Permission{
  name: "Access Clusters",
  module: "Coverages",
  keyword: "access_coverages",
  application: application_payor
})
access_exclusions = Repo.insert!(%Permission{
  name: "Access Exclusions",
  module: "Exclusionss",
  keyword: "access_exclusions",
  application: application_payor
})

IO.puts "Adding Users"
params = %{
  username: "admin",
  password: "P@ssw0rd",
  is_admin: true,
  email: "admin@gmail.com",
  mobile: "09199046601",
  first_name: "Admin",
  middle_name: "is",
  last_name: "trator",
  gender: "Male"
}

{:ok, user} = UserContext.create_admin(params)

#Roles
IO.puts "Adding Roles"
role_uefprocessor = Repo.insert!(%Role{
  name: "UEF Processor",
  description: "this is a sample role",
  step: 4,
  created_by_id: user.id,
})
role_uefsupervisor = Repo.insert!(%Role{
  name: "UEF Supervisor",
  description: "this is a sample role",
  step: 4,
  created_by_id: user.id,
})
role_uefmanager = Repo.insert!(%Role{
  name: "UEF Manager",
  description: "this is a sample role",
  step: 4,
  created_by_id: user.id,
})
role_ccnvfl = Repo.insert!(%Role{
  name: "Contact Ctr Non-Voice Front Line",
  description: "this is a sample role",
  step: 4,
  created_by_id: user.id,
})
role_ccnvs = Repo.insert!(%Role{
  name: "Contact Ctr Non-Voice Supervisor",
  description: "this is a sample role",
  step: 4,
  created_by_id: user.id,
})
role_ccnvm = Repo.insert!(%Role{
  name: "Contact Ctr Non-Voice Manager",
  description: "this is a sample role",
  step: 4,
  created_by_id: user.id,
})
role_ccvfl = Repo.insert!(%Role{
  name: "Contact Ctr Voice Front Line",
  description: "this is a sample role",
  step: 4,
  created_by_id: user.id,
})
role_ccvs = Repo.insert!(%Role{
  name: "Contact Ctr Voice Supervisor",
  description: "this is a sample role",
  step: 4,
  created_by_id: user.id,
})
role_ccvm = Repo.insert!(%Role{
  name: "Contact Ctr Voice Manager",
  description: "this is a sample role",
  step: 4,
  created_by_id: user.id,
})
role_rafrontline = Repo.insert!(%Role{
  name: "Roving Agent Front Line",
  description: "this is a sample role",
  step: 4,
  created_by_id: user.id,
})
role_rasupervisor = Repo.insert!(%Role{
  name: "Roving Agent Supervisor",
  description: "this is a sample role",
  step: 4,
  created_by_id: user.id,
})
role_ramanager = Repo.insert!(%Role{
  name: "Roving Agent Manager",
  description: "this is a sample role",
  step: 4,
  created_by_id: user.id,
})
role_claimp = Repo.insert!(%Role{
  name: "Claim Processor",
  description: "this is a sample role",
  step: 4,
  created_by_id: user.id,
})
role_claimtl = Repo.insert!(%Role{
  name: "Claim TL",
  description: "this is a sample role",
  step: 4,
  created_by_id: user.id,
})
role_claimmanager = Repo.insert!(%Role{
  name: "Claim Manager",
  description: "this is a sample role",
  step: 4,
  created_by_id: user.id,
})
role_billingfl = Repo.insert!(%Role{
  name: "Billing Front Line",
  description: "this is a sample role",
  step: 4,
  created_by_id: user.id,
})
role_billings = Repo.insert!(%Role{
  name: "Billing Supervisor",
  description: "this is a sample role",
  step: 4,
  created_by_id: user.id,
})
role_cfo = Repo.insert!(%Role{
  name: "CFO",
  description: "this is a sample role",
  step: 4,
  created_by_id: user.id,
})
role_coo = Repo.insert!(%Role{
  name: "COO",
  description: "this is a sample role",
  step: 4,
  created_by_id: user.id,
})
role_ceo = Repo.insert!(%Role{
  name: "CEO",
  description: "this is a sample role",
  step: 4,
  created_by_id: user.id,
})
role_admin = Repo.insert!(%Role{
  name: "admin",
  description: "Full access",
  step: 4,
  created_by_id: user.id,
})

#UserRole
Repo.insert!(%UserRole{user_id: user.id, role_id: role_admin.id})

#RoleApplication
IO.puts "Adding Role Applications"
Repo.insert!(%RoleApplication{
  application_id: application_payor.id,
  role_id: role_uefprocessor.id
})
Repo.insert!(%RoleApplication{
  application_id: application_payor.id,
  role_id: role_uefsupervisor.id
})
Repo.insert!(%RoleApplication{
  application_id: application_payor.id,
  role_id: role_uefmanager.id
})
Repo.insert!(%RoleApplication{
  application_id: application_payor.id,
  role_id: role_ccnvfl.id
})
Repo.insert!(%RoleApplication{
  application_id: application_payor.id,
  role_id: role_ccnvs.id
})
Repo.insert!(%RoleApplication{
  application_id: application_payor.id,
  role_id: role_ccnvm.id
})
Repo.insert!(%RoleApplication{
  application_id: application_payor.id,
  role_id: role_ccvs.id
})
Repo.insert!(%RoleApplication{
  application_id: application_payor.id,
  role_id: role_ccvm.id
})
Repo.insert!(%RoleApplication{
  application_id: application_payor.id,
  role_id: role_ccvfl.id
})
Repo.insert!(%RoleApplication{
  application_id: application_payor.id,
  role_id: role_rafrontline.id
})
Repo.insert!(%RoleApplication{
  application_id: application_payor.id,
  role_id: role_rasupervisor.id
})
Repo.insert!(%RoleApplication{
  application_id: application_payor.id,
  role_id: role_ramanager.id
})
Repo.insert!(%RoleApplication{
  application_id: application_payor.id,
  role_id: role_claimp.id
})
Repo.insert!(%RoleApplication{
  application_id: application_payor.id,
  role_id: role_claimtl.id
})
Repo.insert!(%RoleApplication{
  application_id: application_payor.id,
  role_id: role_claimmanager.id
})
Repo.insert!(%RoleApplication{
  application_id: application_payor.id,
  role_id: role_billingfl.id
})
Repo.insert!(%RoleApplication{
  application_id: application_payor.id,
  role_id: role_billings.id
})
Repo.insert!(%RoleApplication{
  application_id: application_payor.id,
  role_id: role_cfo.id
})
Repo.insert!(%RoleApplication{
  application_id: application_payor.id,
  role_id: role_coo.id
})
Repo.insert!(%RoleApplication{
  application_id: application_payor.id,
  role_id: role_ceo.id
})
Repo.insert!(%RoleApplication{
  application_id: application_payor.id,
  role_id: role_admin.id
})

#RolePermission
IO.puts "Adding Role Permissions"
Repo.insert!(%RolePermission{
  role_id: role_uefprocessor.id,
  permission_id: manage_users.id
})
Repo.insert!(%RolePermission{
  role_id: role_uefsupervisor.id,
  permission_id: manage_users.id
})
Repo.insert!(%RolePermission{
  role_id: role_uefmanager.id,
  permission_id: manage_users.id
})
Repo.insert!(%RolePermission{
  role_id: role_ccnvfl.id,
  permission_id: manage_users.id
})
Repo.insert!(%RolePermission{
  role_id: role_ccnvs.id,
  permission_id: manage_users.id
})
Repo.insert!(%RolePermission{
  role_id: role_ccnvm.id,
  permission_id: manage_users.id
})
Repo.insert!(%RolePermission{
  role_id: role_ccvs.id,
  permission_id: manage_users.id
})
Repo.insert!(%RolePermission{
  role_id: role_ccvm.id,
  permission_id: manage_users.id
})
Repo.insert!(%RolePermission{
  role_id: role_ccvfl.id,
  permission_id: manage_users.id
})
Repo.insert!(%RolePermission{
  role_id: role_rafrontline.id,
  permission_id: manage_users.id
})
Repo.insert!(%RolePermission{
  role_id: role_rasupervisor.id,
  permission_id: manage_users.id
})
Repo.insert!(%RolePermission{
  role_id: role_ramanager.id,
  permission_id: manage_users.id
})
Repo.insert!(%RolePermission{
  role_id: role_claimp.id,
  permission_id: manage_users.id
})
Repo.insert!(%RolePermission{
  role_id: role_claimtl.id,
  permission_id: manage_users.id
})
Repo.insert!(%RolePermission{
  role_id: role_claimmanager.id,
  permission_id: manage_users.id
})
Repo.insert!(%RolePermission{
  role_id: role_billingfl.id,
  permission_id: manage_users.id
})
Repo.insert!(%RolePermission{
  role_id: role_billings.id,
  permission_id: manage_users.id
})
Repo.insert!(%RolePermission{
  role_id: role_cfo.id,
  permission_id: manage_users.id
})
Repo.insert!(%RolePermission{
  role_id: role_coo.id,
  permission_id: manage_users.id
})
Repo.insert!(%RolePermission{
  role_id: role_ceo.id,
  permission_id: manage_users.id
})
Repo.insert!(%RolePermission{
  role_id: role_ceo.id,
  permission_id: manage_roles.id
})
Repo.insert!(%RolePermission{
  role_id: role_ceo.id,
  permission_id: manage_benefits.id
})
Repo.insert!(%RolePermission{
  role_id: role_ceo.id,
  permission_id: manage_account.id
})
Repo.insert!(%RolePermission{
  role_id: role_ceo.id,
  permission_id: manage_diseases.id
})
for permission <- Repo.all(Permission) do
  Repo.insert(%RolePermission{
    role_id: role_admin.id,
    permission_id: permission.id
  })
end

IO.puts "Adding Payors"
payor_maxicare = Repo.insert!(%Payor{
  name: "Maxicare",
  legal_name: "Maxicare Healthcare Corporation",
  tax_number: 123_456,
  type: "Payor",
  status: "None",
  code: "ABCDEFG"
})

payor_caritas = Repo.insert!(%Payor{
  name: "Caritas Health Shield",
  legal_name: "Caritas Health Shield",
  tax_number: 123_456,
  type: "Payor",
  status: "None",
  code: "HIJKLMNO"
})

# for Account Group Only
accountgroup1 = Repo.insert!(%AccountGroup{
 name: "Account101",
 code: "CODE101",
 type: "Subsidiary"
})

# for Industry Only
industry = Repo.insert!(%Industry{
  code: "A00 - ACTIVITIES NOT ADEQUATELY DEFINED"
})

# for Product only
IO.puts "Adding Products"
product1 = Repo.insert!(%Product{
  code: Product.random_pcode(),
  name: "Maxicare Product 1",
  description: "Health card for regular employee",
  limit_applicability: "Individual",
  type: "Platinum",
  limit_type: "MBL",
  limit_amount: 100_000,
  phic_status: "Required to file",
  standard_product: "Yes",
  payor_id: payor_maxicare.id,
  principal_min_age: 18,
  principal_min_type: "Years",
  principal_max_age: 64,
  principal_max_type: "Years",
  adult_dependent_min_age: 18,
  adult_dependent_min_type: "Years",
  adult_dependent_max_age: 65,
  adult_dependent_max_type: "Years",
  minor_dependent_min_age: 15,
  minor_dependent_min_type: "Days",
  minor_dependent_max_age: 20,
  minor_dependent_max_type: "Days",
  overage_dependent_min_age: 66,
  overage_dependent_min_type: "Years",
  overage_dependent_max_age: 70,
  overage_dependent_max_type: "Years",
  adnb: 1000.00,
  adnnb: 1000.00,
  opmnb: 2500.00,
  opmnnb: 5000.00,
  room_and_board: "Alternative",
  room_type: "Suite",
  room_limit_amount: 100_000.00,
  room_upgrade: 12,
  room_upgrade_time: "Hours"
})

product2 = Repo.insert!(%Product{
  code: Product.random_pcode(),
  name: "Maxicare Product 2",
  description: "Health card for Manager",
  limit_applicability: "Share with family",
  type: "Platinum",
  limit_type: "ABL",
  limit_amount: 10_000,
  phic_status: "Optional to file",
  standard_product: "No",
  payor_id: payor_maxicare.id,
  principal_min_age: 16,
  principal_min_type: "Years",
  principal_max_age: 55,
  principal_max_type: "Years",
  adult_dependent_min_age: 16,
  adult_dependent_min_type: "Years",
  adult_dependent_max_age: 55,
  adult_dependent_max_type: "Years",
  minor_dependent_min_age: 16,
  minor_dependent_min_type: "Days",
  minor_dependent_max_age: 55,
  minor_dependent_max_type: "Days",
  overage_dependent_min_age: 55,
  overage_dependent_min_type: "Years",
  overage_dependent_max_age: 55,
  overage_dependent_max_type: "Years",
  adnb: 2000.00,
  adnnb: 2000.00,
  opmnb: 3500.00,
  opmnnb: 6000.00,
  room_and_board: "Alternative",
  room_type: "Suite",
  room_limit_amount: 100_000.00,
  room_upgrade: 12,
  room_upgrade_time: "Hours"
})

product3 = Repo.insert!(%Product{
  code: Product.random_pcode(),
  name: "Maxicare Product 3",
  description: "Health card for Executive",
  limit_applicability: "Individual",
  type: "Platinum",
  limit_type: "MBL",
  limit_amount: 100_000,
  phic_status: "Required to file",
  standard_product: "Yes",
  payor_id: payor_maxicare.id,
  principal_min_age: 18,
  principal_min_type: "Years",
  principal_max_age: 64,
  principal_max_type: "Years",
  adult_dependent_min_age: 18,
  adult_dependent_min_type: "Years",
  adult_dependent_max_age: 65,
  adult_dependent_max_type: "Years",
  minor_dependent_min_age: 15,
  minor_dependent_min_type: "Days",
  minor_dependent_max_age: 20,
  minor_dependent_max_type: "Days",
  overage_dependent_min_age: 66,
  overage_dependent_min_type: "Years",
  overage_dependent_max_age: 70,
  overage_dependent_max_type: "Years",
  adnb: 1000.00,
  adnnb: 1000.00,
  opmnb: 2500.00,
  opmnnb: 5000.00,
  room_and_board: "Alternative",
  room_type: "Suite",
  room_limit_amount: 100_000.00,
  room_upgrade: 12,
  room_upgrade_time: "Hours"
})

product4 = Repo.insert!(%Product{
  code: Product.random_pcode(),
  name: "Maxicare Product 4",
  description: "Health card for Consultant",
  limit_applicability: "Share with family",
  type: "Platinum",
  limit_type: "ABL",
  limit_amount: 10_000,
  phic_status: "Optional to file",
  standard_product: "No",
  payor_id: payor_maxicare.id,
  principal_min_age: 16,
  principal_min_type: "Years",
  principal_max_age: 55,
  principal_max_type: "Years",
  adult_dependent_min_age: 16,
  adult_dependent_min_type: "Years",
  adult_dependent_max_age: 55,
  adult_dependent_max_type: "Years",
  minor_dependent_min_age: 16,
  minor_dependent_min_type: "Days",
  minor_dependent_max_age: 55,
  minor_dependent_max_type: "Days",
  overage_dependent_min_age: 55,
  overage_dependent_min_type: "Years",
  overage_dependent_max_age: 55,
  overage_dependent_max_type: "Years",
  adnb: 2000.00,
  adnnb: 2000.00,
  opmnb: 3500.00,
  opmnnb: 6000.00,
  room_and_board: "Alternative",
  room_type: "Suite",
  room_limit_amount: 100_000.00,
  room_upgrade: 12,
  room_upgrade_time: "Hours"
})

product5 = Repo.insert!(%Product{
  code: Product.random_pcode(),
  name: "Maxicare Product 5",
  description: "Health card for Supervisor",
  limit_applicability: "Individual",
  type: "Platinum",
  limit_type: "MBL",
  limit_amount: 100_000,
  phic_status: "Required to file",
  standard_product: "Yes",
  payor_id: payor_maxicare.id,
  principal_min_age: 18,
  principal_min_type: "Years",
  principal_max_age: 64,
  principal_max_type: "Years",
  adult_dependent_min_age: 18,
  adult_dependent_min_type: "Years",
  adult_dependent_max_age: 65,
  adult_dependent_max_type: "Years",
  minor_dependent_min_age: 15,
  minor_dependent_min_type: "Days",
  minor_dependent_max_age: 20,
  minor_dependent_max_type: "Days",
  overage_dependent_min_age: 66,
  overage_dependent_min_type: "Years",
  overage_dependent_max_age: 70,
  overage_dependent_max_type: "Years",
  adnb: 1000.00,
  adnnb: 1000.00,
  opmnb: 2500.00,
  opmnnb: 5000.00,
  room_and_board: "Alternative",
  room_type: "Suite",
  room_limit_amount: 100_000.00,
  room_upgrade: 12,
  room_upgrade_time: "Hours"
})

IO.puts "Adding Coverages"

# for Health Plan only
coverage_opconsult = Repo.insert!(%Coverage{
  name: "OP Consult",
  description: "OP Consult",
  status: "A",
  type: "A",
  plan_type: "health_plan",
  code: "OPC"
})
coverage_oplab = Repo.insert!(%Coverage{
  name: "OP Laboratory",
  description: "OP Laboratory",
  status: "A",
  type: "A",
  plan_type: "health_plan",
  code: "OPL"
})
coverage_emergency = Repo.insert!(%Coverage{
  name: "Emergency",
  description: "Emergency",
  status: "A",
  type: "A",
  plan_type: "health_plan",
  code: "EMRGNCY"
})
coverage_inpatient = Repo.insert!(%Coverage{
  name: "Inpatient",
  description: "Inpatient",
  status: "A",
  type: "A",
  plan_type: "health_plan",
  code: "IP"
})

# for Riders only
coverage_dental = Repo.insert!(%Coverage{
  name: "Dental",
  description: "Dental",
  status: "A",
  type: "A",
  plan_type: "riders",
  code: "DENTL"
})
coverage_maternity = Repo.insert!(%Coverage{
  name: "Maternity",
  description: "Maternity",
  status: "A",
  type: "A",
  plan_type: "riders",
  code: "MTRNTY"
})
coverage_acu = Repo.insert!(%Coverage{
  name: "ACU",
  description: "ACU",
  status: "A",
  type: "A",
  plan_type: "riders",
  code: "ACU"
})
coverage_optical = Repo.insert!(%Coverage{
  name: "Optical",
  description: "Optical",
  status: "A",
  type: "A",
  plan_type: "riders",
  code: "OPT"
})
coverage_medicine = Repo.insert!(%Coverage{
  name: "Medicine",
  description: "Medicine",
  status: "A",
  type: "A",
  plan_type: "riders",
  code: "MED"
})
coverage_cancer = Repo.insert!(%Coverage{
  name: "Cancer",
  description: "Cancer",
  status: "A",
  type: "A",
  plan_type: "riders",
  code: "CNCR"
})

IO.puts "Adding Bank"
# Bank
bank_mbtc = Repo.insert!(%Bank{account_name: "Metropolitan Bank and Trust Company"})
bank_asiatrust = Repo.insert!(%Bank{account_name: "Asia Trust"})
bank_aub = Repo.insert!(%Bank{account_name: "Asia United Bank"})
bank_bdo = Repo.insert!(%Bank{account_name: "Banco De Oro"})
bank_bpi = Repo.insert!(%Bank{account_name: "Bank of the Philippine Islands"})
bank_equicom = Repo.insert!(%Bank{account_name: "Equicom Savings Bank"})
bank_psb = Repo.insert!(%Bank{account_name: "Philippine Savings Bank"})
bank_securitybc = Repo.insert!(%Bank{account_name: "Security Bank Corporation"})
bank_union = Repo.insert!(%Bank{account_name: "Union Bank"})

IO.puts "Adding Bank Branch"
# Bank Branch
bank_branch_makati = Repo.insert!(%BankBranch{
  bank_id: bank_asiatrust.id,
  unit_no: "5b",
  bldg_name: "Cacho Gonzalez Bldg.",
  street_name: "Aguirre st.",
  municipality: "Makati City",
  province: "N/A",
  region: "NCR",
  country: "PHILIPPINES",
  postal_code: "1661",
  phone: "444-38-56",
  branch_type: "Main branch"
})

bank_branch_taguig = Repo.insert!(%BankBranch{
  bank_id: bank_bdo.id,
  unit_no: "10a",
  bldg_name: "Apple Bldg.",
  street_name: "Micro St.",
  municipality: "Taguig City",
  province: "N/A",
  region: "NCR",
  country: "PHILIPPINES",
  postal_code: "1337",
  phone: "444-88-44",
  branch_type: "Main branch"
})

bank_branch_pasig = Repo.insert!(%BankBranch{
  bank_id: bank_aub.id,
  unit_no: "14lite",
  bldg_name: "Jose Rizal Bldg.",
  street_name: "Bayani St.",
  municipality: "Pasig City",
  province: "N/A",
  region: "NCR",
  country: "PHILIPPINES",
  postal_code: "1327",
  phone: "474-83-33",
  branch_type: "Main branch"
})

bank_branch_pasongtamo = Repo.insert!(%BankBranch{
  bank_id: bank_bpi.id,
  unit_no: "P.Tamo",
  bldg_name: "Tamong Paso Bldg.",
  street_name: "Yague St.",
  municipality: "Marikina City",
  province: "N/A",
  region: "NCR",
  country: "PHILIPPINES",
  postal_code: "1927",
  phone: "494-23-44",
  branch_type: "Main branch"
})

bank_branch_magallanes = Repo.insert!(%BankBranch{
  bank_id: bank_equicom.id,
  unit_no: "Magellan 25",
  bldg_name: "St. Viscious Bldg.",
  street_name: "Duhat St.",
  municipality: "Paranaque City",
  province: "N/A",
  region: "NCR",
  country: "PHILIPPINES",
  postal_code: "1557",
  phone: "894-56-53",
  branch_type: "Main branch"
})

bank_branch_vitocruz = Repo.insert!(%BankBranch{
  bank_id: bank_union.id,
  unit_no: "Taffy1",
  bldg_name: "Avenida Bldg.",
  street_name: "Leona St.",
  municipality: "Manila City",
  province: "N/A",
  region: "NCR",
  country: "PHILIPPINES",
  postal_code: "1297",
  phone: "474-89-63",
  branch_type: "Main branch"
})

# Facility Category
tertiary_acu = Repo.insert!(%FacilityCategory{
  type: "TERTIARY + ACU"
})

full_service_acu = Repo.insert!(%FacilityCategory{
  type: "FULL SERVICE + ACU"
})

tertiary = Repo.insert!(%FacilityCategory{
  type: "TERTIARY"
})

# Facility seeds
IO.puts "Adding Facilities"
facility_makatimed = Repo.insert!(%Facility{
  code: "880000000006035",
  name: "MAKATI MEDICAL CENTER",
  status: "I",
  affiliation_date: Ecto.Date.cast!("2011-02-17"),
  prescription_term: 45,
  tin: "123456789",
  step: 4,
  facility_category_id: tertiary_acu.id
})

facility_chinesgen = Repo.insert!(%Facility{
  code: "880000000006024",
  name: "CHINESE GENERAL HOSPITAL & MEDICAL CENTER",
  status: "A",
  affiliation_date: Ecto.Date.cast!("1999-07-31"),
  prescription_term: 30,
  tin: "123456789",
  step: 4,
  facility_category_id: tertiary.id
})

facility_myhealth = Repo.insert!(%Facility{
  code: "880000000013931",
  name: "MYHEALTH CLINIC - SM NORTH EDSA",
  status: "A",
  affiliation_date: Ecto.Date.cast!("2011-02-17"),
  prescription_term: 30,
  tin: "123456789",
  step: 4,
  facility_category_id: full_service_acu.id
})

facility_calambamed = Repo.insert!(%Facility{
  code: "880000000000359",
  name: "CALAMBA MEDICAL CENTER",
  status: "A",
  affiliation_date: Ecto.Date.cast!("1999-08-30"),
  prescription_term: 30,
  tin: "123456789",
  step: 3,
  facility_category_id: tertiary.id
})

facility_olpmed = Repo.insert!(%Facility{
  code: "880000000001724",
  name: "OUR LADY OF PILLAR MEDICAL CENTER",
  status: "A",
  affiliation_date: Ecto.Date.cast!("2011-02-17"),
  prescription_term: 60,
  tin: "658412358",
  step: 2,
  facility_category_id: tertiary_acu.id
})

facility_medcitylwc = Repo.insert!(%Facility{
  code: "880000000017287",
  name: "THE MEDICAL CITY LIFESTYLE AND WELLNESS CENTER (TIMOG)",
  status: "I",
  affiliation_date: Ecto.Date.cast!("2014-06-15"),
  prescription_term: 90,
  tin: "001-044-237-025",
  step: 4,
  facility_category_id: tertiary.id
})

facility_seamedcenter = Repo.insert!(%Facility{
  code: "88000000016375",
  name: "SOUTHEAST ASIAN MEDICAL CENTER, INC.",
  status: "A",
  affiliation_date: Ecto.Date.cast!("2015-09-07"),
  prescription_term: 45,
  tin: "123456789",
  step: 4,
  facility_category_id: full_service_acu.id
})

facility_danielmercado = Repo.insert!(%Facility{
  code: "880000000001544",
  name: "DANIEL O. MERCADO MEDICAL CENTER",
  status: "A",
  affiliation_date: Ecto.Date.cast!("1989-04-15"),
  prescription_term: 60,
  tin: "658412358",
  step: 4,
  facility_category_id: tertiary.id
})

facility_clinicamanila = Repo.insert!(%Facility{
  code: "880000000000528",
  name: "CLINICA MANILA",
  status: "I",
  affiliation_date: Ecto.Date.cast!("2006-07-07"),
  prescription_term: 90,
  tin: "001-044-237-025",
  step: 4,
  facility_category_id: tertiary.id
})

facility_capitolmed = Repo.insert!(%Facility{
  code: "88000000006020",
  name: "CAPITOL MEDICAL CENTER",
  status: "A",
  affiliation_date: Ecto.Date.cast!("1991-09-19"),
  prescription_term: 45,
  tin: "123456789",
  step: 4,
  facility_category_id: tertiary_acu.id
})

# Seeds Procedure_Category
IO.puts "Adding Procedure Category"

anesthesia = Repo.insert! %ProcedureCategory{
  name: "Anesthesia",
  code: "00100-01999"
}

surgery = Repo.insert! %ProcedureCategory{
  name: "Surgery",
  code: "10021-69990"
}

radiology_procedures = Repo.insert! %ProcedureCategory{
  name: "Radiology Procedures",
  code: "70010-79999"
}

path_lab_procedures = Repo.insert! %ProcedureCategory{
  name: "Pathology and Laboratory Procedures",
  code: "80047-89398"
}

med_services_procedures = Repo.insert! %ProcedureCategory{
  name: "Medicine Services and Procedures",
  code: "90281-99607"
}

eval_manage_services = Repo.insert! %ProcedureCategory{
  name: "Evaluation and Management Services",
  code: "99201-99499"
}

category_2 = Repo.insert! %ProcedureCategory{
  name: "Category II Codes",
  code: "0001F-9007F"
}

multi_assay = Repo.insert! %ProcedureCategory{
  name: "Multianalyte Assay",
  code: "0001M-0009M"
}

lab_analyses = Repo.insert! %ProcedureCategory{
  name: "Laboratory Analyses",
  code: "0001U-0005U"
}

category_3 = Repo.insert! %ProcedureCategory{
  name: "Category III Codes",
  code: "0042T-0478T"
}

modifiers = Repo.insert! %ProcedureCategory{
  name: "Modifiers",
  code: "cpt-modifiers"
}

# Seeds Procedures
IO.puts "Adding Procedure"

procedure1 = Repo.insert! %Procedure{
  code: "83498",
  description: "HYDROXYPROGESTERONE, 17-D",
  type: "Diagnostic",
  procedure_category_id: path_lab_procedures.id
}

procedure2 = Repo.insert! %Procedure{
  code: "88271",
  description: "MOLECULAR CYTOGENETICS; DNA PROBE, EACH (EG, FISH)",
  type: "Diagnostic",
  procedure_category_id: path_lab_procedures.id
}

procedure3 = Repo.insert! %Procedure{
  code: "84156",
  description: "PROTEIN, TOTAL, EXCEPT BY REFRACTOMETRY; URINE",
  type: "Diagnostic",
  procedure_category_id: path_lab_procedures.id
}

Repo.insert! %Procedure{
  code: "82507",
  description: "CITRATE",
  type: "Diagnostic",
  procedure_category_id: path_lab_procedures.id
}

procedure4 = Repo.insert! %Procedure{
  code: "83497",
  description: "HYDROXYINDOLACETIC ACID, 5-(HIAA)",
  type: "Diagnostic",
  procedure_category_id: path_lab_procedures.id
}

procedure5 = Repo.insert! %Procedure{
  code: "84060",
  description: "PHOSPHATASE, ACID; TOTAL",
  type: "Diagnostic",
  procedure_category_id: path_lab_procedures.id
}

procedure6 = Repo.insert! %Procedure{
  code: "82024",
  description: "ADRENOCORTICOTROPIC HORMONE (ACTH)",
  type: "Diagnostic",
  procedure_category_id: path_lab_procedures.id
}

Repo.insert! %Procedure{
  code: "87015",
  description: "Concentration (any type), for infectious agents",
  type: "Diagnostic",
  procedure_category_id: path_lab_procedures.id
}

Repo.insert! %Procedure{
  code: "87206",
  description: "SMEAR, PRIMARY SOURCE WITH INTERPRETATION; FLUORESCENT AND/OR ACID FAST STAIN FOR BACTERIA, FUNGI, PARASITES, VIRUSES OR CELL TYPES",
  type: "Diagnostic",
  procedure_category_id: path_lab_procedures.id
}

Repo.insert! %Procedure{
  code: "82042",
  description: "ALBUMIN; URINE OR OTHER SOURCE, QUANTITATIVE, EACH SPECIMEN",
  type: "Diagnostic",
  procedure_category_id: path_lab_procedures.id
}

Repo.insert! %Procedure{
  code: "82040",
  description: "ALBUMIN; SERUM, PLASMA OR WHOLE BLOOD",
  type: "Diagnostic",
  procedure_category_id: path_lab_procedures.id
}

Repo.insert! %Procedure{
  code: "74182",
  description: "MAGNETIC RESONANCE (EG, PROTON) IMAGING, ABDOMEN; WITH CONTRAST MATERIAL(S)",
  type: "Diagnostic",
  procedure_category_id: radiology_procedures.id
}

Repo.insert! %Procedure{
  code: "72147",
  description: "MAGNETIC RESONANCE (EG, PROTON) IMAGING, SPINAL CANAL AND CONTENTS, THORACIC; WITH CONTRAST MATERIAL",
  type: "Diagnostic",
  procedure_category_id: radiology_procedures.id
}

Repo.insert! %Procedure{
  code: "36831",
  description: "THROMBECTOMY, OPEN, ARTERIOVENOUS FISTULA WITHOUT REVISION, AUTOGENOUS OR NONAUTOGENOUS DIALYSIS GRAFT",
  type: "Diagnostic",
  procedure_category_id: surgery.id
}

Repo.insert! %Procedure{
  code: "93886",
  description: "TRANSCRANIAL DOPPLER STUDY OF THE INTRACRANIAL ARTERIES; COMPLETE STUDY",
  type: "Diagnostic",
  procedure_category_id: med_services_procedures.id
}

Repo.insert! %Procedure{
  code: "93971",
  description: "DUPLEX SCAN OF EXTREMITY VEINS INCLUDING RESPONSES TO COMPRESSION AND OTHER MANEUVERS; UNILATERAL OR LIMITED STUDY",
  type: "Diagnostic",
  procedure_category_id: med_services_procedures.id
}

Repo.insert! %Procedure{
  code: "76705",
  description: "Ultrasound, abdominal, real time with image documentation; limited (eg, single organ, quadrant, follow-up)",
  type: "Diagnostic",
  procedure_category_id: radiology_procedures.id
}

Repo.insert! %Procedure{
  code: "21356",
  description: "ZYGOMATIC ARCH",
  type: "Diagnostic",
  procedure_category_id: surgery.id
}

Repo.insert! %Procedure{
  code: "Dental002",
  description: "ORAL PROPHYLAXIS",
  type: "Dental"
}

Repo.insert! %Procedure{
  code: "Dental003",
  description: "SIMPLE TOOTH EXTRACTION",
  type: "Dental"
}

Repo.insert! %Procedure{
  code: "Dental004",
  description: "TEMPORARY FILLING",
  type: "Dental"
}

Repo.insert! %Procedure{
  code: "Dental005",
  description: "SIMPLE REPAIR AND ADJUSTMENT OF DENTURES",
  type: "Dental"
}

Repo.insert! %Procedure{
  code: "Dental006",
  description: "RECEMENTATION OF JACKET CROWNS, BRIDGES, INLAY AND ONLAY",
  type: "Dental"
}

Repo.insert! %Procedure{
  code: "Dental007",
  description: "PALLIATIVE TREATMENT OF SIMPLE MOUTH SORES AND BLISTERS",
  type: "Dental"
}

Repo.insert! %Procedure{
  code: "Dental008",
  description: "DESENSITIZATION OF HYPERSENSITIVE TEETH",
  type: "Dental"
}

Repo.insert! %Procedure{
  code: "Dental009",
  description: "PERMANENT FILLINGS",
  type: "Dental"
}

Repo.insert! %Procedure{
  code: "Dental011",
  description: "PERIAPICAL XRAY",
  type: "Dental"
}

Repo.insert! %Procedure{
  code: "Dental012",
  description: "DEEP SCALING",
  type: "Dental"
}

Repo.insert! %Procedure{
  code: "Dental013",
  description: "IMPACTION SURGERY",
  type: "Dental"
}

Repo.insert! %Procedure{
  code: "Dental014",
  description: "ROOT CANAL TREATMENT (RCT)",
  type: "Dental"
}

Repo.insert! %Procedure{
  code: "Dental016",
  description: "REMOVABLE PARTIAL DENTURE - UNILATERAL",
  type: "Dental"
}

Repo.insert! %Procedure{
  code: "Dental017",
  description: "BITE-WING X-RAY",
  type: "Dental"
}

Repo.insert! %Procedure{
  code: "Dental018",
  description: "OCCLUSAL X-RAY",
  type: "Dental"
}

Repo.insert! %Procedure{
  code: "Dental019",
  description: "TOPICAL FLUORIDE APPLICATION",
  type: "Dental"
}

Repo.insert! %Procedure{
  code: "Dental020",
  description: "PIT & FISSURE SEALANT",
  type: "Dental"
}

Repo.insert! %Procedure{
  code: "Dental021",
  description: "LIGHT CURE-BASE FILLING",
  type: "Dental"
}

Repo.insert! %Procedure{
  code: "Dental022",
  description: "COMPLICATED TOOTH EXTRACTION",
  type: "Dental"
}

Repo.insert! %Procedure{
  code: "Dental023",
  description: "MINOR SOFT TISSUE SURGERY",
  type: "Dental"
}

Repo.insert! %Procedure{
  code: "Dental024",
  description: "APICOECTOMY",
  type: "Dental"
}

Repo.insert! %Procedure{
  code: "Dental025",
  description: "PERIODONTAL SURGERY",
  type: "Dental"
}

Repo.insert! %Procedure{
  code: "Dental037",
  description: "POST & CORE CASTED TYPE",
  type: "Dental"
}

Repo.insert! %Procedure{
  code: "Dental038",
  description: "MOUTHGUARD",
  type: "Dental"
}

Repo.insert! %Procedure{
  code: "Dental039",
  description: "DENTAL X-RAY",
  type: "Dental"
}

Repo.insert! %Procedure{
  code: "Dental046",
  description: "Dental / Oral Surgeries",
  type: "Dental"
}

Repo.insert! %Procedure{
  code: "Dental057",
  description: "GUM TREATMENT FOR CASES LIKE INFLAMMATION OR BLEEDING",
  type: "Dental"
}

Repo.insert! %Procedure{
  code: "Dental069",
  description: "EMERGENCY DENTAL TREATMENT",
  type: "Dental"
}

Repo.insert! %Procedure{
  code: "Dental099",
  description: "Oral Incision and drainage",
  type: "Dental"
}

Repo.insert! %Procedure{
  code: "Dental114",
  description: "ORAL PROPHYLAXIS WITH FLUORIDE BRUSHING",
  type: "Dental"
}

# seed PayorProcedure referencing StandardProcedure as Procedure
payor_procedure1 = Repo.insert! %PayorProcedure{
  description: "17 HYDROXY PROGESTERONE",
  code: "LAB0503004",
  payor_id: payor_maxicare.id,
  procedure_id: procedure1.id
}

payor_procedure2 = Repo.insert! %PayorProcedure{
  description: "BCR/ABL (F.I.S.H.)",
  code: "LAB1220",
  payor_id: payor_maxicare.id,
  procedure_id: procedure2.id
}

payor_procedure3 = Repo.insert! %PayorProcedure{
  description: "24 HOUR URINE TOTAL CHON",
  code: "LAB6764",
  payor_id: payor_maxicare.id,
  procedure_id: procedure3.id
}

payor_procedure4 = Repo.insert! %PayorProcedure{
  description: "5HIAA (PLASMA)",
  code: "LAB0503016",
  payor_id: payor_maxicare.id,
  procedure_id: procedure4.id
}

payor_procedure5 = Repo.insert! %PayorProcedure{
  description: "(ACP) ACID PHOSPHATASE",
  code: "S2196",
  payor_id: payor_maxicare.id,
  procedure_id: procedure5.id
}

payor_procedure6 = Repo.insert! %PayorProcedure{
  description: "ACTH",
  code: "S2737",
  payor_id: payor_maxicare.id,
  procedure_id: procedure6.id
}

IO.puts "Adding Industry"
# Bank
Repo.insert!(%Industry{code: "A01 - ADVERTISING"})
Repo.insert!(%Industry{code: "A02 - AGRICULTURAL SERVICES"})
Repo.insert!(%Industry{code: "A03 - AGRICULTURE & AGRICULTURAL CROPS PRODUCT"})
Repo.insert!(%Industry{code: "A04 - AIRLINE"})
Repo.insert!(%Industry{code: "A05 - ANIMAL FEED MILLING"})
Repo.insert!(%Industry{code: "A06 - AUTOMOBILE SALES"})
Repo.insert!(%Industry{code: "A07 - AGENCY"})
Repo.insert!(%Industry{code: "B01 - BANKING & FINANCE"})
Repo.insert!(%Industry{code: "B02 - BROADCASTING & MEDIA"})
Repo.insert!(%Industry{code: "B03 - BROKERS & AGENT"})
Repo.insert!(%Industry{code: "C01 - CABLE SALES & SERVICES"})
Repo.insert!(%Industry{code: "C02 - CLERICAL OCCUPATIONS"})
Repo.insert!(%Industry{code: "C03 - COMMUNICATION & TELECOMMUNICATION SERVICES"})
Repo.insert!(%Industry{code: "C04 - COMMUNITY, SOCIAL, & PERSONAL SERVICES"})
Repo.insert!(%Industry{code: "C05 - CONSTRUCTION"})
Repo.insert!(%Industry{code: "C06 - CONSULTANCY"})
Repo.insert!(%Industry{code: "C07 - CALIBRATION SERVICES AND TRADING"})
Repo.insert!(%Industry{code: "C08 - CONDO"})

IO.puts "Adding Organization"
# Organization

for i <- 1..3 do
  Repo.insert!(%Organization{name: "Organization #{i}"})
end

# Diagnoses
IO.puts "Adding Diagnoses"
diagnosis1 = Repo.insert!(%Diagnosis{
  code: "A00.0",
  description: "CHOLERA: Cholera due to Vibrio cholerae 01, biovar cholerae",
  group_description: "CHOLERA",
  type: "Dreaded",
  congenital: "N"
})
diagnosis2 = Repo.insert!(%Diagnosis{
  code: "A00.1",
  description: "CHOLERA: Cholera due to Vibrio cholerae 01, biovar eltor",
  group_description: "CHOLERA",
  type: "Dreaded",
  congenital: "N"
})
diagnosis3 = Repo.insert!(%Diagnosis{
  code: "A01.0",
  description: "TYPHOID AND PARATYPHOID FEVERS: Typhoid fever",
  group_description: "TYPHOID AND PARATYPHOID FEVERS",
  type: "Dreaded",
  congenital: "N"
})
Repo.insert!(%Diagnosis{
  code: "A01.1",
  description: "TYPHOID AND PARATYPHOID FEVERS: Paratyphoid fever A",
  group_description: "TYPHOID AND PARATYPHOID FEVERS",
  type: "Dreaded",
  congenital: "N"
})
Repo.insert!(%Diagnosis{
  code: "A01.2",
  description: "TYPHOID AND PARATYPHOID FEVERS: Paratyphoid fever B",
  group_description: "TYPHOID AND PARATYPHOID FEVERS",
  type: "Dreaded",
  congenital: "N"
})
Repo.insert!(%Diagnosis{
  code: "A01.3",
  description: "TYPHOID AND PARATYPHOID FEVERS: Paratyphoid fever C",
  group_description: "TYPHOID AND PARATYPHOID FEVERS",
  type: "Dreaded",
  congenital: "N"
})
Repo.insert!(%Diagnosis{
  code: "A01.4",
  description: "TYPHOID AND PARATYPHOID FEVERS: Paratyphoid fever, unspecified",
  group_description: "TYPHOID AND PARATYPHOID FEVERS",
  type: "Dreaded",
  congenital: "N"
})
Repo.insert!(%Diagnosis{
  code: "A02.0",
  description: "OTHER SALMONELLA INFECTIONS: Salmonella enteritis",
  group_description: "OTHER SALMONELLA INFECTIONS",
  type: "Dreaded",
  congenital: "N"
})
Repo.insert!(%Diagnosis{
  code: "A02.1",
  description: "OTHER SALMONELLA INFECTIONS: Salmonella septicaemia",
  group_description: "OTHER SALMONELLA INFECTIONS",
  type: "Dreaded",
  congenital: "N"
})
Repo.insert!(%Diagnosis{
  code: "A02.2",
  description: "OTHER SALMONELLA INFECTIONS: Localized salmonella infections",
  group_description: "OTHER SALMONELLA INFECTIONS",
  type: "Dreaded",
  congenital: "N"
})
Repo.insert!(%Diagnosis{
  code: "A02.8",
  description: "OTHER SALMONELLA INFECTIONS: Other specified salmonella infections",
  group_description: "OTHER SALMONELLA INFECTIONS",
  type: "Dreaded",
  congenital: "N"
})
Repo.insert!(%Diagnosis{
  code: "A02.9",
  description: "OTHER SALMONELLA INFECTIONS: Salmonella infection, unspecified",
  group_description: "OTHER SALMONELLA INFECTIONS",
  type: "Dreaded",
  congenital: "N"
})
Repo.insert!(%Diagnosis{
  code: "A03.0",
  description: "SHIGELLOSIS: Shigellosis due to Shigella dysenteriae",
  group_description: "SHIGELLOSIS",
  type: "Dreaded",
  congenital: "N"
})
Repo.insert!(%Diagnosis{
  code: "A03.1",
  description: "SHIGELLOSIS: Shigellosis due to Shigella flexneri",
  group_description: "SHIGELLOSIS",
  type: "Dreaded",
  congenital: "N"
})
Repo.insert!(%Diagnosis{
  code: "A03.2",
  description: "SHIGELLOSIS: Shigellosis due to Shigella boydii",
  group_description: "SHIGELLOSIS",
  type: "Dreaded",
  congenital: "N"
})
Repo.insert!(%Diagnosis{
  code: "A03.3",
  description: "SHIGELLOSIS: Shigellosis due to Shigella sonnei",
  group_description: "SHIGELLOSIS",
  type: "Dreaded",
  congenital: "N"
})
Repo.insert!(%Diagnosis{
  code: "A03.8",
  description: "SHIGELLOSIS: Other shigellosis",
  group_description: "SHIGELLOSIS",
  type: "Dreaded",
  congenital: "N"
})
Repo.insert!(%Diagnosis{
  code: "A03.9",
  description: "SHIGELLOSIS: Shigellosis, unspecified",
  group_description: "SHIGELLOSIS",
  type: "Dreaded",
  congenital: "N"
})
Repo.insert!(%Diagnosis{
  code: "A04.0",
  description: "OTHER BACTERIAL INTESTINAL INFECTIONS: Enteropathogenic Escherichia coli infection",
  group_description: "OTHER BACTERIAL INTESTINAL INFECTIONS",
  type: "Dreaded",
  congenital: "N"
})
Repo.insert!(%Diagnosis{
  code: "A04.1",
  description: "OTHER BACTERIAL INTESTINAL INFECTIONS: Enterotoxigenic Escherichia coli infection",
  group_description: "OTHER BACTERIAL INTESTINAL INFECTIONS",
  type: "Dreaded",
  congenital: "N"
})

# Benefit General
accenture_benefit = Repo.insert!(%Benefit{
  code: "B101",
  name: "Accenture Benefit",
  created_by_id: user.id,
  updated_by_id: user.id,
  category: "Health",
  step: 5
})

Repo.insert!(%BenefitCoverage{
  benefit_id: accenture_benefit.id,
  coverage_id: coverage_opconsult.id
})

Repo.insert!(%BenefitCoverage{
  benefit_id: accenture_benefit.id,
  coverage_id: coverage_oplab.id
})

Repo.insert!(%BenefitCoverage{
  benefit_id: accenture_benefit.id,
  coverage_id: coverage_emergency.id
})

# Benefit Procedures

Repo.insert!(%BenefitProcedure{
  benefit_id: accenture_benefit.id,
  procedure_id: procedure1.id
})

Repo.insert!(%BenefitProcedure{
  benefit_id: accenture_benefit.id,
  procedure_id: procedure2.id
})

Repo.insert!(%BenefitProcedure{
  benefit_id: accenture_benefit.id,
  procedure_id: procedure3.id
})

# Benefit Limits
# Repo.insert!(%BenefitLimit{
#   benefit_id: accenture_benefit.id,
#   coverage_id: coverage_opconsult.id,
#   limit_type: "Peso",
#   amount: 1200
# })

# Repo.insert!(%BenefitLimit{
#   benefit_id: accenture_benefit.id,
#   coverage_id: coverage_oplab.id,
#   limit_type: "Peso",
#   amount: 1200
# })

# Repo.insert!(%BenefitLimit{
#   benefit_id: accenture_benefit.id,
#   coverage_id: coverage_emergency.id,
#   limit_type: "Peso",
#   amount: 1200
# })

# Benefit Diagnosis

Repo.insert(%BenefitDiagnosis{
  benefit_id: accenture_benefit.id,
  diagnosis_id: diagnosis1.id
})

Repo.insert(%BenefitDiagnosis{
  benefit_id: accenture_benefit.id,
  diagnosis_id: diagnosis2.id
})

Repo.insert(%BenefitDiagnosis{
  benefit_id: accenture_benefit.id,
  diagnosis_id: diagnosis3.id
})

# Benefit General
medilink_benefit = Repo.insert!(%Benefit{
  code: "B102",
  name: "Medilink Benefit",
  created_by_id: user.id,
  updated_by_id: user.id,
  category: "Health",
  step: 5
})

Repo.insert!(%BenefitCoverage{
  benefit_id: medilink_benefit.id,
  coverage_id: coverage_opconsult.id
})

Repo.insert!(%BenefitCoverage{
  benefit_id: medilink_benefit.id,
  coverage_id: coverage_oplab.id
})

Repo.insert!(%BenefitCoverage{
  benefit_id: medilink_benefit.id,
  coverage_id: coverage_emergency.id
})

# Benefit Procedures

Repo.insert!(%BenefitProcedure{
  benefit_id: medilink_benefit.id,
  procedure_id: procedure1.id
})

Repo.insert!(%BenefitProcedure{
  benefit_id: medilink_benefit.id,
  procedure_id: procedure2.id
})

Repo.insert!(%BenefitProcedure{
  benefit_id: medilink_benefit.id,
  procedure_id: procedure3.id
})

# Benefit Limits
# Repo.insert!(%BenefitLimit{
#   benefit_id: medilink_benefit.id,
#   coverage_id: coverage_opconsult.id,
#   limit_type: "Peso",
#   amount: 1200
# })

# Repo.insert!(%BenefitLimit{
#   benefit_id: medilink_benefit.id,
#   coverage_id: coverage_oplab.id,
#   limit_type: "Peso",
#   amount: 1200
# })

# Repo.insert!(%BenefitLimit{
#   benefit_id: medilink_benefit.id,
#   coverage_id: coverage_emergency.id,
#   limit_type: "Peso",
#   amount: 1200
# })

# Benefit Diagnosis

Repo.insert(%BenefitDiagnosis{
  benefit_id: medilink_benefit.id,
  diagnosis_id: diagnosis1.id
})

Repo.insert(%BenefitDiagnosis{
  benefit_id: medilink_benefit.id,
  diagnosis_id: diagnosis2.id
})

Repo.insert(%BenefitDiagnosis{
  benefit_id: medilink_benefit.id,
  diagnosis_id: diagnosis3.id
})

# Benefit General
ibm_benefit = Repo.insert!(%Benefit{
  code: "B103",
  name: "IBM Benefit",
  created_by_id: user.id,
  updated_by_id: user.id,
  category: "Riders",
  step: 5
})

Repo.insert!(%BenefitCoverage{
  benefit_id: ibm_benefit.id,
  coverage_id: coverage_acu.id
})

# Benefit Procedures

Repo.insert!(%BenefitProcedure{
  benefit_id: ibm_benefit.id,
  procedure_id: procedure1.id,
  gender: "Male & Female",
  age_from: 20,
  age_to: 30
})

Repo.insert!(%BenefitProcedure{
  benefit_id: ibm_benefit.id,
  procedure_id: procedure2.id,
  gender: "Male & Female",
  age_from: 20,
  age_to: 35
})

# Benefit Limits
# Repo.insert!(%BenefitLimit{
#   benefit_id: ibm_benefit.id,
#   coverage_id: coverage_acu.id,
#   limit_type: "Peso",
#   amount: 1200
# })

# Benefit Diagnosis
Repo.insert(%BenefitDiagnosis{
  benefit_id: ibm_benefit.id,
  diagnosis_id: diagnosis1.id
})

Repo.insert(%BenefitDiagnosis{
  benefit_id: ibm_benefit.id,
  diagnosis_id: diagnosis2.id
})

Repo.insert(%BenefitDiagnosis{
  benefit_id: ibm_benefit.id,
  diagnosis_id: diagnosis3.id
})

#ProductBenefit
Repo.insert! %ProductBenefit{
  product_id: product1.id,
  benefit_id: ibm_benefit.id
}
Repo.insert! %ProductBenefit{
  product_id: product1.id,
  benefit_id: medilink_benefit.id
}
Repo.insert! %ProductBenefit{
  product_id: product1.id,
  benefit_id: accenture_benefit.id
}
Repo.insert! %ProductBenefit{
  product_id: product2.id,
  benefit_id: ibm_benefit.id
}
Repo.insert! %ProductBenefit{
  product_id: product3.id,
  benefit_id: ibm_benefit.id
}

#Specializations
Repo.insert! %Specialization{
  name: "Dermatology"
}
Repo.insert! %Specialization{
  name: "General Surgery"
}
Repo.insert! %Specialization{
  name: "Otolaryngology-Head and Neck Surgery"
}
Repo.insert! %Specialization{
  name: "Cardiothoracic Surgery"
}
Repo.insert! %Specialization{
  name: "Vascular Surgery"
}
Repo.insert! %Specialization{
  name: "Radiology"
}
Repo.insert! %Specialization{
  name: "Pathology"
}
Repo.insert! %Specialization{
  name: "Neurosurgery"
}
Repo.insert! %Specialization{
  name: "Sonology"
}
Repo.insert! %Specialization{
  name: "Pediatrics"
}
Repo.insert! %Specialization{
  name: "Resident Physician"
}
Repo.insert! %Specialization{
  name: "Internal Medicine"
}
Repo.insert! %Specialization{
  name: "General Medicine"
}
Repo.insert! %Specialization{
  name: "Family Medicine"
}
Repo.insert! %Specialization{
  name: "Opthalmology"
}
Repo.insert! %Specialization{
  name: "Optometry"
}
Repo.insert! %Specialization{
  name: "Pulmonology"
}
Repo.insert! %Specialization{
  name: "Obstetrics and Gynecology"
}
Repo.insert! %Specialization{
  name: "Occupational Medicine"
}
Repo.insert! %Specialization{
  name: "Psychiatry"
}
Repo.insert! %Specialization{
  name: "Neurology"
}
Repo.insert! %Specialization{
  name: "Orthopedic Surgery"
}
Repo.insert! %Specialization{
  name: "Anesthesiology"
}
Repo.insert! %Specialization{
  name: "Oncology"
}
Repo.insert! %Specialization{
  name: "Cardiology"
}
Repo.insert! %Specialization{
  name: "Physical Medicine and Rehabilitation"
}
Repo.insert! %Specialization{
  name: "Emergency Medicine"
}
Repo.insert! %Specialization{
  name: "Dentistry"
}

#Vat Status
Repo.insert! %Dropdown{
  type: "VAT Status",
  text: "20% VAT-able",
  value: "20% VAT-able"
}
Repo.insert! %Dropdown{
  type: "VAT Status",
  text: "Fully VAT-able",
  value: "Fully VAT-able"
}
Repo.insert! %Dropdown{
  type: "VAT Status",
  text: "VAT Exempt",
  value: "VAT Exempt"
}
Repo.insert! %Dropdown{
  type: "VAT Status",
  text: "VAT-able",
  value: "VAT-able"
}
Repo.insert! %Dropdown{
  type: "VAT Status",
  text: "Zero-Rated",
  value: "Zero-Rated"
}

#Prescription Clause
Repo.insert! %Dropdown{
  type: "Prescription Clause",
  text: "No Provision",
  value: "No Provision"
}
Repo.insert! %Dropdown{
  type: "Prescription Clause",
  text: "Non-Payment beyond 30 days",
  value: "Non-Payment beyond 30 days"
}
Repo.insert! %Dropdown{
  type: "Prescription Clause",
  text: "Percentage deduction - 1% deduction beyond 30 days",
  value: "Percentage deduction - 1% deduction beyond 30 days"
}

#Payment Mode
Repo.insert! %Dropdown{
  type: "Payment Mode",
  value: "A",
  text: "ANNUAL"
}
Repo.insert! %Dropdown{
  type: "Payment Mode",
  value: "D",
  text: "DAILY"
}
Repo.insert! %Dropdown{
  type: "Payment Mode",
  value: "H",
  text: "HOURLY"
}
Repo.insert! %Dropdown{
  type: "Payment Mode",
  value: "M",
  text: "MONTHLY"
}

#Releasing Mode
Repo.insert! %Dropdown{
  type: "Releasing Mode",
  value: "A",
  text: "ADA"
}
Repo.insert! %Dropdown{
  type: "Releasing Mode",
  value: "C",
  text: "Courier"
}
Repo.insert! %Dropdown{
  type: "Releasing Mode",
  value: "M",
  text: "Messenger"
}
Repo.insert! %Dropdown{
  type: "Releasing Mode",
  value: "P",
  text: "Pick-Up"
}

#Facility Type
Repo.insert! %Dropdown{
  type: "Facility Type",
  text: "AMBULANCE",
  value: "A"
}
Repo.insert! %Dropdown{
  type: "Facility Type",
  text: "CLINIC-BASED",
  value: "CB"
}
Repo.insert! %Dropdown{
  type: "Facility Type",
  value: "DP",
  text: "DENTAL PROVIDER"
}
Repo.insert! %Dropdown{
  type: "Facility Type",
  value: "HB",
  text: "HOSPITAL-BASED"
}
Repo.insert! %Dropdown{
  type: "Facility Type",
  value: "PCC",
  text: "PRIMARY CARE CENTER"
}

# Facility Category
Repo.insert!(%Dropdown{
  type: "Facility Category",
  value: "TER_ACU",
  text: "TERTIARY + ACU"
})

Repo.insert!(%Dropdown{
  type: "Facility Category",
  value: "FUL_ACU",
  text: "FULL SERVICE + ACU"
})

Repo.insert!(%Dropdown{
  type: "Facility Category",
  value: "TER",
  text: "TERTIARY"
})

# Practitioner Status
Repo.insert!(%Dropdown{
  type: "Practitioner Status",
  value: "Accredited",
  text: "Accredited"
})

Repo.insert!(%Dropdown{
  type: "Practitioner Status",
  value: "Blacklisted",
  text: "Blacklisted"
})

Repo.insert!(%Dropdown{
  type: "Practitioner Status",
  value: "Disaccredited",
  text: "Disaccredited"
})

Repo.insert!(%Dropdown{
  type: "Practitioner Status",
  value: "Non-accredited",
  text: "Non-accredited"
})

Repo.insert!(%Dropdown{
  type: "Practitioner Status",
  value: "Pending",
  text: "Pending"
})

Repo.insert!(%Dropdown{
  type: "Practitioner Status",
  value: "Probationary",
  text: "Probationary"
})

Repo.insert!(%Dropdown{
  type: "Tel Prefix",
  value: "32",
  text: "32"
})

Repo.insert!(%Dropdown{
  type: "Tel Prefix",
  value: "03",
  text: "03"
})

Repo.insert!(%Dropdown{
  type: "Tel Prefix",
  value: "05",
  text: "05"
})

Repo.insert!(%Dropdown{
  type: "Tel Prefix",
  value: "88",
  text: "88"
})

#Fax Prefix
Repo.insert!(%Dropdown{
  type: "Fax Prefix",
  value: "02",
  text: "02"
})

Repo.insert!(%Dropdown{
  type: "Fax Prefix",
  value: "32",
  text: "32"
})

Repo.insert!(%Dropdown{
  type: "Fax Prefix",
  value: "03",
  text: "03"
})

Repo.insert!(%Dropdown{
  type: "Fax Prefix",
  value: "05",
  text: "05"
})

Repo.insert!(%Dropdown{
  type: "Fax Prefix",
  value: "88",
  text: "88"
})
Repo.insert!(%Dropdown{
  type: "Practitioner Status",
  value: "Suspended",
  text: "Suspended"
})

# CP Clearance
Repo.insert!(%Dropdown{
  type: "CP Clearance",
  value: "Medical Indication",
  text: "Medical Indication"
})

Repo.insert!(%Dropdown{
  type: "CP Clearance",
  value: "Operative Monitoring",
  text: "Operative Monitoring"
})

Repo.insert!(%Dropdown{
  type: "CP Clearance",
  value: "Routine",
  text: "Routine"
})

Repo.insert!(%Dropdown{
  type: "CP Clearance",
  value: "Regular",
  text: "Regular"
})
