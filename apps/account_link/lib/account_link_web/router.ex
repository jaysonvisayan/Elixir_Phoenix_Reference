defmodule AccountLinkWeb.Router do
  use AccountLinkWeb, :router

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
    plug AccountLinkWeb.Plug.Locale, "en"
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug :fetch_flash
  end

  pipeline :login_required do
    plug AccountLink.Guardian.AuthPipeline.Browser
    plug AccountLink.Guardian.AuthPipeline.Authenticate
    plug AccountLinkWeb.Auth.CurrentUser
    plug Auth.SlidingSessionTimeout, timeout_after_seconds: 600
  end

  pipeline :auth_layout do
    plug :put_layout, {AccountLinkWeb.LayoutView , :auth}
  end

  pipeline :reg_layout do
    plug :put_layout, {AccountLinkWeb.LayoutView, :reg}
  end

  pipeline :validate_evoucher_layout do
    plug :put_layout, {AccountLinkWeb.LayoutView, :validate_evoucher}
  end

  scope "/", AccountLinkWeb do
    pipe_through [:browser]

    get "/", PageController, :dummy
  end

  scope "/:locale/validate_evoucher", AccountLinkWeb do
    pipe_through [:browser, :validate_evoucher_layout]

    # get "/", MemberController, :evoucher_index
    # get "/:id", MemberController, :edit_evoucher_member

    # post "/", MemberController, :validate_evoucher
    # put "/:id", MemberController, :update_evoucher_member
  end

  scope "/:locale", AccountLinkWeb do
    get "/render/evoucher/:id", PemeController, :render_evoucher
    get "/print/evoucher/:id", PemeController, :print_evoucher

    post "/print_preview/evoucher/:id", PemeController, :print_preview_evoucher

    pipe_through [:browser, :auth_layout] # Use the default browser stack
    post "/export/evoucher/", PemeController, :export_evoucher
    get "/sign_in", SessionController, :sign_in
    post "/sign_in", SessionController, :login
    get "/verify_code_login/:id", SessionController, :verify_code_login
    post "/verify_code_login/:id", SessionController, :login_verification
    get "/new_code/:id", SessionController, :new_code

    get "/forgot_password", SessionController, :forgot_password
    post "/forgot_password", SessionController, :forgot
    get "/sign", SessionController, :load_all_username
    get "/create", SessionController, :create_password
    put "/create/:password_token", SessionController, :insert_password
    get "/verify_code/:id", SessionController, :verify_code
    get "/verify_code_sms/:id", SessionController, :verify_code_sms
    post "/verify_code/:id", SessionController, :code_verification
    get "/resend_code/:id", SessionController, :resend_code
    put "/resend_code/:id", SessionController, :update_code
    get "/reset_password/:id", SessionController, :reset_password
    put "/reset_password/:id", SessionController, :update_password
  end

  scope "/:locale", AccountLinkWeb do
    pipe_through [:browser, :reg_layout]

    get "/register/:id", UserController, :register
    post "/register/:id", UserController, :sign_up
    get "/register/user/validate", UserController, :user_validate
  end

  scope "/:locale", AccountLinkWeb do
    pipe_through [:browser, :login_required] #:login_required] # Use the default browser stack

    get "/", PageController, :index

    get "/users/change_password", UserController, :change_password
    put "/users/change_password", UserController, :update_change_password
    post "/users/change_password", UserController, :update_change_password
    delete "/sign_out", SessionController, :logout

    # Account
    get "/account/profile", AccountController, :show_profile
    get "/account/product", AccountController, :show_product
    get "/account/product/:id/summary", AccountController, :show_product_summary
    get "/account/finance", AccountController, :show_finance
    get "/account/finance/:id/request_edit", AccountController, :show_finance_edit
    # post "/account/finance/:id/request_edit", AccountController, :finance_request_edit
    get "/account/:code/get_account", AccountController, :get_account
    # End Account

    # PEME
    get "/peme", PemeController, :index
    get "/peme/new", PemeController, :new_peme
    post "/peme/generate_evoucher", PemeController, :peme_generate_evoucher
    get "/peme/:id/peme_member_details", PemeController, :show_peme_member_details
    get "/peme/single/new", PemeController, :new_single
    post "/peme/single/new", PemeController, :create
    get "/peme/:id/single", PemeController, :show_single
    put "/peme/:id/single", PemeController, :update_single
    post "/peme/:id/request_loa", PemeController, :update_request_loa
    get "/peme/single/load_packages", PemeController, :load_packages
    get "/peme/single/:package_id/load_package", PemeController, :load_package
    get "/peme/:id/summary", PemeController, :show_summary
    post "/peme/cancel_evoucher", PemeController, :cancel_evoucher
    get "/peme/:id/show", PemeController, :show_peme_summary

    post "/peme/peme_send_voucher", PemeController, :peme_send_voucher

    get "/peme/:id/register_peme", PemeController, :register_peme
    get "/peme/:id/edit_register_peme", PemeController, :edit_register_peme
    put "/peme/:id/create_peme_member", PemeController, :create_peme_member
    put "/peme/:id/update_peme_member", PemeController, :update_peme_member2
    #------------------------------------------------------------------------------------------------------------------------------------
    get "/peme/:id/evoucher_summary", PemeController, :evoucher_summary
    post "/peme/:id/summary", PemeController, :evoucher_summary_print
    get "/peme/:id/print_preview", PemeController, :evoucher_print_preview
    get "/peme/:id/render", PemeController, :evoucher_render

    delete "/peme/:id/remove_primary_id", PemeController, :remove_primary_id
    delete "/peme/:id/remove_secondary_id", PemeController, :remove_secondary_id
    get "/peme/index/data", PemeController, :load_index
    get "/peme/:account_code/member", PemeController, :get_peme_member_mobile
    # End PEME

    # Members
    get "/members", MemberController, :index
    get "/members/new", MemberController, :new
    post "/members/new", MemberController, :create_general
    get "/members/:id/show", MemberController, :show
    get "/members/:id/setup", MemberController, :setup
    get "/members/:id/edit", MemberController, :edit
    put "/members/:id/setup", MemberController, :update_setup
    post "/members/:id/setup", MemberController, :update_setup

    post "/members/cancel", MemberController, :member_cancel
    post "/members/suspend", MemberController, :member_suspend
    post "/members/reactivate", MemberController, :member_reactivate

    post "/members/:id/add_product", MemberController, :add_member_product
    post "/members/:id/save_product_tier", MemberController, :save_member_prduct_tier

    get "/members/batch_processing", MemberController, :batch_processing_index
    post "/members/batch_processing/upload", MemberController, :import_member

    post "/members/validate_member_info", MemberController, :validate_member_info
    post "/members/:id/add_comment", MemberController, :create_member_comment

    get "/members/evoucher/:id/facility_edit", MemberController, :edit_evoucher_facility
    put "/members/evoucher/:id/update", MemberController, :update_evoucher_member
    put "/members/evoucher/:id/facility_update", MemberController, :update_evoucher_facility

    # post "/members/:id/add_skipping", MemberController, :add_skipping

    # JSON
    get "/members/index/download", MemberController, :download_members
    get "/members/:log_id/:status/member_batch_download", MemberController, :member_batch_downoad
    get "/members/:log_id/:status/:type/member_batch_download", MemberController, :member_batch_download

    delete "/members/:member_id/member_product/:id", MemberController, :delete_member_product
    delete "/members/:id/delete_member_photo", MemberController, :delete_member_photo
    get "/members/:id/logs", MemberController, :get_member_logs
    get "/members/pwd_id/all", MemberController, :get_pwd_id
    get "/members/senior_id/all", MemberController, :get_senior_id
    get "/members/:mobile/get_mobile_number", MemberController, :get_mobile_number
    get "/members/index/data", MemberController, :load_index
    # End JSON
    # End Members

    # Approval
    get "/approval/special", ApprovalController, :show_special
    get "/approval/special/:id/details", ApprovalController, :show_special_details
    put "/approval/special/:id", ApprovalController, :special_action
    # End Approval
  end

  scope "/api", AccountLinkWeb, as: :api do
    pipe_through [:api]

    get "/v1/special/download", ApprovalController, :download_special
    get "/v1/peme/package/with_facility_and_procedures/:id/:account_id", PemeController, :get_package_with_facility_and_procedures
    put "/v1/update_loa_status/:id", PemeController, :update_loa_status
  end
  # Other scopes may use custom stacks.
  # scope "/api", AccountLinkWeb do
  #   pipe_through :api
  # end
end
