alias Innerpeace.Db.{
  ApplicationSeeder,
  UserSeeder,
  DropdownSeeder,
  PermissionSeeder,
  RoleSeeder,
  ApplicationSeeder,
  RoleApplicationSeeder,
  UserRoleSeeder,
  RolePermissionSeeder,
  PayorSeeder,
  PayorCardBinSeeder,
  CoverageSeeder,
  ApiAddressSeeder,
  TranslationSeeder,
  IndustrySeeder,
  ProcedureCategorySeeder,
  AccountGroupSeeder,
  AccountSeeder,
  MemberSeeder
}

#Create Applications
IO.puts "Seeding applications..."
application_data = [
  #1
  %{
    name: "PayorLink"
  },
  #2
  %{
    name: "AccountLink"
  },
  #3
  %{
    name: "ProviderLink"
  },
  #4
  %{
    name: "DentalLink"
  },
  #5
  %{
    name: "MemberLink"
  },
  #6
  %{
    name: "RegistrationLink"
  }
]
[a1, a2, a3, a4, a5, a6] = ApplicationSeeder.seed(application_data)

#Create Users
IO.puts "Seeding users..."
user_data = [
  %{
    #1
    username: "masteradmin",
    password: "1nnerpe@cE",
    is_admin: true,
    email: "mediadmin@medi.com",
    mobile: "09277435476",
    first_name: "Admin",
    middle_name: "is",
    last_name: "trator",
    gender: "male"
  },
]

[u1] = UserSeeder.seed(user_data)

#Create Dropdown
IO.puts "Seeding Dropdown..."
dropdown_data = [
  #VAT Status
  %{
    #1
    type: "VAT Status",
    text: "Vatable",
    value: "Vatable"
  },
  %{
    #2
    type: "VAT Status",
    text: "Non-Vatable",
    value: "Non-Vatable"
  },
  #Precription Clause
  %{
    #6
    type: "Prescription Clause",
    text: "No Provision",
    value: "No Provision"
  },
  %{
    #7
    type: "Prescription Clause",
    text: "Non-Payment beyond 30 days",
    value: "Non-Payment beyond 30 days"
  },
  %{
    #8
    type: "Prescription Clause",
    text: "Percentage deduction - 1% deduction beyond 30 days",
    value: "Percentage deduction - 1% deduction beyond 30 days"
  },

  #Payment Mode
  %{
    #9
    type: "Payment Mode",
    value: "A",
    text: "ANNUAL"
  },
  %{
    #10
    type: "Payment Mode",
    value: "D",
    text: "DAILY"
  },
  %{
    #11
    type: "Payment Mode",
    value: "H",
    text: "HOURLY"
  },
  %{
    #12
    type: "Payment Mode",
    value: "M",
    text: "MONTHLY"
  },

  #Releasing Mode
  %{
    #13
    type: "Releasing Mode",
    value: "A",
    text: "ADA"

  },
  %{
    #14
    type: "Releasing Mode",
    value: "C",
    text: "Courier"

  },
  %{
    #15
    type: "Releasing Mode",
    value: "M",
    text: "Messenger"

  },
  %{
    #16
    type: "Releasing Mode",
    value: "P",
    text: "Pick-Up"

  },

  #Facility Type
  %{
    #17
    type: "Facility Type",
    text: "AMBULANCE",
    value: "A"

  },
  %{
    #18
    type: "Facility Type",
    text: "CLINIC-BASED",
    value: "CB"

  },
  %{
    #19
    type: "Facility Type",
    value: "DP",
    text: "DENTAL PROVIDER"

  },
  %{
    #20
    type: "Facility Type",
    value: "HB",
    text: "HOSPITAL-BASED"

  },
  %{
    #21
    type: "Facility Type",
    value: "PCC",
    text: "PRIMARY CARE CENTER"

  },

  #Facility Category
  %{
    #22
    type: "Facility Category",
    value: "TER_ACU",
    text: "TERTIARY + ACU"
  },
  %{
    #23
    type: "Facility Category",
    value: "FUL_ACU",
    text: "FULL SERVICE + ACU"
  },
  %{
    #24
    type: "Facility Category",
    value: "TER",
    text: "TERTIARY"
  },

  #Practitioner Status
  %{
    #25
    type: "Practitioner Status",
    value: "Affiliated",
    text: "Affiliated"
  },
  %{
    #26
    type: "Practitioner Status",
    value: "Blacklisted",
    text: "Blacklisted"
  },
  %{
    #27
    type: "Practitioner Status",
    value: "Disaffiliated",
    text: "Disaffiliated"
  },
  %{
    #28
    type: "Practitioner Status",
    value: "Non-affiliated",
    text: "Non-affiliated"
  },
  %{
    #29
    type: "Practitioner Status",
    value: "Pending",
    text: "Pending"
  },
  %{
    #30
    type: "Practitioner Status",
    value: "Probationary",
    text: "Probationary"
  },
  %{
    #31
    type: "Practitioner Status",
    value: "Suspended",
    text: "Suspended"
  },
  %{
    #32
    type: "CP Clearance",
    value: "Medical Indication",
    text: "Medical Indication"
  },
  %{
    #33
    type: "CP Clearance",
    value: "Operative Monitoring",
    text: "Operative Monitoring"
  },
  %{
    #34
    type: "CP Clearance",
    value: "Routine",
    text: "Routine"
  },
  %{
    #35
    type: "CP Clearance",
    value: "Regular",
    text: "Regular"
  },

  #Special Approval
  %{
    #36
    type: "Special Approval",
    value: "Ex-Gratia",
    text: "Ex-Gratia"
  },
  %{
    #37
    type: "Special Approval",
    value: "ASO + Limit",
    text: "ASO + Limit"
  },
  %{
    #38
    type: "Special Approval",
    value: "ASO Guarantee",
    text: "ASO Guarantee"
  },
  %{
    #39
    type: "Special Approval",
    value: "Corporate Guarantee + Limit",
    text: "Corporate Guarantee + Limit"
  },
  %{
    #40
    type: "Special Approval",
    value: "Advance Limit",
    text: "Advance Limit"
  },
  %{
    #41
    type: "Special Approval",
    value: "ASO Override",
    text: "ASO Override"
  },
  %{
    #42
    type: "Special Approval",
    value: "Corporate Guarantee",
    text: "Corporate Guarantee"
  },
  %{
    #43
    type: "Special Approval",
    value: "Fee for Service + Limit",
    text: "Fee for Service + Limit"
  },
  %{
    #44
    type: "Special Approval",
    value: "Ex-Gratia + Limit",
    text: "Fee for Service"
  },

  #Payment Mode
  %{
    #45
    type: "Mode of Payment",
    value: "Bank",
    text: "Bank"
  },
  %{
    #46
    type: "Mode of Payment",
    value: "Check",
    text: "Check"
  },
  %{
    #47
    type: "Mode of Payment",
    value: "Auto-Credit",
    text: "Auto-Credit"
  },
  %{
    #48
    type: "Facility Type",
    value: "CORP",
    text: "CORPORATE"

  },
  %{
    #49
    type: "Facility Type",
    value: "DC",
    text: "DENTAL CLINIC"

  },
  %{
    #50
    type: "Facility Type",
    value: "MC",
    text: "MEDICAL MERCHANT"

  },
  %{
    #51
    type: "Facility Type",
    value: "MOBILE",
    text: "MOBILE"

  },
  %{
    #52
    type: "Facility Type",
    value: "OP",
    text: "ONSITE PHLEBOTOMY"

  },
  %{
    #53
    type: "Facility Type",
    value: "OF",
    text: "OUTSOURCED FACILITY"

  },
  %{
    #54
    type: "Facility Type",
    value: "PHARMACY",
    text: "PHARMACY"

  },
  %{
    #55
    type: "Facility Type",
    value: "WELLNESS",
    text: "WELLNESS"

  },
  %{
    #56
    type: "Facility Type",
    value: "OTHERS",
    text: "OTHERS"

  },

  # ADDITIONAL FACILITY CATEGORIES
  %{
    #57
    type: "Facility Category",
    value: "TER_ACU_MOB",
    text: "PRIMARY + ACU + MOBILE"
  },
  %{
    #58
    type: "Facility Category",
    value: "SEC_ACU_MOB",
    text: "SECONDARY + ACU + MOBILE"
  },
  %{
    #59
    type: "Facility Category",
    value: "PRIM_ACU_MOB",
    text: "PRIMARY + ACU + MOBILE"
  },
  %{
    #60
    type: "Facility Category",
    value: "PRIM_ACU_MOB",
    text: "PRIMARY + ACU + MOBILE"
  },
  %{
    #61
    type: "Facility Category",
    value: "SEC",
    text: "SECONDARY"
  },
  %{
    #62
    type: "Facility Category",
    value: "PRIM_ACU",
    text: "PRIMARY + ACU"
  },
  %{
    #63
    type: "Facility Category",
    value: "SEC_ACU",
    text: "SECONDARY + ACU"
  },
  %{
    #64
    type: "Facility Category",
    value: "PRIM_MOB",
    text: "PRIMARY + MOBILE"
  },
  %{
    #65
    type: "Facility Category",
    value: "SEC_MOB",
    text: "SECONDARY + MOBILE"
  },
  %{
    #66
    type: "Facility Category",
    value: "TER_MOB",
    text: "TERTIARY + MOBILE"
  },

  # ADDITIONAL PRESCRIPTION CLAUSE
  %{
    #67
    type: "Prescription Clause",
    text: "Non-Payment beyond 45 days",
    value: "Non-Payment beyond 45 days"
  },
  %{
    #68
    type: "Prescription Clause",
    text: "Non-Payment beyond 60 days",
    value: "Non-Payment beyond 60 days"
  },
  %{
    #69
    type: "Prescription Clause",
    text: "Non-Payment beyond 90 days",
    value: "Non-Payment beyond 90 days"
  },
  %{
    #70
    type: "Prescription Clause",
    text: "Percentage deduction - 1% deduction beyond 45 days",
    value: "Percentage deduction - 1% deduction beyond 45 days"
  },
  %{
    #71
    type: "Prescription Clause",
    text: "Percentage deduction - 1% deduction beyond 60 days",
    value: "Percentage deduction - 1% deduction beyond 60 days"
  },
  %{
    #72
    type: "Prescription Clause",
    text: "Percentage deduction - 1% deduction beyond 90 days",
    value: "Percentage deduction - 1% deduction beyond 90 days"
  },
  %{
    #73
    type: "Prescription Clause",
    text: "Percentage deduction - 1.5% deduction beyond 30 days",
    value: "Percentage deduction - 1.5% deduction beyond 30 days"
  },
  %{
    #74
    type: "Prescription Clause",
    text: "Percentage deduction - 3% deduction beyond 30 days",
    value: "Percentage deduction - 3% deduction beyond 30 days"
  },
  %{
    #75
    type: "Prescription Clause",
    text: "Percentage deduction - 1% deduction per month of delay",
    value: "Percentage deduction - 1% deduction per month of delay"
  },
  %{
    #76
    type: "Prescription Clause",
    text: "Percentage deduction - 1% deduction per month of delay beyond 60 days",
    value: "Percentage deduction - 1% deduction per month of delay beyond 60 days"
  },
  %{
    #77
    type: "Prescription Clause",
    text: "Percentage deduction - 1% deduction per month of delay beyond 45 days; Non-payment beyond 60 days",
    value: "Percentage deduction - 1% deduction per month of delay beyond 45 days; Non-payment beyond 60 days"
  },
  %{
    #78
    type: "Prescription Clause",
    text: "Percentage deduction - 1% deduction per month of delay; Non-payment beyond 60 days",
    value: "Percentage deduction - 1% deduction per month of delay; Non-payment beyond 60 days"
  },
  %{
    #79
    type: "Prescription Clause",
    text: "Percentage deduction - 1% deduction per month of delay; Non-payment beyond 90 days",
    value: "Percentage deduction - 1% deduction per month of delay; Non-payment beyond 90 days"
  },
  %{
    #80
    type: "Prescription Clause",
    text: "Percentage deduction - 2% deduction per month of delay",
    value: "Percentage deduction - 2% deduction per month of delay"
  },

  # Facility Service Fee Types
  %{
    #81
    type: "Facility Service Fee",
    text: "Fixed Fee",
    value: "Fixed Fee"
  },
  %{
    #82
    type: "Facility Service Fee",
    text: "Discount Rate",
    value: "MDR"
  },
  %{
    #83
    type: "Facility Service Fee",
    text: "No Discount Rate",
    value: "No MDR"
  },
]

[d1, d2,
 d6, d7, d8, d9, d10,
 d11, d12, d13, d14, d15,
 d16, d17, d18, d19, d20,
 d21, d22, d23, d24, d25,
 d26, d27, d28, d29, d30,
 d31, d32, d33, d34, d35,
 d36, d37, d38, d39, d40,
 d41, d42, d43, d44, d45,
 d46, d47, d48, d49, d50,
 d51, d52, d53, d54, d55,
 d56, d57, d58, d59, d60,
 d61, d62, d63, d64, d65,
 d66, d67, d68, d69, d70,
 d71, d72, d73, d74, d75,
 d76, d77, d78, d79, d80,
 d81, d82, d83] =
   DropdownSeeder.seed(dropdown_data)

   #End of Dropdown

   #Create Permissions
   IO.puts "Seeding permissions..."
   permission_data = [
     #1
     %{
       name: "Manage Accounts",
       module: "Accounts",
       keyword: "manage_accounts",
       application_id: a1.id,
       status: "sample",
       description: "sample"
     },
     #2
     %{
       name: "Manage Products",
       module: "Products",
       keyword: "manage_products",
       application_id: a1.id,
       status: "sample",
       description: "sample"
     },
     #3
     %{
       name: "Manage Benefits",
       module: "Benefits",
       keyword: "manage_benefits",
       application_id: a1.id,
       status: "sample",
       description: "sample"
     },
     #4
     %{
       name: "Manage Users",
       module: "Users",
       keyword: "manage_users",
       application_id: a1.id,
       status: "sample",
       description: "sample"
     },
     #5
     %{
       name: "Manage Roles",
       module: "Roles",
       keyword: "manage_roles",
       application_id: a1.id,
       status: "sample",
       description: "sample"
     },
     #6
     %{
       name: "Manage Diseases",
       module: "Diseases",
       keyword: "manage_diseases",
       application_id: a1.id,
       status: "sample",
       description: "sample"
     },
     #7
     %{
       name: "Manage Procedures",
       module: "Procedures",
       keyword: "manage_procedures",
       application_id: a1.id,
       status: "sample",
       description: "sample"
     },
     #8
     %{
       name: "Manage Facilities",
       module: "Facilities",
       keyword: "manage_facilities",
       application_id: a1.id,
       status: "sample",
       description: "sample"
     },
     #9
     %{
       name: "Manage Clusters",
       module: "Clusters",
       keyword: "manage_clusters",
       application_id: a1.id,
       status: "sample",
       description: "sample"
     },
     #10
     %{
       name: "Manage Coverages",
       module: "Coverages",
       keyword: "manage_coverages",
       application_id: a1.id,
       status: "sample",
       description: "sample"
     },
     #11
     %{
       name: "Manage Exclusions",
       module: "Exclusions",
       keyword: "manage_exclusions",
       application_id: a1.id,
       status: "sample",
       description: "sample"
     },
     #12
     %{
       name: "Manage Case Rates",
       module: "CaseRates",
       keyword: "manage_caserates",
       application_id: a1.id,
       status: "sample",
       description: "sample"
     },
     #13
     %{
       name: "Access Accounts",
       module: "Accounts",
       keyword: "access_accounts",
       application_id: a1.id,
       status: "sample",
       description: "sample"
     },
     #14
     %{
       name: "Access Products",
       module: "Products",
       keyword: "access_products",
       application_id: a1.id,
       status: "sample",
       description: "sample"
     },
     #15
     %{
       name: "Access Benefits",
       module: "Benefits",
       keyword: "access_benefits",
       application_id: a1.id,
       status: "sample",
       description: "sample"
     },
     #16
     %{
       name: "Access Users",
       module: "Users",
       keyword: "access_users",
       application_id: a1.id,
       status: "sample",
       description: "sample"
     },
     #17
     %{
       name: "Access Roles",
       module: "Roles",
       keyword: "access_roles",
       application_id: a1.id,
       status: "sample",
       description: "sample"
     },
     #18
     %{
       name: "Access Diseases",
       module: "Diseases",
       keyword: "access_diseases",
       application_id: a1.id,
       status: "sample",
       description: "sample"
     },
     #19
     %{
       name: "Access Procedures",
       module: "Procedures",
       keyword: "access_procedures",
       application_id: a1.id,
       status: "sample",
       description: "sample"
     },
     #20
     %{
       name: "Access Facilities",
       module: "Facilities",
       keyword: "access_facilities",
       application_id: a1.id,
       status: "sample",
       description: "sample"
     },
     #21
     %{
       name: "Access Clusters",
       module: "Clusters",
       keyword: "access_clusters",
       application_id: a1.id,
       status: "sample",
       description: "sample"
     },
     #22
     %{
       name: "Access Coverages",
       module: "Coverages",
       keyword: "access_coverages",
       application_id: a1.id,
       status: "sample",
       description: "sample"
     },
     #23
     %{
       name: "Access Exclusions",
       module: "Exclusions",
       keyword: "access_exclusions",
       application_id: a1.id,
       status: "sample",
       description: "sample"
     },
     #24
     %{
       name: "Manage Packages",
       module: "Packages",
       keyword: "manage_packages",
       application_id: a1.id,
       status: "sample",
       description: "sample"
     },
     #25
     %{
       name: "Access Packages",
       module: "Packages",
       keyword: "access_packages",
       application_id: a1.id,
       status: "sample",
       description: "sample"
     },
     #26
     %{
       name: "Access Case Rates",
       module: "CaseRates",
       keyword: "access_caserates",
       application_id: a1.id,
       status: "sample",
       description: "sample"
     },
     #27
     %{
       name: "Manage RUVs",
       module: "RUVs",
       keyword: "manage_ruvs",
       application_id: a1.id,
       status: "sample",
       description: "sample"
     },
     #28
     %{
       name: "Access RUVs",
       module: "RUVs",
       keyword: "access_ruvs",
       application_id: a1.id,
       status: "sample",
       description: "sample"
     },
     #29
     %{
       name: "Manage Authorizations",
       module: "Authorizations",
       keyword: "manage_authorizations",
       application_id: a1.id,
       status: "sample",
       description: "sample"
     },
     #30
     %{
       name: "Access Authorizations",
       module: "Authorizations",
       keyword: "access_authorizations",
       application_id: a1.id,
       status: "sample",
       description: "sample"
     },
     #31
     %{
       name: "Manage Rooms",
       module: "Rooms",
       keyword: "manage_rooms",
       application_id: a1.id,
       status: "sample",
       description: "sample"
     },
     #32
     %{
       name: "Access Rooms",
       module: "Rooms",
       keyword: "access_rooms",
       application_id: a1.id,
       status: "sample",
       description: "sample"
     },
     #33
     %{
       name: "Manage Practitioners",
       module: "Practitioners",
       keyword: "manage_practitioners",
       application_id: a1.id,
       status: "sample",
       description: "sample"
     },
     #34
     %{
       name: "Access Practitioners",
       module: "Practitioners",
       keyword: "access_practitioners",
       application_id: a1.id,
       status: "sample",
       description: "sample"
     },
     #35
     %{
       name: "Manage Members",
       module: "Members",
       keyword: "manage_members",
       application_id: a1.id,
       status: "sample",
       description: "sample"
     },
     #36
     %{
       name: "Access Members",
       module: "Members",
       keyword: "access_members",
       application_id: a1.id,
       status: "sample",
       description: "sample"
     },
     #37
     %{
       name: "Manage MemberLink",
       module: "MemberLink",
       keyword: "manage_memberlink",
       application_id: a5.id,
       status: "sample",
       description: "sample"
     },
     #38
     %{
       name: "Access MemberLink",
       module: "MemberLink",
       keyword: "access_memberlink",
       application_id: a5.id,
       status: "sample",
       description: "sample"
     },
     #39
     %{
       name: "Manage AccountLink",
       module: "AccountLink",
       keyword: "manage_accountlink",
       application_id: a2.id,
       status: "sample",
       description: "sample"
     },
     #40
     %{
       name: "Access AccountLink",
       module: "AccountLink",
       keyword: "access_accountlink",
       application_id: a2.id,
       status: "sample",
       description: "sample"
     },
     #41
     %{
       name: "Manage PF Batch",
       module: "PFBatch",
       keyword: "manage_pfbatch",
       application_id: a6.id,
       status: "sample",
       description: "sample"
     },
     #42
     %{
       name: "Access PF Batch",
       module: "PFBatch",
       keyword: "access_pfbatch",
       application_id: a6.id,
       status: "sample",
       description: "sample"
     },
     #43
     %{
       name: "Manage HB Batch",
       module: "HBBatch",
       keyword: "manage_hbbatch",
       application_id: a6.id,
       status: "sample",
       description: "sample"
     },
     #44
     %{
       name: "Access HB Batch",
       module: "HBBatch",
       keyword: "access_hbbatch",
       application_id: a6.id,
       status: "sample",
       description: "sample"
     }
   ]
   [p1, p2, p3, p4, p5,
    p6, p7, p8, p9, p10,
    p11, p12, p13, p14, p15,
    p16, p17, p18, p19, p20,
    p21, p22, p23, p24, p25,
    p26, p27, p28, p29, p30,
    p31, p32, p33, p34, p35,
    p36, p37, p38, p39, p40,
    p41, p42, p43, p44] =
      PermissionSeeder.seed(permission_data)

      #Create Roles
      IO.puts "Seeding roles..."
      role_data = [
        #1
        %{
          name: "UEF Processor",
          description: "this is a sample role",
          step: 4,
          created_by_id: u1.id
        },
        #2
        %{
          name: "UEF Supervisor",
          description: "this is a sample role",
          step: 4,
          created_by_id: u1.id
        },
        #3
        %{
          name: "UEF Manager",
          description: "this is a sample role",
          step: 4,
          created_by_id: u1.id
        },
        #4
        %{
          name: "Contact Ctr Non-Voice Front Line",
          description: "this is a sample role",
          step: 4,
          created_by_id: u1.id
        },
        #5
        %{
          name: "Contact Ctr Non-Voice Supervisor",
          description: "this is a sample role",
          step: 4,
          created_by_id: u1.id
        },
        #6
        %{
          name: "Contact Ctr Non-Voice Manager",
          description: "this is a sample role",
          step: 4,
          created_by_id: u1.id
        },
        #7
        %{
          name: "Contact Ctr Voice Front Line",
          description: "this is a sample role",
          step: 4,
          created_by_id: u1.id
        },
        #8
        %{
          name: "Contact Ctr Voice Supervisor",
          description: "this is a sample role",
          step: 4,
          created_by_id: u1.id
        },
        #9
        %{
          name: "Contact Ctr Voice Manager",
          description: "this is a sample role",
          step: 4,
          created_by_id: u1.id
        },
        #10
        %{
          name: "Roving Agent Front Line",
          description: "this is a sample role",
          step: 4,
          created_by_id: u1.id
        },
        #11
        %{
          name: "Roving Agent Supervisor",
          description: "this is a sample role",
          step: 4,
          created_by_id: u1.id
        },
        #12
        %{
          name: "Roving Agent Manager",
          description: "this is a sample role",
          step: 4,
          created_by_id: u1.id
        },
        #13
        %{
          name: "Claim Processor",
          description: "this is a sample role",
          step: 4,
          created_by_id: u1.id
        },
        #14
        %{
          name: "Claim TL",
          description: "this is a sample role",
          step: 4,
          created_by_id: u1.id
        },
        #15
        %{
          name: "Claim Manager",
          description: "this is a sample role",
          step: 4,
          created_by_id: u1.id
        },
        #16
        %{
          name: "Billing Front Line",
          description: "this is a sample role",
          step: 4,
          created_by_id: u1.id
        },
        #17
        %{
          name: "Billing Supervisor",
          description: "this is a sample role",
          step: 4,
          created_by_id: u1.id
        },
        #18
        %{
          name: "CFO",
          description: "this is a sample role",
          step: 4,
          created_by_id: u1.id
        },
        #19
        %{
          name: "COO",
          description: "this is a sample role",
          step: 4,
          created_by_id: u1.id
        },
        #20
        %{
          name: "CEO",
          description: "this is a sample role",
          step: 4,
          created_by_id: u1.id
        },
        #21
        %{
          name: "Administrator",
          description: "Full access",
          step: 4,
          created_by_id: u1.id
        },
        #22
        %{
          name: "Trainee",
          description: "Full access to Authorization and approval limit of PHP 0",
          step: 4,
          created_by_id: u1.id,
          approval_limit: 0
        },
        #23
        %{
          name: "Probationary",
          description: "Full access to Authorization and approval limit of PHP 5,000",
          step: 4,
          created_by_id: u1.id,
          approval_limit: 5000
        },
        #24
        %{
          name: "Regular",
          description: "Full access to Authorization and approval limit of PHP 10,000",
          step: 4,
          created_by_id: u1.id,
          approval_limit: 10_000
        },
        #25
        %{
          name: "Team Lead",
          description: "Full access to Authorization and approval limit of PHP 15,000",
          step: 4,
          created_by_id: u1.id,
          approval_limit: 15_000
        },
      ]
      [r1, r2, r3, r4, r5,
       r6, r7, r8, r9, r10,
       r11, r12, r13, r14, r15,
       r16, r17, r18, r19, r20,
       r21, r22, r23, r24, r25] =
         role_data
         |> RoleSeeder.seed()

         #Create Role Applications
         IO.puts "Seeding role_applications..."
         role_application_data = [
           #1
           %{
             application_id: a1.id,
             role_id: r1.id
           },
           #2
           %{
             application_id: a1.id,
             role_id: r2.id
           },
           #3
           %{
             application_id: a1.id,
             role_id: r3.id
           },
           #4
           %{
             application_id: a1.id,
             role_id: r4.id
           },
           #5
           %{
             application_id: a1.id,
             role_id: r5.id
           },
           #6
           %{
             application_id: a1.id,
             role_id: r6.id
           },
           #7
           %{
             application_id: a1.id,
             role_id: r7.id
           },
           #8
           %{
             application_id: a1.id,
             role_id: r8.id
           },
           #9
           %{
             application_id: a1.id,
             role_id: r9.id
           },
           #10
           %{
             application_id: a1.id,
             role_id: r10.id
           },
           #11
           %{
             application_id: a1.id,
             role_id: r11.id
           },
           #12
           %{
             application_id: a1.id,
             role_id: r12.id
           },
           #13
           %{
             application_id: a1.id,
             role_id: r13.id
           },
           #14
           %{
             application_id: a1.id,
             role_id: r14.id
           },
           #15
           %{
             application_id: a1.id,
             role_id: r15.id
           },
           #16
           %{
             application_id: a1.id,
             role_id: r16.id
           },
           #17
           %{
             application_id: a1.id,
             role_id: r17.id
           },
           #18
           %{
             application_id: a1.id,
             role_id: r18.id
           },
           #19
           %{
             application_id: a1.id,
             role_id: r19.id
           },
           #20
           %{
             application_id: a1.id,
             role_id: r20.id
           },
           #21
           %{
             application_id: a1.id,
             role_id: r21.id
           },
           #22
           %{
             application_id: a1.id,
             role_id: r22.id
           },
           #23
           %{
             application_id: a1.id,
             role_id: r23.id
           },
           #24
           %{
             application_id: a1.id,
             role_id: r24.id
           },
           #25
           %{
             application_id: a1.id,
             role_id: r25.id
           },
           #26
           %{
             application_id: a6.id,
             role_id: r21.id
           }
         ]
         [ra1, ra2, ra3, ra4, ra5,
          ra6, ra7, ra8, ra9, ra10,
          ra11, ra12, ra13, ra14, ra15,
          ra16, ra17, ra18, ra19, ra20,
          ra21, ra22, ra23, ra24, ra25,
          ra26] =
            role_application_data
            |> RoleApplicationSeeder.seed()

            #Create User Role
            IO.puts "Seeding user_role..."
            user_role_data = [
              #1
              %{
                user_id: u1.id,
                role_id: r21.id
              }
            ]
            [ra1] = UserRoleSeeder.seed(user_role_data)

            #Create Role Permissions
            IO.puts "Seeding role permissions..."
            role_permission_data = [
              #1
              %{
                permission_id: p1.id,
                role_id: r21.id
              },
              #2
              %{
                permission_id: p2.id,
                role_id: r21.id
              },
              #3
              %{
                permission_id: p3.id,
                role_id: r21.id
              },
              #4
              %{
                permission_id: p4.id,
                role_id: r21.id
              },
              #5
              %{
                permission_id: p5.id,
                role_id: r21.id
              },
              #6
              %{
                permission_id: p6.id,
                role_id: r21.id
              },
              #7
              %{
                permission_id: p7.id,
                role_id: r21.id
              },
              #8
              %{
                permission_id: p8.id,
                role_id: r21.id
              },
              #9
              %{
                permission_id: p9.id,
                role_id: r21.id
              },
              #10
              %{
                permission_id: p10.id,
                role_id: r21.id
              },
              #11
              %{
                permission_id: p11.id,
                role_id: r21.id
              },
              #12
              %{
                permission_id: p12.id,
                role_id: r21.id
              },
              #13
              %{
                permission_id: p13.id,
                role_id: r21.id
              },
              #14
              %{
                permission_id: p14.id,
                role_id: r21.id
              },
              #15
              %{
                permission_id: p15.id,
                role_id: r21.id
              },
              #16
              %{
                permission_id: p16.id,
                role_id: r21.id
              },
              #17
              %{
                permission_id: p17.id,
                role_id: r21.id
              },
              #18
              %{
                permission_id: p18.id,
                role_id: r21.id
              },
              #19
              %{
                permission_id: p19.id,
                role_id: r21.id
              },
              #20
              %{
                permission_id: p20.id,
                role_id: r21.id
              },
              #21
              %{
                permission_id: p21.id,
                role_id: r21.id
              },
              #22
              %{
                permission_id: p22.id,
                role_id: r21.id
              },
              #23
              %{
                permission_id: p23.id,
                role_id: r21.id
              },
              #24
              %{
                permission_id: p24.id,
                role_id: r21.id
              },
              #25
              %{
                permission_id: p25.id,
                role_id: r21.id
              },
              #26
              %{
                permission_id: p26.id,
                role_id: r21.id
              },

              #27
              %{
                permission_id: p27.id,
                role_id: r21.id
              },

              #28
              %{
                permission_id: p28.id,
                role_id: r21.id
              },

              #29
              %{
                permission_id: p29.id,
                role_id: r21.id
              },

              #30
              %{
                permission_id: p30.id,
                role_id: r21.id
              },

              #31
              %{
                permission_id: p31.id,
                role_id: r21.id
              },

              #32
              %{
                permission_id: p32.id,
                role_id: r21.id
              },

              #33
              %{
                permission_id: p33.id,
                role_id: r21.id
              },

              #34
              %{
                permission_id: p34.id,
                role_id: r21.id
              },

              #35
              %{
                permission_id: p35.id,
                role_id: r21.id
              },

              #36
              %{
                permission_id: p36.id,
                role_id: r21.id
              },

              #37
              %{
                permission_id: p29.id,
                role_id: r22.id
              },
              #38
              %{
                permission_id: p30.id,
                role_id: r22.id
              },
              #39
              %{
                permission_id: p29.id,
                role_id: r23.id
              },
              #40
              %{
                permission_id: p30.id,
                role_id: r23.id
              },
              #41
              %{
                permission_id: p29.id,
                role_id: r24.id
              },
              #42
              %{
                permission_id: p30.id,
                role_id: r24.id
              },
              #43
              %{
                permission_id: p29.id,
                role_id: r25.id
              },
              #44
              %{
                permission_id: p30.id,
                role_id: r25.id
              },
              #45
              %{
                permission_id: p41.id,
                role_id: r21.id
              },
              #46
              %{
                permission_id: p42.id,
                role_id: r21.id
              },
              #47
              %{
                permission_id: p43.id,
                role_id: r21.id
              },
              #48
              %{
                permission_id: p44.id,
                role_id: r21.id
              },
            ]

            [rp1, rp2, rp3, rp4, rp5,
             rp6, rp7, rp8, rp9, rp10,
             rp11, rp12, rp13, rp14, rp15,
             rp16, rp17, rp18, rp19, rp20,
             rp21, rp22, rp23, rp24, rp25,
             rp26, rp27, rp28, rp29, rp30,
             rp31, rp32, rp33, rp34, rp35,
             rp36, rp37, rp38, rp39, rp40,
             rp41, rp42, rp43, rp44, rp45,
             rp46, rp47, rp48] =
               role_permission_data
               |> RolePermissionSeeder.seed()

               #Create Payors
               IO.puts "Seeding payors..."
               payor_data = [
                 #1
                 %{
                   name: "Maxicare",
                   legal_name: "Maxicare Healthcare Corporation",
                   tax_number: 123_456,
                   type: "Payor",
                   status: "None",
                   code: "ABCDEFG"
                 }
               ]
               [pa1] = PayorSeeder.seed(payor_data)

               #Seed Payor Card Bins
               IO.puts "Seeding payor_card_bins..."
               payor_card_bin_data = [
                 #1
                 %{
                   payor_id: pa1.id,
                   card_bin: "60508311",
                   sequence: "1"
                 }
               ]
               [pcb1] = PayorCardBinSeeder.seed(payor_card_bin_data)

               #Create Coverages
               IO.puts "Seeding coverages..."
               coverage_data = [
                 #1
                 %{
                   name: "OP Consult",
                   description: "OP Consult",
                   status: "A",
                   type: "A",
                   plan_type: "health_plan",
                   code: "OPC"
                 },
                 #2
                 %{
                   name: "OP Laboratory",
                   description: "OP Laboratory",
                   status: "A",
                   type: "A",
                   plan_type: "health_plan",
                   code: "OPL"
                 },
                 #3
                 %{
                   name: "Emergency",
                   description: "Emergency",
                   status: "A",
                   type: "A",
                   plan_type: "health_plan",
                   code: "EMRGNCY"
                 },
                 #4
                 %{
                   name: "Inpatient",
                   description: "Inpatient",
                   status: "A",
                   type: "A",
                   plan_type: "health_plan",
                   code: "IP"
                 },
                 #5
                 %{
                   name: "Dental",
                   description: "Dental",
                   status: "A",
                   type: "A",
                   plan_type: "riders",
                   code: "DENTL"
                 },
                 #6
                 %{
                   name: "Maternity",
                   description: "Maternity",
                   status: "A",
                   type: "A",
                   plan_type: "riders",
                   code: "MTRNTY"
                 },
                 #7
                 %{
                   name: "ACU",
                   description: "ACU",
                   status: "A",
                   type: "A",
                   plan_type: "riders",
                   code: "ACU"
                 },
                 #8
                 %{
                   name: "Optical",
                   description: "Optical",
                   status: "A",
                   type: "A",
                   plan_type: "riders",
                   code: "OPT"
                 },
                 #9
                 %{
                   name: "Medicine",
                   description: "Medicine",
                   status: "A", type: "A",
                   plan_type: "riders",
                   code: "MED"
                 },
               ]
               [c1, c2, c3, c4, c5, c6, c7, c8, c9] = CoverageSeeder.seed(coverage_data)

               IO.puts "Seeding api address"
               api_address_data = [
                 #1
                 %{
                   name: "PAYORLINK 1.0",
                   address: "https://paylinkapi.medilink.com.ph",
                   username: "admin@mlservices.com",
                   password: "P@ssw0rd1234"
                 },
                 #2
                 %{
                   name: "PROVIDERLINK_2",
                   address: "https://providerlink-prod.medilink.com.ph",
                   username: "masteradmin",
                   password: "P@ssw0rd"
                 }
               ]
               [aa1, aa2] = ApiAddressSeeder.seed(api_address_data)

               IO.puts "Seeding translations"
               translation_data = [
                 #1
                 %{
                   base_value: "Hello",
                   translated_value: "Kumusta",
                   language: "zh"
                 },
                 #2
                 %{
                   base_value: "MAKATI MEDICAL CENTER",
                   translated_value: "MAKATI医疗中心",
                   language: "zh"
                 },
                 #3
                 %{
                   base_value: "CHINESE GENERAL HOSPITAL & MEDICAL CENTER",
                   translated_value: "中文综合医院和医疗中心",
                   language: "zh"
                 },
                 #4
                 %{
                   base_value: "MYHEALTH CLINIC - SM NORTH EDSA",
                   translated_value: "MYHEALTH诊所 - SM北EDSA",
                   language: "zh"
                 },
                 #5
                 %{
                   base_value: "MEDICAL CENTER",
                   translated_value: "医疗中心",
                   language: "zh"
                 },
                 #6
                 %{
                   base_value: "MEDICAL",
                   translated_value: "医",
                   language: "zh"
                 },
                 #7
                 %{
                   base_value: "CENTER",
                   translated_value: "中央",
                   language: "zh"
                 },
                 #8
                 %{
                   base_value: "CLINIC",
                   translated_value: "诊所",
                   language: "zh"
                 },
                 #9
                 %{
                   base_value: "Freud",
                   translated_value: "弗洛伊德",
                   language: "zh"
                 },
                 #10
                 %{
                   base_value: "Sigmund",
                   translated_value: "西格蒙德",
                   language: "zh"
                 },
                 #11
                 %{
                   base_value: "Freud, Sigmund",
                   translated_value: "弗洛伊德, 西格蒙德",
                   language: "zh"
                 },
                 #12
                 %{
                   base_value: "Jung",
                   translated_value: "荣格",
                   language: "zh"
                 },
                 #13
                 %{
                   base_value: "Carl",
                   translated_value: "卡尔",
                   language: "zh"
                 },
                 #14
                 %{
                   base_value: "Jung, Carl",
                   translated_value: "荣格, 卡尔",
                   language: "zh"
                 },
                 #15
                 %{
                   base_value: "Soriano",
                   translated_value: "卡尔索里亚诺",
                   language: "zh"
                 },
                 #16
                 %{
                   base_value: "Demosthenes",
                   translated_value: "德摩斯梯尼",
                   language: "zh"
                 },
                 #17
                 %{
                   base_value: "Soriano, Demosthenes",
                   translated_value: "卡尔索里亚诺, 德摩斯梯尼",
                   language: "zh"
                 },
                 #18
                 %{
                   base_value: "286 Radial Road 8",
                   translated_value: "286径向道路8",
                   language: "zh"
                 },
                 #19
                 %{
                   base_value: "Santa Cruz",
                   translated_value: "圣克鲁斯",
                   language: "zh"
                 },
                 #20
                 %{
                   base_value: "Manila",
                   translated_value: "马尼拉",
                   language: "zh"
                 },
                 #21
                 %{
                   base_value: "Metro Manila",
                   translated_value: "马尼拉大都会",
                   language: "zh"
                 },
                 #22
                 %{
                   base_value: "Philippines",
                   translated_value: "菲律宾",
                   language: "zh"
                 },
                 #23
                 %{
                   base_value: "SM City North SM City North EDSA Annex 1 Tunnel",
                   translated_value: "SM市北SM市北EDSA附件1隧道",
                   language: "zh"
                 },
                 #24
                 %{
                   base_value: "Quezon City",
                   translated_value: "奎松市",
                   language: "zh"
                 },
                 #25
                 %{
                   base_value: "Dela Rosa Street",
                   translated_value: "Dela Rosa街",
                   language: "zh"
                 },
                 #26
                 %{
                   base_value: "Legazpi Village",
                   translated_value: "Legazpi村庄",
                   language: "zh"
                 },
                 #27
                 %{
                   base_value: "Dermatology",
                   translated_value: "皮肤科",
                   language: "zh"
                 },
                 #28
                 %{
                   base_value: "General Surgery",
                   translated_value: "普通外科",
                   language: "zh"
                 },
                 #29
                 %{
                   base_value: "Otolaryngology-Head and Neck Surgery",
                   translated_value: "耳鼻咽喉-头颈外科",
                   language: "zh"
                 },
                 #30
                 %{
                   base_value: "Vascular Surgery",
                   translated_value: "血管外科",
                   language: "zh"
                 },
                 #31
                 %{
                   base_value: "Radiology",
                   translated_value: "放射科",
                   language: "zh"
                 },
                 #32
                 %{
                   base_value: "Pathology",
                   translated_value: "病理",
                   language: "zh"
                 },
                 #33
                 %{
                   base_value: "Neurosurgery",
                   translated_value: "神经外科",
                   language: "zh"
                 },
                 #34
                 %{
                   base_value: "Pediatrics",
                   translated_value: "小儿科的",
                   language: "zh"
                 },
                 #35
                 %{
                   base_value: "Resident Physician",
                   translated_value: "居民医师",
                   language: "zh"
                 },
                 #36
                 %{
                   base_value: "Internal Medicine",
                   translated_value: "内科",
                   language: "zh"
                 },
                 #37
                 %{
                   base_value: "General Medicine",
                   translated_value: "一般医学",
                   language: "zh"
                 },
                 #38
                 %{
                   base_value: "Family Medicine",
                   translated_value: "家庭医学",
                   language: "zh"
                 },
                 #39
                 %{
                   base_value: "Opthalmology",
                   translated_value: "眼科",
                   language: "zh"
                 },
                 #40
                 %{
                   base_value: "Optometry",
                   translated_value: "验光",
                   language: "zh"
                 },
                 #41
                 %{
                   base_value: "Obstetrics and Gynecology",
                   translated_value: "妇产科",
                   language: "zh"
                 },
                 #42
                 %{
                   base_value: "Occupational Medicine",
                   translated_value: "职业医学",
                   language: "zh"
                 },
                 #43
                 %{
                   base_value: "Neurology",
                   translated_value: "神经内科",
                   language: "zh"
                 },
                 #44
                 %{
                   base_value: "Orthopedic Surgery",
                   translated_value: "骨科手术",
                   language: "zh"
                 },
                 #45
                 %{
                   base_value: "Anesthesiology",
                   translated_value: "麻醉学",
                   language: "zh"
                 },
                 #46
                 %{
                   base_value: "Oncology",
                   translated_value: "肿瘤科",
                   language: "zh"
                 },
               ]
               [tr1, tr2, tr3, tr4, tr5,
                tr6, tr7, tr8, tr9, tr10,
                tr11, tr12, tr13, tr14, tr15,
                tr16, tr17, tr18, tr19, tr20,
                tr21, tr22, tr23, tr24, tr25,
                tr26, tr27, tr28, tr29, tr30,
                tr31, tr32, tr33, tr34, tr35,
                tr36, tr37, tr38, tr39, tr40,
                tr41, tr42, tr43, tr44, tr45,
                tr46] =
                  TranslationSeeder.seed(translation_data)

#Create Industry
IO.puts "Seeding Industry..."
industry_data =
  [
    %{
      #1
      code: "A01 - ADVERTISING"
    },
    %{
      #2
      code: "A02 - AGRICULTURAL SERVICES"
    },
    %{
      #3
      code: "A03 - AGRICULTURE & AGRICULTURAL CROPS PRODUCT"
    },
    %{
      #4
      code: "A05 - ANIMAL FEED MILLING"
    },
    %{
      #5
      code: "A06 - AUTOMOBILE SALES"
    },
    %{
      #6
      code: "A07 - AGENCY"
    },
    %{
      #7
      code: "B01 - BANKING & FINANCE"
    },
    %{
      #8
      code: "B02 - BROADCASTING & MEDIA"
    },
    %{
      #9
      code: "B03 - BROKERS & AGENT"
    },
    %{
      #10
      code: "C01 - CABLE SALES & SERVICES"
    },
    %{
      #11
      code: "C02 - CLERICAL OCCUPATIONS"
    },
    %{
      #12
      code: "C03 - COMMUNICATION & TELECOMMUNICATION SERVICES"
    },
    %{
      #13
      code: "C04 - COMMUNITY, SOCIAL, & PERSONAL SERVICES"
    },
    %{
      #14
      code: "C05 - CONSTRUCTION"
    },
    %{
      #15
      code: "C06 - CONSULTANCY"
    },
    %{
      #16
      code: "C07 - CALIBRATION SERVICES AND TRADING"
    },
    %{
      #17
      code: "C08 - CONDO"
    },

    ### add additional industry
    %{
      #18
      code: "A00 - ACTIVITIES NOT ADEQUATELY DEFINED"
    },

    %{
      #19
      code: "D01 - DISTRIBUTION/SUPPLY OF EXPLOSIVES/AMMUNITIONS"
    },

    %{
      #20
      code: "D01 - DISTRIBUTION/SUPPLY OF EXPLOSIVES/AMMUNITIONS"
    },

    %{
      #21
      code: "D02 - DISTRIBUTION/SUPPLY OF CHEMICAL PRODUCTS"
    },

    %{
      #22
      code: "D03 - DISTRIBUTION/SUPPLY OF ELECTRONIC PRODUCTS"
    },

    %{
      #23
      code: "D04 - DISTRIBUTION/SUPPLY OF FOOD & BEVERAGES"
    },

    %{
      #24
      code: "D05 - DISTRIBUTION/SUPPLY OF GARMENTS, TEXTILE"
    },

    %{
      #25
      code: "D06 - DISTRIBUTION/SUPPLY OF HAND-MADE PRODUCT"
    },

    %{
      #26
      code: "D07 - DISTRIBUTION/SUPPLY OF HOME NECESSITIES"
    },

    %{
      #27
      code: "D08 - DISTRIBUTION/SUPPLY OF MECHANICAL/METALLIC PRODUCTS"
    },

    %{
      #28
      code: "D09 - DISTRIBUTION/SUPPLY OF MEDICINES AND DRUGS (PHARMACEUTICAL GROUPS)"
    },

    %{
      #29
      code: "D10 - DISTRIBUTION/SUPPLY OF PAPER & PAPER PRODUCTS"
    },

    %{
      #30
      code: "D11 - DISTRIBUTION/SUPPLY OF PETROLEUM, OIL & COAL"
    },

    %{
      #31
      code: "D12 - DISTRIBUTION/SUPPLY OF RAW MATERIALS"
    },

    %{
      #32
      code: "D13 - DISTRIBUTION/SUPPLY OF RUBBER & PLASTIC PRODUCTS"
    },

    %{
      #33
      code: "D14 - DISTRIBUTION/SUPPLY OF SEMICONDUCTOR"
    },

    %{code: "D15 - DISTRIBUTION/SUPPLY OF WOOD & WOOD PRODUCTS"},
    %{code: "D16 - DOMESTIC & PERSONAL SERVICES"},
    %{code: "D17 - DISTRIBUTION/SUPPLY OF MEDICAL/LABORATORY EQUIPMENT"},
    %{code: "E01 - EDUCATION"},
    %{code: "E02 - ELECTRICAL SERVICES"},
    %{code: "E03 - EMBASSY"},
    %{code: "E04 - ENGINEERING &/OR ARCHITECTURAL SERVICE"},
    %{code: "E05 - Elevator Business"},
    %{code: "F01 - FINANCIAL INTERMEDIARIES"},
    %{code: "F02 - FINANCIAL INVESTMENTS"},
    %{code: "F03 - FISHERY"},
    %{code: "F05 - FREIGHT FORWARDING/SHIPPING"},
    %{code: "FO4 - FORESTRY"},
    %{code: "G01 - GAS & STEAM"},
    %{code: "G02 - GOVERNMENT OFFICE/SECTOR/INSTITUTION"},
    %{code: "H01 - HEALTH CARE PROVIDER"},
    %{code: "H02 - HEALTH MAINTENANCE ORGANIZATION (HMO)"},
    %{code: "H03 - HOLDINGS"},
    %{code: "H04 - HOTEL"},
    %{code: "I01 - IMPORT &/OR EXPORT"},
    %{code: "I02 - INTERIOR DESIGNING"},
    %{code: "L01 - LAW FIRM/PUBLIC ADMINISTRATION & DEFEN"},
    %{code: "L02 - LEASING/RENTING"},
    %{code: "L03 - LENDING COMPANY/PAWNSHOP"},
    %{code: "L04 - LIFE/HEALTH INSURANCE & PRE-NEED"},
    %{code: "L05 - LIVESTOCK, POULTRY & OTHER ANIMALS"},
    %{code: "M01 - MANAGEMENT SERVICES"},
    %{code: "M02 - MANUFACTURING OF CHEMICAL PRODUCTS"},
    %{code: "M03 - MANUFACTURING OF ELECTRONIC PRODUCTS"},
    %{code: "M04 - MANUFACTURING OF EXPLOSIVES/AMMUNITIONS"},
    %{code: "M05 - MANUFACTURING OF FOOD, BEVERAGES AND TOBACCO"},
    %{code: "M06 - MANUFACTURING OF GARMENTS & TEXTILES"},
    %{code: "M07 - MANUFACTURING OF HAND-MADE PRODUCTS"},
    %{code: "M08 - MANUFACTURING OF HOME NECESSITIES"},
    %{code: "M09 - MANUFACTURING OF MECHANICAL/METALLIC PRODUCTS"},
    %{code: "M10 - MANUFACTURING OF MEDICINES AND DRUGS"},
    %{code: "M11 - MANUFACTURING OF PAPER & PAPER PRODUCTS"},
    %{code: "M12 - MANUFACTURING OF PETROLEUM, OIL & COAL"},
    %{code: "M13 - MANUFACTURING OF RUBBER & PLASTIC PRODUC"},
    %{code: "M14 - MANUFACTURING OF WOOD & WOOD PRODUCTS"},
    %{code: "M15 - MARKETING & SALES"},
    %{code: "M16 - MINING/QUARRYING OF METALLIC MINERALS"},
    %{code: "M17 - MINING/QUARRYING OF NON-METALLIC MINERAL"},
    %{code: "M18 - MEDIA AND PUBLISHING"},
    %{code: "M19 - Merchandising"},
    %{code: "N01 - NGO/COOPERATIVE/FOUNDATION"},
    %{code: "N02 - NON GAINFUL OCCUPATIONS"},
    %{code: "N03 - NON-LIFE INSURANCE"},
    %{code: "N04 - NUCLEAR/CHEMICAL/ELECTRICAL PLANT"},
    %{code: "O00 - OIL AND GAS EXPLORATION"},
    %{code: "P01 - PHOTOGRAPH SALES & SERVICES"},
    %{code: "P02 - POLITICAL ORGANIZATION"},
    %{code: "P03 - PRINTING & PUBLISHING"},
    %{code: "P04 - PROFESSIONAL SERVICE"},
    %{code: "P05 - PROTECTION SERVICES"},
    %{code: "P06 - PUBLIC SERVICE"},
    %{code: "P07 - PVC MANUFACTURING"},
    %{code: "R01 - REAL ESTATE DEVELOPMENT"},
    %{code: "R02 - RECORDING/STUDIO COMPANY"},
    %{code: "R03 - RELIGIOUS ORGANIZATION/CHURCH"},
    %{code: "R04 - REPAIR AND ASSEMBLING"},
    %{code: "R05 - RESEARCH"},
    %{code: "R06 - RESTAURANT/FASTFOOD/CAFE"},
    %{code: "R07 - RENEWABLE ENERGY RESOURCING COMPANY"},
    %{code: "S01 - SEMICONDUCTOR"},
    %{code: "S02 - SPORTS, ATHLETICS & RECREATIONAL FACILITY"},
    %{code: "S03 - STOCKS EXCHANGE"},
    %{code: "S04 - STORAGE & WAREHOUSING"},
    %{code: "S05 - SYSTEM/SOFTWARE DEVELOPMENT/INFORMATION TECHNOLOGY"},
    %{code: "S06 - SCHOOL"},
    %{code: "T01 - TRAVEL AGENCY"},
    %{code: "T02 - THERAPEUTIC CENTER/SPA/HEALTH RESORT"},
    %{code: "T03 - TRAINING SERVICES"},
    %{code: "T04 - TRANSPORTATION"},
    %{code: "V01 - VETERINARY SERVICES"},
    %{code: "W01 - WATER TREATMENT"},
    %{code: "W02 - WATERWORKS & SUPPLY"},
    %{code: "W03 - WEDDING PLANNING"},
    %{code: "W04 - WHOLESALE &/OR RETAIL TRADE"}

  ]

[
  i1, i2, i3, i4, i5,
  i6, i7, i8, i9, i10,
  i11, i12, i13, i14, i15,
  i16, i17, i18, i19, i20,
  i21, i22, i23, i24, i25,
  i26, i27, i28, i29, i30,
  i31, i32, i33, i34, i35,
  i36, i37, i38, i39, i40,
  i41, i42, i43, i44, i45,
  i46, i47, i48, i49, i50,
  i51, i52, i53, i54, i55,
  i56, i57, i58, i59, i60,
  i61, i62, i63, i64, i65,
  i66, i67, i68, i69, i70,
  i71, i72, i73, i74, i75,
  i76, i77, i78, i79, i80,
  i81, i82, i83, i84, i85,
  i86, i87, i88, i89, i90,
  i91, i92, i93, i94, i95,
  i96, i97, i98, i99, i100,
  i101, i102, i103, i104, i105,
  i106, i107, i108, i109, i110,
  i111, i112
] = IndustrySeeder.seed(industry_data)
# End of Create Industry

# Create Procedure Category
IO.puts "Seeding Procedure Category..."
procedure_category_data =
  [
    %{
      #1
      name: "Pathology and Laboratory Procedures",
      code: "80047-89398"
    },
  ]
[pc1] = ProcedureCategorySeeder.seed(procedure_category_data)

# Create AccountGroup
IO.puts "Seeding AccountGroup..."
account_group_data =
  [
    %{
      #1
      name: "Jollibee Worldwide",
      code: "C00918",
      type: "Headquarters",
      description: "Jollibee",
      segment: "Corporate",
      security: "Security",
      email: "Jollibee@yahoo.com",
      phone_no: "09123456789",
      industry_id: i1.id,
      original_effective_date: Ecto.Date.cast!("2017-08-01"),
      remarks: "This is a sample text."
    }
  ]

[ag1] = AccountGroupSeeder.seed(account_group_data)
account_group = [ag1]
# End of Create AccountGroup

# Create Account
IO.puts "Seeding Account..."
account_data =
  [
    %{
      #1
      start_date: Ecto.Date.cast!("2017-08-01"),
      end_date: Ecto.Date.cast!("2018-08-15"),
      status: "Active",
      account_group_id: ag1.id,
      major_version: 1,
      minor_version: 0,
      build_version: 0,
      updated_by: u1.id,
      step: 7
    }
  ]

[acc1] = AccountSeeder.seed(account_data)
# End of Create Account

# MemberLink User
IO.puts "Seeding member..."
member_data =
  [
    %{
      #1
      first_name: "Juan",
      last_name: "Dela Cruz",
      gender: "Male",
      type: "Principal",
      account_code: ag1.code,
      created_by_id: u1.id,
      updated_by_id: u1.id,
      card_no: "1168011034280092",
      step: 2,
      birthdate: Ecto.Date.cast!("1990-10-10"),
      effectivity_date: Ecto.Date.cast!("1990-10-10"),
      expiry_date: Ecto.Date.cast!("2090-10-10"),
      civil_status: "Single",
      employee_no: "123123123",
      date_hired: Ecto.Date.cast!("2015-10-10"),
      is_regular: true,
      regularization_date: Ecto.Date.cast!("2015-10-10"),
      tin: "123456789012",
      philhealth: "123456789012",
      for_card_issuance: true,
      philhealth_type: "Not Covered",
      status: "Active"
    },
    %{
      # 2
      first_name: "Maria",
      last_name: "Santos",
      gender: "Female",
      type: "Principal",
      account_code: ag1.code,
      created_by_id: u1.id,
      updated_by_id: u1.id,
      card_no: "1168011034280093",
      step: 2,
      birthdate: Ecto.Date.cast!("1990-10-10"),
      effectivity_date: Ecto.Date.cast!("1990-10-10"),
      expiry_date: Ecto.Date.cast!("2090-10-10"),
      civil_status: "Single",
      employee_no: "123123124",
      date_hired: Ecto.Date.cast!("2015-10-10"),
      is_regular: true,
      regularization_date: Ecto.Date.cast!("2015-10-10"),
      tin: "123456789012",
      philhealth: "123456789012",
      for_card_issuance: true,
      philhealth_type: "Not Covered",
      status: "Active"
    },
    %{
      #3
      first_name: "Leonora",
      last_name: "Silang",
      gender: "Female",
      type: "Principal",
      account_code: ag1.code,
      created_by_id: u1.id,
      updated_by_id: u1.id,
      card_no: "1168011034280094",
      step: 2,
      birthdate: Ecto.Date.cast!("1990-10-10"),
      effectivity_date: Ecto.Date.cast!("1990-10-10"),
      expiry_date: Ecto.Date.cast!("2090-10-10"),
      civil_status: "Single",
      employee_no: "123123125",
      date_hired: Ecto.Date.cast!("2015-10-10"),
      is_regular: true,
      regularization_date: Ecto.Date.cast!("2015-10-10"),
      tin: "123456789012",
      philhealth: "123456789012",
      for_card_issuance: true,
      philhealth_type: "Not Covered",
      status: "Active"
    },
    %{
      #4
      first_name: "Diego",
      last_name: "Del Pilar",
      gender: "Male",
      type: "Principal",
      account_code: ag1.code,
      created_by_id: u1.id,
      updated_by_id: u1.id,
      card_no: "1168011034280095",
      step: 2,
      birthdate: Ecto.Date.cast!("1990-10-10"),
      effectivity_date: Ecto.Date.cast!("1990-10-10"),
      expiry_date: Ecto.Date.cast!("2090-10-10"),
      civil_status: "Single",
      employee_no: "123123126",
      date_hired: Ecto.Date.cast!("2015-10-10"),
      is_regular: true,
      regularization_date: Ecto.Date.cast!("2015-10-10"),
      tin: "123456789012",
      philhealth: "123456789012",
      for_card_issuance: true,
      philhealth_type: "Not Covered",
      status: "Active"
    },
    %{
      #5
      first_name: "Corazon",
      last_name: "Santiago",
      gender: "Male",
      type: "Principal",
      account_code: ag1.code,
      created_by_id: u1.id,
      updated_by_id: u1.id,
      card_no: "1168011034280096",
      step: 2,
      birthdate: Ecto.Date.cast!("1990-10-10"),
      effectivity_date: Ecto.Date.cast!("1990-10-10"),
      expiry_date: Ecto.Date.cast!("2090-10-10"),
      civil_status: "Single",
      employee_no: "123123127",
      date_hired: Ecto.Date.cast!("2015-10-10"),
      is_regular: true,
      regularization_date: Ecto.Date.cast!("2015-10-10"),
      tin: "123456789012",
      philhealth: "123456789012",
      for_card_issuance: true,
      philhealth_type: "Not Covered",
      status: "Active"
    }
  ]

[m1, m2, m3, m4, m5] = MemberSeeder.seed(member_data)

IO.puts "Seeding user for MemberLink"
user_member_data =
  [
    %{
      #1
      "username" => "juan_delacruz",
      "password" => "P@ssw0rd",
      "is_admin" => true,
      "email" => "memberlinkuser@medi.com",
      "mobile" => "09199046601",
      "password_confirmation" => "P@ssw0rd",
      "verification_code" => "1234",
      "verification" => true,
      "member_id" =>  m1.id,
      "first_name" => m1.first_name,
      "middle_name" => m1.middle_name,
      "last_name" => m1.last_name,
      "gender" => m1.gender,
      "birthday" => m1.birthdate,
      "status" => "Active"
    },
    %{
      #2
      "username" => "maria_santos",
      "password" => "P@ssw0rd4",
      "is_admin" => false,
      "email" => "memberlinkuser@medi.com",
      "mobile" => "09199046601",
      "password_confirmation" => "P@ssw0rd4",
      "verification_code" => "1234",
      "verification" => true,
      "member_id" =>  m2.id,
      "first_name" => m2.first_name,
      "middle_name" => m2.middle_name,
      "last_name" => m2.last_name,
      "gender" => m2.gender,
      "birthday" => m2.birthdate,
      "status" => "Active"
    },
    %{
      #3
      "username" => "leonora_silang",
      "password" => "P@ssw0rd3",
      "is_admin" => false,
      "email" => "memberlinkuser@medi.com",
      "mobile" => "09199046601",
      "password_confirmation" => "P@ssw0rd3",
      "verification_code" => "1234",
      "verification" => true,
      "member_id" =>  m3.id,
      "first_name" => m3.first_name,
      "middle_name" => m3.middle_name,
      "last_name" => m3.last_name,
      "gender" => m3.gender,
      "birthday" => m3.birthdate,
      "status" => "Active"
    },
    %{
      #4
      "username" => "diego_delpilar",
      "password" => "P@ssw0rd1",
      "is_admin" => false,
      "email" => "memberlinkuser@medi.com",
      "mobile" => "09199046601",
      "password_confirmation" => "P@ssw0rd1",
      "verification_code" => "1234",
      "verification" => true,
      "member_id" =>  m4.id,
      "first_name" => m4.first_name,
      "middle_name" => m4.middle_name,
      "last_name" => m4.last_name,
      "gender" => m4.gender,
      "birthday" => m4.birthdate,
      "status" => "Active"
    },
    %{
      #5
      "username" => "corazon_santiago",
      "password" => "P@ssw0rd2",
      "is_admin" => false,
      "email" => "memberlinkuser@medi.com",
      "mobile" => "09199046601",
      "password_confirmation" => "P@ssw0rd2",
      "verification_code" => "1234",
      "verification" => true,
      "member_id" =>  m5.id,
      "first_name" => m5.first_name,
      "middle_name" => m5.middle_name,
      "last_name" => m5.last_name,
      "gender" => m5.gender,
      "birthday" => m5.birthdate,
      "status" => "Active"
    }
  ]

[um1, um2, um3, um4, um5] = UserSeeder.seed_memberlink(user_member_data)
