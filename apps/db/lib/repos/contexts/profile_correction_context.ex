defmodule Innerpeace.Db.Base.ProfileCorrectionContext do
  @moduledoc false

  alias Innerpeace.Db.{
    Repo,
    Schemas.ProfileCorrection
  }

  def create_request_prof_cor(user_id, prof_cor_params) do
    prof_cor_params =
      if prof_cor_params |> Map.has_key?("birth_date") do

        if String.trim(prof_cor_params["birth_date"]["year"]) == "" ||
          String.trim(prof_cor_params["birth_date"]["month"]) == "" ||
          String.trim(prof_cor_params["birth_date"]["day"]) == "" ||
          is_nil(String.trim(prof_cor_params["birth_date"]["year"])) ||
          is_nil(String.trim(prof_cor_params["birth_date"]["month"])) ||
          is_nil(String.trim(prof_cor_params["birth_date"]["day"])) do

            prof_cor_params
            |> Map.delete("birth_date")
        else
          birth_date =
            {String.to_integer(prof_cor_params["birth_date"]["year"]),
              String.to_integer(prof_cor_params["birth_date"]["month"]),
              String.to_integer(prof_cor_params["birth_date"]["day"])}

          prof_cor_params
          |> Map.put("birth_date", birth_date)
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
      insert_request_prof_cor(prof_cor_params)
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
    |> ProfileCorrection.changeset(params)
    |> Repo.insert()
  end
end
