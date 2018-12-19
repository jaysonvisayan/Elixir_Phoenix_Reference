defmodule Innerpeace.Db.Base.ExclusionContext do
  @moduledoc false

  import Ecto.{Query, Changeset}, warn: false
  alias Innerpeace.Db.{
    Repo,
    Schemas.Exclusion,
    Schemas.ExclusionDisease,
    Schemas.ExclusionProcedure,
    Schemas.ExclusionDuration,
    Schemas.Diagnosis,
    Parsers.ExclusionGeneralParser,
    Schemas.ExclusionGeneralUploadFile,
    Schemas.ExclusionGeneralUploadLog,
    Schemas.ProductExclusion
  }

  def get_all_exclusions do
    Exclusion
    |> Repo.all
    |> Repo.preload([
      :created_by,
      :updated_by,
      :exclusion_durations,
      exclusion_diseases: :disease,
      exclusion_procedures: :procedure
    ])
  end

  def get_exclusion(id) do
    Exclusion
    |> Repo.get!(id)
    |> Repo.preload(
      [
        :created_by,
        :updated_by,
        :exclusion_durations,
        exclusion_diseases: :disease,
        exclusion_procedures: [procedure: [:procedure_logs, [procedure: :procedure_category]]]
      ])
  end

  def create_exclusion(exclusion_params) do
    %Exclusion{}
    |> Exclusion.changeset_exclusion(exclusion_params)
    |> Repo.insert()
  end

  def create_pre_existing(exclusion_params) do
    %Exclusion{}
    |> Exclusion.changeset_pre_existing(exclusion_params)
    |> Repo.insert()
  end

  def update_exclusion(exclusion, exclusion_params) do
    exclusion
    |> Exclusion.changeset_exclusion(exclusion_params)
    |> Repo.update()
  end

  def update_pre_existing(exclusion, exclusion_params) do
    exclusion
    |> Exclusion.changeset_pre_existing(exclusion_params)
    |> Repo.update()
  end

  def update_exclusion_step(%Exclusion{} = exclusion, exclusion_params) do
    exclusion
    |> Exclusion.changeset_step(exclusion_params)
    |> Repo.update()
  end

  def delete_exclusion(id) do
    id
    |> get_exclusion()
    |> Repo.delete
  end

  def set_exclusion_procedure(exclusion_id, procedure_ids) do
    for procedure_id <- procedure_ids do
      params = %{exclusion_id: exclusion_id, procedure_id: procedure_id}
      changeset = ExclusionProcedure.changeset(%ExclusionProcedure{}, params)
      Repo.insert!(changeset)
    end
  end

  def clear_exclusion_procedure(exclusion_id) do
    ExclusionProcedure
    |> where([ep], ep.exclusion_id == ^exclusion_id)
    |> Repo.delete_all()
  end

  def set_exclusion_disease(exclusion_id, disease_ids) do
    for disease_id <- disease_ids do
      params = %{exclusion_id: exclusion_id, disease_id: disease_id}
      changeset = ExclusionDisease.changeset(%ExclusionDisease{}, params)
      Repo.insert!(changeset)
    end
  end

  def clear_exclusion_disease(exclusion_id) do
    ExclusionDisease
    |> where([ed], ed.exclusion_id == ^exclusion_id)
    |> Repo.delete_all()
  end

  def exclusion_clear_all(exclusion_id) do
    clear_exclusion_disease(exclusion_id)
    clear_exclusion_procedure(exclusion_id)
  end

  def edit_update_exclusion(exclusion, exclusion_params) do
    exclusion
    |> Exclusion.changeset_edit_exclusion(exclusion_params)
    |> Repo.update()
  end

  def edit_update_pre_existing(exclusion, exclusion_params) do
    exclusion
    |> Exclusion.changeset_edit_pre_existing(exclusion_params)
    |> Repo.update()
  end

  def get_all_exclusion_code do
    Exclusion
    |> select([:code])
    |> Repo.all
    |> Repo.preload([:exclusion_durations, :exclusion_diseases, :exclusion_procedures])
  end

  def create_duration(exclusion, attrs) do
    if attrs["covered_after_duration"] == "Peso" do
      attrs =
        attrs
        |> Map.merge(%{"exclusion_id" => exclusion})
        |> Map.put("cad_amount", attrs["cad_value"])

        %ExclusionDuration{}
        |> ExclusionDuration.changeset(attrs)
        |> Repo.insert()
    else
      attrs =
        attrs
        |> Map.merge(%{"exclusion_id" => exclusion})
        |> Map.put("cad_percentage", attrs["cad_value"])

        %ExclusionDuration{}
        |> ExclusionDuration.changeset(attrs)
        |> Repo.insert()
    end
  end

  def list_all_durations do
    ExclusionDuration
    |> Repo.all
  end

  def get_by_exclusion_and_diagnosis(exclusion_id, diagnosis_id) do
    ExclusionDisease
    |> Repo.get_by(exclusion_id: exclusion_id, id: diagnosis_id)
  end

    def get_by_exclusion_and_procedure(exclusion_id, procedure_id) do
    ExclusionProcedure
    |> Repo.get_by(exclusion_id: exclusion_id, id: procedure_id)
  end

  def get_by_exclusion_and_duration(exclusion_id, duration_id) do
    ExclusionDuration
    |> Repo.get_by(exclusion_id: exclusion_id, id: duration_id)
  end

  def delete_exclusion_procedure!(exclusion_id, procedure_id) do
    exclusion_id
    |> get_by_exclusion_and_procedure(procedure_id)
    |> Repo.delete!()
  end

  def delete_exclusion_disease!(exclusion_id, disease_id) do
    exclusion_id
    |> get_by_exclusion_and_diagnosis(disease_id)
    |> Repo.delete!()
  end

  def delete_exclusion_duration!(exclusion_id, duration_id) do
    exclusion_id
    |> get_by_exclusion_and_duration(duration_id)
    |> Repo.delete!()
  end

  def check_duration_disease_type(exclusion_id, disease_type) do
    ExclusionDuration
    |> where([ed], ed.exclusion_id == ^exclusion_id and ed.disease_type == ^disease_type)
    |> Repo.all()
    |> Enum.count
  end

  def check_disease_type(exclusion_id, type) do
    ExclusionDisease
    |> join(:inner, [ed], d in Diagnosis, ed.disease_id == d.id)
    |> where([ed, d], ed.exclusion_id == ^exclusion_id and d.type == ^type)
    |> Repo.all()
    |> Enum.count
  end

  def clear_exclusion_disease_by_diseases_type(exclusion_id, disease_type) do
    ExclusionDisease
    |> join(:inner, [ed], d in Diagnosis, ed.disease_id == d.id)
    |> where([ed, d], ed.exclusion_id == ^exclusion_id and d.type == ^disease_type)
    |> Repo.delete_all()
  end

  def get_eg_upload_file do
    ExclusionGeneralUploadFile
    |> Repo.all()
    |> Repo.preload(:exclusion_general_upload_logs)
  end

  def create_batch_upload(batch_file, user_id) do
    if String.ends_with?(batch_file["file"].filename, ["xls", "csv", "xlsx"]) do
      data =
        batch_file["file"].path
        |> File.stream!()
        |> CSV.decode(headers: true)

        keys = ["Payor CPT Code", "Diagnosis Code"]

        with {:ok, map} <- Enum.at(data, 0),
            {:equal} <- column_checker(keys, map)
        do
          ExclusionGeneralParser.parse_data(data, batch_file["file"].filename, user_id)
         {:ok}
        else
          nil ->
            {:empty_file, "File has empty records"}

          {:missing_header_column, message} ->
            {:missing_header_column, message}
        end
    else
      {:invalid_format}
    end

  end

  defp column_checker(keys, map) do
    #%{key: Enum.sort(keys), file_keys: Enum.sort(Enum.map(Map.keys(map), fn(x) -> String.trim(x) end))}
    if Enum.sort(keys) == Enum.sort(Map.keys(map)) do
      {:equal}
    else
      submitted_header = Enum.sort(Map.keys(map))
      result = keys -- submitted_header
               |> Enum.join(" and ")
      {:missing_header_column, "File has missing column/s: #{result}"}
    end
  end

  def generate_batch_no(batch_no) do
    origin = batch_no

    case Enum.count(Integer.digits(batch_no)) do
      1 ->
        batch_no = "000#{batch_no}"
      2 ->
        batch_no = "00#{batch_no}"
      3 ->
        batch_no = "0#{batch_no}"
      4 ->
        batch_no
      _ ->
        batch_no
    end

    with nil <- Repo.get_by(ExclusionGeneralUploadFile, batch_no: batch_no),
        false <- origin == 0
    do
      batch_no
    else
     %ExclusionGeneralUploadFile{} -> # UploadFile Schema
        generate_batch_no(origin + 1)
      true ->
        "0001"
    end
  end

  def create_exclusion_upload_file(attrs) do
    %ExclusionGeneralUploadFile{}
    |> ExclusionGeneralUploadFile.changeset(attrs)
    |> Repo.insert()
  end

  def create_exclusion_upload_log(attrs) do
    %ExclusionGeneralUploadLog{}
    |> ExclusionGeneralUploadLog.changeset(attrs)
    |> Repo.insert()
  end

  def all_batch_upload_files do
    ExclusionGeneralUploadFile
    |> Repo.all
    |> Repo.preload([:exclusion_general_upload_logs])
  end

  def cpt_get_batch_log(log_id, status) do
    query = (
      from egul in ExclusionGeneralUploadLog,
      join: eguf in ExclusionGeneralUploadFile,
      on: egul.exclusion_general_upload_file_id == eguf.id,
      where: egul.exclusion_general_upload_file_id == ^log_id and egul.payor_cpt_status == ^status,
      select: [egul.payor_cpt_code, egul.payor_cpt_remarks]
    )
    Repo.all query
  end

  def icd_get_batch_log(log_id, status) do
    query = (
      from egul in ExclusionGeneralUploadLog,
      join: eguf in ExclusionGeneralUploadFile,
      on: egul.exclusion_general_upload_file_id == eguf.id,
      where: egul.exclusion_general_upload_file_id == ^log_id and egul.diagnosis_status == ^status,
      select: [egul.diagnosis_code, egul.diagnosis_remarks]
    )
    Repo.all query
  end

  def is_used?(exclusion_id) do
    ProductExclusion
    |> where([pe], pe.exclusion_id == ^exclusion_id)
    |> limit(1)
    |> Repo.one()
  end

end
