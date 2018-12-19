defmodule Innerpeace.Db.Validators.PEMEValidator do
    @moduledoc false

    import Ecto.{
        Query,
        Changeset
    }, warn: false

    alias Decimal
    alias Innerpeace.Db.Schemas.Embedded.PEME
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

    def request_peme(params) do
      changeset =
        %PEME{}
        |> PEME.changeset(params)
        |> put_changeset(:product_benefit, params.product_benefit)

      if changeset.errors == [] do
        member = MemberContext.get_member(params.member_id)
        product = ProductContext.get_product(params.product_id)
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

        result = validate_peme(changeset)
        if result == true do
          changeset =
            changeset
            |> compute_fees()
            |> compute_covered()
            |> process_web()
        else
          result
        end
      else
        {:error, changeset}
      end
    end

    # Validate only one peme availment
    defp validate_peme(changeset) do
      authorization = AuthorizationContext.get_authorization_by_id(changeset.changes.authorization_id)
      member = MemberContext.get_a_member!(changeset.changes.member_id)
      coverage = CoverageContext.get_coverage(changeset.changes.coverage_id)
      facility_id = changeset.changes.facility_id
      product_benefit = changeset.changes.product_benefit

      with true <- AuthorizationContext.validate_peme(member, coverage, authorization),
           true <- ApiAuthorizationContext.validate_peme_pf(facility_id, member.id, coverage)
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
      package_rate = package_facility_rate(package.package_facility, facility_id)
      changeset =
        changeset
        |> put_changeset(:package_rate, package_rate)
    end

    # Compute member and payor covered
    defp compute_covered(changeset) do
      package_rate = changeset.changes.package_rate
      changeset =
        changeset
        |> put_changeset(:payor_pays, package_rate)
        |> put_changeset(:total_amount, package_rate)
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
        Decimal.new(0)
      end
      payor_pays = if Map.has_key?(changeset.changes, :payor_pays) do
        changeset.changes.payor_pays
      else
        Decimal.new(0)
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

      with {:ok, authorization} <- AuthorizationContext.update_authorization_step4_peme(authorization, params, user_id)
      do
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

