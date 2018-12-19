alias Innerpeace.Db.{
  Schemas.Product,
  Schemas.TermsNCondition,
  UserSeeder,
  ApplicationSeeder,
  DropdownSeeder,
  FacilitySeeder,
  BankSeeder,
  AccountGroupSeeder,
  IndustrySeeder,
  BankBranchSeeder,
  ProcedureCategorySeeder,
  ProcedureSeeder,
  DiagnosisSeeder,
  PermissionSeeder,
  RoleSeeder,
  RoleApplicationSeeder,
  UserRoleSeeder,
  RolePermissionSeeder,
  PayorSeeder,
  ProductSeeder,
  CoverageSeeder,
  BenefitSeeder,
  BenefitCoverageSeeder,
  BenefitProcedureSeeder,
  BenefitDiagnosisSeeder,
  BenefitLimitSeeder,
  PayorProcedureSeeder,
  ProductBenefitSeeder,
  ProductBenefitLimitSeeder,
  SpecializationSeeder,
  AccountSeeder,
  RoomSeeder,
  DiagnosisCoverageSeeder,
  AccountGroupAddressSeeder,
  AccountGroupContactSeeder,
  ContactSeeder,
  PhoneSeeder,
  PaymentAccountSeeder,
  ProductCoverageSeeder,
  ProductCoverageFacilitySeeder,
  ProductCoverageRiskShareSeeder,
  ProductCoverageRoomAndBoardSeeder,
  AccountHierarchyOfEligibleDependentSeeder,
  MemberSeeder,
  UserAccountSeeder,
  ProductCoverageLimitThresholdSeeder,
  # PayorCardBinSeeder,
  PractitionerSeeder,
  PractitionerSpecializationSeeder,
  PractitionerFacilitySeeder,
  PractitionerScheduleSeeder,
  AccountProductSeeder,
  AccountProductBenefitSeeder,
  MemberProductSeeder,
  ApiAddressSeeder,
  TermsNConditionSeeder,
  TranslationSeeder,
  CommonPasswordSeeder,
  RegionSeeder
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
    name: "FacilityLink"
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
  },
  #7
  %{
    name: "ProviderLink"
  }

]
[a1, a2, a3, a4, a5, a6, a7] = ApplicationSeeder.seed(application_data)

#Create Users
IO.puts "Seeding users..."
user_data =
  [
    %{
      #1
      username: "masteradmin",
      password: "P@ssw0rd",
      is_admin: true,
      email: "mediadmin@medi.com",
      mobile: "09277435476",
      first_name: "Admin",
      middle_name: "is",
      last_name: "trator",
      gender: "male"
    },
    %{
      #2
      username: "masteruser",
      password: "P@ssw0rd",
      is_admin: true,
      email: "mediuser@medi.com",
      mobile: "22222222222",
      first_name: "User",
      middle_name: "M",
      last_name: "me",
      gender: "male"
    },
    %{
      #3
      username: "accountlink_user",
      password: "P@ssw0rd",
      is_admin: true,
      email: "accountlink_user@medi.com",
      mobile: "09123456781",
      first_name: "Account",
      middle_name: "M",
      last_name: "Link",
      gender: "male"
    },
    %{
      #4
      username: "registrationlink_user",
      password: "P@ssw0rd",
      is_admin: false,
      email: "registrationlink_user@medi.com",
      mobile: "09283457297",
      first_name: "Registration",
      middle_name: "A",
      last_name: "Link",
      verification_code: "1234",
      verification: true,
      gender: "male",
      status: "Active"
    },
    %{
      #5
      username: "peme_medina",
      password: "P@ssw0rd",
      is_admin: false,
      email: "memberlink_user@medi.com",
      mobile: "09283457297",
      first_name: "Pem",
      middle_name: "E",
      last_name: "Medina",
      verification_code: "1234",
      verification: true,
      gender: "female",
      status: "Active"
    }
  ]

[u1, u2, u3, u4, u5] = UserSeeder.seed(user_data)

#Create Dropdown
IO.puts "Seeding Dropdown..."
dropdown_data =
  [
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
    # %{
    #   #3
    #   type: "VAT Status",
    #   text: "VAT Exempt",
    #   value: "VAT Exempt"
    # },
    # %{
    #   #4
    #   type: "VAT Status",
    #   text: "VAT-able",
    #   value: "VAT-able"
    # },
    # %{
    #   #5
    #   type: "VAT Status",
    #   text: "Zero-Rated",
    #   value: "Zero-Rated"
    # },

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
%{
  #84
  type: "Occupation",
  text: "Account Executive",
  value: "Account Executive"
},
%{
  #85
  type: "Occupation",
  text: "Accountant",
  value: "Accountant"
},
%{
  #86
  type: "Occupation",
  text: "Actor / Singer",
  value: "Actor / Singer"
},
%{
  #87
  type: "Occupation",
  text: "Actuarian",
  value: "Actuarian"
},
%{
  #88
  type: "Occupation",
  text: "Agriculturist",
  value: "Agriculturist"
},
%{
  #89
  type: "Occupation",
  text: "Analyst / Programmer",
  value: "Analyst / Programmer"
},
%{
  #90
  type: "Occupation",
  text: "Artist",
  value: "Artist"
},
%{
  #91
  type: "Occupation",
  text: "Bank Employee",
  value: "Bank Employee"
},
%{
  #92
  type: "Occupation",
  text: "Businessman",
  value: "Businessman"
},
%{
  #93
  type: "Occupation",
  text: "Call Center Agent",
  value: "Call Center Agent"
},
%{
  #94
  type: "Occupation",
  text: "Carpenter",
  value: "Carpenter"
},
%{
  #95
  type: "Occupation",
  text: "Constraction Worker",
  value: "Constraction Worker"
},
%{
  #96
  type: "Occupation",
  text: "Chef",
  value: "Chef"
},
%{
  #97
  type: "Occupation",
  text: "Chemist",
  value: "Chemist"
},
%{
  #98
  type: "Occupation",
  text: "Consultant / Franchise",
  value: "Consultant / Franchise"
},
%{
  #99
  type: "Occupation",
  text: "Devt as Contractor",
  value: "Devt as Contractor"
},
%{
  #100
  type: "Occupation",
  text: "Cooks / Bartender / Waiters",
  value: "Cooks / Bartender / Waiters"
},
%{
  #101
  type: "Occupation",
  text: "Dentist / Dental Surgeon / Dietitian / Nutritionist Director",
  value: "Dentist / Dental Surgeon / Dietitian / Nutritionist Director"
},
%{
  #102
  type: "Occupation",
  text: "Drivers / Messenger / Courier",
  value: "Drivers / Messenger / Courier"
},
%{
  #103
  type: "Occupation",
  text: "Editor",
  value: "Editor"
},
%{
  #104
  type: "Occupation",
  text: "Engineer",
  value: "Engineer"
},
%{
  #105
  type: "Occupation",
  text: "Events Planner / Coordinator / Examiner",
  value: "Events Planner / Coordinator / Examiner"
},
%{
  #106
  type: "Occupation",
  text: "Fashion Designer",
  value: "Fashion Designer"
},
%{
  #107
  type: "Occupation",
  text: "Finance Analyst",
  value: "Finance Analyst"
},
%{
  #108
  type: "Occupation",
  text: "Flight Attendant",
  value: "Flight Attendant"
},
%{
  #109
  type: "Occupation",
  text: "Foreman",
  value: "Foreman"
},
%{
  #110
  type: "Occupation",
  text: "Government Official",
  value: "Government Official"
},
%{
  #111
  type: "Occupation",
  text: "Government Employee",
  value: "Government Employee"
},
%{
  #112
  type: "Occupation",
  text: "Hairdresser / Beautician",
  value: "Hairdresser / Beautician"
},
%{
  #113
  type: "Occupation",
  text: "Hotel Housekeeping Staff",
  value: "Hotel Housekeeping Staff"
},
%{
  #114
  type: "Occupation",
  text: "Hotel Senior Personnel",
  value: "Hotel Senior Personnel"
},
%{
  #115
  type: "Occupation",
  text: "Housewife",
  value: "Housewife"
},
%{
  #116
  type: "Occupation",
  text: "Insurance Underwriter",
  value: "Insurance Underwriter"
},
%{
  #117
  type: "Occupation",
  text: "Insurance Agent",
  value: "Insurance Agent"
},
%{
  #118
  type: "Occupation",
  text: "Interior Decorator",
  value: "Interior Decorator"
},
%{
  #119
  type: "Occupation",
  text: "IT Consultant / DB Admin",
  value: "IT Consultant / DB Admin"
},
%{
  #120
  type: "Occupation",
  text: "Journalist",
  value: "Journalist"
},
%{
  #121
  type: "Occupation",
  text: "Junior Executive",
  value: "Junior Executive"
},
%{
  #122
  type: "Occupation",
  text: "Laborer / Factory Worker",
  value: "Laborer / Factory Worker"
},
%{
  #123
  type: "Occupation",
  text: "Landlord",
  value: "Landlord"
},
%{
  #124
  type: "Occupation",
  text: "Lawyer",
  value: "Lawyer"
},
%{
  #125
  type: "Occupation",
  text: "Logistics Officer",
  value: "Logistics Officer"
},
%{
  #126
  type: "Occupation",
  text: "Medical Representative",
  value: "Medical Representative"
},
%{
  #127
  type: "Occupation",
  text: "Medical Technologist",
  value: "Medical Technologist"
},
%{
  #128
  type: "Occupation",
  text: "Midwife",
  value: "Midwife"
},
%{
  #129
  type: "Occupation",
  text: "Militar Officer",
  value: "Military Officer"
},
%{
  #130
  type: "Occupation",
  text: "Military Personnel",
  value: "Military Personnel"
},
%{
  #131
  type: "Occupation",
  text: "Newsman",
  value: "Newsman"
},
%{
  #132
  type: "Occupation",
  text: "Nurse",
  value: "Nurse"
},
%{
  #133
  type: "Occupation",
  text: "Office Personnel",
  value: "Office Personnel"
},
%{
  #134
  type: "Occupation",
  text: "OFW",
  value: "OFW"
},
%{
  #135
  type: "Occupation",
  text: "Pharmacist",
  value: "Pharmacist"
},
%{
  #136
  type: "Occupation",
  text: "Photographer",
  value: "Photographer"
},
%{
  #137
  type: "Occupation",
  text: "Physical Therapist",
  value: "Physical Therapist"
},
%{
  #138
  type: "Occupation",
  text: "Physician",
  value: "Physician"
},
%{
  #139
  type: "Occupation",
  text: "Pilot",
  value: "Pilot"
},
%{
  #140
  type: "Occupation",
  text: "Police Officer",
  value: "Police Officer"
},
%{
  #141
  type: "Occupation",
  text: "Producer",
  value: "Producer"
},
%{
  #142
  type: "Occupation",
  text: "Production Assistant",
  value: "Production Assistant"
},
%{
  #143
  type: "Occupation",
  text: "Professor",
  value: "Professor"
},
%{
  #144
  type: "Occupation",
  text: "Purchaser",
  value: "Purchaser"
},
%{
  #145
  type: "Occupation",
  text: "Quality Controller",
  value: "Quality Controller"
},
%{
  #146
  type: "Occupation",
  text: "Real State Broker",
  value: "Real State Broker"
},
%{
  #147
  type: "Occupation",
  text: "Registrar",
  value: "Registrar"
},
%{
  #148
  type: "Occupation",
  text: "Religious Order",
  value: "Religious Order "
},
%{
  #149
  type: "Occupation",
  text: "Researcher",
  value: "Researcher"
},
%{
  #150
  type: "Occupation",
  text: "Retired",
  value: "Retired"
},
%{
  #151
  type: "Occupation",
  text: "Salesman",
  value: "Salesman"
},
%{
  #152
  type: "Occupation",
  text: "Seaman",
  value: "Seaman"
},
%{
  #153
  type: "Occupation",
  text: "Secretary / Receptionist",
  value: "Secretary / Receptionist"
},
%{
  #154
  type: "Occupation",
  text: "Security Guard / Fireman",
  value: "Security Guard / Fireman"
},
%{
  #155
  type: "Occupation",
  text: "Senior Executive",
  value: "Senior Executive"
},
%{
  #156
  type: "Occupation",
  text: "Stockholder",
  value: "Stockholder"
},
%{
  #157
  type: "Occupation",
  text: "Storekeeper / Custodian(Super Student)",
  value: "Storekeeper / Custodian(Super Student)"
},
%{
  #158
  type: "Occupation",
  text: "Teacher",
  value: "Teacher"
},
%{
  #159
  type: "Occupation",
  text: "Technician / Electrician",
  value: "Technician / Electrician"
},
%{
  #160
  type: "Occupation",
  text: "Trainor / Coach / Gym Instruct",
  value: "Trainor / Coach / Gym Instruct"
},
%{
  #161
  type: "Occupation",
  text: "TV/Radio Commentator",
  value: "TV/Radio Commentator"
},
%{
  #162
  type: "Occupation",
  text: "Unemployed",
  value: "Unemployed"
},
%{
  #163
  type: "Occupation",
  text: "School Principal / Dean",
  value: "School Principal / Dean"
},
%{
  #164
  type: "Occupation",
  text: "Optometrist",
  value: "Optometrist"
},
%{
  #165
  type: "Occupation",
  text: "Radiologist",
  value: "Radiologist"
},
%{
  #166
  type: "Occupation",
  text: "Geologist",
  value: "Geologist"
},
%{
  #167
  type: "Occupation",
  text: "Others",
  value: "Others"
},
%{
  #168
  type: "Occupation",
  text: "EQB Director",
  value: "EQB Officer"
},
%{
  #169
  type: "Occupation",
  text: "EQB Staff",
  value: "EQB Staff"
},
%{
  #170
  type: "Occupation",
  text: "Resigned EQB Officer",
  value: "Resigned EQB Officer"
},
%{
  #171
  type: "Occupation",
  text: "Equicom Group Director",
  value: "Equicom Group Director"
},
%{
  #172
  type: "Occupation",
  text: "Equicom Group Officer",
  value: "Equicom Group Officer"
},
%{
  #173
  type: "Occupation",
  text: "Tieup/Affinity Director",
  value: "Tieup/Affinity Director"
},
%{
  #174
  type: "Occupation",
  text: "Tieup/Aff Officer",
  value: "Tieup/Aff Officer"
},
%{
  #175
  type: "Occupation",
  text: "Tieup/Aff Staff",
  value: "Tieup/Aff Staff"
},
%{
  #176
  type: "Occupation",
  text: "Librarian",
  value: "Librarian"
},
%{
  #177
  type: "Occupation",
  text: "Web Developer",
  value: "Web Developer"
},
%{
  #178
  type: "Occupation",
  text: "Musician",
  value: "Musician"
},
%{
  #179
  type: "Occupation",
  text: "BPO Employee",
  value: "BPO Employee"
},
%{
  #180
  type: "Occupation",
  text: "Outlet/Retail Store Employee",
  value: "Outlet/Retail Store Employee"
},
%{
  #181
  type: "Occupation",
  text: "Radiologist(X-Ray)",
  value: "Radiologist(X-Ray)"
},
%{
  #182
  type: "Occupation",
  text: "School Principal",
  value: "School Principal"
},
%{
  #183
  type: "Occupation",
  text: "College Dean",
  value: "College Dean"
},
%{
  #184
  type: "Occupation",
  text: "Secured Account",
  value: "Secured Account"
},
%{
  #185
  type: "Occupation",
  text: "Guarantee Account",
  value: "Guarantee Account"
}
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
 d81, d82, d83, d84, d85,
 d86, d87, d88, d89, d90,
 d91, d92, d93, d94, d95,
 d96, d97, d98, d99, d100,
 d101, d102, d103, d104, d105,
 d106, d107, d108, d109, d110,
 d111, d112, d113, d114, d115,
 d116, d117, d118, d119, d120,
 d121, d122, d123, d124, d125,
 d126, d127, d128, d129, d130,
 d131, d132, d133, d134, d135,
 d136, d137, d138, d139, d140,
 d141, d142, d143, d144, d145,
 d146, d147, d148, d149, d150,
 d151, d152, d153, d154, d155,
 d156, d157, d158, d159, d160,
 d161, d162, d163, d164, d165,
 d166, d167, d168, d169, d170,
 d171, d172, d173, d174, d175,
 d176, d177, d178, d179, d180,
 d181, d182, d183, d184, d185] =
   DropdownSeeder.seed(dropdown_data)

#End of Dropdown

#Create Facility
IO.puts "Seeding facility..."
facility_data =
  [
    %{
      #1
      "code" => "880000000006035",
      "name" => "MAKATI MEDICAL CENTER",
      "license_name" => "licensename1",
      "phic_accreditation_from" => "02-17-2011",
      "phic_accreditation_to" => "02-17-2011",
      "phic_accreditation_no" => "45654665",
      "status" => "Affiliated",
      "affiliation_date" =>  "02-17-2011",
      "disaffiliation_date" => "01-17-2012",
      "phone_no" => "7656734",
      "email_address" => "g@medilink.com.ph",
      #logo,
      "line_1" => "Dela Rosa Street",
      "line_2" =>  "Legazpi Village",
      "city" => "Makati",
      "province" => "Metro Manila",
      "region" => "NCR",
      "country" => "Philippines",
      "postal_code" => "1200",
      "longitude" => "121.0146",
      "latitude" => "14.5593",
      "tin" => "234234123456",
      "prescription_term" => 20,
      "credit_term" => 100,
      "credit_limit" => 100,
      "no_of_beds" =>"90",
      "bond" => 0.0,
      "step" => 7,
      "fcategory_id" => d24.id,
      "ftype_id" => d20.id,
      "vat_status_id" => d2.id,
      "prescription_clause_id" => d8.id,
      "payment_mode_id" => d38.id,
      "releasing_mode_id" => d15.id,
      "created_by_id" => u2.id,
      "updated_by_id" => u2.id,
      "withholding_tax" => "15",
      "bank_account_no" => "1234567890123456"
    },
    %{
      #2
      "code" => "880000000006024",
      "name" => "CHINESE GENERAL HOSPITAL & MEDICAL CENTER",
      "license_name" => "licensename1",
      "phic_accreditation_from" => "02-17-2011",
      "phic_accreditation_to" => "02-17-2011",
      "phic_accreditation_no" => "45654665",
      "status" => "Affiliated",
      "affiliation_date" =>  "02-17-2011",
      "disaffiliation_date" => "01-17-2012",
      "phone_no" => "7656734",
      "email_address" => "g@medilink.com.ph",
      #logo,
      "line_1" => "286 Radial Road 8",
      "line_2" => "Santa Cruz",
      "city" => "Manila",
      "province" => "Metro Manila",
      "region" => "NCR",
      "country" => "Philippines",
      "postal_code" => "1014",
      "longitude" => "120.9881",
      "latitude" => "14.6259",
      "tin" => "234234123456",
      "prescription_term" => 20,
      "credit_term" => 100,
      "credit_limit" => 100,
      "no_of_beds" => "90",
      "bond" => 0.0,
      "step" => 7,
      "fcategory_id" => d24.id,
      "ftype_id" => d20.id,
      "vat_status_id" => d2.id,
      "prescription_clause_id" => d8.id,
      "payment_mode_id" => d38.id,
      "releasing_mode_id" => d15.id,
      "created_by_id" => u2.id,
      "updated_by_id" => u2.id,
      "withholding_tax" => "15",
      "bank_account_no" => "1234567890123456"
    },
    %{
      #3
      "code" => "880000000013931",
      "name" => "MYHEALTH CLINIC - SM NORTH EDSA",
      "license_name" => "licensename1",
      "phic_accreditation_from" => "02-17-2011",
      "phic_accreditation_to" => "02-17-2011",
      "phic_accreditation_no" => "45654665",
      "status" => "Affiliated",
      "affiliation_date" =>  "02-17-2011",
      "disaffiliation_date" => "01-17-2012",
      "phone_no" => "7656734",
      "email_address" => "g@medilink.com.ph",
      #logo,
      "line_1" => "SM City North SM City North EDSA Annex 1 Tunnel",
      "line_2" => "Bago Bantay",
      "city" => "Quezon City",
      "province" =>"Metro Manila",
      "region" => "NCR",
      "country" => "Philippines",
      "postal_code" => "1100",
      "longitude" => "121.0281",
      "latitude" => "14.6567",
      "tin" => "234234123456",
      "prescription_term" => 20,
      "credit_term" => 100,
      "credit_limit" => 100,
      "no_of_beds" => "90",
      "bond " =>0.0,
      "step" => 7,
      "fcategory_id" => d23.id,
      "ftype_id" => d18.id,
      "vat_status_id" => d2.id,
      "prescription_clause_id" => d8.id,
      "payment_mode_id" => d38.id,
      "releasing_mode_id" => d15.id,
      "created_by_id" => u2.id,
      "updated_by_id" => u2.id,
      "withholding_tax" => "15",
      "bank_account_no" => "1234567890123456"
    },
    %{
      #4
      "code" => "880000000000359",
      "name" => "CALAMBA MEDICAL CENTER",
      "license_name" => "licensename1",
      "phic_accreditation_from" => "02-17-2011",
      "phic_accreditation_to" => "02-17-2012",
      "phic_accreditation_no" => "45654665",
      "status" => "Affiliated",
      "affiliation_date" =>  "02-17-2011",
      "disaffiliation_date" => "01-17-2012",
      "phone_no" => "7656734",
      "email_address" => "g@medilink.com.ph",
      #logo,
      "line_1" => "1234567",
      "line_2" => "1234568",
      "city" => "Makati",
      "province" => "Metro Manila",
      "region" => "NCR",
      "country" => "Philippines",
      "postal_code" => "1206",
      "longitude" => "121.1544",
      "latitude" => "14.2066",
      "tin" => "234234123456",
      "prescription_term" => 20,
      "credit_term" => 100,
      "credit_limit" => 100,
      "no_of_beds" => "90",
      "bond" => 0.0,
      "step" => 7,
      "fcategory_id" => d22.id,
      "ftype_id" => d20.id,
      "vat_status_id" => d2.id,
      "prescription_clause_id" => d8.id,
      "payment_mode_id" => d38.id,
      "releasing_mode_id" => d15.id,
      "created_by_id" => u2.id,
      "updated_by_id" => u2.id,
      "withholding_tax" => "15",
      "bank_account_no" => "1234567890123456"
    },
    %{
      #5
      "code" => "880000000001724",
      "name" => "OUR LADY OF PILLAR MEDICAL CENTER",
      "license_name" => "licensename1",
      "phic_accreditation_from" => "02-17-2011",
      "phic_accreditation_to" => "02-17-2012",
      "phic_accreditation_no" => "45654665",
      "status" => "Affiliated",
      "affiliation_date" =>  "02-17-2011",
      "disaffiliation_date" => "01-17-2012",
      "phone_no" => "7656734",
      "email_address" => "g@medilink.com.ph",
      #logo,
      "line_1" => "1234567",
      "line_2" => "1234568",
      "city" => "Makati",
      "province" => "Metro Manila",
      "region" => "NCR",
      "country" => "Philippines",
      "postal_code" => "1206",
      "longitude" => "120.9392",
      "latitude" => "14.4193",
      "tin" => "234234123456",
      "prescription_term" => 20,
      "credit_term" => 100,
      "credit_limit" => 100,
      "no_of_beds" => "90",
      "bond" => 0.0,
      "step" => 7,
      "fcategory_id" => d22.id,
      "ftype_id" => d20.id,
      "vat_status_id" => d2.id,
      "prescription_clause_id" => d8.id,
      "payment_mode_id" => d38.id,
      "releasing_mode_id" => d15.id,
      "created_by_id" => u1.id,
      "updated_by_id" => u2.id,
      "withholding_tax" => "15",
      "bank_account_no" => "1234567890123456"
    }
  ]

[f1, f2, f3, f4, f5] = FacilitySeeder.seed(facility_data)
#End of Create Facility

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
#End of Create Industry

#Create AccountGroup
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
#End of Create AccountGroup

#Create Account
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
#End of Create Account

# Create Account Hierarchy of Eligible Dependents
IO.puts "Seeding Account Hierarchy of Eligible Dependents"
account_hoed_data =
  [
    # Married
    # 1
    %{
      account_group_id: ag1.id,
      hierarchy_type: "Married Employee",
      dependent: "Spouse",
      ranking: 1
    },
    # 2
    %{
      account_group_id: ag1.id,
      hierarchy_type: "Married Employee",
      dependent: "Child",
      ranking: 2
    },
    # 3
    %{
      account_group_id: ag1.id,
      hierarchy_type: "Married Employee",
      dependent: "Parent",
      ranking: 3
    },
    # 4
    %{
      account_group_id: ag1.id,
      hierarchy_type: "Married Employee",
      dependent: "Sibling",
      ranking: 4
    },
    # Single
    # 5
    %{
      account_group_id: ag1.id,
      hierarchy_type: "Single Employee",
      dependent: "Parent",
      ranking: 1
    },
    # 6
    %{
      account_group_id: ag1.id,
      hierarchy_type: "Single Employee",
      dependent: "Sibling",
      ranking: 2
    },
    # Single Parent
    # 7
    %{
      account_group_id: ag1.id,
      hierarchy_type: "Single Parent Employee",
      dependent: "Child",
      ranking: 1
    },
    # 8
    %{
      account_group_id: ag1.id,
      hierarchy_type: "Single Parent Employee",
      dependent: "Parent",
      ranking: 2
    },
    # 9
    %{
      account_group_id: ag1.id,
      hierarchy_type: "Single Parent Employee",
      dependent: "Sibling",
      ranking: 3
    }
  ]
[acc_hoed1, acc_hoed2, acc_hoed3,
 acc_hoed4, acc_hoed5, acc_hoed6,
 acc_hoed7, acc_hoed8, acc_hoed9] =
   AccountHierarchyOfEligibleDependentSeeder.seed(account_hoed_data)
# End of Hierarchy of Eligible Dependents

#Create Account Group Address
IO.puts "Seeding Account Group Address..."
account_group_address_data =
  [
    %{
      #1
      account_group_id: ag1.id,
      line_1: "Ade",
      line_2: "624",
      postal_code: "4232",
      city: "Paterno Street Quiapo Manila",
      country: "Philippines",
      type: "Account Address",
      province: "Metro Manila",
      is_check: true,
      region: "NCR"
    }
  ]

[aga1] = AccountGroupAddressSeeder.seed(account_group_address_data)
#End of Create Account Group Address

#Create Conctact
IO.puts "Seeding Contact..."
contact_data =
  [
    %{
      #1
      last_name: "Jollibee Corporation",
      first_name: "First Name",
      department: nil,
      designation: "Testing",
      email: "jollibee_corporation@gmail.com",
      ctc: "TESTCTC",
      ctc_date_issued: Ecto.Date.cast!("2017-08-01"),
      ctc_place_issued: "TEST PLACE CTC",
      passport_no: "TESTNUMBER",
      passport_date_issued: Ecto.Date.cast!("2017-08-01"),
      passport_place_issued: "TEST PLACE PASSPORT",
      type: "Contact Person"
    },
    %{
      #2
      last_name: "Jollibee Corporation 2",
      first_name: "First Name",
      department: nil,
      designation: "Testing 2",
      email: "jollibee_corporation2@gmail.com",
      ctc: "TESTCTC 2",
      ctc_date_issued: Ecto.Date.cast!("2017-09-01"),
      ctc_place_issued: "TEST PLACE CTC 2",
      passport_no: "TESTNUMBER 2",
      passport_date_issued: Ecto.Date.cast!("2017-09-01"),
      passport_place_issued: "TEST PLACE PASSPORT 2",
      type: "Corp Signatory"
    }
  ]

[contact1, contact2] = ContactSeeder.seed(contact_data)
#End of Create Contact

#Create Account Group Conctact
IO.puts "Seeding Account Group Contact..."
account_group_contact_data =
  [
    %{
      #1
      account_group_id: ag1.id,
      contact_id: contact1.id
    },
    %{
      #1
      account_group_id: ag1.id,
      contact_id: contact2.id
    }
  ]

[account_group_contact1, account_group_contact2] = AccountGroupContactSeeder.seed(account_group_contact_data)
#End of Create Contact

#Create Phones
IO.puts "Seeding Phones..."
phone_data =
  [
    %{
      #1
      contact_id: contact1.id,
      number: "09111212121",
      type: "mobile"
    },
    %{
      #2
      contact_id: contact1.id,
      number: "424545454",
      type: "telephone"
    },
    %{
      #3
      contact_id: contact2.id,
      number: "09199875463",
      type: "mobile"
    },
    %{
      #4
      contact_id: contact2.id,
      number: "424545454",
      type: "telephone"
    }
  ]

[phone1, phone2, phone3, phone4] = PhoneSeeder.seed(phone_data)
#End of Phones

#Create Payment Account
IO.puts "Seeding Payment Account..."
payment_account_data =
  [
    %{
      #1
      payee_name: nil,
      account_group_id: ag1.id,
      account_tin: "1030232234234234",
      vat_status: "Full VAT-able",
      mode_of_payment: "Check",
      p_sched_of_payment: "DAILY",
      d_sched_of_payment: "ANNUAL",
      previous_carrier: "123412",
      attached_point: nil,
      revolving_fund: nil,
      threshold: nil,
      funding_arrangement: "Full Risk",
      authority_debit: false
    }
  ]

[b1] = PaymentAccountSeeder.seed(payment_account_data)
#End of Payment Account

#Create Bank
IO.puts "Seeding bank..."
bank_data =
  [
    %{
      #1
      account_name: "Metropolitan Bank and Trust Company",
      account_no: "00001",
      account_status: "Active",
      account_group_id: ag1.id
    }
  ]

[b1] = BankSeeder.seed(bank_data)
#End of Create Bank

#Create Bank Branch
IO.puts "Seeding Bank Branch.."
bank_branch_data =
  [
    %{
      #1
      bank_id: b1.id,
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
    }
  ]

[bb1] = BankBranchSeeder.seed(bank_branch_data)
#End of Bank Branch

#Migrate Seed in the Seeder part 2

#Create Procedure Category
IO.puts "Seeding Procedure Category..."
procedure_category_data =
  [
    %{
      #1
      name: "Anesthesia",
      code: "00100-01999"
    },
    %{
      #2
      name: "Surgery",
      code: "10021-69990"
    },
    %{
      #3
      name: "Radiology Procedures",
      code: "70010-79999"
    },
    %{
      #4
      name: "Pathology and Laboratory Procedures",
      code: "80047-89398"
    },
    %{
      #5
      name: "Medicine Services and Procedures",
      code: "90281-99607"
    },
    %{
      #6
      name: "Evaluation and Management Services",
      code: "99201-99499"
    },
    %{
      #7
      name: "Category II Codes",
      code: "0001F-9007F"
    },
    %{
      #8
      name: "Multianalyte Assay",
      code: "0001M-0009M"
    },
    %{
      #9
      name: "Laboratory Analyses",
      code: "0001U-0005U"
    },
    %{
      #10
      name: "Category III Codes",
      code: "0042T-0478T"
    },
    %{
      #11
      name: "Modifiers",
      code: "cpt-modifiers"
    }
  ]
[pc1, pc2, pc3, pc4, pc5, pc6, pc7, pc8, pc9, pc10, pc11] = ProcedureCategorySeeder.seed(procedure_category_data)

#Create Procedure
IO.puts "Seeding Procedure ..."
procedure_data =
  [
    %{
      #1
      code: "83498",
      description: "HYDROXYPROGESTERONE, 17-D",
      type: "Diagnostic",
      procedure_category_id: pc4.id
    },
    %{
      #2
      code: "88271",
      description: "MOLECULAR CYTOGENETICS; DNA PROBE, EACH (EG, FISH)",
      type: "Diagnostic",
      procedure_category_id: pc4.id
    },
    %{
      #3
      code: "84156",
      description: "PROTEIN, TOTAL, EXCEPT BY REFRACTOMETRY; URINE",
      type: "Diagnostic",
      procedure_category_id: pc4.id
    },
    %{
      #4
      code: "82507",
      description: "CITRATE",
      type: "Diagnostic",
      procedure_category_id: pc4.id
    },
    %{
      #5
      code: "83497",
      description: "HYDROXYINDOLACETIC ACID, 5-(HIAA)",
      type: "Diagnostic",
      procedure_category_id: pc4.id
    },
    %{
      #6
      code: "84060",
      description: "PHOSPHATASE, ACID; TOTAL",
      type: "Diagnostic",
      procedure_category_id: pc4.id
    },
    %{
      #7
      code: "82024",
      description: "ADRENOCORTICOTROPIC HORMONE (ACTH)",
      type: "Diagnostic",
      procedure_category_id: pc4.id
    },
    %{
      #8
      code: "87015",
      description: "Concentration (any type), for infectious agents",
      type: "Diagnostic",
      procedure_category_id: pc4.id
    },
    %{
      #9
      code: "87206",
      description: "SMEAR, PRIMARY SOURCE WITH INTERPRETATION; FLUORESCENT AND/OR ACID FAST STAIN FOR BACTERIA, FUNGI, PARASITES, VIRUSES OR CELL TYPES",
      type: "Diagnostic",
      procedure_category_id: pc4.id
    },
    %{
      #10
      code: "82042",
      description: "ALBUMIN; URINE OR OTHER SOURCE, QUANTITATIVE, EACH SPECIMEN",
      type: "Diagnostic",
      procedure_category_id: pc4.id
    },
    %{
      #11
      code: "82040",
      description: "ALBUMIN; SERUM, PLASMA OR WHOLE BLOOD",
      type: "Diagnostic",
      procedure_category_id: pc4.id
    },
    %{
      #12
      code: "74182",
      description: "MAGNETIC RESONANCE (EG, PROTON) IMAGING, ABDOMEN; WITH CONTRAST MATERIAL(S)",
      type: "Diagnostic",
      procedure_category_id: pc4.id
    },
    %{
      #13
      code: "72147",
      description: "MAGNETIC RESONANCE (EG, PROTON) IMAGING, SPINAL CANAL AND CONTENTS, THORACIC; WITH CONTRAST MATERIAL",
      type: "Diagnostic",
      procedure_category_id: pc3.id
    },
    %{
      #14
      code: "36831",
      description: "THROMBECTOMY, OPEN, ARTERIOVENOUS FISTULA WITHOUT REVISION, AUTOGENOUS OR NONAUTOGENOUS DIALYSIS GRAFT",
      type: "Diagnostic",
      procedure_category_id: pc2.id
    },
    %{
      #15
      code: "93886",
      description: "TRANSCRANIAL DOPPLER STUDY OF THE INTRACRANIAL ARTERIES; COMPLETE STUDY",
      type: "Diagnostic",
      procedure_category_id: pc5.id
    },
    %{
      #16
      code: "93971",
      description: "DUPLEX SCAN OF EXTREMITY VEINS INCLUDING RESPONSES TO COMPRESSION AND OTHER MANEUVERS; UNILATERAL OR LIMITED STUDY",
      type: "Diagnostic",
      procedure_category_id: pc5.id
    },
    %{
      #17
      code: "76705",
      description: "Ultrasound, abdominal, real time with image documentation; limited (eg, single organ, quadrant, follow-up)",
      type: "Diagnostic",
      procedure_category_id: pc3.id
    },
    %{
      #18
      code: "21356",
      description: "ZYGOMATIC ARCH",
      type: "Diagnostic",
      procedure_category_id: pc2.id
    },
    %{
      #19
      code: "Dental002",
      description: "ORAL PROPHYLAXIS",
      type: "Dental"
    },
    %{
      #20
      code: "Dental003",
      description: "SIMPLE TOOTH EXTRACTION",
      type: "Dental"
    },
    %{
      #21
      code: "Dental004",
      description: "TEMPORARY FILLING",
      type: "Dental"
    },
    %{
      #22
      code: "Dental005",
      description: "SIMPLE REPAIR AND ADJUSTMENT OF DENTURES",
      type: "Dental"
    },
    %{
      #23
      code: "Dental006",
      description: "RECEMENTATION OF JACKET CROWNS, BRIDGES, INLAY AND ONLAY",
      type: "Dental"
    },
    %{
      #24
      code: "Dental007",
      description: "PALLIATIVE TREATMENT OF SIMPLE MOUTH SORES AND BLISTERS",
      type: "Dental"
    },
    %{
      #25
      code: "Dental008",
      description: "DESENSITIZATION OF HYPERSENSITIVE TEETH",
      type: "Dental"
    },
    %{
      #26
      code: "Dental009",
      description: "PERMANENT FILLINGS",
      type: "Dental"
    },
    %{
      #27
      code: "Dental011",
      description: "PERIAPICAL XRAY",
      type: "Dental"
    },
    %{
      #28
      code: "Dental012",
      description: "DEEP SCALING",
      type: "Dental"
    },
    %{
      #29
      code: "Dental013",
      description: "IMPACTION SURGERY",
      type: "Dental"
    },
    %{
      #30
      code: "Dental014",
      description: "ROOT CANAL TREATMENT (RCT)",
      type: "Dental"
    },
    %{
      #31
      code: "Dental016",
      description: "REMOVABLE PARTIAL DENTURE - UNILATERAL",
      type: "Dental"
    },
    %{
      #32
      code: "Dental017",
      description: "BITE-WING X-RAY",
      type: "Dental"
    },
    %{
      #33
      code: "Dental018",
      description: "OCCLUSAL X-RAY",
      type: "Dental"
    },
    %{
      #34
      code: "Dental019",
      description: "TOPICAL FLUORIDE APPLICATION",
      type: "Dental"
    },
    %{
      #35
      code: "Dental020",
      description: "PIT & FISSURE SEALANT",
      type: "Dental"
    },
    %{
      #36
      code: "Dental021",
      description: "LIGHT CURE-BASE FILLING",
      type: "Dental"
    },
    %{
      #37
      code: "Dental022",
      description: "COMPLICATED TOOTH EXTRACTION",
      type: "Dental"
    },
    %{
      #38
      code: "Dental023",
      description: "MINOR SOFT TISSUE SURGERY",
      type: "Dental"
    },
    %{
      #39
      code: "Dental024",
      description: "APICOECTOMY",
      type: "Dental"
    },
    %{
      #40
      code: "Dental025",
      description: "PERIODONTAL SURGERY",
      type: "Dental"
    },
    %{
      #41
      code: "Dental037",
      description: "POST & CORE CASTED TYPE",
      type: "Dental"
    },
    %{
      #42
      code: "Dental038",
      description: "MOUTHGUARD",
      type: "Dental"
    },
    %{
      #43
      code: "Dental039",
      description: "DENTAL X-RAY",
      type: "Dental"
    },
    %{
      #44
      code: "Dental046",
      description: "Dental / Oral Surgeries",
      type: "Dental"
    },
    %{
      #45
      code: "Dental057",
      description: "GUM TREATMENT FOR CASES LIKE INFLAMMATION OR BLEEDING",
      type: "Dental"
    },
    %{
      #46
              code: "Dental069",
      description: "EMERGENCY DENTAL TREATMENT",
      type: "Dental"
    },
    %{
      #47
      code: "Dental099",
      description: "Oral Incision and drainage",
      type: "Dental"
    },
    %{
      #48
      code: "Dental114",
      description: "ORAL PROPHYLAXIS WITH FLUORIDE BRUSHING",
      type: "Dental"
    }
  ]
[pr1, pr2, pr3, pr4, pr5,
 pr6, pr7, pr8, pr9, pr10,
 pr11, pr12, pr13, pr14, pr15,
 pr16, pr17, pr18, pr19, pr20,
 pr21, pr22, pr23, pr24, pr25,
 pr26, pr27, pr28, pr29, pr30,
 pr31, pr32, pr33, pr34, pr35,
 pr36, pr37, pr38, pr39, pr40,
 pr41, pr42, pr43, pr44, pr45,
 pr46, pr47, pr48] =
   ProcedureSeeder.seed(procedure_data)

 #Create Diagnosis
IO.puts "Seeding diagnosis..."
diagnosis_data = [
  #1
  %{
    code: "A00.0",
    description: "CHOLERA: Cholera due to Vibrio cholerae 01, biovar cholerae",
    group_description: "CHOLERA",
    type: "Dreaded",
    congenital: "N",
    exclusion_type: "General Exclusion"
  },
  #2
  %{
    code: "A00.1",
    description: "CHOLERA: Cholera due to Vibrio cholerae 01, biovar eltor",
    group_description: "CHOLERA",
    type: "Dreaded",
    congenital: "N",
    exclusion_type: "Pre-existing condition"
  },
  #3
  %{
    code: "A01.0",
    description: "TYPHOID AND PARATYPHOID FEVERS: Typhoid fever",
    group_description: "TYPHOID AND PARATYPHOID FEVERS",
    type: "Dreaded",
    congenital: "N",
    exclusion_type: "General Exclusion"
  },
  #4
  %{
    code: "A01.1",
    description: "TYPHOID AND PARATYPHOID FEVERS: Paratyphoid fever A",
    group_description: "TYPHOID AND PARATYPHOID FEVERS",
    type: "Dreaded",
    congenital: "N",
    exclusion_type: "Pre-existing condition"
  },
  #5
    %{
      code: "A01.2",
      description: "TYPHOID AND PARATYPHOID FEVERS: Paratyphoid fever B",
      group_description: "TYPHOID AND PARATYPHOID FEVERS",
      type: "Dreaded",
      congenital: "N",
      exclusion_type: "General Exclusion"
    },
    #6
    %{
      code: "A01.3",
      description: "TYPHOID AND PARATYPHOID FEVERS: Paratyphoid fever C",
      group_description: "TYPHOID AND PARATYPHOID FEVERS",
      type: "Dreaded",
      congenital: "N",
      exclusion_type: "Pre-existing condition"
    },
    #7
    %{
      code: "A01.4",
      description: "TYPHOID AND PARATYPHOID FEVERS: Paratyphoid fever, unspecified",
      group_description: "TYPHOID AND PARATYPHOID FEVERS",
      type: "Dreaded",
      congenital: "N",
      exclusion_type: "General Exclusion"
    },
    #8
    %{
      code: "A02.0",
      description: "OTHER SALMONELLA INFECTIONS: Salmonella enteritis",
      group_description: "OTHER SALMONELLA INFECTIONS",
      type: "Dreaded",
      congenital: "N",
      exclusion_type: "Pre-existing condition"
    },
    #9
    %{
      code: "A02.1",
      description: "OTHER SALMONELLA INFECTIONS: Salmonella septicaemia",
      group_description: "OTHER SALMONELLA INFECTIONS",
      type: "Dreaded",
      congenital: "N",
      exclusion_type: "General Exclusion"
    },
    #10
    %{
      code: "A02.2",
      description: "OTHER SALMONELLA INFECTIONS: Localized salmonella infections",
      group_description: "OTHER SALMONELLA INFECTIONS",
      type: "Dreaded",
      congenital: "N",
      exclusion_type: "Pre-existing condition"
    },
    #11
    %{
      code: "A02.8",
      description: "OTHER SALMONELLA INFECTIONS: Other specified salmonella infections",
      group_description: "OTHER SALMONELLA INFECTIONS",
      type: "Dreaded",
      congenital: "N",
      exclusion_type: "General Exclusion"
    },
    #12
    %{
      code: "A02.9",
      description: "OTHER SALMONELLA INFECTIONS: Salmonella infection, unspecified",
      group_description: "OTHER SALMONELLA INFECTIONS",
      type: "Dreaded",
      congenital: "N",
      exclusion_type: "Pre-existing condition"
    },
    #13
    %{
      code: "A03.0",
      description: "SHIGELLOSIS: Shigellosis due to Shigella dysenteriae",
      group_description: "SHIGELLOSIS",
      type: "Dreaded",
      congenital: "N",
      exclusion_type: "General Exclusion"
    },
    #14
    %{
      code: "A03.1",
      description: "SHIGELLOSIS: Shigellosis due to Shigella flexneri",
      group_description: "SHIGELLOSIS",
      type: "Dreaded",
      congenital: "N",
      exclusion_type: "Pre-existing condition"
    },
    #15
    %{
      code: "A03.2",
      description: "SHIGELLOSIS: Shigellosis due to Shigella boydii",
      group_description: "SHIGELLOSIS",
      type: "Dreaded",
      congenital: "N",
      exclusion_type: "General Exclusion"
    },
    #16
    %{
      code: "A03.3",
      description: "SHIGELLOSIS: Shigellosis due to Shigella sonnei",
      group_description: "SHIGELLOSIS",
      type: "Dreaded",
      congenital: "N",
      exclusion_type: "Pre-existing condition"
    },
    #17
    %{
      code: "A03.8",
      description: "SHIGELLOSIS: Other shigellosis",
      group_description: "SHIGELLOSIS",
      type: "Dreaded",
      congenital: "N",
      exclusion_type: "General Exclusion"
    },
    #18
    %{
      code: "A03.9",
      description: "SHIGELLOSIS: Shigellosis, unspecified",
      group_description: "SHIGELLOSIS",
      type: "Dreaded",
      congenital: "N",
      exclusion_type: "Pre-existing condition"
    },
    #19
    %{
      code: "A04.0",
      description: "OTHER BACTERIAL INTESTINAL INFECTIONS: Enteropathogenic Escherichia coli infection",
      group_description: "OTHER BACTERIAL INTESTINAL INFECTIONS",
      type: "Dreaded",
      congenital: "N",
      exclusion_type: "General Exclusion"
    },
    #20
    %{
      code: "A04.1",
      description: "OTHER BACTERIAL INTESTINAL INFECTIONS: Enterotoxigenic Escherichia coli infection",
      group_description: "OTHER BACTERIAL INTESTINAL INFECTIONS",
      type: "Dreaded",
      congenital: "N",
      exclusion_type: "Pre-existing condition"
    },
    #21
  %{
    code: "A04.2",
    description: "ACTINOMYCOSIS: Abdominal actinomycosis",
    group_description: "OTHER BACTERIAL INTESTINAL INFECTIONS",
    type: "Non-Dreaded",
    congenital: "N",
    exclusion_type: "General Exclusion"
  },
  #22
  %{
    code: "A04.3",
    description: "OTHER BACTERIAL INTESTINAL INFECTIONS: Enterohaemorrhagic Escherichia coli infection",
    group_description: "OTHER BACTERIAL INTESTINAL INFECTIONS",
    type: "Non-Dreaded",
    congenital: "N",
    exclusion_type: "Pre-existing condition"
  },
  #23
  %{
    code: "A04.4",
    description: "OTHER BACTERIAL INTESTINAL INFECTIONS: Other intestinal Escherichia coli infections",
    group_description: "OTHER BACTERIAL INTESTINAL INFECTIONS",
    type: "Non-Dreaded",
    congenital: "N",
    exclusion_type: "General Exclusion"
  },
  #24
  %{
    code: "A04.5",
    description: "OTHER BACTERIAL INTESTINAL INFECTIONS: Campylobacter enteritis",
    group_description: "OTHER BACTERIAL INTESTINAL INFECTIONS",
    type: "Non-Dreaded",
    congenital: "N",
    exclusion_type: "Pre-existing condition"
  },
  #25
    %{
      code: "A04.6",
      description: "OTHER BACTERIAL INTESTINAL INFECTIONS: Enteritis due to Yersinia enterocolitica",
      group_description: "OTHER BACTERIAL INTESTINAL INFECTIONS",
      type: "Non-Dreaded",
      congenital: "N",
      exclusion_type: "General Exclusion"
    },
    #26
    %{
      code: "A04.7",
      description: "OTHER BACTERIAL INTESTINAL INFECTIONS: Enterocolitis due to Clostridium difficile",
      group_description: "OTHER BACTERIAL INTESTINAL INFECTIONS",
      type: "Non-Dreaded",
      congenital: "N",
      exclusion_type: "Pre-existing condition"
    },
    #27
    %{
      code: "A04.8",
      description: "OTHER BACTERIAL INTESTINAL INFECTIONS: Other specified bacterial intestinal infections",
      group_description: "OTHER BACTERIAL INTESTINAL INFECTIONS",
      type: "Non-Dreaded",
      congenital: "N",
      exclusion_type: "General Exclusion"
    },
    #28
    %{
      code: "A04.9",
      description: "OTHER BACTERIAL INTESTINAL INFECTIONS: Bacterial intestinal infection, unspecified",
      group_description: "OTHER BACTERIAL INTESTINAL INFECTIONS",
      type: "Non-Dreaded",
      congenital: "N",
      exclusion_type: "Pre-existing condition"
    },
    #29
    %{
      code: "A05.0",
      description: "OTHER BACTERIAL FOODBORNE INTOXICATIONS: Foodborne staphylococcal intoxication",
      group_description: "OTHER BACTERIAL FOODBORNE INTOXICATIONS",
      type: "Non-Dreaded",
      congenital: "N",
      exclusion_type: "General Exclusion"
    },
    #30
    %{
      code: "A05.1",
      description: "OTHER BACTERIAL FOODBORNE INTOXICATIONS: Botulism",
      group_description: "OTHER BACTERIAL FOODBORNE INTOXICATIONS",
      type: "Non-Dreaded",
      congenital: "N",
      exclusion_type: "Pre-existing condition"
    },
    #31
    %{
      code: "Z71.1",
      description: "PERSONS ENCOUNTERING HEALTH
      SERVICES FOR OTHER COUNSELLING AND MEDICAL
      ADVICE, NOT ELSEWHERE CLASSIFIED:
      Person with feared complaint in whom no diagnosis is made",
      group_description: "PERSONS ENCOUNTERING HEALTH SERVICES
      FOR OTHER COUNSELLING AND MEDICAL ADVICE,
      NOT ELSEWHERE CLASSIFIED",
      type: "Non-Dreaded",
      congenital: "N",
      exclusion_type: "General Exclusion"
    },
    #32
    %{
      code: "Z00.0",
      description: "GENERAL EXAMINATION AND INVESTIGATION OF PERSONS WITHOUT COMPLAINT AND REPORTED DIAGNOSIS: General medical examination",
      group_code: "Z00",
      group_description: "GENERAL EXAMINATION AND INVESTIGATION OF PERSONS WITHOUT COMPLAINT AND REPORTED DIAGNOSIS",
      type: "Non-Dreaded",
      congenital: "N",
      exclusion_type: ""
    },
  ]
  [di1, di2, di3, di4, di5,
   di6, di7, di8, di9, di10,
   di11, di12, di13, di14, di15,
   di16, di17, di18, di19, di20,
   di21, di22, di23, di24, di25,
   di26, di27, di28, di29, di30,
   di31, di32] =
   DiagnosisSeeder.seed(diagnosis_data)

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
  },
  #45
  %{
    name: "Manage Company",
    module: "Company",
    keyword: "manage_company",
    application_id: a1.id,
    status: "sample",
    description: "sample"
  },
  #46
  %{
    name: "Access Company",
    module: "Company",
    keyword: "access_company",
    application_id: a1.id,
    status: "sample",
    description: "sample"
  },
  #47
  %{
    name: "Manage ACU Schedules",
    module: "Acu_Schedules",
    keyword: "manage_acu_schedules",
    application_id: a1.id,
    status: "sample",
    description: "sample"
  },
  #48
  %{
    name: "Manage ProviderLink ACU Schedules",
    module: "ProviderLink_Acu_Schedules",
    keyword: "manage_providerlink_acu_schedules",
    application_id: a1.id,
    status: "sample",
    description: "sample"
  },
  #49
  %{
    name: "Access ACU Schedules",
    module: "Acu_Schedules",
    keyword: "access_acu_schedules",
    application_id: a1.id,
    status: "sample",
    description: "sample"
  },
  #50
  %{
    name: "Access ProviderLink ACU Schedules",
    module: "ProviderLink_Acu_Schedules",
    keyword: "access_providerlink_acu_schedules",
    application_id: a1.id,
    status: "sample",
    description: "sample"
  },
  #51
  %{
    name: "Manage Pharmacies",
    module: "Pharmacies",
    keyword: "manage_pharmacies",
    application_id: a1.id,
    status: "sample",
    description: "sample"
  },
  #52
  %{
    name: "Access Pharmacies",
    module: "Pharmacies",
    keyword: "access_pharmacies",
    application_id: a1.id,
    status: "sample",
    description: "sample"
  },
  #53
  %{
    name: "Manage Miscellaneous",
    module: "Miscellaneous",
    keyword: "manage_miscellaneous",
    application_id: a1.id,
    status: "sample",
    description: "sample"
  },
  #54
  %{
    name: "Access Miscellaneous",
    module: "Miscellaneous",
    keyword: "access_miscellaneous",
    application_id: a1.id,
    status: "sample",
    description: "sample"
  },
  #55
  %{
    name: "Manage Location Groups",
    module: "Location_Groups",
    keyword: "manage_location_groups",
    application_id: a1.id,
    status: "sample",
    description: "sample"
  },
  #56
  %{
    name: "Access Location Groups",
    module: "Location_Groups",
    keyword: "access_location_groups",
    application_id: a1.id,
    status: "sample",
    description: "sample"
  },
  #57
  %{
    name: "Manage User Access",
    module: "User_Access",
    keyword: "manage_user_access",
    application_id: a1.id,
    status: "sample",
    description: "sample"
  },
  #58
  %{
    name: "Access User Access",
    module: "User_Access",
    keyword: "access_user_access",
    application_id: a1.id,
    status: "sample",
    description: "sample"
  },
  #59
  %{
    name: "Manage Company Maintenance",
    module: "Company_Maintenance",
    keyword: "manage_company_maintenance",
    application_id: a1.id,
    status: "sample",
    description: "sample"
  },
  #60
  %{
    name: "Access Company Maintenance",
    module: "Company_Maintenance",
    keyword: "access_company_maintenance",
    application_id: a1.id,
    status: "sample",
    description: "sample"
  },
  #61
  %{
    name: "Manage Home",
    module: "Home",
    keyword: "manage_home",
    application_id: a7.id,
    status: "sample",
    description: "sample"
  },
  #62
  %{
    name: "Access Home",
    module: "Home",
    keyword: "access_home",
    application_id: a7.id,
    status: "sample",
    description: "sample"
  },
  #63
  %{
    name: "Manage LOAs",
    module: "LOAs",
    keyword: "manage_loas",
    application_id: a7.id,
    status: "sample",
    description: "sample"
  },
  #64
  %{
    name: "Access LOAs",
    module: "LOAs",
    keyword: "access_loas",
    application_id: a7.id,
    status: "sample",
    description: "sample"
  },
  #65
  %{
    name: "Manage Batch",
    module: "Batch",
    keyword: "manage_batch",
    application_id: a7.id,
    status: "sample",
    description: "sample"
  },
  #66
  %{
    name: "Access Batch",
    module: "Batch",
    keyword: "access_batch",
    application_id: a7.id,
    status: "sample",
    description: "sample"
  },
  #67
  %{
    name: "Manage Patients",
    module: "Patients",
    keyword: "manage_patients",
    application_id: a7.id,
    status: "sample",
    description: "sample"
  },
  #68
  %{
    name: "Access Patients",
    module: "Patients",
    keyword: "access_patients",
    application_id: a7.id,
    status: "sample",
    description: "sample"
  },
  #69
  %{
    name: "Manage Reports",
    module: "Reports",
    keyword: "manage_reports",
    application_id: a7.id,
    status: "sample",
    description: "sample"
  },
  #70
  %{
    name: "Access Reports",
    module: "Reports",
    keyword: "access_reports",
    application_id: a7.id,
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
 p41, p42, p43, p44, p45,
 p46, p47, p48, p49, p50,
 p51, p52, p53, p54, p55,
 p56, p57, p58, p59, p60,
 p61, p62, p63, p64, p65,
 p66, p67, p68i, p69, p70] =
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
    name: "admin",
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
  #26
  %{
    name: "RegistrationLink User",
    description: "Sample Role for RegistrationLink",
    step: 4,
    created_by_id: u1.id
  },
  #27
  %{
    name: "MemberLink User",
    description: "Sample Role for MemberLink",
    step: 4,
    created_by_id: u1.id
  },
  #28
  %{
    name: "AccountLink User",
    description: "Sample Role for AccountLink",
    step: 4,
    created_by_id: u1.id
  }
]
[r1, r2, r3, r4, r5,
 r6, r7, r8, r9, r10,
 r11, r12, r13, r14, r15,
 r16, r17, r18, r19, r20,
 r21, r22, r23, r24, r25,
 r26, r27, r28] =
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
    role_id: r26.id
  },
  #27
  %{
    application_id: a5.id,
    role_id: r27.id
  },
  #28
  %{
    application_id: a2.id,
    role_id: r28.id
  },
  #29
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
 ra26, ra27, ra28, ra29] =
  role_application_data
  |> RoleApplicationSeeder.seed()

#Create User Role
IO.puts "Seeding user_role..."
user_role_data = [
  #1
  %{
    user_id: u1.id,
    role_id: r21.id
  },
  #2
  %{
    user_id: u2.id,
    role_id: r21.id
  },
  #3
  %{
    user_id: u3.id,
    role_id: r28.id
  },
  #4
  %{
    user_id: u4.id,
    role_id: r26.id
  }
  ##5
  #%{
  #  user_id: u1.id,
  #  role_id: r26.id
  #}
]
[ra1, ra2, ra3, ra4] = UserRoleSeeder.seed(user_role_data)

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
    role_id: r26.id
  },
  #46
  %{
    permission_id: p42.id,
    role_id: r26.id
  },
  #47
  %{
    permission_id: p43.id,
    role_id: r26.id
  },
  #48
  %{
    permission_id: p44.id,
    role_id: r26.id
  },
  #49
  %{
    permission_id: p39.id,
    role_id: r28.id
  },
  #50
  %{
    permission_id: p40.id,
    role_id: r28.id
  },
  #51
  %{
    permission_id: p41.id,
    role_id: r21.id
  },
  #52
  %{
    permission_id: p42.id,
    role_id: r21.id
  },
  #53
  %{
    permission_id: p43.id,
    role_id: r21.id
  },
  #54
  %{
    permission_id: p44.id,
    role_id: r21.id
  },
  #55
  %{
    permission_id: p45.id,
    role_id: r21.id
  },
  #56
  %{
    permission_id: p46.id,
    role_id: r21.id
  },
  #57
  %{
    permission_id: p47.id,
    role_id: r21.id
  },
  #58
  %{
    permission_id: p48.id,
    role_id: r21.id
  },
  #59
  %{
    permission_id: p49.id,
    role_id: r21.id
  },
  #60
  %{
    permission_id: p50.id,
    role_id: r21.id
  },
  #61
  %{
    permission_id: p51.id,
    role_id: r21.id
  },
  #62
  %{
    permission_id: p52.id,
    role_id: r21.id
  },
  #63
  %{
    permission_id: p53.id,
    role_id: r21.id
  },
  #64
  %{
    permission_id: p54.id,
    role_id: r21.id
  },
  #65
  %{
    permission_id: p55.id,
    role_id: r21.id
  },
  #66
  %{
    permission_id: p56.id,
    role_id: r21.id
  },
  #67
  %{
    permission_id: p57.id,
    role_id: r21.id
  },
  #68
  %{
    permission_id: p58.id,
    role_id: r21.id
  }
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
 rp46, rp47, rp48, rp49, rp50,
 rp51, rp52, rp53, rp54, rp55,
 rp56, rp57, rp58, rp59, rp60,
 rp61, rp62, rp63, rp64, rp65,
 rp66, rp67, rp68
] =
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
  },
  #2
  %{
    name: "Caritas Health Shield",
    legal_name: "Caritas Health Shield",
    tax_number: 123_456,
    type: "Payor",
    status: "None",
    code: "HIJKLMNO"
  }
]
[pa1, pa2] = PayorSeeder.seed(payor_data)

#Seed Payor Card Bins
# IO.puts "Seeding payor_card_bins..."
# payor_card_bin_data = [
#   #1
#   %{
#     payor_id: pa1.id,
#     card_bin: "60508311",
#     sequence: "1"
#   }
# ]
# [pcb1] = Innerpeace.Db.PayorCardBinSeeder.seed(payor_card_bin_data)

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
  #10
  %{
    name: "Cancer",
    description: "Cancer",
    status: "A",
    type: "A",
    plan_type: "riders",
    code: "CNCR"
  },
   #11
  %{
    name: "RUV",
    description: "RUV",
    status: "A",
    type: "A",
    plan_type: "health_plan",
    code: "RUV"
  },
   #12
  %{
    name: "PEME",
    description: "PEME",
    status: "A",
    type: "A",
    plan_type: "riders",
    code: "PEME"
  }

]
[c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12] = CoverageSeeder.seed(coverage_data)

#Create Payor Procedure
IO.puts "Seeding payor procedures ..."
payor_procedure_data = [
  #1
  %{
    "description" => "17 HYDROXY PROGESTERONE",
    "code" => "LAB0503004",
    "payor_id" => pa1.id,
    "procedure_id" => pr1.id
  },
  #2
  %{
    "description" => "BCR/ABL (F.I.S.H.)",
    "code" => "LAB1220",
    "payor_id" => pa1.id,
    "procedure_id" => pr2.id
  },
  #3
  %{
    "description" => "24 HOUR URINE TOTAL CHON",
    "code" => "LAB6764",
    "payor_id" => pa1.id,
    "procedure_id" => pr3.id
  },
  #4
  %{
    "description" => "5HIAA (PLASMA)",
    "code" => "LAB0503016",
    "payor_id" => pa1.id,
    "procedure_id" => pr4.id
  },
  #5
  %{
    "description" => "(ACP) ACID PHOSPHATASE",
    "code" => "S2196",
    "payor_id" => pa1.id,
    "procedure_id" => pr5.id
  },
  #6
  %{
    "description" => "ACTH",
    "code" => "S2737",
    "payor_id" => pa1.id,
    "procedure_id" => pr6.id
  }
]

[pp1, pp2, pp3, pp4, pp5, pp6] = PayorProcedureSeeder.seed(payor_procedure_data)

#Create Benefits
IO.puts "Seeding benefits for health..."
benefit_health_data = [
  #1
  %{
    code: "B102",
    name: "Medilink Benefit",
    created_by_id: u1.id,
    updated_by_id: u1.id,
    category: "Health",
    step: 0,
    coverage_ids: [c1.id]
  }
]
[bh1] = BenefitSeeder.seed_health(benefit_health_data)

IO.puts "Seeding benefits for riders..."
benefit_riders_data = [
  #1
  %{
    code: "B101",
    name: "Accenture Benefit",
    created_by_id: u1.id,
    updated_by_id: u1.id,
    category: "Riders",
    step: 0,
    coverage_id: c10.id
  },
  #2
  %{
    code: "B103",
    name: "IBM Benefit",
    created_by_id: u1.id,
    updated_by_id: u1.id,
    category: "Riders",
    step: 0,
    coverage_id: c10.id
  }
]
[br1, br2] = BenefitSeeder.seed_riders(benefit_riders_data)

#Create Benefit Coverage
IO.puts "Seeding benefit coverage for health..."
benefit_coverage_data = [
  #1
  %{
    benefit_id: bh1.id,
    coverage_id: c1.id
  },
  #4
  %{
    benefit_id: br1.id,
    coverage_id: c6.id
  },
  #7
  %{
    benefit_id: br2.id,
    coverage_id: c6.id
  }
]

[bc_health1, bc_riders1, bc_riders2] = BenefitCoverageSeeder.seed(benefit_coverage_data)

#Create Benefit Procedure
IO.puts "Seeding benefit procedure..."
benefit_procedure_data = [
  #1
  %{
    benefit_id: bh1.id,
    procedure_id: pp1.id
  },
  #2
  %{
    benefit_id: bh1.id,
    procedure_id: pp2.id
  },
  #3
  %{
    benefit_id: bh1.id,
    procedure_id: pp3.id
  },
  #4
  %{
    benefit_id: br1.id,
    procedure_id: pp1.id
  },
  #5
  %{
    benefit_id: br1.id,
    procedure_id: pp2.id
  },
  #6
  %{
    benefit_id: br1.id,
    procedure_id: pp3.id
  },
  #4
  %{
    benefit_id: br2.id,
    procedure_id: pp1.id
  },
  #5
  %{
    benefit_id: br2.id,
    procedure_id: pp2.id
  },
  #6
  %{
    benefit_id: br2.id,
    procedure_id: pp3.id
  }
]

[bp_health1, bp_health2, bp_health3,
 bp_riders1, bp_riders2, bp_riders3,
 bp_riders4, bp_riders5, bp_riders6] =
   BenefitProcedureSeeder.seed(benefit_procedure_data)

#Create Benefit Diagnosis
IO.puts "Seeding benefit diagnosis..."
benefit_diagnosis_data = [
  #1
  %{
    benefit_id: bh1.id,
    diagnosis_id: di1.id
  },
  #2
  %{
    benefit_id: bh1.id,
    diagnosis_id: di2.id
  },
  #3
  %{
    benefit_id: bh1.id,
    diagnosis_id: di3.id
  },
  #4
  %{
    benefit_id: br1.id,
    diagnosis_id: di1.id
  },
  #5
  %{
    benefit_id: br1.id,
    diagnosis_id: di2.id
  },
  #6
  %{
    benefit_id: br1.id,
    diagnosis_id: di3.id
  },
  #7
  %{
    benefit_id: br2.id,
    diagnosis_id: di1.id
  },
  #8
  %{
    benefit_id: br2.id,
    diagnosis_id: di2.id
  },
  #9
  %{
    benefit_id: br2.id,
    diagnosis_id: di3.id
  }
]

[bd_health1, bd_health2, bd_health3,
 bd_riders1, bd_riders2, bd_riders3,
 bd_riders4, bd_riders5, bd_riders6] =
   BenefitDiagnosisSeeder.seed(benefit_diagnosis_data)

#Create Benefit Limit
IO.puts "Seeding benefit limits..."
benefit_limit_data = [
  #1
  %{
    benefit_id: bh1.id,
    limit_type: "Peso",
    limit_percentage: "",
    limit_amount: Decimal.new(2500.50),
    limit_session: "",
    coverages: "OPC",
    limit_classification: "Per Coverage Period"
  },
  #2
  %{
    benefit_id: br1.id,
    limit_type: "Peso",
    limit_percentage: "",
    limit_amount: Decimal.new(2500.50),
    limit_session: "",
    coverages: "MTRNTY",
    limit_classification: "Per Coverage Period"
  },
  #3
  %{
    benefit_id: br2.id,
    limit_type: "Peso",
    limit_percentage: "",
    limit_amount: Decimal.new(2500.50),
    limit_session: "",
    coverages: "MTRNTY",
    limit_classification: "Per Coverage Period"
  }
]

[bl_health1, bl_riders1, bl_riders2] = BenefitLimitSeeder.seed(benefit_limit_data)

#Create Specialization
IO.puts "Seeding specialization..."
specialization_data = [
  #1
  %{
    name: "Dermatology"
  },
  #2
  %{
    name: "General Surgery"
  },
  #3
  %{
    name: "Otolaryngology-Head and Neck Surgery"
  },
  #4
  %{
    name: "Cardiothoracic Surgery"
  },
  #5
  %{
    name: "Vascular Surgery"
  },
  #6
  %{
    name: "Radiology"
  },
  #7
  %{
    name: "Pathology"
  },
  #8
  %{
    name: "Neurosurgery"
  },
  #9
  %{
    name: "Sonology"
  },
  #10
  %{
    name: "Pediatrics"
  },
  #11
  %{
    name: "Resident Physician"
  },
  #12
  %{
    name: "Internal Medicine"
  },
  #13
  %{
    name: "General Medicine"
  },
  #14
  %{
    name: "Family Medicine"
  },
  #15
  %{
    name: "Opthalmology"
  },
  #16
  %{
    name: "Optometry"
  },
  #17
  %{
    name: "Pulmonology"
  },
  #18
  %{
    name: "Obstetrics and Gynecology"
  },
  #19
  %{
    name: "Occupational Medicine"
  },
  #20
  %{
    name: "Psychiatry"
  },
  #21
  %{
    name: "Neurology"
  },
  #22
  %{
    name: "Orthopedic Surgery"
  },
  #23
  %{
    name: "Anesthesiology"
  },
  #24
  %{
    name: "Oncology"
  }
]

[s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12, s13, s14,
s15, s16, s17, s18, s19, s20, s21, s22, s23, s24] = SpecializationSeeder.seed(specialization_data)

IO.puts "Seeding rooms..."
room_data = [
  #1
  %{
    code: "REGROOM101",
    type: "Regular Room",
    hierarchy: 1,
    ruv_rate: "1000"
  },
  #2
  %{
    code: "PRIVROOM101",
    type: "Private Room",
    hierarchy: 1,
    ruv_rate: "1000"
  },
  #3
  %{
    code: "16",
    type: "OP",
    hierarchy: 1,
    ruv_rate: "1000"
  },
  #4
  %{
    code: "31",
    type: "ER",
    hierarchy: 0,
    ruv_rate: "1000"
  }
]

[r1, r2, r3, r4] = RoomSeeder.seed(room_data)

###################################################################### Start of Product SEEDS

#Create Products
#to be follow product principal_min_age to room_upgrade_time (data 1 to 5)
IO.puts "Seeding products..."
product_data = [
  #1
  %{
    "code" => Product.random_pcode(),
    "name" => "Maxicare Product 1",
    "description" => "Health card for regular employee",
    "limit_applicability" => "Individual",
    "type" => "Platinum",
    "limit_type" => "MBL",
    "limit_amount" => Decimal.new(100_000),
    "phic_status" => "Required to File",
    "standard_product" => "Yes",
    "member_type" => ["Principal"],
    "product_category" => "Regular Product",
    "payor_id" => pa1.id,
    "principal_min_age" => 18,
    "principal_min_type" => "Years",
    "principal_max_age" => 64,
    "principal_max_type" => "Years",
    "adult_dependent_min_age" => 18,
    "adult_dependent_min_type" => "Years",
    "adult_dependent_max_age" => 65,
    "adult_dependent_max_type" => "Years",
    "minor_dependent_min_age" => 15,
    "minor_dependent_min_type" => "Days",
    "minor_dependent_max_age" => 20,
    "minor_dependent_max_type" => "Days",
    "overage_dependent_min_age" => 66,
    "overage_dependent_min_type" => "Years",
    "overage_dependent_max_age" => 70,
    "overage_dependent_max_type" => "Years",
    "adnb" => 1000.00,
    "adnnb" => 1000.00,
    "opmnb" => 2500.00,
    "opmnnb" => 5000.00,
    "room_and_board" => "Alternative",
    "room_type" => "Suite",
    "room_limit_amount" => 100_000.00,
    "room_upgrade" => 12,
    "room_upgrade_time" => "Hours",
    "nem_principal" => 5,
    "nem_dependent" => 10,
    "no_days_valid" => 100,
    "is_medina" => true,
    "smp_limit" => 100_000.00,
    "hierarchy_waiver" => "Enforce",
    "product_base" => "Benefit-based",
    "step" => "8",
    "created_by_id" => u1.id,
    "updated_by_id" => u1.id,
    "loa_facilitated" => true
  },
  #2
  %{
    "code" => Product.random_pcode(),
    "name" => "Maxicare Product 2",
    "description" => "Health card for Manager",
    "limit_applicability" => "Share with Family",
    "type" => "Platinum",
    "limit_type" => "ABL",
    "limit_amount" => Decimal.new(10_000),
    "phic_status" => "Optional to File",
    "standard_product" => "No",
    "product_category" => "Regular Product",
    "member_type" => ["Principal", "Dependent"],
    "payor_id" => pa1.id,
    "principal_min_age" => 16,
    "principal_min_type" => "Years",
    "principal_max_age" => 55,
    "principal_max_type" => "Years",
    "adult_dependent_min_age" => 16,
    "adult_dependent_min_type" => "Years",
    "adult_dependent_max_age" => 55,
    "adult_dependent_max_type" => "Years",
    "minor_dependent_min_age" => 16,
    "minor_dependent_min_type" => "Days",
    "minor_dependent_max_age" => 55,
    "minor_dependent_max_type" => "Days",
    "overage_dependent_min_age" => 55,
    "overage_dependent_min_type" => "Years",
    "overage_dependent_max_age" => 75,
    "overage_dependent_max_type" => "Years",
    "adnb" => 2000.00,
    "adnnb" => 2000.00,
    "opmnb" => 3500.00,
    "opmnnb" => 6000.00,
    "room_and_board" => "Alternative",
    "room_type" => "Suite",
    "room_limit_amount" => 100_000.00,
    "room_upgrade" => 12,
    "room_upgrade_time" => "Hours",
    "nem_principal" => 5,
    "nem_dependent" => 10,
    "no_days_valid" => 100,
    "is_medina" => true,
    "smp_limit" => 100_000.00,
    "hierarchy_waiver" => "Enforce",
    "product_base" => "Benefit-based",
    "step" => "8",
    "created_by_id" => u1.id,
    "updated_by_id" => u1.id,
    "loa_facilitated" => true
  },
  #3
  %{
    "code" => Product.random_pcode(),
    "name" => "Maxicare Product 3",
    "description" => "Health card for Executive",
    "limit_applicability" => "Individual",
    "type" => "Platinum",
    "limit_type" => "MBL",
    "limit_amount" => Decimal.new(100_000),
    "phic_status" => "Required to File",
    "standard_product" => "Yes",
    "product_category" => "Regular Product",
    "member_type" => ["Dependent"],
    "payor_id" => pa1.id,
    "principal_min_age" => 18,
    "principal_min_type" => "Years",
    "principal_max_age" => 64,
    "principal_max_type" => "Years",
    "adult_dependent_min_age" => 18,
    "adult_dependent_min_type" => "Years",
    "adult_dependent_max_age" => 65,
    "adult_dependent_max_type" => "Years",
    "minor_dependent_min_age" => 15,
    "minor_dependent_min_type" => "Days",
    "minor_dependent_max_age" => 20,
    "minor_dependent_max_type" => "Days",
    "overage_dependent_min_age" => 66,
    "overage_dependent_min_type" => "Years",
    "overage_dependent_max_age" => 70,
    "overage_dependent_max_type" => "Years",
    "adnb" => 1000.00,
    "adnnb" => 1000.00,
    "opmnb" => 2500.00,
    "opmnnb" => 5000.00,
    "room_and_board" => "Alternative",
    "room_type" => "Suite",
    "room_limit_amount" => 100_000.00,
    "room_upgrade" => 12,
    "room_upgrade_time" => "Hours",
    "nem_dependent" => 10,
    "no_days_valid" => 100,
    "is_medina" => false,
    "hierarchy_waiver" => "Enforce",
    "product_base" => "Benefit-based",
    "step" => "8",
    "created_by_id" => u1.id,
    "updated_by_id" => u1.id,
    "loa_facilitated" => true
  },
  #4
  %{
    "code" => Product.random_pcode(),
    "name" => "Maxicare Product 4",
    "description" => "Health card for Consultant",
    "limit_applicability" => "Share with Family",
    "type" => "Platinum",
    "limit_type" => "ABL",
    "limit_amount" => Decimal.new(100_000),
    "phic_status" => "Optional to File",
    "standard_product" => "No",
    "product_category" => "Regular Product",
    "member_type" => ["Principal"],
    "payor_id" => pa1.id,
    "principal_min_age" => 16,
    "principal_min_type" => "Years",
    "principal_max_age" => 55,
    "principal_max_type" => "Years",
    "adult_dependent_min_age" => 16,
    "adult_dependent_min_type" => "Years",
    "adult_dependent_max_age" => 55,
    "adult_dependent_max_type" => "Years",
    "minor_dependent_min_age" => 16,
    "minor_dependent_min_type" => "Days",
    "minor_dependent_max_age" => 55,
    "minor_dependent_max_type" => "Days",
    "overage_dependent_min_age" => 55,
    "overage_dependent_min_type" => "Years",
    "overage_dependent_max_age" => 75,
    "overage_dependent_max_type" => "Years",
    "adnb" => 2000.00,
    "adnnb" => 2000.00,
    "opmnb" => 3500.00,
    "opmnnb" => 6000.00,
    "room_and_board" => "Alternative",
    "room_type" => "Suite",
    "room_limit_amount" => 100_000.00,
    "room_upgrade" => 12,
    "room_upgrade_time" => "Hours",
    "nem_principal" => 5,
    "nem_dependent" => 10,
    "no_days_valid" => 100,
    "is_medina" => true,
    "smp_limit" => 100_000.00,
    "hierarchy_waiver" => "Enforce",
    "product_base" => "Benefit-based",
    "step" => "8",
    "created_by_id" => u1.id,
    "updated_by_id" => u1.id,
    "loa_facilitated" => true
  },
  #5
  %{
    "code" => Product.random_pcode(),
    "name" => "Maxicare Product 5",
    "description" => "Health card for Supervisor",
    "limit_applicability" => "Individual",
    "type" => "Platinum",
    "limit_type" => "MBL",
    "limit_amount" => Decimal.new(100_000),
    "phic_status" => "Required to File",
    "standard_product" => "Yes",
    "product_category" => "Regular Product",
    "member_type" => ["Principal", "Dependent"],
    "payor_id" => pa1.id,
    "principal_min_age" => 18,
    "principal_min_type" => "Years",
    "principal_max_age" => 64,
    "principal_max_type" => "Years",
    "adult_dependent_min_age" => 18,
    "adult_dependent_min_type" => "Years",
    "adult_dependent_max_age" => 65,
    "adult_dependent_max_type" => "Years",
    "minor_dependent_min_age" => 15,
    "minor_dependent_min_type" => "Days",
    "minor_dependent_max_age" => 20,
    "minor_dependent_max_type" => "Days",
    "overage_dependent_min_age" => 66,
    "overage_dependent_min_type" => "Years",
    "overage_dependent_max_age" => 70,
    "overage_dependent_max_type" => "Years",
    "adnb" => 1000.00,
    "adnnb" => 1000.00,
    "opmnb" => 2500.00,
    "opmnnb" => 5000.00,
    "room_and_board" => "Alternative",
    "room_type" => "Suite",
    "room_limit_amount" => 100_000.00,
    "room_upgrade" => 12,
    "room_upgrade_time" => "Hours",
    "nem_principal" => 5,
    "nem_dependent" => 10,
    "no_days_valid" => 100,
    "is_medina" => false,
    "hierarchy_waiver" => "Enforce",
    "product_base" => "Benefit-based",
    "step" => "8",
    "created_by_id" => u1.id,
    "updated_by_id" => u1.id,
    "loa_facilitated" => true
  }
]
[pro1, pro2, pro3, pro4, pro5] = ProductSeeder.seed(product_data)

#Create Product Benefit
IO.puts "Seeding product benefit..."

product_benefit_data = [

  #1
  %{
    product_id: pro1.id,
    benefit_id: bh1.id
  },
  #2
  %{
    product_id: pro2.id,
    benefit_id: bh1.id
  },
  #3
  %{
    product_id: pro3.id,
    benefit_id: bh1.id
  },
  #4
  %{
    product_id: pro4.id,
    benefit_id: bh1.id
  },
  #5
  %{
    product_id: pro5.id,
    benefit_id: bh1.id
  },
  #6
  %{
    product_id: pro1.id,
    benefit_id: br1.id
  },
  #7
  %{
    product_id: pro2.id,
    benefit_id: br1.id
  },
  #8
  %{
    product_id: pro3.id,
    benefit_id: br1.id
  },

  #9
  %{
    product_id: pro4.id,
    benefit_id: br1.id
  },
  #10
  %{
    product_id: pro5.id,
    benefit_id: br1.id
  },
  #11
  %{
    product_id: pro1.id,
    benefit_id: br2.id
  },
  #12
  %{
    product_id: pro2.id,
    benefit_id: br2.id
  },
  #13
  %{
    product_id: pro3.id,
    benefit_id: br2.id
  },
  #14
  %{
    product_id: pro4.id,
    benefit_id: br2.id
  },
  #15
  %{
    product_id: pro5.id,
    benefit_id: br2.id
  }
]

[pb1, pb2, pb3, pb4, pb5,
 pb6, pb7, pb8, pb9, pb10,
 pb11, pb12, pb13, pb14, pb15] =
   ProductBenefitSeeder.seed(product_benefit_data)

#Create Product Benefit Limit
IO.puts "Seeding product benefit limit..."
product_benefit_limit_data = [
  #1
  # owned by pro1
  %{
    product_benefit_id: pb1.id,
    benefit_limit_id: bl_health1.id,
    coverages: bl_health1.coverages,
    limit_type: bl_health1.limit_type,
    limit_percentage: nil,
    limit_amount: bl_health1.limit_amount,
    limit_session: nil,
    limit_classification: bl_health1.limit_classification
  },
  #2
  # owned by pro1
  %{
    product_benefit_id: pb6.id,
    benefit_limit_id: bl_riders1.id,
    coverages: bl_riders1.coverages,
    limit_type: bl_riders1.limit_type,
    limit_percentage: nil,
    limit_amount: bl_riders1.limit_amount,
    limit_session: nil,
    limit_classification: bl_riders1.limit_classification
  },
  #3
  # owned by pro1
  %{
    product_benefit_id: pb11.id,
    benefit_limit_id: bl_riders2.id,
    coverages: bl_riders2.coverages,
    limit_type: bl_riders2.limit_type,
    limit_percentage: nil,
    limit_amount: bl_riders2.limit_amount,
    limit_session: nil,
    limit_classification: bl_riders2.limit_classification
  },

  #4
  # owned by pro2
  %{
    product_benefit_id: pb2.id,
    benefit_limit_id: bl_health1.id,
    coverages: bl_health1.coverages,
    limit_type: bl_health1.limit_type,
    limit_percentage: nil,
    limit_amount: bl_health1.limit_amount,
    limit_session: nil,
    limit_classification: bl_health1.limit_classification
  },
  #5
  # owned by pro2
  %{
    product_benefit_id: pb7.id,
    benefit_limit_id: bl_riders1.id,
    coverages: bl_riders1.coverages,
    limit_type: bl_riders1.limit_type,
    limit_percentage: nil,
    limit_amount: bl_riders1.limit_amount,
    limit_session: nil,
    limit_classification: bl_riders1.limit_classification
  },
  #6
  # owned by pro2
  %{
    product_benefit_id: pb12.id,
    benefit_limit_id: bl_riders2.id,
    coverages: bl_riders2.coverages,
    limit_type: bl_riders2.limit_type,
    limit_percentage: nil,
    limit_amount: bl_riders2.limit_amount,
    limit_session: nil,
    limit_classification: bl_riders2.limit_classification
  },
  #7
  # owned by pro3
  %{
    product_benefit_id: pb3.id,
    benefit_limit_id: bl_health1.id,
    coverages: bl_health1.coverages,
    limit_type: bl_health1.limit_type,
    limit_percentage: nil,
    limit_amount: bl_health1.limit_amount,
    limit_session: nil,
    limit_classification: bl_health1.limit_classification
  },
  #8
  # owned by pro3
  %{
    product_benefit_id: pb8.id,
    benefit_limit_id: bl_riders1.id,
    coverages: bl_riders1.coverages,
    limit_type: bl_riders1.limit_type,
    limit_percentage: nil,
    limit_amount: bl_riders1.limit_amount,
    limit_session: nil,
    limit_classification: bl_riders1.limit_classification
  },
  #9
  # owned by pro3
  %{
    product_benefit_id: pb13.id,
    benefit_limit_id: bl_riders2.id,
    coverages: bl_riders2.coverages,
    limit_type: bl_riders2.limit_type,
    limit_percentage: nil,
    limit_amount: bl_riders2.limit_amount,
    limit_session: nil,
    limit_classification: bl_riders2.limit_classification
  },
  #10
  # owned by pro4
  %{
    product_benefit_id: pb4.id,
    benefit_limit_id: bl_health1.id,
    coverages: bl_health1.coverages,
    limit_type: bl_health1.limit_type,
    limit_percentage: nil,
    limit_amount: bl_health1.limit_amount,
    limit_session: nil,
    limit_classification: bl_health1.limit_classification
  },
  #11
  # owned by pro4
  %{
    product_benefit_id: pb9.id,
    benefit_limit_id: bl_riders1.id,
    coverages: bl_riders1.coverages,
    limit_type: bl_riders1.limit_type,
    limit_percentage: nil,
    limit_amount: bl_riders1.limit_amount,
    limit_session: nil,
    limit_classification: bl_riders1.limit_classification
  },
  #12
  # owned by pro4
  %{
    product_benefit_id: pb14.id,
    benefit_limit_id: bl_riders2.id,
    coverages: bl_riders2.coverages,
    limit_type: bl_riders2.limit_type,
    limit_percentage: nil,
    limit_amount: bl_riders2.limit_amount,
    limit_session: nil,
    limit_classification: bl_riders2.limit_classification
  },
  #13
  # owned by pro5
  %{
    product_benefit_id: pb5.id,
    benefit_limit_id: bl_health1.id,
    coverages: bl_health1.coverages,
    limit_type: bl_health1.limit_type,
    limit_percentage: nil,
    limit_amount: bl_health1.limit_amount,
    limit_session: nil,
    limit_classification: bl_health1.limit_classification
  },
  #14
  # owned by pro5
  %{
    product_benefit_id: pb10.id,
    benefit_limit_id: bl_riders1.id,
    coverages: bl_riders1.coverages,
    limit_type: bl_riders1.limit_type,
    limit_percentage: nil,
    limit_amount: bl_riders1.limit_amount,
    limit_session: nil,
    limit_classification: bl_riders1.limit_classification
  },
  #15
  # owned by pro5
  %{
    product_benefit_id: pb15.id,
    benefit_limit_id: bl_riders2.id,
    coverages: bl_riders2.coverages,
    limit_type: bl_riders2.limit_type,
    limit_percentage: nil,
    limit_amount: bl_riders2.limit_amount,
    limit_session: nil,
    limit_classification: bl_riders2.limit_classification
  }
]

[pbl1, pbl2, pbl3, pbl4, pbl5,
 pbl6, pbl7, pbl8, pbl9, pbl10,
 pbl11, pbl12, pbl13, pbl14, pbl15] =
   ProductBenefitLimitSeeder.seed(product_benefit_limit_data)

#Create Product Coverage
IO.puts "Seeding product coverage..."
product_coverage_data = [
  #1
  %{
    product_id: pro1.id,
    coverage_id: c1.id,
    type: "inclusion",
    funding_arrangement: "Full Risk"
  },
  #2
  %{
    product_id: pro1.id,
    coverage_id: c6.id,
    type: "inclusion",
    funding_arrangement: "Full Risk"
  },
  #3
  %{
    product_id: pro2.id,
    coverage_id: c1.id,
    type: "exception",
    funding_arrangement: "Full Risk"
  },
  #4
  %{
    product_id: pro2.id,
    coverage_id: c6.id,
    type: "exception",
    funding_arrangement: "Full Risk"
  },
  #5
  %{
    product_id: pro3.id,
    coverage_id: c1.id,
    type: "exception",
    funding_arrangement: "Full Risk"
  },
  #6
  %{
    product_id: pro3.id,
    coverage_id: c6.id,
    type: "exception",
    funding_arrangement: "ASO"
  },
  #7
  %{
    product_id: pro4.id,
    coverage_id: c1.id,
    type: "exception",
    funding_arrangement: "ASO"
  },
  #8
  %{
    product_id: pro4.id,
    coverage_id: c6.id,
    type: "exception",
    funding_arrangement: "ASO"
  },
  #9
  %{
    product_id: pro5.id,
    coverage_id: c1.id,
    type: "exception",
    funding_arrangement: "ASO"
  },
  #10
  %{
    product_id: pro5.id,
    coverage_id: c6.id,
    type: "exception",
    funding_arrangement: "ASO"
  },
]

[pc1, pc2, pc3, pc4, pc5, pc6, pc7, pc8, pc9, pc10] = ProductCoverageSeeder.seed(product_coverage_data)

############################################################# start of product coverage facility

#Create Product Coverage Facility
IO.puts "Seeding product coverage facility..."
product_coverage_facility_data = [
  #1
  %{
    product_coverage_id: pc1.id,
    facility_id: f1.id
  },

  #2
  %{
    product_coverage_id: pc1.id,
    facility_id: f3.id
  },

  #3
  %{
    product_coverage_id: pc2.id,
    facility_id: f2.id
  },
  #4
  %{
    product_coverage_id: pc2.id,
    facility_id: f3.id
  },
  #4
  %{
    product_coverage_id: pc3.id,
    facility_id: f3.id
  },
  #5
  %{
    product_coverage_id: pc4.id,
    facility_id: f4.id
  }
]

[pcf1, pcf2, pcf3, pcf4, pcf5, pcf6] = ProductCoverageFacilitySeeder.seed(product_coverage_facility_data)

############################################################# end of product coverage facility

############################################################# for condition tab

#Create Product Coverage Room and Board
IO.puts "Seeding product coverage room and board..."
product_coverage_room_and_board_data = [
  #1
  %{
    product_coverage_id: pc2.id,
    room_and_board: "Alternative",
    room_type: r1.id,
    room_limit_amount: Decimal.new(1500.50),
    room_upgrade: 4,
    room_upgrade_time: "Hours"
  },
  #2
  %{
    product_coverage_id: pc4.id,
    room_and_board: "Alternative",
    room_type: r1.id,
    room_limit_amount: Decimal.new(1600.50),
    room_upgrade: 4,
    room_upgrade_time: "Hours"
  },
  #3
  %{
    product_coverage_id: pc6.id,
    room_and_board: "Alternative",
    room_type: r1.id,
    room_limit_amount: Decimal.new(1700.50),
    room_upgrade: 4,
    room_upgrade_time: "Hours"
  },
  #4
  %{
    product_coverage_id: pc8.id,
    room_and_board: "Alternative",
    room_type: r1.id,
    room_limit_amount: Decimal.new(1800.50),
    room_upgrade: 4,
    room_upgrade_time: "Hours"
  },
  #5
  %{
    product_coverage_id: pc10.id,
    room_and_board: "Alternative",
    room_type: r1.id,
    room_limit_amount: Decimal.new(1900.50),
    room_upgrade: 4,
    room_upgrade_time: "Hours"
  }
]

[pcrnb1, pcrnb2, pcrnb3, pcrnb4, pcrnb5] = ProductCoverageRoomAndBoardSeeder.seed(product_coverage_room_and_board_data)

#Create Product Coverage Limit Threshold
# SKIP for LIMIT THRESHOLD
IO.puts "Seeding product coverage limit threshold..."
product_coverage_limit_threshold_data = [
  #1
  %{
    product_coverage_id: pc1.id,
  },
  #2
  %{
    product_coverage_id: pc2.id
  },
  #3
  %{
    product_coverage_id: pc3.id
  },
  #4
  %{
    product_coverage_id: pc4.id
  },
  #5
  %{
    product_coverage_id: pc5.id
  },
  #6
  %{
    product_coverage_id: pc6.id
  },
  #7
  %{
    product_coverage_id: pc7.id
  },
  #8
  %{
    product_coverage_id: pc8.id
  },
  #9
  %{
    product_coverage_id: pc9.id
  },
  #10
  %{
    product_coverage_id: pc10.id
  }
]

[pclt1, pclt2, pclt3, pclt4, pclt5,
 pclt6, pclt7, pclt8, pclt9, pclt10] =
   ProductCoverageLimitThresholdSeeder.seed(product_coverage_limit_threshold_data)

############################################################# for risk share tab

#Create Product Coverage Risk Share
IO.puts "Seeding product coverage risk share..."
product_coverage_risk_share_data = [
  #1
  %{
    product_coverage_id: pc1.id
  },
  #2
  %{
    product_coverage_id: pc2.id
  },
  #3
  %{
    product_coverage_id: pc3.id
  },
  #4
  %{
    product_coverage_id: pc4.id
  },
  #5
  %{
    product_coverage_id: pc5.id
  },
  #6
  %{
    product_coverage_id: pc6.id
  },
  #7
  %{
    product_coverage_id: pc7.id
  },
  #8
  %{
    product_coverage_id: pc8.id
  },
  #9
  %{
    product_coverage_id: pc9.id
  },
  #10
  %{
    product_coverage_id: pc10.id
  }
]

[pcrs1, pcrs2, pcrs3, pcrs4, pcrs5,
 pcrs6, pcrs7, pcrs8, pcrs9, pcrs10] =
   ProductCoverageRiskShareSeeder.seed(product_coverage_risk_share_data)

##### to be follow product seed for
#[
#  "product_coverage_limit_thresholds",
#  "product_coverage_limit_threshold_facilities"
#  "product_coverage_risk_share_facilities",
#  "product_coverage_riskshare_facility_payor_procedures",
#  "product_exclusions",
#]
###################################################################### End of Product SEEDS

IO.puts "Seeding diagnosis coverage..."
diagnosis_coverage_data = [
  #1
  %{
    diagnosis_id: di1.id,
    coverage_id: c1.id
  },
  #2
  %{
    diagnosis_id: di1.id,
    coverage_id: c2.id
  },
  #3
  %{
    diagnosis_id: di1.id,
    coverage_id: c3.id
  },
  #4
  %{
    diagnosis_id: di1.id,
    coverage_id: c4.id
  },
  #5
  %{
    diagnosis_id: di1.id,
    coverage_id: c5.id
  },
  #6
  %{
    diagnosis_id: di1.id,
    coverage_id: c6.id
  },
  #7
  %{
    diagnosis_id: di1.id,
    coverage_id: c7.id
  },
  #8
  %{
    diagnosis_id: di1.id,
    coverage_id: c8.id
  },
  #9
  %{
    diagnosis_id: di1.id,
    coverage_id: c9.id
  },
  #10
  %{
    diagnosis_id: di1.id,
    coverage_id: c10.id
  },
  #11
  %{
    diagnosis_id: di2.id,
    coverage_id: c1.id
  },
  #12
  %{
    diagnosis_id: di2.id,
    coverage_id: c2.id
  },
  #13
  %{
    diagnosis_id: di2.id,
    coverage_id: c3.id
  },
  #14
  %{
    diagnosis_id: di2.id,
    coverage_id: c4.id
  },
  #15
  %{
    diagnosis_id: di2.id,
    coverage_id: c5.id
  },
  #16
  %{
    diagnosis_id: di2.id,
    coverage_id: c6.id
  },
  #17
  %{
    diagnosis_id: di2.id,
    coverage_id: c7.id
  },
  #18
  %{
    diagnosis_id: di2.id,
    coverage_id: c8.id
  },
  #19
  %{
    diagnosis_id: di2.id,
    coverage_id: c9.id
  },
  #20
  %{
    diagnosis_id: di2.id,
    coverage_id: c10.id
  },
  #21
  %{
    diagnosis_id: di3.id,
    coverage_id: c1.id
  },
  #22
  %{
    diagnosis_id: di3.id,
    coverage_id: c2.id
  },
  #23
  %{
    diagnosis_id: di3.id,
    coverage_id: c3.id
  },
  #24
  %{
    diagnosis_id: di3.id,
    coverage_id: c4.id
  },
  #25
  %{
    diagnosis_id: di3.id,
    coverage_id: c5.id
  },
  #26
  %{
    diagnosis_id: di3.id,
    coverage_id: c6.id
  },
  #27
  %{
    diagnosis_id: di3.id,
    coverage_id: c7.id
  },
  #28
  %{
    diagnosis_id: di3.id,
    coverage_id: c8.id
  },
  #29
  %{
    diagnosis_id: di3.id,
    coverage_id: c9.id
  },
  #30
  %{
    diagnosis_id: di3.id,
    coverage_id: c10.id
  },
  #31
  %{
    diagnosis_id: di4.id,
    coverage_id: c1.id
  },
  #32
  %{
    diagnosis_id: di4.id,
    coverage_id: c2.id
  },
  #33
  %{
    diagnosis_id: di4.id,
    coverage_id: c3.id
  },
  #34
  %{
    diagnosis_id: di4.id,
    coverage_id: c4.id
  },
  #35
  %{
    diagnosis_id: di4.id,
    coverage_id: c5.id
  },
  #36
  %{
    diagnosis_id: di4.id,
    coverage_id: c6.id
  },
  #37
  %{
    diagnosis_id: di4.id,
    coverage_id: c7.id
  },
  #38
  %{
    diagnosis_id: di4.id,
    coverage_id: c8.id
  },
  #39
  %{
    diagnosis_id: di4.id,
    coverage_id: c9.id
  },
  #40
  %{
    diagnosis_id: di4.id,
    coverage_id: c10.id
  },
  #41
  %{
    diagnosis_id: di5.id,
    coverage_id: c1.id
  },
  #42
  %{
    diagnosis_id: di5.id,
    coverage_id: c2.id
  },
  #43
  %{
    diagnosis_id: di5.id,
    coverage_id: c3.id
  },
  #44
  %{
    diagnosis_id: di5.id,
    coverage_id: c4.id
  },
  #45
  %{
    diagnosis_id: di5.id,
    coverage_id: c5.id
  },
  #46
  %{
    diagnosis_id: di5.id,
    coverage_id: c6.id
  },
  #47
  %{
    diagnosis_id: di5.id,
    coverage_id: c7.id
  },
  #48
  %{
    diagnosis_id: di5.id,
    coverage_id: c8.id
  },
  #49
  %{
    diagnosis_id: di5.id,
    coverage_id: c9.id
  },
  #50
  %{
    diagnosis_id: di5.id,
    coverage_id: c10.id
  },
  #51
  %{
    diagnosis_id: di6.id,
    coverage_id: c1.id
  },
  #52
  %{
    diagnosis_id: di6.id,
    coverage_id: c2.id
  },
  #53
  %{
    diagnosis_id: di6.id,
    coverage_id: c3.id
  },
  #54
  %{
    diagnosis_id: di6.id,
    coverage_id: c4.id
  },
  #55
  %{
    diagnosis_id: di6.id,
    coverage_id: c5.id
  },
  #56
  %{
    diagnosis_id: di6.id,
    coverage_id: c6.id
  },
  #57
  %{
    diagnosis_id: di6.id,
    coverage_id: c7.id
  },
  #58
  %{
    diagnosis_id: di6.id,
    coverage_id: c8.id
  },
  #59
  %{
    diagnosis_id: di6.id,
    coverage_id: c9.id
  },
  #60
  %{
    diagnosis_id: di6.id,
    coverage_id: c10.id
  },
  #61
  %{
    diagnosis_id: di7.id,
    coverage_id: c1.id
  },
  #62
  %{
    diagnosis_id: di7.id,
    coverage_id: c2.id
  },
  #63
  %{
    diagnosis_id: di7.id,
    coverage_id: c3.id
  },
  #64
  %{
    diagnosis_id: di7.id,
    coverage_id: c4.id
  },
  #65
  %{
    diagnosis_id: di7.id,
    coverage_id: c5.id
  },
  #66
  %{
    diagnosis_id: di7.id,
    coverage_id: c6.id
  },
  #67
  %{
    diagnosis_id: di7.id,
    coverage_id: c7.id
  },
  #68
  %{
    diagnosis_id: di7.id,
    coverage_id: c8.id
  },
  #69
  %{
    diagnosis_id: di7.id,
    coverage_id: c9.id
  },
  #70
  %{
    diagnosis_id: di7.id,
    coverage_id: c10.id
  },
  #71
  %{
    diagnosis_id: di8.id,
    coverage_id: c1.id
  },
  #72
  %{
    diagnosis_id: di8.id,
    coverage_id: c2.id
  },
  #73
  %{
    diagnosis_id: di8.id,
    coverage_id: c3.id
  },
  #74
  %{
    diagnosis_id: di8.id,
    coverage_id: c4.id
  },
  #75
  %{
    diagnosis_id: di8.id,
    coverage_id: c5.id
  },
  #76
  %{
    diagnosis_id: di8.id,
    coverage_id: c6.id
  },
  #77
  %{
    diagnosis_id: di8.id,
    coverage_id: c7.id
  },
  #78
  %{
    diagnosis_id: di8.id,
    coverage_id: c8.id
  },
  #79
  %{
    diagnosis_id: di8.id,
    coverage_id: c9.id
  },
  #80
  %{
    diagnosis_id: di8.id,
    coverage_id: c10.id
  },
  #81
  %{
    diagnosis_id: di9.id,
    coverage_id: c1.id
  },
  #82
  %{
    diagnosis_id: di9.id,
    coverage_id: c2.id
  },
  #83
  %{
    diagnosis_id: di9.id,
    coverage_id: c3.id
  },
  #84
  %{
    diagnosis_id: di9.id,
    coverage_id: c4.id
  },
  #85
  %{
    diagnosis_id: di9.id,
    coverage_id: c5.id
  },
  #86
  %{
    diagnosis_id: di9.id,
    coverage_id: c6.id
  },
  #87
  %{
    diagnosis_id: di9.id,
    coverage_id: c7.id
  },
  #88
  %{
    diagnosis_id: di9.id,
    coverage_id: c8.id
  },
  #89
  %{
    diagnosis_id: di9.id,
    coverage_id: c9.id
  },
  #90
  %{
    diagnosis_id: di9.id,
    coverage_id: c10.id
  },
  #91
  %{
    diagnosis_id: di10.id,
    coverage_id: c1.id
  },
  #92
  %{
    diagnosis_id: di10.id,
    coverage_id: c2.id
  },
  #93
  %{
    diagnosis_id: di10.id,
    coverage_id: c3.id
  },
  #94
  %{
    diagnosis_id: di10.id,
    coverage_id: c4.id
  },
  #95
  %{
    diagnosis_id: di10.id,
    coverage_id: c5.id
  },
  #96
  %{
    diagnosis_id: di10.id,
    coverage_id: c6.id
  },
  #97
  %{
    diagnosis_id: di10.id,
    coverage_id: c7.id
  },
  #98
  %{
    diagnosis_id: di10.id,
    coverage_id: c8.id
  },
  #99
  %{
    diagnosis_id: di10.id,
    coverage_id: c9.id
  },
  #100
  %{
    diagnosis_id: di10.id,
    coverage_id: c10.id
  },
  #101
  %{
    diagnosis_id: di11.id,
    coverage_id: c1.id
  },
  #102
  %{
    diagnosis_id: di11.id,
    coverage_id: c2.id
  },
  #103
  %{
    diagnosis_id: di11.id,
    coverage_id: c3.id
  },
  #104
  %{
    diagnosis_id: di11.id,
    coverage_id: c4.id
  },
  #105
  %{
    diagnosis_id: di11.id,
    coverage_id: c5.id
  },
  #106
  %{
    diagnosis_id: di11.id,
    coverage_id: c6.id
  },
  #107
  %{
    diagnosis_id: di11.id,
    coverage_id: c7.id
  },
  #108
  %{
    diagnosis_id: di11.id,
    coverage_id: c8.id
  },
  #109
  %{
    diagnosis_id: di11.id,
    coverage_id: c9.id
  },
  #110
  %{
    diagnosis_id: di11.id,
    coverage_id: c10.id
  },
  #111
  %{
    diagnosis_id: di12.id,
    coverage_id: c1.id
  },
  #112
  %{
    diagnosis_id: di12.id,
    coverage_id: c2.id
  },
  #113
  %{
    diagnosis_id: di12.id,
    coverage_id: c3.id
  },
  #114
  %{
    diagnosis_id: di12.id,
    coverage_id: c4.id
  },
  #115
  %{
    diagnosis_id: di12.id,
    coverage_id: c5.id
  },
  #116
  %{
    diagnosis_id: di12.id,
    coverage_id: c6.id
  },
  #117
  %{
    diagnosis_id: di12.id,
    coverage_id: c7.id
  },
  #118
  %{
    diagnosis_id: di12.id,
    coverage_id: c8.id
  },
  #119
  %{
    diagnosis_id: di12.id,
    coverage_id: c9.id
  },
  #120
  %{
    diagnosis_id: di12.id,
    coverage_id: c10.id
  },
  #121
  %{
    diagnosis_id: di13.id,
    coverage_id: c1.id
  },
  #122
  %{
    diagnosis_id: di13.id,
    coverage_id: c2.id
  },
  #123
  %{
    diagnosis_id: di13.id,
    coverage_id: c3.id
  },
  #124
  %{
    diagnosis_id: di13.id,
    coverage_id: c4.id
  },
  #125
  %{
    diagnosis_id: di13.id,
    coverage_id: c5.id
  },
  #126
  %{
    diagnosis_id: di13.id,
    coverage_id: c6.id
  },
  #127
  %{
    diagnosis_id: di13.id,
    coverage_id: c7.id
  },
  #128
  %{
    diagnosis_id: di13.id,
    coverage_id: c8.id
  },
  #129
  %{
    diagnosis_id: di13.id,
    coverage_id: c9.id
  },
  #130
  %{
    diagnosis_id: di13.id,
    coverage_id: c10.id
  },
  #131
  %{
    diagnosis_id: di14.id,
    coverage_id: c1.id
  },
  #132
  %{
    diagnosis_id: di14.id,
    coverage_id: c2.id
  },
  #133
  %{
    diagnosis_id: di14.id,
    coverage_id: c3.id
  },
  #134
  %{
    diagnosis_id: di14.id,
    coverage_id: c4.id
  },
  #135
  %{
    diagnosis_id: di14.id,
    coverage_id: c5.id
  },
  #136
  %{
    diagnosis_id: di14.id,
    coverage_id: c6.id
  },
  #137
  %{
    diagnosis_id: di14.id,
    coverage_id: c7.id
  },
  #138
  %{
    diagnosis_id: di14.id,
    coverage_id: c8.id
  },
  #139
  %{
    diagnosis_id: di14.id,
    coverage_id: c9.id
  },
  #140
  %{
    diagnosis_id: di14.id,
    coverage_id: c10.id
  },
  #141
  %{
    diagnosis_id: di15.id,
    coverage_id: c1.id
  },
  #142
  %{
    diagnosis_id: di15.id,
    coverage_id: c2.id
  },
  #143
  %{
    diagnosis_id: di15.id,
    coverage_id: c3.id
  },
  #144
  %{
    diagnosis_id: di15.id,
    coverage_id: c4.id
  },
  #145
  %{
    diagnosis_id: di15.id,
    coverage_id: c5.id
  },
  #146
  %{
    diagnosis_id: di15.id,
    coverage_id: c6.id
  },
  #147
  %{
    diagnosis_id: di15.id,
    coverage_id: c7.id
  },
  #148
  %{
    diagnosis_id: di15.id,
    coverage_id: c8.id
  },
  #149
  %{
    diagnosis_id: di15.id,
    coverage_id: c9.id
  },
  #150
  %{
    diagnosis_id: di15.id,
    coverage_id: c10.id
  },
  #151
  %{
    diagnosis_id: di16.id,
    coverage_id: c1.id
  },
  #152
  %{
    diagnosis_id: di16.id,
    coverage_id: c2.id
  },
  #153
  %{
    diagnosis_id: di16.id,
    coverage_id: c3.id
  },
  #154
  %{
    diagnosis_id: di16.id,
    coverage_id: c4.id
  },
  #155
  %{
    diagnosis_id: di16.id,
    coverage_id: c5.id
  },
  #156
  %{
    diagnosis_id: di16.id,
    coverage_id: c6.id
  },
  #157
  %{
    diagnosis_id: di16.id,
    coverage_id: c7.id
  },
  #158
  %{
    diagnosis_id: di16.id,
    coverage_id: c8.id
  },
  #159
  %{
    diagnosis_id: di16.id,
    coverage_id: c9.id
  },
  #160
  %{
    diagnosis_id: di16.id,
    coverage_id: c10.id
  },
  #161
  %{
    diagnosis_id: di17.id,
    coverage_id: c1.id
  },
  #162
  %{
    diagnosis_id: di17.id,
    coverage_id: c2.id
  },
  #163
  %{
    diagnosis_id: di17.id,
    coverage_id: c3.id
  },
  #164
  %{
    diagnosis_id: di17.id,
    coverage_id: c4.id
  },
  #165
  %{
    diagnosis_id: di17.id,
    coverage_id: c5.id
  },
  #166
  %{
    diagnosis_id: di17.id,
    coverage_id: c6.id
  },
  #167
  %{
    diagnosis_id: di17.id,
    coverage_id: c7.id
  },
  #168
  %{
    diagnosis_id: di17.id,
    coverage_id: c8.id
  },
  #169
  %{
    diagnosis_id: di17.id,
    coverage_id: c9.id
  },
  #170
  %{
    diagnosis_id: di17.id,
    coverage_id: c10.id
  },
  #171
  %{
    diagnosis_id: di18.id,
    coverage_id: c1.id
  },
  #172
  %{
    diagnosis_id: di18.id,
    coverage_id: c2.id
  },
  #173
  %{
    diagnosis_id: di18.id,
    coverage_id: c3.id
  },
  #174
  %{
    diagnosis_id: di18.id,
    coverage_id: c4.id
  },
  #175
  %{
    diagnosis_id: di18.id,
    coverage_id: c5.id
  },
  #176
  %{
    diagnosis_id: di18.id,
    coverage_id: c6.id
  },
  #177
  %{
    diagnosis_id: di18.id,
    coverage_id: c7.id
  },
  #178
  %{
    diagnosis_id: di18.id,
    coverage_id: c8.id
  },
  #179
  %{
    diagnosis_id: di18.id,
    coverage_id: c9.id
  },
  #180
  %{
    diagnosis_id: di18.id,
    coverage_id: c10.id
  },
  #181
  %{
    diagnosis_id: di19.id,
    coverage_id: c1.id
  },
  #182
  %{
    diagnosis_id: di19.id,
    coverage_id: c2.id
  },
  #183
  %{
    diagnosis_id: di19.id,
    coverage_id: c3.id
  },
  #184
  %{
    diagnosis_id: di19.id,
    coverage_id: c4.id
  },
  #185
  %{
    diagnosis_id: di19.id,
    coverage_id: c5.id
  },
  #186
  %{
    diagnosis_id: di19.id,
    coverage_id: c6.id
  },
  #187
  %{
    diagnosis_id: di19.id,
    coverage_id: c7.id
  },
  #188
  %{
    diagnosis_id: di19.id,
    coverage_id: c8.id
  },
  #189
  %{
    diagnosis_id: di19.id,
    coverage_id: c9.id
  },
  #190
  %{
    diagnosis_id: di19.id,
    coverage_id: c10.id
  },
  #191
  %{
    diagnosis_id: di20.id,
    coverage_id: c1.id
  },
  #192
  %{
    diagnosis_id: di20.id,
    coverage_id: c2.id
  },
  #193
  %{
    diagnosis_id: di20.id,
    coverage_id: c3.id
  },
  #194
  %{
    diagnosis_id: di20.id,
    coverage_id: c4.id
  },
  #195
  %{
    diagnosis_id: di20.id,
    coverage_id: c5.id
  },
  #196
  %{
    diagnosis_id: di20.id,
    coverage_id: c6.id
  },
  #197
  %{
    diagnosis_id: di20.id,
    coverage_id: c7.id
  },
  #198
  %{
    diagnosis_id: di20.id,
    coverage_id: c8.id
  },
  #199
  %{
    diagnosis_id: di20.id,
    coverage_id: c9.id
  },
  #200
  %{
    diagnosis_id: di20.id,
    coverage_id: c10.id
  },
  #201
  %{
    diagnosis_id: di21.id,
    coverage_id: c1.id
  },
  #202
  %{
    diagnosis_id: di21.id,
    coverage_id: c2.id
  },
  #203
  %{
    diagnosis_id: di21.id,
    coverage_id: c3.id
  },
  #204
  %{
    diagnosis_id: di21.id,
    coverage_id: c4.id
  },
  #205
  %{
    diagnosis_id: di21.id,
    coverage_id: c5.id
  },
  #206
  %{
    diagnosis_id: di21.id,
    coverage_id: c6.id
  },
  #207
  %{
    diagnosis_id: di21.id,
    coverage_id: c7.id
  },
  #208
  %{
    diagnosis_id: di21.id,
    coverage_id: c8.id
  },
  #209
  %{
    diagnosis_id: di21.id,
    coverage_id: c9.id
  },
  #210
  %{
    diagnosis_id: di21.id,
    coverage_id: c10.id
  },
  #211
  %{
    diagnosis_id: di22.id,
    coverage_id: c1.id
  },
  #212
  %{
    diagnosis_id: di22.id,
    coverage_id: c2.id
  },
  #213
  %{
    diagnosis_id: di22.id,
    coverage_id: c3.id
  },
  #214
  %{
    diagnosis_id: di22.id,
    coverage_id: c4.id
  },
  #215
  %{
    diagnosis_id: di22.id,
    coverage_id: c5.id
  },
  #216
  %{
    diagnosis_id: di22.id,
    coverage_id: c6.id
  },
  #217
  %{
    diagnosis_id: di22.id,
    coverage_id: c7.id
  },
  #218
  %{
    diagnosis_id: di22.id,
    coverage_id: c8.id
  },
  #219
  %{
    diagnosis_id: di22.id,
    coverage_id: c9.id
  },
  #220
  %{
    diagnosis_id: di22.id,
    coverage_id: c10.id
  },
  #221
  %{
    diagnosis_id: di23.id,
    coverage_id: c1.id
  },
  #222
  %{
    diagnosis_id: di23.id,
    coverage_id: c2.id
  },
  #223
  %{
    diagnosis_id: di23.id,
    coverage_id: c3.id
  },
  #224
  %{
    diagnosis_id: di23.id,
    coverage_id: c4.id
  },
  #225
  %{
    diagnosis_id: di23.id,
    coverage_id: c5.id
  },
  #226
  %{
    diagnosis_id: di23.id,
    coverage_id: c6.id
  },
  #227
  %{
    diagnosis_id: di23.id,
    coverage_id: c7.id
  },
  #228
  %{
    diagnosis_id: di23.id,
    coverage_id: c8.id
  },
  #229
  %{
    diagnosis_id: di23.id,
    coverage_id: c9.id
  },
  #230
  %{
    diagnosis_id: di23.id,
    coverage_id: c10.id
  },
  #231
  %{
    diagnosis_id: di24.id,
    coverage_id: c1.id
  },
  #232
  %{
    diagnosis_id: di24.id,
    coverage_id: c2.id
  },
  #233
  %{
    diagnosis_id: di24.id,
    coverage_id: c3.id
  },
  #234
  %{
    diagnosis_id: di24.id,
    coverage_id: c4.id
  },
  #235
  %{
    diagnosis_id: di24.id,
    coverage_id: c5.id
  },
  #236
  %{
    diagnosis_id: di24.id,
    coverage_id: c6.id
  },
  #237
  %{
    diagnosis_id: di24.id,
    coverage_id: c7.id
  },
  #238
  %{
    diagnosis_id: di24.id,
    coverage_id: c8.id
  },
  #239
  %{
    diagnosis_id: di24.id,
    coverage_id: c9.id
  },
  #240
  %{
    diagnosis_id: di24.id,
    coverage_id: c10.id
  },
  #241
  %{
    diagnosis_id: di25.id,
    coverage_id: c1.id
  },
  #242
  %{
    diagnosis_id: di25.id,
    coverage_id: c2.id
  },
  #243
  %{
    diagnosis_id: di25.id,
    coverage_id: c3.id
  },
  #244
  %{
    diagnosis_id: di25.id,
    coverage_id: c4.id
  },
  #245
  %{
    diagnosis_id: di25.id,
    coverage_id: c5.id
  },
  #246
  %{
    diagnosis_id: di25.id,
    coverage_id: c6.id
  },
  #247
  %{
    diagnosis_id: di25.id,
    coverage_id: c7.id
  },
  #248
  %{
    diagnosis_id: di25.id,
    coverage_id: c8.id
  },
  #249
  %{
    diagnosis_id: di25.id,
    coverage_id: c9.id
  },
  #250
  %{
    diagnosis_id: di25.id,
    coverage_id: c10.id
  },
  #251
  %{
    diagnosis_id: di26.id,
    coverage_id: c1.id
  },
  #252
  %{
    diagnosis_id: di26.id,
    coverage_id: c2.id
  },
  #253
  %{
    diagnosis_id: di26.id,
    coverage_id: c3.id
  },
  #254
  %{
    diagnosis_id: di26.id,
    coverage_id: c4.id
  },
  #255
  %{
    diagnosis_id: di26.id,
    coverage_id: c5.id
  },
  #256
  %{
    diagnosis_id: di26.id,
    coverage_id: c6.id
  },
  #257
  %{
    diagnosis_id: di26.id,
    coverage_id: c7.id
  },
  #258
  %{
    diagnosis_id: di26.id,
    coverage_id: c8.id
  },
  #259
  %{
    diagnosis_id: di26.id,
    coverage_id: c9.id
  },
  #260
  %{
    diagnosis_id: di26.id,
    coverage_id: c10.id
  },
  #261
  %{
    diagnosis_id: di27.id,
    coverage_id: c1.id
  },
  #262
  %{
    diagnosis_id: di27.id,
    coverage_id: c2.id
  },
  #263
  %{
    diagnosis_id: di27.id,
    coverage_id: c3.id
  },
  #264
  %{
    diagnosis_id: di27.id,
    coverage_id: c4.id
  },
  #265
  %{
    diagnosis_id: di27.id,
    coverage_id: c5.id
  },
  #266
  %{
    diagnosis_id: di27.id,
    coverage_id: c6.id
  },
  #267
  %{
    diagnosis_id: di27.id,
    coverage_id: c7.id
  },
  #268
  %{
    diagnosis_id: di27.id,
    coverage_id: c8.id
  },
  #269
  %{
    diagnosis_id: di27.id,
    coverage_id: c9.id
  },
  #270
  %{
    diagnosis_id: di27.id,
    coverage_id: c10.id
  },
  #271
  %{
    diagnosis_id: di28.id,
    coverage_id: c1.id
  },
  #272
  %{
    diagnosis_id: di28.id,
    coverage_id: c2.id
  },
  #273
  %{
    diagnosis_id: di28.id,
    coverage_id: c3.id
  },
  #274
  %{
    diagnosis_id: di28.id,
    coverage_id: c4.id
  },
  #275
  %{
    diagnosis_id: di28.id,
    coverage_id: c5.id
  },
  #276
  %{
    diagnosis_id: di28.id,
    coverage_id: c6.id
  },
  #277
  %{
    diagnosis_id: di28.id,
    coverage_id: c7.id
  },
  #278
  %{
    diagnosis_id: di28.id,
    coverage_id: c8.id
  },
  #279
  %{
    diagnosis_id: di28.id,
    coverage_id: c9.id
  },
  #280
  %{
    diagnosis_id: di28.id,
    coverage_id: c10.id
  },
  #281
  %{
    diagnosis_id: di29.id,
    coverage_id: c1.id
  },
  #282
  %{
    diagnosis_id: di29.id,
    coverage_id: c2.id
  },
  #283
  %{
    diagnosis_id: di29.id,
    coverage_id: c3.id
  },
  #284
  %{
    diagnosis_id: di29.id,
    coverage_id: c4.id
  },
  #285
  %{
    diagnosis_id: di29.id,
    coverage_id: c5.id
  },
  #286
  %{
    diagnosis_id: di29.id,
    coverage_id: c6.id
  },
  #287
  %{
    diagnosis_id: di29.id,
    coverage_id: c7.id
  },
  #288
  %{
    diagnosis_id: di29.id,
    coverage_id: c8.id
  },
  #289
  %{
    diagnosis_id: di29.id,
    coverage_id: c9.id
  },
  #290
  %{
    diagnosis_id: di29.id,
    coverage_id: c10.id
  },
  #291
  %{
    diagnosis_id: di30.id,
    coverage_id: c1.id
  },
  #292
  %{
    diagnosis_id: di30.id,
    coverage_id: c2.id
  },
  #293
  %{
    diagnosis_id: di30.id,
    coverage_id: c3.id
  },
  #294
  %{
    diagnosis_id: di30.id,
    coverage_id: c4.id
  },
  #295
  %{
    diagnosis_id: di30.id,
    coverage_id: c5.id
  },
  #296
  %{
    diagnosis_id: di30.id,
    coverage_id: c6.id
  },
  #297
  %{
    diagnosis_id: di30.id,
    coverage_id: c7.id
  },
  #298
  %{
    diagnosis_id: di30.id,
    coverage_id: c8.id
  },
  #299
  %{
    diagnosis_id: di30.id,
    coverage_id: c9.id
  },
  #300
  %{
    diagnosis_id: di30.id,
    coverage_id: c10.id
  }

]

[dic1, dic2, dic3, dic4, dic5,
 dic6, dic7, dic8, dic9, dic10,
 dic11, dic12, dic13, dic14, dic15,
 dic16, dic17, dic18, dic19, dic20,
 dic21, dic22, dic23, dic24, dic25,
 dic26, dic27, dic28, dic29, dic30,
 dic31, dic32, dic33, dic34, dic35,
 dic36, dic37, dic38, dic39, dic40,
 dic41, dic42, dic43, dic44, dic45,
 dic46, dic47, dic48, dic49, dic50,
 dic51, dic52, dic53, dic54, dic55,
 dic56, dic57, dic58, dic59, dic60,
 dic61, dic62, dic63, dic64, dic65,
 dic66, dic67, dic68, dic69, dic70,
 dic71, dic72, dic73, dic74, dic75,
 dic76, dic77, dic78, dic79, dic80,
 dic81, dic82, dic83, dic84, dic85,
 dic86, dic87, dic88, dic89, dic90,
 dic91, dic92, dic93, dic94, dic95,
 dic96, dic97, dic98, dic99, dic100,
 dic101, dic102, dic103, dic104, dic105,
 dic106, dic107, dic108, dic109, dic110,
 dic111, dic112, dic113, dic114, dic115,
 dic116, dic117, dic118, dic119, dic120,
 dic121, dic122, dic123, dic124, dic125,
 dic126, dic127, dic128, dic129, dic130,
 dic131, dic132, dic133, dic134, dic135,
 dic136, dic137, dic138, dic139, dic140,
 dic141, dic142, dic143, dic144, dic145,
 dic146, dic147, dic148, dic149, dic150,
 dic151, dic152, dic153, dic154, dic155,
 dic156, dic157, dic158, dic159, dic160,
 dic161, dic162, dic163, dic164, dic165,
 dic166, dic167, dic168, dic169, dic170,
 dic171, dic172, dic173, dic174, dic175,
 dic176, dic177, dic178, dic179, dic180,
 dic181, dic182, dic183, dic184, dic185,
 dic186, dic187, dic188, dic189, dic190,
 dic191, dic192, dic193, dic194, dic195,
 dic196, dic197, dic198, dic199, dic200,
 dic201, dic202, dic203, dic204, dic205,
 dic206, dic207, dic208, dic209, dic210,
 dic211, dic212, dic213, dic214, dic215,
 dic216, dic217, dic218, dic219, dic220,
 dic221, dic222, dic223, dic224, dic225,
 dic226, dic227, dic228, dic229, dic230,
 dic231, dic232, dic233, dic234, dic235,
 dic236, dic237, dic238, dic239, dic240,
 dic241, dic242, dic243, dic244, dic245,
 dic246, dic247, dic248, dic249, dic250,
 dic251, dic252, dic253, dic254, dic255,
 dic256, dic257, dic258, dic259, dic260,
 dic261, dic262, dic263, dic264, dic265,
 dic266, dic267, dic268, dic269, dic270,
 dic271, dic272, dic273, dic274, dic275,
 dic276, dic277, dic278, dic279, dic280,
 dic281, dic282, dic283, dic284, dic285,
 dic286, dic287, dic288, dic289, dic290,
 dic291, dic292, dic293, dic294, dic295,
 dic296, dic297, dic298, dic299, dic300] =
   DiagnosisCoverageSeeder.seed(diagnosis_coverage_data)

#Seeding Member - MemberLink

IO.puts "Seeding member..."
member_data =
  [
    %{
      #1
      first_name: "MemberlinkAdministrator",
      middle_name: "Member",
      last_name: "link",
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
    }
  ]

[m1] = MemberSeeder.seed(member_data)

IO.puts "Seeding user for MemberLink"
user_member_data =
  [
    %{
      #1
      "username" => "memberlink_user",
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
    }
  ]

[um1] = UserSeeder.seed_memberlink(user_member_data)

IO.puts "Seeding user for AccountLink"
user_account_data =
  [
    %{
      #1
      user_id: u3.id,
      account_group_id: ag1.id,
      role: "role"
    }
  ]

[um1] = UserAccountSeeder.seed(user_account_data)

IO.puts "Seeding Practitioner"
practitioner_data =
  [
    %{
      #1
      first_name: "Sigmund",
      middle_name: "A",
      last_name: "Freud",
      gender: "Male",
      suffix: "Jr.",
      affiliated: "Yes",
      prc_no: "0000000",
      code: "123456",
      exclusive: ["PCS"],
      vat_status: "20% VAT-able",
      tin: "123456789012",
      payment_type: "Bank",
      bank_id: b1.id,
      payee_name: "Shane",
      account_no: "1234567890123456",
      created_by_id: u1.id,
      updated_by_id: u1.id,
      step: 5,
      birth_date: Ecto.Date.cast!("1966-10-10"),
      effectivity_from: Ecto.Date.cast!("1990-10-10"),
      effectivity_to: Ecto.Date.cast!("2090-10-10"),
      status: "Affiliated"
    },

    %{
      #2
      first_name: "Carl",
      middle_name: "A",
      last_name: "Jung",
      gender: "Male",
      suffix: "Jr.",
      affiliated: "Yes",
      prc_no: "0000001",
      code: "123457",
      status: "Affiliated",
      exclusive: ["PCS"],
      vat_status: "20% VAT-able",
      tin: "123456789013",
      payment_type: "Bank",
      bank_id: b1.id,
      payee_name: "Shane",
      account_no: "1234567890123457",
      created_by_id: u1.id,
      updated_by_id: u1.id,
      step: 5,
      birth_date: Ecto.Date.cast!("1966-10-10"),
      effectivity_from: Ecto.Date.cast!("1990-10-10"),
      effectivity_to: Ecto.Date.cast!("2090-10-10")
    },

    %{
      #3
      first_name: "Demosthenes",
      middle_name: "A",
      last_name: "Soriano",
      gender: "Male",
      affiliated: "Yes",
      prc_no: "0000002",
      code: "123458",
      status: "Affiliated",
      exclusive: ["PCS"],
      vat_status: "20% VAT-able",
      tin: "123456789014",
      payment_type: "Bank",
      bank_id: b1.id,
      payee_name: "Shane",
      account_no: "1234567890123458",
      created_by_id: u1.id,
      updated_by_id: u1.id,
      step: 5,
      birth_date: Ecto.Date.cast!("1966-10-10"),
      effectivity_from: Ecto.Date.cast!("1990-10-10"),
      effectivity_to: Ecto.Date.cast!("2090-10-10")
    }
  ]

[p1, p2, p3] = PractitionerSeeder.seed(practitioner_data)

IO.puts "Seeding practitioner specialization .."
practitioner_specialization_data = [
  %{
    practitioner_id: p1.id,
    specialization_id: s1.id,
    type: "Primary"
  },

  %{
    practitioner_id: p2.id,
    specialization_id: s2.id,
    type: "Primary"
  },

  %{
    practitioner_id: p3.id,
    specialization_id: s3.id,
    type: "Primary"
  }

]
[ps1, ps2, ps3] = PractitionerSpecializationSeeder.seed(practitioner_specialization_data)

IO.puts "Seeding practitioner facility .."
practitioner_facility_data = [
  #1
  %{
    affiliation_date: Ecto.Date.cast!("2000-10-10"),
    disaffiliation_date: Ecto.Date.cast!("2099-10-10"),
    payment_mode: "Umbrella",
    step: 5,
    coordinator_fee: Decimal.new(1000),
    consultation_fee: Decimal.new(1000),
    fixed: true,
    coordinator: true,
    fixed_fee: Decimal.new(1000),
    facility_id: f1.id,
    practitioner_id: p1.id,
    pstatus_id: d25.id
  },

  #2
  %{
    affiliation_date: Ecto.Date.cast!("2000-10-10"),
    disaffiliation_date: Ecto.Date.cast!("2099-10-10"),
    payment_mode: "Umbrella",
    step: 5,
    coordinator_fee: Decimal.new(1000),
    consultation_fee: Decimal.new(1000),
    fixed: true,
    coordinator: true,
    fixed_fee: Decimal.new(1000),
    facility_id: f2.id,
    practitioner_id: p2.id,
    pstatus_id: d25.id
  },

  #3
  %{
    affiliation_date: Ecto.Date.cast!("2000-10-10"),
    disaffiliation_date: Ecto.Date.cast!("2099-10-10"),
    payment_mode: "Umbrella",
    step: 5,
    coordinator_fee: Decimal.new(1000),
    consultation_fee: Decimal.new(1000),
    fixed: true,
    coordinator: true,
    fixed_fee: Decimal.new(1000),
    facility_id: f3.id,
    practitioner_id: p3.id,
    pstatus_id: d25.id
  }

]
[pf1, pf2, pf3] = PractitionerFacilitySeeder.seed(practitioner_facility_data)

IO.puts "Seeding practitioner schedules .."
practitioner_schedules_data = [
  #1
  %{
    practitioner_facility_id: pf1.id,
    day: "Monday",
    room: "1",
    time_from: Ecto.Time.cast!("12:00:00Z"),
    time_to: Ecto.Time.cast!("15:00:00Z")
  },

  #6
  %{
    practitioner_facility_id: pf3.id,
    day: "Monday",
    room: "1",
    time_from: Ecto.Time.cast!("12:00:00Z"),
    time_to: Ecto.Time.cast!("15:00:00Z")
  }
]
[pfs1, pfs2] = PractitionerScheduleSeeder.seed(practitioner_schedules_data)

IO.puts "Seeding account products"
account_product_data = [
  %{
    name: pro1.name,
    description: pro1.description,
    type: pro1.type,
    limit_applicability: pro1.limit_applicability,
    limit_type: pro1.limit_type,
    limit_amount: pro1.limit_amount,
    standard_product: pro1.standard_product,
    account_id: acc1.id,
    product_id: pro1.id,
    rank: 1
  }

]
[ap1] = AccountProductSeeder.seed(account_product_data)

IO.puts "Seeding account product benefit"
account_product_benefit_data = [
  #1
  %{
    account_product_id: ap1.id,
    product_benefit_id: pb1.id
  },
  #2
  %{
    account_product_id: ap1.id,
    product_benefit_id: pb6.id
  },
  #3
  %{
    account_product_id: ap1.id,
    product_benefit_id: pb11.id
  }

]
[apb1, apb2, apb3] = AccountProductBenefitSeeder.seed(account_product_benefit_data)

IO.puts "Seeding member product"
member_product_data = [
  #1
  %{
    account_product_id: ap1.id,
    member_id: m1.id,
    tier: 1
  }

]
[mpro1] = MemberProductSeeder.seed(member_product_data)

IO.puts "Seeding api address"
api_address_data = [
  #1
  %{
    name: "PAYORLINK 1.0",
    address: "https://api.maxicare.com.ph",
    username: "admin@mlservices.com",
    password: "P@ssw0rd1234"
  },
  #2
  %{
    name: "PROVIDERLINK_2",
    address: "https://providerlink-ip-ist.medilink.com.ph",
    username: "masteradmin",
    password: "P@ssw0rd"
  },
  #3
  %{
    name: "SAPCSRF",
    address: "https://sap-webd.maxicare.com.ph:8081/sap/opu/odata/sap/ZPUBD_SRV/",
    username: "JQUINGCO",
    password: "appcentric1"
  },
  #4
  %{
    name: "SAP-UpdateAccount",
    address: "https://sap-webd.maxicare.com.ph:8081/sap/opu/odata/sap/ZPUBD_SRV/UpdateAccountStatus",
    username: "JQUINGCO",
    password: "appcentric1"
  },
  #5 For Email
  %{
    name: "PAYORLINK_2",
    address: "https://payorlink-ip-ist.medilink.com.ph",
    username: "masteradmin",
    password: "P@ssw0rd"
  },
  #6 For Export PEME Accountlink
  %{
    name: "MEMBERLINK",
    address: "https://memberlink-ip-ist.medilink.com.ph",
    username: "memberlink_user",
    password: "P@ssw0rd"
  },
  #7 For Paylink Request LOA
  %{
    name: "PaylinkAPI",
    address: "https://api.maxicare.com.ph/paylinkapi/",
    username: "admin@mlservices.com",
    password: "P@ssw0rd1234"
  }
]
[aa1, aa2, aa3, aa4, aa5, aa6, aa7] = ApiAddressSeeder.seed(api_address_data)

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

#create common password
IO.puts "Seeding common password..."
common_password_data =
  [
    %{
      #1
      password: "P@ssw0rd"
    },
    %{
      #2
      password: "#Passwor1"
    },
    %{
      #3
      password: "P@ssw0rd123"
    },
  ]

[cp1, cp2, cp3] = CommonPasswordSeeder.seed(common_password_data)

#Create Terms and Conditions
IO.puts "Seeding terms and conditions..."
terms_data = [
 %{
    version: "00"
  }
]
[tnc1] = TermsNConditionSeeder.seed(terms_data)

#Create Region
IO.puts "Seeding regions..."
region_data = [
  #1
  %{
    island_group: "Luzon",
    region: "Region I - Ilocos Region",
    index: 1
  },
  #2
  %{
    island_group: "Luzon",
    region: "Region II - Cagayan Valley",
    index: 2
  },
  #3
  %{
    island_group: "Luzon",
    region: "Region III - Central Luzon",
    index: 3
  },
  #4
  %{
    island_group: "Luzon",
    region: "Region IVA - CALABARZON",
    index: 4
  },
  #5
  %{
    island_group: "Luzon",
    region: "Region IVB - MIMAROPA Western Tagalog Region",
    index: 5
  },
  #6
  %{
    island_group: "Luzon",
    region: "Region V - Bicol Region",
    index: 6
  },
  #7
  %{
    island_group: "Luzon",
    region: "CAR - Cordillera Administrative Region",
    index: 7
  },
  #1
  %{
    island_group: "Luzon",
    region: "NCR - National Capital Region",
    index: 8
  },
  #9
  %{
    island_group: "Visayas",
    region: "Region VI - Western Visayas",
    index: 9
  },
  #10
  %{
    island_group: "Visayas",
    region: "Region VII - Central Visayas",
    index: 10
  },
  #11
  %{
    island_group: "Visayas",
    region: "Region VIII - Eastern Visayas",
    index: 11
  },
  #12
  %{
    island_group: "Mindanao",
    region: "Region IX - Zamboanga Peninsula",
    index: 12
  },
  #13
  %{
    island_group: "Mindanao",
    region: "Region X - Northern Mindanao",
    index: 13
  },
  #14
  %{
    island_group: "Mindanao",
    region: "Region XI - Davao Region",
    index: 14
  },
  #15
  %{
    island_group: "Mindanao",
    region: "Region XII - SOCCSARGEN",
    index: 15
  },
  #16
  %{
    island_group: "Mindanao",
    region: "Region XIII - CARAGA Region",
    index: 16
  },
  #17
  %{
    island_group: "Mindanao",
    region: "ARMM - Autonimous Region of Muslim Mindanao",
    index: 17
  },
  #18
  %{
    island_group: "Luzon",
    region: "All",
    index: 18
  },
  #19
  %{
    island_group: "Visayas",
    region: "All",
    index: 19
  },
  #20
  %{
    island_group: "Mindanao",
    region: "All",
    index: 20
  }

]
[r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13, r14, r15, r16, r17, r18, r19, r20] = RegionSeeder.seed(region_data)
