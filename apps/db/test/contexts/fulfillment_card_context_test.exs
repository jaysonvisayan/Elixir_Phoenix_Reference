defmodule Innerpeace.Db.Base.FulfillmentCardContextTest do
  use Innerpeace.Db.SchemaCase
 use Innerpeace.Db.PayorRepo, :context
  alias Innerpeace.Db.Schemas.{
    # Account,
    FulfillmentCard,
    AccountGroupFulfillment,
    # File,
    CardFile
  }
  alias Innerpeace.Db.Base.FulfillmentCardContext

  @invalid_attrs %{}

  test "list all fulfillment cards" do
    fulfillment = insert(:fulfillment_card)
    assert FulfillmentCardContext.list_fulfillments == [fulfillment] |> Repo.preload(card_files: :file)

  end

  test "get fulfillment using id return fulfillment" do
    fulfillment = insert(:fulfillment_card, card: "test")
    assert FulfillmentCardContext.get_fulfillment(fulfillment.id) == fulfillment |> Repo.preload(card_files: :file)

  end

  test "create fulfillment card" do
    params = %{
      card: "some_content",
      card_type: "some_content",
      product_code_name: "some_content",
      transmittal_listing: "some content",
      packaging_style: "some content",
    }

    assert {:ok, %FulfillmentCard{}} = create_fulfillment_card(params)
  end

  test "create account fulfillment card" do
    fulfillment = insert(:fulfillment_card)
    account_group = insert(:account_group)
    params = %{
      fulfillment_id: fulfillment.id,
      account_group_id: account_group.id
    }

    assert {:ok, %AccountGroupFulfillment{}} = create_account_fulfillment(params)
  end

  test "create fulfillment card with invalid data returns error changeset" do
    assert {:error, %Ecto.Changeset{}} = create_fulfillment_card(@invalid_attrs)
  end

  test "create fulfillment document" do
    params = %{
      letter_instruction: "some content",
      brochure_instruction: "some content",
      booklet_instruction: "some content",
      summary_coverage_instruction: "some content",
      envelope_instruction: "some content",
      no_years_after_issuance: "some content",
      replacement_letter_mailer_instruction: "some content",
      replacement_card_details_instruction: "some content",
      lost_letter_mailer_instruction: "some content",
      lost_card_details_instruction: "some content"
    }

    fulfillment = insert(:fulfillment_card, params)

    assert {:ok, %FulfillmentCard{} = fulfillment} == create_fulfillment_document(fulfillment, params)
  end

  test "create fulfillment document with invalid data returns error changeset" do
    fulfillment = insert(:fulfillment_card)
    assert {:error, %Ecto.Changeset{}} = create_fulfillment_document(fulfillment, @invalid_attrs)
  end

  test "create fulfillment file" do
    params = %{
      name: "Name of File"
    }
    file = create_fulfillment_file(params)
    name = params.name
    assert name == file.name
  end

  test "create card file" do
    fulfillment = insert(:fulfillment_card)
    file = insert(:file)
    params = %{
      fulfillment_card_id: fulfillment.id,
      file_id: file.id
    }
    assert {:ok, %CardFile{}} = create_card_file(params)
  end

  test "update fulfillment card" do
    params = %{
      card: "some_content",
      card_type: "some_content",
      product_code_name: "some_content",
      transmittal_listing: "some content",
      packaging_style: "some content",
    }
    fulfillment = insert(:fulfillment_card, params)

    assert {:ok, %FulfillmentCard{}} = update_fulfillment_card(fulfillment, params)
  end

  test "update fulfillment card with invalid data returns error changeset" do
    fulfillment = insert(:fulfillment_card)
    assert {:error, %Ecto.Changeset{}} = update_fulfillment_card(fulfillment, @invalid_attrs)
  end

  test "update fulfillment card with step" do
    fulfillment = insert(:fulfillment_card)
    step = %{step: 1}
    assert {:ok, %FulfillmentCard{}} = update_fulfillment_step(fulfillment, step)
  end

  test "delete fulfillment card" do
    fulfillment = insert(:fulfillment_card)
    account_group = insert(:account_group)
    account = insert(:account, account_group_id: account_group.id)
    insert(:account_group_fulfillment, account_group_id: account_group.id, fulfillment_id: fulfillment.id)
    assert {:ok, %FulfillmentCard{}} = delete_fulfillment_card(account.id, fulfillment.id)
  end

end
