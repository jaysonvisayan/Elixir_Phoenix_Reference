defmodule Innerpeace.Db.Validators.ACUValidator do
  @moduledoc false

  import Ecto.{
      Query,
      Changeset
  }, warn: false

  alias Decimal
  alias Innerpeace.Db.Schemas.Embedded.ACU
  # alias Innerpeace.PayorLink.Web.AuthorizationView, as: AuthorizationView

  alias Innerpeace.Db.Base.{
    AuthorizationContext,
    MemberContext,
    CoverageContext,
    ProductContext,
    BenefitContext,
    PackageContext,
    FacilityContext,
    RoomContext,
    DiagnosisContext,
    AcuScheduleContext
  }

  alias Innerpeace.Db.Base.Api.AuthorizationContext, as: ApiAuthorizationContext

  def put_changeset(changeset, key, value) do
    Ecto.Changeset.put_change(changeset, key, value)
  end

  def request_acu(params) do
    changeset =
      %ACU{}
      |> ACU.changeset(params)
      |> put_changeset(:product_benefit, params.product_benefit)
      # |> put_changeset(:package_id, params.package_id)

    if changeset.errors == [] do
      member = MemberContext.get_member(params.member_id)
      product = params.product
      benefit_package = BenefitContext.get_benefit_package(params.benefit_package_id)

      cond do
        is_nil(member) ->
          {:error, changeset}
        is_nil(product) ->
          {:error, changeset}
        is_nil(benefit_package) ->
          {:error, changeset}
        true ->
          member = MemberContext.get_a_member!(changeset.changes.member_id)
      end

      changeset =
        changeset
        |> put_changeset(:member, member)

      # result = validate_acu(changeset)
      # if result == true do
        changeset =
          changeset
          |> compute_fees()
          |> compute_covered()
          |> process_web()
      # else
      #   result
      # end
    else
      {:error, changeset}
    end
  end

  # Validate only one acu availment
  defp validate_acu(changeset) do
    authorization = AuthorizationContext.get_authorization_by_id(changeset.changes.authorization_id)
    member = MemberContext.get_a_member!(changeset.changes.member_id)
    coverage = CoverageContext.get_coverage(changeset.changes.coverage_id)
    facility_id = changeset.changes.facility_id
    product_benefit = changeset.changes.product_benefit

    with true <- AuthorizationContext.validate_acu(member, coverage, authorization),
         # true <- AuthorizationContext.validate_acu_pf(authorization)
         true <- ApiAuthorizationContext.validate_acu_pf_schedule(facility_id, member.id, coverage, product_benefit)
         # true <- AuthorizationContext.validate_acu_frr(authorization)
    do
      true
    end
  end

  # Get package rate and room rate
  defp compute_fees(changeset) do
    facility_id = changeset.changes.facility_id
    benefit_package_id = changeset.changes.benefit_package_id
    room_id = if Map.has_key?(changeset.changes, :room_id) do
      changeset.changes.room_id
    end

    benefit_package = BenefitContext.get_benefit_package(benefit_package_id)
    package_id = benefit_package.package_id
    package = PackageContext.get_package(package_id)
    package_rate = if Map.has_key?(changeset.changes, :acu_schedule_id) do
      # AcuScheduleContext.get_acu_schedule_package_by_acu_and_package(changeset.changes.acu_schedule_id, package.id).rate
      AcuScheduleContext.get_acu_package(changeset.changes.acu_schedule_id, changeset.changes.product_id, package.id).rate
    else
      package_facility_rate(package.package_facility, facility_id)
    end
    if is_nil(room_id) do
      changeset =
        changeset
        |> put_changeset(:package_rate, package_rate)
    else
      {:ok, admission_date} = Timex.parse(changeset.changes.admission_date, "{YYYY}-{0M}-{D}")
      {:ok, discharge_date} = Timex.parse(changeset.changes.discharge_date, "{YYYY}-{0M}-{D}")
      days = Timex.diff(discharge_date, admission_date, :days) + 1

      facility_room = FacilityContext.get_facility_room(facility_id, room_id)
      room_rate = Decimal.mult(Decimal.new(facility_room.room_rate), Decimal.new(days))
      room_hierarchy = facility_room.room_hierarchy

      changeset =
        changeset
        |> put_changeset(:package_rate, package_rate)
        |> put_changeset(:room_rate, room_rate)
        |> put_changeset(:room_hierarchy, room_hierarchy)
    end
  end

  # Compute member and payor covered
  defp compute_covered(changeset) do
    package_rate = changeset.changes.package_rate
    room_id = if Map.has_key?(changeset.changes, :room_id) do
      changeset.changes.room_id
    end

    # Regular/Executive - Outpatient
    if is_nil(room_id) do
      changeset =
        changeset
        |> put_changeset(:payor_pays, package_rate)
        |> put_changeset(:total_amount, package_rate)
    # Executive - Inpatient
    else
      product_id = changeset.changes.product_id
      coverage_id = changeset.changes.coverage_id

      product = ProductContext.get_product(product_id)
      rnb = AuthorizationContext.get_rnb_by_coverage(product, coverage_id)

      rnb_hierarchy =
        if rnb.room_and_board == "Peso Based" do
          rnb_hierarchy = nil
        else
          room = RoomContext.get_a_room(rnb.room_type)
          rnb_hierarchy = room.hierarchy
        end

      params = %{
        "rnb" => rnb.room_and_board,
        "rnb_amount" => rnb.room_limit_amount,
        "rnb_id" => rnb.room_type,
        "rnb_hierarchy" => rnb_hierarchy,
        "selected_room_id" => room_id,
        "selected_room_rate" => changeset.changes.room_rate,
        "selected_room_hierarchy" => changeset.changes.room_hierarchy,
        "package_rate" => package_rate
      }

      compute_acu = AuthorizationContext.compute_acu(params)
      payor_pays = compute_acu.payor
      member_pays = if is_nil(compute_acu.member) or compute_acu.member == "" do
        ""
      else
        compute_acu.member
      end
      total_amount = if member_pays == "" do
        Decimal.new(payor_pays)
      else
        Decimal.add(member_pays, payor_pays)
      end

     changeset =
        changeset
        |> put_changeset(:member_pays, member_pays)
        |> put_changeset(:payor_pays, payor_pays)
        |> put_changeset(:total_amount, total_amount)
    end
  end

  defp process_web(changeset) do
    authorization = AuthorizationContext.get_authorization_by_id(changeset.changes.authorization_id)

    user_id = changeset.changes.user_id
    room_id = if Map.has_key?(changeset.changes, :room_id) do
      changeset.changes.room_id
    else
      nil
    end
    admission_date = if Map.has_key?(changeset.changes, :admission_date) do
      changeset.changes.admission_date
    else
      nil
    end
    discharge_date = if Map.has_key?(changeset.changes, :discharge_date) do
      changeset.changes.discharge_date
    else
      nil
    end
    room_rate = if Map.has_key?(changeset.changes, :room_rate) do
      changeset.changes.room_rate
    else
      nil
    end
    member_pays = if Map.has_key?(changeset.changes, :member_pays) do
      changeset.changes.member_pays
    else
      nil
    end
    internal_remarks = if Map.has_key?(changeset.changes, :internal_remarks) do
      changeset.changes.internal_remarks
    else
      nil
    end
    valid_until = if Map.has_key?(changeset.changes, :valid_until) do
      changeset.changes.valid_until
    else
      nil
    end

    diagnosis = DiagnosisContext.get_diagnosis_by_code("Z00.0")

    pbl = ProductContext.get_product_benefit(changeset.changes.product_benefit_id).product_benefit_limits

    limit_amount =
      if Enum.empty?(pbl) do
        limit_amount = Decimal.new(0)
      else
        product_benefit_limit =
          pbl
          |> List.first()
        limit_amount = product_benefit_limit.limit_amount || Decimal.new(0)
      end

    if Decimal.to_float(Decimal.new(limit_amount)) == Decimal.to_float(Decimal.new(0)) do
      payor_pays = changeset.changes.payor_pays
      member_pays = Decimal.new(0)
    else
      if Decimal.to_float(Decimal.new(limit_amount)) > Decimal.to_float(Decimal.new(changeset.changes.payor_pays)) do
        payor_pays = changeset.changes.payor_pays
        member_pays = Decimal.new(0)
      else
        payor_pays = limit_amount
        member_pays = Decimal.sub(Decimal.new(changeset.changes.payor_pays), Decimal.new(limit_amount))
      end
    end

    params = %{
      "benefit_package_id" => changeset.changes.benefit_package_id,
      "room_id" => room_id,
      "admission_datetime" => admission_date,
      "discharge_datetime" => discharge_date,
      "room_rate" => room_rate,
      "payor_covered" => payor_pays,
      "member_covered" => member_pays,
      "payor_pays" => payor_pays,
      "member_pays" => member_pays,
      "total_amount" => changeset.changes.total_amount,
      "internal_remarks" => internal_remarks,
      "valid_until" => valid_until,
      "package_rate" => changeset.changes.package_rate,
      "member_product_id" => changeset.changes.member_product_id,
      "product_benefit_id" => changeset.changes.product_benefit_id,
      "diagnosis_id" => diagnosis.id,
      "origin" => changeset.changes.origin
    }

    benefit_package =
      changeset.changes.benefit_package_id
      |> BenefitContext.get_benefit_package()

    package_id = benefit_package.package_id
    member_id = changeset.changes.member_id

    with {:ok, authorization} <- AuthorizationContext.update_authorization_step4_acu(authorization, params, user_id)
    do
      MemberContext.update_member_products_by_package_id(member_id, package_id, true)
      params = Map.put_new(params, "authorization_id", authorization.id)
      AuthorizationContext.create_authorization_benefit_package(params, user_id)
      AuthorizationContext.create_authorization_amount(params, user_id)
      AuthorizationContext.create_authorization_diagnosis(params, user_id)

      if changeset.valid? do
        changeset =
          changeset
          |> put_changeset(:authorization_id, authorization.id)
          {:ok, changeset}
      end
    end
  end

  defp package_facility_rate(package_facilities, facility_id) do
    if Enum.count(package_facilities) > 1 do
      rate = for package_facility <- package_facilities do
        if package_facility.facility_id == facility_id do
          package_facility.rate
        end
      end

      rate =
        rate
        |> Enum.uniq()
        |> List.delete(nil)
        |> List.first()
    else
      package_facility = List.first(package_facilities)
      rate = package_facility.rate
    end
  end
end
