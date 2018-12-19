defmodule Innerpeace.Db.Base.DiagnosisContext do
  @moduledoc false
  alias Innerpeace.Db.{
    Repo,
    Schemas.Diagnosis,
    Schemas.Coverage,
    Schemas.DiagnosisCoverage,
    Schemas.DiagnosisLog
  }

  import Ecto.Query

  def insert_or_update_diagnosis(params) do
    diagnosis = get_diagnosis_by_code(params.code)
    if is_nil(diagnosis) do
      create_diagnosis(params)
    else
      update_diagnosis(diagnosis.id, params)
    end
  end

  def get_diagnosis_by_code(code) do
    Diagnosis
    |> Repo.get_by(code: code)
  end

  #Diagnosis Coverage Seeder
  def insert_or_update_diagnosis_coverage(params) do
    diagnosis_coverage = get_by_coverage_and_diagnosis(params.diagnosis_id, params.coverage_id)
    if is_nil(diagnosis_coverage) do
      create_diagnosis_coverage(params)
    else
      update_diagnosis_coverage(diagnosis_coverage.id, params)
    end
  end

  def get_by_coverage_and_diagnosis(diagnosis_id, coverage_id) do
    DiagnosisCoverage
    |> Repo.get_by(diagnosis_id: diagnosis_id, coverage_id: coverage_id)
  end

  def create_diagnosis_coverage(diagnosis_coverage_param) do
    %DiagnosisCoverage{}
    |> DiagnosisCoverage.changeset(diagnosis_coverage_param)
    |> Repo.insert
  end

  def update_diagnosis_coverage(id, diagnosis_coverage_param) do
    id
    |> get_diagnosis_coverage()
    |> DiagnosisCoverage.changeset(diagnosis_coverage_param)
    |> Repo.update
  end

  def get_diagnosis_coverage(id) do
    DiagnosisCoverage
    |> Repo.get!(id)
  end
  #End Seeder

  def get_all_diagnoses do
    Diagnosis
    |> Repo.all
    |> Repo.preload([diagnosis_coverages: :coverage])
  end

  def get_all_diagnosis do
    Diagnosis
    |> Repo.all
  end

  def get_all_tagged_diagnoses do
    Diagnosis
    |> where([d], d.exclusion_type == "General Exclusion")
    |> Repo.all()
  end

  def get_diagnosis(id) do
    Diagnosis
    |> Repo.get(id)
  end

  def csv_params(model) do
    date = "Diagnosis_" <> to_string(DateTime.to_date(DateTime.utc_now()))
    case model do
      date ->
        export_diagnosis
    end
  end

  defp export_diagnosis do
    diagnoses =
      Diagnosis
      |> select([d], [d.code, d.description, d.group_description, d.type, d.congenital, d.exclusion_type])
      |> order_by([d], asc: d.code)
      |> Repo.all
    diagnosis2 = get_all_diagnoses
    coverages = for diagnosis <- diagnosis2 do
      for dc <- diagnosis.diagnosis_coverages do
        dc.coverage.name
      end
    end
    coverage_diagnosis = for diagnoses <- diagnoses do
      coverage = for coverage <- coverages do
        cove =
          coverage
          |> Enum.sort()
          |> Enum.join(", ")
        diagnoses ++ [cove]
      end
    end
    diagnoses = for coverage_diagnosis <- coverage_diagnosis do
      Enum.at(coverage_diagnosis, 0)
    end
    csv_content = [['Code',
                    'Description',
                    'Group Description',
                    'Type', 'Congenital',
                    'Exclusion Type',
                    'Coverage']] ++ diagnoses
                  |> CSV.encode
                  |> Enum.to_list
                  |> to_string
  end

  def csv_downloads(params) do
    param = params["search_value"]

    query = (
      from d in Diagnosis,
      where: ilike(d.code, ^("%#{param}%")) or ilike(d.description, ^("%#{param}%")) or
      ilike(d.group_name, ^("%#{param}%")) or ilike(d.chapter, ^("%#{param}%")) or
      ilike(d.type, ^("%#{param}%")) or
      ilike(fragment("case when ? = 'N' then 'No' else 'Yes' end", d.congenital), ^("%#{param}%")),
      order_by: d.code,
      group_by: d.code,
      group_by: d.description,
      group_by: d.group_name,
      group_by: d.chapter,
      group_by: d.type,
      group_by: d.congenital,
      select: ([
        d.code,
        d.description,
        d.group_name,
        d.chapter,
        d.type,
        fragment("case when ? = 'N' then 'No' else 'Yes' end", d.congenital)
      ])
    )
    query = Repo.all(query)
  end

  def create_diagnosis(diagnosis_param) do
    %Diagnosis{}
    |> Diagnosis.changeset(diagnosis_param)
    |> Repo.insert
  end

  def update_diagnosis(id, diagnosis_param) do
    id
    |> get_diagnosis()
    |> Diagnosis.changeset(diagnosis_param)
    |> Repo.update
  end

  # Start of diagnosis log functions
  def create_update_diagnosis_log(user, diagnosis_changeset) do
    if Map.has_key?(diagnosis_changeset.changes, :exclusion_type) do
      message = "<p>#{user.username} edited Exclusion Type of #{diagnosis_changeset.data.code} from #{if is_nil(diagnosis_changeset.data.exclusion_type), do: "None", else: diagnosis_changeset.data.exclusion_type} to #{if is_nil(diagnosis_changeset.changes.exclusion_type), do: "None", else: diagnosis_changeset.changes.exclusion_type}</p>"

        insert_log(%{
          message: message,
          user_id: user.id,
          diagnosis_id: diagnosis_changeset.data.id
        })
    end
  end

  defp insert_log(params) do
    changeset = DiagnosisLog.changeset(%DiagnosisLog{}, params)
    Repo.insert!(changeset)
  end

  def get_logs(diagnosis_id) do
    DiagnosisLog
    |> where([dl], dl.diagnosis_id == ^diagnosis_id)
    |> order_by([dl], desc: dl.inserted_at)
    |> Repo.all()
  end
  # End of diagnosis log functions

  def icd_clear_tagging(diagnosis) do
    params = %{exclusion_type: nil}
    diagnosis
    |> Diagnosis.changeset_exclusion_type_nil(params)
    |> Repo.update()
  end

  def get_all_diagnosis_query(params, offset) do
    Diagnosis
    |> where([d],
             ilike(d.code, ^"%#{params}%") or
             ilike(d.description, ^"%#{params}%") or
             ilike(d.type, ^"#{params}%")
    )
    |> order_by([d], d.code)
    |> limit(100)
    |> offset(^offset)
    |> Repo.all()
    |> Repo.preload([diagnosis_coverages: :coverage])
  end

  def load_diagnosis_table(ids) when ids == [""] do
    Diagnosis
    |> select([d],
              %{
                id: d.id,
                code: d.code,
                name: d.group_description,
                description: d.description,
                type: d.type
              }
    )
    |> Repo.all()
    |> insert_table_buttons([])
  end

  def load_diagnosis_table(ids) when ids != [""] do
    Diagnosis
    |> where([d], d.code not in ^ids)
    |> select([d],
              %{
                id: d.id,
                code: d.code,
                name: d.group_description,
                description: d.description,
                type: d.type
              }
    )
    |> Repo.all()
    |> insert_table_buttons([])
  end

  defp insert_table_buttons([head | tails], tbl) do
    tbl =
      tbl ++ [[
        "<input type='checkbox' style='width:20px; height:20px' class='diagnosis_chkbx' diagnosis_id='#{head.id}' code='#{head.code}' description='#{head.description}' diagnosis_type='#{head.type}' diagnosis_name='#{head.name}' />",
        "<span class='green'>#{head.code}</span>",
        "<strong>#{head.name}</strong><br><small class='thin dim'>#{head.description}</small>",
        head.type
      ]]

    insert_table_buttons(tails, tbl)
  end
  defp insert_table_buttons([], tbl), do: tbl
end
