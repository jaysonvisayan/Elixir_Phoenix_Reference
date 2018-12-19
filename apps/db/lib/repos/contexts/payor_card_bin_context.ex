defmodule Innerpeace.Db.Base.PayorCardBinContext do
  @moduledoc """
  """

  alias Innerpeace.Db.Repo
  alias Innerpeace.Db.Schemas.PayorCardBin

  def insert_or_update_payor_card_bin(params) do
    payor_card_bin = get_payor_card_bin_by_payor_id(params.payor_id)
    if is_nil(payor_card_bin) do
      create_payor_card_bin(params)
    else
      update_payor_card_bin(payor_card_bin.id, params)
    end
  end

  def create_payor_card_bin(params) do
    %PayorCardBin{}
    |> PayorCardBin.changeset(params)
    |> Repo.insert()
  end

  def update_payor_card_bin(id, params) do
    id
    |> get_payor_card_bin_by_id
    |> PayorCardBin.changeset(params)
    |> Repo.update()
  end

  def get_payor_card_bin_by_id(id) do
    PayorCardBin
    |> Repo.get(id)
  end

  def get_payor_card_bin_by_payor_id(payor_id) do
    PayorCardBin
    # uncomment once payor_id is available
    # |> Repo.get_by(payor_id: payor_id)
    |> Repo.one()
  end
end
