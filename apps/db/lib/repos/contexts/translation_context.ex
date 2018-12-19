defmodule Innerpeace.Db.Base.TranslationContext do
  @moduledoc false

  import Ecto.{Query, Changeset}, warn: false
  alias Innerpeace.Db.{
    Repo,
    Schemas.Translation,
    Schemas.Practitioner,
    Schemas.Facility,
    Base.MemberContext,
    Base.PractitionerContext,
    Base.FacilityContext,
  }
  alias Innerpeace.Db.Base.Api.FacilityContext, as: ApiFacilityContext

  def get_all_translation do
    Translation
    |> Repo.all()
  end

  def get_translated_values(conn, params) do
    locale = conn.assigns.locale
    cond do
      locale == "zh" ->
        translate_from_base_value(params)
      locale == "en" ->
        get_all_translation_by_base_value(params)
      true ->
        raise 3
    end
  end

  def search_from_translated_values(conn, params) do
    locale = conn.assigns.locale
    if locale == "zh" do
      if Enum.any?([params == "", params == nil]) do
        %{"name" => params["name"], "address" => params["address"], "specialization" => params["specialization"]}
      else
        name = search_translated_value(params["name"])
        specialization = search_translated_value(params["specialization"])
        address = search_translated_value(params["address"])
        cond do
          Enum.all?([is_nil(name), is_nil(specialization), is_nil(address)]) ->
            %{"name" => params["name"], "address" => params["address"], "specialization" => params["specialization"]}
          not is_nil(name) ->
            %{"name" => name, "address" => params["address"], "specialization" => params["specialization"]}
          not is_nil(address) ->
            %{"name" => params["name"], "address" => address, "specialization" => params["specialization"]}
          not is_nil(specialization) ->
            %{"name" => params["name"], "address" => params["address"], "specialization" => specialization}
          true ->
            %{"name" => name, "address" => address, "specialization" => specialization}
        end
      end
    else
      %{"name" => params["name"], "address" => params["address"], "specialization" => params["specialization"]}
    end
  end

  #translation seeds
  def insert_or_update_translation(params) do
    translation = get_translation_by_base_value(params.base_value)
    if is_nil(translation) do
      create_a_translation(params)
    else
      update_a_translation(translation.id, params)
    end
  end

  def get_translation_by_base_value(params) do
    Translation
    |> Repo.get_by(base_value: params)
  end

  def get_all_translation_by_base_value(params) do
    Translation
    |> where([t], t.base_value == ^params)
    |> select([t], t.base_value)
    |> Repo.one
  end

  def translate_from_base_value(params) do
    Translation
    |> where([t], t.base_value == ^params)
    |> select([t], t.translated_value)
    |> Repo.one
  end

  def search_translated_value(params) do
    Translation
    |> where([t], t.translated_value == ^params)
    |> select([t], t.base_value)
    |> Repo.one()
  end

  def get_translation!(id) do
    Translation
    |> Repo.get!(id)
  end

  def create_a_translation(params) do
    %Translation{}
    |> Translation.changeset(params)
    |> Repo.insert
  end

  def update_a_translation(id, params) do
    id
    |> get_translation!()
    |> Translation.changeset(params)
    |> Repo.update
  end

  def delete_translation(id) do
    id
    |> get_translation!()
    |> Repo.delete()
  end

end
