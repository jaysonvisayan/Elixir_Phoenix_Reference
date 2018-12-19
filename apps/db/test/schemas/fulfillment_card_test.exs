defmodule Innerpeace.Db.Schemas.FulfillmentCardTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.FulfillmentCard

  test "changeset_card with valid attributes" do
    params = %{
      card: "some content",
      card_type: "some content",
      product_code_name: "some content",
      transmittal_listing: "some content",
      packaging_style: "some content"
    }

    changeset = FulfillmentCard.changeset_card(%FulfillmentCard{}, params)
    assert changeset.valid?
  end

  test "changeset_card with invalid attributes" do
    params = %{
      card: "",
      card_type: "",
      product_code_name: "",
    }

    changeset = FulfillmentCard.changeset_card(%FulfillmentCard{}, params)
    refute changeset.valid?
  end

  test "changeset_document with valid attributes" do
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

    changeset = FulfillmentCard.changeset_document(%FulfillmentCard{}, params)
    assert changeset.valid?
  end

  test "changeset_document with invalid attributes" do
    params = %{
       letter_instruction: "",
      brochure_instruction: "",
      booklet_instruction: "",
      summary_coverage_instruction: "",
      envelope_instruction: "",
      no_years_after_issuance: "",
      replacement_letter_mailer_instruction: "",
      replacement_card_details_instruction: "",
      lost_letter_mailer_instruction: "",
      lost_card_details_instruction: ""

    }

    changeset = FulfillmentCard.changeset_document(%FulfillmentCard{}, params)
    refute changeset.valid?
  end

end
