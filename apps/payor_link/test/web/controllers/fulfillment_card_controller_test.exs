defmodule Innerpeace.PayorLink.Web.FulfillmentCardControllerTest do
  use Innerpeace.PayorLink.Web.ConnCase
  import Innerpeace.PayorLink.TestHelper

  @invalid_attrs %{}

@create_attrs_card %{
      card: "some_content",
      card_type: "some_content",
      product_code_name: "some_content",
      transmittal_listing: "some content",
      packaging_style: "some content",
}
@create_attrs_document %{
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

  setup do
    conn = build_conn()
    account_group = insert(:account_group)
    account = insert(:account, account_group_id: account_group.id)
    fulfillment_card = insert(:fulfillment_card)
    account_group_fulfillment = insert(:account_group_fulfillment, account_group_id: account_group.id,
                                       fulfillment_id: fulfillment_card.id)
    user = insert(:user, is_admin: true)
    conn = sign_in(conn, user)
    {:ok, %{conn: conn, user: user, account_group: account_group, fulfillment_card: fulfillment_card,
      account_group_fulfillment: account_group_fulfillment, account: account}}
  end

  test "renders form for new fulfillment card", %{conn: conn, account: account} do
    conn = get conn, fulfillment_card_path(conn, :new_card, account.id)
    assert html_response(conn, 200) =~ "Add Fulfillment"
  end

  test "renders form for new edit fulfillment card", %{conn: conn, account: account, fulfillment_card: fulfillment_card} do
    conn = get conn, fulfillment_card_path(conn, :new_edit_card, account.id, fulfillment_card.id)
    assert html_response(conn, 200) =~ "Add Fulfillment"
  end

  test "create card and redirect to fulfillment_document", %{conn: conn, account: account} do
    conn = post conn, fulfillment_card_path(conn, :create_card, account.id), fulfillment_card: @create_attrs_card

    assert %{fulfillment_id: id} = redirected_params(conn)
    assert redirected_to(conn) == fulfillment_card_path(conn, :new_document, account.id, id)
  end

  test "does not create fulfillment and renders errors when data is invalid", %{conn: conn, account: account} do
    conn = post conn, fulfillment_card_path(conn, :create_card, account.id), fulfillment_card: @invalid_attrs
    assert html_response(conn, 200) =~ "Add Fulfillment"
  end

  test "update card and redirect to fulfillment_document", %{conn: conn, account: account, fulfillment_card: fulfillment_card} do
    conn = put conn, fulfillment_card_path(conn, :update_card, account.id,
                                           fulfillment_card.id), fulfillment_card: @create_attrs_card

    assert %{fulfillment_id: id} = redirected_params(conn)
    assert redirected_to(conn) == fulfillment_card_path(conn, :edit_document, account.id, id)
  end

  test "does not update fulfillment and renders errors when data is invalid", %{conn: conn,
    account: account, fulfillment_card: fulfillment_card} do
      conn = put conn, fulfillment_card_path(conn, :update_card, account.id,
                                             fulfillment_card.id), fulfillment_card: @invalid_attrs
    assert html_response(conn, 200) =~ "Add Fulfillment"
  end

  test "renders form for new fulfillment document", %{conn: conn, account: account, fulfillment_card: fulfillment_card} do
    conn = get conn, fulfillment_card_path(conn, :new_document, account.id, fulfillment_card.id)
    assert html_response(conn, 200) =~ "Add Fulfillment"
  end

  test "renders form for new edit fulfillment document", %{conn: conn, account: account, fulfillment_card: fulfillment_card} do
    conn = get conn, fulfillment_card_path(conn, :edit_document, account.id, fulfillment_card.id)
    assert html_response(conn, 200) =~ "Add Fulfillment"
  end

  test "update document and redirect to Account fulfillment", %{conn: conn, account: account, fulfillment_card: fulfillment_card} do
    conn = put conn, fulfillment_card_path(conn, :create_document, account.id,
                                           fulfillment_card.id), fulfillment_card: @create_attrs_document

    assert redirected_to(conn) == account_path(conn, :show, account.id, active: "fulfillment")
  end

 test "does not create fulfillment document and renders errors when data is invalid", %{conn: conn, account: account, fulfillment_card: fulfillment_card} do
   conn = put conn, fulfillment_card_path(conn, :create_document, account.id,
                                          fulfillment_card.id), fulfillment_card: @invalid_attrs
    assert html_response(conn, 200) =~ "Add Fulfillment"
  end

  test "deletes chosen fulfillment card", %{conn: conn, account: account, fulfillment_card: fulfillment_card} do
    conn = get conn, fulfillment_card_path(conn, :delete_card, account.id, fulfillment_card.id)
    assert redirected_to(conn) == "/accounts/#{account.id}?active=fulfillment"
  end
end
