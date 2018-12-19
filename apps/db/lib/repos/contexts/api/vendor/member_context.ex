defmodule Innerpeace.Db.Base.Api.Vendor.MemberContext do
  import Ecto.{Query, Changeset}, warn: false
  alias Ecto.Changeset

  @moduledoc false

  alias Innerpeace.Db.Base.Api.MemberContext, as: MainApiMemberContext
  alias Innerpeace.Db.Base.MemberContext, as: MainWebMemberContext
  alias Innerpeace.Db.Base.Api.UtilityContext

  alias Innerpeace.Db.{
    Repo,
    Schemas.Account,
    Schemas.Member,
    Schemas.Product,
    Schemas.AccountProduct,
    Schemas.MemberProduct,
    Schemas.Coverage,
    Base.CoverageContext,
    Base.FacilityContext,
    Base.DiagnosisContext,
    Base.ProcedureContext,
    Schemas.Room,
    Schemas.FacilityPayorProcedureRoom,
    Schemas.FacilityPayorProcedure
  }

  def validate_params(params) do
    with {:ok, changeset} <- validate_card_no(params),
         %Member{} = member <- get_member_card_no_w_preload(params),
         member_rnbs <- get_all_mp_rnb(member)
    do
      {:ok, member_rnbs}
    else
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def validate_card_no(params) do
    data = %{}
    general_types = %{
      card_number: :string,
    }
    changeset =
      {data, general_types}
      |> Changeset.cast(params, Map.keys(general_types))
      |> Changeset.validate_required([
        :card_number
      ])
      |> validate_length(:card_number, is: 16, message: "Card Number Should be 16 digit")
      |> member_existing?()

    if changeset.valid? do
      {:ok, changeset}
    else
      {:error, changeset}
    end

  end

  defp member_existing?(changeset) do
    with true <- Map.has_key?(changeset.changes, :card_number),
         %Member{} = member <- get_member_card_no_wo_preload(changeset.changes.card_number)
    do
      changeset
    else
      false ->
        changeset

      nil ->
        Changeset.add_error(changeset, :card_number, "Card Number Doesn't Exist!")

    end
  end

  defp get_member_card_no_wo_preload(card_number) do
    Member
    |> Repo.get_by(card_no: card_number)
  end

  defp get_member_card_no_w_preload(params) do
    Member
    |> Repo.get_by(card_no: params["card_number"])
    |> Repo.preload([
      account_group: :account,
      products: [
        account_product: [
          product: [
            product_coverages: :product_coverage_room_and_board
          ]
        ]
      ]
    ])

  end

  defp get_all_mp_rnb(member) do
    member.products
    |> Enum.into([], &(&1.account_product.product.product_coverages))
    |> Enum.map(fn(x) -> x
    |> Enum.filter(fn(y) -> y.product_coverage_room_and_board != nil end)
    end)
    |> List.flatten()
  end

  def get_member_utilization(card_no, coverage_name) do
    member =
      Member
      |> where([m], m.card_no == ^card_no)
      |> Repo.one
      |> Repo.preload([
        authorizations: [
          :facility,
          :special_approval,
          :room,
          :created_by,
          :authorization_amounts,
          authorization_practitioners: :practitioner,
          authorization_diagnosis: [
            :diagnosis,
            product_benefit: [:benefit],
            member_product: [
              account_product: :product]
          ],
          coverage: [coverage_benefits: :benefit],
          authorization_procedure_diagnoses: [:diagnosis, product_benefit: :benefit],
          authorization_benefit_packages: [benefit_package: [:benefit, :package]]
        ]
      ])

    coverage =
      Coverage
      |> where([c], ilike(c.name, ^coverage_name))
      |> Repo.one

    with true <- not is_nil(member),
         true <- not is_nil(coverage)
    do
      return_utilization(member, coverage)
    end
  end

  defp return_utilization(member, coverage) do
    result = [] ++ for auth <- member.authorizations do
      if auth.coverage_id == coverage.id and auth.status == "Approved" do
        %{
          authorization: auth,
          result: %{}
        }
        |> auth_loa_number
        |> auth_coverage
        |> auth_product_code
        |> auth_icd
        |> auth_benefit
        |> auth_facility_code
        |> auth_facility_name
        |> auth_availment_date
        |> auth_processed_by
        |> auth_type
        |> auth_amount
        |> auth_result
      end
    end
    |> Enum.uniq
    |> List.delete(nil)

    {:ok, result}
  end

  defp insert_utilization_param(authorization, result, field, value) do
    result = Map.put_new(result, field, value)

    %{
      authorization: authorization,
      result: result
    }
  end

  defp auth_loa_number(
    %{
      authorization: authorization,
      result: result
    }
  ) do
    loa_number = if not is_nil(authorization.number) do
      authorization.number
    else
      "N/A"
    end

    insert_utilization_param(authorization, result, :loa_number, loa_number)
  end

  defp auth_coverage(
    %{
      authorization: authorization,
      result: result
    }
  ) do
    coverage = if not is_nil(authorization.coverage) do
      authorization.coverage.name
    else
      "N/A"
    end

    insert_utilization_param(authorization, result, :coverage, coverage)
  end

  defp auth_product_code(
    %{
      authorization: authorization,
      result: result
    }
  ) do
    product_code =
      if not is_nil(authorization.coverage) do
        coverage = String.downcase(authorization.coverage.name)

        case coverage do
          "acu" ->
            load_auth_product_acu(authorization)
          _ ->
            load_auth_product_others(authorization)
        end
      else
        "N/A"
      end

    insert_utilization_param(authorization, result, :product_code, product_code)
  end

  defp load_auth_product_acu(authorization) do
    m_id = authorization.member_id

    product = MainWebMemberContext.get_acu_product_by_member_id(m_id)
    case product do
      nil ->
        "N/A"
      {:error} ->
        "N/A"
      _ ->
        product.code
    end
  rescue
    _ ->
      "N/A"
  end

  defp load_auth_product_others(authorization) do
    with authorization_diagnosis <- authorization.authorization_diagnosis,
          member_product <- List.first(authorization_diagnosis).member_product,
          account_product <- member_product.account_product,
          product <- account_product.product
    do
      product.code
    end
  rescue
    _ ->
      "N/A"
  end

  defp auth_icd(
    %{
      authorization: authorization,
      result: result
    }
  ) do
    icd = if not is_nil(authorization.coverage) do
      coverage = String.downcase(authorization.coverage.name)

      load_auth_icd(authorization, coverage)
    else
      "N/A"
    end

    insert_utilization_param(authorization, result, :icd, icd)
  end

  defp load_auth_icd(auth, coverage) do
    cond do
      coverage  == "op consult" ->

        result =
          Enum.into(
            auth.authorization_diagnosis, [],
            &(Enum.join([&1.diagnosis.code, &1.diagnosis.description], " : ")))

        result
        |> Enum.uniq()
        |> Enum.join(", ")

      coverage == "op laboratory" || coverage == "emergency" ->

        result =
          Enum.into(
            auth.authorization_procedure_diagnoses, [],
            &(Enum.join([&1.diagnosis.code, &1.diagnosis.description], " : ")))

        result
        |> Enum.uniq()
        |> Enum.join(", ")

      coverage == "acu" ->

        abp = Enum.into(auth.authorization_benefit_packages, [], fn(abp) ->
          abp
        end)

        abp
        |> Enum.into([], fn(abp) ->
          if is_nil(abp.benefit_package) do
            []
          else
            "Package code:" <> " " <> abp.benefit_package.package.code <> " | " <>
              "name:" <> " " <> abp.benefit_package.package.name
          end
        end)
        |> Enum.uniq()
        |> Enum.join(", ")

      coverage == "acu" ->

        Enum.into(auth.authorization_benefit_packages, [], fn(abp) ->
          abp
          |> Enum.into([], fn(abp) ->
            if is_nil(abp.benefit_package) do
              []
            else
              Enum.join([abp.package.code, abp.package.name], " : ")
            end
          end)
          |> Enum.uniq()
          |> Enum.join(", ")
        end)

      true ->
        "N/A"
    end
  end

  defp auth_benefit(
    %{
      authorization: authorization,
      result: result
    }
  ) do
    benefit = if not is_nil(authorization.coverage) do
      coverage = authorization.coverage.name
      load_auth_benefit(authorization, coverage)
    else
      "N/A"
    end

    insert_utilization_param(authorization, result, :benefit, benefit)
  end

  defp load_auth_benefit(auth, coverage) do
    case String.downcase(coverage) do
      "op consult" ->
        auth.authorization_diagnosis
        |> Enum.into([], fn(ad) ->
          if is_nil(ad.product_benefit) do
            []
          else
            ad.product_benefit.benefit.name
          end
        end)
        |> Enum.uniq()
        |> Enum.join(", ")
      "op laboratory" ->
        auth.authorization_procedure_diagnoses
        |> Enum.into([], fn(apd) ->
          if is_nil(apd.product_benefit) do
            []
          else
            apd.product_benefit.benefit.name
          end
        end)
        |> Enum.uniq()
        |> Enum.join(", ")
      "emergency" ->
        auth.authorization_procedure_diagnoses
        |> Enum.into([], fn(apd) ->
          if is_nil(apd.product_benefit) do
            []
          else
            apd.product_benefit.benefit.name
          end
        end)
        |> Enum.uniq()
        |> Enum.join(", ")
        "acu" ->
          auth.authorization_benefit_packages
          |> Enum.into([], fn(abp) ->
            if is_nil(abp.benefit_package) do
              []
            else
              abp.benefit_package.benefit.name
            end
          end)
          |> Enum.uniq()
          |> Enum.join(", ")
          _ ->
            "N/A"
    end
  end

  defp auth_facility_code(
    %{
      authorization: authorization,
      result: result
    }
  ) do
    facility_code = if not is_nil(authorization.facility) do
      authorization.facility.code
    else
      "N/A"
    end

    insert_utilization_param(authorization, result, :facility_code, facility_code)
  end

  defp auth_facility_name(
    %{
      authorization: authorization,
      result: result
    }
  ) do
    facility_name = if not is_nil(authorization.facility) do
      authorization.facility.name
    else
      "N/A"
    end

    insert_utilization_param(authorization, result, :facility_name, facility_name)
  end

  defp auth_availment_date(
    %{
      authorization: authorization,
      result: result
    }
  ) do
    availment_date = if not is_nil(authorization.admission_datetime) do
      authorization.admission_datetime
      load_date(authorization.admission_datetime)
    else
      "N/A"
    end

    insert_utilization_param(authorization, result, :availment_date, availment_date)
  end

  def load_date(date_time) do
    date =
      date_time
      |> Ecto.DateTime.to_date
      |> Ecto.Date.to_string
      |> String.split("-")

    "#{Enum.at(date, 1)}/#{Enum.at(date, 2)}/#{Enum.at(date, 0)}"
  end

  defp auth_processed_by(
    %{
      authorization: authorization,
      result: result
    }
  ) do
    processed_by = if not is_nil(authorization.created_by) do
      Enum.join([authorization.created_by.first_name, authorization.created_by.last_name], " ")
    else
      "N/A"
    end

    insert_utilization_param(authorization, result, :processed_by, processed_by)
  end

  defp auth_type(
    %{
      authorization: authorization,
      result: result
    }
  ) do

    insert_utilization_param(authorization, result, :type, "IBNR")
  end

  defp auth_amount(
    %{
      authorization: authorization,
      result: result
    }
  ) do
    amount = if not is_nil(authorization.total_amount) do
      authorization.total_amount
    else
      "N/A"
    end

    insert_utilization_param(authorization, result, :amount, amount)
  end

  defp auth_result(
    %{
      authorization: authorization,
      result: result
    }
  ) do
    result
  end

  def validate_pre_availment_params(params) do
    with {:ok, changeset} <- pre_availment_changeset(params),
         {:ok_fpp} <- check_facility_procedure(changeset.changes),
         {:ok_product_pp} <- check_member_products(changeset.changes)
         # {:ok_card, coverage} <- check_coverage_code(params["coverage"])
    do
      {:ok, %{procedure: changeset.changes.facility_procedure,
              remarks: "Covered",
              procedure_amount: changeset.changes.procedure_amount}}
    else
      {:invalid_fpp} ->
        {:error, "The selected procedure is not available in the selected facility"}
      {:no_procedure_found} ->
        {:error, "The selected procedure/diagnosis is not covered in any member's product benefit"}
      {:no_op_lab_coverage_found} ->
        {:error, "No OP LAB coverage belongs to member products"}
      {:no_products_in_members} ->
        {:error, "Member has no available product"}
      {:error, changeset} ->
        {:error, UtilityContext.changeset_errors_to_string(changeset.errors)}
      _ ->
        raise "123123"
        # message = required_params -- Map.keys(params)
        # message = Enum.join(message, ", ")
        # {:incomplete_params, message}
    end
  end

  defp check_member_products(changes) do
    member_products = MainWebMemberContext.get_a_member!(changes.member.id).products
    if member_products == [] do
      {:no_products_in_members}
    else
      check_diagnosis_procedure_in_product(member_products, changes)
    end
  end

  defp check_diagnosis_procedure_in_product(member_products, changes) do
    procedure_code = changes.facility_procedure.payor_procedure.code
    diagnosis_code = changes.diagnosis.code
    params =
    %{
      procedure: nil,
      diagnosis: nil
    }
    result = Enum.map(member_products, fn(member_product) ->
      if member_product.account_product.product.product_base == "Benefit-based" do
        Enum.map(member_product.account_product.product.product_benefits, fn(product_benefit) ->
          Enum.map(product_benefit.benefit.benefit_coverages, fn(benefit_coverage) ->
            if benefit_coverage.coverage.id == changes.coverage.id do
              benefit_checker =
                check_procedure_in_product_benefit_based(product_benefit, procedure_code, params, diagnosis_code)
              benefit_checker =
                benefit_checker
                |> List.flatten()
                |> Enum.uniq()
              if Enum.member?(benefit_checker, %{diagnosis: "covered", procedure: "covered"}) do
                {:ok}
              else
                {:not_found}
              end
            else
              {:no_op_lab_coverage_found}
            end
          end)
        end)
      else
        exclusion_base_result =
          Enum.map(member_product.account_product.product.product_coverages, fn(product_coverage) ->
          if product_coverage.coverage.id == changes.coverage.id do
            Enum.map(member_product.account_product.product.product_exclusions, fn(product_exclusion) ->
              exclusion_checker =
                check_procedure_in_product_exclusion_based(product_exclusion, procedure_code, params, diagnosis_code)
                exclusion_checker =
                  exclusion_checker
                  |> List.flatten()
                  |> Enum.uniq()

                if Enum.member?(exclusion_checker, {:excluded}) do
                  {:excluded}
                else
                  {:not_excluded}
                end

            end)
          else
            {:no_op_lab_coverage_found}
          end
        end)
        exclusion_base_result =
          exclusion_base_result
          |> List.flatten()

        if Enum.member?(exclusion_base_result, {:excluded}) do
          {:not_found}
        else
          {:ok}
        end
      end
    end)

    result =
      result
      |> List.flatten()

    if Enum.member?(result, {:ok}) do
      {:ok_product_pp}
    else
      if Enum.count(Enum.filter(result, &(&1 == {:not_found}))) > 0 do
        {:no_procedure_found}
      else
        if Enum.member?(result, {:no_op_lab_coverage_found}) do
          {:no_op_lab_coverage_found}
        end
      end
    end
  end

  defp check_procedure_in_product_exclusion_based(product_exclusion, procedure_code, params, diagnosis_code) do
    Enum.map(product_exclusion.exclusion.exclusion_procedures, fn(exclusion_procedure) ->
      if exclusion_procedure.procedure.code == procedure_code do
        {:excluded}
      else
        params =
          params
          |> Map.put(:procedure, "covered")
          |> Map.put(:diagnosis, "covered")
        Enum.map(product_exclusion.exclusion.exclusion_diseases, fn(exclusion_diagnosis) ->
          if exclusion_diagnosis.disease.code == diagnosis_code do
            params =
             params
             |> Map.put(:diagnosis, nil)
          else
            params =
              params
              |> Map.put(:diagnosis, "covered")
          end
        end)
      end
    end)
  end

  defp check_procedure_in_product_benefit_based(product_benefit, procedure_code, params, diagnosis_code) do
    Enum.map(product_benefit.benefit.benefit_procedures, fn(benefit_procedure) ->
      if benefit_procedure.procedure.code == procedure_code do
        params =
         params
         |> Map.put(:procedure, "covered")
         Enum.map(product_benefit.benefit.benefit_diagnoses, fn(benefit_diagnosis) ->
          if benefit_diagnosis.diagnosis.code == diagnosis_code do
            params =
              params
              |> Map.put(:diagnosis, "covered")
          else
            params =
              params
              |> Map.put(:diagnosis, nil)
          end
        end)
      else
        {:not_found}
      end
    end)
  end

  defp check_facility_procedure(%{facility: facility, facility_procedure: facility_procedure}) do
    facility = preload_facility_procedures(facility)
    facility_procedure_ids = Enum.map(facility.facility_payor_procedures, &(&1.id))
    if Enum.member?(facility_procedure_ids, facility_procedure.id) do
      {:ok_fpp}
    else
      {:invalid_fpp}
    end
  end

  def pre_availment_changeset(params) do
    types = %{
      card_number: :string,
      coverage: :string,
      facility_code: :string,
      diagnosis_code: :string,
      procedure_code: :string,
      availment_date: Ecto.Date
    }
    changeset =
      {%{}, types}
      |> Changeset.cast(params, Map.keys(types))
      |> Changeset.validate_required(
        ~w(card_number coverage facility_code diagnosis_code procedure_code availment_date)a,
        message: "is required"
      )
      |> check_card_number()
      |> check_coverage_code()
      |> check_facility_code()
      |> check_diagnosis_code()
      |> check_procedure_code()

    if changeset.valid? do
      {:ok, changeset}
    else
      {:error, changeset}
    end
  end

  defp check_card_number(changeset) do
    if Map.has_key?(changeset.changes, :card_number) do
      member = MainApiMemberContext.validate_active_card(changeset.changes.card_number)
      if member do
        put_change(changeset, :member, member)
      else
        add_error(changeset, :card_number, "is invalid")
      end
    else
      changeset
    end
  end

  defp check_coverage_code(changeset) do
    if Map.has_key?(changeset.changes, :coverage) do
      coverage = CoverageContext.get_coverage_by_code(changeset.changes.coverage)
      if coverage do
        put_change(changeset, :coverage, coverage)
      else
        add_error(changeset, :coverage, "is invalid")
      end
    else
      changeset
    end
  end

  defp check_facility_code(changeset) do
    if Map.has_key?(changeset.changes, :facility_code) do
      facility = FacilityContext.get_facility_by_code(changeset.changes.facility_code)
      if facility do
        put_change(changeset, :facility, facility)
      else
        add_error(changeset, :facility_code, "is invalid")
      end
    else
      changeset
    end
  end

  defp check_diagnosis_code(changeset) do
    if Map.has_key?(changeset.changes, :diagnosis_code) do
      diagnosis = DiagnosisContext.get_diagnosis_by_code(changeset.changes.diagnosis_code)
      if diagnosis do
        put_change(changeset, :diagnosis, diagnosis)
      else
        add_error(changeset, :diagnosis_code, "is invalid")
      end
    else
      changeset
    end
  end

  defp check_procedure_code(changeset) do
    if Map.has_key?(changeset.changes, :procedure_code) do
      procedure = ProcedureContext.get_payor_procedure_by_code2(changeset.changes.procedure_code)
      if is_nil(procedure) == false do

        fpp_code = Enum.map(procedure.facility_payor_procedures, fn(fpp) ->
          fpp.code
        end)

        fpp_code =
          fpp_code
          |> List.first()

        if is_nil(fpp_code) do
          add_error(changeset, :procedure_code, "is invalid")
        else
          facility_procedure = FacilityContext.get_fpp_by_code(fpp_code)
          if is_nil(facility_procedure) == false and check_op_room(facility_procedure) do
            changeset = put_change(changeset, :facility_procedure, facility_procedure)
            put_change(changeset, :procedure_amount, get_op_room_rate(facility_procedure))
          else
            add_error(changeset, :procedure_code, "is invalid")
          end
        end

      else
        add_error(changeset, :procedure_code, "is invalid")
      end
    else
      changeset
    end
  end

  defp check_op_room(facility_procedure) do
    fpp =
      facility_procedure.facility_payor_procedure_rooms
      |> Enum.find(fn(fppr) ->
        fppr.facility_room_rate.room.code == "16"
      end)
    if is_nil(fpp) do
      false
    else
      true
    end
  end

  defp get_op_room_rate(facility_procedure) do
    fpp =
      facility_procedure.facility_payor_procedure_rooms
      |> Enum.find(fn(fppr) ->
        fppr.facility_room_rate.room.code == "16"
      end)
    fpp.amount
  end

  defp preload_facility_procedures(facility) do
    facility
    |> Repo.preload([
      facility_payor_procedures: [:payor_procedure]
    ])
  end

  def validate_params_verification(params) do
    count =
      params
      |> Enum.count()

    if count == 3 do
      {:both_are_not_accepted, "You can only set one method, either Full Name/Bdate or Card Number"}
    else
      params
      |> Map.keys()
      |> Enum.sort()
      |> validate_keys(params)
    end

  end

  defp validate_keys(keys, params) do
    case keys do
      ["birthdate", "full_name"] ->
        with {:ok, changeset} <- validate_fullname_and_bdate(params),
             member <- get_member_by_fullname_bdate(params),
             account_latest_version <- member |> get_member_account_statuses_list()
        do
          {:ok_list, account_latest_version}
        else
          nil ->
            {:fullname_bdate_not_matched, "Full Name and Birthdate not matched."}

          {:error, changeset} ->
            {:error, changeset}
        end

      ["card_number"] ->
        with {:ok, changeset} <- params |> validate_card_no(),
             %Member{} = member <- params |> get_member_card_no_w_preload(),
             account_latest_version <- member |> get_member_account_statuses()

        do
          {:ok, member, account_latest_version}
        else
          {:error, changeset} ->
            {:error, changeset}
        end

      ["full_name"] ->
        {:birthdate_is_missing, "Birthdate parameter is missing"}

      ["birthdate"] ->
        {:full_name_is_missing, "Full Name parameter is missing"}

      _ ->
        {:both_are_not_accepted, "You can only set one method, either Full Name/Bdate or Card Number"}

    end
  end

  defp get_member_account_statuses(member) do
    account_status =
      member.account_group.account
      |> Enum.filter(&(&1.status == "Active"))

    if account_status |> Enum.empty?() do
      Account
      |> where([a], a.account_group_id == ^member.account_group.id)
      |> order_by([a], desc: a.inserted_at)
      |> Repo.all()
      |> List.first()
      |> Repo.preload([:account_group])

    else
      account_status
      |> List.first()
      |> Repo.preload([:account_group])
    end

  end

  defp get_member_account_statuses_list(member) do
    member
    |> Enum.map(fn(x) ->

      account_status =
        x.account_group.account
        |> Enum.filter(fn(a) -> a == "Active" end)

      if account_status |> Enum.empty?() do
        account =
          Account
          |> where([a], a.account_group_id == ^x.account_group.id)
          |> order_by([a], desc: a.inserted_at)
          |> Repo.all()
          |> List.first()
          |> Repo.preload([:account_group])

          %{
            full_name: "#{x.first_name} #{x.middle_name} #{x.last_name}",
            card_number: x.card_no,
            status: x.status,
            gender: x.gender,
            birthdate: x.birthdate,
            account: %{
              code: account.account_group.code,
              name: account.account_group.name,
              status: account.status
            }
          }

      else
        account =
          account_status
          |> List.first()
          |> Repo.preload([:account_group])

          %{
            full_name: "#{x.first_name} #{x.middle_name} #{x.last_name}",
            card_number: x.card_no,
            status: x.status,
            gender: x.gender,
            birthdate: x.birthdate,
            account: %{
              code: account.account_group.code,
              name: account.account_group.name,
              status: account.status
            }
          }
      end
    end)

  end

  defp validate_fullname_and_bdate(params) do
    data = %{}
    general_types = %{
      full_name: :string,
      birthdate: Ecto.Date
    }
    changeset =
      {data, general_types}
      |> Changeset.cast(params, Map.keys(general_types))
      |> Changeset.validate_required([
        :full_name,
        :birthdate
      ])

    if changeset.valid? do
      {:ok, changeset}
    else
      {:error, changeset}
    end

  end

  defp get_member_by_fullname_bdate(params) do
    birthdate =
      params["birthdate"]
      |> Ecto.Date.cast!()

    Member
    |> where([m], fragment("to_tsvector(concat(?, ' ', ?, ' ', ?)) @@ plainto_tsquery(?)",
             m.first_name, m.middle_name, m.last_name, ^"#{params["full_name"]}")
             and fragment("? = coalesce(?, ?)", m.birthdate, ^birthdate, m.birthdate))
    |> Repo.all()
    |> Repo.preload([
      account_group: :account,
      products: [
        account_product: [
          product: [
            product_coverages: :product_coverage_room_and_board
          ]
        ]
      ]
    ])

  end

  def validate_member_eligibility(params) do
    with {:ok, changeset} <- member_eligibility_changeset(params),
         {:ok, changeset} <- member_validity_changeset(params),
         {:ok_product_dp} <- check_member_product_dp(changeset.changes)
    do
      {:ok, %{message: "Eligible"}}
    else
      {:no_procedure_found} ->
        {:error, %{message: "Not Eligible"}}
      {:no_diagnosis_found} ->
        {:error, %{message: "Not Eligible"}}
      {:not_eligible} ->
        {:error, %{message: "Not Eligible"}}
      {:no_products_in_members} ->
        {:error, %{message: "Member has no available product"}}
      {:error, changeset} ->
        {:error, %{message: UtilityContext.changeset_errors_to_string(changeset.errors)}}
      _ ->
        raise "1"
    end
  end

  def member_eligibility_changeset(params) do
    types = %{
      card_number: :string,
      icd_group_code: :string,
      cpt_code: :string
    }
    changeset =
      {%{}, types}
      |> Changeset.cast(params, Map.keys(types))
      |> Changeset.validate_required(
        ~w(card_number)a,
        message: "is required"
      )
      |> check_member_card_number()
      |> check_existing_diagnosis_code()
      |> check_existing_procedure_code()

    if changeset.valid? do
      {:ok, changeset}
    else
      {:error, changeset}
    end
  end

  def member_validity_changeset(params) do
    types = %{
      card_number: :string,
      icd_group_code: :string,
      cpt_code: :string
    }
    changeset =
      {%{}, types}
      |> Changeset.cast(params, Map.keys(types))
      |> Changeset.validate_required(
        ~w(card_number)a,
        message: "is required"
      )
      |> check_member_is_active()
      |> check_existing_diagnosis_code()
      |> check_existing_procedure_code()

    if changeset.valid? do
      {:ok, changeset}
    else
      {:error, changeset}
    end
  end

  defp check_member_is_active(changeset) do
    if Map.has_key?(changeset.changes, :card_number) do
      member = MainApiMemberContext.validate_active_card(changeset.changes.card_number)
      if member do
        put_change(changeset, :member, member)
      else
        add_error(changeset, :card_number, "N (Not Eligible)")
      end
    else
      changeset
    end
  end

  defp check_member_card_number(changeset) do
    if Map.has_key?(changeset.changes, :card_number) do
      member = MainApiMemberContext.get_member_by_card_number(changeset.changes.card_number)
      if member do
        put_change(changeset, :member, member)
      else
        add_error(changeset, :card_number, "is invalid")
      end
    else
      changeset
    end
  end

  defp check_existing_diagnosis_code(changeset) do
    if Map.has_key?(changeset.changes, :icd_group_code) do
      diagnosis = DiagnosisContext.get_diagnosis_by_code(changeset.changes.icd_group_code)
      if diagnosis do
        put_change(changeset, :diagnosis, diagnosis)
      else
        add_error(changeset, :diagnosis_code, "does not exist")
      end
    else
      changeset
    end
  end

  defp check_existing_procedure_code(changeset) do
    if Map.has_key?(changeset.changes, :cpt_code) do
      procedure = ProcedureContext.get_payor_procedure_by_code(changeset.changes.cpt_code)
      if procedure do
        put_change(changeset, :procedure, procedure)
      else
        add_error(changeset, :cpt_code, "does not exist")
      end
    else
      changeset
    end
  end

  defp check_member_product_dp(changes) do
    member_products = MainWebMemberContext.get_a_member!(changes.member.id).products
    if member_products == [] do
      {:no_products_in_members}
    else
      check_diagnosis_procedure_in_product_no_coverage(member_products, changes)
    end
  end

  defp check_diagnosis_procedure_in_product_no_coverage(member_products, changes) do
    if Map.has_key?(changes, :icd_group_code) and Map.has_key?(changes, :cpt_code)  do
      cond do
        Map.has_key?(changes, :icd_group_code) and Map.has_key?(changes, :cpt_code) == false ->

          diagnosis_code = changes.diagnosis.code
          params =
          %{
            diagnosis: nil
          }
          check_diagnosis_no_coverage(member_products, diagnosis_code, params)

        Map.has_key?(changes, :icd_group_code) == false and Map.has_key?(changes, :cpt_code) ->
          raise 123
        true ->
          procedure_code = changes.cpt_code
          diagnosis_code = changes.diagnosis.code
          params =
          %{
            procedure: nil,
            diagnosis: nil
          }
          check_diagnosis_and_procedure(member_products, diagnosis_code, procedure_code, params)
      end
    else
      if Map.has_key?(changes, :icd_group_code) and Map.has_key?(changes, :cpt_code) == false do
        diagnosis_code = changes.diagnosis.code
        params =
        %{
          diagnosis: nil
        }
        check_diagnosis_no_coverage(member_products, diagnosis_code, params)
      else
        check_member_status(changes)
      end

    end
  end

  defp check_member_status(changes) do
    if changes.member.status == "Active" do
      {:ok_product_dp}
    else
      {:not_eligible}
    end
  end

  def check_diagnosis_no_coverage(member_products, diagnosis_code, params) do
    result = Enum.map(member_products, fn(member_product) ->
      if member_product.account_product.product.product_base == "Benefit-based" do
        Enum.map(member_product.account_product.product.product_benefits, fn(product_benefit) ->
          benefit_checker =
            check_diagnosis_in_product_benefit_based_nc(product_benefit, params, diagnosis_code)
          benefit_checker =
            benefit_checker
            |> List.flatten()
            |> Enum.uniq()
          if Enum.member?(benefit_checker, %{diagnosis: "covered"}) do
            {:ok}
          else
            {:not_found}
          end
        end)
      else
        exclusion_base_result =
          Enum.map(member_product.account_product.product.product_coverages, fn(product_coverage) ->
            Enum.map(member_product.account_product.product.product_exclusions, fn(product_exclusion) ->
              exclusion_checker =
                check_diagnosis_in_product_exclusion_based_nc(product_exclusion, params, diagnosis_code)
              exclusion_checker =
                exclusion_checker
                |> List.flatten()
                |> Enum.uniq()

              if Enum.member?(exclusion_checker, {:excluded}) do
                {:excluded}
              else
                {:not_excluded}
              end
            end)
        end)
        exclusion_base_result =
          exclusion_base_result
          |> List.flatten()

        if Enum.member?(exclusion_base_result, {:excluded}) do
          {:not_found}
        else
          {:ok}
        end
      end
    end)

    result =
      result
      |> List.flatten()

    if Enum.member?(result, {:ok}) do
      {:ok_product_dp}
    else
      {:no_diagnosis_found}
    end
  end

  def check_diagnosis_and_procedure(member_products, diagnosis_code, procedure_code, params) do
    result = Enum.map(member_products, fn(member_product) ->
      if member_product.account_product.product.product_base == "Benefit-based" do
        Enum.map(member_product.account_product.product.product_benefits, fn(product_benefit) ->
          benefit_checker =
            check_dp_in_product_benefit_based_nc(product_benefit, procedure_code, params, diagnosis_code)
          benefit_checker =
            benefit_checker
            |> List.flatten()
            |> Enum.uniq()
          if Enum.member?(benefit_checker, %{diagnosis: "covered", procedure: "covered"}) do
            {:ok}
          else
            {:not_found}
          end
        end)
      else
        exclusion_base_result =
          Enum.map(member_product.account_product.product.product_coverages, fn(product_coverage) ->
            Enum.map(member_product.account_product.product.product_exclusions, fn(product_exclusion) ->
              exclusion_checker =
                check_dp_in_product_exclusion_based_nc(product_exclusion, procedure_code, params, diagnosis_code)
              exclusion_checker =
                exclusion_checker
                |> List.flatten()
                |> Enum.uniq()

              if Enum.member?(exclusion_checker, {:excluded}) do
                {:excluded}
              else
                {:not_excluded}
              end
            end)
        end)
        exclusion_base_result =
          exclusion_base_result
          |> List.flatten()

        if Enum.member?(exclusion_base_result, {:excluded}) do
          {:not_found}
        else
          {:ok}
        end
      end
    end)

    result =
      result
      |> List.flatten()

    if Enum.member?(result, {:ok}) do
      {:ok_product_dp}
    else
      {:no_procedure_found}
    end
  end

  defp check_dp_in_product_exclusion_based_nc(product_exclusion, procedure_code, params, diagnosis_code) do
    Enum.map(product_exclusion.exclusion.exclusion_procedures, fn(exclusion_procedure) ->
      if exclusion_procedure.procedure.code == procedure_code do
        {:excluded}
      else
        params =
          params
          |> Map.put(:procedure, "covered")
          |> Map.put(:diagnosis, "covered")
        Enum.map(product_exclusion.exclusion.exclusion_diseases, fn(exclusion_diagnosis) ->
          if exclusion_diagnosis.disease.code == diagnosis_code do
            params =
             params
             |> Map.put(:diagnosis, nil)
          else
            params =
              params
              |> Map.put(:diagnosis, "covered")
          end
        end)
      end
    end)
  end

  defp check_dp_in_product_benefit_based_nc(product_benefit, procedure_code, params, diagnosis_code) do
    Enum.map(product_benefit.benefit.benefit_procedures, fn(benefit_procedure) ->
      if benefit_procedure.procedure.code == procedure_code do
        params =
         params
         |> Map.put(:procedure, "covered")
         Enum.map(product_benefit.benefit.benefit_diagnoses, fn(benefit_diagnosis) ->
          if benefit_diagnosis.diagnosis.code == diagnosis_code do
            params =
              params
              |> Map.put(:diagnosis, "covered")
          else
            params =
              params
              |> Map.put(:diagnosis, nil)
          end
        end)
      else
        {:not_found}
      end
    end)
  end

  defp check_diagnosis_in_product_benefit_based_nc(product_benefit, params, diagnosis_code) do
    Enum.map(product_benefit.benefit.benefit_diagnoses, fn(benefit_diagnosis) ->
      if benefit_diagnosis.diagnosis.code == diagnosis_code do
        params =
          params
          |> Map.put(:diagnosis, "covered")
      else
        {:not_found}
      end
    end)
  end

  defp check_diagnosis_in_product_exclusion_based_nc(product_exclusion, params, diagnosis_code) do
    Enum.map(product_exclusion.exclusion.exclusion_diseases, fn(exclusion_diagnosis) ->
      if exclusion_diagnosis.disease.code == diagnosis_code do
        {:excluded}
      else
        params =
          params
          |> Map.put(:diagnosis, "covered")
      end
    end)
  end
end
