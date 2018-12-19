defmodule Innerpeace.Db.Base.BenefitContext do
  @moduledoc false

  import Ecto.{Query, Changeset}, warn: false

  alias Innerpeace.Db.{
    Repo,
    Schemas.Benefit,
    Schemas.Package,
    Schemas.BenefitCoverage,
    Schemas.BenefitProcedure,
    Schemas.BenefitDiagnosis,
    Schemas.BenefitLimit,
    Schemas.BenefitRUV,
    Schemas.Coverage,
    Schemas.User,
    Schemas.BenefitPackage,
    Schemas.Coverage,
    Schemas.BenefitPackagePayorProcedure,
    Schemas.BenefitPharmacy,
    Schemas.BenefitMiscellaneous,
    Schemas.PackagePayorProcedure,
    Schemas.PayorProcedure,
    Schemas.BenefitLog,
    Schemas.RUV,
    Schemas.Procedure,
    Schemas.ProcedureCategory,
    Schemas.BenefitDiagnosis,
    Schemas.Diagnosis,
    Schemas.ProductBenefit,
    Schemas.BenefitProcedure
  }

  alias Innerpeace.Db.Base.{
    PackageContext,
    BenefitContext,
    CoverageContext,
    ProcedureContext,
    PharmacyContext,
    MiscellaneousContext
  }

  alias Plug.CSRFProtection

  def insert_or_update_benefit_health(params) do
    benefit = get_benefit_by_name_and_code(params.name, params.code)

    if is_nil(benefit) do
      create_benefit_health(params)
    else
      update_benefit_health(benefit, params)
    end
  end

  def get_benefit_by_name_and_code(name, code) do
    Benefit
    |> Repo.get_by(name: name, code: code)
  end

  def get_benefit_by_coverage(coverage) do
    Benefit
    |> Repo.get_by(coverage: coverage)
  end

  def insert_or_update_benefit_riders(params) do
    benefit = get_benefit_by_name_and_code(params.name, params.code)

    if is_nil(benefit) do
      create_benefit_riders(params)
    else
      update_benefit_riders(benefit, params)
    end
  end

  def get_benefit_by_name(name) do
    Benefit
    |> Repo.get_by(name: name)
    |> Repo.preload([
      :created_by,
      :updated_by,
      :benefit_limits,
      benefit_ruvs: :ruv,
      benefit_packages: [package: [package_payor_procedure: [payor_procedure: :procedure]]],
      benefit_procedures: :procedure,
      benefit_coverages: :coverage
    ])
  end

  def get_all_benefits do
    Benefit
    |> Repo.all()
    |> Repo.preload([
      :created_by,
      :updated_by,
      :benefit_limits,
      benefit_ruvs: :ruv,
      benefit_packages: [package: [package_payor_procedure: [payor_procedure: :procedure]]],
      benefit_coverages: :coverage,
      benefit_procedures: [
        procedure: [
          procedure: :procedure_category
        ]
      ]
    ])
  end

  def get_benefit(id) do
    Benefit
    |> Repo.get!(id)
    |> Repo.preload([
      :benefit_limits,
      :benefit_logs,
      :product_benefits,
      benefit_ruvs: :ruv,
      benefit_packages: [
        benefit_package_payor_procedures: :payor_procedure,
        package: [
          package_payor_procedure: [
            payor_procedure: :procedure
          ]
        ]
      ],
      benefit_pharmacies: :pharmacy,
      benefit_miscellaneous: :miscellaneous,
      benefit_coverages: :coverage,
      benefit_diagnoses: :diagnosis,
      benefit_procedures: [
        :package,
        procedure: [
          procedure: :procedure_category
        ]
      ]
    ])
  end

  def get_benefit_by_code_or_name(param) do
    Benefit
    |> where([b], b.code == ^param or b.name == ^param)
    |> limit(1)
    |> Repo.one()
    |> Repo.preload([
      :benefit_limits,
      :benefit_logs,
      :product_benefits,
      benefit_ruvs: :ruv,
      benefit_packages: [
        benefit_package_payor_procedures: :payor_procedure,
        package: [
          package_payor_procedure: [
            payor_procedure: :procedure
          ]
        ]
      ],
      benefit_pharmacies: :pharmacy,
      benefit_miscellaneous: :miscellaneous,
      benefit_coverages: :coverage,
      benefit_diagnoses: :diagnosis,
      benefit_procedures: [
        :package,
        procedure: [
          procedure: :procedure_category
        ]
      ]
    ])
  end

  def get_benefit!(id) do
    Benefit
    |> Repo.get(id)
    |> Repo.preload([
      :benefit_limits,
      :benefit_logs,
      benefit_ruvs: :ruv,
      benefit_packages: [
        benefit_package_payor_procedures: :payor_procedure,
        package: [
          package_payor_procedure: [
            payor_procedure: :procedure
          ]
        ]
      ],
      benefit_pharmacies: :pharmacy,
      benefit_miscellaneous: :miscellaneous,
      benefit_coverages: :coverage,
      benefit_diagnoses: :diagnosis,
      benefit_procedures: [
        :package,
        procedure: [
          procedure: :procedure_category
        ]
      ]
    ])
  end

  def get_benefit_new!(id) do
    Benefit
    |> where([b], b.id == ^id)
    |> select([b], %{
      id: b.id,
      category: b.category,
      step: b.step
    })
    |> Repo.one()
  end

  def get_benefit_procedures(id) do
    query = (
    from b in Benefit,
    join: bp in BenefitProcedure, on: bp.benefit_id == b.id,
    join: pp in PayorProcedure, on: pp.id == bp.procedure_id,
    join: p in Procedure, on: pp.procedure_id == p.id,
    join: pc in ProcedureCategory, on: pc.id == p.procedure_category_id,
    where: b.id == ^id,
    select: %{
      id: bp.id,
      code: pp.code,
      description: pp.description,
      procedure_code: p.code,
      procedure_description: p.description,
      procedure_category: pc.name
    }
    )
    Repo.all(query)
  end

  def get_benefit_procedure_ids(id) do
    query = (
    from b in Benefit,
    join: bp in BenefitProcedure, on: bp.benefit_id == b.id,
    join: pp in PayorProcedure, on: pp.id == bp.procedure_id,
    join: p in Procedure, on: pp.procedure_id == p.id,
    join: pc in ProcedureCategory, on: pc.id == p.procedure_category_id,
    where: b.id == ^id,
    select: (pp.id)
    )
    Repo.all(query)
  end

  # def get_benefit_procedure_data(id) do
  #   Procedure
  #   |> where([p], p.id == ^id)
  #   |> select([p], %{
  #     code: p.code,
  #     description: p.description
  #   })
  #   |> Repo.all()
  # end

  def changes_to_string(changeset) do
    changes =
      for {key, new_value} <- changeset.changes, into: [] do
        "<b> <i> #{transform_atom(key)} </b> </i> from <b> <i> #{Map.get(changeset.data, key)} </b> </i> to <b> <i> #{
          new_value
        } </b> </i>"
      end

    changes |> Enum.join(", ")
  end

  def get_benefit_log(benefit_id, message) do
    BenefitLog
    |> where([bn], bn.benefit_id == ^benefit_id and like(bn.message, ^"%#{message}%"))
    |> Repo.all()
  end

  def get_all_benefit_log(benefit_id) do
    BenefitLog
    |> where([bn], bn.benefit_id == ^benefit_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  def get_package_by_id(package_id) do
    BenefitPackage
    |> where([pl], pl.package_id == ^package_id)
    |> Repo.all()
    |> Repo.preload(:package)
  end

  def create_benefit_peme_log(user, benefit) do
    message = " <b> #{user.username} </b> created benefit."

    insert_log(%{
      benefit_id: benefit.id,
      user_id: user.id,
      message: message
    })
  end

  def edit_benefit_peme_log(user, changeset, tab) do
    if Enum.empty?(changeset.changes) == false do
      # changes = insert_changes_to_string_benefit(params)
      changes = changes_to_string(changeset)
      message = " <b> #{user.username} </> edited #{changes} in <i> #{tab}
    </i> tab."

      insert_log(%{
        benefit_id: changeset.data.id,
        user_id: user.id,
        message: message
      })
    end
  end

  def add_package_peme_log(user, benefit, params, tab) do
    # if Enum.empty?(changeset.changes) == false do
    # changes = changes_to_string(changeset)
    changes = insert_changes_to_string_package(params)
    message = " <b> #{user.username} </> added a new package where #{changes} in <i> #{tab}
      </i> tab."

    insert_log(%{
      benefit_id: benefit.id,
      user_id: user.id,
      message: message
    })
  end

  def delete_package_peme_log(user, benefit, params, tab) do
    changes = delete_package_changes_to_string(params)
    message = " <b> #{user.username} </> removed a package where #{changes} in <i> #{tab}
    </i> tab."

    insert_log(%{
      benefit_id: benefit.id,
      user_id: user.id,
      message: message
    })
  end

  def discontinue_peme_log(user, benefit, params) do
    # if Enum.empty?(changeset.changes) == false do
    changes = discontinue_changes_to_string_benefits(params)
    # changes = changes_to_string(changeset)
    message =
      " <b> #{user.username} </> Discontinue benefit where #{changes} <i> <i/> on #{
        benefit.discontinue_date
      }."

    insert_log(%{
      benefit_id: benefit.id,
      user_id: user.id,
      message: message
    })
  end

  def disable_peme_log(user, benefit, params) do
    # if Enum.empty?(changeset.changes) == false do
    changes = disable_changes_to_string_benefits(params)
    # changes = changes_to_string(changeset)
    message = " <b> #{user.username} </> Disabled benefit where #{changes} <i>
    </i> on #{benefit.disabled_date}."

    insert_log(%{
      benefit_id: benefit.id,
      user_id: user.id,
      message: message
    })
  end

  def delete_peme_log(user, benefit, params) do
    # if Enum.empty?(changeset.changes) == false do
    changes = delete_changes_to_string_benefits(params)
    # changes = changes_to_string(changeset)
    message = " <b> #{user.username} </> Added benefit for deletion where #{changes} <i>
    </i> on #{benefit.delete_date}."

    insert_log(%{
      benefit_id: benefit.id,
      user_id: user.id,
      message: message
    })
  end

  def insert_changes_to_string_benefit(params) do
    changes = params

    changes =
      changes
      |> Map.delete("created_by")
      |> Map.delete("updated_by")
      |> Map.delete("step")

    params = %{benefit_name: changes["name"]}

    changes =
      for {key, new_value} <- params, into: [] do
        "<b> <i> #{transform_atom(key)} </b> </i> <b> <i> #{new_value} </b> </i>"
      end

    changes |> Enum.join(", ")
  end

  def discontinue_changes_to_string_benefits(params) do
    benefit = get_benefit(params["id"])
    changes = params

    changes =
      changes
      |> Map.delete("created_by")
      |> Map.delete("updated_by")
      |> Map.delete("step")

    params = %{benefit_code: benefit.code, benefit_name: benefit.name}

    changes =
      for {key, new_value} <- params, into: [] do
        "<b> <i> #{transform_atom(key)} </b> </i> <b> <i> #{new_value} </b> </i>"
      end

    changes |> Enum.join(", ")
  end

  def disable_changes_to_string_benefits(params) do
    benefit = get_benefit(params["id"])
    changes = params

    changes =
      changes
      |> Map.delete("created_by")
      |> Map.delete("updated_by")
      |> Map.delete("step")

    params = %{benefit_code: benefit.code, benefit_name: benefit.name}

    changes =
      for {key, new_value} <- params, into: [] do
        "<b> <i> #{transform_atom(key)} </b> </i> <b> <i> #{new_value} </b> </i>"
      end

    changes |> Enum.join(", ")
  end

  def delete_changes_to_string_benefits(params) do
    benefit = get_benefit(params["id"])
    changes = params

    changes =
      changes
      |> Map.delete("created_by")
      |> Map.delete("updated_by")
      |> Map.delete("step")

    params = %{benefit_code: benefit.code, benefit_name: benefit.name}

    changes =
      for {key, new_value} <- params, into: [] do
        "<b> <i> #{transform_atom(key)} </b> </i> <b> <i> #{new_value} </b> </i>"
      end

    changes |> Enum.join(", ")
  end

  def insert_changes_to_string_package(params) do
    Enum.map(params["package_ids"], fn x ->
      package = PackageContext.get_package(x)
      changes = params

      changes =
        changes
        |> Map.delete("created_by")
        |> Map.delete("updated_by")
        |> Map.delete("step")

      # |> Map.merge(%{package_code: package.code, package_name: package.name})
      params = %{package_code: package.code, package_name: package.name}

      changes =
        for {key, new_value} <- params, into: [] do
          "<b> <i> #{transform_atom(key)} </b> </i> <b> <i> #{new_value} </b> </i>"
        end

      changes |> Enum.join(", ")
    end)
  end

  def delete_package_changes_to_string(params) do
    package = PackageContext.get_package(params.package_id)
    changes = params

    changes =
      changes
      |> Map.delete("created_by")
      |> Map.delete("updated_by")
      |> Map.delete("step")

    params = %{package_code: package.code, package_name: package.name}

    changes =
      for {key, new_value} <- params, into: [] do
        "<b> <i> #{transform_atom(key)} </b> </i> <b> <i> #{new_value} </b> </i>"
      end

    changes |> Enum.join(", ")
  end

  defp transform_atom(atom) do
    atom
    |> Atom.to_string()
    |> String.split("_")
    |> Enum.map(&String.capitalize(&1))
    |> Enum.join(" ")
  end

  defp insert_log(params) do
    changeset = BenefitLog.changeset(%BenefitLog{}, params)
    Repo.insert!(changeset)
  end

  def create_benefit_health(benefit_params) do
    %Benefit{}
    |> Benefit.changeset_health(benefit_params)
    |> Repo.insert()
  end

  def create_benefit_riders(benefit_params) do
    %Benefit{}
    |> Benefit.changeset_riders(benefit_params)
    |> Repo.insert()
  end

  def update_benefit_health(benefit, benefit_params) do
    benefit
    |> Benefit.changeset_health(benefit_params)
    |> Repo.update()
  end

  def update_benefit_riders(benefit, benefit_params) do
    benefit
    |> Benefit.changeset_riders(benefit_params)
    |> Repo.update()
  end

  def update_benefit(%Benefit{} = benefit, benefit_params) do
    benefit
    |> Benefit.changeset_step(benefit_params)
    |> Repo.update()
  end

  def delete_benefit(id) do
    benefit =
      id
      |> get_benefit()

    if is_nil(benefit.product_benefits) || Enum.empty?(benefit.product_benefits) do
      benefit
      |> Repo.delete()
    end
  end

  def delete_benefit!(id) do
    benefit =
      id
      |> get_benefit()

    if is_nil(benefit.product_benefits) || Enum.empty?(benefit.product_benefits) do
      benefit
      |> Repo.delete!()
    end
  end

  def disabling_benefit(id) do
    id
    |> get_benefit()
    |> Benefit.changset_change_status(%{status: "Disabled"})
    |> Repo.update()
  end

  def disable_benefit(id) do
    id
    |> get_benefit()
    |> Benefit.changset_change_status(%{status: "Disabled"})
    |> Repo.update()
  end

  def discontinue_benefit(id) do
    id
    |> get_benefit()
    |> Benefit.changset_change_status(%{status: "Discontinued"})
    |> Repo.update()
  end

  def set_benefit_coverages(benefit_id, coverage_ids) do
    for coverage_id <- coverage_ids do
      params = %{benefit_id: benefit_id, coverage_id: coverage_id}
      changeset = BenefitCoverage.changeset(%BenefitCoverage{}, params)
      Repo.insert!(changeset)
    end
  end

  def clear_benefit_coverages(benefit_id) do
    BenefitCoverage
    |> where([cb], cb.benefit_id == ^benefit_id)
    |> Repo.delete_all()
  end

  def set_benefit_procedures(benefit_id, procedure_ids) do
    for procedure_id <- procedure_ids do
      params = %{benefit_id: benefit_id, procedure_id: procedure_id}
      changeset = BenefitProcedure.changeset(%BenefitProcedure{}, params)
      Repo.insert!(changeset)
    end
  end

  def set_benefit_procedure(benefit_id, procedure_ids) do
    for package_id <- procedure_ids do
      params = %{benefit_id: benefit_id, procedure_id: package_id}
      changeset = BenefitPackage.changeset(%BenefitPackage{}, params)
      Repo.insert!(changeset)
    end
  end

  def clear_benefit_procedures(benefit_id) do
    BenefitProcedure
    |> where([bc], bc.benefit_id == ^benefit_id)
    |> Repo.delete_all()
  end

  def set_benefit_diagnoses(benefit_id, diagnosis_ids) do
    for diagnosis_id <- diagnosis_ids do
      params = %{benefit_id: benefit_id, diagnosis_id: diagnosis_id}
      changeset = BenefitDiagnosis.changeset(%BenefitDiagnosis{}, params)
      Repo.insert!(changeset)
    end
  end

  def clear_benefit_diagnoses(benefit_id) do
    BenefitDiagnosis
    |> where([bd], bd.benefit_id == ^benefit_id)
    |> Repo.delete_all()
  end

  def set_benefit_ruvs(benefit_id, ruv_ids) do
    for ruv_id <- ruv_ids do
      params = %{benefit_id: benefit_id, ruv_id: ruv_id}
      changeset = BenefitRUV.changeset(%BenefitRUV{}, params)
      Repo.insert!(changeset)
    end
  end

  def clear_benefit_ruvs(benefit_id) do
    BenefitRUV
    |> where([bd], bd.benefit_id == ^benefit_id)
    |> Repo.delete_all()
  end

  def set_benefit_packages(benefit_id, package_ids) do
    test =
      Enum.map(get_benefit(benefit_id).benefit_coverages, fn x ->
        x.coverage.code
      end)

    test =
      test
      |> List.first()

    if test == "PEME" do
      params = %{
        "limit_type" => "Sessions",
        "limit_session" => 1,
        "benefit_id" => benefit_id,
        "coverages" => "PEME"
      }

      %BenefitLimit{}
      |> BenefitLimit.changeset(params)
      |> Repo.insert!()
    end

    for package_id <- package_ids do
      packages = PackageContext.get_package(package_id)
      {
        male,
        female,
        age_from,
        age_to
      } = get_package_details(List.first(packages.package_payor_procedure))
      benefit_package =
        %BenefitPackage{}
        |> BenefitPackage.changeset(%{
          benefit_id: benefit_id,
          package_id: package_id,
          male: male,
          female: female,
          age_from: age_from,
          age_to: age_to
        })
        |> Repo.insert!()
    end
  end

  defp get_package_details(nil), do: {nil, nil, nil, nil}
  defp get_package_details(package_procedure) do
    {
      package_procedure.male,
      package_procedure.female,
      package_procedure.age_from,
      package_procedure.age_to
    }
  end

  ##################################### start of Package Overlapping Validation #################################

  ################### ajax request from new layout benefit ###################

  def set_acu_packages(package_ids) do
    with {:recursion_done} <- validate_male_multiple_packages(package_ids),
         {:recursion_done} <- validate_female_multiple_packages(package_ids) do
      {:ok}
    else
      {:invalid, message} ->
        {:invalid, message}
      _ ->
        {:invalid, "Error setting up benefit package."}
    end
  end

  #################### ajax request from new layout benefit ##################

  def package_checker(benefit_id, package_id) do
    checker_query =
      from(
        bp in BenefitPackage,
        where: bp.benefit_id == ^benefit_id and bp.package_id == ^package_id
      )

    result = Repo.all(checker_query)

    if result == [] do
      true
    else
      false
    end
  end

  def set_acu_benefit_packages(benefit_id, package_ids) do
    with {:merged_ids, package_ids} <- benefit_id |> if_overlaps_bp_lvl1(package_ids),
         {:recursion_done} <- validate_male_multiple_packages(package_ids),
         {:recursion_done} <- validate_female_multiple_packages(package_ids) do
      package_ids
      |> Enum.each(fn x ->
        result = package_checker(benefit_id, x)

        ## ppp = package_payor_procedure
        distincted_ppp =
          PackageContext.get_package(x).package_payor_procedure
          |> Enum.map(fn x -> package_pp_details(x) end)
          |> ppp_gender_age_cloning()

        if result == true do
          %BenefitPackage{}
          |> BenefitPackage.changeset(%{
            benefit_id: benefit_id,
            package_id: x,
            age_from: distincted_ppp.age_from,
            age_to: distincted_ppp.age_to,
            male: distincted_ppp.male,
            female: distincted_ppp.female
          })
          |> Repo.insert!()
        end
      end)

      benefit = get_benefit(benefit_id)

      if Enum.empty?(benefit.benefit_limits) do
        test =
          Enum.map(get_benefit(benefit_id).benefit_coverages, fn x ->
            x.coverage.code
          end)

        test =
          test
          |> List.first()

        if test == "PEME" do
          params = %{
            "limit_type" => "Sessions",
            "limit_session" => 1,
            "benefit_id" => benefit_id,
            "coverages" => "PEME"
          }

          %BenefitLimit{}
          |> BenefitLimit.changeset(params)
          |> Repo.insert!()
        end
      end

      {:ok}
    else
      {:invalid, message} ->
        {:invalid, message}
    end
  end

  def validate_male_multiple_packages(package_ids) do
    package_ids
    |> Enum.map(&PackageContext.get_package(&1))
    |> Enum.into(
      [],
      &(&1.package_payor_procedure
        |> Enum.map(fn x -> package_pp_details(x) end)
        |> ppp_gender_age_checker(&1.name))
    )
    |> collecting_all_male()
  rescue
    _ ->
    {:invalid, "Invalid Benefit Packages"}
  end

  def validate_female_multiple_packages(package_ids) do
    package_ids
    |> Enum.map(&PackageContext.get_package(&1))
    |> Enum.into(
      [],
      &(&1.package_payor_procedure
        |> Enum.map(fn x -> package_pp_details(x) end)
        |> ppp_gender_age_checker(&1.name))
    )
    |> collecting_all_female()
  rescue
    _ ->
    {:invalid, "Invalid Benefit Packages"}
  end

  defp package_pp_details(ppp_struct) do
    %{
      age_from: ppp_struct.age_from,
      age_to: ppp_struct.age_to,
      male: ppp_struct.male,
      female: ppp_struct.female
    }
  end

  defp ppp_gender_age_checker(list_maps, x) do
    ##  - package payor procedure gender and age checker
    ##     - take all package_payor_procedure of this package and distinct
    %{
      package_name: x,
      age_from: check_age_from(list_maps),
      age_to: check_age_to(list_maps),
      male: take_gender(list_maps, :male),
      female: take_gender(list_maps, :female)
    }
  end

  defp ppp_gender_age_cloning(list_maps) do
    ##  - package payor procedure gender and age checker
    ##     - take all package_payor_procedure of this package and distinct
    %{
      age_from: check_age_from(list_maps),
      age_to: check_age_to(list_maps),
      male: take_gender(list_maps, :male),
      female: take_gender(list_maps, :female)
    }
  end

  defp take_gender(list_maps, gender) do
    list_maps
    |> Enum.into([], & &1[gender])
    |> Enum.uniq()
    |> List.first()
  end

  defp check_age_from(ages) do
    ## catcher for wrong data
      ages
      |> Enum.into([], & &1.age_from)
      |> Enum.uniq()
      |> Enum.min()
    rescue
      _ ->
        nil
  end

  defp check_age_to(ages) do
    ## catcher for wrong data
      ages
      |> Enum.into([], & &1.age_to)
      |> Enum.uniq()
      |> Enum.max()
    rescue
      _ ->
        nil
  end

  defp collecting_all_male(list) do
    list
    |> Enum.filter(&(&1.male == true))
    |> validate_overlapping_age()
  end

  defp collecting_all_female(list) do
    list
    |> Enum.filter(&(&1.female == true))
    |> validate_overlapping_age()
  end

  def validate_overlapping_age([head | tail]) do
    # recursion for overlapping age
    tail
    |> Enum.map(
      &if comparing_age(head, &1) do
        true
      else
        with true <- comparing_age(&1, head) do
          true
        else
          _ ->
            false
        end
      end
    )
    |> result_false_checker(tail)
  end

  def validate_overlapping_age([]), do: {:recursion_done}

  defp result_false_checker(result, tail) do
    if Enum.member?(result, false) do
      {:invalid,
       "Package/s cannot be added. Selected package/s have overlapping age and gender."}
    else
      validate_overlapping_age(tail)
    end
  end

  defp comparing_age(a, b) do
    if a.age_from > b.age_to do
      true
    else
      false
    end
  end

  defp if_overlaps_bp_lvl1(benefit_id, package_ids) do
    get_benefit!(benefit_id).benefit_packages
    |> Enum.map(fn bp -> bp.package.id end)
    |> if_overlaps_bp_lvl2(package_ids)
  end

  defp if_overlaps_bp_lvl2(current_bp, package_ids) do
    {:merged_ids, package_ids ++ current_bp}
  end

  ##################################### end of Package Overlapping Validation #################################

  def set_benefit_pharmacies(benefit_id, pharmacy_ids) do
    pharmacy_ids
    |> Enum.map(fn x ->
      if check_benefit_pharma(benefit_id, x) do
        pharmacy = PharmacyContext.get_pharmacy(x)

        %BenefitPharmacy{}
        |> BenefitPharmacy.changeset(%{
          benefit_id: benefit_id,
          pharmacy_id: pharmacy.id,
          ## cloned data
          drug_code: pharmacy.drug_code,
          generic_name: pharmacy.generic_name,
          brand: pharmacy.brand,
          strength: pharmacy.strength,
          form: pharmacy.form,
          maximum_price: pharmacy.maximum_price
        })
        |> Repo.insert()
      end
    end)
  end

  def set_benefit_miscellaneous(benefit_id, miscellaneous_ids) do
    miscellaneous_ids
    |> Enum.map(fn x ->
      if check_benefit_misc(benefit_id, x) do
        miscellaneous = MiscellaneousContext.get_miscellaneous(x)

        %BenefitMiscellaneous{}
        |> BenefitMiscellaneous.changeset(%{
          benefit_id: benefit_id,
          miscellaneous_id: miscellaneous.id,
          code: miscellaneous.code,
          description: miscellaneous.description,
          price: miscellaneous.price
        })
        |> Repo.insert()
      end
    end)
  end

  defp check_benefit_pharma(benefit_id, pharmacy_id) do
    checker_query =
      from(
        bp in BenefitPharmacy,
        where: bp.benefit_id == ^benefit_id and bp.pharmacy_id == ^pharmacy_id
      )

    result = Repo.all(checker_query)

    if result == [] do
      true
    else
      false
    end
  end

  defp check_benefit_misc(benefit_id, miscellaneous_id) do
    checker_query =
      from(
        bm in BenefitMiscellaneous,
        where: bm.benefit_id == ^benefit_id and bm.miscellaneous_id == ^miscellaneous_id
      )

    result = Repo.all(checker_query)

    if result == [] do
      true
    else
      false
    end
  end

  def clear_benefit_pharmacy(benefit_id) do
    BenefitPharmacy
    |> where([x], x.benefit_id == ^benefit_id)
    |> Repo.delete_all()
  end

  def clear_benefit_miscellaneous(benefit_id) do
    BenefitMiscellaneous
    |> where([x], x.benefit_id == ^benefit_id)
    |> Repo.delete_all()
  end

  def clear_benefit_packages(benefit_id) do
    BenefitPackage
    |> where([bd], bd.benefit_id == ^benefit_id)
    |> Repo.delete_all()
  end

  def acu_coverage?(benefit_coverages) do
    list =
      [] ++
        for benefit_coverage <- benefit_coverages do
          benefit_coverage.coverage.name
        end

    Enum.member?(list, "ACU")
  end

  def peme_coverage?(benefit_coverages) do
    list =
      [] ++
        for benefit_coverage <- benefit_coverages do
          benefit_coverage.coverage.name
        end

    Enum.member?(list, "PEME")
  end

  def insert_acu_procedure(benefit_id, package_id, package_payor_procedures) do
    for package_payor_procedure <- package_payor_procedures do
      params = %{
        benefit_id: benefit_id,
        package_id: package_id,
        procedure_id: package_payor_procedure.payor_procedure.id,
        gender: setup_gender(package_payor_procedure.male, package_payor_procedure.female),
        age_from: package_payor_procedure.age_from,
        age_to: package_payor_procedure.age_to
      }

      %BenefitProcedure{}
      |> BenefitProcedure.changeset_acu(params)
      |> Repo.insert!()
    end
  end

  defp setup_gender(male, female) do
    male =
      if male do
        "Male"
      end

    female =
      if female do
        "Female"
      end

    [male, female]
    |> List.delete(nil)
    |> Enum.join(" & ")
  end

  def insert_benefit_limit(benefit_id, benefit_params) do
    %BenefitLimit{}
    |> BenefitLimit.changeset(benefit_params)
    |> Repo.insert()
  end

  # def update_discontinue_benefit(benefit, benefit_params) do
  #   benefit
  #   |> Benefit.changeset_discontinue_benefit(benefit_params)
  #   |> Repo.update()
  # end

  def clear_benefit_limits(benefit_id) do
    BenefitLimit
    |> where([bl], bl.benefit_id == ^benefit_id)
    |> Repo.delete_all()
  end

  def clear_all(benefit_id) do
    clear_benefit_coverages(benefit_id)
    clear_benefit_procedures(benefit_id)
    clear_benefit_limits(benefit_id)
    clear_benefit_diagnoses(benefit_id)
    clear_benefit_packages(benefit_id)
    clear_benefit_ruvs(benefit_id)
    clear_benefit_pharmacy(benefit_id)
    clear_benefit_miscellaneous(benefit_id)
  end

  def edit_update_benefit_health(benefit, benefit_params) do
    benefit
    |> Benefit.changeset_edit_health(benefit_params)
    |> Repo.update()
  end

  def edit_update_benefit_riders(benefit, benefit_params) do
    benefit
    |> Benefit.changeset_edit_riders(benefit_params)
    |> Repo.update()
  end

  def update_benefit_limit(benefit_limit_id, params) do
    BenefitLimit
    |> Repo.get!(benefit_limit_id)
    |> BenefitLimit.changeset(params)
    |> Repo.update()
  end

  def delete_benefit_limit(benefit_limit_id) do
    BenefitLimit
    |> Repo.get!(benefit_limit_id)
    |> Repo.delete()
  end

  def setup_limits_params(params) do
    setup_limit_by_coverage(
      params["coverages"],
      params
    )
  end

  def setup_limits_peme_params(params) do
    setup_limit_by_coverage_peme(
      params["coverages"],
      params
    )
  end

  defp setup_limit_by_coverage(coverages, params) when is_list(coverages) do
    cond do
      Enum.member?(coverages, "ACU") == true ->
        setup_limit_acu(params)

      Enum.member?(coverages, "PEME") == true ->
        setup_limit_peme(params)

      true ->
        setup_limit_normal(params)
    end
  end

  defp setup_limit_by_coverage(coverages, params) when is_bitstring(coverages) do
    if coverages == "ACU" do
      setup_limit_acu(params)
    else
      setup_limit_normal(params)
    end
  end

  defp setup_limit_by_coverage_peme(coverages, params) when is_list(coverages) do
    if coverages == "PEME" do
      setup_limit_peme(params)
    else
      setup_limit_normal(params)
    end
  end

  defp setup_limit_by_coverage_peme(coverages, params) when is_bitstring(coverages) do
    if coverages == "PEME" do
      setup_limit_peme(params)
    else
      setup_limit_normal(params)
    end
  end

  defp setup_limit_normal(params) do
    case params["limit_type"] do
      "Peso" ->
        Map.merge(params, %{
          "limit_amount" => params["amount"],
          "limit_session" => nil,
          "limit_percentage" => nil,
          "limit_tooth" => nil,
          "limit_quadrant" => nil,
        })

      "Sessions" ->
        Map.merge(params, %{
          "limit_amount" => nil,
          "limit_session" => params["amount"],
          "limit_percentage" => nil,
          "limit_tooth" => nil,
          "limit_quadrant" => nil,
        })

      "Plan Limit Percentage" ->
        Map.merge(params, %{
          "limit_amount" => nil,
          "limit_session" => nil,
          "limit_percentage" => params["amount"],
          "limit_tooth" => nil,
          "limit_quadrant" => nil
        })

      "Tooth" ->
        Map.merge(params, %{
          "limit_amount" => nil,
          "limit_session" => nil,
          "limit_percentage" => nil,
          "limit_tooth" => params["amount"],
          "limit_quadrant" => nil
        })

      "Quadrant" ->
        Map.merge(params, %{
          "limit_amount" => nil,
          "limit_session" => nil,
          "limit_percentage" => nil,
          "limit_tooth" => nil,
          "limit_quadrant" => params["amount"]
        })

      _ ->
        raise "Invalid limit type!"
    end
  end

  defp setup_limit_acu(params) do
    amount =
      if params["amount"] != "" do
        params["amount"]
        |> String.split(",")
        |> Enum.join("")
        |> Decimal.new()
      else
        nil
      end

    params
    |> Map.put("limit_amount", amount)
    # |> Map.put("limit_session", 1)
  end

  defp setup_limit_peme(params) do
    params
    |> Map.put("limit_type", "Session")
    |> Map.put("limit_session", 1)
  end

  def get_benefit_limits_by_benefit_id(benefit_id) do
    BenefitLimit
    |> where([bl], bl.benefit_id == ^benefit_id)
    |> Repo.all()
  end

  ## BENEFIT COVERAGE SEEDS
  def insert_or_update_benefit_coverage(params) do
    benefit_coverage = get_by_benefit_and_coverage(params.benefit_id, params.coverage_id)

    if is_nil(benefit_coverage) do
      create_benefit_coverage(params)
    else
      update_benefit_coverage(benefit_coverage.id, params)
    end
  end

  def get_by_benefit_and_coverage(benefit_id, coverage_id) do
    BenefitCoverage
    |> Repo.get_by(benefit_id: benefit_id, coverage_id: coverage_id)
  end

  def create_benefit_coverage(benefit_coverage_param) do
    %BenefitCoverage{}
    |> BenefitCoverage.changeset(benefit_coverage_param)
    |> Repo.insert()
  end

  def update_benefit_coverage(id, benefit_coverage_param) do
    id
    |> get_benefit_coverage()
    |> BenefitCoverage.changeset(benefit_coverage_param)
    |> Repo.update()
  end

  def get_benefit_coverage(id) do
    BenefitCoverage
    |> Repo.get!(id)
  end

  ## END OF BENEFIT COVERAGE SEEDS

  ## BENEFIT PROCEDURE SEEDS
  def insert_or_update_benefit_procedure(params) do
    benefit_procedure = get_by_benefit_and_procedure(params.benefit_id, params.procedure_id)

    if is_nil(benefit_procedure) do
      create_benefit_procedure(params)
    else
      update_benefit_procedure(benefit_procedure.id, params)
    end
  end

  def get_by_benefit_and_procedure(benefit_id, procedure_id) do
    BenefitProcedure
    |> Repo.get_by(benefit_id: benefit_id, procedure_id: procedure_id)
  end

  def get_benefit_procedure_by_id(benefit_id) do
    BenefitProcedure
    |> Repo.get_by(benefit_id: benefit_id)
  end

  def create_benefit_procedure(benefit_procedure_param) do
    %BenefitProcedure{}
    |> BenefitProcedure.changeset(benefit_procedure_param)
    |> Repo.insert()
  end

  def update_benefit_procedure(id, benefit_procedure_param) do
    id
    |> get_benefit_procedure()
    |> BenefitProcedure.changeset(benefit_procedure_param)
    |> Repo.update()
  end

  def get_benefit_procedure(id) do
    BenefitProcedure
    |> Repo.get!(id)
  end

  def get_benefit_procedure!(id) do
    BenefitProcedure
    |> Repo.get(id)
  end

  ## END OF BENEFIT PROCEDURE SEEDS

  ## BENEFIT DIAGNOSIS SEEDS
  def insert_or_update_benefit_diagnosis(params) do
    benefit_diagnosis = get_by_benefit_and_diagnosis(params.benefit_id, params.diagnosis_id)

    if is_nil(benefit_diagnosis) do
      create_benefit_diagnosis(params)
    else
      update_benefit_diagnosis(benefit_diagnosis.id, params)
    end
  end

  def get_by_benefit_and_diagnosis(benefit_id, diagnosis_id) do
    BenefitDiagnosis
    |> Repo.get_by(benefit_id: benefit_id, diagnosis_id: diagnosis_id)
  end

  def get_benefit_diagnosis_by_id(benefit_id) do
    BenefitDiagnosis
    |> Repo.get_by(benefit_id: benefit_id)
  end

  def get_benefit_diagnoses_by_benefit_id(benefit_id) do
    BenefitDiagnosis
    |> where([bd], bd.benefit_id == ^benefit_id)
    |> Repo.all()
  end

  def create_benefit_diagnosis(benefit_diagnosis_param) do
    %BenefitDiagnosis{}
    |> BenefitDiagnosis.changeset(benefit_diagnosis_param)
    |> Repo.insert()
  end

  def update_benefit_diagnosis(id, benefit_diagnosis_param) do
    id
    |> get_benefit_diagnosis()
    |> BenefitDiagnosis.changeset(benefit_diagnosis_param)
    |> Repo.update()
  end

  def get_benefit_diagnosis(id) do
    BenefitDiagnosis
    |> Repo.get!(id)
  end

  ## END OF BENEFIT DIAGNOSIS SEEDS
  #

  ############################## BENEFIT LIMIT SEEDS
  def insert_or_update_benefit_limit(params) do
    benefit_limit = get_by_benefit_and_limit(params.benefit_id, params.coverages)

    if is_nil(benefit_limit) do
      create_benefit_limit(params)
    else
      update_benefit_limit(benefit_limit.id, params)
    end
  end

  def get_by_benefit_and_limit(benefit_id, coverages) do
    BenefitLimit
    |> Repo.get_by(benefit_id: benefit_id, coverages: coverages)
  end

  def create_benefit_limit(benefit_limit_param) do
    %BenefitLimit{}
    |> BenefitLimit.changeset(benefit_limit_param)
    |> Repo.insert()
  end

  def update_benefit_limit(id, benefit_limit_param) do
    id
    |> get_benefit_limit()
    |> BenefitLimit.changeset(benefit_limit_param)
    |> Repo.update()
  end

  def get_benefit_limit(id) do
    BenefitLimit
    |> Repo.get(id)
  end

  ##################### END OF BENEFIT LIMIT SEEDS

  def get_benefit_ruv(id) do
    BenefitRUV
    |> where([m], m.id == ^id)
    |> Repo.all()
  end

  def get_benefit_package(id) do
    BenefitPackage
    |> Repo.get!(id)
  end

  def get_benefit_package(package_id, payor_procedure) do
    BenefitPackage
    |> Repo.get_by(package_id: package_id, payor_procedure_code: payor_procedure)
  end

  def get_benefit_package_by_benefit_and_package(benefit_id, package_id) do
    BenefitPackage
    |> Repo.get_by(benefit_id: benefit_id, package_id: package_id)
  end

  def delete_benefit_procedure!(benefit_procedure_id) do
    benefit_procedure_id
    |> get_benefit_procedure()
    |> Repo.delete!()
  end

  def delete_benefit_procedure(benefit_procedure) do
    benefit_procedure
    |> Repo.delete()
  end

  def delete_benefit_disease!(benefit_disease_id) do
    benefit_disease_id
    |> get_benefit_diagnosis()
    |> Repo.delete!()
  end

  def delete_benefit_ruv!(benefit_ruv_id) do
    if get_benefit_ruv(benefit_ruv_id) == [] do
      {:error}
    else
      benefit_ruv_id
      |> get_benefit_ruv()
      |> List.first()
      |> Repo.delete()
    end
  end

  def delete_benefit_package!(id) do
    id
    |> get_benefit_package()
    |> Repo.delete!()
  end

  def delete_benefit_pharmacy!(benefit_pharmacy_id) do
    benefit_pharmacy_id
    |> get_benefit_pharmacy()
    |> Repo.delete!()
  end

  def delete_benefit_miscellaneous!(benefit_miscellaneous_id) do
    benefit_miscellaneous_id
    |> get_benefit_miscellaneous()
    |> Repo.delete!()
  end

  def get_benefit_pharmacy(id) do
    BenefitPharmacy |> Repo.get!(id)
  end

  def get_benefit_miscellaneous(id) do
    BenefitMiscellaneous |> Repo.get!(id)
  end

  def get_all_benefit_code do
    Benefit
    |> select([:code])
    |> Repo.all()
  end

  def get_benefit_code(code) do
    Benefit
    |> Repo.get_by(code: code)
  end

  def set_acu_limit(benefit_id) do
    params = %{
      benefit_id: benefit_id,
      limit_type: "Sessions",
      limit_session: 1,
      coverages: "ACU"
    }

    %BenefitLimit{}
    |> BenefitLimit.changeset(params)
    |> Repo.insert!()
  end

  def set_acu_limit(benefit_id, params) do
    acu_params = List.first(params.limits)
    params = %{
      benefit_id: benefit_id,
      limit_type: "Sessions",
      limit_session: 1,
      limit_amount: acu_params["limit_amount"],
      limit_classification: acu_params["limit_classification"],
      coverages: "ACU"
    }

    %BenefitLimit{}
    |> BenefitLimit.changeset(params)
    |> Repo.insert!()
  end

  def list_benefit_coverages_ids(benefit_id) do
    BenefitCoverage
    |> join(:inner, [bc], c in Coverage, bc.coverage_id == c.id)
    |> where([bc], bc.benefit_id == ^benefit_id)
    |> select([bc, c], c.id)
    |> order_by([bc, c], asc: c.name)
    |> Repo.all()
  end

  def download_benefits(params) do
    param = params["search_value"]

    query =
      from(
        b in Benefit,
        join: cb in User,
        on: b.created_by_id == cb.id,
        join: ub in User,
        on: b.updated_by_id == ub.id,
        join: bcov in BenefitCoverage,
        on: b.id == bcov.benefit_id,
        join: cov in Coverage,
        on: bcov.coverage_id == cov.id,
        where: ilike(b.code, ^"%#{param}%") or ilike(b.name, ^"%#{param}%"),
        order_by: b.code,
        select: [
          b.code,
          b.name,
          cb.username,
          b.inserted_at,
          ub.username,
          b.updated_at,
          fragment("array_to_string(?,', ')", fragment("ARRAY_AGG(?)", cov.name))
        ],
        group_by: b.code,
        group_by: b.name,
        group_by: cb.username,
        group_by: ub.username,
        group_by: b.inserted_at,
        group_by: b.updated_at
      )

    query = Repo.all(query)
  end

  def get_benefit_index(params, offset) do
    query =
      from(
        c in Coverage,
        join: cb in BenefitCoverage,
        on: c.id == cb.coverage_id,
        join: b in Benefit,
        on: b.id == cb.benefit_id,
        join: u in User,
        on: u.id == b.created_by_id,
        join: uu in User,
        on: uu.id == b.updated_by_id,
        where:
          ilike(b.code, ^"%#{params}%") or ilike(b.name, ^"%#{params}%") or
            ilike(c.name, ^"%#{params}%") or ilike(u.username, ^"%#{params}%") or
            ilike(fragment("to_char(?, 'YYYY-MM-DD')", b.inserted_at), ^"%#{params}%") or
            ilike(fragment("to_char(?, 'YYYY-MM-DD')", b.updated_at), ^"%#{params}%") or
            ilike(uu.username, ^"%#{params}%"),
        offset: ^offset,
        order_by: b.code,
        distinct: b.code,
        limit: 100,
        select: b
      )

    # Benefit
    # |> join(:left, [b], u in User, u.id == b.created_by_id)
    # |> join(:left, [b, u], uu in User, uu.id == b.updated_by_id)
    # |> where(
    #  [b, u, uu],
    #  ilike(b.code, ^"%#{params}%") or
    #    ilike(b.name, ^"%#{params}%") or
    #    #TO-DO coverage_benefits
    #    ilike(u.username, ^"%#{params}%") or
    #    ilike(uu.username, ^"%#{params}%")
    # )
    # |> order_by([b], b.code)
    # |> offset(^offset)
    # |> limit(100)
    query
    |> Repo.all()
    |> Enum.uniq()
    |> Repo.preload([
      :created_by,
      :updated_by,
      :benefit_limits,
      benefit_ruvs: :ruv,
      benefit_packages: [package: [package_payor_procedure: [payor_procedure: :procedure]]],
      benefit_coverages: :coverage,
      benefit_procedures: [
        procedure: [
          procedure: :procedure_category
        ]
      ]
    ])
  end

  def get_acu_benefit(id) do
    Benefit
    |> where([b], b.id == ^id)
    |> Repo.all()
    |> Repo.preload([
      :benefit_limits,
      benefit_packages: [
        benefit_package_payor_procedures: :payor_procedure,
        package: [
          package_payor_procedure: [
            payor_procedure: :procedure
          ]
        ]
      ],
      benefit_coverages: :coverage,
      benefit_diagnoses: :diagnosis,
      benefit_procedures: [
        :package,
        procedure: [
          procedure: :procedure_category
        ]
      ]
    ])
    |> Enum.map(
      &(&1.benefit_coverages
        |> Enum.into([], fn x -> if x.coverage.name == "ACU", do: &1.id end))
    )
    |> List.flatten()
    |> Enum.filter(fn b -> b != nil end)
  end

  def disable_benefit(benefit, params) do
    changeset = Benefit.changeset_disabling_benefit(benefit, params)

    if changeset.valid? do
      changeset
      |> Repo.update()

      {:success}
    else
      {:error}
    end
  end

  def discontinue_benefit(benefit, params) do
    changeset = Benefit.changeset_discontinue_benefit(benefit, params)

    if changeset.valid? do
      changeset
      |> Repo.update()

      {:success}
    else
      {:error}
    end
  end

  def delete_peme_benefit(benefit, params) do
    changeset = Benefit.changeset_delete_benefit(benefit, params)

    if changeset.valid? do
      changeset
      |> Repo.update()

      {:success}
    else
      {:error}
    end
  end

  def disabling_peme_benefit(benefit, params) do
    changeset = Benefit.changeset_disabling_benefit(benefit, params)

    if changeset.valid? do
      changeset
      |> Repo.update()

      {:success}
    else
      {:error}
    end
  end

  def discontinue_peme_benefit(benefit, params) do
    changeset = Benefit.changeset_discontinue_benefit(benefit, params)

    if changeset.valid? do
      changeset
      |> Repo.update()

      {:success}
    else
      {:error}
    end
  end

  def trigger_benefit_delete_date do
    benefit_dates =
      Benefit
      |> where([b], not is_nil(b.delete_date))
      |> select([b], [b.delete_date, b.id])
      |> Repo.all()

    for benefit_date <- benefit_dates do
      {:ok, date} = Date.from_erl(Ecto.Date.to_erl(Enum.at(benefit_date, 0)))
      compared_date = Date.compare(date, Date.utc_today())

      if compared_date == :eq or compared_date == :lt do
        id = Enum.at(benefit_date, 1)
        delete_benefit(id)
      end

      # if date = Date.utc_today()
    end
  end

  ################# start: Refactoring Benefit / SinglePageApp approach #####################

  def create_benefit("riders", params), do: validate_riders(params) #Dental_policy_goes_here
  def create_benefit("healthplan", params), do: validate_healthplan(params)
  def create_dental("riders", params), do: validate_riders_dental(params) #Dental_with_availment_goes_here

  def create_benefit(type, params) when type != "healthplan" and type != "riders",
    do: raise type #("Not Valid Benefit Type")

  ## to be follow healthplan
  defp validate_healthplan(params), do: raise(params["coverage_ids"])

  defp validate_riders(params) do
    benefit_policy = params["benefit_policy"]
    params =
      params
      |> Map.put_new("procedure_ids", [])
      |> Map.put_new("diagnosis_ids", [])

    validate_riders_coverage(
      CoverageContext.repo_get_coverage_by_id(params["coverage_ids"]).code,
      params, benefit_policy
    )
  end

  defp validate_riders_dental(params) do
    benefit_policy = params["benefit_policy"]
    params =
      params
      |> Map.put_new("procedure_ids", [])
      |> Map.put_new("diagnosis_ids", [])

    validate_riders_coverage(
      CoverageContext.repo_get_coverage_by_id(params["coverage_ids"]).code,
      params, benefit_policy)
  end

  defp validate_riders_coverage("ACU", params, "Availment") do
    with {:ok, changeset} <- validate_acu_changeset(params),
         {:ok, benefit} <- insert_benefit(changeset.changes),
         {:ok, benefit_coverage} <-
           insert_benefit_coverage(benefit.id, changeset.changes.coverage_ids),
         {:ok, limits} <- insert_benefit_limit_acu(benefit.id, changeset.changes.limits, params["created_by_id"]),
         {:ok} <- insert_benefit_packages_acu(benefit.id, changeset.changes[:acu_package_ids]),
         %Benefit{} = benefit <- get_benefit(benefit.id) do
      {:done, benefit}
    else
      {:schemaless_error, changeset} ->
        {:schemaless_error, changeset}

      {:error, changeset} ->
        {:error, changeset}

      {:draft} ->
        {:draft}
    end
  end

  defp validate_riders_coverage(coverage, params, "Policy") do
    with {:ok, changeset} <- validate_acu_changeset_policy(params),
         {:ok, benefit} <- insert_benefit_policy(changeset.changes),
         {:ok, benefit_coverage} <-
           insert_benefit_coverage(benefit.id, changeset.changes.coverage_ids),
         %Benefit{} = benefit <- get_benefit(benefit.id) do
      {:done, benefit}
    else
      {:schemaless_error, changeset} ->
        {:schemaless_error, changeset}

      {:error, changeset} ->
        {:error, changeset}

      {:draft} ->
        {:draft}
    end
  end

  defp validate_riders_coverage("PEME", params) do
    with {:ok, changeset} <- params |> validate_peme_changeset(),
         {:ok, benefit} <- insert_benefit(changeset.changes),
         {:ok, benefit_coverage} <-
           insert_benefit_coverage(benefit.id, changeset.changes.coverage_ids),
         {:ok} <- insert_benefit_packages_acu(benefit.id, changeset.changes[:acu_package_ids]),
         %Benefit{} = benefit <- get_benefit(benefit.id) do
      {:done, benefit}
    else
      {:schemaless_error, changeset} ->
        {:schemaless_error, changeset}

      {:error, changeset} ->
        {:error, changeset}

      {:draft} ->
        {:draft}
    end
  end

  defp validate_riders_coverage("PEME", params, "Availment") do
    with {:ok, changeset} <- params |> validate_peme_changeset(),
         {:ok, benefit} <- insert_benefit(changeset.changes),
         {:ok, benefit_coverage} <-
           insert_benefit_coverage(benefit.id, changeset.changes.coverage_ids),
         {:ok} <- insert_benefit_packages_acu(benefit.id, changeset.changes[:acu_package_ids]),
         %Benefit{} = benefit <- get_benefit(benefit.id) do
      {:done, benefit}
    else
      {:schemaless_error, changeset} ->
        {:schemaless_error, changeset}

      {:error, changeset} ->
        {:error, changeset}

      {:draft} ->
        {:draft}
    end
  end

  defp validate_riders_coverage("MTRNTY", params) do
    with {:ok, changeset} <- params |> validate_maternity_changeset(),
         {:ok, benefit} <- insert_benefit(changeset.changes),
         {:ok, benefit_coverage} <-
           insert_benefit_coverage(benefit.id, changeset.changes.coverage_ids),
         {:ok, procedures} <- insert_benefit_procedures(benefit.id, changeset.changes.procedure_ids),
         {:ok, bd} <- insert_benefit_diagnosis(benefit.id, changeset.changes.diagnosis_ids),
         {:ok, limits} <- insert_benefit_limit2(benefit.id, changeset.changes.limits, params["created_by_id"]),
         {:ok} <- insert_benefit_packages(benefit.id, changeset),
         %Benefit{} = benefit <- get_benefit(benefit.id) do
      {:done, benefit}
    else
      {:schemaless_error, changeset} ->
        {:schemaless_error, changeset}

      {:error, changeset} ->
        {:error, changeset}

      {:draft} ->
        {:draft}
    end
  end

  defp validate_riders_coverage("MTRNTY", params, "Availment") do
    with {:ok, changeset} <- params |> validate_maternity_changeset(),
         {:ok, benefit} <- insert_benefit(changeset.changes),
         {:ok, benefit_coverage} <-
           insert_benefit_coverage(benefit.id, changeset.changes.coverage_ids),
         {:ok, procedures} <- insert_benefit_procedures(benefit.id, changeset.changes.procedure_ids),
         {:ok, bd} <- insert_benefit_diagnosis(benefit.id, changeset.changes.diagnosis_ids),
         {:ok, limits} <- insert_benefit_limit2(benefit.id, changeset.changes.limits, params["created_by_id"]),
         {:ok} <- insert_benefit_packages(benefit.id, changeset),
         %Benefit{} = benefit <- get_benefit(benefit.id) do
      {:done, benefit}
    else
      {:schemaless_error, changeset} ->
        {:schemaless_error, changeset}

      {:error, changeset} ->
        {:error, changeset}

      {:draft} ->
        {:draft}
    end
  end

  defp validate_riders_coverage("DENTL", params, "Availment") do
    with {:ok, changeset} <- params |> validate_dental_changeset(),
         {:ok, benefit} <- insert_dental_benefit(changeset.changes),
         {:ok, benefit_coverage} <-
           insert_benefit_coverage(benefit.id, changeset.changes.coverage_ids),
         {:ok, bd} <- insert_benefit_diagnosis(benefit.id, changeset.changes.diagnosis_ids),
         {:ok} <- insert_benefit_limit_dental(benefit.id, params["created_by_id"], params, params["limit_type"]),
         %Benefit{} = benefit <- get_benefit(benefit.id) do

           {:done, benefit}
    else
      {:schemaless_error, changeset} ->
        {:schemaless_error, changeset}

      {:error, changeset} ->
        {:error, changeset}

      {:draft} ->
        {:draft}
         end
  end

  defp validate_riders_coverage(code, params) do
    with {:ok, changeset} <- params |> validate_default_rider_changeset(),
         {:ok, benefit} <- insert_benefit(changeset.changes),
         {:ok, benefit_coverage} <-
           insert_benefit_coverage(benefit.id, changeset.changes.coverage_ids),
         {:ok, procedures} <- insert_benefit_procedures(benefit.id, changeset.changes.procedure_ids),
         {:ok, bd} <- insert_benefit_diagnosis_optional(benefit.id, changeset),
         {:ok, limits} <- insert_benefit_limit2(benefit.id, changeset.changes.limits, params["created_by_id"]),
         {:ok} <- insert_benefit_packages(benefit.id, changeset),
         %Benefit{} = benefit <- get_benefit(benefit.id) do
      {:done, benefit}
    else
      {:schemaless_error, changeset} ->
        {:schemaless_error, changeset}

      {:error, changeset} ->
        {:error, changeset}

      {:draft} ->
        {:draft}

      {:limit_type_error} ->
        {:limit_type_error}

    end
  end

  defp validate_riders_coverage(code, params, "Availment") do
    with {:ok, changeset} <- params |> validate_default_rider_changeset(),
         {:ok, benefit} <- insert_benefit(changeset.changes),
         {:ok, benefit_coverage} <-
           insert_benefit_coverage(benefit.id, changeset.changes.coverage_ids),
         {:ok, procedures} <- insert_benefit_procedures(benefit.id, changeset.changes.procedure_ids),
         {:ok, bd} <- insert_benefit_diagnosis_optional(benefit.id, changeset),
         {:ok, limits} <- insert_benefit_limit2(benefit.id, changeset.changes.limits, params["created_by_id"]),
         {:ok} <- insert_benefit_packages(benefit.id, changeset),
         %Benefit{} = benefit <- get_benefit(benefit.id) do
      {:done, benefit}
    else
      {:schemaless_error, changeset} ->
        {:schemaless_error, changeset}

      {:error, changeset} ->
        {:error, changeset}

      {:draft} ->
        {:draft}

      {:limit_type_error} ->
        {:limit_type_error}

    end
  end

  defp convert_string_to_boolean(string)
  when string == "true" or string == "false"
  do
    if string == "true", do: true, else: false
  end
  defp convert_string_to_boolean(string), do: nil

  defp check_peme_draft(params, "true"), do: params

  defp check_peme_draft(params, "") do
    params
    |> validate_required(
      [
        :name,
        :code,
        :coverage_ids,
        :category,
        :acu_package_ids,
        #############
        :updated_by_id,
        :created_by_id
      ],
      message: "is required"
    )
  end

  defp validate_peme_changeset(params) do
    reimbursement = convert_string_to_boolean(params["reimbursement"])
    loa_facilitated = convert_string_to_boolean(params["loa_facilitated"])
    params
      params
      |> Map.replace("loa_facilitated", loa_facilitated)
      |> Map.replace("reimbursement", reimbursement)

    types = %{
      name: :string,
      code: :string,
      coverage_ids: :string,
      category: :string,
      acu_package_ids: :string,
      updated_by_id: :binary_id,
      created_by_id: :binary_id,
      step: :integer,
      loa_facilitated: :boolean,
      reimbursement: :boolean,
      type: :string,
    }

    changeset =
      {%{}, types}
      |> cast(params, Map.keys(types))
      |> check_peme_draft(params["is_draft"])

    if changeset.valid? do
      {:ok, changeset}
    else
      {:schemaless_error, changeset}
    end
  end

  defp check_acu_draft(params, "true"), do: params

  defp check_acu_draft(params, "") do
    params
    |> validate_required(
      [
        :name,
        :code,
        :coverage_ids,
        :category,
        #############
        :acu_type,
        :acu_coverage,
        :provider_access,
        #############
        :limits,
        :acu_package_ids,
        #############
        :updated_by_id,
        :created_by_id
      ],
      message: "is required"
    )
  end
  defp check_acu_draft_policy(params, "true"), do: params

  defp check_acu_draft_policy(params, "") do
    params
    |> validate_required(
      [
        :name,
        :code,
        :category,
        #############
        #############
        #############
        :updated_by_id,
        :created_by_id
      ],
      message: "is required"
    )
  end

  defp check_acu_update_draft_policy(params, "true"), do: params

  defp check_acu_update_draft_policy(params, "") do
    params
    |> validate_required(
      [
        :name,
        :code,
        :category,
        #############
        #############
        #############
        :updated_by_id,
        # :created_by_id
      ],
      message: "is required"
    )
  end

  defp validate_acu_changeset(params) do
    reimbursement = convert_string_to_boolean(params["reimbursement"])
    loa_facilitated = convert_string_to_boolean(params["loa_facilitated"])
    params
      params
      |> Map.replace("loa_facilitated", loa_facilitated)
      |> Map.replace("reimbursement", reimbursement)

    types = %{
      type: :string,
      name: :string,
      code: :string,
      loa_facilitated: :boolean,
      reimbursement: :boolean,
      coverage_ids: :string,
      category: :string,
      acu_type: :string,
      acu_coverage: :string,
      provider_access: :string,
      limits: {:array, :string},
      acu_package_ids: :string,
      updated_by_id: :binary_id,
      created_by_id: :binary_id,
      step: :integer
    }

    changeset =
      {%{}, types}
      |> cast(params, Map.keys(types))
      |> check_acu_draft(params["is_draft"])

    if changeset.valid? do
      {:ok, changeset}
    else
      {:schemaless_error, changeset}
    end
  end

  defp validate_acu_update_changeset_policy(params) do
    types = %{
      code: :string,
      type: :string,
      name: :string,
      coverage_ids: :string,
      category: :string,
      acu_package_ids: :string,
      updated_by_id: :binary_id,
      created_by_id: :binary_id,
      step: :integer
    }

    changeset =
      {%{}, types}
      |> cast(params, Map.keys(types))
      |> check_acu_update_draft_policy(params["is_draft"])

    if changeset.valid? do
     {:ok, changeset}
    else
      {:schemaless_error, changeset}
    end
  end

  defp validate_acu_changeset_policy(params) do
    types = %{
      type: :string,
      name: :string,
      code: :string,
      coverage_ids: :string,
      category: :string,
      acu_package_ids: :string,
      updated_by_id: :binary_id,
      created_by_id: :binary_id,
      step: :integer
    }

    changeset =
      {%{}, types}
      |> cast(params, Map.keys(types))
      |> check_acu_draft_policy(params["is_draft"])

    if changeset.valid? do
      {:ok, changeset}
    else
      {:schemaless_error, changeset}
    end
  end

  defp check_maternity_draft(params, "true"), do: params

  defp check_maternity_draft(params, "") do
    params
    |> validate_required(
      [
        :name,
        :code,
        :coverage_ids,
        :category,
        #############
        :waiting_period,
        :maternity_type,
        :covered_enrollees,
        #############
        :limits,
        :diagnosis_ids,
        :procedure_ids,
        #############
        :updated_by_id,
        :created_by_id
      ],
      message: "is required"
    )
  end

  defp validate_maternity_changeset(params) do
    reimbursement = convert_string_to_boolean(params["reimbursement"])
    loa_facilitated = convert_string_to_boolean(params["loa_facilitated"])
    params
      params
      |> Map.replace("loa_facilitated", loa_facilitated)
      |> Map.replace("reimbursement", reimbursement)

    types = %{
      name: :string,
      classification: :string,
      loa_facilitated: :boolean,
      reimbursement: :boolean,
      code: :string,
      coverage_ids: :string,
      category: :string,
      waiting_period: :string,
      maternity_type: :string,
      covered_enrollees: :string,
      diagnosis_ids: {:array, :string},
      procedure_ids: {:array, :string},
      limits: {:array, :string},
      package_ids: :string,
      updated_by_id: :binary_id,
      created_by_id: :binary_id,
      type: :string,
      step: :integer
    }

    changeset =
      {%{}, types}
      |> cast(params, Map.keys(types))
      |> check_maternity_draft(params["is_draft"])

    if changeset.valid? do
      {:ok, changeset}
    else
      {:schemaless_error, changeset}
    end
  end

  defp check_default_rider_draft(params, "true"), do: params

  defp check_default_rider_draft(params, "") do
    params
    |> validate_required(
      [
        :name,
        :code,
        :coverage_ids,
        :category,
        #############
        :limits,
        :procedure_ids,
        #############
        :updated_by_id,
        :created_by_id
      ],
      message: "is required"
    )
  end

  defp validate_default_rider_changeset(params) do
    reimbursement = convert_string_to_boolean(params["reimbursement"])
    loa_facilitated = convert_string_to_boolean(params["loa_facilitated"])
    params
      params
      |> Map.replace("loa_facilitated", loa_facilitated)
      |> Map.replace("reimbursement", reimbursement)
    types = %{
      name: :string,
      code: :string,
      coverage_ids: :string,
      category: :string,
      limits: {:array, :string},
      package_ids: :string,
      updated_by_id: :binary_id,
      created_by_id: :binary_id,
      step: :integer,
      type: :string,
      classification: :string,
      loa_facilitated: :boolean,
      reimbursement: :boolean,
    }

    changeset =
      {%{}, types}
      |> cast(params, Map.keys(types))
      |> check_default_rider_draft(params["is_draft"])

    if changeset.valid? do
      {:ok, changeset}
    else
      {:schemaless_error, changeset}
    end
  end

  defp validate_dental_changeset(params) do
    reimbursement = convert_string_to_boolean(params["reimbursement"])
    loa_facilitated = convert_string_to_boolean(params["loa_facilitated"])
    # limit_amount = convert_string_to_integer(params["limit_amount"])
    # limit_session = convert_string_to_integer(params["limit_session"])

    params =
      params
      |> Map.replace("loa_facilitated", loa_facilitated)
      |> Map.replace("reimbursement", reimbursement)
      # |> Map.replace("limit_amount", limit_amount)
      # |> Map.replace("limit_session", limit_session)

    types = %{
      name: :string,
      code: :string,
      coverage_ids: :string,
      category: :string,
      updated_by_id: :binary_id,
      created_by_id: :binary_id,
      step: :integer,
      type: :string,
      loa_facilitated: :boolean,
      reimbursement: :boolean,
      frequency: :string,
      diagnosis_ids: {:array, :string},
      # limit_type: :string
    }

    changeset =
      {%{}, types}
      |> cast(params, Map.keys(types))
      |> check_default_dental_draft(params["is_draft"])

    if changeset.valid? do
      {:ok, changeset}
    else
      {:schemaless_error, changeset}
    end
  end

  defp check_default_dental_draft(params, "") do
    params
    |> validate_required(
      [
        :name,
        :code,
        :coverage_ids,
        :category,
        #############
        :updated_by_id,
        :created_by_id
      ],
      message: "is required"
    )
  end

  defp update_benefit_policy(benefit, benefit_params) do
    benefit_params =
      benefit_params
      |> Map.put(:acu_type, nil)
      |> Map.put(:provider_access, nil)
      |> Map.put(:covered_enrollees, nil)
      |> Map.put(:waiting_period, nil)
      |> Map.put(:acu_coverage, nil)
      |> Map.put(:maternity_type, nil)

    benefit
    |> Benefit.changeset_acu_update_policy(benefit_params)
    |> Repo.update()
  end

  defp insert_benefit_policy(params) do
    %Benefit{}
    |> Benefit.changeset_acu_policy(params)
    |> Repo.insert()
  end

  defp insert_benefit(params) do
    %Benefit{}
    |> Benefit.new_changeset_riders(params)
    |> Repo.insert()
  end

  defp insert_dental_benefit(params) do
    %Benefit{}
    |> Benefit.changeset_dental(params)
    |> Repo.insert()
  end

  defp insert_benefit_coverage(benefit_id, coverage_id) when is_nil(coverage_id), do: {:draft}

  defp insert_benefit_coverage(benefit_id, coverage_id) do
    %BenefitCoverage{}
    |> BenefitCoverage.changeset(%{benefit_id: benefit_id, coverage_id: coverage_id})
    |> Repo.insert()
  end

  @docp """
  Sample limits parameter
      limits: ["6990f184-4092-4fa0-b580-647f34011fdc&Session&1&1111&Per Coverage Period"]
      splitted: ["6990f184-4092-4fa0-b580-647f34011fdc", "Session", "1", "1111", "Per Coverage Period"]
  """
  defp insert_benefit_limit_acu(benefit_id, limits, user_id) when is_nil(limits), do: {:draft}

  defp insert_benefit_limit_acu(benefit_id, limits, user_id) do
    limits =
      limits
      |> Enum.map(fn x ->
        limit_params =
          x |> String.split("&")

          if Enum.count(limit_params) != 1 do
            {coverage_id, limit_type, limit_session, limit_amt, limit_class} =
              x |> String.split("&") |> List.to_tuple()

              limit_amt =
                limit_amt
                |> String.split(",")
                |> Enum.join("")

                params = %{
                  benefit_id: benefit_id,
                  coverages: CoverageContext.repo_get_coverage_by_id(coverage_id).name,
                  limit_type: limit_type,
                  limit_amount: limit_amt,
                  limit_session: limit_session,
                  limit_classification: limit_class,
                  created_by_id: user_id,
                  updated_by_id: user_id
                }

                %BenefitLimit{}
                |> BenefitLimit.changeset(params)
                |> Repo.insert()
          end
      end)

    {:ok, limits}
  end

  defp insert_benefit_limit2(benefit_id, limits, user_id) when is_nil(limits), do: {:ok, ""}

  defp insert_benefit_limit2(benefit_id, limits, user_id) do
    limits =
      limits
      |> Enum.map(fn x ->
        limit_params =
          x |> String.split("&")

          if Enum.count(limit_params) != 1 do
            {coverage_id, limit_type, limit_value, limit_class} =
              limit_params
              |> List.to_tuple()

              limit_value =
                limit_value
                |> String.split(",")
                |> Enum.join()
                |> String.split(" PHP")
                |> Enum.join()
                |> String.split(" %")
                |> Enum.join()
                |> String.split(" Tooth")
                |> Enum.join()
                |> String.split(" Quadrant")
                |> Enum.join()

                separate_cond_do2(%{
                  benefit_id: benefit_id,
                  coverage_id: coverage_id,
                  limit_type: limit_type,
                  limit_value: limit_value,
                  limit_class: limit_class,
                  user_id: user_id
                })
          end
      end)

    {:ok, limits}
  end

  def separate_cond_do2(%{benefit_id: benefit_id, coverage_id: coverage_id, limit_type: limit_type, limit_value: limit_value, limit_class: limit_class, user_id: user_id}) do
    cond do
      limit_type == "Peso" ->
        params = %{
          benefit_id: benefit_id,
          coverages: CoverageContext.repo_get_coverage_by_id(coverage_id).name,
          limit_type: limit_type,
          limit_amount: limit_value,
          limit_classification: limit_class
        }

      limit_type == "Plan Limit Percentage" ->
        params = %{
          benefit_id: benefit_id,
          coverages: CoverageContext.repo_get_coverage_by_id(coverage_id).name,
          limit_type: limit_type,
          limit_percentage: limit_value,
          limit_classification: limit_class
        }

      limit_type == "Sessions" ->
        params = %{
          benefit_id: benefit_id,
          coverages: CoverageContext.repo_get_coverage_by_id(coverage_id).name,
          limit_type: limit_type,
          limit_session: limit_value,
          limit_classification: limit_class
        }

      limit_type == "Tooth" ->
        params = %{
          benefit_id: benefit_id,
          coverages: CoverageContext.repo_get_coverage_by_id(coverage_id).name,
          limit_type: limit_type,
          limit_tooth: limit_value,
          limit_classification: limit_class
        }

        limit_type == "Quadrant" ->
        params = %{
          benefit_id: benefit_id,
          coverages: CoverageContext.repo_get_coverage_by_id(coverage_id).name,
          limit_type: limit_type,
          limit_quadrant: limit_value,
          limit_classification: limit_class
        }

        true ->
        {:limit_type_error}
    end

    params =
      params
      |> Map.merge(%{
        created_by_id: user_id,
        updated_by_id: user_id
      })

    %BenefitLimit{}
    |> BenefitLimit.changeset(params)
    |> Repo.insert()

  end

  defp insert_benefit_limit3(benefit_id, limits, user_id) when is_nil(limits), do: {:ok, ""}

  defp insert_benefit_limit3(benefit_id, limits, user_id) do
    limits =
      limits
      |> Enum.map(fn x ->
        limit_params =
          x |> String.split("&")

          if Enum.count(limit_params) != 1 do
            {coverage_id, limit_type, limit_value, limit_class} =
              limit_params
              |> List.to_tuple()

              limit_value =
                limit_value
                |> String.split(",")
                |> Enum.join()
                |> String.split(" PHP")
                |> Enum.join()
                |> String.split(" %")
                |> Enum.join()
                |> String.split(" Tooth")
                |> Enum.join()
                |> String.split(" Quadrant")
                |> Enum.join()

              coverage_ids = CoverageContext.get_coverage_id_by_name(coverage_id)

              separate_cond_do(%{
                limit_type: limit_type,
                coverage_ids: coverage_ids,
                benefit_id: benefit_id,
                limit_value: limit_value,
                limit_class: limit_class,
                user_id: user_id
              })

          end
      end)

    {:ok, limits}
  end

  defp separate_cond_do(%{limit_type: limit_type, coverage_ids: coverage_ids, benefit_id: benefit_id, limit_value: limit_value, limit_class: limit_class, user_id: user_id}) do
    cond do
      limit_type == "Peso" ->
        params = %{
          benefit_id: benefit_id,
          coverages: get_coverage_name(CoverageContext.repo_get_coverage_by_id(coverage_ids)),
          limit_type: limit_type,
          limit_amount: limit_value,
          limit_classification: limit_class
        }

      limit_type == "Plan Limit Percentage" ->
        params = %{
          benefit_id: benefit_id,
          coverages: get_coverage_name(CoverageContext.repo_get_coverage_by_id(coverage_ids)),
          limit_type: limit_type,
          limit_percentage: limit_value,
          limit_classification: limit_class
        }

      limit_type == "Sessions" ->
        params = %{
          benefit_id: benefit_id,
          coverages: get_coverage_name(CoverageContext.repo_get_coverage_by_id(coverage_ids)),
          limit_type: limit_type,
          limit_session: limit_value,
          limit_classification: limit_class
        }
      limit_type == "Tooth" ->
        params = %{
          benefit_id: benefit_id,
          coverages: get_coverage_name(CoverageContext.repo_get_coverage_by_id(coverage_ids)),
          limit_type: limit_type,
          limit_tooth: limit_value,
          limit_classification: limit_class
        }

        limit_type == "Quadrant" ->
        params = %{
          benefit_id: benefit_id,
          coverages: get_coverage_name(CoverageContext.repo_get_coverage_by_id(coverage_ids)),
          limit_type: limit_type,
          limit_quadrant: limit_value,
          limit_classification: limit_class
        }

        true ->
        {:limit_type_error}
    end

    params =
      params
      |> Map.merge(%{
        created_by_id: user_id,
        updated_by_id: user_id
      })

    %BenefitLimit{}
    |> BenefitLimit.changeset(params)
    |> Repo.insert()

  end

  defp insert_benefit_limit_dental(benefit_id, user_id, params, "Peso") do

    limit_amount = params["limit_amount"]
    limit_amount =
      limit_amount
      |> String.split(",")
      |> Enum.join()

    limit_amount = convert_string_to_decimal(limit_amount)
    limit_amount =
      limit_amount
      |> elem(0)

    params =
      params
      |> Map.replace("limit_amount", limit_amount)

    params = %{
      benefit_id: benefit_id,
      coverages: get_coverage_name(CoverageContext.repo_get_coverage_by_id(params["coverage_ids"])),
      limit_type: "Peso",
      limit_amount: limit_amount,
    }

    params =
      params
      |> Map.merge(%{
        created_by_id: user_id,
        updated_by_id: user_id,
      })

    %BenefitLimit{}
    |> BenefitLimit.changeset(params)
    |> Repo.insert()

    {:ok}

  end

  defp insert_benefit_limit_dental(benefit_id, user_id, params, "Session") do
    limit_session = params["limit_session"]
    limit_session =
      limit_session
      |> convert_string_to_integer()

    params = %{
      benefit_id: benefit_id,
      coverages: get_coverage_name(CoverageContext.repo_get_coverage_by_id(params["coverage_ids"])),
      limit_type: "Session",
      limit_session: limit_session,
    }

    params =
      params
      |> Map.merge(%{
        created_by_id: user_id,
        updated_by_id: user_id,
      })

    %BenefitLimit{}
    |> BenefitLimit.changeset_sap_dental(params)
    |> Repo.insert()

    {:ok}
  end

  defp insert_benefit_limit_dental(benefit_id, user_id, params, "Tooth"), do: insert_benefit_limit_dental_tooth(benefit_id, user_id, params, "Tooth", params["limit_tooth"])

  defp insert_benefit_limit_dental_tooth(benefit_id, user_id, params, "Tooth", "Session") do
    limit_session = params["tooth_limit_session"]
    limit_session =
      limit_session
      |> convert_string_to_integer()

    params = %{
      benefit_id: benefit_id,
      coverages: get_coverage_name(CoverageContext.repo_get_coverage_by_id(params["coverage_ids"])),
      limit_type: "Tooth",
      limit_session: limit_session,
    }

    params =
      params
      |> Map.merge(%{
        created_by_id: user_id,
        updated_by_id: user_id,
      })

    %BenefitLimit{}
    |> BenefitLimit.changeset_sap_dental(params)
    |> Repo.insert()

    {:ok}
  end

 defp insert_benefit_limit_dental_tooth(benefit_id, user_id, params, "Tooth", "Peso") do

    limit_amount = params["tooth_limit_amount"]
    limit_amount =
      limit_amount
      |> String.split(",")
      |> Enum.join()

    limit_amount = convert_string_to_decimal(limit_amount)
    limit_amount =
      limit_amount
      |> elem(0)

    params =
      params
      |> Map.replace("limit_amount", limit_amount)

    params = %{
      benefit_id: benefit_id,
      coverages: get_coverage_name(CoverageContext.repo_get_coverage_by_id(params["coverage_ids"])),
      limit_type: "Tooth",
      limit_amount: limit_amount
    }

    params =
      params
      |> Map.merge(%{
        created_by_id: user_id,
        updated_by_id: user_id
      })

    %BenefitLimit{}
    |> BenefitLimit.changeset_sap_dental(params)
    |> Repo.insert()

    {:ok}
  end

  defp insert_benefit_limit_dental(benefit_id, user_id, params, "Area") do
    limit_area_type = params["limit_area_type"]
    limit_area = params["limit_area"]

    params = %{
      benefit_id: benefit_id,
      coverages: get_coverage_name(CoverageContext.repo_get_coverage_by_id(params["coverage_ids"])),
      limit_type: "Area",
      limit_area_type: limit_area_type,
      limit_area: limit_area
    }

    params =
      params
      |> Map.merge(%{
        created_by_id: user_id,
        updated_by_id: user_id
      })

    %BenefitLimit{}
    |> BenefitLimit.changeset_sap_dental(params)
    |> Repo.insert()

    {:ok}

  end

  defp get_coverage_name(nil), do: nil
  defp get_coverage_name(cov), do: cov.name

  defp insert_benefit_packages_acu(benefit_id, acu_package_ids) when is_nil(acu_package_ids),
    do: {:draft}

  defp insert_benefit_packages_acu(benefit_id, acu_package_ids) do
    acu_package_ids
    |> String.split(",")
    |> Enum.each(fn x ->
      result = package_checker(benefit_id, x)

      distincted_ppp =
        PackageContext.get_package(x).package_payor_procedure
        |> Enum.map(fn x -> package_pp_details(x) end)
        |> ppp_gender_age_cloning()

      if result == true do
        %BenefitPackage{}
        |> BenefitPackage.changeset(%{
          benefit_id: benefit_id,
          package_id: x,
          age_from: distincted_ppp.age_from,
          age_to: distincted_ppp.age_to,
          male: distincted_ppp.male,
          female: distincted_ppp.female
        })
        |> Repo.insert!()
      end
    end)

    {:ok}
  end

  defp insert_benefit_packages(benefit_id, changeset) do
    if Map.has_key?(changeset.changes, :package_ids) do
      changeset.changes.package_ids
      |> String.split(",")
      |> Enum.each(fn x ->
        result = package_checker(benefit_id, x)

        distincted_ppp =
          PackageContext.get_package(x).package_payor_procedure
          |> Enum.map(fn x -> package_pp_details(x) end)
          |> ppp_gender_age_cloning()

        if result == true do
          %BenefitPackage{}
          |> BenefitPackage.changeset(%{
            benefit_id: benefit_id,
            package_id: x,
            age_from: distincted_ppp.age_from,
            age_to: distincted_ppp.age_to,
            male: distincted_ppp.male,
            female: distincted_ppp.female
          })
          |> Repo.insert!()
        end
      end)

      {:ok}
    else
      ### if they did not pick any of the packages
      {:ok}
    end
  end

  defp insert_benefit_procedures(benefit_id, procedure_ids) when is_nil(procedure_ids), do: {:ok, ""}
  defp insert_benefit_procedures(benefit_id, []), do: {:ok, ""}
  defp insert_benefit_procedures(benefit_id, procedure_ids) do
    procedures =
      procedure_ids
      |> Enum.map(fn x ->
        params = %{benefit_id: benefit_id, procedure_id: x}

        %BenefitProcedure{}
        |> BenefitProcedure.changeset(params)
        |> Repo.insert()
      end)

    {:ok, procedures}
  end

  defp insert_benefit_diagnosis(benefit_id, diagnosis_ids) when is_nil(diagnosis_ids), do: {:ok, ""}
  defp insert_benefit_diagnosis(benefit_id, []), do: {:ok, ""}

  defp insert_benefit_diagnosis(benefit_id, diagnosis_ids) do
    bd =
      diagnosis_ids
      |> Enum.map(fn y ->
        params = %{benefit_id: benefit_id, diagnosis_id: y}

        %BenefitDiagnosis{}
        |> BenefitDiagnosis.changeset(params)
        |> Repo.insert()
      end)
    {:ok, bd}
  end

  defp insert_benefit_diagnosis_optional(benefit_id, changeset) do
    if Map.has_key?(changeset.changes, :diagnosis_ids) do
      changeset.changes.diagnosis_ids
      |> Enum.map(fn y ->
        params = %{benefit_id: benefit_id, diagnosis_id: y}

        %BenefitDiagnosis{}
        |> BenefitDiagnosis.changeset(params)
        |> Repo.insert()
      end)

      {:ok}
    else
      {:ok}
    end
  end

  ################################ end: Refactoring Benefit / SinglePageApp approach ###################################
  def trigger_benefit_disabling_date do
    benefit_dates =
      Benefit
      |> where([b], not is_nil(b.disabled_date))
      |> select([b], [b.disabled_date, b.id])
      |> Repo.all()

    for benefit_date <- benefit_dates do
      {:ok, date} = Date.from_erl(Ecto.Date.to_erl(Enum.at(benefit_date, 0)))
      compared_date = Date.compare(date, Date.utc_today())

      if compared_date == :eq or compared_date == :lt do
        id = Enum.at(benefit_date, 1)
        disabling_benefit(id)
      end

      # if date = Date.utc_today()
    end
  end

  def trigger_benefit_discontinue_date do
    benefit_dates =
      Benefit
      |> where([b], not is_nil(b.discontinue_date))
      |> select([b], [b.discontinue_date, b.id])
      |> Repo.all()

    for benefit_date <- benefit_dates do
      {:ok, date} = Date.from_erl(Ecto.Date.to_erl(Enum.at(benefit_date, 0)))
      compared_date = Date.compare(date, Date.utc_today())

      if compared_date == :eq or compared_date == :lt do
        id = Enum.at(benefit_date, 1)
        discontinue_benefit(id)
      end

      # if date = Date.utc_today()
    end
  end

  ##### BENEFIT SHOW PAGE#######

  def get_benefit_packages_by_id(benefit) do
    benefit_package =
      Benefit
      |> join(:inner, [b], bp in BenefitPackage, b.id == bp.benefit_id)
      |> join(:inner, [b, bp], p in Package, bp.package_id == p.id)
      |> where([b, bp, p], b.id == ^benefit.id)
      |> select([b, bp, p], %{
        id: b.id,
        package_id: p.id,
        package_code: p.code,
        package_name: p.name,
        gender: [bp.male, bp.female],
        age_from: bp.age_from,
        age_to: bp.age_to
      })
      |> Repo.all()

    benefit
    |> Map.put(:benefit_package, benefit_package)
  end

  def get_benefits_by_id(id) do
    Benefit
    |> join(:left, [b], u in User, u.id == b.updated_by_id)
    |> where([b, u], b.id == ^id)
    |> select([b, u], %{
      id: b.id,
      name: b.name,
      code: b.code,
      category: b.category,
      delete_date: b.delete_date,
      discontinue_date: b.discontinue_date,
      disabled_date: b.disabled_date,
      # coverage_id: b.coverage_id,
      # coverage_ids: b.coverage_ids,
      acu_type: b.acu_type,
      loa_facilitated: b.loa_facilitated,
      reimbursement: b.reimbursement,
      provider_access: b.provider_access,
      step: b.step,
      peme: b.peme,
      all_diagnosis: b.all_diagnosis,
      all_procedure: b.all_procedure,
      updated_by_id: b.updated_by_id,
      classification: b.classification,
      updated_at: b.updated_at,
      status: b.status,
      updated_by: u.username,
      type: b.type,
    })
    |> Repo.one()
    |> get_benefit_packages_by_id()
    |> get_benefit_coverages!()
    |> get_benefit_limit_by_id()
    |> get_benefit_procedures_new()
    |> get_benefit_procedures_new()
    |> load_benefit_ruv!()
    |> load_benefit_diagnosis()
    |> load_product_benefit()
  end

  def get_benefit_by_id(id) do
    Benefit
    |> Repo.get(id)
  end

  def get_benefit_limit_by_id(benefit) do
    benefit_limit =
      Benefit
      |> join(:inner, [b], bl in BenefitLimit, b.id == bl.benefit_id)
      |> where([b, bl], b.id == ^benefit.id)
      |> select([b, bl], %{
        id: b.id,
        coverages: bl.coverages,
        limit_type: bl.limit_type,
        limit_amount: bl.limit_amount,
        limit_session: bl.limit_session,
        limit_percentage: bl.limit_percentage,
        limit_tooth: bl.limit_tooth,
        limit_quadrant: bl.limit_quadrant,
        limit_classification: bl.limit_classification
      })
      |> Repo.all()

    benefit
    |> Map.put(:benefit_limit, benefit_limit)
  end

  def get_benefit_coverages!(benefit) do
    benefit_coverage =
      Benefit
      |> join(:inner, [b], cb in BenefitCoverage, b.id == cb.benefit_id)
      |> join(:inner, [b, cb], c in Coverage, cb.coverage_id == c.id)
      |> where([b, cb, c], b.id == ^benefit.id)
      |> select([b, cb, c], %{
        coverage_name: c.name,
        coverage_description: c.description,
        coverage_id: c.id,
        coverage_plan_type: c.plan_type
      })
      |> Repo.all()

    benefit
    |> Map.put(:benefit_coverages, benefit_coverage)
  end

  def load_benefit_ruv!(benefit) do
    benefit_ruv =
      RUV
      |> join(:inner, [r], br in BenefitRUV, r.id == br.ruv_id)
      |> join(:inner, [r, br], b in Benefit, br.benefit_id == b.id)
      |> where([r, br, b], b.id == ^benefit.id)
      |> select([r, br, b], %{
        ruv_code: r.code,
        ruv_type: r.type,
        ruv_value: r.value,
        ruv_description: r.description,
        ruv_effectivity_date: r.effectivity_date
      })
      |> Repo.all()

    benefit
    |> Map.put(:benefit_ruv, benefit_ruv)
  end

  def get_benefit_procedures_new(benefit) do
    benefit_procedures =
      BenefitProcedure
      |> join(:left, [bp], pckg in Package, bp.package_id == pckg.id)
      |> join(:left, [bp, pckg], ppp in PackagePayorProcedure, ppp.package_id == pckg.id)
      |> join(:left, [bp, pckg, ppp], pp in PayorProcedure, bp.procedure_id == pp.id)
      |> join(:left, [bp, pckg, ppp, pp], sp in Procedure, pp.procedure_id == sp.id)
      |> join(
        :left,
        [bp, pckg, ppp, pp, sp],
        pc in ProcedureCategory,
        sp.procedure_category_id == pc.id
      )
      |> where([bp], bp.benefit_id == ^benefit.id)
      |> select([bp, pckg, ppp, pp, sp, pc], %{
        package_id: pckg.id,
        package_code: pckg.code,
        package_name: pckg.name,
        sp_code: sp.code,
        sp_id: sp.id,
        pp_id: pp.id,
        sp_description: sp.description,
        pp_code: pp.code,
        pp_description: pp.description,
        age_from: ppp.age_from,
        age_to: ppp.age_to,
        male: ppp.male,
        female: ppp.female,
        procedure_category: pc.name
      })
      |> Repo.all()

    benefit
    |> Map.put(:benefit_procedures, benefit_procedures)
  end

  def load_benefit_diagnosis(benefit) do
    benefit_diagnosis =
      Diagnosis
      |> join(:left, [d], bd in BenefitDiagnosis, bd.diagnosis_id == d.id)
      |> where([d, bd], bd.benefit_id == ^benefit.id)
      |> select([d, bd], %{
        diagnosis_code: d.code,
        diagnosis_type: d.type,
        diagnosis_desc: d.description
      })
      |> Repo.all()

    benefit
    |> Map.put(:benefit_diagnosis, benefit_diagnosis)
  end

  def load_product_benefit(benefit) do
    product_benefit =
      ProductBenefit
      |> where([pb], pb.benefit_id == ^benefit.id)
      |> Repo.all()

    benefit
    |> Map.put(:product_benefit, product_benefit)
  end

  def load_benefit_data(id) do
    BenefitCoverage
    |> where([bc], bc.benefit_id == ^id)
    |> join(:left, [bc], c in Coverage, bc.coverage_id == c.id)
    |> select([bc, c], c.code)
    |> Repo.all()
    |> serialize_data(id)
  end

  defp serialize_data(coverages, benefit_id) when is_list(coverages) do
    count = Enum.count(coverages)
    serialize_data(
      count,
      coverages,
      benefit_id
    )
  end

  defp serialize_data(count, coverages, benefit_id) do
    if count == 1 do
      # Single Coverage

      coverages
      |> List.first()
      |> serialize_data(benefit_id)

    else
      Benefit
      |> where([b], b.id == ^benefit_id)
      |> select([b], %{
        id: b.id,
        name: b.name,
        code: b.code,
        category: b.category,
        step: b.step,
        type: b.type
      })
      |> Repo.one()
      |> load_coverages()
      |> load_limit()
      |> load_diagnosis()
      |> load_packages()
      |> load_procedure()
    end
  end

  defp serialize_data(coverage, benefit_id) when is_bitstring(coverage) and coverage == "PEME" do
    Benefit
    |> where([b], b.id == ^benefit_id)
    |> select([b], %{
      id: b.id,
      name: b.name,
      code: b.code,
      category: b.category,
      step: b.step,
      type: b.type
    })
    |> Repo.one()
    |> load_coverages()
    |> load_packages()
    |> load_procedure()
  end

  defp serialize_data(coverage, benefit_id) when is_bitstring(coverage) and coverage == "ACU" do
    Benefit
    |> where([b], b.id == ^benefit_id)
    |> select([b], %{
      id: b.id,
      name: b.name,
      code: b.code,
      category: b.category,
      step: b.step,
      type: b.type,
      acu_type: b.acu_type,
      acu_coverage: b.acu_coverage,
      provider_access: b.provider_access
    })
    |> Repo.one()
    |> load_coverages()
    |> load_limit()
    |> load_packages()
    |> load_procedure()
  end

  defp serialize_data(coverage, benefit_id) when is_bitstring(coverage) and coverage == "MTRNTY" do
    Benefit
    |> where([b], b.id == ^benefit_id)
    |> select([b], %{
      id: b.id,
      step: b.step,
      name: b.name,
      code: b.code,
      type: b.type,
      maternity_type: b.maternity_type,
      covered_enrollees: b.covered_enrollees,
      waiting_period: b.waiting_period
    })
    |> Repo.one()
    |> load_coverages()
    |> load_limit()
    |> load_diagnosis()
    |> load_packages()
    |> load_procedure()
  end

  defp serialize_data(coverage, benefit_id) when is_bitstring(coverage) do
    Benefit
    |> where([b], b.id == ^benefit_id)
    |> select([b], %{
      id: b.id,
      step: b.step,
      type: b.type,
      name: b.name,
      code: b.code,
      provider_access: b.provider_access
    })
    |> Repo.one()
    |> load_coverages()
    |> load_limit()
    |> load_diagnosis()
    |> load_packages()
    |> load_procedure()
  end

  # defp serialize_data(count, coverages, benefit_id) when count > 1 do
  #   # Multiple Coverage

  #   Benefit
  #   |> where([b], b.id == ^benefit_id)
  #   |> select([b], %{
  #     id: b.id,
  #     name: b.name,
  #     code: b.code,
  #     category: b.category,
  #     step: b.step
  #   })
  #   |> Repo.one()
  #   |> load_coverages()
  #   |> load_limit()
  #   |> load_diagnosis()
  #   |> load_packages()
  #   |> load_procedure()
  # end

  defp load_coverages(benefit) do
    benefit_coverages =
      BenefitCoverage
      |> join(:left, [bc], c in Coverage, bc.coverage_id == c.id)
      |> where([bc], bc.benefit_id == ^benefit.id)
      |> select([bc, c], %{
        id: c.id,
        code: c.code,
        name: c.name
      })
      |> Repo.all()

    benefit
    |> Map.put(:coverages, benefit_coverages)
  end

  defp load_limit(benefit) do
    benefit_limit =
      BenefitLimit
      |> where([bl], bl.benefit_id == ^benefit.id)
      |> select([bl, c], %{
        id: bl.id,
        type: bl.limit_type,
        percentage: bl.limit_percentage,
        amount: bl.limit_amount,
        session: bl.limit_session,
        classification: bl.limit_classification,
        coverage_names: bl.coverages,
        tooth: bl.limit_tooth,
        quadrant: bl.limit_quadrant
      })
      |> Repo.all()

    benefit
    |> Map.put(:limits, benefit_limit)
  end

  defp load_diagnosis(benefit) do
    benefit_diagnosis =
      BenefitDiagnosis
      |> join(:left, [bd], d in Diagnosis, bd.diagnosis_id == d.id)
      |> where([bd], bd.benefit_id == ^benefit.id)
      |> select([bd, d], %{
        id: d.id,
        code: d.code,
        name: d.group_description,
        description: d.description,
        type: d.type
      })
      |> Repo.all()

    benefit
    |> Map.put(:diagnosis, benefit_diagnosis)
  end

  defp load_procedure(benefit) do
    benefit_procedures =
      BenefitProcedure
      |> join(:left, [bp], pp in PayorProcedure, bp.procedure_id == pp.id)
      |> join(:left, [bp, pp], sp in Procedure, pp.procedure_id == sp.id)
      |> select([bp, pp, sp], %{
        sp_id: sp.id,
        sp_code: sp.code,
        sp_description: sp.description,
        pp_id: pp.id,
        pp_code: pp.code,
        pp_description: pp.description
      })
      |> where([bp], bp.benefit_id == ^benefit.id)
      |> Repo.all()

    benefit
    |> Map.put(:procedures, benefit_procedures)
  end

  defp load_packages(benefit) do
    benefit_package =
      BenefitPackage
      |> join(:left, [bp], p in Package, bp.package_id == p.id)
      |> where([bp], bp.benefit_id == ^benefit.id)
      |> select([bp, p], %{
        id: p.id,
        code: p.code,
        name: p.name
      })
      |> Repo.all()

    benefit
    |> Map.put(:packages, benefit_package)
  end

  def create_benefit_healthplan(params) do
    with {:ok, benefit} <- create_benefit_health(params),
         {:ok, bc} <- insert_benefit_coverage_healthplan(benefit.id, params["coverage_ids"]),
         {:ok, limits} <- insert_benefit_limit2(benefit.id, params["limits"], params["created_by_id"]),
         {:ok, bd} <- insert_benefit_diagnosis(benefit.id, params["diagnosis_ids"]),
         {:ok} <- insert_benefit_packages_healthplan(benefit.id, params["package_ids"]),
         {:ok, procedures} <- insert_benefit_procedures(benefit.id, params["procedure_ids"])
    do
      {:ok, benefit}
    else
      _ ->
        {:error}
    end
  end

  defp insert_benefit_health(benefit_params) do
    %Benefit{}
    |> Benefit.new_changeset_health(benefit_params)
    |> Repo.insert()
  end

  defp insert_benefit_packages_healthplan(id, package_ids) do
    package_ids
    |> String.split(",")
    |> List.delete("")
    |> Enum.each(fn x ->
      result = package_checker(id, x)

      distincted_ppp =
        PackageContext.get_package(x).package_payor_procedure
        |> Enum.map(fn x -> package_pp_details(x) end)
        |> ppp_gender_age_cloning()

      if result == true do
        %BenefitPackage{}
        |> BenefitPackage.changeset(%{
          benefit_id: id,
          package_id: x,
          age_from: distincted_ppp.age_from,
          age_to: distincted_ppp.age_to,
          male: distincted_ppp.male,
          female: distincted_ppp.female
        })
        |> Repo.insert!()
      end
    end)

    {:ok}
  end

  defp insert_benefit_coverage_healthplan(id, coverage_ids) when is_bitstring(coverage_ids) do
    bc =
      %BenefitCoverage{}
      |> BenefitCoverage.changeset(%{benefit_id: id, coverage_id: coverage_ids})
      |> Repo.insert()

    {:ok, bc}
  end

  defp insert_benefit_coverage_healthplan(id, coverage_ids) do
    bc =
      coverage_ids
      |> Enum.map(&(
        %BenefitCoverage{}
        |> BenefitCoverage.changeset(%{benefit_id: id, coverage_id: &1})
        |> Repo.insert()
      ))

    {:ok, bc}
  end

  def update_benefit_record_v2(benefit, benefit_params, "Availment") do
    package_ids = with true <- not is_nil(benefit_params["package_ids"]) do
      benefit_params["package_ids"]
    else
      _ ->
        benefit_params["acu_package_ids"]
    end

    coverage_ids =
      benefit_params["coverage_ids"]
      |> String.split(",", trim: true)

    category =
      benefit_params["category"]
      |> String.downcase()

    benefit_policy = benefit_params["benefit_policy"]

    benefit_params =
      benefit_params
      |> Map.put("type", benefit_policy)

    is_acu = not is_nil(benefit_params["acu_coverage"])

    with {:ok, benefit} <- update_benefit(benefit, benefit_params, category),
         {:ok} <- delete_benefit_data(benefit),
         {:ok, bc} <- insert_benefit_coverage_healthplan(benefit.id, coverage_ids),
         {:ok, limits} <- insert_benefit_limit_by_coverage(
           benefit.id,
           benefit_params["limits"],
           is_acu, category,
           benefit_params["updated_by_id"]
         ),
         {:ok, bd} <- insert_benefit_diagnosis(benefit.id, benefit_params["diagnosis_ids"]),
         {:ok} <- insert_benefit_packages_healthplan(benefit.id, package_ids),
         {:ok, procedures} <- insert_benefit_procedures(benefit.id, benefit_params["procedure_ids"])
    do
      {:ok, benefit}

    else

      {:error, changeset} ->
        {:error, changeset}

      {:limit_type_error} ->
        {:limit_type_error}

    end
  end

  def update_benefit_record_v2(benefit, benefit_params, "Policy") do
    with {:ok, changeset} <- validate_acu_update_changeset_policy(benefit_params),
         {:ok, benefit} <- update_benefit_policy(benefit, changeset.changes),
         {:ok} <- delete_benefit_data_v2(benefit),
         %Benefit{} = benefit <- get_benefit(benefit.id) do
      {:ok, benefit}
    else
      {:schemaless_error, changeset} ->
        {:schemaless_error, changeset}

      {:error, changeset} ->
        {:error, changeset}

      # {:draft} ->
      #   {:draft}
    end
  end

  def update_benefit_record(benefit, benefit_params) do
    package_ids = with true <- not is_nil(benefit_params["package_ids"]) do
      benefit_params["package_ids"]
    else
      _ ->
        benefit_params["acu_package_ids"]
    end

    coverage_ids =
      benefit_params["coverage_ids"]
      |> String.split(",", trim: true)

    category =
      benefit_params["category"]
      |> String.downcase()

    is_acu = not is_nil(benefit_params["acu_coverage"])

    with {:ok, benefit} <- update_benefit(benefit, benefit_params, category),
         {:ok} <- delete_benefit_data(benefit),
         {:ok, bc} <- insert_benefit_coverage_healthplan(benefit.id, coverage_ids),
         {:ok, limits} <- insert_benefit_limit_by_coverage(
           benefit.id,
           benefit_params["limits"],
           is_acu, category,
           benefit_params["updated_by_id"]
         ),
         {:ok, bd} <- insert_benefit_diagnosis(benefit.id, benefit_params["diagnosis_ids"]),
         {:ok} <- insert_benefit_packages_healthplan(benefit.id, package_ids),
         {:ok, procedures} <- insert_benefit_procedures(benefit.id, benefit_params["procedure_ids"])
    do
      {:ok, benefit}

    else

      {:error, changeset} ->
        {:error, changeset}

      {:limit_type_error} ->
        {:limit_type_error}

    end
  end

  defp insert_benefit_limit_by_coverage(id, limits, is_acu, category, user_id) when is_acu == true do
    insert_benefit_limit_acu(id, limits, user_id)
  end

  defp insert_benefit_limit_by_coverage(id, limits, is_acu, category, user_id) when is_acu == false do
    if category == "riders" do
      insert_benefit_limit2(id, limits, user_id)
    else
      insert_benefit_limit3(id, limits, user_id)
    end
  end

  defp delete_benefit_data_v2(benefit) do
    id = benefit.id

    BenefitLimit
    |> delete_records(id)

    BenefitDiagnosis
    |> delete_records(id)

    BenefitPackage
    |> delete_records(id)

    BenefitProcedure
    |> delete_records(id)

    {:ok}
  end

  defp delete_benefit_data(benefit) do
    id = benefit.id

    BenefitCoverage
    |> delete_records(id)

    BenefitLimit
    |> delete_records(id)

    BenefitDiagnosis
    |> delete_records(id)

    BenefitPackage
    |> delete_records(id)

    BenefitProcedure
    |> delete_records(id)

    {:ok}
  end

  defp delete_records(table, id) do
    table
    |> where([t], t.benefit_id == ^id)
    |> Repo.delete_all()
  end

  defp update_benefit(benefit, benefit_params, category) when category == "health" do
    benefit_params =
      benefit_params
      |> Map.put(
        "coverage_ids",
        String.split(
          benefit_params["coverage_ids"]
        )
      )
    update_benefit_health(benefit, benefit_params)
  end

  defp update_benefit(benefit, benefit_params, category) when category == "riders" do
    update_benefit_new_riders(benefit, benefit_params)
  end

  def update_benefit_new_riders(benefit, benefit_params) do
    benefit
    |> Benefit.new_changeset_riders(benefit_params)
    |> Repo.update()
  end

  def check_code(code) do
    Benefit
    |> where([b], ilike(b.code, ^code))
    |> Repo.one
    |> check_code_duplication()
  end

  def check_code_duplication(benefit) when is_nil(benefit), do: true
  def check_code_duplication(benefit), do: false

  defp convert_string_to_boolean(string)
  when string == "true" or string == "false"
  do
    if string == "true", do: true, else: false
  end
  defp convert_string_to_boolean(string), do: nil

  defp convert_string_to_integer(nil), do: nil
  defp convert_string_to_integer(string), do: string |> String.to_integer()

  defp convert_string_to_decimal(nil), do: nil
  defp convert_string_to_decimal(string), do: string |> Float.parse()

  def get_benefit_dental_by_code_or_name(benefit, "", nil), do: get_benefit_dental_by_code_or_name(benefit, nil, nil)

  def get_benefit_dental_by_code_or_name(benefit, "0", nil), do: get_benefit_dental_by_code_or_name(benefit, nil, nil)

  def get_benefit_dental_by_code_or_name(benefit, nil, nil) do
    benefit_c_or_n = if is_nil(benefit), do: "", else: benefit
    Benefit
    |> join(:inner, [b], bc in BenefitCoverage, b.id == bc.benefit_id)
    |> join(:inner, [b, bc], c in Coverage, c.id == bc.coverage_id)
    # |> where([b, bc, c], b.code == ^benefit_c_or_n or b.name == ^benefit_c_or_n)
    |> where([b, bc, c], fragment("lower(?) = lower(?) or lower(?) = lower(?)", b.code, ^benefit_c_or_n, b.name, ^benefit_c_or_n))
    |> where([b, bc, c], c.code == "DENTL")
    |> limit(1)
    |> Repo.one()
    |> Repo.preload([
          :benefit_limits,
          benefit_procedures: [:procedure],
          benefit_coverages: [:coverage]
    ])
  end

  def get_benefit_dental_by_code_or_name(benefit, page_number, nil) do
    limit = String.to_integer("#{page_number}0")
    offset = limit - 10
    benefit_c_or_n = if is_nil(benefit), do: "", else: benefit
    Benefit
    |> join(:inner, [b], bc in BenefitCoverage, b.id == bc.benefit_id)
    |> join(:inner, [b, bc], c in Coverage, c.id == bc.coverage_id)
    |> where([b, bc, c], fragment("lower(?) = lower(?) or lower(?) = lower(?)", b.code, ^benefit_c_or_n, b.name, ^benefit_c_or_n))
    # |> where([b, bc, c], b.code == ^benefit_c_or_n or b.name == ^benefit_c_or_n)
    |> where([b, bc, c], c.code == "DENTL")
    # |> select([b, bc, c], b)
    |> limit(1)
    |> Repo.one()
    |> Repo.preload([
          :benefit_limits,
          benefit_procedures: from(bp in BenefitProcedure, limit: ^limit, offset: ^offset),
          benefit_procedures: [:procedure],
          benefit_coverages: [:coverage]
    ])
  end

  def get_benefit_dental_by_code_or_name(benefit, _, _) do
    benefit_c_or_n = if is_nil(benefit), do: "", else: benefit

    benefit =
      Benefit
      |> join(:inner, [b], bc in BenefitCoverage, b.id == bc.benefit_id)
      |> join(:inner, [b, bc], c in Coverage, c.id == bc.coverage_id)
      |> where([b, bc, c], b.code == ^benefit_c_or_n or b.name == ^benefit_c_or_n)
      |> where([b, bc, c], c.code == "DENTL")
      # |> select([b, bc, c], b)
      |> limit(1)
      |> preload([
        :updated_by,
        :benefit_limits,
        benefit_coverages: [:coverage]
      ])
      |> Repo.one()
      if !is_nil(benefit), do: Map.put(benefit, :benefit_procedures, [])
      # with nil <- check_if_benefit_is_nil(benefit) do
      #   nil
      # else
      #   benefit ->
      #     benefit =  Map.put(:benefit_procedures, [])
      # end
  end
  # defp check_if_benefit_is_nil(nil), do: nil
  # defp check_if_benefit_is_nil(benefit), do: benefit

  def check_coverage_if_dental(coverage_id) do
    coverage_id =
      coverage_id
      |> CoverageContext.get_coverage()

    get_coverage_code(coverage_id.code)
  end

  defp get_coverage_code("DENTL"), do: true
  defp get_coverage_code(_), do: false

  def check_if_type_is_availment_for_dental("Availment"), do: true
  def check_if_type_is_availment_for_dental(_), do: false

end
