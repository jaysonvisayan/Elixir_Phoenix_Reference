defmodule Innerpeace.Db.Base.PayorContext do
  @moduledoc false

  import Ecto.{Query, Changeset}, warn: false
  alias Innerpeace.{
    Db.Repo,
    Db.Schemas.Payor
  }

 def insert_or_update_payor(params) do
   payor = get_payor_by_name(params.name)
    if is_nil(payor) do
      create_payor(params)
    else
      update_payor(payor.id, params)
    end
 end

  def get_payor_by_name(name) do
    Payor
    |> Repo.get_by(name: name)
  end

  def create_payor(payor_param) do
    %Payor{}
    |> Payor.changeset(payor_param)
    |> Repo.insert
  end

  def update_payor(id, params) do
    id
    |> get_payor_by_id()
    |> Payor.changeset(params)
    |> Repo.update
  end

  def get_payor_by_id(id) do
    Payor
    |> Repo.get!(id)
  end

  def get_payor_by_name!(name) do
    Payor
    |> Repo.get_by!(name: name)
    |> Repo.preload([
      payor_procedures: :procedure
    ])
  end

end
