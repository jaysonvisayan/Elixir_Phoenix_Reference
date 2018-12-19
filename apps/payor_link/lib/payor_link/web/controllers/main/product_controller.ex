defmodule Innerpeace.PayorLink.Web.Main.ProductController do
  use Innerpeace.PayorLink.Web, :controller
  use Innerpeace.Db.PayorRepo, :context

  import Ecto.{Query, Changeset}, warn: false

  alias Innerpeace.Db.{
    Base.Api.UtilityContext,
    Repo,
    Schemas.Product,
    Schemas.ProductCoverage,
    Schemas.ProductCoverageFacility,
    Schemas.ProductBenefit,
    Schemas.ProductBenefitLimit,
    Schemas.ProductExclusion,
    Schemas.ProductCoverageRiskShare,
    Schemas.ProductCoverageDentalRiskShare,
    Schemas.ProductCoverageLocationGroup,
    Schemas.ProductCoverageRiskShareFacility,
    Schemas.ProductCoverageLimitThresholdFacility,
    Schemas.ProductCoverageDentalRiskShareFacility,
    Schemas.BenefitPackage,
    Base.ProductContext,
    Base.BenefitContext,
    Base.ExclusionContext,
    Base.RoomContext,
    Base.CoverageContext,
    Base.FacilityContext,
    Base.LocationGroupContext,
    Base.PackageContext,
    Datatables.ProductDatatable,
    Datatables.PackageDatatable,
    Datatables.ProcedureDatatable,
    Datatables.DentalBenefitDatatable,
    Datatables.ExclusionFacilityDatatable,
    Datatables.ProductDentalBenefitDatatable,
    Datatables.ProductDentalFacilityDatatable,
    Datatables.ProductDentalFacilityInclusionDatatable,
    Datatables.ProductDentalRiskShareDatatable
  }

  # plug :can_access?, %{permissions: ["manage_products", "access_products"]} when action in [:index]
  # plug :can_access?, %{permissions: ["manage_products"]} when not action in [:index]

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

  def index(conn, _params) do
    products = ProductContext.get_all_products_for_index("", 0)
    render(conn, "index.html", products: products)
  end

  def index(conn, _), do: render(conn, "index.html")

  def index_load_datatable(conn, %{"params" => params}) do
    products = ProductContext.get_all_products_for_index(params["search_value"], params["offset"])

    render(
      conn,
      Innerpeace.PayorLink.Web.ProductView,
      "load_all_products.json",
      products: products
    )
  end

  def validate_category(conn, post) do
    with "Regular Plan" <- post["params"]["product_category"], true <- Map.has_key?(post["params"], "product_base") do
      conn |> redirect(to: main_product_path(conn, :new_reg, product_base: post["params"]["product_base"]))
    else
      "PEME Plan" -> conn |> redirect(to: main_product_path(conn, :new_peme, product_base: "Benefit-based"))
      "Dental Plan" -> conn |> redirect(to: main_product_path(conn, :new_dental, product_base: "Benefit-based"))

      _ ->
        conn
        |> put_flash(:error, "Please select a plan base.")
        |> redirect(to: "/web/products")

    end
  end

  def show(conn, %{"id" => id}) do
    # Loads all the record inside Product and its child tables.
    product = ProductContext.get_product!(id)

    # benefits = BenefitContext.get_all_benefits()
    # exclusions = ExclusionContext.get_all_exclusions()
    # facility = FacilityContext.get_all_facility!()
    # funding = ProductContext.get_funding_arrangement()

    get_product_show(conn, product)
  end

  def get_product_show(conn, product) when not is_nil(product) do

    step =
      product.step
      |>String.to_integer()

    case product.product_category do
      "Dental Plan" ->
        cond do
          Enum.empty?(product.product_coverages) ->
            conn
            |> put_flash(:error, "Plan has no coverages!")
            |> redirect(to: "/web/products")
          step <= 3 ->
            conn
            |> put_flash(:error, "Page does not exist!")
            |> redirect(to: "/web/products")
          true ->
            risk_share = get_dental_risk_share(product.product_coverages)
            render(conn, "dental/show.html", product: product, risk_share: risk_share)
        end
      "Regular Plan" ->
        if step > 4 do
          render(conn, "show.html", product: product)
        else
          conn
          |> put_flash(:error, "Page does not exist!")
          |> redirect(to: "/web/products")
        end

      "Regular Product" ->
        if step > 4 do
          render(conn, "show.html", product: product)
        else
          conn
          |> put_flash(:error, "Page does not exist!")
          |> redirect(to: "/web/products")
        end

      "PEME Plan" ->
        if step > 4 do
          render(conn, "show.html", product: product)
        else
          conn
          |> put_flash(:error, "Page does not exist!")
          |> redirect(to: "/web/products")
        end

    end
  end

  defp get_dental_risk_share([]), do: []
  defp get_dental_risk_share(pc), do: get_dental_risk_share2(List.first(pc).product_coverage_dental_risk_share)

  defp get_dental_risk_share2(nil), do: []
  defp get_dental_risk_share2(drs), do: drs.product_coverage_dental_risk_share_facilities

  def get_product_show(conn, product) when is_nil(product) do
    conn
    |> put_flash(:error, "ID Doesn't Exist!")
    |> redirect(to: "/web/products")
  end

  def show_product_benefit(conn, %{"pb_id" => pb_id}) do
    product_benefit = ProductContext.get_pb_by_id(pb_id)
    benefit = BenefitContext.get_benefits_by_id(product_benefit.benefit_id)
    pb_limits = product_benefit.product_benefit_limits
    render(
      conn,
      "show_benefit.html",
      benefit: benefit,
      pb_limits: pb_limits,
      product_id: product_benefit.product_id
    )
  end

  ##################### For web/products/")w_reg and web/products/new_peme #######################

  def new_peme(conn, product_base = "Benefit-based") do
    changeset_general = Product.changeset_general(%Product{})
    render(conn, "new.html", p_cat: "PEME Plan", changeset_general: changeset_general, product_base: product_base)
  end

  def new_peme(conn, %{"product_base" => product_base}) when product_base != "Benefit-based" do
    conn
    |> put_flash(:error, "Invalid Plan Base")
    |> redirect(to: main_product_path(conn, :index))
  end

  def new_dental(conn, product_base = "Benefit-based") do
    changeset_general = Product.changeset_general_dental(%Product{})
    # raise BenefitContext.get_benefit_by_coverage(coverage)
    dental_benefit =  ProductContext.get_all_benefits_dental("", 0)
    # get_dental_benefits = ProductContext.get_all_benefits_dental("", 0, product)
    render(conn, "new.html", p_cat: "Dental Plan", changeset_general: changeset_general, product_base: product_base, benefit: dental_benefit, conn: conn )

  end

  def new_dental(conn, %{"product_base" => product_base}) when product_base != "Benefit-based" do
    conn
    |> put_flash(:error, "Invalid Plan Base")
    |> redirect(to: main_product_path(conn, :index))
  end

  def new_dental(conn, params), do: new_dental(conn, params["product_base"])

  def new_peme(conn, params), do: new_peme(conn, params["product_base"])

  def new_reg(conn, product_base = "Benefit-based") do
    changeset_general = Product.changeset_general(%Product{})
    render(conn, "new.html", p_cat: "Regular Plan", changeset_general: changeset_general, product_base: product_base)
  end

  def new_reg(conn, product_base = "Exclusion-based") do
    changeset_general = Product.changeset_general(%Product{})
    render(conn, "new.html", p_cat: "Regular Plan", changeset_general: changeset_general, product_base: product_base)
  end

  def new_reg(conn, %{"product_base" => product_base})
  when product_base != "Benefit-based" and product_base != "Exclusion-based" do
    conn
    |> put_flash(:error, "Invalid Plan Base")
    |> redirect(to: main_product_path(conn, :index))
  end

  def new_reg(conn, params), do: new_reg(conn, params["product_base"])

  ##################################### setup?step="" ##########################################

  def setup(conn, %{"id" => id, "step" => step, "pb" => product_benefit_id}) when step == "2.1" do
    product = ProductContext.get_product!(id)
    product_benefit = ProductContext.get_product_benefit(product_benefit_id)
    if not is_nil(product_benefit) do
      changeset = ProductBenefitLimit.changeset(%ProductBenefitLimit{})
      render(conn, "benefit_limit.html", product: product, changeset: changeset, product_benefit: product_benefit)
    else
      conn
      |> put_flash(:error, "Invalid Product Benefit ID")
      |> step(product, "2")
    end
  end

  def setup(conn, %{"id" => id, "step" => step}) do
    product = ProductContext.get_product!(id)
    step(conn, product, step)
  end

  def setup(conn, _), do: redirect_to_index(conn, "Page not found!")

  def step(conn, product, "1") do
    if product.product_category == "Dental Plan" do
      changeset_general = Product.changeset_general_dental(product)
      dental_benefit =  ProductContext.get_all_benefits_dental("", 0)
      render(conn, "edit/step1_dental_form.html", changeset_general: changeset_general, product: product, benefit: dental_benefit)
    else
      changeset_general_edit = Product.changeset_general_edit(product)
      render(conn, "step1.html", changeset_general_edit: changeset_general_edit, product: product)
    end
  end

  def step(conn, nil, "2"), do: conn |> put_flash(:error, "Product Not Found!") |> redirect(to: "/web/products")

  def step(conn, product, "2") do
    benefits = ProductContext.get_all_benefits_step3("", 0, product)
    changeset = ProductBenefit.changeset(%ProductBenefit{})
    if product.product_category == "Dental Plan" do
      location_groups =
        ProductContext.get_all_dental_facility_location_groups()
        |> Enum.map(&{&1.name, &1.id})

      facilities = ProductContext.get_dental_facilities_for_risk_share(product.id)
      render(
        conn,
        "dental/step2.html",
        conn: conn,
        changeset: changeset,
        product: product,
        benefits: benefits,
        location_groups: location_groups,
        dental_facilities: facilities
      )
    else
      render(
        conn,
        "step2.html",
        conn: conn,
        changeset: changeset,
        product: product,
        benefits: benefits
      )
    end
  end

  def step(conn, product, "2.1") do
    # Loads form for ProductBenefit to modify its limit.
    raise product
    # product_benefit = ProductContext.get_product_benefit(product_benefit_id)
    # changeset = ProductBenefitLimit.changeset(%ProductBenefitLimit{})
    # render(conn, "benefit_limit.html", product: product, changeset: changeset, product_benefit: product_benefit)
  end

  def step(conn, product, "3") do
    render(
      conn,
      "step3.html",
      changeset_condition: Product.changeset_condition(product),
      product: product
    )
  end

  def step(conn, product, "4") do
    changeset = Product.changeset_general(%Product{})
    render(conn, "step4.html", product: product, changeset: changeset, modal_result: false)
  end

  def step(conn, product, _) do
    conn
    |> put_flash(:error, "Invalid Step, You are redirected to your current step")
    |> redirect(to: "/web/products/#{product.id}/setup?step=#{product.step}")
  end

  #################################### update step ###########################################

  def update_setup(conn, %{"id" => id, "step" => step, "product" => product_params}) do
    product = ProductContext.get_product!(id)
    update_step(conn, product, product_params, step)
  end
  def update_setup(conn, _), do: redirect_to_index(conn, "Page not found!")

  def update_step(conn, product, product_params, "1"),
  do: step1_update(conn, product, product_params)

  def update_step(conn, product, product_params, "1.1"),
  do: step1_update_peme(conn, product, product_params)

  def update_step(conn, product, product_params, "2"),
  do: step2_update(conn, product, product_params)

  def update_step(conn, product, product_params, "3"),
  do: step3_update(conn, product, product_params)

  def update_step(conn, product, product_params, "3.1"),
  do: step3_update_dental(conn, product, product_params)

  def update_step(conn, product, product_params, "4"),
  do: step4_update(conn, product, product_params)

  ################################## AJAX Requests ###########################################

  # saving a product_coverage_facility
  def save_pcf(conn, %{"product_id" => product_id, "product_params" => product_params}) do
    facility_ids =
      product_params["facility_ids"]
      |> String.split(",")
      |> Enum.uniq()

    conn
    |> set_product_facility(product_params["product_coverage_id"], facility_ids)
  end

  def set_product_facility(conn, pc_id, [""]), do: json(conn, Poison.encode!(%{result: "failed"}))
  def set_product_facility(conn, pc_id, facility_ids), do: process_pcf(conn, pc_id, facility_ids)

  def process_pcf(conn, pc_id, facility_ids) do
    facility_ids =
      facility_ids -- (ProductContext.get_all_pcf(pc_id) |> Enum.map(& &1.facility.id))

    ProductContext.set_product_facility(pc_id, facility_ids)
    conn |> take_pcf_result(pc_id)
  end

  def take_pcf_result(conn, pc_id), do: pc_id |> ProductContext.get_all_pcf() |> render_pcf(conn)

  def render_pcf(pcfs, conn),
  do: render(conn, Innerpeace.PayorLink.Web.Main.ProductView, "all_pcf.json", pcfs: pcfs)

  ################################## Other Stuffs ###########################################

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
        |> put_flash(:info, "Success")
        |> redirect(to: "/web/products/#{product.id}/setup?step=2")

      {:error, %Ecto.Changeset{} = changeset_general} ->
        p_cat = changeset_general.changes.product_category

        conn
        |> put_flash(:error, "Please fill in the required fields!")
        |> render(
          "new.html",
          changeset_general: changeset_general,
          p_cat: p_cat,
          product_base: product_params["product_base"]
        )
    end
  end

  def create_peme(conn, %{"product" => product_params}) do
    product_params =
      product_params
      |> Map.put("step", "2")
      |> Map.put("created_by_id", conn.assigns.current_user.id)
      |> Map.put("updated_by_id", conn.assigns.current_user.id)

    case ProductContext.create_product_peme(product_params) do
      {:ok, product} ->
        conn
        # |> put_flash(:info, "Success")
        |> redirect(to: "/web/products/#{product.id}/setup?step=2")

      {:error, %Ecto.Changeset{} = changeset_general_peme} ->
        p_cat = changeset_general_peme.changes.product_category

        conn
        |> put_flash(:error, "Please complete your fields!")
        |> render(
          "new.html",
          changeset_general: changeset_general_peme,
          p_cat: p_cat,
          product_base: product_params["product_base"]
        )
    end
  end

  defp check_limit_applicability(nil), do: nil
  defp check_limit_applicability(limit) do
    limit =
      limit
      |> Enum.join(",")
  end

  def create_dental(conn, %{"product" => product_params}) do
    dental_benefit =  ProductContext.get_all_benefits_dental("", 0)
    if product_params["is_draft"] == "true" do
      limit_amount =
        if is_nil(product_params["limit_amount"]) or product_params["limit_amount"] == "" do
          Decimal.new(0)
        else
        product_params["limit_amount"]
        |> String.split(",")
        |> Enum.join()
        |> Decimal.new()
        end

      product_params =
        product_params
        |> Map.put("step", "1")
        |> Map.put("limit_amount", limit_amount)
        |> Map.put("created_by_id", conn.assigns.current_user.id)
        |> Map.put("updated_by_id", conn.assigns.current_user.id)
        |> Map.put("limit_applicability", check_limit_applicability(product_params["limit_applicability"]))

        case ProductContext.save_draft_product_dental(product_params) do
          {:ok, product} ->
            conn
            #add facility step here
            #|> put_flash(:info, "Success")
            |> put_flash(:info, "Successfully save as draft")
            |> redirect(to: "/web/products/")

          {:error, %Ecto.Changeset{} = changeset_general_dental} ->
            p_cat = changeset_general_dental.changes.product_category

            conn
            |> put_flash(:error, "Please complete your fields!")
            |> render(
              "new.html",
              changeset_general: changeset_general_dental,
              p_cat: p_cat,
              product_base: product_params["product_base"]
            )
        end
    else
      if is_nil(product_params["limit_amount"]) or product_params["limit_amount"] == "" do
        Decimal.new(0)
      else
        limit_amount =
          product_params["limit_amount"]
          |> String.split(",")
          |> Enum.join()
          |> Decimal.new()
      end

      product_params =
      product_params
      |> Map.put("step", "2")
      |> Map.put("limit_amount", limit_amount)
      |> Map.put("created_by_id", conn.assigns.current_user.id)
      |> Map.put("updated_by_id", conn.assigns.current_user.id)
      |> Map.put("limit_applicability", check_limit_applicability(product_params["limit_applicability"]))

        case ProductContext.create_product_dental(product_params) do
          {:ok, product} ->
          coverage = ProductContext.coverage_struct_by_code("dentl")
          product_coverage = ProductContext.get_pc_by_pid_and_cid(product.id, coverage.id)
          ProductContext.insert_product_coverage_dental_risk_share(%{"product_coverage_id" => product_coverage.id})

          conn
          |> redirect(to: "/web/products/#{product.id}/setup?step=2")

        {:error, %Ecto.Changeset{} = changeset_general_dental} ->
          p_cat = changeset_general_dental.changes.product_category
          conn
          |> put_flash(:error, "Please complete your fields!")
          |> render(
            "new.html",
            changeset_general: changeset_general_dental,
            p_cat: p_cat,
            benefit: dental_benefit,
            product_base: product_params["product_base"]
          )
        {:error} ->
          conn
          |> put_flash(:error, "Please complete your fields!")
          |> redirect(to: "/web/products/new_dental?product_base=Benefit-based")
      end
    end
  end

  def get_all_product_code(conn, _params) do
    product = ProductContext.get_all_product_code()
    json conn, Poison.encode!(product)
  end

  # def edit_setup(conn, %{"id" => id, "tab" => tab, "product_category" => product_category}) do
  #   # Loads the form template according to the step the user
  #   #  is in with the value of 'product_benefit_id' to be used only in Step .

  #   product = ProductContext.get_product!(id)
  #   case tab do
  #     "general" ->
  #       edit_general(conn, product)
  #     # "facilities" ->
  #     #   edit_facilities(conn, product)
  #     # "condition" ->
  #     #   edit_condition(conn, product, product_benefit_id)
  #     _ ->
  #       conn
  #       |> put_flash(:error, "Invalid Step")
  #       |> redirect(to: "/products/#{product.id}/")
  #   end
  # end

  def copy_product(conn, %{"product_id" => product_id}) do
    product = ProductContext.get_product!(product_id)

    if is_nil(product) do
      conn
      |> put_flash(:error, "Plan doesn't exist")
      |> redirect(to: "/web/products")
    else
      case product.product_category do
        "Dental Plan" ->
          copied_product = ProductContext.copy_dental_product_general(conn, product)

          conn
          |> put_flash(:info, "Dental Plan copied successfully")
          |> redirect(to: "/web/products/#{copied_product.id}/setup?step=1")


        "Regular Plan" ->
          copied_product = ProductContext.copy_product_general(conn, product)

          conn
          |> put_flash(:info, "Plan copied successfully")
          |> redirect(to: "/web/products/#{copied_product.id}/setup?step=1")

        "PEME Plan" ->
          copied_product = ProductContext.copy_product_general(conn, product)

          conn
          |> put_flash(:info, "Plan copied successfully")
          |> redirect(to: "/web/products/#{copied_product.id}/setup?step=1")


        _ ->
          conn
          |> put_flash(:error, "Error")
          |> redirect(to: "/web/products/#{product_id}/show")
      end
    end
  end

  def edit_dental(conn, %{"id" => id, "tab" => tab, "category" => category}) do
    product = ProductContext.get_product!(id)
    changeset_general_edit = Product.changeset_general_edit(product)
    changeset_general_dental_edit = Product.changeset_general_dental_edit(product)
    dental_benefit =  ProductContext.get_all_benefits_dental("", 0)
    case category do
      "Dental" ->
      render(conn, "edit/general.html", changeset: changeset_general_dental_edit , product: product, benefit: dental_benefit)

      # "PEME" ->
      #   render(conn, "edit/general_peme.html", changeset_general_peme_edit: changeset_general_peme_edit , product: product)

      _ ->
        render(
          conn,
          "edit/general.html",
          changeset_general_edit: changeset_general_edit,
          product: product
        )
    end
  end

  defp get_limit_amount(""), do: Decimal.new(0)
  defp get_limit_amount(nil), do: Decimal.new(0)
  defp get_limit_amount(limit_amount) do
      limit_amount
      |> String.split(",")
      |> Enum.join()
      |> Decimal.new()
    rescue
     _ ->
      Decimal.new(0)
  end

  def step1_update(conn, product, product_params) do
    with {:valid} <- validate_product_name(product_params["name"]) do
      if product.product_category == "Dental Plan" do
        limit_amount = get_limit_amount(product_params["limit_amount"])
        limit_applicability = if not is_nil(product_params["limit_applicability"]), do: Enum.join(product_params["limit_applicability"], ",")
        product_params =
          product_params
          |> Map.put("step", "1")
          |> Map.put("limit_amount", limit_amount)
          |> Map.put("created_by_id", conn.assigns.current_user.id)
          |> Map.put("updated_by_id", conn.assigns.current_user.id)
          |> Map.put("limit_applicability", limit_applicability)

        if product_params["add_benefit"] == "true" do
          if product_params["benefit_ids"] == [""] do
            conn
            |> put_flash(:error, "At least one Benefit is required")
            |> redirect(to: "/web/products/#{product.id}/setup?step=1")
          else
            case ProductContext.update_product_dental(product, product_params) do
              {:ok, product, "no_benefit"} ->
                if product_params["is_draft"] == "true" do
                  conn
                  |> redirect(to: "/web/products")
                else
                  conn
                  |> put_flash(:info, "Dental Plan successfully updated.")
                  |> redirect(to: "/web/products/#{product.id}/setup?step=2")

                end
              {:ok, product, "with_benefit"} ->
                if product_params["is_draft"] == "true" do
                  conn
                  |> redirect(to: "/web/products")
                else
                  conn
                  |> put_flash(:info, "Dental Plan successfully updated.")
                  |> redirect(to: "/web/products/#{product.id}/setup?step=2")

                end
                # |> redirect(to: "/web/products/")

              {:error, %Ecto.Changeset{} = changeset_general_dental} ->
                p_cat = changeset_general_dental.changes.product_category

                conn
                |> put_flash(:error, "Error")
                |> redirect(to: "/web/products/#{product.id}/setup?step=1")
            end
          end
        else
          case ProductContext.update_product_dental(product, product_params) do
            {:ok, product, "no_benefit"} ->

              if product_params["is_draft"] == "true" do
                conn
                |> put_flash(:info, "Successfully save as draft")
                |> redirect(to: "/web/products")
              else
                conn
                |> put_flash(:info, "Dental Plan successfully updated.")
                |> redirect(to: "/web/products/#{product.id}/setup?step=2")
              end

            {:ok, product, "with_benefit"} ->

              if product_params["is_draft"] == "true" do
                conn
                |> put_flash(:info, "Successfully save as draft")
                |> redirect(to: "/web/products")
              else
                conn
                |> put_flash(:info, "Dental Plan successfully updated.")
                |> redirect(to: "/web/products/#{product.id}/setup?step=2")
              end
              # |> redirect(to: "/web/products/")

            {:error, %Ecto.Changeset{} = changeset_general_dental} ->
              p_cat = changeset_general_dental.changes.product_category

              conn
              |> put_flash(:error, "Error")
              |> redirect(to: "/web/products/#{product.id}/setup?step=1")
          end
        end
      else
        product_params =
          product_params
          |> Map.put("step", "2")
          |> Map.put("updated_by_id", conn.assigns.current_user.id)
          # |> Map.put("shared_limit_amount", sla)

        case ProductContext.update_product(product, product_params) do
          {:ok, product} ->
            ProductContext.update_product_step(product, product_params)

            if product_params["is_draft"] == "true" do
              conn
              |> redirect(to: "/web/products")
            else
              conn
              |> put_flash(:info, "Plan updated successfully.")
              |> redirect(to: "/web/products/#{product.id}/setup?step=2")
            end

          {:error, %Ecto.Changeset{} = changeset_general_edit} ->
            conn
            |> put_flash(:error, "Please fill in the required fields!")
            |> render("step1.html", product: product, changeset_general_edit: changeset_general_edit)

          {:error_product_limit, message} ->
            conn
            |> put_flash(:error, message)
            |> redirect(to: "/web/products/#{product.id}/setup?step=1")
        end
      end
    else
      {:invalid, message} ->
        conn
        |> put_flash(:error, message)
        |> redirect(to: "/web/products/#{product.id}/setup?step=1")
      _ ->
        conn
        |> put_flash(:error, "Error")
        |> redirect(to: "/web/products/#{product.id}/setup?step=1")
    end
  end

  defp validate_product_name(nil), do: {:invalid, "Please enter plan name"}
  defp validate_product_name(name), do: validate_product_name2(String.length(name))

  defp validate_product_name2(count) when count > 150, do: {:invalid, "Plan name cannot exceed 150 characters"}
  defp validate_product_name2(_), do: {:valid}

    # Updates the initial fields of Product with Step 1 fields.

    # sla =
    #   product_params["shared_limit_amount"]
    #   |> String.split(",")
    #   |> Enum.join()


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
        |> redirect(to: "/web/products/#{product.id}/setup?step=2")

      {:error, %Ecto.Changeset{} = changeset_general_peme_edit} ->
        render(
          conn,
          "step1_edit.html",
          product: product,
          changeset_general_edit: changeset_general_peme_edit
        )

      {:error_product_limit, message} ->
        conn
        |> put_flash(:error, message)
        |> redirect(to: "/web/products/#{product.id}/setup?step=1")
    end
  end

  def step1_update_dental(conn, product, product_params) do
    product_params =
      product_params
      |> Map.put("step", "2")
      |> Map.put("updated_by_id", conn.assigns.current_user.id)

    case ProductContext.update_product(product, product_params) do
      {:ok, product} ->
        ProductContext.update_product_step(product, product_params)

        conn
        |> put_flash(:info, "Plan updated successfully.")
        |> redirect(to: "/web/products/#{product.id}/setup?step=2")

      {:error, %Ecto.Changeset{} = changeset_general_dental_edit} ->
        render(
          conn,
          "step1_edit.html",
          product: product,
          changeset_general_edit: changeset_general_dental_edit
        )

      {:error_product_limit, message} ->
        conn
        |> put_flash(:error, message)
        |> redirect(to: "/products/#{product.id}/setup?step=1")
    end
  end

  def step2_update(conn, product, product_params) do
    # Updates ProductBenefit records according to the current Product.
    user_id = conn.assigns.current_user.id

    product_params =
      product_params
      |> Map.put("step", "3")
      |> Map.put("updated_by_id", user_id)

    changeset =
      %ProductBenefit{}
      |> ProductBenefit.changeset()
      |> Map.delete(:action)
      |> Map.put(:action, "insert")

    benefit = String.split(product_params["benefit_ids_main"], ",")

    if benefit == [""] do
      conn
      |> put_flash(:error, "At least one benefit must be added.")
      |> render(
        "step2.html",
        changeset: changeset,
        product: product,
        modal_open: true
      )
    else
      case ProductContext.set_product_benefits(product, benefit, user_id) do
        {:ok} ->
          ProductContext.update_product_step(product, product_params)

          conn
          |> put_flash(:info, "Successfully added Plan Benefits!")
          |> redirect(to: "/web/products/#{product.id}/setup?step=2")

        {:error, message} ->
          conn
          |> put_flash(:error, message)
          |> redirect(to: "/web/products/#{product.id}/setup?step=2")
      end
    end
  end

  defp update_step3_step(map, category) when category == "PEME Plan", do: map |> Map.put("step", "5")
  defp update_step3_step(map, category) when category == "Regular Plan", do: map |> Map.put("step", "4")
  defp update_step3_step(map, category) when category == "Dental Plan", do: map |> Map.put("step", "4")

  def step3_update(conn, product, product_params) do
    product_params =
      product_params
      |> checkbox_states()
      |> update_step3_step(product.product_category)
      |> Map.put("updated_by_id", conn.assigns.current_user.id)

    changeset_condition = Product.changeset_condition(product)

    with {:valid} <- validate_nem(String.length(product_params["nem_principal"]), "principal"),
         {:valid} <- validate_nem(String.length(product_params["nem_dependent"]), "dependent"),
         {:ok, product} <- ProductContext.update_product_condition(product, product_params)
    do
        ProductContext.update_product_step(product, product_params)

        conn
        |> put_flash(:info, "Age, Limit, Deductions, Schedule, updated successfully.")
        |> condition_redirect(product.product_category, product)
    else
      {:error, %Ecto.Changeset{} = changeset_condition} ->
        conn
        |> put_flash(:error, "Please check your inputs.")
        |> render("step3.html", changeset_condition: changeset_condition, product: product)
      {:invalid, type, message} ->
        changeset_condition = Ecto.Changeset.add_error(changeset_condition, type, message, additional: "Not valid integer")

        conn
        |> put_flash(:error, message)
        |> render("step3.html", changeset_condition: changeset_condition, product: product)
    end
  end

  defp validate_nem(0, type) when type == "principal", do: {:invalid, :nem_principal, "Please enter valid number of eligible principal"}
  defp validate_nem(0, type) when type == "dependent", do: {:invalid, :nem_dependent, "Please enter valid number of eligible dependent"}
  defp validate_nem(nem, type) when nem > 9 and type == "principal", do: {:invalid, :nem_principal, "Please enter valid number of eligible principal"}
  defp validate_nem(nem, type) when nem > 9 and type == "dependent", do: {:invalid, :nem_dependent, "Please enter valid number of eligible dependent"}
  defp validate_nem(_, _), do: {:valid}

  def step3_update_dental(conn, product, product_params) do
    product_params =
    product_params
    |> checkbox_states()
    |> update_step3_step(product.product_category)
    |> Map.put("updated_by_id", conn.assigns.current_user.id)

    changeset_condition = Product.changeset_condition(product)
    if product_params["is_draft"] == "true" do
      product_params = Map.put(product_params, "step", "3")
    else
      product_params
    end
    case ProductContext.update_product_condition(product, product_params) do
      {:ok, product} ->
        if product_params["is_draft"] == "true" do
          ProductContext.update_product_step(product, product_params)
          conn
          |> put_flash(:info, "Successfully save as draft")
          |> redirect(to: "/web/products")
        end
        if product_params["backButton"] == "true" do
          ProductContext.update_product_step(product, product_params)
          conn
          |> redirect(to: "/web/products/#{product.id}/setup?step=2")
        end
        conn
        |> condition_redirect(product.product_category, product)
        ProductContext.update_product_step(product, product_params)
      {:error, %Ecto.Changeset{} = changeset_condition} ->
        conn
        |> put_flash(:error, "Please check your inputs.")
        |> render("step3.html", changeset_condition: changeset_condition, product: product)
    end
  end

  defp condition_redirect(conn, category, product) when category == "PEME Plan" do
    conn
    |> put_flash(:info, "Plan has been added!")
    |> redirect(to: "/web/products")
  end

  defp condition_redirect(conn, category, product) when category == "Regular Plan" do
    conn
    |> redirect(to: "/web/products/#{product.id}/setup?step=4")
  end

  defp condition_redirect(conn, category, product) when category == "Dental Plan" do
    conn
    |> redirect(to: "/web/products/#{product.id}/setup?step=4")
  end

  def checkbox_states(product_params) do
    product_params =
      if Map.has_key?(product_params, "no_outright_denial") do
        Map.put(product_params, "no_outright_denial", true)
      else
        Map.merge(product_params, %{"no_outright_denial" => false})
      end

    product_params =
      if Map.has_key?(product_params, "loa_facilitated") or Map.has_key?(product_params, "availment_type") and Enum.member?(product_params["availment_type"], "LOA facilitated") do
        Map.put(product_params, "loa_facilitated", true)
      else
        Map.merge(product_params, %{"loa_facilitated" => false})
      end

    product_params =
      if Map.has_key?(product_params, "reimbursement") or Map.has_key?(product_params, "availment_type") and Enum.member?(product_params["availment_type"], "Reimbursement") do
        Map.put(product_params, "reimbursement", true)
      else
        Map.merge(product_params, %{"reimbursement" => false})
      end

    product_params =
      if Map.has_key?(product_params, "peme_fee_for_service") do
        Map.put(product_params, "peme_fee_for_service", true)
      else
        Map.merge(product_params, %{"peme_fee_for_service" => false})
      end
  end

  def delete_product_all(conn, %{"id" => id}), do: ProductContext.delete_product_all(id) |> delete_product_all_v2(conn)
  defp delete_product_all_v2({:ok, _}, conn), do: json(conn, Poison.encode!(%{valid: true}))
  defp delete_product_all_v2(_, conn), do: json(conn, Poison.encode!(%{valid: false}))

  def deleting_product_benefit_step(conn, %{"product_id" => product_id, "id" => id}) do
    product = ProductContext.get_product!(product_id)

    with %ProductBenefit{} = product_benefit <- ProductContext.get_product_benefit(id) do
      ProductContext.benefit_hard_delete(product, product_benefit)
      json(conn, Poison.encode!(%{valid: true}))
    else
      _ ->
        json(conn, Poison.encode!(%{valid: true}))
    end
  end

  def delete_product_coverage(conn, %{"id" => id, "product_id" => product_id}) do
    with %ProductCoverageFacility{} = pcf <- ProductContext.get_product_coverage_facility(id),
         {:ok, _} <- ProductContext.delete_struct(pcf)
    do
      conn
      |> put_flash(:info, "Facility deleted successfully")
      |> redirect(to: "/web/products/#{product_id}/setup?step=2")
    else
      nil ->
        conn
        |> put_flash(:error, "Product Coverage Facility not found.")
        |> redirect(to: "/web/products/#{product_id}/setup?step=2")
      _ ->
        conn
        |> put_flash(:error, "Error deleting facility")
        |> redirect(to: "/web/products/#{product_id}/setup?step=2")
    end
  end

  def delete_product_risk_share(conn, %{"id" => id, "product_id" => product_id}) do
    with %ProductCoverageDentalRiskShareFacility{} = pcdrsf <- ProductContext.get_pcdrsf(id),
         {:ok, _pcdrsf} <- ProductContext.delete_struct(pcdrsf)
    do
      conn
      |> put_flash(:info, "Risk share deleted successfully")
      |> redirect(to: "/web/products/#{product_id}/setup?step=2")
    else
      nil ->
        conn
        |> put_flash(:error, "Risk share not found.")
        |> redirect(to: "/web/products/#{product_id}/setup?step=2")
      _ ->
        conn
        |> put_flash(:error, "Error deleting risk share")
        |> redirect(to: "/web/products/#{product_id}/setup?step=2")
    end
  end

  ################################## Other Stuffs ###########################################

  def update_facility_dental(conn, %{"id" => id, "product" => product_params}) do
    changeset = Product.changeset_general(%Product{})
    product = ProductContext.get_product!(id)
    cond do
      product_params["backButtonFacility"] == "true" ->
        with :ok <-
          product_params["coverages"]
          |> Enum.each(&ProductContext.set_product_coverages(product, product_params[&1], &1)) do
            if not is_nil(product_params["location_group_id"]) and product_params["location_group_id"] != "" do
              ProductContext.insert_or_update_pclg(%{"location_group_id" => product_params["location_group_id"], "product_coverage_id" => product_params["product_coverage_id"]})
            end

          product_params =
            product_params
            |> Map.put("updated_by_id", conn.assigns.current_user.id)
            |> Map.put("step", "1")

          ProductContext.update_product_step(product, product_params)
          conn
          |> redirect(to: "/web/products/#{product.id}/setup?step=1")

        else
          false ->
            conn
            |> put_flash(:error, "Please check your inputs")
            |> render("dental/step2.html", product: product, changeset: changeset)
        end

      product_params["is_draft"] == "true" ->
        with :ok <-
          product_params["coverages"]
          |> Enum.each(&ProductContext.set_product_coverages(product, product_params[&1], &1)) do
            # ProductContext.insert_or_update_pclg(%{"location_group_id" => product_params["location_group_id"], "product_coverage_id" => product_params["product_coverage_id"]})
            product_params =
              product_params
              |> Map.put("updated_by_id", conn.assigns.current_user.id)
              |> Map.put("step", "2")

             ProductContext.update_product_step(product, product_params)
              conn
              |> put_flash(:info, "Dental Plan saved as draft!")
              |> redirect(to: "/web/products")

        else
          false ->
            conn
            |> put_flash(:error, "Please check your inputs")
            |> render("dental/step2.html", product: product, changeset: changeset)
        end

      true ->

        update_step2_facility_with_rs(conn, id, product_params, product)
    end
  end

  defp update_step2_facility_without_rs(conn, id, product_params, product) do
    with :ok <- product_params["coverages"] |> Enum.each(&ProductContext.set_product_coverages2(product, product_params[&1], &1)),
         {:ok, _} <- ProductContext.update_product_step(product, %{"updated_by_id" => conn.assigns.current_user.id, "step" => "3"})
    do
      conn
      |> redirect(to: "/web/products/#{product.id}/setup?step=3")
    else
      _ ->
        conn
        |> put_flash(:error, "Please check your inputs")
        |> redirect(to: "/web/products/#{product.id}/setup?step=2")
    end
  end

  defp convert_to_decimal(nil), do: nil
  defp convert_to_decimal(val) do
      val
      |> String.split(",")
      |> Enum.join()
      |> Decimal.new()
    rescue
     _ ->
      nil
  end

  defp update_step2_facility_with_rs(conn, id, product_params, product) do
    risk_share_amount = convert_to_decimal(product_params["copay"])
    risk_share_percentage = convert_to_decimal(product_params["coinsurance"])

    rs_params = %{
      "product_coverage_id" => product_params["product_coverage_id"],
      "asdf_type" => product_params["copay_rss"],
      "asdf_amount" => risk_share_amount,
      "asdf_percentage" => risk_share_percentage,
      "asdf_special_handling" => product_params["special_handling_type"]
    }
    if is_nil(product_params["dentl"]) do
        conn
        |> put_flash(:error, "Please check your inputs")
        |> redirect(to: "/web/products/#{product.id}/setup?step=2")
    else
      with %ProductCoverageDentalRiskShare{} = pcdrs <- ProductContext.get_pcdrs_by_id(product_params["pcdrs_id"]),
        {:ok, pcdrs} <- ProductContext.update_pcdrs(pcdrs, rs_params),
        :ok <- product_params["coverages"] |> Enum.each(&ProductContext.set_product_coverages2(product, product_params[&1], &1)),
        {:ok, _} <- ProductContext.update_product_step(product, %{"updated_by_id" => conn.assigns.current_user.id, "step" => "3"})
      do
        conn
        |> redirect(to: "/web/products/#{product.id}/setup?step=3")
      else
        _ ->
        conn
         |> put_flash(:error, "Please check your inputs")
         |> redirect(to: "/web/products/#{product.id}/setup?step=2")
      end
    end
  end

  def edit_update_facility_dental(conn, %{"id" => id, "product" => product_params}) do
    changeset = Product.changeset_general(%Product{})
    product = ProductContext.get_product!(id)

    with true <- Map.keys(product_params) -- ["coverages"] == product_params["coverages"],
         true <- product.product_coverages |> ProductContext.verify_product_coverages(product_params),
         :ok <- product_params["coverages"]
         |> Enum.each(&ProductContext.set_product_coverages(product, product_params[&1], &1)) do
      product_params =
        product_params
      # |> Map.put("step", "5")
      |> Map.put("updated_by_id", conn.assigns.current_user.id)

      ProductContext.update_product_step(product, product_params)

      conn
      |> put_flash(:info, "Dental Plan Coverages Updated Successfully!")
      |> redirect(to: "/web/products/#{product.id}/edit?tab=facility")
    else
      false ->
        conn
        |> put_flash(:error, "Please check your inputs")
        |> render("dental/edit_facility.html", product: product, changeset_facility_dental_edit: changeset)
    end
  end

  def step4_update(conn, product, product_params) do
    changeset = Product.changeset_general(%Product{})

    with true <- Map.keys(product_params) -- ["coverages"] == product_params["coverages"],
         true <- product.product_coverages |> ProductContext.verify_product_coverages(product_params),
         :ok <-
           product_params["coverages"]
           |> Enum.each(&ProductContext.set_product_coverages(product, product_params[&1], &1)) do
      product_params =
        product_params
        |> Map.put("step", "5")
        |> Map.put("updated_by_id", conn.assigns.current_user.id)

      ProductContext.update_product_step(product, product_params)

      conn
      |> put_flash(:info, "Plan Coverages Updated Successfully!")
      |> redirect(to: "/web/products/#{product.id}/show")
    else
      false ->
        conn
        |> put_flash(:error, "Coverages in parameter is not matched to our valid coverages")
        |> render("step4.html", product: product, changeset: changeset)
    end
  end

  def save_dental_plan(conn, %{"id" => id}) do
    product = ProductContext.get_product!(id)
    product_params = %{}
    product_params =
      product_params
      |> Map.put("step", "5")
      |> Map.put("updated_by_id", conn.assigns.current_user.id)
    changeset = Product.changeset_general(%Product{})
    ProductContext.update_product_step(product, product_params)
    render(
      conn,
      "step4.html",
      product: product,
      changeset: changeset,
      modal_result: true
    )
    # conn
    # |> put_flash(:info, "Plan Successfully created.")
    # |> redirect(to: "/web/products/#{product.id}/setup?step=4")
  end

  defp generate_coverage_params(coverage) do
    compare_coverage_param()
  end

  def load_facility_access(conn, %{"ids" => facility_ids, "provider_access" => provider_access}) do
    provider_access =
      provider_access
      |> validate_provider_access()

    facilities =
      facility_ids
      |> String.split(",")

    facility_ids2 = Enum.map(facilities, fn(x) ->
      String.trim(x)
    end)

    facilities =
      facility_ids2
      |> FacilityContext.load_facility_table(provider_access)

    conn
    |> json(%{
      data: facilities
    })
  end

  def load_facility_access(conn, params) do
    provider_access =
      params["provider_access"]
      |> validate_provider_access()

    selected_facility_ids =
      if is_nil (params["selected_facility_ids"]) do
        []
      else
        params["selected_facility_ids"]
        |> String.split(",")
      end

    facility_ids =
      if is_nil (params["facility_ids"]) do
        []
      else
        params["facility_ids"]
        |> String.split(",")
      end

    facility_ids2 = Enum.map(facility_ids, fn(x) ->
      String.trim(x)
    end)

    count =
      facility_ids2
      |> FacilityContext.facility_count(provider_access)

    facility_params = %{
      "selected_facility_ids" => selected_facility_ids,
      "provider_access" => provider_access
    }

    data =
      if params["start"] == "NaN" do
        []
      else
      facility_ids2
      |> FacilityContext.facility_data(
        facility_params,
        params["start"],
        params["length"],
        params["search"]["value"]
      )
      end

    filtered_count =
      facility_ids2
      |> FacilityContext.facility_filtered_count(
        params["search"]["value"],
        provider_access
      )

    conn
    |> json(%{
      data: data,
      draw: params["draw"],
      recordsTotal: count,
      recordsFiltered: filtered_count
    })
  end

  def load_facility_access(conn, _) do
    conn
    |> json(%{data: []})
  end

  defp validate_provider_access(nil), do: ["HOSPITAL-BASED", "CLINIC-BASED", "MOBILE"]
  defp validate_provider_access(provider_access) when provider_access == "",
  do: ["HOSPITAL-BASED", "CLINIC-BASED", "MOBILE"]
  defp validate_provider_access(provider_access) do
    provider_access
    |> String.split("/")
    |> Enum.map(&String.split(&1, " and "))
    |> List.flatten()
    |> get_access([])
    |> Enum.uniq()
    |> List.delete(nil)
  end

  defp get_access([head | tails], result) do
    result = result ++ [check_access(head)]
    get_access(tails, result)
  end

  defp get_access([], result), do: result

  defp check_access(access) when access == "Hospital", do: "HOSPITAL-BASED"
  defp check_access(access) when access == "Clinic", do: "CLINIC-BASED"
  defp check_access(access) when access == "Mobile", do: "MOBILE"
  defp check_access(_), do: nil

  def load_dropdown_facilities(conn, %{
    "facilities" => facility_ids,
    "provider_access" => provider_access,
    "type" => type,
    "selected_lt_codes" => selected_lt_codes
  }) do
    provider_access =
      provider_access
      |> validate_provider_access()

    selected_lt_codes =
      selected_lt_codes
      |> String.split(",")
      |> List.delete("")

    facilities =
      facility_ids
      |> String.split(",")
      |> List.delete("")
      |> FacilityContext.load_limit_threshold_facilities(provider_access, type, selected_lt_codes)

    conn
    |> json(%{
      success: true,
      results: facilities
    })
  end

  ##################################### edit?tab="" ##########################################

  def load_product(conn, %{"id" => id}) do
    product = ProductContext.get_product!(id)

    render(
      conn,
      Innerpeace.PayorLink.Web.Main.ProductView,
      "load_one_product.json",
      product: product
    )
  end


  def edit_setup(conn, %{"id" => id, "tab" => tab, "pb" => product_benefit_id}) when tab == "product_benefit" do
    product = ProductContext.get_product!(id)

    edit(conn, product, tab, product_benefit_id)
  end

  def edit_setup(conn, %{"id" => id, "tab" => tab}) do
    product = ProductContext.get_product!(id)

    edit(conn, product, tab)
  end

  def edit_setup(conn, params), do: redirect_to_index(conn, "Page not found!")

  def edit(conn, product, "general") do
    changeset_general_edit = Product.changeset_general_edit(product)
    changeset_general_peme_edit = Product.changeset_general_peme_edit(product)
    changeset_general_dental_edit = Product.changeset_general_dental(product)
    dental_benefit =  ProductContext.get_all_benefits_dental("", 0)

    case product.product_category do
      "PEME Plan" ->
        render(
          conn,
          "edit/general_peme.html",
          changeset_general_peme_edit: changeset_general_peme_edit,
          product: product
        )
      "Dental Plan" ->
        render(
          conn,
          "dental/edit_general.html",
          changeset_general_dental_edit: changeset_general_dental_edit,
          product: product,
          benefit: dental_benefit
        )
      _ ->
        render(
          conn,
          "edit/general.html",
          changeset_general_edit: changeset_general_edit,
          product: product
        )
    end
    # if product.product_category == "PEME Plan" do
    #   render(conn, "edit/general_peme.html", changeset_general_peme_edit: changeset_general_peme_edit , product: product)

    # else
    #   render(
    #     conn,
    #     "edit/general.html",
    #     changeset_general_edit: changeset_general_edit,
    #     product: product
    #   )
    # end
  end

  def edit(conn, product, "facility") do
    changeset_general_edit = Product.changeset_general_edit(product)
    changeset_facility_dental_edit = ProductBenefit.changeset(%ProductBenefit{})
    dental_benefit =  ProductContext.get_all_benefits_dental("", 0)
    if product.product_category == "Dental Plan" do
      render(
        conn,
        "dental/edit_facility.html",
        changeset_facility_dental_edit: changeset_facility_dental_edit,
        product: product,
        benefit: dental_benefit
      )
    else
      render(
        conn,
        "edit/general.html",
        changeset_general_edit: changeset_general_edit,
        product: product
      )
    end
  end

  def edit(conn, product, "condition") do
    changeset_condition = Product.changeset_condition(product)
    dental_benefit =  ProductContext.get_all_benefits_dental("", 0)
    if product.product_category == "Dental Plan" do
      render(
        conn,
        "dental/edit_condition.html",
        changeset_condition: changeset_condition,
        product: product,
        benefit: dental_benefit
      )
    else
      render(
        conn,
        "edit/condition.html",
        changeset_condition: changeset_condition,
        product: product
      )
    end
  end

  def edit(conn, product, "benefit") do
    benefits = ProductContext.get_all_benefits_step3("", 0, product)
    changeset = ProductBenefit.changeset(%ProductBenefit{})

    render(
      conn,
      "edit/benefit_edit.html",
      conn: conn,
      changeset: changeset,
      product: product,
      benefits: benefits
    )
  end

  def edit(conn, product, "condition") do
    changeset_condition = Product.changeset_condition(product)

    render(
      conn,
      "edit/condition.html",
      changeset_condition: changeset_condition,
      product: product
    )
  end

  def edit(conn, product, "coverage") do
    changeset = Product.changeset_general(%Product{})
    render(conn, "edit/coverage.html", product: product, changeset: changeset)
  end

  def edit(conn, product, "product_benefit", product_benefit_id) do
    product_benefit = ProductContext.get_product_benefit(product_benefit_id)
    changeset = ProductBenefitLimit.changeset(%ProductBenefitLimit{})

    render(
      conn,
      "edit/edit_product_benefit.html",
      product: product,
      changeset: changeset,
      product_benefit: product_benefit
    )
  end

  ##################################### save tab ##########################################
  def update_general_peme(conn, %{"id" => id, "product" => product_params}) do
    product = ProductContext.get_product!(id)
    product_params =
      product_params
      |> Map.put("updated_by_id", conn.assigns.current_user.id)
    case ProductContext.update_product(product, product_params) do
      {:ok, update_product} ->
        ProductContext.update_product_step(product, product_params)
        ProductContext.create_product_log(
          conn.assigns.current_user,
          Product.changeset_general_peme_edit(product, product_params),
          "General"
        )
        conn
        |> put_flash(:info, "Plan Updated Successfully.")
        |> redirect(to: "/web/products/#{product.id}/edit?tab=general")
      {:error, %Ecto.Changeset{} = changeset_general_peme_edit} ->
        render(conn, "edit/general_peme.html", product: product, changeset_general_peme_edit: changeset_general_peme_edit)

      {:error_product_limit, message} ->
        conn
        |> put_flash(:info, "Please check your inputs")
        |> redirect(to: "/web/products/#{product.id}/edit?tab=general")
    end
  end

  def update_general(conn, %{"id" => id, "product" => product_params}) do
    product = ProductContext.get_product!(id)
    if product.product_category == "Dental Plan" do
      limit_amount =
        product_params["limit_amount"]
        |> String.split(",")
        |> Enum.join()
        |> Decimal.new()

        product_params =
          product_params
          # |> Map.put("step", "1")
          |> Map.put("limit_amount", limit_amount)
          |> Map.put("created_by_id", conn.assigns.current_user.id)
          |> Map.put("updated_by_id", conn.assigns.current_user.id)
          |> Map.put("limit_applicability", Enum.join(product_params["limit_applicability"], ","))

      if product_params["add_benefit"] == "true" do
          # benefits = String.split(product_params["benefit_ids_main"], ",")

          # if benefits == [""] do
          if product_params["benefit_ids"] == [""] do
          conn
          |> put_flash(:error, "At least one Benefit is required")
          |> redirect(to: "/web/products/#{product.id}/edit?tab=general")
        else
          case ProductContext.update_product_dental(product, product_params) do
            {:ok, product, "no_benefit"} ->
              conn
              |> put_flash(:info, "Dental Plan successfully updated.")
              |> redirect(to: "/web/products/#{product.id}/edit?tab=general")

            {:ok, product, "with_benefit"} ->
              conn
              |> put_flash(:info, "Dental Plan successfully updated.")
              |> redirect(to: "/web/products/#{product.id}/edit?tab=general")
              # |> redirect(to: "/web/products/")

            {:error, %Ecto.Changeset{} = changeset_general_dental} ->
              p_cat = changeset_general_dental.changes.product_category

              conn
              |> put_flash(:error, "Error")
              |> redirect(to: "/web/products/#{product.id}/edit?tab=general")
          end
        end
      else
        case ProductContext.update_product_dental(product, product_params) do
          {:ok, product, "no_benefit"} ->
            conn
            |> put_flash(:info, "Dental Plan successfully updated.")
            |> redirect(to: "/web/products/#{product.id}/edit?tab=general")

          {:ok, product, "with_benefit"} ->
            conn
            |> put_flash(:info, "Dental Plan successfully updated.")
            |> redirect(to: "/web/products/#{product.id}/edit?tab=general")
            # |> redirect(to: "/web/products/")

          {:error, %Ecto.Changeset{} = changeset_general_dental} ->
            p_cat = changeset_general_dental.changes.product_category

            conn
            |> put_flash(:error, "Error")
            |> redirect(to: "/web/products/#{product.id}/edit?tab=general")
        end
      end
    end
  end

  def update_general_reg_plan(conn, %{"id" => id, "product" => product_params}) do
    product = ProductContext.get_product!(id)
    product_params =
      product_params
      |> Map.put("updated_by_id", conn.assigns.current_user.id)

    changeset = Product.changeset_general_edit(product, product_params)

    case ProductContext.update_product(product, product_params) do
      {:ok, product} ->
        ProductContext.create_product_log(
          conn.assigns.current_user,
          changeset,
          "General"
        )
        ProductContext.update_product_step(product, product_params)
        conn
        |> put_flash(:info, "Plan Updated Successfully.")
        |> redirect(to: "/web/products/#{product.id}/edit?tab=general")
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit/general.html", product: product, changeset: changeset)

      {:error_product_limit, message} ->
        conn
        |> put_flash(:info, "Please Check your Params")
        |> redirect(to: "/products/#{product.id}/edit?tab=general")
    end
  end

  def update_benefit(conn, product, product_params) do
    # Updates ProductBenefit records according to the current Product.
    # benefits = BenefitContext.get_all_benefits()
    benefits = ProductContext.get_all_benefits_step3("", 0, product)
    user_id = conn.assigns.current_user.id

    product_params =
      product_params
      |> Map.put("updated_by_id", user_id)

    changeset =
      %ProductBenefit{}
      |> ProductBenefit.changeset()
      |> Map.delete(:action)
      |> Map.put(:action, "insert")

    benefit = String.split(product_params["benefit_ids_main"], ",")

    if benefit == [""] do
      conn
      |> put_flash(:error, "At least one benefit must be added.")
      |> render(
        "edit/benefit_edit.html",
        changeset: changeset,
        product: product,
        benefits: benefits,
        modal_open: true
      )
    else
      case ProductContext.set_product_benefits(product, benefit, user_id) do
        {:ok} ->
          ProductContext.update_product_step(product, product_params)

          conn
          |> put_flash(:info, "Successfully added Plan Benefits!")
          |> redirect(to: "/web/products/#{product.id}/edit?tab=benefit")

        {:error, message} ->
          conn
          |> put_flash(:error, message)
          |> redirect(to: "/web/products/#{product.id}/edit?tab=benefit")
      end
    end
  end

  def update_condition(conn, %{"id" => id, "product" => product_params}) do
    product = ProductContext.get_product!(id)

    product_params =
      product_params
      |> checkbox_states()
      |> update_step3_step(product.product_category)
      |> Map.put("updated_by_id", conn.assigns.current_user.id)

    changeset_condition = Product.changeset_condition(product)

    case ProductContext.update_product_condition(product, product_params) do
      {:ok, product} ->
        conn
        |> put_flash(:info, "Plan was successfully updated!")
        |> redirect(to: "/web/products/#{product.id}/edit?tab=condition")

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Please check your params!")
        |> redirect(to: "/products/#{product.id}/edit?tab=condition")
    end
  end

  def update_coverage(conn, product, product_params) do
    changeset = Product.changeset_general(%Product{})

    with true <- Map.keys(product_params) -- ["coverages"] == product_params["coverages"],
         true <- product.product_coverages |> ProductContext.verify_product_coverages(product_params),
         result <-
           product_params["coverages"]
           |> Enum.map(&ProductContext.set_product_coverages(product, product_params[&1], &1)),
         {true, result} <- check_if_contains_error_changeset(result) do
           product_params = %{}

         product_params
         |> Map.put("step", "5")
         |> Map.put("updated_by_id", conn.assigns.current_user.id)

         ProductContext.update_product_step(product, product_params)

         conn
         |> put_flash(:info, "Plan Coverages Updated Successfully!")
         |> redirect(to: "/web/products/#{product.id}/show")
        else
         false ->
        conn
        |> put_flash(:error, "Coverages in parameter is not matched to our valid coverages")
        |> render("edit/coverage.html", product: product, changeset: changeset)

      {false, result} ->
        message =
          Enum.filter(result, fn x -> x != {:ok} end)
          |> merge_changeset_errors(%Ecto.Changeset{data: %{}})
          |> consolidate_error_msg()

         conn
          |> put_flash(:error, message)
          |> render("edit/coverage.html", product: product, changeset: changeset)
         end
  end

  def check_if_contains_error_changeset(result) do
    if result |> Enum.map(&if &1 == {:ok}, do: true, else: false) |> Enum.all?() do
      {true, result}
    else
    {false, result}
    end
  end

  defp merge_changeset_errors([head | tails], changeset) do
    {:schemaless_error, head} = head
    merge_changeset_errors(tails, merge(head, changeset))
  end

  defp merge_changeset_errors([], changeset), do: changeset

  defp consolidate_error_msg(changeset),
  do: UtilityContext.changeset_errors_to_string(changeset.errors)

  defp redirect_to_index(conn, message) do
    conn
    |> put_flash(:error, message)
    |> redirect(to: main_product_path(conn, :index))
  end

  ########################### Save and Update ###########################

  def save(conn, %{"id" => id, "tab" => tab, "product" => product_params}) do
    product = ProductContext.get_product!(id)
    update(conn, product, product_params, tab)
  end

  def save(conn, params), do: redirect_to_index(conn, "Page not found!")

  def update(conn, product, product_params, "benefit"),
  do: update_benefit(conn, product, product_params)

  def update(conn, product, product_params, "coverage"),
  do: update_coverage(conn, product, product_params)

  def step(conn, product, _) do
    conn
    |> put_flash(:error, "Invalid Step, You are redirected to your current step")
    |> redirect(to: "/web/products/#{product.id}/edit?tab=#{product.tab}")
  end

  def load_index(conn, params) do
    count = ProductDatatable.product_count()

    data =
      params["start"]
      |> ProductDatatable.product_data(
        params["length"],
        params["search"]["value"],
        params["order"]["0"]
      )

    filtered_count =
      params["search"]["value"]
      |> ProductDatatable.product_filtered_count()

    conn
    |> json(%{
      data: data,
      draw: params["draw"],
      recordsTotal: count,
      recordsFiltered: filtered_count
    })
  end

  def load_view_package(conn, params) do
    count = PackageDatatable.view_package_count(params["id"])

    data =
      params["start"]
      |> PackageDatatable.view_package_data(params["id"], params["length"], params["search"]["value"])

    filtered_count =
      params["search"]["value"]
      |> PackageDatatable.view_package_filtered_count(params["id"])

    conn
    |> json(%{
      data: data,
      draw: params["draw"],
      recordsTotal: count,
      recordsFiltered: filtered_count
    })

  end

  def update_pb(conn, %{"id" => id, "product" => product_params}) do
    product = ProductContext.get_product!(id)

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
        |> redirect(to: "/web/products/#{product.id}/setup?step=2.1&pb=#{product_benefit_limit.product_benefit_id}")
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "product_benefit.html", product: product, changeset: changeset, product_benefit: product_benefit, modal_open: true)
    end
  end

  def update_product_benefit(conn, %{"id" => id, "product" => product_params}) do
    product = ProductContext.get_product!(id)
    product_benefit = ProductContext.get_product_benefit(product_params["product_benefit_id"])
    product_params = BenefitContext.setup_limits_params(product_params)
    pbl = ProductContext.get_product_benefit_limit(product_params["product_benefit_limit_id"])
    changeset = ProductBenefitLimit.changeset_update_product_limit(pbl, product_params)

    product_params =
      product_params
      |> Map.put("updated_by_id", conn.assigns.current_user.id)

    case ProductContext.update_product_benefit_limit(pbl, product_params) do
      {:ok, product_benefit_limit} ->
        ProductContext.create_product_log_join_tables(
          product_benefit.product_id,
          conn.assigns.current_user,
          changeset,
          "Benefit"
        )
          conn
        |> put_flash(:info, "Benefit Limit updated successfully.")
        |> redirect(to: "/web/products/#{product.id}/edit?tab=product_benefit&pb=#{product_benefit_limit.product_benefit_id}")
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit/product_benefit.html", product: product, changeset: changeset, product_benefit: product_benefit, modal_open: true)
    end
  end

  def load_all_dental_benefit(conn, params) do

    benefit_ids =
      params["benefit_ids"]
      |> String.split(",")
      |> Enum.uniq()

    data =
      benefit_ids
      |> DentalBenefitDatatable.get_all_dental_benefit_with_procedure()
    conn
    |> json(%{
      data: data
    })
  end

  def load_benefit(conn, params) do
    procedure_ids =
      params["procedure_ids"]
      |> String.split(",")

    benefit_ids =
      if is_nil (params["selected_benefit_ids"]) do
        []
      else
        params["selected_benefit_ids"]
        |> String.split(",")
      end

    count =
      procedure_ids
      |> DentalBenefitDatatable.procedure_count()

    data = if params["start"] == "NaN" or params["start"] == NaN do
      []
    else
      if Map.has_key?(params, "offset") do
        procedure_ids
        |> DentalBenefitDatatable.procedure_data(
          benefit_ids,
          params["offset"],
          params["length"],
          params["search"]["value"],
          params["order"]["0"]
        )
      else
        procedure_ids
        |> DentalBenefitDatatable.procedure_data(
          benefit_ids,
          params["start"],
          params["length"],
          params["search"]["value"],
          params["order"]["0"]
        )
      end
    end

    filtered_count =
      procedure_ids
      |> DentalBenefitDatatable.procedure_filtered_count(
        params["search"]["value"]
      )

    conn
    |> json(%{
      data: data,
      draw: params["draw"],
      recordsTotal: count,
      recordsFiltered: filtered_count
    })
  end

  def delete_product_benefit(conn, %{"id" => id, "product_id" => product_id}) do
    with {:ok, _} <- ProductContext.delete_product_benefit(product_id) do
      json(conn, Poison.encode!(%{success: true}))
    else
      _ ->
      json(conn, Poison.encode!(%{success: false}))
    end
  end

  defp check_procedure_id_params(nil), do: nil
  defp check_procedure_id_params(procedure_ids), do: procedure_ids

  def procedure_checker(conn, params) do
    with nil <- check_procedure_id_params(params["procedure_ids"]) do
      json conn, Poison.encode!(false)
    else
      _ ->
        results = Enum.map(params["procedure_ids"], fn(ids) ->
        result = for <<x::binary-36 <- ids>>, do: x
        end)

        results =
          results
          |> Enum.concat()

        result_count =
          results
          |> Enum.count()

        uniq_count =
          results
          |> Enum.uniq()
          |> Enum.count()

        if result_count == uniq_count do
          json conn, Poison.encode!(false)
        else
          json conn, Poison.encode!(true)
        end
    end
  end

  def delete_product_coverage_facilities(conn, params) do
    id = params["id"]
    product = ProductContext.get_product!(id)
    pc = ProductContext.get_product_coverage(product.id) |> List.first()

    with {:ok, _} <- update_product_coverage_type(pc, %{type: params["type"]}),
        {_count, nil} <- ProductContext.clear_product_facility(pc.id),
        {_count, nil} <- ProductContext.clear_product_risk_share_facility(pc.id)
    do
      json conn, Poison.encode!(%{valid: true})
    else
      _ ->
      json conn, Poison.encode!(%{valid: false})
    end
  end

  def show_product_benefit_v2(conn, %{"pb_id" => pb_id}) do
    with nil <- ProductContext.get_pb_by_id(pb_id) do
      conn
      |> put_flash(:error, "Invalid Plan Benefit")
      |> redirect(to: main_product_path(conn, :index))
    else
      _  ->
        product_benefit = ProductContext.get_pb_by_id(pb_id)
        benefit = BenefitContext.get_benefits_by_id(product_benefit.benefit_id)
        pb_limits = product_benefit.product_benefit_limits
        render(
          conn,
          "show_product_benefit.html",
          benefit: benefit,
          pb_limits: pb_limits,
          product_benefit: product_benefit,
          product_id: product_benefit.product_id
        )
    end

    rescue
    Ecto.Query.CastError ->
      conn
      |> put_flash(:error, "Invalid Plan Benefit")
      |> redirect(to: main_product_path(conn, :index))
  end

  def load_facility_datatable(conn, params) do
    if params["type"] == "exclusion" do
      load_exclusion_facility_datatable(conn, params)
    else
      load_inclusion_facility_datatable(conn, params)
    end
  end

  defp load_exclusion_facility_datatable(conn, params) do
    facility_ids = ProductContext.get_selected_product_coverage_facility(params["product_coverage_id"])

    count =
    facility_ids
      |> ExclusionFacilityDatatable.facility_count(params["location_group_id"])

    data =
      facility_ids
      |> ExclusionFacilityDatatable.facility_data(
        params["location_group_id"],
        params["start"],
        params["length"],
        params["search"]["value"],
        params["order"]["0"]
      )

    filtered_count =
      facility_ids
      |> ExclusionFacilityDatatable.facility_filtered_count(
        params["location_group_id"],
        params["search"]["value"]
      )

    conn
    |> json(%{
      data: data,
      draw: params["draw"],
      recordsTotal: count,
      recordsFiltered: filtered_count
    })
  end

  defp load_inclusion_facility_datatable(conn, params) do
    facility_ids = ProductContext.get_selected_product_coverage_facility(params["product_coverage_id"])

    count =
    facility_ids
      |> ExclusionFacilityDatatable.a_facility_count()

    data =
      facility_ids
      |> ExclusionFacilityDatatable.a_facility_data(
        params["start"],
        params["length"],
        params["search"]["value"],
        params["order"]["0"]
      )

    filtered_count =
      facility_ids
      |> ExclusionFacilityDatatable.a_facility_filtered_count(
        params["search"]["value"]
      )

    conn
    |> json(%{
      data: data,
      draw: params["draw"],
      recordsTotal: count,
      recordsFiltered: filtered_count
    })
  end

  def insert_product_coverage_location_group(conn, params) do
    result =
      with {:ok, result} <- ProductContext.insert_or_update_pclg(
        %{"location_group_id" => params["location_group_id"],
          "product_coverage_id" => params["product_coverage_id"]
        })
      do
        %{
          product_coverage_id: result.product_coverage_id,
          location_group_id: result.location_group_id,
          id: result.location_group_id
        }
      else
        _ ->
        %{
          product_coverage_id: nil,
          location_group_id: nil,
          id: nil
        }
      end

    conn
    |> json(Poison.encode!(result))
  end

  def insert_product_coverage_facility(conn, params) do
    with {:ok, facility_ids} <- validate_facility_ids(params["facility_ids"]),
         false <- is_nil(params["product_coverage_id"])
    do
      result = Enum.map(facility_ids, fn(id) ->
        get_exclusion_pcf(Map.has_key?(params, "location_group_id"), params, id)
      end)

         conn
         |> json(Poison.encode!(result))
    else
      _ ->
        conn
        |> json(Poison.encode!(%{}))
    end
  end

  defp validate_facility_ids(nil), do: nil
  defp validate_facility_ids([]), do: nil
  defp validate_facility_ids(facility_ids), do: {:ok, facility_ids |> Enum.uniq()}

  defp get_exclusion_pcf(true, params, id) do
    params["location_group_id"]
    |> ProductContext.create_and_get_exclusion_pcf(%{
      "facility_id" => id,
      "product_coverage_id" => params["product_coverage_id"]
    })
  end

  defp get_exclusion_pcf(false, params, id) do
    ProductContext.create_and_get_inclusion_pcf(%{
      "facility_id" => id,
      "product_coverage_id" => params["product_coverage_id"]
    })
  end

  def load_all_dental_facility(conn, params) do
    if Map.has_key?(params, "location_group_id") do
      facility_ids = if Map.has_key?(params, "facility_ids") do
        if params["facility_ids"] == "" do
          []
        else
          params["facility_ids"]
          |> String.split(",")
          |> Enum.uniq()
        end
      else
        []
      end

      data =
        facility_ids
        |> ExclusionFacilityDatatable.get_all_exclusion_facility_data(params["location_group_id"])
      conn
      |> json(%{
        data: data
      })
    else
      facility_ids = if Map.has_key?(params, "facility_ids") do
        if params["facility_ids"] == "" do
          []
        else
          params["facility_ids"]
          |> String.split(",")
          |> Enum.uniq()
        end
      else
        []
      end

      data =
        facility_ids
        |> ExclusionFacilityDatatable.get_all_inclusion_facility_data()
      conn
      |> json(%{
        data: data
      })

    end
  end

  def load_all_selected_dental_benefit(conn, params) do
    benefit_ids =
      params["benefit_ids"]
      |> Enum.uniq()

    data =
      benefit_ids
      |> DentalBenefitDatatable.get_all_selected_dental_benefit()
    conn
    |> json(%{
      data: data
    })
  end

  def get_product_facility_rs(conn, %{"prod_id" => prod_id}) do
    p_facilities =  ProductContext.get_facility_by_product_id(prod_id)
    render(
      conn,
      Innerpeace.PayorLink.Web.Main.ProductView,
      "all_product_facility_rs.json",
      p_facilities: p_facilities
    )
  end

  # def update_product_coverage_risk_share_dental(conn, params) do
  #   with %ProductCoverageDentalRiskShareFacility{} = pcdrsf <-  ProductContext.get_pcdrsf_by_id2(params["id"]),
  #      {:ok, pcdrsf} <- ProductContext.update_product_coverage_dental_risk_share_facility(%{
  #        "product_coverage_dental_risk_share_id" => pcdrsf.id,
  #        "facility_id" => params["fac_id"],
  #        "sdf_type" => params["fac_sdftype"],
  #        "sdf_amount" => params["fac_sftamount"],
  #        "sdf_percentage" => params["fac_sftamount"],
  #        "sdf_special_handling" => params["fac_s_handling"]
  #      }),
  #      pcdrsf_res = %ProductCoverageDentalRiskShareFacility{}  <- ProductContext.get_pcdrsf_by_id(pcdrsf.id)
  #      do
  #       raise 1234
  #       #  # sdf_amount = ProductDentalRiskShareDatatable.get_amount(String.contains?(params["value"], "."), params["value"])
  #       #  # sdf_percentage = ProductDentalRiskShareDatatable.get_amount(String.contains?(params["value"], "."), params["value"])
  #       #  sdf_special_handling = pcdrsf.sdf_special_handling || "N/A"
  #       #  json(conn, Poison.encode!(%{"id" => pcdrsf.id,
  #       #                              "product_coverage_dental_risk_share_id" => pcdrsf.product_coverage_dental_risk_share_id,
  #       #                              "facility_id" => pcdrsf.facility_id,
  #       #                              "facility_code" => pcdrsf_res.facility.code,
  #       #                              "facility_name" => pcdrsf_res.facility.name,
  #       #                              "sdf_type" => String.capitalize(pcdrsf.sdf_type),
  #       #                              "sdf_amount" => pcdrsf_res.sdf_amount,
  #       #                              "sdf_percentage" => pcdrsf_res.sdf_percentage,
  #       #                              "sdf_special_handling" => sdf_special_handling}))
  #      else
  #        _ ->
  #        json(conn, Poison.encode!(false))
  #      end

  # end

  defp get_amount(_, nil), do: 0
  defp get_amount(true, value) do
    value = String.split(value, ".")

    value1 =
      value
      |> Enum.at(0)
      |> String.to_integer
      |> Integer.to_char_list
      |> Enum.reverse
      |> Enum.chunk(3, 3, [])
      |> Enum.join(",")
      |> String.reverse

    "#{value1}.#{Enum.at(value, 1)}"
  end

  defp get_amount(false, nil), do: 0
  defp get_amount(false, ""), do: 0
  defp get_amount(false, value) do
    value
    |> String.to_integer
    |> Integer.to_char_list
    |> Enum.reverse
    |> Enum.chunk(3, 3, [])
    |> Enum.join(",")
    |> String.reverse
  end

  defp string_capitalize(nil), do: nil
  defp string_capitalize(param) do
    String.capitalize(param)
  end
  def update_product_coverage_risk_share_dental(conn, params) do
    with facility <-  ProductContext.get_product_coverage_dental_risk_share_facility(params["pcdrsf_id"]),
         {:ok, pcdrsf} <- ProductContext.update_product_coverage_dental_risk_share_facility(%{
           "product_coverage_dental_risk_share_facility_id" => params["pcdrsf_id"],
           "sdf_type" => params["risk_share"],
           "sdf_amount" => Decimal.new(params["value"]),
           "sdf_percentage" => Decimal.new(params["value"]),
           "sdf_special_handling" => params["type"]
         }),
         pcdrsf_res = %ProductCoverageDentalRiskShareFacility{}  <- ProductContext.get_pcdrsf_by_id(params["pcdrsf_id"])
    do
      sdf_amount =
        if not is_nil(pcdrsf_res.sdf_amount) do
          get_amount(String.contains?(Decimal.to_string(pcdrsf_res.sdf_amount), "."), Decimal.to_string(pcdrsf_res.sdf_amount))
        else
          nil
        end

      sdf_special_handling = pcdrsf.sdf_special_handling || "N/A"
      sdf_type = pcdrsf.sdf_type || "N/A"
      json(conn, Poison.encode!(%{"id" => pcdrsf.id,
                                  "product_coverage_dental_risk_share_id" => pcdrsf.product_coverage_dental_risk_share_id,
                                  "facility_id" => pcdrsf.facility_id,
                                  "facility_code" => pcdrsf_res.facility.code,
                                  "facility_name" => pcdrsf_res.facility.name,
                                  "sdf_type" => string_capitalize(pcdrsf.sdf_type),
                                  "sdf_amount" => sdf_amount,
                                  "sdf_percentage" => pcdrsf_res.sdf_percentage,
                                  "sdf_special_handling" => sdf_special_handling}))
    else
      _ ->
      json(conn, Poison.encode!(false))
    end
  end

  def create_product_coverage_risk_share_dental(conn, params) do
    with %ProductCoverageDentalRiskShare{} = pcdrs <-  ProductContext.get_pcdrs_by_id(params["id"]),
         {:ok, pcdrsf} <- ProductContext.insert_product_coverage_dental_risk_share_facility(%{
                            "product_coverage_dental_risk_share_id" => pcdrs.id,
                            "facility_id" => params["facility_id"],
                            "sdf_type" => params["risk_share"],
                            "sdf_amount" => params["value"],
                            "sdf_percentage" => params["value"],
                            "sdf_special_handling" => params["type"]
                          }),
        pcdrsf_res = %ProductCoverageDentalRiskShareFacility{}  <- ProductContext.get_pcdrsf_by_id(pcdrsf.id)
    do
      sdf_amount =
        if not is_nil(pcdrsf_res.sdf_amount) do
          get_amount(String.contains?(Decimal.to_string(pcdrsf_res.sdf_amount), "."), Decimal.to_string(pcdrsf_res.sdf_amount))
        else
          nil
        end
      # sdf_percentage = ProductDentalRiskShareDatatable.get_amount(String.contains?(params["value"], "."), params["value"])
      sdf_special_handling = pcdrsf.sdf_special_handling || "N/A"
      json(conn, Poison.encode!(%{"id" => pcdrsf.id,
                                  "product_coverage_dental_risk_share_id" => pcdrsf.product_coverage_dental_risk_share_id,
                                  "facility_id" => pcdrsf.facility_id,
                                  "facility_code" => pcdrsf_res.facility.code,
                                  "facility_name" => pcdrsf_res.facility.name,
                                  "sdf_type" => string_capitalize(pcdrsf.sdf_type),
                                  "sdf_amount" => sdf_amount,
                                  "sdf_percentage" => pcdrsf_res.sdf_percentage,
                                  "sdf_special_handling" => sdf_special_handling}))
    else
      _ ->
      json(conn, Poison.encode!(false))
    end
  end

  def load_dental_benefit_index(conn, params) do
    count = ProductDentalBenefitDatatable.benefit_count(params["product_id"])

    data =
      params["start"]
      |> ProductDentalBenefitDatatable.benefit_data(
        params["length"],
        params["search"]["value"],
        params["order"]["0"],
        params["product_id"]
      )

    filtered_count =
      params["search"]["value"]
      |> ProductDentalBenefitDatatable.benefit_filtered_count(params["product_id"])

    conn
    |> json(%{
      data: data,
      draw: params["draw"],
      recordsTotal: count,
      recordsFiltered: filtered_count
    })
  end

  def load_dental_facility_index(conn, params) do

    type = ProductContext.get_dental_product_coverage_type(params["product_id"])

    case type do
      "exception" ->
        count = ProductDentalFacilityDatatable.facility_count(params["product_id"])

        facility_param =
          %{offset: params["length"],
            limit: params["search"]["value"],
            search_value: params["order"]["0"],
            order: params["order"]["0"],
            product_id: params["product_id"],
            step: 4}
        data =
          params["start"]
          |> ProductDentalFacilityDatatable.facility_data(facility_param)

        filtered_count =
          params["search"]["value"]
          |> ProductDentalFacilityDatatable.facility_filtered_count(params["product_id"])

        conn
        |> json(%{
          data: data,
          draw: params["draw"],
          recordsTotal: count,
          recordsFiltered: filtered_count
        })

      "inclusion" ->
        count = ProductDentalFacilityInclusionDatatable.facility_count(params["product_id"])

        inclusion_param =
          %{offset: params["length"],
            limit: params["search"]["value"],
            search_value: params["order"]["0"],
            order: params["order"]["0"],
            product_id: params["product_id"],
            step: 4}
        data =
          params["start"]
          |> ProductDentalFacilityInclusionDatatable.facility_data(inclusion_param)

        filtered_count =
          params["search"]["value"]
          |> ProductDentalFacilityInclusionDatatable.facility_filtered_count(params["product_id"])

        conn
        |> json(%{
          data: data,
          draw: params["draw"],
          recordsTotal: count,
          recordsFiltered: filtered_count
        })
        _ ->

        conn
        |> json(%{
          data: [],
          draw: params["draw"],
          recordsTotal: 0,
          recordsFiltered: 0
        })

    end
  end

  def load_dental_risk_share_index(conn, params) do
    count = ProductDentalRiskShareDatatable.risk_share_count(params["product_id"])

    data =
      params["start"]
      |> ProductDentalRiskShareDatatable.risk_share_data(
        params["length"],
        params["search"]["value"],
        params["order"]["0"],
        params["product_id"]
      )

    filtered_count =
      params["search"]["value"]
      |> ProductDentalRiskShareDatatable.risk_share_filtered_count(params["product_id"])

    conn
    |> json(%{
      data: data,
      draw: params["draw"],
      recordsTotal: count,
      recordsFiltered: filtered_count
    })
  end

  def load_dental_facility_index2(conn, params) do
    with nil <- check_dental_id(params["product_id"]) do
      conn
      |> json(%{
        valid: false
      })
    else
      _ ->
        count = ProductDentalFacilityDatatable.facility_count(params["product_id"])

        facility_param =
          %{offset: params["length"],
            limit: params["search"]["value"],
            search_value: params["order"]["0"],
            order: params["order"]["0"],
            product_id: params["product_id"],
            step: 2}
        data =
          params["start"]
          |> ProductDentalFacilityDatatable.facility_data(facility_param)

          filtered_count =
            params["search"]["value"]
            |> ProductDentalFacilityDatatable.facility_filtered_count(params["product_id"])

            conn
            |> json(%{
              data: data,
              draw: params["draw"],
              recordsTotal: count,
              recordsFiltered: filtered_count
            })
    end
  end

  defp check_dental_id(product_id), do: product_id
  defp check_dental_id(nil), do: nil

end
