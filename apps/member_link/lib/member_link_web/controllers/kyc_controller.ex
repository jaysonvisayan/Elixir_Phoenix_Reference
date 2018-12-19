defmodule MemberLinkWeb.KycController do
  use MemberLinkWeb, :controller

  # alias Innerpeace.Db.Repo
  alias Innerpeace.Db.Base.{
    KycContext,
    MemberContext,
    DropdownContext
    # EmailContext,
    # PhoneContext
  }
  alias Innerpeace.Db.Schemas.{
    KycBank
  }
  alias MemberLink.Guardian, as: MG

  def new(conn, _params) do
    current_user = MG.current_resource(conn)
    member = MemberContext.get_member!(current_user.member_id)
    countries = KycContext.all_countries()
    dropdowns = DropdownContext.get_dropdown_occupation()

    changeset = KycBank.changeset_step1(%KycBank{})
    render(conn, "step1.html", changeset: changeset, countries: countries, member: member, dropdowns: dropdowns)
  end

  def create(conn, %{"kyc" => kyc_params}) do
    current_user = MG.current_resource(conn)
    member = MemberContext.get_member!(current_user.member_id)
    countries = KycContext.all_countries()
    locale = conn.assigns.locale

    kyc_params =
      kyc_params
      |> Map.put("member_id", member.id)
      |> Map.put("step", 2)

    case KycContext.create_kyc(kyc_params) do
      {:ok, kyc} ->
        conn
        |> put_flash(:info, "Success")
        |> redirect(to: "/#{locale}/kyc/#{kyc.id}/setup?step=2")

      {:error, changeset} ->
        dropdowns = DropdownContext.get_dropdown_occupation()
        conn
        |> put_flash(:error, "Error")
        |> render("step1.html", changeset: changeset, countries: countries, member: member, dropdowns: dropdowns)
    end
  end

  def setup(conn, %{"id" => id, "step" => step}) do
    kyc = KycContext.get_kyc!(id)

    case step do
      "1" ->
        step1(conn, kyc)
      "2" ->
        step2(conn, kyc)
      "3" ->
        step3(conn, kyc)
      "4" ->
        step4(conn, kyc)
      _ ->
        conn
        |> put_flash(:error, "Invalid step!")
    end
  end

  def setup(conn, params) do
    conn
    |> put_flash(:error, "Invalid step!")
    |> redirect(to: "/#{params["locale"]}")
  end

  def update_setup(conn, %{"id" => id, "step" => step, "kyc" => kyc_params}) do
    kyc = KycContext.get_kyc!(id)

    case step do
      "1" ->
        step1_update(conn, kyc, kyc_params)
      "2" ->
        step2_update(conn, kyc, kyc_params)
      "3" ->
        step3_update(conn, kyc, kyc_params)
    end

  end

  def step1(conn, kyc) do
    current_user = MG.current_resource(conn)
    member = MemberContext.get_member!(current_user.member_id)
    countries = KycContext.all_countries()
    dropdowns = DropdownContext.get_dropdown_occupation()

    changeset = KycBank.changeset_step1(kyc)
    render(conn, "step1_edit.html", changeset: changeset, countries: countries, member: member, kyc: kyc, dropdowns: dropdowns)
  end

  def step1_update(conn, kyc, kyc_params) do
    current_user = MG.current_resource(conn)
    member = MemberContext.get_member!(current_user.member_id)
    countries = KycContext.all_countries()
    locale = conn.assigns.locale

    kyc_params =
      kyc_params
      |> Map.put("member_id", member.id)
      |> Map.put("step", 2)

    case KycContext.update_kyc(kyc, kyc_params) do
      {:ok, kyc} ->
        conn
        |> put_flash(:info, "Successfully Updated")
        |> redirect(to: "/#{locale}/kyc/#{kyc.id}/setup?step=2")

      {:error, changeset} ->
        dropdowns = DropdownContext.get_dropdown_occupation()
        conn
        |> put_flash(:error, "Error")
        |> render("step1_edit.html", changeset: changeset, countries: countries, member: member, kyc: kyc, dropdowns: dropdowns)
    end
  end

  def summary(conn, _params) do
    changeset = KycBank.changeset(%KycBank{})
    render(conn, "step4.html", changeset: changeset)
  end

  def step2_update(conn, kyc, kyc_params) do
    current_user = MG.current_resource(conn)
    member = MemberContext.get_member!(current_user.member_id)
    countries = KycContext.all_countries()
    locale = conn.assigns.locale
    cities = KycContext.all_cities()

    kyc_params =
      kyc_params
      |> Map.put("residential_line", String.replace(kyc_params["residential_line"], "-", ""))
      |> Map.put("mobile1", String.replace(kyc_params["mobile1"], "-", ""))
      |> Map.put("mobile2", String.replace(kyc_params["mobile2"], "-", ""))
      |> Map.put("step", 3)

    with false <- is_nil(kyc),
         {:ok, kyc} <- KycContext.update_kyc_step2(kyc, kyc_params)
    do
      conn
      |> put_flash(:info, "Successfully Updated")
      |> redirect(to: "/en/kyc/#{kyc.id}/setup?step=3")
    else
      {:error, changeset} ->
      conn
      |> put_flash(:error, "Error")
      |> render("step2.html",
                  changeset: changeset,
                  member: member,
                  countries: countries,
                  locale: locale,
                  cities: cities,
                  kyc: kyc)
      _ ->
        conn
        |> put_flash(:error, "Invalid KYC Setup")
        |> redirect(to: "/en")
    end

  end

  def step2(conn, kyc) do
    changeset = KycBank.changeset(kyc)
    current_user = MG.current_resource(conn)
    member = MemberContext.get_member!(current_user.member_id)
    countries = KycContext.all_countries()
    cities = KycContext.all_cities()
    locale = conn.assigns.locale
    render(conn, "step2.html",
           changeset: changeset,
           member: member,
           countries: countries,
           locale: locale,
           cities: cities,
           kyc: kyc)
  end

  def step3(conn, kyc) do
    if not is_nil(kyc) do
      changeset = KycBank.changeset(kyc)
      current_user = MG.current_resource(conn)
      member = MemberContext.get_member!(current_user.member_id)
      countries = KycContext.all_countries()
      kyc = KycContext.preload_files(kyc)
      render(conn,
             "step3.html",
             changeset: changeset,
             kyc: kyc,
             member: member,
             countries: countries)
    else
      conn
      |> put_flash(:error, "Invalid KYC Setup")
      |> redirect(to: "/en")
    end
  end

  def step3_update(conn, kyc, kyc_params) do
    current_user = MG.current_resource(conn)
    member = MemberContext.get_member!(current_user.member_id)
    countries = KycContext.all_countries()
    _changeset = KycBank.changeset(kyc)

    kyc_params =
      kyc_params
      |> Map.put("step", 4)

    with {:ok, kyc} <- KycContext.update_kyc_step3(kyc, kyc_params),
         {:ok, _} <- KycContext.insert_front_side(kyc, kyc_params),
         {:ok, _} <- KycContext.insert_back_side(kyc, kyc_params),
         {:ok, _} <- KycContext.insert_cir_form(kyc, kyc_params),
         {:ok, _} <- KycContext.insert_terms_form(kyc, kyc_params)
    do
      conn
      |> put_flash(:info, "Successfully Updated")
      |> redirect(to: "/en/kyc/#{kyc.id}/setup?step=4")
    else
      {:error, changeset} ->
        conn
        |> put_flash(:error, "Error")
        |> render(conn,
                  "step3.html",
                  changeset: changeset,
                  member: member,
                  countries: countries,
                  kyc: kyc)
    end
  end

  def step4(conn, kyc) do
    changeset = KycBank.changeset(kyc)
    render(conn, "step4.html", changeset: changeset, kyc: kyc)
  end

  def submit(conn, kyc) do
    kyc = KycContext.get_kyc!(kyc["id"])
    step_params = %{step: 5}
    KycContext.update_summary_step(kyc, step_params)

    conn
    |> put_flash(:info, "KYC Successfully Submitted")
    |> redirect(to: "/en/kyc/#{kyc.id}/show")
  end

  def kyc_existing?(conn, _params) do
    current_user = MG.current_resource(conn)
    member = MemberContext.get_member!(current_user.member_id)
    if is_nil(member.kyc_bank) do
      redirect(conn, to: "/en/kyc/new")
    else

      if member.kyc_bank.step > 4 do
        kyc_bank_id =  member.kyc_bank.id
        conn
        |> redirect(to: "/en/kyc/#{kyc_bank_id}/show")

      else
        kyc_bank_id =  member.kyc_bank.id
        conn
        # |> put_flash(:info, "Please submit this Step #{member.kyc_bank.step}")
        |> redirect(to: "/en/kyc/#{kyc_bank_id}/setup?step=#{member.kyc_bank.step}")
      end

    end
  end

  def show(conn, %{"id" => id}) do
    kyc = KycContext.get_kyc!(id)
    render(conn, "show.html", kyc: kyc)
  end

  def delete_kyc(conn, %{"id" => kyc_id}) do
    kyc = KycContext.get_kyc!(kyc_id)
    with {count, nil} <- KycContext.get_all_files(kyc.id),
         {:ok, kyc} <- KycContext.delete_kyc(kyc.id)
    do
      json(conn, Poison.encode!(%{valid: true}))
    else
      _ ->
        json(conn, Poison.encode!(%{valid: false}))
    end
  end

end
