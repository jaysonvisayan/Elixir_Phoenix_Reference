defmodule MemberLinkWeb.Router do
  use MemberLinkWeb, :router

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
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug MemberLinkWeb.Plug.Locale, "en"
  end

  pipeline :auth_api do
    plug :accepts, ["json", "json-api"]
    plug MemberLink.Guardian.AuthPipeline.JSON
    plug :fetch_session
    plug :fetch_flash
  end

  pipeline :mg_api do
    plug :accepts, ["json", "json-api"]
    plug MemberLinkWeb.Plug.MigrationAuth, ""
    plug MemberLink.Guardian.AuthPipeline.JSON
    plug :fetch_session
    plug :fetch_flash
  end

  pipeline :token_required do
    plug Guardian.Plug.EnsureAuthenticated,
      handler: MemberLinkWeb.Api.V1.SessionController
  end

  pipeline :login_required do
    plug MemberLink.Guardian.AuthPipeline.Browser
    plug MemberLink.Guardian.AuthPipeline.Authenticate
    plug MemberLinkWeb.Auth.CurrentUser
    plug Auth.SlidingSessionTimeout, timeout_after_seconds: 600
  end

  pipeline :acct_layout do
    plug MemberLink.Guardian.AuthPipeline.Browser
    plug MemberLink.Guardian.AuthPipeline.Authenticate
    plug MemberLinkWeb.Auth.CurrentUser
    plug :put_layout, {MemberLinkWeb.LayoutView , :acct}
  end

  pipeline :auth_layout do
    plug :put_layout, {MemberLinkWeb.LayoutView , :auth}
  end

  pipeline :evoucher_layout do
    plug :put_layout, {MemberLinkWeb.LayoutView , :evoucher}
  end

  pipeline :reg_layout do
    plug :put_layout, {MemberLinkWeb.LayoutView, :reg}
  end

  pipeline :af_layout do
    # Affiliated Facilities Layout

    plug :put_layout, {MemberLinkWeb.LayoutView , :affiliated_facility}
  end

  scope "/", MemberLinkWeb do
    pipe_through :browser # Use the default browser stack
    get "/", PageController, :dummy
  end

  scope "/:locale", MemberLinkWeb do
    pipe_through [:browser, :evoucher_layout]
    get "/evoucher", MemberController, :evoucher
    post "/evoucher", MemberController, :verify_evoucher
    get "/evoucher/reprint", MemberController, :evoucher_reprint
    post "/evoucher/reprint", MemberController, :evoucher_reprint_validate
    get "/evoucher/:id/member_details", MemberController, :evoucher_member_details
    put "/evoucher/:id/member_details", MemberController, :evoucher_member_details_update
    get "/evoucher/:id/facility", MemberController, :evoucher_select_facility
    put "/evoucher/:id/facility", MemberController, :evoucher_select_facility_update
    get "/evoucher/:id/summary", MemberController, :evoucher_summary
    post "/evoucher/:id/summary", MemberController, :evoucher_summary_print
    get "/evoucher/:id/print_preview", MemberController, :evoucher_print_preview
    get "/evoucher/:id/render", MemberController, :evoucher_render
    delete "/evoucher/:id/remove_primary_id", MemberController, :remove_primary_id
    delete "/evoucher/:id/remove_secondary_id", MemberController, :remove_secondary_id

    pipe_through [:auth_layout]

    get "/sign_in", SessionController, :sign_in
    post "/sign_in", SessionController, :login
    get "/verify_code_login/:id", SessionController, :verify_code_login
    post "/verify_code_login/:id", SessionController, :login_verification
    get "/new_code/:id", SessionController, :new_code

    get "/forgot_password", SessionController, :forgot_password
    post "/forgot_password", SessionController, :forgot
    # get "/sign", SessionController, :load_all_user_email_mobile
    get "/create", SessionController, :create_password
    put "/create/:password_token", SessionController, :insert_password
    get "/verify_code/:id", SessionController, :verify_code
    get "/verify_code_sms/:id", SessionController, :verify_code_sms
    post "/verify_code/:id", SessionController, :code_verification
    get "/resend_code/:id", SessionController, :resend_code
    put "/resend_code/:id", SessionController, :update_code
    get "/reset_password/:id", SessionController, :reset_password
    put "/reset_password/:id", SessionController, :update_password
    get "/resend_code_email/:id", SessionController, :resend_code_email
    get "/resend_code_sms/:id", SessionController, :resend_code_sms
  end

  scope "/:locale", MemberLinkWeb do
    pipe_through [:browser, :af_layout]

    get "/affiliated_facility/:member_id", SearchController, :load_affiliated_facilities
  end

  scope "/:locale", MemberLinkWeb do
    pipe_through [:browser, :login_required]

    get "/", PageController, :index
    get "/export/:id/loa", PageController, :export_csv
    get "/transaction/:id/export_pdf", PageController, :export_pdf
    delete "/sign_out", SessionController, :logout

    resources "/translations", TranslationController
    get "/translations/load/base_value", TranslationController, :get_base_value

    #Search Routes
    get "/search", SearchController, :search_doctors
    get "/search/doctors/:id", SearchController, :filter_doctors
    get "/search/doctors/all/:offset", SearchController, :get_all_doctors
    get "/search/all/:offset", SearchController, :get_all_doctors_and_hospitals
    get "/search/hospitals/:offset", SearchController, :get_all_hospitals
    #  get "/search/text/all", SearchController, :search_all_doctors_and_hospitals
    #  get "/search/text/all_hospital", SearchController, :search_all_hospitals
    get "/search/submit/all/:current_active/:offset", SearchController, :search_doctors_submit
    get "/search/get_direction/:id", SearchController, :get_direction
    get "/search/request_loa_consult/:id/:facility_id/:practitioner_specialization_id", SearchController, :request_loa
    get "/search/intellisense/:current_active", SearchController, :search_intellisense
    get "/search/request_loa_consult/check_coverage", SearchController, :check_coverage
    get "/search/request_acu/procedures", SearchController, :get_all_procedures_in_request_acu
    get "/search/request_acu/check_authorization", SearchController, :check_acu_authorization

    get "/smarthealth", PageController, :smarthealth
  end

  scope "/:locale", MemberLinkWeb do
    pipe_through [:browser, :acct_layout]

    # Account Settings
    get "/account", UserController, :view_account
    get "/account/edit", UserController, :edit_account
    post "/account/edit", UserController, :update_account
    put "/account/edit", UserController, :update_account

    get "/profile", UserController, :edit_profile
    post "/profile", UserController, :update_profile
    put "/profile", UserController, :update_profile
    get "/profile/request/correction", UserController, :request_profile_correction
    post "/profile/request/correction", UserController, :send_request_prof_cor
    put "/profile/request/correction", UserController, :send_request_prof_cor

    get "/contact_details", UserController, :edit_contact_details
    post "/contact_details", UserController, :update_contact_details
    put "/contact_details", UserController, :update_contact_details
    post "/account/validate/old_password", UserController, :validate_old_password

    get "/kyc", KycController, :kyc_existing?
    get "/kyc/:id/show", KycController, :show
    get "/kyc/new", KycController, :new
    post "/kyc/new", KycController, :create
    get "/kyc/:id/step_3", KycController, :step_3
    post "/kyc/:id/step_3", KycController, :step_3_create
    post "/kyc/delete", KycController, :delete_kyc

    get "/emergency_contact", MemberController, :emergency_contact
    get "/emergency_contact/edit", MemberController, :edit_emergency_contact
    post "/emergency_contact/edit", MemberController, :save_emergency_contact

    get "/kyc/:id/setup", KycController, :setup
    put "/kyc/:id/setup", KycController, :update_setup
    post "/kyc/:id/setup", KycController, :update_setup

    get "/kyc/:id/submit", KycController, :submit
  end

  scope "/:locale", MemberLinkWeb do
    pipe_through [:browser, :reg_layout]

    get "/register/card_verification", UserController, :register_card_verification
    post "/register/card_verification", UserController, :register_verify_member
    get "/register/:id/setup", UserController, :register_setup
    get "/register/:id/new", UserController, :register_setup_registration
    get "/register/:member_id/:user_id/contacts", UserController, :register_setup_contacts
    post "/register/:id/new", UserController, :register_member
    get "/register/user/validate", UserController, :register_user_validate
    get "/register/:member_id/:user_id/success", UserController, :register_success
    get "/register/:member_id/:user_id/sms_verification", UserController, :register_verify_account
    get "/register/:member_id/:user_id/sms_verification/:attempts", UserController, :register_verify_account_failed
    post "/register/:member_id/:user_id/sms_verification/:attempts", UserController, :register_account_verification
    get "/register/:member_id/:user_id/kyc_bank_details", UserController, :register_bank_kyc_1
    get "/register/:member_id/:user_id/kyc_bank_contact", UserController, :register_bank_kyc_2
    get "/register/:member_id/:user_id/kyc_bank_submit", UserController, :register_bank_kyc_3
    get "/register/resend_code/:user_id/", UserController, :register_resend_code
  end

  # Other scopes may use custom stacks.

  scope "/api", MemberLinkWeb.Api do
    pipe_through :auth_api

    scope "/v1", V1 do
      # Status
      get "/status", StatusController, :index
      post "/user/login", SessionController, :login
      post "/user/register", UserController, :register
      post "/user/card_verification", UserController, :card_verification
      post "/user/forgot/username", UserController, :forgot_username
      post "/user/forgot/password", UserController, :forgot_password
      put "/user/forgot/password_confirm", UserController, :forgot_password_confirm
      put "/user/forgot/password_reset", UserController, :forgot_password_reset
      post "/user/forgot/resend_code", UserController, :resend_code_api
      post "/user/login_card", SessionController, :login_card

      #Token required endpointsss
      pipe_through :token_required

      put "/user/sms_verification", UserController, :sms_verification
      get "/profile", ProfileController, :get_member
      put "/profile/update", ProfileController, :update_member_profile
      put "/user/username", UserController, :update_username
      put "/user/password", UserController, :update_password
      get "/doctors", DoctorController, :search
      post "/loa/request/op-lab", LoaController, :request_op_lab
      post "/loa/request/op-consult", LoaController, :request_op_consult
      get "/user/request/pin", UserController, :request_pin
      get "/loas", LoaController, :get_loa
      post "/kyc/bank", KycController, :create_kyc_bank
      get "/dependents", ProfileController, :get_dependents
      post "/profile/dependent", ProfileController, :register_dependent
      post "/profile/emergency_contact", ProfileController, :create_emergency_contact
      put "/profile/update/emergency_contact", ProfileController, :update_emergency_contact
      get "/emergency_contact", ProfileController, :get_emergency_contact
      get "/specializations", DoctorController, :get_specializations
      get "/hospitals", HospitalController, :search
      get "/kyc_bank", KycController, :get_kyc_bank
      put "/profile/contact_details", ProfileController, :update_contact_details
      get "/loa/check/coverage", LoaController, :check_benefit_coverage
      put "/profile/update/profile_photo", ProfileController, :update_member_profile_photo
      #memberlink web
    end
  end

  scope "/api/v1", MemberLinkWeb.Api.V1 do
    pipe_through :mg_api

    post "/members/change_password", SessionController, :change_password
  end
end
