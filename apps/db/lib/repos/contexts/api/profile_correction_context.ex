defmodule Innerpeace.Db.Base.Api.ProfileCorrectionContext do
  @moduledoc false

  alias Innerpeace.Db.{
    Repo,
    Schemas.ProfileCorrection,
    Base.Api.UtilityContext,
    Base.Api.KycContext,
    Parsers.MemberLinkParser
  }

  def create_request_prof_cor(user_id, prof_cor_params) do
    prof_cor_params =
      if prof_cor_params |> Map.has_key?("birth_date") do
        with {:ok, birth_date} <- UtilityContext.birth_date_transform(prof_cor_params["birth_date"])
        do
          prof_cor_params
          |> Map.put("birth_date", birth_date)
        else
          {:empty_birthday} ->
            prof_cor_params
            |> Map.delete("birth_date")
          _ ->
            prof_cor_params
            |> Map.delete("birth_date")
        end
      else
        prof_cor_params
      end

    prof_cor_params =
      prof_cor_params
      |> Map.put("user_id", user_id)
      |> Map.put("status", "for approval")

    if Enum.any?([
      "first_name",
      "middle_name",
      "last_name",
      "suffix",
      "birth_date",
      "gender"
    ], fn(field) -> present?(prof_cor_params, field) end) do
      with {:ok, "uploads"} <- KycContext.validate_upload_profile(prof_cor_params["id_card"])
      do
        with {:ok, %ProfileCorrection{} = prof_cor} <- insert_request_prof_cor(prof_cor_params)
        do
          MemberLinkParser.upload_an_id_card_profile(prof_cor.id, prof_cor_params["id_card"])
        else
          {:error, changeset} ->
            {:error, changeset}
        end
      else
        {:error_upload_params} ->
          {:error_upload_params}
        {:error_base_64} ->
          {:error_base_64}
      end
    else
      {:atleast_one}
    end
  end

  defp present?(params, field) do
    value =
      params
      |> Map.get(field)

    value && value != ""
  end

  def insert_request_prof_cor(params) do
    %ProfileCorrection{}
    |> ProfileCorrection.changeset_api(params)
    |> Repo.insert()
  end

  def get_profile_correction(id) do
    ProfileCorrection
    |> Repo.get(id)
    |> Repo.preload([
      :user
    ])
  end

  def update_id_card(prof_cor, params) do
    prof_cor
    |> ProfileCorrection.changeset_id_card(params)
    |> Repo.update()
  end

end
