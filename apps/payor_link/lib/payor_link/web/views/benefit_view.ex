defmodule Innerpeace.PayorLink.Web.BenefitView do
  use Innerpeace.PayorLink.Web, :view

  def filter_coverages(coverages, category) do
    coverages
    |> Enum.filter(&(&1.plan_type == category))
    |> Enum.map(&{&1.name, &1.id})
    |> Enum.sort()
  end

  def acu_coverage?(benefit_coverages) do
    list = [] ++ for benefit_coverage <- benefit_coverages do
      benefit_coverage.coverage.name
    end
    Enum.member?(list, "ACU")
  end

  def peme_coverage?(benefit_coverages) do
    list = [] ++ for benefit_coverage <- benefit_coverages do
      benefit_coverage.coverage.name
    end
    Enum.member?(list, "PEME")
  end

  def ruv_coverage?(benefit_coverages) do
    list = [] ++ for benefit_coverage <- benefit_coverages do
      benefit_coverage.coverage.name
    end
    Enum.member?(list, "RUV")
  end

  def atleast_one_of_them?(benefit_coverages) do
    list = [] ++ for benefit_coverage <- benefit_coverages do
      benefit_coverage.coverage.name
    end

    ["OP Laboratory", "Inpatient", "Emergency"] -- list
    |> Enum.count()
    |> pharmacy_misc_setup()

  end

  def pharmacy_misc_setup(count) do
    if count != 3 do
      true
    else
      false
    end
  end

  def maternity_coverage?(benefit_coverages) do
    list = [] ++ for benefit_coverage <- benefit_coverages do
      benefit_coverage.coverage.name
    end
    Enum.member?(list, "Maternity")
  end

  def check_procedure(benefit_procedures, procedure_id) do
    list = [] ++ for benefit_procedure <- benefit_procedures do
      benefit_procedure.procedure.id
    end
    Enum.member?(list, procedure_id)
  end

  def check_diagnosis(benefit_diagnoses, diagnosis_id) do
    list = [] ++ for benefit_diagnosis <- benefit_diagnoses do
      benefit_diagnosis.diagnosis.id
    end
    Enum.member?(list, diagnosis_id)
  end

  def map_acu_procedures(benefit, procedures) do
    benefit_procedures = [] ++ for benefit_procedure <- benefit.benefit_procedures do
      benefit_procedure.procedure
    end
    procedures = procedures -- benefit_procedures
    procedures
    |> Enum.map(&({&1.description, &1.id}))
    |> Enum.sort()
  end

  def display_coverages(benefit) do
    list = [] ++ for benefit_coverage <- benefit.benefit_coverages do
      benefit_coverage.coverage.name
    end
    Enum.join(list, ", ")
  end

  def display_coverages_code(benefit) do
    list = [] ++ for benefit_coverage <- benefit.benefit_coverages do
      benefit_coverage.coverage.code
    end
    Enum.join(list, ", ")
  end

  def filter_benefit_limits(benefit_coverages, benefit_limits) do
    benefit_coverages = [] ++ for benefit_coverage <- benefit_coverages do
      {benefit_coverage.coverage.name, benefit_coverage.coverage.code}
    end
    benefit_limits = [] ++ for benefit_limit <- benefit_limits do
      for bl <- String.split(benefit_limit.coverages, ", ") do
        bl
      end
    end
    benefit_limits =
      benefit_limits
      |> List.flatten()
    Enum.reject(benefit_coverages,
                fn(x) ->
                  {_name, code} = x
                  Enum.member?(benefit_limits, code)
                end
    )
  end

  def display_edit_coverages(benefit) do
    if benefit.category == "Riders" do
      list = [] ++ for benefit_coverage <- benefit.benefit_coverages do
        benefit_coverage.coverage.id
      end
      List.to_string(list)
      else
      list = [] ++ for benefit_coverage <- benefit.benefit_coverages do
        benefit_coverage.coverage.id
      end
      list
    end
  end

  def display_limit_amount(benefit_limit) do
    case benefit_limit.limit_type do
      "Plan Limit Percentage" ->
        benefit_limit.limit_percentage
      "Peso" ->
        benefit_limit.limit_amount
      "Sessions" ->
        benefit_limit.limit_session
      _ ->
        ""
    end
  end

  def check_active_step(conn, step) do
    step = Integer.to_string(step)
    current_step = check_current_step(conn.params["step"])
    if step == current_step do
      "active"
    else
      if String.to_integer(step) < String.to_integer(current_step) do
        "completed"
      else
        "disabled"
      end
    end
  end

  def check_current_step("4.1"), do: "4"
  def check_current_step(step), do: step

  def filter_benefit_procedures(benefit_procedures, procedures) do
    benefit_procedures = for benefit_procedure <- benefit_procedures, into: [] do
      %{
        id: benefit_procedure.id,
        code: benefit_procedure.code,
        description: benefit_procedure.description,
        std_code: benefit_procedure.procedure_code,
        std_description: benefit_procedure.procedure_description,
        std_section: benefit_procedure.procedure_category
      }
    end
    procedures = for procedure <- procedures, into: [] do
      %{
        id: procedure.id,
        code: procedure.code,
        description: procedure.description,
        std_code: procedure.procedure_code,
        std_description: procedure.procedure_description,
        std_section: procedure.procedure_category
      }
    end
    procedures -- benefit_procedures
    |> Enum.sort_by(&(&1.code))
  end

  def filter_benefit_diagnoses(benefit_diagnoses, diagnoses) do
    benefit_diagnoses = for benefit_diagnosis <- benefit_diagnoses, into: [] do
      %{
        id: benefit_diagnosis.diagnosis.id,
        code: benefit_diagnosis.diagnosis.code,
        description: benefit_diagnosis.diagnosis.description,
        type: benefit_diagnosis.diagnosis.type
      }
    end
    diagnoses = for diagnosis <- diagnoses, into: [] do
      %{
        id: diagnosis.id,
        code: diagnosis.code,
        description: diagnosis.description,
        type: diagnosis.type
      }
    end
    diagnoses -- benefit_diagnoses
    |> Enum.sort_by(&(&1.code))
  end

  def filter_benefit_ruvs(benefit_ruvs, ruvs) do
    benefit_ruvs = for benefit_ruv <- benefit_ruvs, into: [] do
      %{
        id: benefit_ruv.ruv.id,
        code: benefit_ruv.ruv.code,
        description: benefit_ruv.ruv.description,
        type: benefit_ruv.ruv.type,
        value: benefit_ruv.ruv.value,
        effectivity_date: benefit_ruv.ruv.effectivity_date
      }
    end
    ruvs = for ruv <- ruvs, into: [] do
      %{
        id: ruv.id,
        code: ruv.code,
        description: ruv.description,
        type: ruv.type,
        value: ruv.value,
        effectivity_date: ruv.effectivity_date
      }
    end
    ruvs -- benefit_ruvs
    |> Enum.sort_by(&(&1.code))
  end

  def filter_benefit_packages(benefit_packages, packages) do
    benefit_packages = for benefit_package <- benefit_packages, into: [] do
      %{
        id: benefit_package.package.id,
        code: benefit_package.package.code,
        name: benefit_package.package.name,
        step: benefit_package.package.step
      }
    end
    packages = for package <- packages, into: [] do
      %{
        id: package.id,
        code: package.code,
        name: package.name,
        step: package.step
      }
    end
    packages -- benefit_packages
    |> Enum.sort_by(&(&1.code))
  end

  def filter_benefit_pharmacies(benefit_pharmacies, pharmacies) do
    benefit_pharmacies =
      benefit_pharmacies
      |> Enum.into([], &(&1.pharmacy))

    pharmacies -- benefit_pharmacies
    |> Enum.sort_by(&(&1.drug_code))
  end

  def filter_benefit_miscellaneous(benefit_miscellaneous, miscellaneous) do
    benefit_miscellaneous =
      benefit_miscellaneous
      |> Enum.into([], &(&1.miscellaneous))

    miscellaneous -- benefit_miscellaneous
    |> Enum.sort_by(&(&1.code))
  end

  def disease_required?(benefit) do
    list = for benefit_coverage <- benefit.benefit_coverages do
      benefit_coverage.coverage.name
    end
    condition1 = Enum.member?(list, "Maternity") and benefit.maternity_type == "Consultation"
    condition2 = Enum.member?(list, "OP Consult")
    condition1 || condition2
  end

  def map_packages(packages) do
    packages
    |> Enum.map(&{&1.name, &1.id})
  end

  def acu_tab_checker(benefit_coverages) do
    if acu_coverage?(benefit_coverages) do
      {"active", ""}
    else
      {"", "active"}
    end
  end

  def peme_tab_checker(benefit_coverages) do
    if peme_coverage?(benefit_coverages) do
      {"active", ""}
    else
      {"", "active"}
    end
  end

  def display_package_name(benefit_procedure) do
    if is_nil(benefit_procedure.package) do
      ""
    else
      benefit_procedure.package.name
    end
  end

  def render("load_all_benefits.json", %{benefits: benefits}) do
    %{benefit: render_many(benefits, Innerpeace.PayorLink.Web.BenefitView, "benefit.json", as: :benefit)}
  end

  def render("benefit.json", %{benefit: benefit}) do
    available_coverages = for bc <- benefit.benefit_coverages do
      bc.coverage.name
    end
    |> Enum.join(", ")
    %{
      id: benefit.id,
      code: benefit.code,
      name: benefit.name,
      created_by: benefit.created_by.username,
      updated_by: benefit.updated_by.username,
      inserted_at: NaiveDateTime.to_date(benefit.inserted_at),
      updated_by: benefit.updated_by.username,
      updated_at: NaiveDateTime.to_date(benefit.updated_at),
      coverages: available_coverages,
      step: benefit.step
    }
  end

  def is_acu?(benefit_coverages) do
    benefit_coverages
    |> Enum.map(&(
      if &1.coverage.name == "ACU" do
        true
      else
        false
      end
    ))
  end

  def is_peme?(benefit_coverages) do
    benefit_coverages
    |> Enum.map(&(
      if &1.coverage.name == "PEME" do
        true
      else
        false
      end
    ))
  end

  def is_benefit_already_used?(benefit) do
    benefit =
      benefit
      |> Innerpeace.Db.Repo.preload([:product_benefits])

    if not Enum.empty?(benefit.product_benefits) do
      true
    else
      false
    end
  end

end
