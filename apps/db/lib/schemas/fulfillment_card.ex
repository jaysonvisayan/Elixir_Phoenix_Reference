defmodule Innerpeace.Db.Schemas.FulfillmentCard do
  @moduledoc """
  """

  use Innerpeace.Db.Schema
  use Arc.Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Poison.Encoder, only: [
    :card,
    :card_type,
    :product_code_name,
    :transmittal_listing,
    :packaging_style,
    :card_display_line1,
    :card_display_line2,
    :card_display_line3,
    :card_display_line4,
    :letter_instruction,
    :brochure_instruction,
    :booklet_instruction,
    :summary_coverage_instruction,
    :envelope_instruction,
    :no_years_after_issuance,
    :replacement_letter_mailer_instruction,
    :replacement_card_details_instruction,
    :lost_letter_mailer_instruction,
    :lost_card_details_instruction,
    :photo,
    :step
  ]}
  @timestamps_opts [usec: false]

  schema "fulfillment_cards" do
    field :card, :string
    field :card_type, :string
    field :product_code_name, :string
    field :transmittal_listing, :string
    field :packaging_style, :string
    field :card_display_line1, :string
    field :card_display_line2, :string
    field :card_display_line3, :string
    field :card_display_line4, :string
    field :letter_instruction, :string
    field :brochure_instruction, :string
    field :booklet_instruction, :string
    field :summary_coverage_instruction, :string
    field :envelope_instruction, :string
    field :no_years_after_issuance, :string
    field :replacement_letter_mailer_instruction, :string
    field :replacement_card_details_instruction, :string
    field :lost_letter_mailer_instruction, :string
    field :lost_card_details_instruction, :string
    field :photo, Innerpeace.ImageUploader.Type
    field :step, :integer

    has_many :card_files, Innerpeace.Db.Schemas.CardFile, on_delete: :nothing
    has_many :account_group_fulfillments,
      Innerpeace.Db.Schemas.AccountGroupFulfillment, on_delete: :nothing

    timestamps()
  end

  def changeset_card(struct, params \\ %{}) do
    struct
    |> cast(params, [:card,
                     :card_type,
                     :product_code_name,
                     :transmittal_listing,
                     :packaging_style,
                     :card_display_line1,
                     :card_display_line2,
                     :card_display_line3,
                     :card_display_line4])
     |> validate_required([:card,
                           :transmittal_listing,
                           :packaging_style,
                           :product_code_name])
  end

  def changeset_document(struct, params \\ %{}) do
    struct
    |> cast(params, [
                    :letter_instruction,
                    :brochure_instruction,
                    :booklet_instruction,
                    :summary_coverage_instruction,
                    :envelope_instruction,
                    :no_years_after_issuance,
                    :replacement_letter_mailer_instruction,
                    :replacement_card_details_instruction,
                    :lost_letter_mailer_instruction,
                    :lost_card_details_instruction])
    |> validate_required([
                      :letter_instruction,
                    :brochure_instruction,
                    :booklet_instruction,
                    :summary_coverage_instruction,
                    :envelope_instruction,
                    :no_years_after_issuance,
                    :replacement_letter_mailer_instruction,
                    :replacement_card_details_instruction,
                    :lost_letter_mailer_instruction,
                    :lost_card_details_instruction])
  end

  def changeset_photo(struct, params \\ %{}) do
    struct
    |> cast_attachments(params, [:photo])
  end

  def changeset_step(struct, params \\ %{}) do
    struct
    |> cast(params, [:step])
    |> validate_required([:step])
  end

end
