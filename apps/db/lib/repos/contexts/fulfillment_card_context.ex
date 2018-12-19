defmodule Innerpeace.Db.Base.FulfillmentCardContext do
  @moduledoc false

  import Ecto.{Query, Changeset}, warn: false
   alias Innerpeace.Db.Base.{
    AccountContext
  }

  alias Innerpeace.{
    Db.Repo,
    # Db.Schemas.AccountGroup,
    Db.Schemas.AccountGroupFulfillment,
    Db.Schemas.FulfillmentCard,
    Db.Schemas.File,
    Db.Schemas.CardFile
  }

  def list_fulfillments do
    FulfillmentCard
    |> Repo.all()
    |> Repo.preload(card_files: :file)
  end

  def get_fulfillment(id) do
    FulfillmentCard
    |> Repo.get!(id)
    |> Repo.preload(card_files: :file)

    rescue
        Ecto.NoResultsError ->
             nil
  end

  def create_fulfillment_card(attrs \\ %{}) do
    %FulfillmentCard{}
    |> FulfillmentCard.changeset_card(attrs)
    |> Repo.insert()
  end

  def create_account_fulfillment(attrs \\ %{}) do
    %AccountGroupFulfillment{}
    |> AccountGroupFulfillment.changeset(attrs)
    |> Repo.insert()
  end

  def create_fulfillment_document(%FulfillmentCard{} = fulfillment_card, attrs) do
    fulfillment_card
    |> FulfillmentCard.changeset_document(attrs)
    |> Repo.update()
  end

  def create_fulfillment_file(attrs \\ %{}) do
    %File{}
    |> File.changeset(attrs)
    |> Repo.insert!()
    |> File.changeset_file(attrs)
    |> Repo.update!()
  end

  def create_card_file(attrs \\ %{}) do
    %CardFile{}
    |> CardFile.changeset(attrs)
    |> Repo.insert()
  end

  def delete_fulfillment_card_file(fulfillment_id, name) do
    fulfillment = get_fulfillment(fulfillment_id)
    for fc <- fulfillment.card_files do
      if fc.file.name == name do
        File
          |> Repo.get(fc.file.id)
          |> Repo.delete()
        CardFile
          |> where([cf], cf.fulfillment_card_id == ^fulfillment_id and cf.file_id == ^fc.file.id)
          |> Repo.delete_all()
      end
    end
  end

  def delete_all_fulfillment_card_file(fulfillment_id) do
    card_file =
    CardFile
    |> where([cf], cf.fulfillment_card_id == ^fulfillment_id)
    |> Repo.all
    |> Repo.preload([:file])
    for card <- card_file do
      File
      |> Repo.get(card.file.id)
      |> Repo.delete()
    end
  end

  def update_fulfillment_step(%FulfillmentCard{} = fulfillment_card, attrs) do
    fulfillment_card
    |> FulfillmentCard.changeset_step(attrs)
    |> Repo.update()
  end

  def update_fulfillment_card(%FulfillmentCard{} = fulfillment_card, attrs) do
    fulfillment_card
    |> FulfillmentCard.changeset_card(attrs)
    |> Repo.update()
  end

  def delete_fulfillment_card(id, fulfillment_id) do
    account = AccountContext.get_account!(id)
    AccountGroupFulfillment
    |> where([af], af.account_group_id == ^account.account_group_id and af.fulfillment_id == ^fulfillment_id)
    |> Repo.delete_all()
    fulfillment = get_fulfillment(fulfillment_id)
    Repo.delete(fulfillment)
  end

  def changeset_card(%FulfillmentCard{} = fulfillment) do
    FulfillmentCard.changeset_card(fulfillment, %{})
  end

  def changeset_document(%FulfillmentCard{} = fulfillment) do
    FulfillmentCard.changeset_document(fulfillment, %{})
  end

  def update_fulfillment_photo(%FulfillmentCard{} = fulfillment_card, attrs) do
    fulfillment_card
    |> FulfillmentCard.changeset_photo(attrs)
    |> Repo.update()

  end

end
