defmodule Innerpeace.Db.Base.ApiAddressContext do
  @moduledoc """
  """

  alias Innerpeace.Db.Repo
  alias Innerpeace.Db.Schemas.ApiAddress

  def insert_or_update_api_address(params) do
    api_address =
      params.name
      |> get_api_address_by_name()

    if is_nil(api_address) do
      params
      |> create_api_address()
    else
      api_address.id
      |> update_api_address(params)
    end
  end

  def get_api_address_by_name(name) do
    ApiAddress
    |> Repo.get_by(name: name)
  end

  def create_api_address(payor_param) do
    %ApiAddress{}
    |> ApiAddress.changeset(payor_param)
    |> Repo.insert
  end

  def update_api_address(id, params) do
    id
    |> get_api_address_by_id()
    |> ApiAddress.changeset(params)
    |> Repo.update
  end

  def get_api_address_by_id(id) do
    ApiAddress
    |> Repo.get(id)
  end
end
