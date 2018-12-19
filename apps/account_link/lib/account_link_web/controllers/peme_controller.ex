defmodule AccountLinkWeb.PemeController do
  use AccountLinkWeb, :controller

  # alias AccountLink.Guardian.Plug
  import Ecto.{Query, Changeset}, warn: false
  alias Ecto.Changeset
  alias Innerpeace.Db.{
    Repo,
    Schemas.Member,
    Schemas.Peme,
    Schemas.Facility,
    Base.MemberContext,
    Base.CoverageContext,
    Base.PackageContext,
    Base.AccountContext,
    Base.BenefitContext,
    Base.ApiAddressContext,
    Base.Api.UtilityContext,
    Base.PackageContext,
    Datatables.PemeDatatable
  }

  alias Innerpeace.{
    Db.Utilities.SMS,
    AccountLink.EmailSmtp,
    AccountLink.Mailer
  }

  alias AccountLinkWeb.PemeView
  alias Phoenix.View

  def index(conn, _params) do
    id = conn.assigns.current_user.user_account.account_group_id
    if check_peme_product(conn) do
      changeset = Member.changeset_general(%Member{}, %{})
      # peme = MemberContext.get_all_peme(id)
      render(conn, "index.html", peme: [], changeset: changeset, locale: conn.assigns.locale)
    else
      conn
      |> redirect(to: member_path(conn, :index, conn.assigns.locale))
    end
  end

  def load_index(conn, params) do
    id = conn.assigns.current_user.user_account.account_group_id
    ag = AccountContext.get_account_group(id)
    count = PemeDatatable.peme_count(ag)

    data =
      PemeDatatable.peme_data(%{
        offset: params["start"],
        limit: params["length"],
        search_value: params["search"]["value"],
        ag: ag,
        locale: conn.assigns.locale,
        order: params["order"]["0"]
      })

    filtered_count =
      params["search"]["value"]
      |> PemeDatatable.peme_filtered_count(ag)

    conn
    |> json(%{
      data: data,
      draw: params["draw"],
      recordsTotal: count,
      recordsFiltered: filtered_count
    })
  end

  def new_peme(conn, _params) do
    id = conn.assigns.current_user.user_account.account_group_id
    coverage = CoverageContext.get_coverage_by_code("PEME")
    account_group = AccountContext.get_account_group(id)
    account = AccountContext.get_account_by_account_group(account_group.id)
    packages = get_package_filter_from_account(account, coverage)
    facilities = get_facility_filter_from_account(account, coverage)
    changeset = Peme.changeset(%Peme{})
    render(conn, "generate_evoucher.html", changeset: changeset, packages: packages, facilities: facilities, account: account)
  end

  defp get_product_from_account(account) do
    product =
      Enum.map(account.account_products, & (if &1.product.product_category == "PEME Plan", do: &1.product))

    product =
      product
      |> Enum.uniq()
      |> List.delete(nil)
  end

  defp get_account_product_from_account(account) do
    Enum.filter(account.account_products, & (if &1.product.product_category == "PEME Plan", do: &1))
  end

  defp get_package_filter_from_account(account, coverage) do
    products = get_product_from_account(account)
    benefits =
      for product <- products do
        Enum.map(product.product_benefits, & (
          if List.first(&1.benefit.benefit_coverages).coverage.id == coverage.id do
            &1.benefit.id
          end
        ))
      end

    benefits =
      benefits
      |> List.flatten()
      |> Enum.uniq()
      |> List.delete(nil)

    packages = for benefit_id <- benefits do
      benefit = BenefitContext.get_benefit(benefit_id)
      Enum.map(benefit.benefit_packages, & (&1.package))
    end

    packages =
      packages
      |> List.flatten()
      |> Enum.uniq()
      |> List.delete(nil)
  end

  defp get_facility_filter_from_account(account, coverage) do
    products = get_product_from_account(account)
    facilities_id =
      for product <- products do
        for product_coverage <- product.product_coverages do
          if product_coverage.coverage_id == coverage.id do
            if product_coverage.type == "inclusion" do
              Enum.map(product_coverage.product_coverage_facilities, & (&1.facility.id))
            else
              get_all_facility_id -- Enum.map(product_coverage.product_coverage_facilities, & (&1.facility.id))
            end
          end
        end
      end
    facilities_id =
      facilities_id
      |> List.flatten()
      |> Enum.uniq()
      |> List.delete(nil)
    facilities =
      Facility
      |> where([f], f.id in ^facilities_id)
      |> where([f], f.step > 6 and f.status == "Affiliated")
      |> order_by([f], asc: f.name)
      |> Repo.all()
  end

  defp get_all_facility_id do
    Facility
    |> select([f], f.id)
    |> Repo.all()
  end

  def peme_generate_evoucher(conn, %{"peme" => params, "locale" => locale}) do
    if is_nil(params["package_id"]) do
      redirect(conn, to: "/#{locale}/peme/new")
    else
      id = conn.assigns.current_user.user_account.account_group_id
      account_group = AccountContext.get_account_group(id)
      account = AccountContext.get_account_by_account_group(account_group.id)
      account_products = get_account_product_from_account(account)
      params = Map.put(params, "created_by_id", conn.assigns.current_user.id)
      params = Map.put(params, "updated_by_id", conn.assigns.current_user.id)
      MemberContext.insert_peme_member_v2(
        params, params["member_count"], account_products, account_group
      )

      conn
      |> put_flash(:info, "E-voucher has been generated successfully.")
      |> redirect(to: "/#{locale}/peme")
    end
  end

  def peme_send_voucher(conn, %{"peme" => params, "locale" => locale}) do
    if is_nil(params["package_id"]) do
      redirect(conn, to: "/#{locale}/peme/new")
    else
      id = conn.assigns.current_user.user_account.account_group_id
      account_group = AccountContext.get_account_group(id)
      account = AccountContext.get_account_by_account_group(account_group.id)
      account_products = get_account_product_from_account(account)
      MemberContext.send_evoucher_electronically(
        params, params["member_count"], account_products, account_group, locale
      )

      conn
      |> put_flash(:info, "E-voucher has been send to email or mobile")
      |> redirect(to: "/#{locale}/peme")
    end
  end

  def random_peme_id(counts, chars) do
    data = for count <- 1..counts do
      get_random(chars)
    end
    id =
      data
      |> Enum.join("")

    checker =
      Peme
      |> where([p], p.peme_id == ^id)
      |> Repo.all()
    if Enum.empty?(checker) do
      id
    else
      random_peme_id(8, chars)
    end
  end

  def get_random(chars) do
    data = Enum.random(chars)
    if data == "" do
      get_random(chars)
    else
      data
    end
  end

  def show_peme_member_details(conn, params) do
    id = params["id"]
    show_swall = params["show_swall"]
    show_swall_cancel = params["show_swall_cancel"] || ""
    peme = MemberContext.get_peme(id)
    changeset = Member.changeset_general(%Member{}, %{})
    evoucher = nil
    fail = "failed"

    if show_swall == "true" do
      render(
        conn, "peme_member_details.html",
        peme: peme, show_swall: true, show_swall_cancel: false,
        changeset: changeset, evoucher: evoucher
      )
    end

    cond do
      show_swall_cancel =~ "true" ->
        m_id =
          show_swall_cancel
          |> String.split("=")
          |> Enum.at(1)
          evoucher = MemberContext.get_member_evoucher(m_id)
          render(
            conn,
            "peme_member_details.html",
            peme: peme, show_swall: false,
            show_swall_cancel: true,
            changeset: changeset,
            evoucher: evoucher
          )
      show_swall_cancel =~ "failed" ->
        m_id =
          show_swall_cancel
          |> String.split("=")
          |> Enum.at(1)
          evoucher = MemberContext.get_member_evoucher(m_id)
          render(
            conn,
            "peme_member_details.html",
            peme: peme,
            show_swall: false,
            show_swall_cancel: fail,
            changeset: changeset,
            evoucher: evoucher
          )
      true ->
        render(
          conn,
          "peme_member_details.html",
          peme: peme,
          show_swall: false,
          show_swall_cancel: false,
          changeset: changeset,
          evoucher: evoucher
        )
    end
  end

  def get_package_with_facility_and_procedures(conn, %{"id" => id, "account_id" => account_id}) do
    package = PackageContext.get_package(id)
    coverage = CoverageContext.get_coverage_by_code("PEME")
    account = AccountContext.get_account(account_id)
    facilities = get_facility_filter_from_account(account, coverage)
    params = %{package: package, facilities: facilities}

    render(conn, "package.json", params: params)
  end

  def show_peme_summary(conn, %{"id" => id, "locale" => locale}) do
    with {:ok, peme} <- validate_peme(conn, id)
    do
      changeset = Peme.changeset(%Peme{}, %{})
      render(conn,
        "show_peme_summary.html",
        changeset: changeset,
        locale: locale,
        peme: peme
      )
    else
      {:invalid, message} ->
        redirect_to_index(conn, message)
      _ ->
        redirect_to_index(conn, "Error has been occured")
    end
  end
  def show_peme_summary(conn, _), do: redirect_to_index(conn, "Page not found")

  defp validate_peme(conn, nil), do: {:invalid, "Invalid PEME ID"}
  defp validate_peme(conn, ""), do: {:invalid, "Invalid PEME ID"}
  defp validate_peme(conn, id), do: validate_peme_v2(conn, MemberContext.get_peme(id))
  defp validate_peme_v2(conn, nil), do: {:invalid, "PEME not found"}
  defp validate_peme_v2(_, peme), do: {:ok, peme}

  defp redirect_to_index(conn, message) do
    conn
    |> put_flash(:error, message)
    |> redirect(to: "/peme")
  end

  # Functions for enrollment of single PEME

  # def new_single(conn, _params) do
  #   # Display form for enrollment of new PEME Member

  #   changeset = Member.al_peme_changeset_general(%Member{})
  #   render(conn, "new.html", changeset: changeset)
  # end

  # def show_single(conn, %{"id" => id, "step" => step}) do
  #   # Routes for creation wizard

  #   member = MemberContext.get_member!(id)
  #   case step do
  #     "1" ->
  #       step1(conn, member)
  #     "2" ->
  #       step2(conn, member)
  #     "3" ->
  #       step3(conn, member)
  #     _ ->
  #       conn
  #       |> put_flash(:error, "Invalid Step")
  #       |> redirect(to: page_path(conn, :index, conn.assigns.locale))
  #   end
  # end

  # def update_single(conn, %{"id" => id, "tab" => tab, "member" => member}) do
  #   # Updates a member record

  #   case tab do
  #     "general" ->
  #       update_general(conn, id, member)
  #     "contact" ->
  #       update_contact(conn, id, member)
  #     _ ->
  #       conn
  #       |> put_flash(:error, "Invalid Step")
  #       |> redirect(to: "/")
  #   end
  # end

  # def create(conn, %{"member" => member}) do
  #   # Inserts a new member record

  #   card_no = MemberContext.member_card_checker("1168011034280092")

  #   member =
  #     member
  #     |> Map.put("step", "2")
  #     |> Map.put("status", "peme")
  #     |> Map.put("created_by_id", conn.assigns.current_user.id)
  #     |> Map.put("card_no", card_no)

  #   case MemberContext.single_peme_create(member) do
  #     {:ok, member} ->
  #       conn
  #       |> put_flash(:info, "All fields in general step passed.")
  #       |> redirect(to: "/peme/#{member.id}/single?step=2")
  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       conn
  #       |> put_flash(:error, "Please enter a value on all required fields.")
  #       |> render("new.html", changeset: changeset)
  #   end
  # end

  # defp step1(conn, member) do
  #   # Renders form for updating general fields

  #   changeset = Member.al_peme_changeset_general(member)
  #   render(conn, "step1.html", member: member, changeset: changeset)
  # end

  # defp step2(conn, member) do
  #   # Renders form for updating contact fields

  #   changeset = Member.al_peme_changeset_contact(member)
  #   render(conn, "step2.html", member: member, changeset: changeset)
  # end

  # defp step3(conn, member) do
  #   # Renders form for requesting loa
  #   changeset = PemeLoa.changeset(%PemeLoa{})
  #   render(conn, "step3.html", member: member, changeset: changeset)
  # end

  # def show_summary(conn, %{"id" => id}) do
  #   # Renders form for summary

  #   member = MemberContext.get_member!(id)
  #   peme_loa = MemberContext.get_peme_loa(member.id)
  #   render(conn, "summary.html", member: member, peme_loa: peme_loa)
  # end

  # defp update_general(conn, id, member) do
  #   # Update general member fields

  #   member =
  #     member
  #     |> Map.put("step", "2")
  #     |> Map.put("updated_by_id", conn.assigns.current_user.id)

  #   case MemberContext.single_peme_update_general(id, member) do
  #     {:ok, member} ->
  #       conn
  #       |> put_flash(:info, "Member was succesfully updated.")
  #       |> redirect(to: "/peme/#{member.id}/single?step=2")
  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       conn
  #       |> put_flash(:error, "Please enter a value on all required fields.")
  #       |> render("step1.html", changeset: changeset, member: member)
  #   end
  # end

  # defp update_contact(conn, id, member) do
  #   # Update contact member fields

  #   member =
  #     member
  #     |> Map.put("step", "3")
  #     |> Map.put("updated_by_id", conn.assigns.current_user.id)

  #   case MemberContext.single_peme_update_contact(id, member) do
  #     {:ok, member} ->
  #       conn
  #       |> put_flash(:info, "All fields in general step passed.")
  #       |> redirect(to: "/peme/#{member.id}/single?step=3")
  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       member = MemberContext.get_member!(id)
  #       conn
  #       |> put_flash(:error, "Please enter a value on all required fields.")
  #       |> render("step2.html", changeset: changeset, member: member)
  #   end
  # end

  # def update_request_loa(conn, params) do
  #   # Generate Request loa

  #   id = params["id"]
  #   peme_loa = params["peme_loa"]

  #   peme_loa =
  #     peme_loa
  #     |> Map.put("member_id", id)

  #   member = MemberContext.get_member!(id)

  #   params = %{
  #     step: "4",
  #     updated_by_id: conn.assigns.current_user.id
  #   }

  #   MemberContext.update_member_ste
  #   p(member, params)

  #   case MemberContext.single_peme_request_loa(peme_loa) do
  #     {:ok, peme_loa} ->
  #       conn
  #       |> put_flash(:info, "PEME Member was successfully created.")
  #       |> redirect(to: "/peme/#{peme_loa.member_id}/summary")
  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       member = MemberContext.get_member!(id)
  #       conn
  #       |> put_flash(:error, "Please enter a value on all required fields.")
  #       |> render("step3.html", changeset: changeset, member: member)
  #   end
  # end

  # def load_packages(conn, _params) do
  #   # Loads all packages
  #   member_id = conn.assigns[:current_user].member_id
  #   packages = MemberContext.load_packages(member_id)
  #   json conn, Poison.encode!(packages)
  # end

  # def load_package(conn, params) do
  #   # Loads a package

  #   package_id = params["package_id"]

  #   package = MemberContext.load_package(package_id)
  #   render(conn, AccountLinkWeb.PemeView, "package.json", package: package)
  # end

  defp check_peme_product(conn) do
    id = conn.assigns.current_user.user_account.account_group_id
    account_group = AccountContext.get_account_group(id)
    account = AccountContext.get_account_by_account_group(account_group.id)
    product =
      Enum.map(account.account_products, & (if &1.product.product_category == "PEME Plan", do: &1))

    product =
      product
      |> Enum.uniq()
      |> List.delete(nil)

    if product == [] do
      false
    else
      true
    end
  end

  def cancel_evoucher(conn, %{"locale" => locale, "member" => params}) do
    params = check_cancel_reason(params)
    #update member_status to canceled
    peme = MemberContext.get_peme(params["peme_id"])

    if is_nil(peme.member_id) do
      MemberContext.cancel_evoucher_peme(peme, params)
      conn
      |> json(Poison.encode!(true))
    else
      with {:ok} <- MemberContext.validate_cancel_evoucher(params["member_id"]) do
        conn
        |> json(Poison.encode!(true))
      else
        {:error} ->
          conn
          |> json(Poison.encode!(false))
        _  ->
          conn
          |> json(Poison.encode!(false))
      end
    end
  end

  defp check_cancel_reason(params) do
    if params["cancel_reason"] == "Others" do
      Map.put(params, "cancel_reason", params["cancel_others"])
    else
      params
    end
  end

  # def update_loa_peme_status(conn, params) do
  #   loa_id = params["authorization_id"]
  #   with {:ok, authorization} <- AuthorizationAPI.update_loa_peme_status(loa_id, status) do
  #     conn
  #     |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "message.json", message: "success")
  #   else
  #     true ->
  #       conn
  #       |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "message.json", message: "Invalid parameters")
  #     _ ->
  #       conn
  #       |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "message.json", message: "loa not found")
  #   end
  # end

  def render_evoucher(conn, %{"id" => id, "locale" => locale}) do
    with {:ok, peme} <- validate_peme(conn, id)
    do
      html =
        View.render_to_string(
          PemeView,
          "print/render_evoucher.html",
          peme: peme,
          locale: locale
        )
      json conn, %{html: html}
    else
      {:invalid, message} ->
        json conn, %{html: message}
      _ ->
        json conn, %{html: "Error has been occured"}
    end
  end
  def render_evoucher(conn, _), do: json conn, %{html: "Error has been occured"}

  def print_evoucher(conn, %{"id" => peme_member_id}) do
    peme_member = MemberContext.get_peme_member(peme_member_id)

    if not is_nil(peme_member) do
      html = View.render_to_string(
        PemeView,
        "print/evoucher.html",
        peme_member: peme_member
      )
      {date, time} = :erlang.localtime
      unique_id =  "#{peme_member.member.last_name}_#{peme_member.member.first_name}" #Enum.join(Tuple.to_list(date)) <> Enum.join(Tuple.to_list(time))
      filename = "evoucher_#{unique_id}"

      {:ok, content} = PdfGenerator.generate_binary(html, filename: filename, delete_temporary: true)

      conn
      |> put_resp_content_type("application/pdf")
      |> put_resp_header("content-disposition", "attachment; filename=#{filename}.pdf")
      |> send_resp(200, content)
    else
      json conn, %{result: "Peme member has not been found."}
    end
  end

  def export_evoucher(conn, params) do
    pemes = get_struct(params["peme"]["peme_ids"])
    address = ApiAddressContext.get_api_address_by_name("PORTAL")
    if not Enum.empty?(pemes) do
      if address do
        html = View.render_to_string(
          PemeView,
          "print/multiple_evoucher.html",
          address: address,
          peme: pemes,
          locale: params["locale"]
        )
        {date, time} = :erlang.localtime
        filename = "multiple_evoucher_#{Enum.join(Tuple.to_list(date))}_#{Enum.join(Tuple.to_list(time))}"
        {:ok, content} = PdfGenerator.generate_binary(html, filename: filename, delete_temporary: true)

        conn
        |> put_resp_content_type("application/pdf")
        |> put_resp_header("content-disposition", "attachment; filename=#{filename}.pdf")
        |> send_resp(200, content)
      else
        conn
        |> put_flash(:error, "Error. Url not found")
        |> redirect(
          to: "/#{params["locale"]}/peme"
        )
      end
    else
      json conn, %{result: "Peme member has not been found."}
    end
  end

  defp get_struct(peme_ids) do
    ids =
      peme_ids
      |> String.split(",")
      |> Enum.map(&(Enum.at(String.split(&1, "_"), 0)))

    pemes =
      Peme
      |> where([p], p.id in ^ids)
      |> order_by([p], desc: p.inserted_at)
      |> Repo.all()
      |> Repo.preload([
        :facility,
        :account_group,
        [
          member: :account_group
        ],
        [
          package: :package_payor_procedure
        ],
        [
          peme_members: [
            member: [
              :authorizations
            ]
          ]
        ]
      ])

    pemes = for peme <- pemes do
      peme_ids
      |> String.split(",")
      |> Enum.map(fn(peme_id) ->
        if peme.id == Enum.at(String.split(peme_id, "_"), 0) do
          %{
            data: peme,
            account_group: peme.account_group,
            canvas: "data:image/png;base64,#{Enum.at(String.split(peme_id, "_"), 1)}"
          }
        end
      end)
    end

    pemes =
      pemes
      |> List.flatten()
      |> Enum.uniq()
      |> List.delete(nil)

      # peme_ids
      # |> String.split(",")
      # |> Enum.into([], &(
      #   %{
      #     data: MemberContext.get_peme(Enum.at(String.split(&1, "_"), 0)),
      #     canvas:  "data:image/png;base64,#{Enum.at(String.split(&1, "_"), 1)}"
      #   }
      # ))
      # |> Enum.sort_by(&(&1.data.request_date))
  end

  def print_preview_evoucher(conn, params) do
    peme_id = params["id"]
    peme = MemberContext.get_peme(peme_id)

    if not is_nil(peme) do
      html = View.render_to_string(
        PemeView,
        "print/evoucher.html",
        peme: peme,
        locale: params["locale"],
        canvas: params["print_qrcode_evoucher"]
      )
      {date, time} = :erlang.localtime
      # unique_id =  "#{peme.member.last_name}_#{peme.member.first_name}" #Enum.join(Tuple.to_list(date)) <> Enum.join(Tuple.to_list(time))
      unique_id = "#{peme.evoucher_number}"
      filename = "evoucher_#{unique_id}"
      {:ok, file} = PdfGenerator.generate(html, filename: filename)
      {:ok, content} = File.read file

      conn
      |> put_resp_content_type("application/pdf")
      |> put_resp_header("content-disposition", "attachment; filename=#{filename}.pdf")
      |> send_resp(200, content)

    else
      json conn, %{result: "Peme member has not been found."}
    end
  end

  def create_peme_member(conn, %{"evoucher" => params, "locale" => locale, "id" => id}) do
    if is_nil(params["primary_id"]) and params["primary_photo"] == "" do 
      conn
      |> put_flash(:error, "Please Upload Primary ID")
      |> redirect(to: "/#{conn.assigns.locale}/peme/#{id}/register_peme")
    else
      peme_fag = MemberContext.get_peme_facility(id)
      account_group_id = peme_fag.peme_ag
      account_code = peme_fag.account_code
      account = AccountContext.get_account_by_account_group(account_group_id)
      account_products = get_account_product_from_account(account)
      peme_facility = peme_fag.peme_fac
      birthdate =
        params["birthdate"]
        |>  UtilityContext.transform_date_search()
      mobile = String.replace(params["mobile"], "-", "")

      peme = MemberContext.get_peme(id)
      # mobiles = MemberContext.get_all_mobile(peme.account_group.code, peme.id)

      package = PackageContext.get_package(peme.package_id)
      package_payor_procedure = package.package_payor_procedure
                                |> List.first()
      params =
        params
        |> Map.put("birthdate", birthdate)
        |> Map.put("account_code", account_code)
        |> Map.put("mobile", mobile)
        |> Map.put("status", "Active")
        |> Map.put("step", 5)
        |> Map.put("created_by_id", conn.assigns.current_user.id)
        |> Map.put("updated_by_id", conn.assigns.current_user.id)
        |> Map.put("type", "Principal")
        |> Map.put("effectivity_date", account.start_date)
        |> Map.put("expiry_date", account.end_date)
        |> Map.put("temporary_member", true)

      with {:ok, member} <- MemberContext.insert_evoucher_member(params)
      do
        peme =
          MemberContext.get_peme(id)
          |> MemberContext.insert_peme_member_id(member.id)
    
        if params["primary_photo"] == "" do
          if params["primary_id"] do
            MemberContext.update_primary_id(member, params)
          end
        else
          primary_photo = MemberContext.convert_base_64_image(%{
            "filename" => "primary_id",
            "extension" => "png",
            "photo" => params["primary_photo"]})
            
          MemberContext.update_primary_id(member, %{"primary_id" => primary_photo})
          MemberContext.delete_local_image(%{"filename" => "primary_id", "extension" => "png"})
        end

        if params["secondary_photo"] == "" do
          if params["secondary_id"] do
            MemberContext.update_secondary_id(member, params)
          else
            MemberContext.update_secondary_id(member, %{"secondary_id" => nil})
          end
        else
          secondary_photo = MemberContext.convert_base_64_image(%{
            "filename" => "secondary_id",
            "extension" => "png",
            "photo" => params["secondary_photo"]})

          MemberContext.update_secondary_id(member, %{"secondary_id" => secondary_photo})
          MemberContext.delete_local_image(%{"filename" => "secondary_id", "extension" => "png"})
        end

        for {account_product, tier} <- Enum.with_index(account_products, 1) do
          member_product_param = %{
            member_id: member.id,
            account_product_id: account_product.id,
            tier: tier
          }
          MemberContext.create_a_member_product(member_product_param)
        end

        conn
        |> redirect(
          to: "/#{conn.assigns.locale}/members/evoucher/#{id}/facility_edit"
        )
      else
        {:invalid, message} ->
          peme = MemberContext.get_peme(id)
          changeset = Member.changeset_update_evoucher(peme)
          conn
          |> put_flash(:error, message)
          |> render(
            "register_peme.html",
            id: id,
            member: peme,
            changeset: changeset,
            evoucher: peme.evoucher_number,
            # mobiles: Poison.encode!(mobiles),
            package_payor_procedure: package_payor_procedure,
            account_code: peme.account_group.code
          )
        {:error, changeset} ->
          peme = MemberContext.get_peme(id)
          conn
          |> put_flash(:error, "Please check your inputs")
          |> render(
            "register_peme.html",
            id: id,
            member: peme,
            changeset: changeset,
            evoucher: peme.evoucher_number,
            # mobiles: Poison.encode!(mobiles),
            package_payor_procedure: package_payor_procedure,
            account_code: peme.account_group.code
          )
      end
    end
  end

  def register_peme(conn, %{"id" => id}) do
    peme = MemberContext.get_peme(id)
    changeset = Member.changeset_update_evoucher(%Member{})
    # mobiles = MemberContext.get_all_mobile(peme.account_group.code, peme.id)

    package = PackageContext.get_package(peme.package_id)
    package_payor_procedure = package.package_payor_procedure
                              |> List.first()

    render(
      conn, "register_peme.html", changeset: changeset, package_payor_procedure: package_payor_procedure,
      id: id, account_code: peme.account_group.code
    )
  end

  def edit_register_peme(conn, %{"id" => id}) do
    peme = MemberContext.get_peme(id)
    member = MemberContext.get_a_member!(peme.member_id)
    changeset = Member.changeset_update_evoucher(member)
    # mobiles = MemberContext.get_all_mobile(peme.account_group.code, member.id)

    package = PackageContext.get_package(peme.package_id)
    package_payor_procedure = package.package_payor_procedure
                              |> List.first()
    render(
      conn, "edit_register_peme.html", changeset: changeset,
      id: peme.id, member: member, package: package, package_payor_procedure: package_payor_procedure,
      account_code: peme.account_group.code
    )
  end

  def update_peme_member2(conn, %{"evoucher" => params, "locale" => locale, "id" => id}) do
    if is_nil(params["primary_id"]) and params["primary_photo"] == "" do 
      conn
      |> put_flash(:error, "Please Upload Primary ID")
      |> redirect(to: "/#{conn.assigns.locale}/peme/#{id}/edit_register_peme")
    else
      peme = MemberContext.get_peme(id)
      member = MemberContext.get_a_member!(peme.member_id)
      changeset = Member.changeset_update_evoucher(member, params)
      # mobiles = MemberContext.get_all_mobile(peme.account_group.code, member.id)
      birthdate =
        params["birthdate"]
        |>  UtilityContext.transform_date_search()
      mobile = String.replace(params["mobile"], "-", "")
  
      package = PackageContext.get_package(peme.package_id)
      package_payor_procedure = package.package_payor_procedure
                                |> List.first()
      params =
        params
        |> Map.put("birthdate", birthdate)
        |> Map.put("mobile", mobile)
  
      with {:ok, member} <- MemberContext.update_evoucher_member(member, params)
      do
        if params["primary_photo"] == "" do
          if params["primary_id"] do
            MemberContext.update_primary_id(member, params)
          end
        else
          primary_photo = MemberContext.convert_base_64_image(%{
            "filename" => "primary_id",
            "extension" => "png",
            "photo" => params["primary_photo"]})
  
          MemberContext.update_primary_id(member, %{"primary_id" => primary_photo})
          MemberContext.delete_local_image(%{"filename" => "primary_id", "extension" => "png"})
        end
  
        if params["secondary_photo"] == "" do
          if params["secondary_id"] do
            MemberContext.update_secondary_id(member, params)
          else
            MemberContext.update_secondary_id(member, %{"secondary_id" => nil})
          end
        else
          secondary_photo = MemberContext.convert_base_64_image(%{
            "filename" => "secondary_id",
            "extension" => "png",
            "photo" => params["secondary_photo"]})
  
          MemberContext.update_secondary_id(member, %{"secondary_id" => secondary_photo})
          MemberContext.delete_local_image(%{"filename" => "secondary_id", "extension" => "png"})
        end
  
        conn
        |> put_flash(:info, "Member Details Successfully Updated ")
        |> redirect(
          to: "/#{conn.assigns.locale}/members/evoucher/#{id}/facility_edit"
        )
      else
        {:error, changeset} ->
          conn
          |> put_flash(:error, "Changeset error")
          |> render(
            "edit_register_peme.html",
            id: id,
            changeset: changeset,
            member: member,
            # mobiles: Poison.encode!(mobiles),
            package_payor_procedure: package_payor_procedure,
            account_code: peme.account_group.code
          )
        _ ->
          conn
          |> put_flash(:error, "Error")
          |> render(
            "edit_register_peme.html",
            id: id,
            changeset: changeset,
            member: member,
            # mobiles: Poison.encode!(mobiles),
            package_payor_procedure: package_payor_procedure,
            account_code: peme.account_group.code
          )
      end
    end
  end

  def evoucher_summary(conn, %{"id" => peme_id}) do
    peme = MemberContext.get_peme(peme_id)
    render(conn, "evoucher_summary.html", peme: peme)
  end

  def evoucher_summary_print(conn, %{"id" => peme_id, "peme" => peme_params}) do
    peme = MemberContext.get_peme(peme_id)

    if not is_nil(peme) do
      procedures = get_peme_procedures(peme.authorization.authorization_benefit_packages)
      html = Phoenix.View.render_to_string(
        PemeView,
        "evoucher_print_loa.html",
        peme: peme,
        procedures: procedures,
        locale: conn.assigns.locale,
        canvas: peme_params["base64"]
      )
      filename = "#{Ecto.Date.utc()}"
      {:ok, content} = PdfGenerator.generate_binary(html, filename: filename, delete_temporary: true)

      conn
      |> put_resp_content_type("application/pdf")
      |> put_resp_header("content-disposition", "attachment; filename=#{filename}.pdf")
      |> send_resp(200, content)
    else
      json conn, %{result: "Peme member has not been found."}
    end
  end

  defp get_peme_procedures(authorization_benefit_package) do
    authorization_benefit_package =
      authorization_benefit_package
      |> List.first()

    package = PackageContext.get_package(authorization_benefit_package.benefit_package.package_id)

    Enum.map(package.package_payor_procedure, fn(x) ->
      %{
        code: x.payor_procedure.code,
        description: x.payor_procedure.description
      }
    end)
  end

  def evoucher_print_preview(conn, %{"id" => peme_id}) do
    peme = MemberContext.get_peme(peme_id)

    if not is_nil(peme) do
      html = View.render_to_string(
        PemeView,
        "evoucher_preview.html",
        peme: peme
      )
      filename = "#{Ecto.Date.utc()}"
      {:ok, content} = PdfGenerator.generate_binary(html, filename: filename, delete_temporary: true)

      conn
      |> put_resp_content_type("application/pdf")
      |> put_resp_header("content-disposition", "inline; filename=#{filename}.pdf")
      |> send_resp(200, content)
    else
      json conn, %{result: "Peme member has not been found."}
    end
  end

  def evoucher_render(conn, %{"id" => peme_id}) do
    peme = MemberContext.get_peme(peme_id)
    procedures = get_peme_procedures(peme.authorization.authorization_benefit_packages)

    html = Phoenix.View.render_to_string(
      PemeView,
      "evoucher_print_loa.html",
      procedures: procedures,
      peme: peme
    )
    json(conn, %{html: html})
  end

  def remove_primary_id(conn, %{"id" => id}) do
    peme = MemberContext.get_peme(id)
    member = MemberContext.get_a_member!(peme.member_id)
    changeset = Member.changeset_update_evoucher(member)
    mobiles = MemberContext.get_all_mobile(peme.account_group.code, member.id)
    package = PackageContext.get_package(peme.package_id)
    package_payor_procedure = package.package_payor_procedure
                              |> List.first()

    with {:ok, member} <- MemberContext.update_primary_id(member, %{"primary_id" => nil})
    do
      conn
      |> put_flash(:info, "Primary ID Successfully Removed.")
      |> redirect(
        to: peme_path(conn, :edit_register_peme, conn.assigns.locale, id),
        changeset: changeset, id: id, mobiles: Poison.encode!(mobiles), member: member,
        package_payor_procedure: package_payor_procedure,
        account_code: peme.account_group.code
      )
    else
      _->
        conn
        |> put_flash(:error, "Error in Removing Primary ID.")
        |> redirect(
          to: peme_path(conn, :edit_register_peme, conn.assigns.locale, id),
          changeset: changeset, id: id, mobiles: Poison.encode!(mobiles), member: member,
          package_payor_procedure: package_payor_procedure,
          account_code: peme.account_group.code
        )
    end
  end

  def remove_secondary_id(conn, %{"id" => id}) do
    peme = MemberContext.get_peme(id)
    member = MemberContext.get_a_member!(peme.member_id)
    changeset = Member.changeset_update_evoucher(member)
    mobiles = MemberContext.get_all_mobile(peme.account_group.code, member.id)
    package = PackageContext.get_package(peme.package_id)
    package_payor_procedure = package.package_payor_procedure
                              |> List.first()

    with {:ok, member} <- MemberContext.update_secondary_id(member, %{"secondary_id" => nil})
    do
      conn
      |> put_flash(:info, "Secondary ID Successfully Removed.")
      |> redirect(
        to: peme_path(conn, :edit_register_peme, conn.assigns.locale, id),
        changeset: changeset, id: id, mobiles: Poison.encode!(mobiles), member: member,
        package_payor_procedure: package_payor_procedure,
        account_code: peme.account_group.code
      )
    else
      _->
        conn
        |> put_flash(:error, "Error in Removing Secondary ID.")
        |> redirect(
          to: peme_path(conn, :edit_register_peme, conn.assigns.locale, id),
          changeset: changeset, id: id, mobiles: Poison.encode!(mobiles), member: member,
          package_payor_procedure: package_payor_procedure,
          account_code: peme.account_group.code
        )
    end
  end

  def get_peme_member_mobile(conn, %{"account_code" => account_code}) do
    m = MemberContext.get_peme_member_by_mobile(account_code)
    json conn, Poison.encode!(m)
  end
end
