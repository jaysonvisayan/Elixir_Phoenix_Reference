defmodule RegistrationLinkWeb.Router do
  use RegistrationLinkWeb, :router

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
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug :fetch_flash
  end

  pipeline :auth_layout do
    plug :put_layout, {RegistrationLinkWeb.LayoutView, :auth}
  end

  pipeline :login_required do
    plug RegistrationLink.Guardian.AuthPipeline.Browser
    plug RegistrationLink.Guardian.AuthPipeline.Authenticate
    plug RegistrationLinkWeb.Auth.CurrentUser
  end

  scope "/", RegistrationLinkWeb do
    pipe_through [:browser, :auth_layout]

    get "/sign_in", SessionController, :sign_in
    post "/sign_in", SessionController, :login
    delete "/sign_out", SessionController, :logout
 end

  scope "/", RegistrationLinkWeb do
    pipe_through [:browser, :login_required]

    get "/", PageController, :index
    get "/batch_processing/pf_batch/new", BatchController, :new_pf_batch
    post "/batch_processing/pf_batch/new", BatchController, :create_pf_batch

    get "/batch_processing/:id/pf_batch/", BatchController, :edit_pf_batch
    put "/batch_processing/:id/pf_batch/", BatchController, :update_pf_batch

    get "/batch_processing/:id/get_practitioner_details", BatchController, :get_practitioner_details
    get "/batch_processing/:id/get_affiliated_practitioner", BatchController, :get_affiliated_practitioner
    get "/batch_processing/pf_batch/summary", BatchController, :pf_batch_summary

    get "/batch_processing/hb_batch/new", BatchController, :new_hb_batch
    post "/batch_processing/hb_batch/new", BatchController, :create_hb_batch

    get "/batch_processing/:id/hb_batch/", BatchController, :edit_hb_batch
    put "/batch_processing/:id/hb_batch/", BatchController, :update_hb_batch

    get "/batch_processing/:id/get_facility_address", BatchController, :get_facility_address
    get "/batch_processing/hb_batch/summary", BatchController, :hb_batch_summary

    get "/batch_processing/:id", BatchController, :show
    put "/batch_processing/:id/update_soa_amount", BatchController, :update_soa_amount

    get "/batch_processing", BatchController, :index
    get "/batch_processing/index/download", BatchController, :batch_download

    get "/batch_processing/:id/loa/:authorization_id/new", BatchController, :new_loa
    put "/batch_processing/:id/loa/:authorization_id/new", BatchController, :create_new_batch_loa
    post "/batch_processing/:id/loa/:authorization_id/new", BatchController, :create_new_batch_loa

    get "/batch_processing/:id/delete_batch_authorization_file", BatchController, :delete_batch_authorization_file
    get "/batch_processing/:id/delete_batch_authorization", BatchController, :delete_batch_authorization
    get "/batch_processing/:id/return_index", BatchController, :return_index
    get "/batch_processing/:id/return_not_available_loa", BatchController, :return_not_available_loa
    post "/batch_processing/:id/loa/:authorization_id/checker", BatchController, :batch_authorization_availability_checker
    post "/batch_processing/:batch_id/submit_batch", BatchController, :submit_batch
    post "/batch_processing/:batch_id/add_comment", BatchController, :add_batch_comment
    delete "/batch_processing/:batch_id/delete_batch", BatchController, :delete_batch
    get "/batch_processing/:id/search_batch_loa", BatchController, :search_batch_loa

    get "/batch_processing/:user_id/get_current_user", BatchController, :get_current_user

    get "/batch_processing/pf_batch/save", BatchController, :save_pf_batch
    get "/batch_processing/pf_batch/save_edit", BatchController, :save_edit_pf_batch
    put "/batch_processing/pf_batch/new", BatchController, :create_pf_batch
    get "/batch_processing/:batch_file_id/delete", BatchController, :delete_batch_file

    get "/batch_processing/hb_batch/save", BatchController, :save_hb_batch
    get "/batch_processing/hb_batch/save_edit", BatchController, :save_edit_hb_batch
    put "/batch_processing/hb_batch/new", BatchController, :create_hb_batch
    get "/batch_processing/:batch_file_id/delete", BatchController, :delete_batch_file
  end

  # Other scopes may use custom stacks.
  scope "/api", RegistrationLinkWeb do
    pipe_through :api

    post "/save_scan_doc/:id", BatchController, :save_scan_doc
    post "/save_scan_loa/:id", BatchController, :save_scan_loa
    # get "/save_scan_loa/:id", BatchController, :save_scan_loa
  end
end
