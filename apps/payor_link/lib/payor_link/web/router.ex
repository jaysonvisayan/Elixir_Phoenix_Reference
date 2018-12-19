defmodule Innerpeace.PayorLink.Web.Router do
  use Innerpeace.PayorLink.Web, :router

  if Mix.env == :dev || Mix.env == :test do
    forward "/sent_emails", Bamboo.EmailPreviewPlug
  else
    use Plug.ErrorHandler
    use Sentry.Plug
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    # plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug :fetch_flash
  end

  pipeline :auth_api do
    plug :accepts, ["json", "json-api"]
    plug PayorLink.Guardian.AuthPipeline.JSON
  end

  pipeline :token_required do
    plug Guardian.Plug.EnsureAuthenticated,
      handler: Innerpeace.PayorLink.Web.Api.V1.SessionController
  end

  pipeline :session_required do
    plug PayorLink.Guardian.AuthPipeline.Browser
    plug PayorLink.Guardian.AuthPipeline.Authenticate
    plug Innerpeace.Auth.CurrentUser
    plug Auth.SlidingSessionTimeout, timeout_after_seconds: 600
  end

  pipeline :auth_layout do
    plug :put_layout, {Innerpeace.PayorLink.Web.LayoutView, :auth}
  end

  pipeline :loaderio_layout do
    plug :protect_from_forgery
    plug :put_layout, {Innerpeace.PayorLink.Web.LayoutView, :loaderio}
  end

  pipeline :main_layout do
    # plug :protect_from_forgery
    plug :put_layout, {Innerpeace.PayorLink.Web.LayoutView, :main}
  end

  pipeline :no_session do
    plug :put_layout, {Innerpeace.PayorLink.Web.LayoutView, :no_session_layout}
  end

  pipeline :new_layout do
    plug :protect_from_forgery
    plug :put_layout, {Innerpeace.PayorLink.Web.LayoutView, :new}
  end

  pipeline :auth_main_layout do
    plug :put_layout, {Innerpeace.PayorLink.Web.LayoutView, :auth_main}
  end

  pipeline :acunetix do
    plug :accepts, ["html", "xml"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/web", Innerpeace.PayorLink.Web.Main, as: :main do
    pipe_through [:browser, :no_session]
    get "/view_acu_schedules/:id", AcuScheduleController, :show
  end

  ################# new apd design routes ##############################################
  scope "/web", Innerpeace.PayorLink.Web.Main, as: :main do
    pipe_through [:browser, :main_layout, :session_required]

    get "/", PageController, :index

    # Accounts Module
    get "/accounts", AccountController, :index
    get "/accounts/:code/view", AccountController, :view #Vue JS

    # Users Module
    get "/users", UserController, :index
    get "/users/new", UserController, :new
    post "/users/new", UserController, :create
    get "/users/load_facilities", UserController, :load_facilities
    get "/users/:id", UserController, :show
    get "/users/:id/edit", UserController, :edit
    put "/users/:id/edit", UserController, :save
    put "/users/:id/update_status", UserController, :update_user_status
    get "/check_existing_username", UserController, :check_existing_username
    get "/check_existing_user_mobile", UserController, :check_existing_mobile
    get "/check_existing_user_email", UserController, :check_existing_email
    get "/check_existing_user_payroll", UserController, :check_existing_payroll
    get "/get_all_company_users", UserController, :get_all_company_users
    get "/users/index/data", UserController, :index_data

    ## Product Module
    get "/products", ProductController, :index
    post "/products", ProductController, :validate_category
    post "/products/load_product", ProductController, :load_product
    get "/products/new_reg", ProductController, :new_reg
    get "/products/index/data", ProductController, :load_index

    get "/products/new_peme", ProductController, :new_peme
    post "/products/new", ProductController, :create
    post "/products/new_peme", ProductController, :create_peme
    get "/products/new_dental", ProductController, :new_dental
    post "/products/save_as_draft", ProductController, :dental_draft_step1
    post "/products/new_dental", ProductController, :create_dental
    get "/products/:id/setup", ProductController, :setup
    post "/products/:id/setup", ProductController, :update_setup
    put "/products/:id/setup", ProductController, :update_setup
    post "/products/:product_id/save_pcf", ProductController, :save_pcf
    post "/products/:id/submit_coverage", ProductController, :submit_coverage

    delete "/products/:id/delete/product_facilities", ProductController, :delete_product_coverage_facilities
    get "/products/load_fa", ProductController, :load_facility_access
    get "/products/load_dropdown_facilities", ProductController, :load_dropdown_facilities
    post "/products/:id/edit", ProductController, :save
    put "/products/:id/edit", ProductController, :save
    post "/products/:id/update_facility_dental", ProductController, :update_facility_dental
    put "/products/:id/update_facility_dental", ProductController, :edit_update_facility_dental

    # get "/products/benefit/:pb_id", ProductController, :show_product_benefit
    get "/products/benefit/:pb_id", ProductController, :show_product_benefit_v2

    get "/products/:id/edit", ProductController, :edit_setup
    post "/products/:id/update_pb", ProductController, :update_pb

    put "/products/:id/update_general_peme", ProductController, :update_general_peme
    put "/products/:id/update_general", ProductController, :update_general
    put "/products/:id/update_general_reg_plan", ProductController, :update_general_reg_plan
    put "/products/:id/update_condition", ProductController, :update_condition
    post "/products/:id/update_product_benefit", ProductController, :update_product_benefit
    get "/products/benefit/:id/view_package", ProductController, :load_view_package
    get "/products/:id/save_dental_plan", ProductController, :save_dental_plan

    get "/get_all_product_code", ProductController, :get_all_product_code
    get "/products/delete/:id/:product_id/product_benefit", ProductController, :delete_product_benefit
    get "/products/delete/:id/:product_id/product_coverage", ProductController, :delete_product_coverage
    get "/products/delete/:id/:product_id/risk_share", ProductController, :delete_product_risk_share

    get "/products/load_benefit", ProductController, :load_benefit

    ## DENTAL LEVEL 1
    post "/products/load_dental_benefit", ProductController, :load_benefit
    post "/products/load_all_dental_benefit", ProductController, :load_all_dental_benefit
    post "/products/load_all_selected_dental_benefit", ProductController, :load_all_selected_dental_benefit
    post "/products/compare_procedure_ids", ProductController, :procedure_checker

    ## DENTAL LEVEL 2
    post "/products/dental/load_facility_datatable", ProductController, :load_facility_datatable
    post "/products/:id/dental/insert_pclg", ProductController, :insert_product_coverage_location_group
    post "/products/:id/dental/insert_pcf", ProductController, :insert_product_coverage_facility
    post "/products/dental/load_all_facility", ProductController, :load_all_dental_facility

    delete "/products/:product_id/product_benefit/:id/step", ProductController, :deleting_product_benefit_step
    delete "/products/:id/delete_all", ProductController, :delete_product_all
    get "/products/setup", ProductController, :setup

    get "/products/:id/show", ProductController, :show

    post "/products/:product_id/copy", ProductController, :copy_product
    get "/products/:prod_id/facility_risk_share", ProductController, :get_product_facility_rs
    post "/products/:id/save_product_risk_share", ProductController, :create_product_coverage_risk_share_dental
    post "/products/:id/update_product_risk_share", ProductController, :update_product_coverage_risk_share_dental
    put "/products/:id/update_product_risk_share", ProductController, :update_product_coverage_risk_share_dental
    get "/products/dental_benefit_index/data", ProductController, :load_dental_benefit_index
    get "/products/dental_facility_index/data", ProductController, :load_dental_facility_index
    get "/products/dental_facility/data", ProductController, :load_dental_facility_index2
    get "/products/dental_risk_share_index/data", ProductController, :load_dental_risk_share_index

    ## Member module
    post "/members/upload_status", MemberController, :upload_status
    get "/members", MemberController, :index
    get "/members/index/data", MemberController, :load_index
    get "/members/index/batch_data", MemberController, :load_batch_index
    get "/members/batch_processing", MemberController, :batch_processing
    get "/members/member_detail", MemberController, :member_detail
    get "/members/new", MemberController, :new
    get "/members/:id/", MemberController, :show_page
    # get "/roles/:id", RoleController, :show_page
    post "/members/new", MemberController, :create_general
    post "/members/choose", MemberController, :choose_member_upload_type
    post "/members/:id/add_product", MemberController, :add_member_product
    get "/members/:id/setup", MemberController, :setup
    put "/members/:id/setup", MemberController, :update_setup
    post "/members/:id/setup", MemberController, :update_setup

    delete "/members/:id/delete_all", MemberController, :delete_member_all
    delete "/members/:member_id/member_product/:id", MemberController, :delete_member_product

    get "/members/:id/edit", MemberController, :edit_setup

    put "/members/:id/update_general", MemberController, :update_general
    put "/members/:id/update_contact", MemberController, :update_contact
    put "/members/:id/update_product", MemberController, :update_product

    post "/members/batch_processing", MemberController, :import_member

    get "/members/pwd_id/all", MemberController, :get_pwd_id
    get "/members/senior_id/all", MemberController, :get_senior_id

    get "/products/setup", ProductController, :setup

    # Benefit Routes
    get "/benefits", BenefitController, :index
    post "/benefits/new", BenefitController, :choose_benefit_type
    # post "/benefits/create", BenefitController, :create
    post "/benefits/create", BenefitController, :create_v2
    post "/benefits/create_healthplan", BenefitController, :create_healthplan
    get "/benefits/load_benefit_data", BenefitController, :load_benefit

    get "/benefits/delete_benefit/:id", BenefitController, :delete_benefit
    get "/benefits/index/data", BenefitController, :load_index
    get "/benefits/check_benefit_code/:code", BenefitController, :check_code
    get "/benefits/load_diagnosis", BenefitController, :load_diagnosis
    get "/benefits/load_all_diagnosis", BenefitController, :load_all_diagnosis
    get "/benefits/load_coverages", BenefitController, :load_coverages
    get "/benefits/load_packages", BenefitController, :load_packages
    get "/benefits/get_package", BenefitController, :get_package
    get "/benefits/set_benefit_package", BenefitController, :set_benefit_package
    get "/benefits/load_procedure", BenefitController, :load_procedure
    get "/benefits/create_new_rider", BenefitController, :create_new_rider

    ## Benefit module
    # get "/benefits", BenefitController, :benefit_list
    # get "/benefits/add_benefit_healthplan", BenefitController, :add_benefit_healthplan
    get "/benefits/add_benefit_riders", BenefitController, :add_benefit_riders
    # get "/benefits/benefit_detail", BenefitController, :benefit_detail
    put "/discontinue_peme_benefit", BenefitController, :discontinue_peme_benefit
    post "/discontinue_peme_benefit", BenefitController, :discontinue_peme_benefit
    post "/delete_peme_benefit", BenefitController, :delete_peme_benefit
    put "/delete_peme_benefit", BenefitController, :delete_peme_benefit
    put "/disable_benefit", BenefitController, :disabling_benefit
    post "/disable_benefit", BenefitController, :disabling_benefit
    get "/benefits/:id" , BenefitController, :show
    put "/benefits/:id/edit" , BenefitController, :edit
    # put "/benefits/:id/update" , BenefitController, :update
    put "/benefits/:id/update" , BenefitController, :update_v2
    get "/benefits/:code/view", BenefitController, :view
    get "/benefits/:code/show", BenefitController, :view_benefit


    ## Role Module
    # get "/roles/:id/setup", RoleController, :setup
    # put "/roles/:id/setup", RoleController, :update_setup
  # post "/roles/:id/setup", RoleController, :update_setup
    get "/roles", RoleController, :index
    get "/roles/new", RoleController, :new
    post "/roles/new", RoleController, :create
    get "/roles/:id", RoleController, :show
    delete "/roles/:id", RoleController, :delete
    get "/roles/load/role_name", RoleController, :load_all_roles
    get "/roles/:id/edit", RoleController, :edit
    put "/roles/:id/edit", RoleController, :save
    get "/roles/coverages/name", RoleController, :get_coverage_name

    ## Acu Schedule module
    get "/acu_schedules", AcuScheduleController, :index
    get "/acu_schedules/new", AcuScheduleController, :new
    post "/acu_schedules/finalize", AcuScheduleController, :finalize
    post "/acu_schedules/save_as_draft", AcuScheduleController, :save_as_draft
    post "/acu_schedules/new", AcuScheduleController, :create_acu_schedule
    get "/acu_schedules/:id/edit", AcuScheduleController, :edit
    put "/acu_schedules/update_status/remove", AcuScheduleController, :update_asm_status
    put "/acu_schedules/update_status/multiple", AcuScheduleController, :update_multiple_asm_status
    post "/acu_schedules/:id/request_loa", AcuScheduleController, :create_acu_schedule_loa
    post "/acu_schedules/:id/submit_acu_schedule_member", AcuScheduleController, :submit_acu_schedule_member
    put "/acu_schedules/:id/edit", AcuScheduleController, :update_acu_schedule
    put "/acu_schedules/packages/update_rate", AcuScheduleController, :update_acu_package_rate
    get "/acu_schedules/:id", AcuScheduleController, :show
    get "/acu_schedules/export/:acu_data", AcuScheduleController, :acu_schedule_export

    get "/acu_schedule_members/load_datatable", AcuScheduleController, :asm_member_load_datatable

    get "/acu_schedules/get_active/members", AcuScheduleController, :number_of_members

    #Datatable
    get "/acu_schedules/:id/datatable/load/members", AcuScheduleController, :load_members_tbl
    get "/acu_schedules/:id/datatable/load/members/show", AcuScheduleController, :load_members_tbl_show
    get "/acu_schedules/:id/datatable/load/removed_members", AcuScheduleController, :load_remove_members_tbl
    get "/acu_schedules/:id/discard", AcuScheduleController, :discard_acu_schedule
    get "/benefits/:id/load_benefit_packages", BenefitController, :load_benefit_package_dt
    get "/benefits/:id/load_benefit_limit", BenefitController, :load_benefit_limit_dt
    get "/benefits/:id/load_procedure_data", BenefitController, :load_procedure_data
    get "/benefits/:id/load_diagnosis_data", BenefitController, :load_diagnosis_data
    get "/benefits/:id/load_dental_procedure_data", BenefitController, :load_dental_procedure_data

    #Facility Group Module
    get "/facility_groups", FacilityGroupController, :index
    get "/facility_groups/new", FacilityGroupController, :new
    get "/facility_groups/:id/show", FacilityGroupController, :show
    post "/facility_groups/new", FacilityGroupController, :create
    get "/facility_groups/get_all_names", FacilityGroupController, :get_all_names
    get "/facility_groups/:id/edit_draft", FacilityGroupController, :edit_draft
    put "/facility_groups/:id/edit_draft", FacilityGroupController, :update_draft
    get "/facility_groups/load_fg_data", FacilityGroupController, :load_facility_group

    get "/facility_groups/:id/edit_save", FacilityGroupController, :edit_save
    put "/facility_groups/:id/edit_save", FacilityGroupController, :update_save

    # location group Datatable
    post "/facility_groups/load_facilities", FacilityGroupController, :load_facilities
    get "/facility_groups/show_load_datatable/:id", FacilityGroupController, :show_load_datatable
    get "/facility_groups/index/data", FacilityGroupController, :location_group_index

    post "/facility_groups/check_existing_facility_group_name", FacilityGroupController, :check_existing_facility_group_name
    post "/facility_groups/check_existing_facility_group_name_edit", FacilityGroupController, :check_existing_facility_group_name_edit
    # Exclusion Module
    get "/exclusions", ExclusionController, :index
    get "/exclusions/:id/show", ExclusionController, :show
    get "/exclusions/:code/view", ExclusionController, :view
    get "/exclusions/:code/view_general", ExclusionController, :view_general

    # Exclusion datatable
    get "/exclusions/:id/show/load_diagnosis", ExclusionController, :load_diagnosis
    get "/exclusions/:id/show/load_condition", ExclusionController, :load_condition

  end
  ######################################################################################

  scope "/", Innerpeace.PayorLink.Web do
    pipe_through [:browser, :loaderio_layout]

    get "/loaderio-3b2260f6ebe3274a50035a38e9d4f4a2", SessionController, :loaderio_ist
    get "/loaderio-773b562690212f26bd74ba197be27cf3", SessionController, :loaderio_uat
  end

  scope "/", Innerpeace.PayorLink.Web do
    pipe_through [:browser, :new_layout]

    get "/sign_in", SessionController, :new
  end

  scope "/", Innerpeace.PayorLink.Web do
    pipe_through [:browser, :auth_main_layout]

    get "/forgot_password", SessionController, :forgot_password
    post "/forgot_password", SessionController, :send_verification2

    get "/verify_code/:id", SessionController, :verify_code
    post "/verify_code/:id", SessionController, :code_verification
    get "/resend_code/:id", SessionController, :resend_code
    post "/resend_code/:id", SessionController, :code_verification
    get "/reset_password/:reset_token", SessionController, :reset_password
    put "/reset_password/:reset_token", SessionController, :update_password
    get "/verify_code_sms/:id", SessionController, :verify_code_sms

  end

  scope "/", Innerpeace.PayorLink.Web do
    pipe_through [:browser, :auth_layout] # Use the default browser stack

    get "/generate_balancing_file", MemberController, :generate_balancing_file

    post "/sign_in", SessionController, :create
    get "/create", SessionController, :create_password
    put "/create/:password_token", SessionController, :insert_password
    # post "/forgot_password", SessionController, :send_verification

       # get "/sign", SessionController, :load_all_username
  end

  scope "/", Innerpeace.PayorLink.Web do
    pipe_through [:browser, :session_required] # Use the default browser stack

    get "/", PageController, :index
    get "/forms", PageController, :sample_forms
    get "/print", PageController, :sample_print

    delete "/sign_out", SessionController, :delete

    get "/sign_out_error_dt", SessionController, :sign_out_error_dt

    #Account
    get "/accounts/load_products", AccountController, :load_products_tbl
    resources "/accounts", AccountController
    get "/accounts/:id/versions", AccountController, :index_versions
    get "/accounts/:id/setup", AccountController, :setup
    put "/accounts/:id/setup", AccountController, :update_setup
    post "/accounts/:id/setup", AccountController, :update_setup
    post "/accounts/:id/new_address", AccountController, :create_address
    put "/accounts/:id/edit_address", AccountController, :update_address
    post "/accounts/:id/new_contact", AccountController, :create_contact
    put "/accounts/:id/edit_contact", AccountController, :update_contact
    get "/accounts/:id/get_contact", AccountController, :get_contact #API
    get "/accounts/:id/next_contact", AccountController, :next_contact
    post "/accounts/:id/new_financial", AccountController, :create_financial
    put "/accounts/:id/new_financial", AccountController, :update_financial
    post "/accounts/:id/create_coverage_fund", AccountController, :create_coverage_fund
    delete "/accounts/:id/delete_coverage_fund", AccountController, :delete_coverage_fund
    post "/accounts/:id/new_product", AccountController, :create_product
    post "/accounts/:id/edit_product", AccountController, :update_product
    get "/accounts/:id/get_account_product", AccountController, :get_account_product #API
    get "/accounts/:id/summary", AccountController, :submit_summary
    delete "/accounts/:id/remove_photo", AccountController, :remove_photo
    get "/get_all_account_name", AccountController, :get_all_account_name #API
    get "/get_all_account_tin", AccountController, :get_all_account_tin #API
    delete "/accounts/:id/delete_contact", AccountController, :delete_account_contact
    delete "/accounts/:id/delete_account_product", AccountController, :delete_account_product
    get "/accounts/:id/cancel", AccountController, :update_cancel
    post "/accounts/:id/cancel", AccountController, :update_cancel
    get "/accounts/:id/logs", AccountController, :show_logs
    post "/accounts/:id/new_approver", AccountController, :create_approver
    put "/accounts/:id/new_approver", AccountController, :create_approver
    delete "/accounts/:id/delete_approver/:account_id", AccountController, :delete_approver
    post "/accounts/:id/on_click_update", AccountController, :on_click_update
    post "/accounts/:id/extend_account", AccountController, :extend_account
    put "/accounts/:id/extend_account", AccountController, :extend_account
    put "/accounts/:id/save_product_tier", AccountController, :save_product_tier
    get "/accounts/:id/save_product_tier", AccountController, :save_product_tier


    #Card Fulfillment in Account
    resources "/fulfillment_card", FulfillmentCardController

    get "/accounts/:id/new_card", FulfillmentCardController, :new_card
    get "/accounts/:id/card/:fulfillment_id/new_edit_card", FulfillmentCardController, :new_card_edit
    get "/accounts/:id/card/:fulfillment_id/edit_card", FulfillmentCardController, :new_edit_card
    get "/accounts/:id/card/:fulfillment_id/edit_document", FulfillmentCardController, :edit_document
    get "/accounts/:id/card/:fulfillment_id/new_document", FulfillmentCardController, :new_document
    post "/accounts/:id/create_fulfillment", FulfillmentCardController, :create_card
    put "/accounts/:id/create_fulfillment", FulfillmentCardController, :create_card
    post "/accounts/:id/card/:fulfillment_id/create_document", FulfillmentCardController, :create_document
    put "/accounts/:id/card/:fulfillment_id/create_document", FulfillmentCardController, :create_document
    put "/accounts/:id/card/:fulfillment_id/update_card", FulfillmentCardController, :update_card
    get "/accounts/:id/card/:fulfillment_id/delete", FulfillmentCardController, :delete_card
    get "/fulfillments/:id/remove_photo", FulfillmentCardController, :remove_fulfillment_photo
    get "/fulfillments/:id/get_fulfillment_files", FulfillmentCardController, :get_fulfillment_files
    #end of Card Fulfillment

    post "/accounts/:id/new_comment", AccountController, :create_account_comment
    post "/accounts/:id/renew_account", AccountController, :renew_account
    post "/accounts/:id/activate_account", AccountController, :activate_account
    post "/accounts/:id/cancel_renewal", AccountController, :cancel_renewal
    post "/accounts/:id/suspend_account", AccountController, :suspend_account_in_account
    post "/accounts/:id/reactivate_account", AccountController, :reactivate_account_in_account
    get "/accounts/:id/print_account", AccountController, :print_account
    post "/accounts/index/download", AccountController, :download_accounts
    post "/accounts/:id/retract", AccountController, :retract_account
    post "/accounts/:account_id/save_ahoed", AccountController, :save_ahoed
    #DataTables
    get "/accounts/index/data", AccountController, :account_index

    #Application
    resources "/applications", ApplicationController

    #Coverage
    resources "/coverages", CoverageController

    #Room
    resources "/rooms", RoomController, except: [:show]
    get "/rooms", RoomController, :index
    get "/rooms/:id/update", RoomController, :edit
    post "/rooms/:id/", RoomController, :update
    get "/rooms/:id/logs", RoomController, :show_logs
    get "/get_all_room_type", RoomController, :get_all_room_type #API
    get "/get_all_room_code_and_type", RoomController, :get_all_room_code_and_type
    get "/rooms/:id/get_a_room", RoomController, :show_facilities

    #Cluster
    resources "/clusters", ClusterController
    get "/clusters/:id/delete", ClusterController, :delete
    get "/clusters/:id/delete_account_group_clusters", ClusterController, :delete_account_group_clusters
    get "/clusters/:id/delete_edit_account_group_clusters", ClusterController, :delete_edit_account_group_clusters
    get "/clusters/:id/setup", ClusterController, :setup
    put "/clusters/:id/setup", ClusterController, :update_setup
    post "/clusters/:id/setup", ClusterController, :update_setup
    post "/clusters/:id/new_account", ClusterController, :create_account
    get "/clusters/:id/next_step3", ClusterController, :next_step3
    get "/clusters/:id", ClusterController, :show
    get "/clusters/:id/accounts/:account_id", ClusterController, :account_movements
    get "/clusters/:id/accounts/:account_id/get_all_group_accounts", ClusterController, :get_all_group_accounts
    get "/clusters/load/cluster_code", ClusterController, :load_all_clusters
    get "/clusters/load/cluster_name", ClusterController, :load_all_clusters_name
    get "/clusters/:id/edit", ClusterController, :edit_setup
    post "/clusters/:id/edit", ClusterController, :update_edit_setup
    put "/clusters/:id/edit", ClusterController, :update_edit_setup
    post "/clusters/renew", ClusterController, :update_renew
    post "/clusters/cancel", ClusterController, :update_cancel
    post "/cluster/suspend", ClusterController, :update_suspend
    post "/clusters/extend", ClusterController, :update_extend
    get "/clusters/:id/:message/logs", ClusterController, :show_log
    get "/clusters/:id/logs", ClusterController, :show_all_log
    get "/clusters/:id/print_cluster", ClusterController, :print_cluster
    get "/clusters/:id/submit", ClusterController, :submit

     # Roles
    get "/roles/:id/setup", RoleController, :setup
    put "/roles/:id/setup", RoleController, :update_setup
    post "/roles/:id/setup", RoleController, :update_setup
    get "/roles", RoleController, :index
    get "/roles/new", RoleController, :new
    post "/roles/new", RoleController, :create
    get "/roles/:id", RoleController, :show
    delete "/roles/:id", RoleController, :delete
    get "/roles/load/role_name", RoleController, :load_all_roles
    get "/roles/coverages/name", RoleController, :get_coverage_name

    # Users
    get "/users", UserController, :index
    get "/users/new", UserController, :new
    post "/users/new", UserController, :create_basic
    get "/users/:id/setup", UserController, :setup
    put "/users/:id/setup", UserController, :update_setup
    post "/users/:id/setup", UserController, :update_setup
    delete "/users/:id/setup", UserController, :delete
    get "/users/:id", UserController, :show
    get "/users/get/validate", UserController, :user_validate
    get "/change_password", SessionController, :change_password
    put "/:id/change_password", SessionController, :submit_change_password

    # Users Access Activation
    get "/user_access_activations", UserAccessActivationController, :index
    get "/user_access_activations/download/template", UserAccessActivationController, :download_template
    post "/user_access_activations/import/activation", UserAccessActivationController, :import_activation

    # Products
    get "/products", ProductController, :index
    get "/products/load_datatable", ProductController, :index_load_datatable
    get "/products/new/peme", ProductController, :new_peme
    get "/products/new/reg", ProductController, :new_reg
    post "/products/new", ProductController, :create
    post "/products/new/peme", ProductController, :create_peme
    get "/products/:id/setup", ProductController, :setup
    get "/products/:id/product_benefit/:product_benefit_id/setup", ProductController, :setup
    put "/products/:id/setup", ProductController, :update_setup
    put "/products/:product_id/update_product_coverage/:coverage_id", ProductController, :update_product_coverage
    post "/products/:id/setup", ProductController, :update_setup
    get "/products/:product_benefit_limit_id/get_product_benefit_limit", ProductController, :get_product_benefit_limit
    get "/products/:exclusion_id/get_exclusion", ProductController, :get_exclusion
    get "/products/:product_risk_share_id/get_product_risk_share", ProductController, :get_product_risk_share
    get "/products/:product_risk_share_id/get_product_risk_share/:facility_id", ProductController, :get_product_rs_facility
    get "/products/:product_risk_share_facility_id/get_product_risk_share_facility", ProductController, :get_product_risk_share_facility
    get "/products/:product_risk_share_facility_id/get_product_risk_share_facility/:procedure_id", ProductController, :get_prsf_procedure
    delete "/delete_prs_facility/:id", ProductController, :delete_prs_facility
    delete "/delete_prs_procedure/:id", ProductController, :delete_prsf_procedure
    get "/products/:product_facility_id/get_product_facilities", ProductController, :get_product_facilities
    delete "/products/:product_facility_id/deleting_product_facility", ProductController, :deleting_product_facility
    delete "/products/:product_coverage_id/deleting_product_facilities/", ProductController, :deleting_product_facilities
    delete "/products/:product_id/product_exclusion/:product_exclusion_id", ProductController, :delete_product_exclusion

    delete "/products/:product_id/product_benefit/:id/step", ProductController, :deleting_product_benefit_step
    delete "/products/:product_id/product_benefit/:id/edit", ProductController, :deleting_product_benefit_edit
    put "/products/:product_coverage_id/insert_coverage_type/:type/:product_id/:coverage_id", ProductController, :insert_coverage_type
    put "/products/:product_id/update_prsf_coverage/:coverage_id", ProductController, :update_prsf_coverage
    put "/products/:product_id/update_rnb_coverage/:coverage_id", ProductController, :update_rnb_coverage
    put "/products/:product_id/update_lt_coverage/:coverage_id", ProductController, :update_lt_coverage
    get "/products/:product_coverage_id/product_risk_share/", ProductController, :filter_prs_facilities
    get "/products/:product_coverage_id/included_product_risk_share/", ProductController, :filter_included_prs_facilities
    get "/products/:product_id/product_risk_share_facility/:product_risk_share_facility_id", ProductController, :filter_prs_facility_procedures
    get "/products/:product_id/included_product_risk_share_facility/:product_risk_share_facility_id", ProductController, :filter_included_prs_facility_procedures
    get "/products/:product_limit_threshold_id/get_product_limit_threshold", ProductController, :filter_pcltf
    get "/products/:product_limit_threshold_id/get_product_limit_threshold_edit", ProductController, :filter_pcltf_edit
    delete "/products/:pcltf_id/delete_pcltf", ProductController, :delete_pcltf
    get "/products/:product_coverage_id/check_pclt", ProductController, :check_pclt
    get "/products/:product_coverage_id/get_pcf", ProductController, :get_pcf
    get "/products/:product_coverage_id/get_pcf_by_search", ProductController, :get_pcf_by_search
    get "/products/:product_coverage_id/get_pcf_by_region", ProductController, :get_pcf_by_region
    get "/products/:id/get_product_struct", ProductController, :get_product_struct

    get "/products/:id", ProductController, :show
    get "/products/:id/edit", ProductController, :edit_setup
    post "/products/:id/edit", ProductController, :save
    put "/products/:id/edit", ProductController, :save
    get "/products/:id/product_benefit/:product_benefit_id/edit", ProductController, :edit_setup
    get "/products/:id/summary", ProductController, :show_summary
    get "/get_all_product", ProductController, :get_all_product
    get "/products/:id/print_summary", ProductController, :print_summary
    get "/products/:id/save_product", ProductController, :save_product

    delete "/products/:id/delete_all", ProductController, :delete_product_all

    get "/products/:id/next_btn/:nxt_step", ProductController, :next_btn
    post "/products/:product_id/save_pcltf", ProductController, :step5_update_lt

    get "/products/:id/benefit_load_datatable", ProductController, :benefit_load_datatable

    ### for copy product
    post "/products/:product_id/copy", ProductController, :copy_product

    post "/products/:product_id/edit_pec_limit", ProductController, :edit_pec_limit
    post "/products/:product_id/edit_pec_limit_edit", ProductController, :edit_pec_limit_edit

    get "/products/:id/revert_step/:step", ProductController, :reverting_back_step
    get "/products/index/data_v2", ProductController, :load_all_products

    # Benefits
    get "/benefits/index/data", BenefitController, :load_all_benefits
    get "/benefits/load_datatable", BenefitController, :index_load_datatable
    get "/benefits", BenefitController, :index
    get "/benefits/new", BenefitController, :new
    post "/benefits/new", BenefitController, :create_basic
    get "/benefits/:id/setup", BenefitController, :setup
    put "/benefits/:id/setup", BenefitController, :update_setup
    post "/benefits/:id/setup", BenefitController, :update_setup
    delete "/benefits/:id/setup", BenefitController, :update_setup
    get "/benefits/:id", BenefitController, :show
    delete "/delete_benefit_limit/:id", BenefitController, :delete_benefit_limit
    get "/benefits/:id/edit", BenefitController, :edit_setup
    post "/benefits/:id/edit", BenefitController, :save
    put "/benefits/:id/edit", BenefitController, :save
    get "/benefits/:id/summary", BenefitController, :show_summary
    delete "/benefits/:id/procedure/:procedure_id", BenefitController, :delete_benefit_procedure
    get "/get_all_benefit_code", BenefitController, :get_all_benefit_code
    get "/get_benefit/code/:code", BenefitController, :get_benefit_code
    delete "/benefits/:id", BenefitController, :delete_benefit
    delete "/benefit_procedure/:id", BenefitController, :delete_benefit_procedure
    delete "/benefit_disease/:id", BenefitController, :delete_benefit_disease
    delete "/benefit_ruv/:id", BenefitController, :delete_benefit_ruv
    delete "/benefit_package/:id", BenefitController, :delete_benefit_package
    delete "/benefit_pharmacy/:id", BenefitController, :delete_benefit_pharmacy
    delete "/benefit_miscellaneous/:id", BenefitController, :delete_benefit_miscellaneous
    get "/benefits/:id/submit", BenefitController, :submit
    get "/benefits/index/download", BenefitController, :download_benefits
    #post "/benefits/:id/discontinue_benefit", BenefitController, :discontinue_benefit
    get "/benefits/:id/:message/logs", BenefitController, :show_benefit_log
    get "/benefits/:id/logs", BenefitController, :show_all_benefit_log
    get "/benefits/:id/:step/redirect_delete", BenefitController, :redirect_delete
    get "/benefits/:id/:step/edit/redirect_delete", BenefitController, :edit_redirect_delete
    get "/benefits/index/data_v2", BenefitController, :load_all_benefits

    put "/discontinue_benefit", BenefitController, :discontinue_benefit
    post "/discontinue_benefit", BenefitController, :discontinue_benefit
    put "/disable_benefit", BenefitController, :disabling_benefit
    post "/disable_benefit", BenefitController, :disabling_benefit
    post "/delete_peme_benefit", BenefitController, :delete_peme_benefit
    put "/discontinue_peme_benefit", BenefitController, :discontinue_peme_benefit
    post "/discontinue_peme_benefit", BenefitController, :discontinue_peme_benefit
    #DataTables
    get "/benefits/modal_procedure/data", BenefitController, :modal_procedure_index

    # Diagnoses
    get "/diseases", DiagnosisController, :index
    get "/diseases/:id/edit", DiagnosisController, :edit
    put "/diseases/:id/edit", DiagnosisController, :update
    get "/diseases/:id/logs", DiagnosisController, :logs
    get "/diseases/new/export/", DiagnosisController, :csv_export
    get "/diseases/new/export_excel/", DiagnosisController, :csv_export_excel
    get "/diseases/load_datatable", DiagnosisController, :index_load_datatable

    # Exclusions
    get "/exclusions", ExclusionController, :index
    get "/exclusions/new", ExclusionController, :new
    post "/exclusions/new", ExclusionController, :create_basic
    get "/exclusions/:id/setup", ExclusionController, :setup
    put "/exclusions/:id/setup", ExclusionController, :update_setup
    post "/exclusions/:id/setup", ExclusionController, :update_setup
    delete "/exclusions/:id/setup", ExclusionController, :update_setup
    get "/exclusions/:id", ExclusionController, :show
    get "/exclusions/:id/edit", ExclusionController, :edit_setup
    post "/exclusions/:id/edit", ExclusionController, :save
    put "/exclusions/:id/edit", ExclusionController, :save
    delete "/exclusions/:id/procedure/:procedure_id", ExclusionController, :delete_exclusion_procedure
    delete "/exclusions/:id/disease/:disease_id", ExclusionController, :delete_exclusion_disease
    delete "/exclusions/:id/duration_dreaded/:duration_id", ExclusionController, :delete_exclusion_duration_dreaded
    delete "/exclusions/:id/duration_non_dreaded/:duration_id", ExclusionController, :delete_exclusion_duration_non_dreaded
    get "/get_all_exclusion_code", ExclusionController, :get_all_exclusion_code
    get "/exclusions/:id/duration", ExclusionController, :create_duration
    post "/exclusions/:id/duration", ExclusionController, :create_duration
    delete "/exclusions/:id/procedure/:procedure_id", ExclusionController, :delete_exclusion_procedure
    delete "/exclusions/:id/disease/:disease_id", ExclusionController, :delete_exclusion_disease
    delete "/exclusions/:id/duration/:duration_id", ExclusionController, :delete_exclusion_duration
    delete "/exclusions/:id", ExclusionController, :delete_exclusion
    delete "/exclusions/:id/edit_duration_dreaded/:duration_id", ExclusionController, :delete_edit_exclusion_duration_dreaded
    delete "/exclusions/:id/edit_duration_non_dreaded/:duration_id", ExclusionController, :delete_edit_exclusion_duration_non_dreaded
    get "/exclusions/:id/submit", ExclusionController, :submit
    get "/exclusions/batch_upload/files", ExclusionController, :render_batch_upload
    get "/exclusions/download/template", ExclusionController, :download_template
    post "/exclusions/batch_upload/files", ExclusionController, :submit_batch_upload

    put "/exclusions/general/procedure/:payor_procedure_id", ExclusionController, :cpt_delete_tag
    put "/exclusions/general/disease/:disease_id", ExclusionController, :icd_delete_tag

    # Procedures
    get "/procedures", ProcedureController, :index
    post "/procedures", ProcedureController, :deactivate_cpt
    get "/procedures/new", ProcedureController, :new
    get "/procedures/:id/edit/:payor_procedure_id", ProcedureController, :edit
    post "/procedures/new", ProcedureController, :create_cpt
    put "/procedures/:id/update", ProcedureController, :update_cpt
    get "/procedures/:id/payor_procedure", ProcedureController, :get_payor_procedure
    get "/procedures/:id/procedure", ProcedureController, :get_procedure
    get "/procedures/:id/deactivated", ProcedureController, :get_deactivated_cpt
    get "/procedures/index/download", ProcedureController, :download_procedures
    get "/procedures/import", ProcedureController, :new_import
    post "/procedures/import/cpt", ProcedureController, :import
    get "/procedures/download/template", ProcedureController, :download_template
    get "/procedures/download/success/uploaded", ProcedureController, :download_uploaded_procedure_log
    get "/procedures/uploaded/file", ProcedureController, :new_upload_file
    get "/procedures/search/file", ProcedureController, :get_file_by_filename
    get "/procedures/load_datatable", ProcedureController, :index_load_datatable

    # Practitioners
    get "/practitioners/:id/setup", PractitionerController, :setup
    put "/practitioners/:id/setup", PractitionerController, :update_setup
    post "/practitioners/:id/setup", PractitionerController, :update_setup
    get "/practitioners", PractitionerController, :index
    get "/practitioners/new", PractitionerController, :new
    post "/practitioners/new", PractitionerController, :create
    get "/practitioners/:id", PractitionerController, :show
    delete "/practitioners/:id", PractitionerController, :delete
    delete "/practitioners/:id/delete_contact", PractitionerController, :delete_contact
    delete "/practitioners/:id/delete_edit_contact", PractitionerController, :delete_edit_contact
    put "/practitioners/:id/new_contact", PractitionerController, :create_contact
    put "/practitioners/:id/new_edit_contact", PractitionerController, :create_edit_contact
    put "/practitioners/:id/new_financial", PractitionerController, :create_financial
    post "/practitioners/:id/new_financial", PractitionerController, :create_financial
    get "/practitioners/:id/summary", PractitionerController, :create_summary
    get "/practitioners/:id/edit", PractitionerController, :edit_setup
    post "/practitioners/:id/edit", PractitionerController, :update_edit_setup
    put "/practitioners/:id/edit", PractitionerController, :update_edit_setup
    get "/practitioners/:id/next_contact", PractitionerController, :next_contact
    get "/practitioners/:id/print_summary", PractitionerController, :print_summary
    get "/practitioners/:s_id/load_specializations", PractitionerController, :load_specializations
    get "/practitioners/:id/get_specializations_by_practitioner", PractitionerController, :get_specializations_by_practitioner
    get "/practitioners/:id/get_practitioners_by_specialization", PractitionerController, :get_practitioners_by_specialization

    # Practitioner Facility
    get "/practitioners/:id/pf/new", PractitionerController, :new_pf
    post "/practitioners/:id/pf/new", PractitionerController, :create_pf
    get "/practitioners/:id/pf/create", PractitionerController, :create_pf_setup
    post "/practitioners/:id/pf/create", PractitionerController, :update_pf_setup
    put "/practitioners/:id/pf/create", PractitionerController, :update_pf_setup
    get "/practitioners/:id/pf/summary", PractitionerController, :pf_summary
    get "/practitioners/:id/pf/submitted", PractitionerController, :pf_submitted
    get "/practitioners/:id/pf/delete", PractitionerController, :pf_delete
    get "/practitioners/:id/pf/print_summary", PractitionerController, :print_pf_summary
    get "/practitioners/:id/pf/edit", PractitionerController, :edit_pf_setup
    post "/practitioners/:id/pf/edit", PractitionerController, :update_edit_pf_setup
    put "/practitioners/:id/pf/edit", PractitionerController, :update_edit_pf_setup
    post "/practitioners/:id/pf/new_schedule", PractitionerController, :create_pf_schedule
    put "/practitioners/:id/pf/new_schedule", PractitionerController, :create_pf_schedule
    put "/practitioners/:id/pf/edit_schedule", PractitionerController, :update_pf_schedule
    delete "/practitioners/:id/pf/delete_pf_schedule", PractitionerController, :delete_pf_schedule
    get "/practitioners/:id/pf/next_schedule", PractitionerController, :next_pf_schedule
    post "/practitioners/:id/pf/edit_new_schedule", PractitionerController, :edit_create_pf_schedule
    put "/practitioners/:id/pf/edit_new_schedule", PractitionerController, :edit_create_pf_schedule
    put "/practitioners/:id/pf/edit_edit_schedule", PractitionerController, :edit_update_pf_schedule
    delete "/practitioners/:id/pf/edit_delete_pf_schedule", PractitionerController, :edit_delete_pf_schedule

    # Practitioner Account
    get "/practitioners/:id/pa/new", PractitionerController, :new_pa
    post "/practitioners/:id/pa/new", PractitionerController, :create_pa
    get "/practitioners/:id/pa/create", PractitionerController, :create_pa_setup
    post "/practitioners/:id/pa/create", PractitionerController, :update_pa_setup
    put "/practitioners/:id/pa/create", PractitionerController, :update_pa_setup
    get "/practitioners/:id/pa/edit", PractitionerController, :edit_pa_setup
    post "/practitioners/:id/pa/edit", PractitionerController, :update_edit_pa_setup
    put "/practitioners/:id/pa/edit", PractitionerController, :update_edit_pa_setup
    delete "/practitioners/:id/pa/delete_pa_schedule", PractitionerController, :delete_pa_schedule
    delete "/practitioners/:id/pa/delete_edit_pa_schedule", PractitionerController, :delete_edit_pa_schedule
    put "/practitioners/:id/pa/new_schedule", PractitionerController, :update_pa_schedule
    put "/practitioners/:id/pa/edit_schedule", PractitionerController, :update_edit_pa_schedule_modal
    delete "/practitioners/:id/pa/delete_pa", PractitionerController, :delete_practitioner_account
    get "/practitioners/:id/pa/summary", PractitionerController, :pa_summary

    # Members
    get "/members", MemberController, :index
    get "/members/new", MemberController, :new
    get "/members/:id", MemberController, :show
    get "/members/reports/generate", MemberController, :reports_index
    post "/members/reports/generate", MemberController, :generate_reports

    post "/members/:id/add_product", MemberController, :add_member_product
    post "/members/:id/save_product_tier", MemberController, :save_member_prduct_tier
    post "/members/new", MemberController, :create_general
    get "/members/:id/setup", MemberController, :setup
    put "/members/:id/setup", MemberController, :update_setup
    post "/members/:id/setup", MemberController, :update_setup
    delete "/members/:member_id/member_product/:id", MemberController, :delete_member_product
    get "/members/enrollment/import", MemberController, :new_import
    post "/members/enrollment/import", MemberController, :import_member
    get "/member_enrollment/download/corporate_template", MemberController, :download_corporate_template
    get "/member_enrollment/download/ifg_template", MemberController, :download_ifg_template
    get "/member_enrollment/download/change_of_product", MemberController, :download_cop
    post "/members/suspend", MemberController, :member_suspend
    post "/members/cancel", MemberController, :member_cancel
    post "/members/reactivate", MemberController, :member_reactivate
    get "/members/skipping/hierarchy", MemberController, :skipping_hierarchy
    get "/members/pwd_id/all", MemberController, :get_pwd_id
    get "/members/senior_id/all", MemberController, :get_senior_id
    get "/members/:id/edit", MemberController, :edit_setup
    post "/members/:id/edit", MemberController, :save
    put "/members/:id/edit", MemberController, :save

    post "/members/:id/add_comment", MemberController, :create_member_comment
    get "/members/load/datatable", MemberController, :index_load_datatable

    ### members documents ajax
    get "/members/:member_id/document/data", MemberController, :member_documents

    #Facilities
    resources "/facilities", FacilityController, only: [:index, :new, :show]
    post "/facilities/new", FacilityController, :create_step1
    get "/facilities/:id/setup", FacilityController, :setup
    put "/facilities/:id/setup", FacilityController, :update_setup
    post "/facilities/:id/setup", FacilityController, :update_setup
    post "/facilities/:id/new_contact", FacilityController, :create_contact
    put "/facilities/:id/new_contact", FacilityController, :create_contact
    get "/facilities/:id/next_contact", FacilityController, :next_contact
    get "/facilities/:id/summary", FacilityController, :submit_summary
    get "/facilities/:id/get_contact", FacilityController, :get_contact
    put "/facilities/:id/edit_contact", FacilityController, :update_contact
    delete "/facilities/:id/delete_contact", FacilityController, :delete_facility_contact
    get "/facilities/:id/edit", FacilityController, :edit_setup
    post "/facilities/:id/edit", FacilityController, :update_edit_setup
    put "/facilities/:id/edit", FacilityController, :update_edit_setup
    post "/facilities/:id/for_edit_new_contact", FacilityController, :for_edit_create_contact
    put "/facilities/:id/for_edit_new_contact", FacilityController, :for_edit_create_contact
    put "/facilities/:id/for_edit_udpate_contact", FacilityController, :for_edit_update_contact
    delete "/facilities/:id/for_edit_delete_facility_contact", FacilityController, :for_edit_delete_facility_contact
    get "/facilities/:id/get_facility", FacilityController, :get_facility_by_member_id
    get "/facilities/:id/print_summary", FacilityController, :print_summary
    get "/facilities/:id/delete", FacilityController, :delete_facility
    get "/facilities/:region_name/get_lg_by_region", FacilityController, :get_location_group_by_region

    # Facility Datatable
    get "/facilities/index/data", FacilityController, :facility_index

    #Add procedure in facility
    get "/facilities/:id/add_procedure", FacilityController, :render_facility_payor_procedure
    get "/facilities/:id/facilities_procedure/:facility_procedure_id/edit_procedure", FacilityController, :render_edit_facility_payor_procedure
    get "/facilities/:id/remove_procedure/:fpp_id", FacilityController, :remove_facility_procedure

    #Add room_rate in Facility
    post "/facilities/:id/facility_room_rate/update", FacilityRoomRateController, :update_room_rate
    post "/facilities/:id/facility_room_rate/create_room_rate", FacilityRoomRateController, :create_room_rate
    get "/facilities/:id/get_rooms", FacilityRoomRateController, :get_room
    get "/facilities/:id/get_all_room_rate", FacilityRoomRateController, :get_all_room_rate

    #get "/facilities/:id/:code/", FacilityRoomRateController, :get_rooms_using_code
    get "/facilities/room_rate/:id/:code/", FacilityRoomRateController, :get_rooms_using_code
    get "/facilities/:id/facility_room_rate/:room_rate_id/delete", FacilityRoomRateController, :delete_room_rate

    #Add RUV in Facility
    post "/facilities/:id/facility_ruv/update", FacilityRontroller, :update_ruv
    post "/facilities/:id/facility_ruv/create_ruv", FacilityController, :create_ruv
    get "/facilities/:id/get_ruvs", FacilityController, :get_ruv
    get "/facilities/:id/get_all_ruv", FacilityController, :get_all_ruv

    # get "/facilities/:id/:code/", FacilityController, :get_ruvs_using_code
    get "/facilities/:id/facility_ruv/:ruv_id/delete", FacilityController, :delete_ruv

    # FacilityProcedure
    get "/get_facility_payor_procedure/:id", FacilityController, :get_facility_payor_procedure #API
    get "/get_all_fpp_id_and_code/:id", FacilityController, :ajax_fpprocedure_checker #API
    post "/facilities/:id/new_procedure", FacilityController, :create_facility_payor_procedure
    put "/facilities/:id/update_procedure", FacilityController, :update_facility_payor_procedure
    get "/facilities/payor_procedure/:id/import", FacilityController, :new_import
    get "/facilities/ruv/:id/import", FacilityController, :ruv_import
    post "/facilities/:id/import", FacilityController, :import_facility_payor_procedure
    get "/payor_procedure/download/template", FacilityController, :download_template
    get "/ruv/download/template", FacilityController, :ruv_download_template
    post "/facilities/ruv/:id/ruv_import", FacilityController, :import_facility_ruv

    #FacilityImport
    get "/facilities/new/import/file", FacilityController, :new_facility_upload_file
    post "/facilities/new/import/file", FacilityController, :facility_import
    get "/facilities/new/download/general_template", FacilityController, :download_facility_template
    get "/facilities/new/download/contacts_template", FacilityController, :download_facility_contacts_template
    get "/facilities/download/success/uploaded", FacilityController, :download_uploaded_facility_log

    #Authorization
    resources "/authorizations", AuthorizationController, only: [:index, :new]
    get "/authorizations/:id", AuthorizationController, :show
    get "/authorizations/:id/setup", AuthorizationController, :setup
    post "/authorizations/:id/setup", AuthorizationController, :update_setup
    post "/authorizations/:id/setup", AuthorizationController, :setup
    put "/authorizations/:id/setup", AuthorizationController, :update_setup
    post "/authorizations/:id/setup", AuthorizationController, :setup
    post "/authorizations/validate_info", AuthorizationController, :validate_member_info
    post "/authorizations/validate_card", AuthorizationController, :validate_card
    post "/authorizations/:id/cancel_loa", AuthorizationController, :cancel_loa
    get "/authorizations/:id/logs", AuthorizationController, :get_logs
    #OP Consult
    post "/authorizations/:id/get_pec", AuthorizationController, :get_pec
    post "/authorizations/:id/get_consultation_fee", AuthorizationController, :get_consultation_fee
    post "/authorizations/:id/compute_consultation", AuthorizationController, :compute_consultation
    post "/authorizations/select_member", AuthorizationController, :select_member
    get "/authorizations/:id/delete_authorization", AuthorizationController, :delete_authorization
    get "/authorizations/:id/approve_authorization", AuthorizationController, :approve_authorization
    get "/authorizations/:id/disapprove_authorization/:reason", AuthorizationController, :disapprove_authorization
    #OP LAB
    get "/authorizations/:id/delete_authorization_procedure", AuthorizationController, :delete_authorization_procedure
    get "/authorizations/:id/delete_authorization_ruv", AuthorizationController, :delete_authorization_ruv
    post "/authorizations/compute_fees", AuthorizationController, :compute_fees
    post "/authorizations/:id/create_authorization_ruv", AuthorizationController, :create_authorization_ruv
    #Emergency
    put "/authorizations/:id/create_practitioner_specialization", AuthorizationController, :create_practitioner_specialization
    get "/authorizations/:id/delete_practitioner_specialization/:aps_id", AuthorizationController, :delete_practitioner_specialization
    put "/authorizations/:id/create_disease_procedure", AuthorizationController, :create_disease_procedure
    get "/authorizations/:id/delete_emergency_authorization_procedure", AuthorizationController, :delete_emergency_authorization_procedure
    get "/authorizations/:id/save_authorization_data_emergency", AuthorizationController, :save_authorization_data_emergency
    put "/authorizations/:id/update_disease_procedure", AuthorizationController, :update_disease_procedure
    #ACU
    post "/authorizations/:id/get_facility_room", AuthorizationController, :get_facility_room
    post "/authorizations/:id/compute_acu", AuthorizationController, :compute_acu
    get "/authorizations/:facility_id/filter_specialization/:val", AuthorizationController, :filter_practitioner_specialization
    get "/authorizations/:facility_id/filter_all_specialization", AuthorizationController, :filter_all_practitioner_specialization
    #INPATIENT
    put "/authorizations/:id/create_inpatient_room_and_board", AuthorizationController, :create_inpatient_room_and_board
    get "/authorizations/get_facility_room_rate/:room_number", AuthorizationController, :get_facility_room_rate_by_room_number
    get "/authorizations/get_authorization_room/:arb_id", AuthorizationController, :get_authorization_room_and_board_modal

    get "/authorizations/:id/send_otp", AuthorizationController, :send_otp
    get "/authorizations/:id/:otp/:copy/validate_otp", AuthorizationController, :validate_otp
    get "/authorizations/:id/auth_verified", AuthorizationController, :auth_verified
    get "/authorizations/:id/:cvv/validate_cvv", AuthorizationController, :validate_cvv
    get "/authorizations/:id/save_draft", AuthorizationController, :save_draft
    get "/authorizations/:id/save_authorization_data", AuthorizationController, :save_authorization_data
    post "/authorizations/:id/upload_file", AuthorizationController, :upload_file
    delete "/authorizations/:id/delete_file", AuthorizationController, :delete_file
    get "/authorizations/:id/reschedule", AuthorizationController, :reschedule_loa

    get "/authorizations/:coverage/:id/edit", AuthorizationController, :edit_authorization_setup
    put "/authorizations/:id/save", AuthorizationController, :edit_save
    get "/authorizations/:id/edit_status_checker", AuthorizationController, :check_edit_status
    get "/authorizations/:id/cancel_edit_opc", AuthorizationController, :cancel_edit_opc

    get "/authorizations/index/data", AuthorizationController, :authorization_index

    get "/authorizations/:id/:copy/print_authorization", AuthorizationController, :print_authorization
    get "/authorizations/:id/print_authorization", AuthorizationController, :print_authorization

    #Package
    resources "/packages", PackageController
    get "/packages/:id/setup", PackageController, :setup
    put "/packages/:id/setup", PackageController, :update_setup
    post "/packages/:id/setup", PackageController, :update_setup
    post "/packages/:id/new_account", PackageController, :create_account
    get "/packages/:id/next_step3", PackageController, :next_step3
    get "/packages/:id", PackageController, :show
    get "/packages/:id/delete_package_payor_procedure", PackageController, :delete_package_payor_procedure
    delete "/packages/:id/delete_package_payor_procedure_edit", PackageController, :delete_package_payor_procedure_edit
    delete "/packages/:id/delete_package_facility_edit", PackageController, :delete_package_facility_edit
    get "/packages/:id/delete_package_facility", PackageController, :delete_package_facility
    get "/packages/:id/edit", PackageController, :edit_setup
    post "/packages/:id/edit", PackageController, :update_edit_setup
    put "/packages/:id/edit", PackageController, :update_edit_setup
    put "/packages/:id/update_package_facilities", PackageController, :update_package_facilities
    post "/packages/:id/update_package_facilities", PackageController, :update_package_facilities
    post "/packages/:id", PackageController, :create_facility_setup
    put "/packages/:id", PackageController, :create_facility_setup
    get "/packages/:id/:message/logs", PackageController, :show_log
    get "/packages/:id/logs", PackageController, :show_all_log
    get "/packages/:id/delete", PackageController, :delete
    get "/packages/:id/submit", PackageController, :submit
    get "/packages/:id/summary", PackageController, :show_summary

    #Companies
    get "/companies/new", CompanyController, :new
    get "/companies", CompanyController, :index
    post "/companies/new", CompanyController, :create
    get "/companies/:id", CompanyController, :show
    get "/get_company_by_code/:code", CompanyController, :get_company_by_code

    #Case Rate
    resources "/case_rates", CaseRateController, except: [:show]
    get "/case_rates/:id/update", CaseRateController, :edit
    post "/case_rates/:id/", CaseRateController, :update
    get "/case_rates/:id/logs", CaseRateController, :show_logs
    get "/case_rates/:id/:message/logs", CaseRateController, :search_logs
    get "/case_rates/:id/delete_case_rate", CaseRateController, :delete

    # RUV
    resources "/ruvs", RUVController, only: [:index, :new, :create, :edit, :update]
    get "/ruvs/:id/logs", RUVController, :logs
    get "/ruvs/:id/delete", RUVController, :delete
    get "/ruvs/:id/get", RUVController, :get_ruv_ajax

    # Location Group
    resources "/location_groups", LocationGroupController, only: [:index]
    get "/location_groups/:id/setup", LocationGroupController, :setup
    put "/location_groups/:id/setup", LocationGroupController, :update_setup
    post "/location_groups/:id/setup", LocationGroupController, :update_setup
    get "/location_groups/new", LocationGroupController, :new
    post "/location_groups/new", LocationGroupController, :create_general
    put "/location_groups/:id/submit", LocationGroupController, :submit_location_group
    get "/location_groups/:id/summary", LocationGroupController, :show_summary
    delete "/location_groups/:id", LocationGroupController, :delete_lg
    get "/location_groups/:id/show", LocationGroupController, :show
    get "/get_all_location_group_name", LocationGroupController, :get_all_location_group_name

    #Pharmacy
    # resources "/pharmacies", PharmacyController, only: [:index, :new, :create, :edit, :update]
    get "/pharmacies", PharmacyController, :index
    get "/pharmacies/new", PharmacyController, :new
    get "/get_all_pharmacy_code", PharmacyController, :get_all_pharmacy_code
    post "/pharmacies/new", PharmacyController, :create
    get "/pharmacies/:id/edit", PharmacyController, :edit
    put "/pharmacies/:id/edit", PharmacyController, :update
    delete "/pharmacies/:id", PharmacyController, :delete_pharmacy

    # Miscellaneous
    resources "/miscellaneous", MiscellaneousController, only: [:index]
    get "/miscellaneous/new", MiscellaneousController, :new
    post "/miscellaneous/new", MiscellaneousController, :create_general
    get "/miscellaneous/:id/show", MiscellaneousController, :show
    get "/get_all_miscellaneous_code", MiscellaneousController, :get_all_miscellaneous_code
    get "/miscellaneous/:id/edit", MiscellaneousController, :edit
    put "/miscellaneous/:id/edit", MiscellaneousController, :save_edit
    delete "/miscellaneous/:id", MiscellaneousController, :delete_miscellaneous

    #ACU Schedule
    get "/acu_schedules/export/:acu_data", AcuScheduleController, :acu_schedule_export
    get "/acu_schedules", AcuScheduleController, :index
    get "/acu_schedules/new", AcuScheduleController, :new
    get "/acu_schedules/:id/edit", AcuScheduleController, :edit
    #get "/get_all_acu_mobile", AcuMobileController, :get_all_acu_mobile
    get "/acu_schedules/:id", AcuScheduleController, :show
    post "/acu_schedules/new", AcuScheduleController, :create_acu_schedule
    put "/acu_schedules/:id/edit", AcuScheduleController, :update_acu_schedule
    #delete "/acu_mobiles/:id", AcuMobileController, :delete_mobile
    get "/acu_schedules/get_acu_products/:account_code", AcuScheduleController, :get_acu_product
    get "/acu_schedules/get_acu_products/edit/:account_code/:acu_schedule_id", AcuScheduleController, :get_edit_acu_schedule_product
    get "/acu_schedules/get_members/:account_code/:product_code", AcuScheduleController, :number_of_members
    get "/acu_schedule_export", AcuScheduleController, :acu_schedule_download
    get "/acu_schedules/get_active/members", AcuScheduleController, :number_of_members
    get "/acu_schedules/get_acu/facilities", AcuScheduleController, :get_acu_facilities
    get "/acu_schedules/delete/xlsx", AcuScheduleController, :delete_xlsx
    get "/acu_schedules/get_account_date/:account_code", AcuScheduleController, :get_account_date
    get "/acu_schedules/:id/packages", AcuScheduleController, :render_acu_schedule_packages
    post "/acu_schedules/:id/submit_acu_schedule_member", AcuScheduleController, :submit_acu_schedule_member
    post "/acu_schedules/:id/update_package_rate/:rate", AcuScheduleController, :update_acu_package_rate
    post "/acu_schedules/:id/request_loa", AcuScheduleController, :create_acu_schedule_loa
    put "/acu_schedules/update_status/remove", AcuScheduleController, :update_asm_status
    put "/acu_schedules/update_status/multiple", AcuScheduleController, :update_multiple_asm_status
    get "/acu_schedules/:id/delete_acu_schedule", AcuScheduleController, :delete_acu_schedule
    put "/acu_schedules/delete_acu_schedule_members", AcuScheduleController, :delete_acu_schedule_members
    get "/acu_schedules/load/datatable", AcuScheduleController, :asm_member_load_datatable
    get "/acu_schedules/load/datatable/grid", AcuScheduleController, :asm_member_load_datatable_grid

    #Datatable
    get "/acu_schedules/:id/datatable/load/members", AcuScheduleController, :load_members_tbl
    get "/acu_schedules/:id/datatable/load/members/show", AcuScheduleController, :load_members_tbl_show
    get "/acu_schedules/:id/datatable/load/removed_members", AcuScheduleController, :load_remove_members_tbl

    #Migration
    get "/migration/:id/results", MigrationController, :results
    get "/migration/:id/result/:count", MigrationController, :result
    get "/migration/:id/json/result", MigrationController, :result_v2
    get "/generate/claims_file", MemberController, :generate_claims_job
    get "/migration/index/download", MigrationController, :download_migration

  end

  scope "/", Innerpeace.PayorLink.Web do
    pipe_through [:browser, :auth_layout] # Use the default browser stack

    get "/sign_in", SessionController, :new
    post "/sign_in", SessionController, :create
  end

  # Other scopes may use custom stacks.
  scope "/api", Innerpeace.PayorLink.Web.Api, as: :api do
    pipe_through [:api]

    # Users
    get "/v1/user_access_activations/:id/:status/csv_download", UserAccessActivationController, :csv_log_download

    get "/v1/products/download", ProductController, :download_product

    get "/v1/diagnosis/download", DiagnosisController, :download_diagnosis

    get "/v1/facilities/:id/fpp_download", FacilityController, :download_fpp

    get "/v1/facilities/:log_id/:status/fpp_batch_download", FacilityController, :fpp_batch_download

    get "/v1/practitioners/download", PractitionerController, :download_practitioner

    get "/v1/facilities/:id/fr_download", FacilityController, :download_fr

    get "/v1/facilities/:log_id/:status/fr_batch_download", FacilityController, :fr_batch_download

    get "/products/dental/exclusion_facilities", ProductController, :exclusion_facility_datatable

    #Account
    get "/v1/accounts/:id/get_an_account", AccountController, :get_an_account
    post "/v1/accounts/:id/new_comment", AccountController, :create_account_comment
    get "/v1/accounts/:code/get_an_account_by_code", V1.AccountController, :get_an_account_by_code

    #Package
    get "/v1/packages/get_all_package_code_and_name", PackageController, :get_all_package_code_and_name
    get "/v1/packages/:id/:name", PackageController, :get_facility_by_name

    #Member
    get "/v1/members/:account_group_code", MemberController, :get_members_by_account_group
    get "/v1/members/reports/csv_download", V1.MemberController, :csv_get_account_members_csv_download

    get "/v1/members/details/:id", MemberController, :get_member_details
    get "/v1/members/:log_id/:status/member_batch_download", MemberController, :member_batch_download
    get "/v1/members/skipping_hierarchy/:user_id/approve_skipping", MemberController, :approve_skipping_hierarchy
    get "/v1/members/skipping_hierarchy/:user_id/disapprove_skipping/:reason", MemberController, :disapprove_skipping_hierarchy
    get "/v1/members/index/skipping/:type", MemberController, :download_skipping
    get "/v1/members/:log_id/:status/:type/member_batch_download", MemberController, :member_batch_download

    #Exclusion
    get "/v1/exclusions/:log_id/:status/cpt_batch_download", ExclusionController, :cpt_batch_download
    get "/v1/exclusions/:log_id/:status/icd_batch_download", ExclusionController, :icd_batch_download

    #AcuSchedule
    get "/v1/acu_schedule_export", AcuScheduleController, :acu_schedule_download
    get "/v1/acu_schedules/delete/xlsx", AcuScheduleController, :delete_xlsx
    get "/v1/acu_schedules/:id/export", AcuScheduleController, :acu_schedule_export

    #Authorization
    get "/v1/authorizations/:id/get_amount/:facility_id/:unit", AuthorizationController, :get_amount_by_payor_procedure_id
    get "/v1/authorizations/:id/get_emergency_amount/:facility_id/:unit", AuthorizationController, :get_emergency_amount_by_payor_procedure_id
    get "/v1/authorizations/:id/get_emergency_solo_amount/:facility_id",
    AuthorizationController, :get_emergency_solo_amount_by_payor_procedurename

    scope "/v1", V1 do
      pipe_through :auth_api

      post "/sign_in", SessionController, :login
      # Status
      get "/status", StatusController, :index

      pipe_through :token_required
      # Token required end points

      get "/sign_out", SessionController, :logout

      #Email
      post "/email/worker_error/logs", EmailController, :send_error_logs
      post "/email/migration/details", EmailController, :send_migration_details

      # Product
      get "/products/load_products", ProductController, :load_products
      post "/products", ProductController, :create_product_api
      post "/member/movement/change_product", ProductController, :change_member_product

      # Account
      # post "/accounts", AccountController, :create_account_api
      post "/accounts", Migration.MigrationController, :account_single_migration
      post "/accounts/existing", AccountController, :create_account_api_existing
      get "/accounts/get_all_accounts", AccountController, :index
      post "/accounts/renew", AccountController, :renew_account
      get "/accounts/latest", AccountController, :get_account_latest
      put "/accounts/replicated", AccountController, :set_account_replicated
      post "/accounts/movement/add_product", AccountController, :add_product

      #Diagnosis
      get "/diagnoses/", DiagnosisController, :index
      post "/diagnoses/new", DiagnosisController, :create_diagnosis_api
      get "/:id/get_diagnosis/", DiagnosisController, :get_diagnosis
      get "/diagnoses/name", DiagnosisController, :get_diagnosis_by_name

      #Procedures
      get "/procedures", ProcedureController, :load_procedures
      post "/procedures", ProcedureController, :create
      get "/:id/get_procedure/", ProcedureController, :get_procedure
      get "/:id/get_payor_procedure/", ProcedureController, :get_payor_procedure

      #Exclusions
      get "/exclusions", ExclusionController, :index
      post "/exclusion/custom", ExclusionController, :create_custom_exclusion_api
      post "/exclusion/general", ExclusionController, :create_general_exclusion_api
      post "/exclusion_procedure_datatable", ExclusionController, :exclusion_procedure_datatable

      #Loa
      get "/loa/validate/facility", MemberController, :validate_facility

      #Authorization
      get "/loa/generate/transaction_no", AuthorizationController, :generate_transaction_no
      post "/loa/validate/coverage", AuthorizationController, :validate_coverage
      post "/loa/request/op-consult", AuthorizationController, :request_op_consult
      post "/loa/insert/utilization", AuthorizationController, :insert_utilization
      post "/loa/request/acu", AuthorizationController, :request_acu
      post "/loa/request/op-lab", AuthorizationController, :request_loa_op_lab
      put "/loa/request/peme", AuthorizationController, :request_peme
      post "/loa/request/peme", AuthorizationController, :request_peme
      get "/loa/details/acu", AuthorizationController, :get_acu_details
      get "/loa/details/peme", AuthorizationController, :get_peme_details
      post "/loa/details/peme/get_all_details", AuthorizationController, :request_peme_v2
      get "/loa/cancel/:id", AuthorizationController, :cancel_authorization
      put "/loa/:authorization_id/update_loa_no", AuthorizationController, :update_loa_number
      put "/loa/:authorization_id/update_otp_status", AuthorizationController, :update_otp_status
      put "/loa/:authorization_id/update_peme_status", AuthorizationController, :update_peme_status
      put "/loa/:authorization_id/approve_loa_status", AuthorizationController, :approve_loa_status
      put "/loa/batch/acu_schedule/update_otp_status", AuthorizationController, :update_batch_otp_status
      put "/loa/batch/acu_schedule/update_otp_status_v2", AuthorizationController, :update_otp_status_v2
      put "/loa/batch/acu_schedule/create_batch", AuthorizationController, :create_batch_for_acu_schedule
      put "/loa/batch/clinic/create_batch", AuthorizationController, :create_batch_for_clinic
      get "/loa/reschedule", AuthorizationController, :reschedule_loa
      post "/loa/request/pos_terminal", AuthorizationController, :request_loe_pos_terminal
      post "/loa/verify/acu", AuthorizationController, :verify_acu
      post "/vendor/authorizations/pdf", AuthorizationController, :print_pdf
      get "/claims", AuthorizationController, :get_claims
      get "/claims2", AuthorizationController, :get_claims2

      #Members
      get "/member/validate/details", MemberController, :validate_details
      post "/member/validate/details", MemberController, :validate_details
      post "/member/validate/card", MemberController, :validate_card
      put "/member/:id/update_mobile_no", MemberController, :update_mobile_no
      get "/member/:id/get_all_mobile_no", MemberController, :get_all_mobile_no
      get "/member/principal/get_all_mobile_no", MemberController, :get_all_mobile_no
      post "/members", MemberController, :create
      post "/members/user", MemberController, :create_with_user
      get "/member", MemberController, :get_member
      get "/member/security", MemberController, :get_member_security
      post "/member/movement/cancellation", MemberController, :member_cancellation
      post "/member/movement/suspension", MemberController, :member_suspension
      post "/member/movement/retraction", MemberController, :retract_movement
      post "/member/movement/reactivation", MemberController, :reactivate
      post "/member/get_member_by_id", MemberController, :get_member_by_id
      post "/members/batch", MemberController, :batch_upload
      post "/members/batch/user", MemberController, :batch_upload_with_user
      post "/members/user/batch", MemberController, :create_batch_with_user
      post "/member/validate/evoucher", MemberController, :validate_evoucher
      post "/member/validate/cvv", MemberController, :validate_cvv
      post "/member/existing", MemberController, :create_existing_member
      get "/vendor/members/philhealth_status", MemberController, :get_member_status
      post "/vendor/members/remaining_limit", MemberController, :get_remaining_limits
      get "/member/:evoucher/get_member_peme_by_evoucher/:provider_code", MemberController, :get_member_peme_by_evoucher
      post "/member/update_peme_member", MemberController, :update_peme_member
      post "/members/movement/add_product", MemberController, :add_product
      post "/members/movement/remove_product", MemberController, :remove_product
      post "/members/batch/status_update", MemberController, :batch_active_members
      get "/members/replicate/member", MemberController, :replicate_member
      get "/members/add/attempt", MemberController, :block_member
      get "/members/remove/attempt", MemberController, :remove_member_attempts
      post "/members/document", MemberController, :member_document

      #Practitioners
      post "/practitioners", PractitionerController, :validate_affiliated_practitioner
      post "/practitioners/new", PractitionerController, :create_practitioner_api
      get "/practitioner_code", PractitionerController, :get_practitioner_by_vendor_code
      get "/practitioners/:id/specializations", PractitionerController, :get_practitioner_specializations
      get "/practitioners", PractitionerController, :index
      get "/practitioners/code", PractitionerController, :get_practitioner_by_code

      #Benefits
      post "/benefits", BenefitController, :create
      get "/benefits/get_all_benefits", BenefitController, :index

      #Facility
      post "/facilities", FacilityController, :create_facility_api
      get "/facility_code", FacilityController, :get_facility_by_vendor_code
      get "/facilities/get_by_code", FacilityController, :get_facility_by_code
      get "/facilities", FacilityController, :index
      post "/facility/get_facility_by_id", FacilityController, :get_facility_by_id

      #LocationGroups
      post "/location_groups", LocationGroupController, :create_lg

      #ACU Schedule
      post "/acu_schedules/create_schedule", AcuScheduleController, :create_schedule_api
      post "/acu_schedules/create_batch", AcuScheduleController, :acu_schedule_create_batch
      put "/acu_schedules/create_batch", AcuScheduleController, :update_batch_loa_status_and_create_claim
      put "/acu_schedule/acu_schedule_member/upload_image", AcuScheduleController, :acu_schedule_member_upload_image

      #Claim
      post "/claims/update_migrated", AuthorizationController, :update_migrated_claim

      ## vendors
      scope "/vendor", Vendor, as: :vendor do
        post "/practitioners/accredited/verification", PractitionerController, :get_accredited_verification
        post "/practitioners/affiliated/verification", PractitionerController, :get_affiliated_verification
        post "/practitioners", PractitionerController, :get_practitioner
        post "/facilities", FacilityController, :index
        get "/members/room_entitlement", MemberController, :get_member_product_rnb
        post "/members/validate/pre-availment", MemberController, :pre_availment
        get "/members/utilization", MemberController, :get_member_utilization
        post "/members/verification", MemberController, :verification
        post "/members/eligibility", MemberController, :validate_member_eligibility
        post "/diagnoses", DiagnosisController, :index
        post "/procedures", ProcedureController, :index
        post "/facilities/location", FacilityController, :search_facility_by_location
        post "/authorizations", AuthorizationController, :create_authorization

      end

      ## migration
      scope "/migration", Migration, as: :migration do
        post "/urg/migrate", MigrationController, :urg_migrate
        post "/urg/migrate/existing", MigrationController, :urg_existing_migrate
        post "/urg/migrate/v2/existing", MigrationController, :urg_existing_migrate_v2
        post "/benefits/batch", MigrationController, :benefit_migrate
        post "/products/batch", MigrationController, :product_migrate
        post "/accounts/batch", MigrationController, :account_migrate
      end

      ## SAP
      scope "/sap", Sap, as: :sap do
        post "/accounts", AccountController, :create_v2
        post "/benefits", BenefitController, :create
        post "/benefits/dental", BenefitController, :create_sap_dental
        post "/members", MemberController, :create
        post "/products", ProductController, :create
        post "/get_packages", PackageController, :get_packages_by_name_or_code
        post "/products/dental", ProductController, :create_dental
        post "/facility_groups", FacilityGroupController, :facility_group
        post "/products/get_dental", ProductController, :get_dental
        post "/accounts/renew", AccountController, :renew_account
        post "/accounts/get_account", AccountController, :get_account
        # post "/accounts/movement/cancel", AccountController, :cancel_account
        # ## temporary use only
        # post "/benefits/get_dental", BenefitController, :get_dental_temporary

        post "/benefits/get_dental", BenefitController, :get_dental
        post "/pre_existings", ExclusionController, :create_pre_existing
        post "/get_pre_existings", ExclusionController, :get_sap_pre_existing
        post "/get_benefits", BenefitController, :get_benefits
        post "/exclusions", ExclusionController, :create_exclusion
        post "/get_exclusions", ExclusionController, :get_exclusion

        scope "/batch", Batch, as: :batch do
          post "/accounts", AccountController, :create
          post "/benefits", BenefitController, :create
          post "/members", MemberController, :create
          post "/membersv2", MemberController, :create_batch
          post "/products", ProductController, :create
        end

        scope "/accounts/movement" do
          post "/cancel", AccountController, :cancel_account
          post "/reactivate", AccountController, :reactivate_account
          post "/suspend", AccountController, :suspend_account
          post "/extend", AccountController, :extend_account
        end
      end

    end
  end
end
