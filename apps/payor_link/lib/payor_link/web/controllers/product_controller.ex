defmodule Innerpeace.PayorLink.Web.ProductController do
  use Innerpeace.PayorLink.Web, :controller

  # import Ecto.Changeset

  alias Innerpeace.Db.Base.{
    ProductContext,
    BenefitContext,
    # FacilityContext,
    ExclusionContext,
    # ProcedureContext,
    RoomContext,
    CoverageContext,
    LocationGroupContext,
    Api.UtilityContext
  }

  alias Innerpeace.Db.Repo

  alias Innerpeace.Db.Schemas.{
    Product,
    ProductCoverage,
    ProductCoverageFacility,
    # ProductFacility,
    ProductBenefit,
    ProductBenefitLimit,
    ProductExclusion,
    # ProductRiskShare,
    # ProductRiskShareFacility,
    ProductCoverageRiskShare,
    ProductCoverageRiskShareFacility,
    # ProductCoverageRiskShareFacilityPayorProcedure,
    # FacilityPayorProcedure,
    # ProductCoverageLimitThreshold,
    ProductCoverageLimitThresholdFacility
  }

  alias Innerpeace.Db.Datatables.ProductDatatableV2

  plug Guardian.Permissions.Bitwise,
    [handler: Innerpeace.PayorLink.Web.FallbackController,
     one_of: [
       %{products: [:manage_products]},
       %{products: [:access_products]},
     ]] when action in [
       :index,
       :show
     ]

  plug Guardian.Permissions.Bitwise,
    [handler: Innerpeace.PayorLink.Web.FallbackController,
     one_of: [
       %{products: [:manage_products]},
     ]] when not action in [
       :index,
       :show
     ]

  plug :valid_uuid?, %{origin: "products"}
  when not action in [:index]

  def index(conn, _params) do
    # Loads index page.

    # products = ProductContext.get_all_products_for_index("", 0)
    products = []
    render(conn, "index.html", products: products)
  end

  def index_load_datatable(conn, %{"params" => params}) do
    # Loads index page.

    # products = ProductContext.get_all_products_for_index(params["search_value"], params["offset"])
    products = []
    render(conn, Innerpeace.PayorLink.Web.ProductView, "load_all_products.json", products: products)
  end

  def new_peme(conn, _params) do
    # Loads Step 1 form in the Product creation wizard.

    changeset_general_peme = Product.changeset_general_peme(%Product{})
    p_cat = "PEME Plan"
    render(conn, "step1_peme.html", changeset_general: changeset_general_peme, p_cat: p_cat)
  end

  def new_reg(conn, _params) do
    # Loads Step 1 form in the Product creation wizard.
    changeset_general = Product.changeset_general(%Product{})
    p_cat = "Regular Plan"
    render(conn, "step1.html", changeset_general: changeset_general, p_cat: p_cat)
  end

  def create(conn, %{"product" => product_params}) do
    # Saves Step 1 fields as the initial fields of a Product record.
    product_params =
      product_params
      |> Map.put("step", "2")
      |> Map.put("created_by_id", conn.assigns.current_user.id)
      |> Map.put("updated_by_id", conn.assigns.current_user.id)

    case ProductContext.create_product(product_params) do
      {:ok, product} ->
        conn
        # |> put_flash(:info, "Success")
        |> redirect(to: "/products/#{product.id}/setup?step=2")
      {:error, %Ecto.Changeset{} = changeset_general} ->
        p_cat = changeset_general.changes.product_category
        conn
        |> put_flash(:error, "Please complete your fields!")
        |> render("step1.html", changeset_general: changeset_general, p_cat: p_cat)
    end
  end

  def create_peme(conn, %{"product" => product_params}) do
    # Saves Step 1 fields as the initial fields of a Product record.
    product_params =
      product_params
      |> Map.put("step", "2")
      |> Map.put("created_by_id", conn.assigns.current_user.id)
      |> Map.put("updated_by_id", conn.assigns.current_user.id)

    case ProductContext.create_product_peme(product_params) do
      {:ok, product} ->
        conn
        # |> put_flash(:info, "Success")
        |> redirect(to: "/products/#{product.id}/setup?step=2")
      {:error, %Ecto.Changeset{} = changeset_general_peme} ->
        p_cat = changeset_general_peme.changes.product_category
        conn
        |> put_flash(:error, "Please complete your fields!")
        |> render("step1_peme.html", changeset_general: changeset_general_peme, p_cat: p_cat)
    end
  end

  def delete(conn, %{"id" => id}) do
    # Deletes a Product record.

    {:ok, _product} = ProductContext.delete_product(id)

    conn
    |> put_flash(:info, "Plan deleted successfully.")
    |> redirect(to: product_path(conn, :index))
  end

  def show(conn, %{"id" => id}) do
    # Loads all the record inside Product and its child tables.
    case Repo.get(Product, id) do
      %Product{} ->
        product = ProductContext.get_product!(id)

        accounts =
          product.id
          |> ProductContext.get_account_products()

        # benefits = BenefitContext.get_all_benefits()
        # exclusions = ExclusionContext.get_all_exclusions()
        if product.product_category == "PEME Plan" do
          # render(conn, "show_peme.html", product: product, benefits: benefits, exclusions: exclusions)
          render(conn, "show_peme.html", product: product, accounts: accounts)
        else
          # render(conn, "show.html", product: product, benefits: benefits, exclusions: exclusions)
          render(conn, "show.html", product: product, accounts: accounts)
        end

      _ ->
        conn
        |> put_flash(:error, "ID Doesn't Exist!")
        |> redirect(to: "/products")
  end

  end

  def setup(conn, %{"id" => id, "step" => step, "product_benefit_id" => product_benefit_id}) do
    # Loads the form template according to the step the
    # user is in with the value of 'product_benefit_id'
    # to be used only in Step.

    product = ProductContext.get_product!(id)

    case step do
      "1" ->
        step1(conn, product)
      "2" ->
        step2(conn, product)
      "3" ->
        step3(conn, product)
      "3.1" ->
        step3_open_pb(conn, product, product_benefit_id)
      "4" ->
        step4(conn, product)
      "5" ->
        step5(conn, product)
      "6" ->
        step6(conn, product)
      "7" ->
        step7(conn, product)
      _ ->
        conn
        |> put_flash(:error, "Invalid step!")
    end
  end

  def reverting_back_step(conn, %{"id" => id, "step" => step}) do
    product = ProductContext.get_product!(id)
    params =
      %{}
      |> Map.put("step", "4")
      |> Map.put("updated_by_id", conn.assigns.current_user.id)

    ProductContext.update_product_step(product, params)
    conn
    |> put_flash(:error, "You are redirected to the step process again due to deleting of Benefit that contains Plan Coverages")
    |> redirect(to: "/products/#{id}/setup?step=4")
  end
  
  def category(nil), do: ""
  def category(product), do: product.product_category

  def setup(conn, %{"id" => id, "step" => step}) do
    # Loads the form template according to the step the user is in.
    product = ProductContext.get_product!(id)
    setup(conn, product, category(product), step)
  end

  def setup(conn, nil, _category, step) do
    conn
    |> put_flash(:error, "Product not found!")
    |> redirect(to: product_path(conn, :index))
  end

  def setup(conn, product, "PEME Plan", step) do
    cond do
      product.step == "8" ->
        conn
        |> put_flash(:error, "You are not allowed to get back to creation steps")
        |> redirect(to: product_path(conn, :show, product))
      true ->
        case step do
          "1" ->
            step1_peme(conn, product)
          "2" ->
            step2_peme(conn, product)
          "2.2" ->
            step2_cov_peme(conn, product)
          "3" ->
            step3_peme(conn, product)
          "4" ->
            step4_peme(conn, product)
          "5" ->
            step5_peme(conn, product)
          # "6" ->
            #   step6(conn, product)
          # "7" ->
            #   step7(conn, product)
          _ ->
            conn
            |> put_flash(:error, "Invalid step!")
            |> redirect(to: "/products/#{product.id}/")
        end
    end
  end

  def setup(conn, product, _category, step) do
    cond do
      product.step == "8" ->
        conn
        |> put_flash(:error, "You are not allowed to get back to creation steps")
        |> redirect(to: product_path(conn, :show, product))

        true ->
        case step do
          "1" ->
            step1(conn, product)
          "2" ->
            step2(conn, product)
          "3" ->
            step3(conn, product)
          "3.2" ->
            step3_cov(conn, product)
          "4" ->
           step4(conn, product)
          "5" ->
            step5(conn, product)
          "6" ->
            step6(conn, product)
          "7" ->
            step7(conn, product)
          _ ->
           conn
           |> put_flash(:error, "Invalid step!")
           |> redirect(to: "/products/#{product.id}/")
       end
    end
  end

  def setup(conn, %{"id" => id}) do
    conn
    |> put_flash(:error, "Invalid step!")
    |> redirect(to: product_path(conn, :index))
  end

  def update_setup(conn, %{"id" => id, "step" => step, "product" => product_params}) do
    # Updates Product or any of its child tables according to the step the user is in
    product = ProductContext.get_product!(id)
    if product.product_category == "PEME Plan" do
      case step do
        "1" ->
          step1_update_peme(conn, product, product_params)
        "2" ->
          step2_update_peme(conn, product, product_params)
        "2.2" ->
          step2_cov_update_peme(conn, product, product_params)
        "2.1" ->
          step2_open_pb_update_peme(conn, product, product_params)
        "3" ->
          step3_update_peme(conn, product, product_params)
        "3.1" ->
          step5_update_rnb(conn, product, product_params)
        "4" ->
          step4_update_peme(conn, product, product_params)
        # "4" ->
        #   step6_update(conn, product, product_params)
        # "4.1" ->
        #   step6_rs_facility_update(conn, product, product_params)
        # "4.2" ->
        #   step6_rs_procedure_update(conn, product, product_params)
        _ ->
          conn
          |> put_flash(:error, "Invalid Step")
          |> redirect(to: "/products")
      end
      else
        case step do
          "1" ->
            step1_update(conn, product, product_params)
          "2.1" ->
            step2_genex_update(conn, product, product_params)
          "2.2" ->
            step2_pre_existing_update(conn, product, product_params)
          "3" ->
            step3_update(conn, product, product_params)
          "3.2" ->
            step3_cov_update(conn, product, product_params)
          "3.1" ->
            step3_open_pb_update(conn, product, product_params)
          "4" ->
            step4_update(conn, product, product_params)
          "5" ->
            step5_update(conn, product, product_params)
          "5.1" ->
            step5_update_rnb(conn, product, product_params)
          "6" ->
            step6_update(conn, product, product_params)
          "6.1" ->
            step6_rs_facility_update(conn, product, product_params)
          "6.2" ->
            step6_rs_procedure_update(conn, product, product_params)
          _ ->
            conn
            |> put_flash(:error, "Invalid Step")
            |> redirect(to: "/products")
        end
    end
  end

  def edit_setup(conn, %{"id" => id, "tab" => tab, "product_benefit_id" => product_benefit_id}) do
    # Loads the form template according to the step the user
    #  is in with the value of 'product_benefit_id' to be used only in Step .

    product = ProductContext.get_product!(id)
    case tab do
      "general" ->
        edit_general(conn, product)
      "benefit" ->
        edit_benefit(conn, product)
      "benefit-limit" ->
        edit_benefit_open_pb(conn, product, product_benefit_id)
      "facility_access" ->
        edit_facility_access(conn, product)
      _ ->
        conn
        |> put_flash(:error, "Invalid Step")
        |> redirect(to: "/products/#{product.id}/")
    end
  end

  def edit_setup(conn, %{"id" => id, "tab" => tab}) do
    # Loads the edit form template according to the step the user is in.


    product = ProductContext.get_product!(id)

    if Enum.count(product.account_products) < 1 and product.standard_product == "No" do
      case tab do
        "general" ->
          edit_general(conn, product)
        "benefit" ->
          edit_benefit(conn, product)
        "coverage" ->
          edit_coverage(conn, product)
        "exclusion" ->
          edit_exclusion(conn, product)
        "facility_access" ->
          edit_facility_access(conn, product)
        "condition" ->
          edit_condition(conn, product)
        "risk_share" ->
          edit_risk_share(conn, product)
        _ ->
          conn
          |> put_flash(:error, "Invalid Step")
          |> redirect(to: "/products/#{product.id}/")
      end
    else
      conn
      |> put_flash(:error, "You are not allowed to edit this Plan, Bec: It has been already used by Account or its Plan Classification is Standard Plan")
      |> redirect(to: product_path(conn, :show, product))
    end

  end

  def edit_setup(conn, params) do
    conn
    |> put_flash(:error, "Page not found")
    |> redirect(to: "/products")
  end

  def delete_product_all(conn, %{"id" => id}) do
    ProductContext.delete_product_all(id)

    json conn, Poison.encode!(%{valid: true})
  end

  def save(conn, %{"id" => id, "tab" => tab, "product" => product_params}) do
    # Updates Product or any of its child tables according to the step the user is in

    product = ProductContext.get_product!(id)
    case tab do
      "general" ->
        update_general(conn, product, product_params)
      "benefit" ->
        update_benefit(conn, product, product_params)
      "coverage" ->
        update_coverage(conn, product, product_params)
      "benefit-limit" ->
        update_benefit_open_pb(conn, product, product_params)
      "exclusion-genex" ->
        update_exclusion_genex(conn, product, product_params)
      "exclusion-pre-existing" ->
        update_exclusion_pre_existing(conn, product, product_params)
      "facility_access" ->
        update_facility_access(conn, product, product_params)
      "condition" ->
        update_condition(conn, product, product_params)
      "condition_rnb" ->
        update_condition_rnb(conn, product, product_params)
      "risk_share" ->
        update_risk_share(conn, product, product_params)
      "risk_share_facility" ->
        update_risk_share_facility(conn, product, product_params)
      "risk_share_facility_procedure" ->
        update_risk_share_facility_procedure(conn, product, product_params)
    end
  end

  def get_all_product(conn, _params) do
    products = ProductContext.get_all_products()
    json conn, Poison.encode!(products)
  end

  ######################### START -- Functions regarding General.

  def step1(conn, product) do
    # Loads edit form of Step 1 in the Product creation wizard..
    changeset_general_edit = Product.changeset_general_edit(product)
    render(conn, "step1_edit.html", changeset_general_edit: changeset_general_edit, product: product)
  end

  def step1_peme(conn, product) do
    # Loads edit form of Step 1 in the Product creation wizard..
    changeset_general_edit = Product.changeset_general_peme_edit(product)
    render(conn, "step1_peme_edit.html", changeset_general_edit: changeset_general_edit, product: product)
  end

  def step1_update(conn, product, product_params) do
    # Updates the initial fields of Product with Step 1 fields.
    product_params =
      product_params
      |> Map.put("step", "2")
      |> Map.put("updated_by_id", conn.assigns.current_user.id)
    case ProductContext.update_product(product, product_params) do
      {:ok, product} ->
        ProductContext.update_product_step(product, product_params)
        conn
        |> put_flash(:info, "Plan updated successfully.")
        |> redirect(to: "/products/#{product.id}/setup?step=2")
      {:error, %Ecto.Changeset{} = changeset_general_edit} ->
        render(conn, "step1_peme_edit.html", product: product, changeset_general_edit: changeset_general_edit)

      {:error_product_limit, message} ->
        conn
        |> put_flash(:error, message)
        |> redirect(to: "/products/#{product.id}/setup?step=1")

    end
  end

  def step1_update_peme(conn, product, product_params) do
    # Updates the initial fields of Product with Step 1 fields.
    product_params =
      product_params
      |> Map.put("step", "2")
      |> Map.put("updated_by_id", conn.assigns.current_user.id)
    case ProductContext.update_product(product, product_params) do
      {:ok, product} ->
        ProductContext.update_product_step(product, product_params)
        conn
        |> put_flash(:info, "Plan updated successfully.")
        |> redirect(to: "/products/#{product.id}/setup?step=2")
      {:error, %Ecto.Changeset{} = changeset_general_peme_edit} ->
        render(conn, "step1_edit.html", product: product, changeset_general_edit: changeset_general_peme_edit)

      {:error_product_limit, message} ->
        conn
        |> put_flash(:error, message)
        |> redirect(to: "/products/#{product.id}/setup?step=1")

    end
  end

  def edit_general(conn, product) do
    # Loads the General tab form in Product edit.

    changeset_general_edit = Product.changeset_general_edit(product)
    render(conn, "edit/general.html", conn: conn, changeset_general_edit: changeset_general_edit, product: product)
  end

  def update_general(conn, product, product_params) do
    # Updates the initial fields of Product with General fields.
    _changeset_general_edit = Product.changeset_general_edit(product)
    product_params =
      product_params
      |> Map.put("updated_by_id", conn.assigns.current_user.id)
    case ProductContext.update_product(product, product_params) do
      {:ok, updated_product} ->
        ProductContext.create_product_log(
          conn.assigns.current_user,
          Product.changeset_general_edit(product, product_params),
          "General"
        )
        conn
        |> put_flash(:info, "Plan updated successfully.")
        |> redirect(to: "/products/#{updated_product.id}/edit?tab=general")
      {:error, %Ecto.Changeset{} = changeset_general_edit} ->
        render(conn, "edit/general.html", product: product, changeset_general_edit: changeset_general_edit)

      {:error_product_limit, message} ->
        conn
        |> put_flash(:error, message)
        |> redirect(to: "/products/#{product.id}/edit?tab=general")
    end
  end

  ######################### END -- Functions regarding General.

  ######################### START -- Functions regarding Exclusion

  def step2(conn, product) do
    # Loads the step 3 form of the Product creation wizard.

    exclusions = ExclusionContext.get_all_exclusions()
    changeset_genex = ProductExclusion.changeset_genex(%ProductExclusion{})
    changeset_pre_existing = ProductExclusion.changeset_pre_existing(%ProductExclusion{})
    render(
      conn,
      "step2.html",
      conn: conn,
      changeset_genex: changeset_genex,
      changeset_pre_existing: changeset_pre_existing,
      product: product,
      exclusions: exclusions
    )
  end

  def step2_genex_update(conn, product, product_params) do
    # Updates ProductExclusion records according to its coverage.

    exclusions = ExclusionContext.get_all_exclusions()
    product_params =
      product_params
      |> Map.put("updated_by_id", conn.assigns.current_user.id)
    changeset_genex =
      %ProductExclusion{}
      |> ProductExclusion.changeset_genex()
      |> Map.delete(:action)
      |> Map.put(:action, "insert")
    changeset_pre_existing =
      ProductExclusion.changeset_pre_existing(%ProductExclusion{})
    exclusion = String.split(product_params["gen_exclusion_ids_main"], ",")
    if exclusion == [""] do
      conn
      |> put_flash(:error, "Please select at least one general exclusion")
      |> render(
        "step2.html",
        changeset_genex: changeset_genex,
        changeset_pre_existing: changeset_pre_existing,
        product: product,
        exclusions: exclusions,
        modal_open_gen: true
      )
    else
      #clear_genex(product)
      ProductContext.set_genex(product.id, exclusion)
      ProductContext.update_product_step(product, product_params)
      conn
      |> put_flash(:info, "Successfully added plan exclusions")
      |> redirect(to: "/products/#{product.id}/setup?step=2")
    end
  end

  def step2_pre_existing_update(conn, product, product_params) do
    # Updates ProductExclusion records according to its coverage.

    exclusions = ExclusionContext.get_all_exclusions()
    product_params =
      product_params
      |> Map.put("updated_by_id", conn.assigns.current_user.id)
    changeset_genex =
      ProductExclusion.changeset_genex(%ProductExclusion{})
    changeset_pre_existing =
      %ProductExclusion{}
      |> ProductExclusion.changeset_pre_existing()
      |> Map.delete(:action)
      |> Map.put(:action, "insert")
    exclusion = String.split(product_params["pre_existing_ids_main"], ",")
    if exclusion == [""] do
      conn
      |> put_flash(:error, "Please select at least one Pre existing condition")
      |> render(
        "step2.html",
        changeset_genex: changeset_genex,
        changeset_pre_existing: changeset_pre_existing,
        product: product,
        exclusions: exclusions,
        modal_open_pre: true
      )
    else
      #  clear_pre_existing(product)
      ProductContext.set_pre_existing(product.id, exclusion)
      ProductContext.update_product_step(product, product_params)
      conn
      |> put_flash(:info, "Successfully added plan exclusions")
      |> redirect(to: "/products/#{product.id}/setup?step=2")
    end
  end

  def edit_exclusion(conn, product) do
    # Loads Exclusion tab in Product edit.

    exclusions = ExclusionContext.get_all_exclusions()
    changeset_genex = ProductExclusion.changeset_genex(%ProductExclusion{})
    changeset_pre_existing = ProductExclusion.changeset_pre_existing(%ProductExclusion{})
    render(
      conn,
      "edit/exclusion.html",
      conn: conn,
      changeset_genex: changeset_genex,
      changeset_pre_existing: changeset_pre_existing,
      product: product,
      exclusions: exclusions
    )
  end

  def update_exclusion_pre_existing(conn, product, product_params) do
    # Updates ProductExclusion records according to its coverage.

    exclusions = ExclusionContext.get_all_exclusions()
    changeset_genex =
      ProductExclusion.changeset_genex(%ProductExclusion{})
    changeset_pre_existing =
      %ProductExclusion{}
      |> ProductExclusion.changeset_pre_existing()
      |> Map.delete(:action)
      |> Map.put(:action, "insert")
    exclusion = String.split(product_params["pre_existing_ids_main"], ",")
    if exclusion == [""] do
      conn
      |> put_flash(:error, "Please select at least one Pre existing condition")
      |> render(
        "edit/exclusion.html",
        changeset_genex: changeset_genex,
        changeset_pre_existing: changeset_pre_existing,
        product: product,
        exclusions: exclusions,
        modal_open_pre: true
      )
    else
      case ProductContext.set_pre_existing(product.id, exclusion) do
        {:ok, exclusions} ->
          conn
          |> put_flash(:info, "Successfully added plan Exclusions")
          |> redirect(to: "/products/#{product.id}/edit?tab=exclusion")
        {:error} ->
          conn
          |> put_flash(:error, "One or more exclusion doesn't have exclusion limit.")
          |> redirect(to: "/products/#{product.id}/edit?tab=exclusion")
      end
    end
  end

  def update_exclusion_genex(conn, product, product_params) do
    # Updates ProductExclusion records according to its coverage.

    exclusions = ExclusionContext.get_all_exclusions()
    changeset_genex =
      %ProductExclusion{}
      |> ProductExclusion.changeset_genex()
      |> Map.delete(:action)
      |> Map.put(
        :action,
        "insert"
      )
    changeset_pre_existing =
      ProductExclusion.changeset_pre_existing(%ProductExclusion{})
    exclusion = String.split(product_params["gen_exclusion_ids_main"], ",")
    if exclusion == [""] do
      conn
      |> put_flash(:error, "Please select at least one general exclusion")
      |> render(
        "edit/exclusion.html",
        changeset_genex: changeset_genex,
        changeset_pre_existing: changeset_pre_existing,
        product: product,
        exclusions: exclusions,
        modal_open_gen: true
      )
    else
      ProductContext.set_genex(product.id, exclusion)
      conn
      |> put_flash(:info, "Successfully added plan exclusions")
      |> redirect(to: "/products/#{product.id}/edit?tab=exclusion")
    end
  end

  def get_exclusion(conn, %{"exclusion_id" => exclusion_id}) do
    # Returns an Exclusion record.

    exclusion = ExclusionContext.get_exclusion(exclusion_id)
    json conn, Poison.encode!(exclusion)
  end

  ########################## END -- Functions regarding Exclusion

  ######################### START -- Functions regarding Benefit

  def benefit_load_datatable(conn, get_params) do
    product = ProductContext.get_product!(get_params["id"])
    benefits = ProductContext.get_all_benefits_step3(
      get_params["params"]["search_value"],
      get_params["params"]["offset"],
      product)
    render(conn, Innerpeace.PayorLink.Web.ProductView, "load_all_benefits.json", benefits: benefits)
  end

  def step3(conn, product) do
    # Loads the step 2 form of the Product creation wizard.

    benefits = ProductContext.get_all_benefits_step3("", 0, product)
    changeset = ProductBenefit.changeset(% ProductBenefit{})
    render(conn, "step3.html", conn: conn, changeset: changeset, product: product, benefits: benefits)
  end

  def step2_peme(conn, product) do
    # Loads the step 2 form of the Product creation wizard.

    benefits = ProductContext.get_all_benefits_step3("", 0, product)
    changeset = ProductBenefit.changeset(% ProductBenefit{})
    render(conn, "step2_peme.html", conn: conn, changeset: changeset, product: product, benefits: benefits)
  end

  def step2_update_peme(conn, product, product_params) do
    # Updates ProductBenefit records according to the current Product.
    #benefits = BenefitContext.get_all_benefits()
    benefits = ProductContext.get_all_benefits_step3("", 0, product)
    product_params =
      product_params
      |> Map.put("updated_by_id", conn.assigns.current_user.id)
    changeset =
      %ProductBenefit{}
      |> ProductBenefit.changeset()
      |> Map.delete(:action)
      |> Map.put(:action, "insert")
    benefit = String.split(product_params["benefit_ids_main"], ",")
    user_id = conn.assigns.current_user.id

    if benefit == [""] do
      conn
      |> put_flash(:error, "At least one benefit must be added.")
      |> render("step2_peme.html", changeset: changeset, product: product, benefits: benefits, modal_open: true)
    else
      #clear_product_benefit(product)
      # inserting product_benefits Then inserting for product_benefit_limit_replica
      case ProductContext.set_product_benefits(product, benefit, user_id) do
        {:ok} ->
          ProductContext.update_product_step(product, product_params)
          conn
          |> put_flash(:info, "Successfully added Plan Benefits!")
          |> redirect(to: "/products/#{product.id}/setup?step=2")
        {:error, message} ->
          conn
          |> put_flash(:error, message)
          |> redirect(to: "/products/#{product.id}/setup?step=2")
      end
    end
  end

  def step2_open_pb_peme(conn, product, product_benefit_id) do
    # Loads form for ProductBenefit to modify its limit.

    product_benefit = ProductContext.get_product_benefit(product_benefit_id)
    changeset = ProductBenefitLimit.changeset(%ProductBenefitLimit{})
    render(conn, "product_benefit.html", product: product, changeset: changeset, product_benefit: product_benefit)
  end

  def step2_open_pb_update_peme(conn, product, product_params) do
    # Updates the limit of the current ProductBenefit.
    product_benefit = ProductContext.get_product_benefit(product_params["product_benefit_id"])
    product_params = BenefitContext.setup_limits_params(product_params)
    _changeset = ProductBenefitLimit.changeset(%ProductBenefitLimit{})
    pbl = ProductContext.get_product_benefit_limit(product_params["product_benefit_limit_id"])
    product_params =
      product_params
      |> Map.put("updated_by_id", conn.assigns.current_user.id)

    case ProductContext.update_product_benefit_limit(pbl, product_params) do
      {:ok, product_benefit_limit} ->
        conn
        |> put_flash(:info, "Benefit Limit updated successfully.")
        |> redirect(to: "/products/#{product.id}/product_benefit/#{product_benefit_limit.product_benefit_id}/setup?step=3.1")
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "product_benefit.html", product: product, changeset: changeset, product_benefit: product_benefit, modal_open: true)
    end
  end

  def step3_update(conn, product, product_params) do
    # Updates ProductBenefit records according to the current Product.
    #benefits = BenefitContext.get_all_benefits()
    benefits = ProductContext.get_all_benefits_step3("", 0, product)
    product_params =
      product_params
      |> Map.put("updated_by_id", conn.assigns.current_user.id)
    changeset =
      %ProductBenefit{}
      |> ProductBenefit.changeset()
      |> Map.delete(:action)
      |> Map.put(:action, "insert")
    benefit = String.split(product_params["benefit_ids_main"], ",")
    user_id = conn.assigns.current_user.id

    if benefit == [""] do
      conn
      |> put_flash(:error, "At least one benefit must be added.")
      |> render("step3.html", changeset: changeset, product: product, benefits: benefits, modal_open: true)
    else
      #clear_product_benefit(product)
      # inserting product_benefits Then inserting for product_benefit_limit_replica
      case ProductContext.set_product_benefits(product, benefit, user_id) do
        {:ok} ->
          ProductContext.update_product_step(product, product_params)
          conn
          |> put_flash(:info, "Successfully added Plan Benefits!")
          |> redirect(to: "/products/#{product.id}/setup?step=3")
        {:error, message} ->
          conn
          |> put_flash(:error, message)
          |> redirect(to: "/products/#{product.id}/setup?step=3")
      end
    end
  end

  def step3_open_pb(conn, product, product_benefit_id) do
    # Loads form for ProductBenefit to modify its limit.

    product_benefit = ProductContext.get_product_benefit(product_benefit_id)
    changeset = ProductBenefitLimit.changeset(%ProductBenefitLimit{})
    render(conn, "product_benefit.html", product: product, changeset: changeset, product_benefit: product_benefit)
  end

  def step3_open_pb_update(conn, product, product_params) do
    # Updates the limit of the current ProductBenefit.
    product_benefit = ProductContext.get_product_benefit(product_params["product_benefit_id"])
    product_params = BenefitContext.setup_limits_params(product_params)
    _changeset = ProductBenefitLimit.changeset(%ProductBenefitLimit{})
    pbl = ProductContext.get_product_benefit_limit(product_params["product_benefit_limit_id"])
    product_params =
      product_params
      |> Map.put("updated_by_id", conn.assigns.current_user.id)

    case ProductContext.update_product_benefit_limit(pbl, product_params) do
      {:ok, product_benefit_limit} ->
        conn
        |> put_flash(:info, "Benefit Limit updated successfully.")
        |> redirect(to: "/products/#{product.id}/product_benefit/#{product_benefit_limit.product_benefit_id}/setup?step=3.1")
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "product_benefit.html", product: product, changeset: changeset, product_benefit: product_benefit, modal_open: true)
    end
  end

  def get_product_benefit_limit(conn, %{"product_benefit_limit_id" => product_benefit_limit_id}) do
    # Returns ProductBenefit record.

    product_benefit_limit = ProductContext.get_product_benefit_limit(product_benefit_limit_id)
    json conn, Poison.encode!(product_benefit_limit)
  end

  def edit_benefit(conn, product) do
    # Loads Benefit tab in Product edit.

    benefits = ProductContext.get_all_benefits_step3("", 0, product)
    changeset = ProductBenefit.changeset(% ProductBenefit{})
    render(conn, "edit/benefit.html", conn: conn, changeset: changeset, product: product, benefits: benefits)
  end

  def update_benefit(conn, product, product_params) do
    # Updates ProductBenefit record of Products according to its Product.
    #benefits = BenefitContext.get_all_benefits()
    benefits = ProductContext.get_all_benefits_step3("", 0, product)
    changeset =
      %ProductBenefit{}
      |> ProductBenefit.changeset()
      |> Map.delete(:action)
      |> Map.put(:action, "insert")
    benefit = String.split(product_params["benefit_ids_main"], ",")
    user_id = conn.assigns.current_user.id

    if benefit == [""] do
      conn
      |> put_flash(:error, "Please select at least one benefit")
      |> render("edit/benefit.html", changeset: changeset, product: product, benefits: benefits, modal_open: true)
    else
      #clear_product_benefit(product)
      # inserting product_benefits Then inserting for product_benefit_limit_replica
      case ProductContext.set_product_benefits(product, benefit, user_id) do
        {:ok} ->
          ProductContext.update_product_step(product, product_params)
          conn
          |> put_flash(:info, "Successfully added Plan Benefits!")
          |> redirect(to: "/products/#{product.id}/edit?tab=benefit")
        {:error, message} ->
          conn
          |> put_flash(:error, message)
          |> redirect(to: "/products/#{product.id}/edit?tab=benefit")
      end
    end
  end

  def edit_benefit_open_pb(conn, product, product_benefit_id) do
    # Loads form for ProductBenefit to modify its limit.

    product_benefit = ProductContext.get_product_benefit(product_benefit_id)
    changeset = ProductBenefitLimit.changeset(%ProductBenefitLimit{})
    render(conn, "edit/product_benefit.html", product: product, changeset: changeset, product_benefit: product_benefit)
  end

  def update_benefit_open_pb(conn, product, product_params) do
    # Updates the limit of the current ProductBenefit.

    product_benefit = ProductContext.get_product_benefit(product_params["product_benefit_id"])
    product_params = BenefitContext.setup_limits_params(product_params)
    coverages_string =
      product_params["coverages"] || []
      |> String.split(",")
      |> Enum.join(", ")
    _changeset = ProductBenefitLimit.changeset(%ProductBenefitLimit{})
    pbl = ProductContext.get_product_benefit_limit(product_params["product_benefit_limit_id"])
    product_params =
      product_params
      |> Map.put("updated_by_id", conn.assigns.current_user.id)
      |> Map.put("coverages", coverages_string)

    case ProductContext.update_product_benefit_limit(pbl, product_params) do
      {:ok, product_benefit_limit} ->
        conn
        |> put_flash(:info, "Benefit Limit updated successfully.")
        |> redirect(to: "/products/#{product.id}/product_benefit/#{product_benefit_limit.product_benefit_id}/edit?tab=benefit-limit")
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit/product_benefit.html", product: product, changeset: changeset, product_benefit: product_benefit, modal_open: true)
    end
  end

  def deleting_product_benefit_step(conn, %{"product_id" => product_id, "id" => id}) do
    product = ProductContext.get_product!(product_id)
    with %ProductBenefit{} = product_benefit <- ProductContext.get_product_benefit(id) do
      ProductContext.benefit_hard_delete(product, product_benefit)
      ProductContext.delete_product_benefit_log(conn.assigns.current_user, product_benefit.benefit_id, product_benefit.product_id)
      json conn, Poison.encode!(%{valid: true})
    else
      _ ->
      json conn, Poison.encode!(%{valid: true})
    end
  end

  def deleting_product_benefit_edit(conn, %{"product_id" => product_id, "id" => id}) do
    product = ProductContext.get_product!(product_id)
    product_benefit = ProductContext.get_product_benefit(id)
    ProductContext.benefit_hard_delete(product, product_benefit)
    conn
    |> put_flash(:info, "Benefit deleted successfully!")
    |> redirect(to: "/products/#{product.id}/edit?tab=benefit")
  end

  ######################### END -- Functions regarding Benefit

  ######################### Start -- Functions regarding Coverage

  def step3_cov(conn, product) do
    # Loads the step 2 form of the Product creation wizard.
    coverages = CoverageContext.get_all_coverages()
    changeset = ProductCoverage.changeset(% ProductCoverage{})
    render(conn, "step3-1.html", conn: conn, changeset: changeset, product: product, coverages: coverages)
  end

  def step3_cov_update(conn, product, product_params) do
    coverages = CoverageContext.get_all_coverages()
    product_params =
      product_params
      |> Map.put("updated_by_id", conn.assigns.current_user.id)
    changeset =
      %ProductCoverage{}
      |> ProductCoverage.changeset()
      |> Map.delete(:action)
      |> Map.put(:action, "insert")
    coverage = product_params["coverages"]
    coverage_not_existing = Map.has_key?(product_params, "coverages")
    if coverage_not_existing == false do
      conn
      |> put_flash(:error, "Please select at least one coverage!")
      |> render("step3-1.html", changeset: changeset, product: product, coverages: coverages, conn: conn)
    else
      case ProductContext.set_coverage(product.id, coverage) do
        {:ok} ->
          ProductContext.update_product_step(product, product_params)
          conn
          |> put_flash(:info, "Successfully added Coverage/s")
          |> redirect(to: "/products/#{product.id}/setup?step=4")
        {:error, _changeset} ->
          conn
          |> put_flash(:error, "Error Entry")
          |> redirect(to: "/products/#{product.id}/setup?step=3.2")
      end
    end
  end

  def step2_cov_peme(conn, product) do
    # Loads the step 2 form of the Product creation wizard.
    coverages = CoverageContext.get_all_coverages()
    changeset = ProductCoverage.changeset(% ProductCoverage{})
    render(conn, "step2-1_peme.html", conn: conn, changeset: changeset, product: product, coverages: coverages)
  end

  def step2_cov_update_peme(conn, product, product_params) do
    coverages = CoverageContext.get_all_coverages()
    product_params =
      product_params
      |> Map.put("updated_by_id", conn.assigns.current_user.id)
    changeset =
      %ProductCoverage{}
      |> ProductCoverage.changeset()
      |> Map.delete(:action)
      |> Map.put(:action, "insert")
    coverage = product_params["coverages"]
    coverage_not_existing = Map.has_key?(product_params, "coverages")
    if coverage_not_existing == false do
      conn
      |> put_flash(:error, "Please select at least one coverage!")
      |> render("step2-1_peme.html", changeset: changeset, product: product, coverages: coverages, conn: conn)
    else
      case ProductContext.set_coverage(product.id, coverage) do
        {:ok} ->
          ProductContext.update_product_step(product, product_params)
          conn
          |> put_flash(:info, "Successfully added Coverage/s")
          |> redirect(to: "/products/#{product.id}/setup?step=3")
        {:error, _changeset} ->
          conn
          |> put_flash(:error, "Error Entry")
          |> redirect(to: "/products/#{product.id}/setup?step=2.2")
      end
    end
  end

  def edit_coverage(conn, product) do
    # Loads the coverage tab
    product_coverages = ProductContext.get_product_coverages(product.id)
    coverages = CoverageContext.get_all_coverages()
    changeset = ProductCoverage.changeset(% ProductCoverage{})
    render(
      conn,
      "edit/coverage.html",
      conn: conn,
      changeset: changeset,
      product: product,
      coverages: coverages,
      product_coverages: product_coverages
    )
  end

  def update_coverage(conn, product, product_params) do
    product_coverages = ProductContext.get_product_coverages(product.id)
    coverages = CoverageContext.get_all_coverages()
    product_params =
      product_params
      |> Map.put("updated_by_id", conn.assigns.current_user.id)
    changeset =
      %ProductCoverage{}
      |> ProductCoverage.changeset()
      |> Map.delete(:action)
      |> Map.put(:action, "insert")
    coverage = product_params["coverages"]
    coverage_not_existing = Map.has_key?(product_params, "coverages")
    if coverage_not_existing == false do
      conn
      |> put_flash(:error, "Please select at least one coverage!")
      |> render(
        "edit/coverage.html",
        changeset: changeset,
        product: product,
        coverages: coverages,
        conn: conn,
        product_coverages: product_coverages
      )
    else
      case ProductContext.set_coverage(product.id, coverage) do
        {:ok} ->
          ProductContext.update_product_step(product, product_params)
          conn
          |> put_flash(:info, "Coverage/s Updated Successfully!")
          |> redirect(to: "/products/#{product.id}/edit?tab=coverage")
        {:error, _changeset} ->
          conn
          |> put_flash(:error, "Error Entry")
          |> redirect(to: "/products/#{product.id}/edit?tab=coverage")
      end
    end
  end

  ######################### END -- Functions regarding Coverage

  ########################## START -- Functions regarding Facilty Access

  def step4_peme(conn, product) do
    # Loads step 4 form of Product creation wizard.

    facilities = ProductContext.get_list_of_facilities()
    changeset = ProductCoverageFacility.changeset(%ProductCoverageFacility{})
    location_group = LocationGroupContext.get_all_location_group()
    product_coverages = ProductContext.get_product_coverage(product.id)
    render(
      conn,
      "step4_peme.html",
      product: product,
      changeset: changeset,
      facilities: facilities,
      location_group: location_group,
      product_coverages: product_coverages
    )
  end

  def step4(conn, product) do
    # Loads step 4 form of Product creation wizard.

    # facilities = ProductContext.get_list_of_facilities() |> Enum.count() |> raise
    changeset = ProductCoverageFacility.changeset(%ProductCoverageFacility{})
    location_group = LocationGroupContext.get_all_location_group()
    product_coverages = ProductContext.get_product_coverage(product.id)
    render(
      conn,
      "step4.html",
      product: product,
      changeset: changeset,
      # facilities: facilities,
      location_group: location_group,
      product_coverages: product_coverages
    )
  end

  def step4_update(conn, product, product_params) do
    # Updates ProductCoverageFacility records according to its coverage.

    location_group = LocationGroupContext.get_all_location_group()
    # facilities = ProductContext.get_list_of_facilities()
    product_coverages = ProductContext.get_product_coverage(product.id)
    product_params =
      product_params
      |> Map.put("step", "4")
      |> Map.put("updated_by_id", conn.assigns.current_user.id)
    _coverages = ProductContext.get_product_coverage(product.id)
    product_coverage_id = product_params["product_coverage_id"]
    changeset =
      %ProductCoverageFacility{}
      |> ProductCoverageFacility.changeset()
      |> Map.delete(:action)
      |> Map.put(:action, "insert")

    facility = String.split(product_params["facility_ids_main"], ",")
    facility = Enum.uniq(facility)
    if facility == [""] do
      conn
      |> put_flash(:error, "At least one facility must be added.")
      |> render(
        "step4.html",
        changeset: changeset,
        product: product,
        # facilities: facilities,
        location_group: location_group,
        product_coverages: product_coverages,
        modal_open: true
      )
    else
      current_pcf = ProductContext.check_pcf(product_coverage_id)
      if current_pcf == facility do
        conn
        |> put_flash(:error, "At least one facility must be added.")
        |> render(
          "step4.html",
          changeset: changeset,
          product: product,
          # facilities: facilities,
          location_group: location_group,
          product_coverages: product_coverages,
          modal_open: true
        )
      else
        ProductContext.clear_product_facility(product_coverage_id)
        ProductContext.set_product_facility(product_coverage_id, facility)
        ProductContext.update_product_step(product, product_params)
        conn
        |> put_flash(:info, "Successfully added facility plans!")
        |> redirect(to: "/products/#{product.id}/setup?step=4")
      end
    end
  end

  def step4_update_peme(conn, product, product_params) do
    # Updates ProductCoverageFacility records according to its coverage.

    location_group = LocationGroupContext.get_all_location_group()
    facilities = ProductContext.get_list_of_facilities()
    product_coverages = ProductContext.get_product_coverage(product.id)
    product_params =
      product_params
      |> Map.put("step", "5")
      |> Map.put("updated_by_id", conn.assigns.current_user.id)
    _coverages = ProductContext.get_product_coverage(product.id)
    product_coverage_id = product_params["product_coverage_id"]
    changeset =
      %ProductCoverageFacility{}
      |> ProductCoverageFacility.changeset()
      |> Map.delete(:action)
      |> Map.put(:action, "insert")

    facility = String.split(product_params["facility_ids_main"], ",")
    facility = Enum.uniq(facility)
    if facility == [""] do
      conn
      |> put_flash(:error, "At least one facility must be added.")
      |> render(
        "step4_peme.html",
        changeset: changeset,
        product: product,
        facilities: facilities,
        location_group: location_group,
        product_coverages: product_coverages,
        modal_open: true
      )
    else
      current_pcf = ProductContext.check_pcf(product_coverage_id)
      if current_pcf == facility do
        conn
        |> put_flash(:error, "At least one facility must be added.")
        |> render(
          "step4_peme.html",
          changeset: changeset,
          product: product,
          facilities: facilities,
          location_group: location_group,
          product_coverages: product_coverages,
          modal_open: true
        )
      else
        ProductContext.clear_product_facility(product_coverage_id)
        ProductContext.set_product_facility(product_coverage_id, facility)
        ProductContext.update_product_step(product, product_params)
        conn
        |> put_flash(:info, "Successfully added facility plan!")
        |> redirect(to: "/products/#{product.id}/setup?step=4")
      end
    end
  end

  def insert_coverage_type(conn, %{"product_coverage_id" => product_coverage_id, "type" => type, "product_id" => product_id, "coverage_id" => coverage_id}) do
    # Inserts coverage type.

    product_coverage = ProductContext.get_product_coverage_by_id(product_coverage_id)
    params = %{
      type: type,
      coverage_id: coverage_id,
      product_id: product_id
    }
    ProductContext.set_product_coverage_type(product_coverage, params)
    json conn, Poison.encode!(%{valid: true})
  end

  def update_product_coverage(conn, %{"product_id" => product_id, "coverage_id" => coverage_id}) do
    product = ProductContext.get_product!(product_id)
    ProductContext.update_product_facility_coverage(product, coverage_id)
    json conn, Poison.encode!(%{valid: true})
  end

  def edit_facility_access(conn, product) do
    facilities = ProductContext.get_list_of_facilities()
    changeset = ProductCoverageFacility.changeset(%ProductCoverageFacility{})
    location_group = LocationGroupContext.get_all_location_group()

    product_coverages = ProductContext.get_product_coverage(product.id)
    render(
      conn,
      "edit/product_facility.html",
      product: product,
      changeset: changeset,
      facilities: facilities,
      location_group: location_group,
      product_coverages: product_coverages
    )
  end

  def update_facility_access(conn, product, product_params) do
    # Updates ProductCoverageFacility records according to its coverage.

    location_group = LocationGroupContext.get_all_location_group()
    facilities = ProductContext.get_list_of_facilities()
    product_coverages = ProductContext.get_product_coverage(product.id)
    product_params =
      product_params
      |> Map.put("updated_by_id", conn.assigns.current_user.id)
    _coverages = ProductContext.get_product_coverage(product.id)
    product_coverage_id = product_params["product_coverage_id"]
    changeset =
      %ProductCoverageFacility{}
      |> ProductCoverageFacility.changeset()
      |> Map.delete(:action)
      |> Map.put(:action, "insert")

    facility = String.split(product_params["facility_ids_main"], ",")
    facility = Enum.uniq(facility)
    if facility == [""] do
      conn
      |> put_flash(:error, "Please select at least one facility.")
      |> render(
        "edit/product_facility.html",
        changeset: changeset,
        product: product,
        facilities: facilities,
        location_group: location_group,
        product_coverages: product_coverages,
        modal_open: true
      )
    else
      ProductContext.clear_product_facility(product_coverage_id)
      ProductContext.set_product_facility(product_coverage_id, facility)
      ProductContext.update_product_step(product, product_params)
      conn
      |> put_flash(:info, "Successfully added facility plan!")
      |> redirect(to: "/products/#{product.id}/edit?tab=facility_access")
    end
  end

  def get_pcf(conn, params) when not is_nil(params) do
    with {:ok, pcf} <- ProductContext.get_pcf(params["product_coverage_id"])
    do
      render(conn, Innerpeace.PayorLink.Web.ProductView, "load_pcf.json", pcf: pcf)
    else
      _ ->
        render(conn, Innerpeace.PayorLink.Web.ProductView, "load_pcf.json", pcf: [])
    end
  end

   def get_pcf(conn, params) when is_nil(params) do
     conn
     |> put_flash(:info, "Incorrect entry.")
     |> redirect(to: "/")
   end


  def get_pcf_by_search(conn, params) do
    pcf = ProductContext.get_pcf_by_search(params["product_coverage_id"], params["datatable_params"])
    render(conn, Innerpeace.PayorLink.Web.ProductView, "load_pcf.json", pcf: pcf)
  end

  def get_pcf_by_region(conn, params) do
    pcf = ProductContext.get_pcf_by_region(params["product_coverage_id"], params["regions"])
    render(conn, Innerpeace.PayorLink.Web.ProductView, "load_pcf.json", pcf: pcf)
  end
  ########################## END -- Functions regarding Facility Access

  ########################## START -- Functions regarding Condition.

  def step5(conn, product) do
    rooms = RoomContext.list_all_rooms()
    changeset_condition = Product.changeset_condition(product)
    product_coverages = ProductContext.get_product_coverage(product.id)
    product_coverages_rnb = ProductContext.get_product_coverages_rnb(product)
    checker_product_coverages_lt = ProductContext.get_product_coverages_lt(product)
    changeset_product_coverage_lt =
      %ProductCoverageLimitThresholdFacility{}
      |> ProductCoverageLimitThresholdFacility.changeset()

    if checker_product_coverages_lt == [] do
      if product.product_base == "Benefit-based" do
        ProductContext.set_product_coverage(product)
      else
        coverage_ids = ProductContext.get_product_coverage_ids(product.id)
        ProductContext.set_coverage(product.id, coverage_ids)
      end
    end

    product_coverages_lt = ProductContext.get_product_coverages_lt(product)
    render(conn,
           "step5.html",
           changeset_condition: changeset_condition,
           product: product,
           product_coverages_rnb: product_coverages_rnb,
           product_coverages: product_coverages,
           product_coverages_lt: product_coverages_lt,
           changeset_product_coverage_lt: changeset_product_coverage_lt,
           rooms: rooms
    )
  end

  def step3_peme(conn, product) do
    rooms = RoomContext.list_all_rooms()
    changeset_condition = Product.changeset_condition(product)
    product_coverages = ProductContext.get_product_coverage(product.id)
    product_coverages_rnb = ProductContext.get_product_coverages_rnb(product)
    checker_product_coverages_lt = ProductContext.get_product_coverages_lt(product)
    changeset_product_coverage_lt =
      %ProductCoverageLimitThresholdFacility{}
      |> ProductCoverageLimitThresholdFacility.changeset()

    if checker_product_coverages_lt == [] do
      if product.product_base == "Benefit-based" do
        ProductContext.set_product_coverage(product)
      else
        coverage_ids = ProductContext.get_product_coverage_ids(product.id)
        ProductContext.set_coverage(product.id, coverage_ids)
      end
    end

    product_coverages_lt = ProductContext.get_product_coverages_lt(product)
    render(conn,
           "step3_peme.html",
           changeset_condition: changeset_condition,
           product: product,
           product_coverages_rnb: product_coverages_rnb,
           product_coverages: product_coverages,
           product_coverages_lt: product_coverages_lt,
           changeset_product_coverage_lt: changeset_product_coverage_lt,
           rooms: rooms
    )
  end

  def step3_update_peme(conn, product, product_params) do
    rooms = RoomContext.list_all_rooms()
    _changeset_condition = Product.changeset_condition(product)
    product_coverages = ProductContext.get_product_coverage(product.id)
    product_params =
      product_params
      |> Map.put("step", "4")
      |> Map.put("updated_by_id", conn.assigns.current_user.id)
    product_coverages_rnb = ProductContext.get_product_coverages_rnb(product)
    product_coverages_lt = ProductContext.get_product_coverages_lt(product)
    changeset_product_coverage_lt =
      %ProductCoverageLimitThresholdFacility{}
      |> ProductCoverageLimitThresholdFacility.changeset()
    ##### for Saving "Age Eligibility, Deductions, Funding
    married_employee = product_params["married_employee"]
    single_employee = product_params["single_employee"]
    single_parent_employee = product_params["single_parent_employee"]

    if married_employee == "" do
      conn
      |> put_flash(:error, "Please enter atleast one Married Employee Dependent.")
      |> redirect(to: "/products/#{product.id}/setup?step=3")
    else
      if single_employee == "" do
        conn
        |> put_flash(:error, "Please enter atleast one Single Employee Dependent.")
        |> redirect(to: "/products/#{product.id}/setup?step=3")
      else
        if single_parent_employee == "" do
          conn
          |> put_flash(:error, "Please enter atleast one Single Parent Employee Dependent.")
          |> redirect(to: "/products/#{product.id}/setup?step=3")
        else
          product_params = if Map.has_key?(product_params, "no_outright_denial") do
            Map.put(product_params, "no_outright_denial", true)
          else
            Map.merge(product_params, %{"no_outright_denial" => false})
          end

          product_params = if Map.has_key?(product_params, "loa_facilitated") do
            Map.put(product_params, "loa_facilitated", true)
          else
            Map.merge(product_params, %{"loa_facilitated" => false})
          end

          product_params = if Map.has_key?(product_params, "reimbursement") do
            Map.put(product_params, "reimbursement", true)
          else
            Map.merge(product_params, %{"reimbursement" => false})
          end
          case ProductContext.update_product_condition(product, product_params) do
            {:ok, product} ->
              ProductContext.set_product_coverage_funding(product, product_params)
              ProductContext.update_product_step(product, product_params)
              ProductContext.clear_product_condition_hierarchy(product.id)
              if Enum.member?(product.member_type, "Principal") do
                insert_hoed(product.id, married_employee, "Married Employee")
                insert_hoed(product.id, single_employee, "Single Employee")
                insert_hoed(product.id, single_parent_employee, "Single Parent Employee")
              end

              if product_params["rnb_array"] != "" do
                ProductContext.update_pc_rnb_batch(product_params)
              end

              case ProductContext.update_pclt(product, product_params) do
                {:ok} ->
                  product
                  |> Repo.preload([product_coverages: :coverage])

                  pc =
                    product.product_coverages
                    |> Enum.filter(&(&1.coverage.name == "PEME"))
                    |> List.first()

                    if not is_nil(pc) do
                      coverage = pc.coverage.name

                      redirect_step5(conn, product, coverage)
                    else
                      conn
                      |> put_flash(:info, "Age Eligibility, Deductions, Funding updated successfully.")
                      |> redirect(to: "/products/#{product.id}/setup?step=4")
                    end

                _ ->
                  if product.product_base == "Benefit-based" do
                    ProductContext.set_product_coverage(product)
                  else
                    coverage_ids = ProductContext.get_product_coverage_ids(product.id)
                    ProductContext.set_coverage(product.id, coverage_ids)
                  end
                  conn
                  |> put_flash(:info, "Limit Threshold was just generated for this plan. You can enter or skip limit threshold.")
                  |> redirect(to: "/products/#{product.id}/setup?step=3")
              end
            {:error, %Ecto.Changeset{} = changeset_condition} ->
              conn
              |> put_flash(:error, "Please check your inputs.")
              |> render("step3_peme.html",
                        changeset_condition: changeset_condition,
                        product: product,
                        product_coverages_rnb: product_coverages_rnb,
                        product_coverages: product_coverages,
                        product_coverages_lt: product_coverages_lt,
                        changeset_product_coverage_lt: changeset_product_coverage_lt,
                        rooms: rooms
              )
          end
        end
      end
    end

  end

  def step5_update(conn, product, product_params) do
    rooms = RoomContext.list_all_rooms()
    _changeset_condition = Product.changeset_condition(product)
    product_coverages = ProductContext.get_product_coverage(product.id)
    product_params =
      product_params
      |> Map.put("step", "6")
      |> Map.put("updated_by_id", conn.assigns.current_user.id)
    product_coverages_rnb = ProductContext.get_product_coverages_rnb(product)
    product_coverages_lt = ProductContext.get_product_coverages_lt(product)
    changeset_product_coverage_lt =
      %ProductCoverageLimitThresholdFacility{}
      |> ProductCoverageLimitThresholdFacility.changeset()
    ##### for Saving "Age Eligibility, Deductions, Funding
    married_employee = product_params["married_employee"]
    single_employee = product_params["single_employee"]
    single_parent_employee = product_params["single_parent_employee"]

    if married_employee == "" do
      conn
      |> put_flash(:error, "Please enter atleast one Married Employee Dependent.")
      |> redirect(to: "/products/#{product.id}/setup?step=5")
    else
      if single_employee == "" do
        conn
        |> put_flash(:error, "Please enter atleast one Single Employee Dependent.")
        |> redirect(to: "/products/#{product.id}/setup?step=5")
      else
        if single_parent_employee == "" do
          conn
          |> put_flash(:error, "Please enter atleast one Single Parent Employee Dependent.")
          |> redirect(to: "/products/#{product.id}/setup?step=5")
        else
          product_params = if Map.has_key?(product_params, "no_outright_denial") do
            Map.put(product_params, "no_outright_denial", true)
          else
            Map.merge(product_params, %{"no_outright_denial" => false})
          end

          product_params = if Map.has_key?(product_params, "loa_facilitated") do
            Map.put(product_params, "loa_facilitated", true)
          else
            Map.merge(product_params, %{"loa_facilitated" => false})
          end

          product_params = if Map.has_key?(product_params, "reimbursement") do
            Map.put(product_params, "reimbursement", true)
          else
            Map.merge(product_params, %{"reimbursement" => false})
          end
          case ProductContext.update_product_condition(product, product_params) do
            {:ok, product} ->
              ProductContext.set_product_coverage_funding(product, product_params)
              ProductContext.update_product_step(product, product_params)
              ProductContext.clear_product_condition_hierarchy(product.id)
              if Enum.member?(product.member_type, "Principal") do
                insert_hoed(product.id, married_employee, "Married Employee")
                insert_hoed(product.id, single_employee, "Single Employee")
                insert_hoed(product.id, single_parent_employee, "Single Parent Employee")
              end

              if product_params["rnb_array"] != "" do
                ProductContext.update_pc_rnb_batch(product_params)
              end

              case ProductContext.update_pclt(product, product_params) do
                {:ok} ->
                  product
                  |> Repo.preload([product_coverages: :coverage])

                  pc =
                    product.product_coverages
                    |> Enum.filter(&(&1.coverage.name == "PEME"))
                    |> List.first()

                    if not is_nil(pc) do
                      coverage = pc.coverage.name

                      redirect_step5(conn, product, coverage)
                    else
                      conn
                      |> put_flash(:info, "Age Eligibility, Deductions, Funding updated successfully.")
                      |> redirect(to: "/products/#{product.id}/setup?step=6")
                    end

                _ ->
                  if product.product_base == "Benefit-based" do
                    ProductContext.set_product_coverage(product)
                  else
                    coverage_ids = ProductContext.get_product_coverage_ids(product.id)
                    ProductContext.set_coverage(product.id, coverage_ids)
                  end
                  conn
                  |> put_flash(:info, "Limit Threshold was just generated for this plan. You can enter or skip limit threshold.")
                  |> redirect(to: "/products/#{product.id}/setup?step=5")
              end
            {:error, %Ecto.Changeset{} = changeset_condition} ->
              conn
              |> put_flash(:error, "Please check your inputs.")
              |> render("step5.html",
                        changeset_condition: changeset_condition,
                        product: product,
                        product_coverages_rnb: product_coverages_rnb,
                        product_coverages: product_coverages,
                        product_coverages_lt: product_coverages_lt,
                        changeset_product_coverage_lt: changeset_product_coverage_lt,
                        rooms: rooms
              )
          end
        end
      end
    end

  end

  defp redirect_step5(conn, product, coverage) when coverage == "PEME" do
    conn
    # |> put_flash(:info, "Age Eligibility, Deductions, Funding updated successfully.")
    |> redirect(to: "/products/#{product.id}/setup?step=4")
  end

  defp redirect_step5(conn, product, coverage) when coverage != "PEME" do
    conn
    |> put_flash(:info, "Age Eligibility, Deductions, Funding updated successfully.")
    |> redirect(to: "/products/#{product.id}/setup?step=6")
  end

  def insert_hoed(product_id, dependent_string_array, hierarchy_type) do
    dependent_array = String.split(dependent_string_array, ",")

    for dependent <- dependent_array do
      dependent_record = String.split(dependent, "-")
      dependent = Enum.at(dependent_record, 1)
      ranking = Enum.at(dependent_record, 0)

      ProductContext.insert_product_condition_hierarchy(product_id, hierarchy_type, dependent, ranking)
    end
  end

  def step5_update_rnb(conn, product, product_params) do
    _changeset_condition = Product.changeset_condition(product)
    _product_coverages = ProductContext.get_product_coverage(product.id)
    product_params =
      product_params
      |> Map.put("step", "6")
      |> Map.put("updated_by_id", conn.assigns.current_user.id)
    _product_coverages_rnb = ProductContext.get_product_coverages_rnb(product)
    pc_rnb = ProductContext.get_pc_rnb(product_params["product_coverage_room_and_board_id"])
    ProductContext.update_pc_rnb(pc_rnb, product_params)
    ProductContext.update_product_step(product, product_params)
    conn
    |> put_flash(:info, "Plan Condition Room and board updated successfully.")
    |> redirect(to: "/products/#{product.id}/setup?step=5")
  end

  def step5_update_lt(conn, %{"product_id" => _id, "product_params" => product_params}) do
    facility_id = product_params["facility_id"]
    limit_threshold = product_params["limit_threshold"]
    pclt_id = product_params["pclt_id"]
    pcltf_id = product_params["pcltf_id"]

    if product_params["pcltf_id"] != "" do
      case ProductContext.update_pcltf(pcltf_id, pclt_id, facility_id, limit_threshold) do
        {:ok, _product_coverage_limit_threshold_facility} ->
          pcltf = ProductContext.get_all_pcltf_by_pclt(pclt_id)
          render(conn, Innerpeace.PayorLink.Web.ProductView, "pcltf.json", pcltf: pcltf)
        _ ->
          json conn, Poison.encode!(%{result: "failed"})
      end
    else
      case ProductContext.insert_pcltf(pclt_id, facility_id, limit_threshold) do
        {:ok, _product_coverage_limit_threshold_facility} ->
          pcltf = ProductContext.get_all_pcltf_by_pclt(pclt_id)
          render(conn, Innerpeace.PayorLink.Web.ProductView, "pcltf.json", pcltf: pcltf)
        _ ->
          json conn, Poison.encode!(%{result: "failed"})
      end
    end

  end

  def get_product_condition(conn, _params) do
    changeset_general = Product.changeset_general(%Product{})
    render(conn, "step5.html", changeset_general: changeset_general)
  end

  def edit_condition(conn, product) do
    rooms = RoomContext.list_all_rooms()
    changeset_condition = Product.changeset_condition(product)
    product_coverages = ProductContext.get_product_coverage(product.id)
    product_coverages_rnb = ProductContext.get_product_coverages_rnb(product)
    checker_product_coverages_lt = ProductContext.get_product_coverages_lt(product)
    changeset_product_coverage_lt =
      %ProductCoverageLimitThresholdFacility{}
      |> ProductCoverageLimitThresholdFacility.changeset()

    if checker_product_coverages_lt == [] do
      if product.product_base == "Benefit-based" do
        ProductContext.set_product_coverage(product)
      else
        coverage_ids = ProductContext.get_product_coverage_ids(product.id)
        ProductContext.set_coverage(product.id, coverage_ids)
      end
    end

    product_coverages_lt = ProductContext.get_product_coverages_lt(product)
    render(conn,
           "edit/condition.html",
           changeset_condition: changeset_condition,
           product: product,
           product_coverages_rnb: product_coverages_rnb,
           product_coverages_lt: product_coverages_lt,
           product_coverages: product_coverages,
           changeset_product_coverage_lt: changeset_product_coverage_lt,
           rooms: rooms
    )
  end

  def update_condition(conn, product, product_params) do
    rooms = RoomContext.list_all_rooms()
    _changeset_condition = Product.changeset_condition(product)
    product_coverages = ProductContext.get_product_coverage(product.id)
    product_params =
      product_params
      |> Map.put("updated_by_id", conn.assigns.current_user.id)
    product_coverages_rnb = ProductContext.get_product_coverages_rnb(product)
    product_coverages_lt = ProductContext.get_product_coverages_lt(product)

    changeset_product_coverage_lt =
      %ProductCoverageLimitThresholdFacility{}
      |> ProductCoverageLimitThresholdFacility.changeset()

    ##### for Saving "Age Eligibility, Deductions, Funding
    married_employee = product_params["married_employee"]
    single_employee = product_params["single_employee"]
    single_parent_employee = product_params["single_parent_employee"]

    if married_employee == "" do
      conn
      |> put_flash(:error, "Please enter atleast one Married Employee Dependent.")
      |> redirect(to: "/products/#{product.id}/edit?tab=condition")
    else
      if single_employee == "" do
        conn
        |> put_flash(:error, "Please enter atleast one Single Employee Dependent.")
        |> redirect(to: "/products/#{product.id}/edit?tab=condition")
      else
        if single_parent_employee == "" do
          conn
          |> put_flash(:error, "Please enter atleast one Single Parent Employee Dependent.")
          |> redirect(to: "/products/#{product.id}/edit?tab=condition")
        else
          product_params = if Map.has_key?(product_params, "no_outright_denial") do
            Map.put(product_params, "no_outright_denial", true)
          else
            Map.merge(product_params, %{"no_outright_denial" => false})
          end
          product_params = if Map.has_key?(product_params, "loa_facilitated") do
            Map.put(product_params, "loa_facilitated", true)
          else
            Map.merge(product_params, %{"loa_facilitated" => false})
          end

          product_params = if Map.has_key?(product_params, "reimbursement") do
            Map.put(product_params, "reimbursement", true)
          else
            Map.merge(product_params, %{"reimbursement" => false})
          end
          case ProductContext.update_product_condition(product, product_params) do
            {:ok, product} ->
              ProductContext.set_product_coverage_funding(product, product_params)
              ProductContext.update_product_step(product, product_params)

              ProductContext.clear_product_condition_hierarchy(product.id)
              if Enum.member?(product.member_type, "Principal") do
                insert_hoed(product.id, married_employee, "Married Employee")
                insert_hoed(product.id, single_employee, "Single Employee")
                insert_hoed(product.id, single_parent_employee, "Single Parent Employee")
              end

              if product_params["rnb_array"] != "" do
                ProductContext.update_pc_rnb_batch(product_params)
              end

              if product_params["outer_limit_threshold"] == "" do
                 conn
                    |> put_flash(:info, "Age Eligibility, Deductions, Funding updated successfully.")
                    |> redirect(to: "/products/#{product.id}/edit?tab=condition")
              else
                case ProductContext.update_pclt(product, product_params) do
                  {:ok} ->
                    conn
                    |> put_flash(:info, "Age Eligibility, Deductions, Funding updated successfully.")
                    |> redirect(to: "/products/#{product.id}/edit?tab=condition")
                  _ ->
                    if product.product_base == "Benefit-based" do
                      ProductContext.set_product_coverage(product)
                    else
                      coverage_ids = ProductContext.get_product_coverage_ids(product.id)
                      ProductContext.set_coverage(product.id, coverage_ids)
                    end
                    conn
                    |> put_flash(:error, "Please enter a limit threshold.")
                    |> redirect(to: "/products/#{product.id}/edit?tab=condition")
                end
              end
            {:error, %Ecto.Changeset{} = changeset_condition} ->
              conn
              |> put_flash(:error, "Please check your inputs.")
              |> render("edit/condition.html",
                        changeset_condition: changeset_condition,
                        product: product,
                        product_coverages_rnb: product_coverages_rnb,
                        product_coverages: product_coverages,
                        product_coverages_lt: product_coverages_lt,
                        changeset_product_coverage_lt: changeset_product_coverage_lt,
                        rooms: rooms
              )
          end
        end
      end
    end
  end

  def filter_pcltf(conn, %{"product_limit_threshold_id" => product_coverage_limit_threshold_id}) do
    ## ongoing
    facilities = ProductContext.get_product_limit_threshold(product_coverage_limit_threshold_id)
    json conn, Poison.encode!(facilities)
  end

  def filter_pcltf_edit(conn, %{"product_limit_threshold_id" => product_coverage_limit_threshold_id}) do
    facilities = ProductContext.get_product_limit_threshold_edit(product_coverage_limit_threshold_id)
    json conn, Poison.encode!(facilities)
  end

  def delete_pcltf(conn, %{"pcltf_id" => pcltf_id}) do
    pclt_f = ProductContext.get_pclt_by_pcltf(pcltf_id)
    pclt_id = pclt_f.product_coverage_limit_threshold_id
    ProductContext.delete_pcltf(pcltf_id)
    pcltf = ProductContext.get_all_pcltf_by_pclt(pclt_id)
    render(conn, Innerpeace.PayorLink.Web.ProductView, "pcltf.json", pcltf: pcltf)
  end

  def check_pclt(conn, %{"product_coverage_id" => product_coverage_id}) do
    case ProductContext.check_pclt(product_coverage_id) do
      {:ok} ->
        json conn, Poison.encode!(%{result: "ok"})
      {:has_data} ->
        json conn, Poison.encode!(%{result: "has_data"})
      {:no_lt} ->
        json conn, Poison.encode!(%{result: "no_lt"})
    end
  end

  ########################## END -- Functions regarding Condition.
  def update_condition_rnb(conn, product, product_params) do
    _changeset_condition = Product.changeset_condition(product)
    _product_coverages = ProductContext.get_product_coverage(product.id)
    product_params =
      product_params
      |> Map.put("updated_by_id", conn.assigns.current_user.id)
    _product_coverages_rnb = ProductContext.get_product_coverages_rnb(product)
    pc_rnb = ProductContext.get_pc_rnb(product_params["product_coverage_room_and_board_id"])
    ProductContext.update_pc_rnb(pc_rnb, product_params)
    ProductContext.update_product_step(product, product_params)
    conn
    |> put_flash(:info, "Plan Condition Room and board updated successfully.")
    |> redirect(to: "/products/#{product.id}/edit?tab=condition")
  end

  ########################## START -- Functions regarding Risk Share.

  def step6(conn, product) do
    standard_facility = ProductContext.get_list_of_facilities()
    standard_procedure = ProductContext.get_facility_payor_procedure(product)
    product_risk_share = ProductContext.get_product_risk_shares(product)
    changeset = ProductCoverageRiskShare.changeset(%ProductCoverageRiskShare{})
    changeset_risk_share_facility = ProductCoverageRiskShareFacility.changeset(%ProductCoverageRiskShareFacility{})
    delete_facility = ProductCoverageRiskShareFacility.changeset(%ProductCoverageRiskShareFacility{})
    changeset_risk_share_facility_procedure =
      %ProductCoverageRiskShareFacility{}
      |> ProductCoverageRiskShareFacility.changeset()
    product_coverages = ProductContext.get_product_coverage(product.id)
    _changeset_general = Product.changeset_general(%Product{})
    render(conn, "step6.html",
           product: product,
           product_risk_share: product_risk_share,
           product_coverages: product_coverages,
           changeset: changeset,
           changeset_risk_share_facility: changeset_risk_share_facility,
           standard_facility: standard_facility,
           changeset_risk_share_facility_procedure: changeset_risk_share_facility_procedure,
           standard_procedure: standard_procedure,
           delete_facility: delete_facility
    )
  end

  def step6_update(conn, product, product_params) do
    af_type = product_params["af_type"]
    af_value = product_params["af_value"]
    af_covered = product_params["af_covered"]

    cond do
      af_type == "N/A" ->
        if af_covered == "" do
          step6_put_flash_error(conn, product.id)
        else
          validate_naf(conn, product, product_params)
        end
      af_type == "Copayment" ->
        if af_value == "" or af_covered == "" do
          step6_put_flash_error(conn, product.id)
        else
          validate_naf(conn, product, product_params)
        end
      af_type == "CoInsurance" ->
        if af_value == "" or af_covered == "" do
          step6_put_flash_error(conn, product.id)
        else
          validate_naf(conn, product, product_params)
        end
      true ->
        step6_update_validated(conn, product, product_params)
    end

  end

  defp step6_put_flash_error(conn, product_id) do
    conn
    |> put_flash(:error, "Please complete your inputs in this Risk Share")
    |> redirect(to: "/products/#{product_id}/setup?step=6")
  end

  defp validate_naf(conn, product, product_params) do
    naf_type = product_params["naf_type"]
    naf_value = product_params["naf_value"]
    naf_covered = product_params["naf_covered"]

    cond do
      naf_type == "N/A" ->
        if naf_covered == "" do
          step6_put_flash_error(conn, product.id)
        else
          step6_update_validated(conn, product, product_params)
        end
      naf_type == "Copayment" ->
        if naf_value == "" or naf_covered == "" do
          step6_put_flash_error(conn, product.id)
        else
          step6_update_validated(conn, product, product_params)
        end
      naf_type == "CoInsurance" ->
        if naf_value == "" or naf_covered == "" do
          conn
          |> put_flash(:error, "Please complete your inputs in this Risk Share")
          |> redirect(to: "/products/#{product.id}/setup?step=6")
        else
          step6_update_validated(conn, product, product_params)
        end
      true ->
        step6_update_validated(conn, product, product_params)
    end
  end

  defp step6_update_validated(conn, product, product_params) do
    product_params =
      product_params
      |> Map.put("updated_by_id", conn.assigns.current_user.id)
    product_risk_share = ProductContext.get_product_risk_shares(product)
    risk_share = ProductContext.get_product_risk_share(product_params["risk_share_id"])
    _changeset = ProductCoverageRiskShare.changeset(risk_share)
    case ProductContext.update_product_risk_share(risk_share, product_params) do
      {:ok, _product_risk_share} ->
        ProductContext.update_product_step(product, product_params)
        conn
        |> put_flash(:info, "Risk Share successfully saved.")
        |> redirect(to: "/products/#{product.id}/setup?step=6")
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Please complete your fields in this Risk Share form.")
        |> render("step6.html", product: product, product_risk_share: product_risk_share, changeset: changeset)
    end
  end

  def step6_rs_facility_update(conn, product, product_params) do
    pcrs_id = product_params["product_risk_share_id"]
    product_params =
      product_params
      |> Map.put("updated_by_id", conn.assigns.current_user.id)
      |> Map.put("product_coverage_risk_share_id", pcrs_id)
    product_risk_share = ProductContext.get_product_risk_shares(product)
    risk_share = ProductContext.get_product_risk_share(product_params["product_risk_share_id"])
    _changeset = ProductCoverageRiskShare.changeset(risk_share)
    case ProductContext.set_product_risk_share_facility(product_params) do
      {:ok, _product_risk_share} ->
        ProductContext.update_product_step(product, product_params)
        conn
        |> put_flash(:info, "Risk Share Facility successfully saved.")
        |> redirect(to: "/products/#{product.id}/setup?step=6")
      {:error, %Ecto.Changeset{} = changeset} ->
        render(
          conn,
          "step6.html",
          product: product,
          product_risk_share: product_risk_share,
          changeset: changeset,
          modal_open: true
        )
      _ ->
        conn
        |> redirect(to: "/products/#{product.id}/setup?step=6")
    end
  end

  def step6_rs_procedure_update(conn, product, product_params) do
    product_params =
      product_params
      |> Map.put("updated_by_id", conn.assigns.current_user.id)
    product_risk_share = ProductContext.get_product_risk_shares(product)
    risk_share_facility = ProductContext.get_product_risk_share_facility(product_params["product_risk_share_facility_id"])
    risk_share = ProductContext.get_product_risk_share(risk_share_facility.product_coverage_risk_share_id)
    _changeset = ProductCoverageRiskShare.changeset(risk_share)
    case ProductContext.set_product_risk_share_facility_procedure(product_params) do
      {:ok, _product_risk_share_procedure} ->
        ProductContext.update_product_step(product, product_params)
        conn
        |> put_flash(:info, "Risk Share Procedure successfully saved.")
        |> redirect(to: "/products/#{product.id}/setup?step=6")
      {:error, %Ecto.Changeset{} = changeset} ->
        render(
          conn,
          "step6.html",
          product: product,
          product_risk_share: product_risk_share,
          changeset: changeset,
          modal_open: true
        )
      _ ->
        conn
        |> redirect(to: "/products/#{product.id}/setup?step=6")
    end
  end

  def get_product_risk_share(conn, %{"product_risk_share_id" => product_risk_share_id}) do
    get_product_risk_share = ProductContext.get_product_risk_share(product_risk_share_id)
    json conn, Poison.encode!(get_product_risk_share)
  end

  def get_product_rs_facility(conn, %{"product_risk_share_id" => product_risk_share_id, "facility_id" => facility_id}) do
    get_product_rs_facility = ProductContext.get_product_riskshare_facility(product_risk_share_id, facility_id)
    json conn, Poison.encode!(get_product_rs_facility)
  end

  def get_product_risk_share_facility(conn, %{"product_risk_share_facility_id" => product_risk_share_facility_id}) do
    get_product_risk_share_facility = ProductContext.get_product_risk_share_facility(product_risk_share_facility_id)
    json conn, Poison.encode!(get_product_risk_share_facility)
  end

  def get_prsf_procedure(conn, %{"product_risk_share_facility_id" => product_risk_share_facility_id, "procedure_id" => procedure_id}) do
    get_prsf_procedure =
      ProductContext.get_product_riskshare_facility_procedure(
        product_risk_share_facility_id,
        procedure_id)
    json conn, Poison.encode!(get_prsf_procedure)
  end

  def delete_prs_facility(conn, %{"id" => id}) do
    ProductContext.clear_prs_facility(id)
    json conn, Poison.encode!(%{valid: true})
  end

  def get_product_facilities(conn, %{"product_facility_id" => product_facility_id}) do
    product_facility = ProductContext.get_product_facility(product_facility_id)
    json conn, Poison.encode!(product_facility)
  end

  def deleting_product_facilities(conn, %{"product_coverage_id" => product_coverage_id}) do
     _product_facility = ProductContext.delete_product_facilities(product_coverage_id)
     json conn, Poison.encode!(%{valid: true})
  end

  def deleting_product_facility(conn, %{"product_facility_id" => product_facility_id}) do
     _product_facility = ProductContext.delete_product_facility(product_facility_id)
     json conn, Poison.encode!(%{valid: true})
  end

  def update_prsf_coverage(conn, %{"product_id" => product_id, "coverage_id" => coverage_id}) do
    product = ProductContext.get_product!(product_id)
    ProductContext.update_product_prsf_coverage(product, coverage_id)
    json conn, Poison.encode!(%{valid: true})
  end

  def delete_prsf_procedure(conn, %{"id" => id}) do
    ProductContext.clear_prsf_procedure(id)
    json conn, Poison.encode!(%{valid: true})
  end

  def edit_risk_share(conn, product) do
    standard_facility = ProductContext.get_list_of_facilities()
    standard_procedure = ProductContext.get_facility_payor_procedure(product)
    product_risk_share = ProductContext.get_product_risk_shares(product)
    changeset = ProductCoverageRiskShare.changeset(%ProductCoverageRiskShare{})
    changeset_risk_share_facility = ProductCoverageRiskShareFacility.changeset(%ProductCoverageRiskShareFacility{})
    delete_facility = ProductCoverageRiskShareFacility.changeset(%ProductCoverageRiskShareFacility{})
    changeset_risk_share_facility_procedure =
      %ProductCoverageRiskShareFacility{}
      |> ProductCoverageRiskShareFacility.changeset()
    product_coverages = ProductContext.get_product_coverage(product.id)
    _changeset_general = Product.changeset_general(%Product{})
    render(conn, "edit/risk_share.html",
           product: product,
           product_risk_share: product_risk_share,
           product_coverages: product_coverages,
           changeset: changeset,
           changeset_risk_share_facility: changeset_risk_share_facility,
           standard_facility: standard_facility,
           changeset_risk_share_facility_procedure: changeset_risk_share_facility_procedure,
           standard_procedure: standard_procedure,
           delete_facility: delete_facility
    )
  end

  def update_risk_share(conn, product, product_params) do
    af_type = product_params["af_type"]
    af_value = product_params["af_value"]
    af_covered = product_params["af_covered"]

    cond do
      af_type == "N/A" ->
        if af_covered == "" do
          update_rs_put_flash_error(conn, product.id)
        else
          update_rs_validate_naf(conn, product, product_params)
        end
      af_type == "Copayment" ->
        if af_value == "" or af_covered == "" do
          update_rs_put_flash_error(conn, product.id)
        else
          update_rs_validate_naf(conn, product, product_params)
        end
      af_type == "CoInsurance" ->
        if af_value == "" or af_covered == "" do
          update_rs_put_flash_error(conn, product.id)
        else
          update_rs_validate_naf(conn, product, product_params)
        end
      true ->
        edit_rs_update_validated(conn, product, product_params)
    end
  end

  defp update_rs_put_flash_error(conn, product_id) do
    conn
    |> put_flash(:error, "Please complete your inputs in this Risk Share")
    |> redirect(to: "/products/#{product_id}/edit?tab=risk_share")
  end

  defp update_rs_validate_naf(conn, product, product_params) do
    naf_type = product_params["naf_type"]
    naf_value = product_params["naf_value"]
    naf_covered = product_params["naf_covered"]

    cond do
      naf_type == "N/A" ->
        if naf_covered == "" do
          update_rs_put_flash_error(conn, product.id)
        else
          edit_rs_update_validated(conn, product, product_params)
        end
      naf_type == "Copayment" ->
        if naf_value == "" or naf_covered == "" do
          update_rs_put_flash_error(conn, product.id)
        else
          edit_rs_update_validated(conn, product, product_params)
        end
      naf_type == "CoInsurance" ->
        if naf_value == "" or naf_covered == "" do
          conn
          |> put_flash(:error, "Please complete your inputs in this Risk Share")
          |> redirect(to: "/products/#{product.id}/edit?tab=risk_share")
        else
          edit_rs_update_validated(conn, product, product_params)
        end
      true ->
        edit_rs_update_validated(conn, product, product_params)
    end
  end

  defp edit_rs_update_validated(conn, product, product_params) do
    product_params =
      product_params
      |> Map.put("updated_by_id", conn.assigns.current_user.id)

    product_risk_share = ProductContext.get_product_risk_shares(product)
    risk_share = ProductContext.get_product_risk_share(product_params["risk_share_id"])
    _changeset = ProductCoverageRiskShare.changeset(risk_share)
    case ProductContext.update_product_risk_share(risk_share, product_params) do
      {:ok, _product_risk_share} ->
        ProductContext.update_product_step(product, product_params)
        conn
        |> put_flash(:info, "Risk Share successfully saved.")
        |> redirect(to: "/products/#{product.id}/edit?tab=risk_share")
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Please complete your fields in this Non-Accredited Facility.")
        |> render("edit/risk_share.html", product: product, product_risk_share: product_risk_share, changeset: changeset)
    end
  end

  def update_risk_share_facility(conn, product, product_params) do
    pcrs_id = product_params["product_risk_share_id"]
    product_params =
      product_params
      |> Map.put("updated_by_id", conn.assigns.current_user.id)
      |> Map.put("product_coverage_risk_share_id", pcrs_id)
    product_risk_share = ProductContext.get_product_risk_shares(product)
    risk_share = ProductContext.get_product_risk_share(product_params["product_risk_share_id"])
    _changeset = ProductCoverageRiskShare.changeset(risk_share)
    case ProductContext.set_product_risk_share_facility(product_params) do
      {:ok, _product_risk_share} ->
        conn
        |> put_flash(:info, "Risk Share Facility Successfully Updated.")
        |> redirect(to: "/products/#{product.id}/edit?tab=risk_share")
      {:error, %Ecto.Changeset{} = changeset} ->
        render(
          conn,
          "edit/risk_share.html",
          product: product,
          product_risk_share: product_risk_share,
          changeset: changeset,
          modal_open: true
        )
    end
  end

  def update_risk_share_facility_procedure(conn, product, product_params) do
    product_params =
      product_params
      |> Map.put("updated_by_id", conn.assigns.current_user.id)
    product_risk_share = ProductContext.get_product_risk_shares(product)
    risk_share_facility = ProductContext.get_product_risk_share_facility(product_params["product_risk_share_facility_id"])
    risk_share = ProductContext.get_product_risk_share(risk_share_facility.product_coverage_risk_share_id)
    _changeset = ProductCoverageRiskShare.changeset(risk_share)
    case ProductContext.set_product_risk_share_facility_procedure(product_params) do
      {:ok, _product_risk_share_procedure} ->
        conn
        |> put_flash(:info, "Risk Share Procedure successfully saved.")
        |> redirect(to: "/products/#{product.id}/edit?tab=risk_share")
      {:error, %Ecto.Changeset{} = changeset} ->
        render(
          conn,
          "edit/risk_share.html",
          product: product,
          product_risk_share: product_risk_share,
          changeset: changeset,
          modal_open: true
        )
    end
  end

  def delete_product_exclusion(conn, %{"product_id" => product_id, "product_exclusion_id" => product_exclusion_id}) do
    product = ProductContext.get_product!(product_id)
    ProductContext.delete_product_exclusion!(product, product_exclusion_id)
   json conn, Poison.encode!(%{valid: true})
  end

  def filter_prs_facilities(conn, %{"product_coverage_id" => product_coverage_id}) do
    prs = ProductContext.get_prs(product_coverage_id)
    prsf = for product_risk_share_facility <- prs.product_coverage_risk_share_facilities, into: [] do
      %{display: "#{product_risk_share_facility.facility.code} - #{product_risk_share_facility.facility.name}", id: product_risk_share_facility.facility.id}
    end

    ##### [{"880000000006035 - MAKATI MEDICAL CENTER", "390274d8-e45f-4a62-b9d3-9034db690a8d"}]
    facilities = ProductContext.get_list_of_facilities()
    facilities = ProductContext.loop_facilities(facilities)
    json conn, Poison.encode!(facilities -- prsf)
  end

  def filter_included_prs_facilities(conn, %{"product_coverage_id" => product_coverage_id}) do
    prs = ProductContext.get_prs(product_coverage_id)
    prsf = for product_risk_share_facility <- prs.product_coverage_risk_share_facilities, into: [] do
      %{display: "#{product_risk_share_facility.facility.code} - #{product_risk_share_facility.facility.name}", id: product_risk_share_facility.facility.id}
    end
    json conn, Poison.encode!(prsf)
  end

  def filter_prs_facility_procedures(conn, %{"product_id" => _product_id, "product_risk_share_facility_id" => prsf_id}) do
    prsf = ProductContext.get_prsf(prsf_id)
    prsfp = for prsfp <- prsf.product_coverage_risk_share_facility_payor_procedures do
      %{display: "#{prsfp.facility_payor_procedure.code} - #{prsfp.facility_payor_procedure.name}", id: prsfp.facility_payor_procedure.id}
    end

    facility_payor_procedure = ProductContext.get_fpp(prsf_id)
    facility_payor_procedure =
      facility_payor_procedure
      |> List.flatten()
      |> Enum.uniq()
    if facility_payor_procedure == [] do
      procedures = ProductContext.loop_procedures(facility_payor_procedure)
      json conn, Poison.encode!(procedures)
    else
      procedures = ProductContext.loop_procedures(facility_payor_procedure)
      fpp_left = procedures -- prsfp
      json conn, Poison.encode!(fpp_left)
    end
  end

  def filter_included_prs_facility_procedures(conn, %{"product_id" => _product_id, "product_risk_share_facility_id" => prsf_id}) do
    prsf = ProductContext.get_prsf(prsf_id)
    prsfp = for prsfp <- prsf.product_coverage_risk_share_facility_payor_procedures do
      %{display: "#{prsfp.facility_payor_procedure.code} - #{prsfp.facility_payor_procedure.name}", id: prsfp.facility_payor_procedure.id}
    end
    json conn, Poison.encode!(prsfp)
  end

  ########################## END -- Functions regarding Risk Share.

  ########################## START -- Functions regarding Summary.

  def step5_peme(conn, product) do
    _product_params = %{}
    conn
    # |> put_flash(:success, "Please enter atleast one Married Employee Dependent.")
    |> render("step5_peme.html", product: product)
  end

  def step7(conn, product) do
    _product_params = %{}
    render(conn, "step7.html", product: product)
  end

  def save_product(conn, %{"id" => id}) do
    product = ProductContext.get_product!(id)
    product_params = %{}
    product_params =
      product_params
      |> Map.put("step", "8")
      |> Map.put("updated_by_id", conn.assigns.current_user.id)

    ProductContext.update_product_step(product, product_params)
    conn
    |> put_flash(:info, "Plan has been Successfully added.")
    |> redirect(to: "/products/#{id}")
  end

  def show_summary(conn, %{"id" => id}) do
    product = ProductContext.get_product!(id)
    if product.product_category == "PEME Plan" do
      render(conn, "show_peme_summary.html", product: product)
    else
      render(conn, "show_summary.html", product: product)
    end
  end

  ########################## END -- Functions regarding Summary.

  def copy_product(conn, %{"product_id" => product_id}) do
    with {true, _} <- UtilityContext.valid_uuid?(product_id),
      valid_product_id = %Product{} <- ProductContext.get_product_by_id(product_id)
    do
      product = ProductContext.get_product!(product_id)
      copied_product = ProductContext.copy_product_general(conn, product)
      if not is_nil(copied_product.id) do
        conn
        |> redirect(to: "/web/products/#{copied_product.id}/edit?tab=general")
      else
        conn
        |> put_flash(:error, "Error ID")
        |> redirect(to: "/products/#{product_id}")
      end
    else
      nil ->
        conn
        |> put_flash(:error, "Product Not Found")
        |> redirect(to: "/products/#{product_id}")
      _ ->
        conn
        |> put_flash(:error, "Error")
        |> redirect(to: "/products/#{product_id}")
    end
  end

  def update_rnb_coverage(conn, %{"product_id" => product_id, "coverage_id" => coverage_id}) do
    product = ProductContext.get_product!(product_id)
    ProductContext.update_product_rnb_coverage(product, coverage_id)
    json conn, Poison.encode!(%{valid: true})
  end

  def update_lt_coverage(conn, %{"product_id" => product_id, "coverage_id" => coverage_id}) do
    product = ProductContext.get_product!(product_id)
    ProductContext.update_product_lt_coverage(product, coverage_id)
    json conn, Poison.encode!(%{valid: true})
  end

  #for product download
  def download_product(conn, %{"product_param" => download_param}) do
    data = ProductContext.csv_product_downloads(download_param)
    # conn
    json conn, Poison.encode!(data)
  end

  def print_summary(conn, %{"id" => id}) do
    product = ProductContext.get_product!(id)
    html = Phoenix.View.render_to_string(Innerpeace.PayorLink.Web.ProductView, "print_summary.html", product: product)
    {date, time} = :erlang.localtime
    unique_id = Enum.join(Tuple.to_list(date)) <> Enum.join(Tuple.to_list(time))
    filename = "#{product.name}_#{unique_id}"

    with {:ok, content} <- PdfGenerator.generate_binary html, filename: filename, delete_temporary: true
    do
      conn
      |> put_resp_content_type("application/pdf")
      |> put_resp_header("content-disposition", "inline; filename=#{filename}.pdf")
      |> send_resp(200, content)
    else
      {:error, reason} ->
        conn
        |> put_flash(:error, reason)
        |> redirect(to: "/products/#{product.id}/")
    end
  end

  def next_btn(conn, %{"id" => product_id, "nxt_step" => nxt_step}) do
    product = ProductContext.get_product!(product_id)

    # if nxt_step == "4" do
      # case ProductContext.remaining_age_range_checker(product) do
        # {:zero_to_100_fulfilled} ->
          # product_params = %{}
          # product_params =
          #   product_params
          #   |> Map.put("step", nxt_step)
          #   |> Map.put("updated_by_id", conn.assigns.current_user.id)

          #   {:ok, updated_step} = ProductContext.update_product_step(product, product_params)
          #   json conn, Poison.encode!(updated_step)

        # {:no_pb_acu_found} ->
          # product_params = %{}
        #   product_params =
        #     product_params
        #     |> Map.put("step", nxt_step)
        #     |> Map.put("updated_by_id", conn.assigns.current_user.id)

        #     {:ok, updated_step} = ProductContext.update_product_step(product, product_params)
        #     json conn, Poison.encode!(updated_step)

        # {:unfulfilled_age_male, message} ->
        #   conn
        #   |> json(Poison.encode!(%{message: message}))

        # {:unfulfilled_age_female, message} ->
        #   conn
        #   |> json(Poison.encode!(%{message: message}))
      # end

    # else

      product_params = %{}
      product_params =
        product_params
        |> Map.put("step", nxt_step)
        |> Map.put("updated_by_id", conn.assigns.current_user.id)

        {:ok, updated_step} = ProductContext.update_product_step(product, product_params)
        json conn, Poison.encode!(updated_step)

    # end

  end

  def get_product_struct(conn, %{"id" => id}) do
    # Returns given Product record.
    product = ProductContext.get_product!(id)
    json conn, Poison.encode!(product)
  end

  def edit_pec_limit(conn, %{"product_id" => product_id, "product_exclusion" => params}) do
    exclusion = ExclusionContext.get_exclusion(params["exclusion_id"])
    limit_peso =
      if params["limit_type"] == "Peso" do
        params["amount"]
      else
        nil
      end
    limit_percentage =
      if params["limit_type"] == "Percentage" do
        params["amount"]
      else
        nil
      end
    limit_session =
      if params["limit_type"] == "Sessions" do
        params["amount"]
      else
        nil
      end
    exclusion_params =
      %{
        limit_type: params["limit_type"],
        limit_peso: limit_peso,
        limit_percentage: limit_percentage,
        limit_session: limit_session
      }
    with {:ok, exclusion} <-
        ProductContext.update_pec_limit(
          product_id, exclusion.id , exclusion_params) do
      conn
        |> put_flash(:info, "Successfully updated PEC Limit")
        |> redirect(to: "/products/#{product_id}/setup?step=2")
    else
      _ ->
      conn
        |> put_flash(:error, "Error updating PEC Limit")
        |> redirect(to: "/products/#{product_id}/setup?step=2")
    end
  end

  def edit_pec_limit_edit(conn, %{"product_id" => product_id, "product_exclusion" => params}) do
    exclusion = ExclusionContext.get_exclusion(params["exclusion_id"])
    limit_peso =
      if params["limit_type"] == "Peso" do
        params["amount"]
      else
        nil
      end
    limit_percentage =
      if params["limit_type"] == "Percentage" do
        params["amount"]
      else
        nil
      end
    limit_session =
      if params["limit_type"] == "Sessions" do
        params["amount"]
      else
        nil
      end
    exclusion_params =
      %{
        limit_type: params["limit_type"],
        limit_peso: limit_peso,
        limit_percentage: limit_percentage,
        limit_session: limit_session
      }
    with {:ok, exclusion} <-
        ProductContext.update_pec_limit(
          product_id, exclusion.id , exclusion_params) do
      conn
        |> put_flash(:info, "Successfully updated PEC Limit")
        |> redirect(to: "/products/#{product_id}/edit?tab=exclusion")
    else
      _ ->
      conn
        |> put_flash(:error, "Error updating PEC Limit")
        |> redirect(to: "/products/#{product_id}/edit?tab=exclusion")
    end
  end

  def load_all_products(conn, params) do
    count = ProductDatatableV2.get_products_count(params["search"]["value"])
    products = ProductDatatableV2.get_products(params["start"], params["length"], params["search"]["value"])

    json(conn, %{
      data: products,
      draw: params["draw"],
      recordsTotal: count,
      recordsFiltered: count
    })
  end

end
