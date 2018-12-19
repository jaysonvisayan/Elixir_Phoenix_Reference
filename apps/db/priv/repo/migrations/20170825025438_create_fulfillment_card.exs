defmodule Innerpeace.Db.Repo.Migrations.CreateFulfillmentCard do
  use Ecto.Migration

  def change do
    create table(:fulfillment_cards, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :photo, :string
      add :card, :string
      add :card_type, :string
      add :product_code_name, :string
      add :card_display_line1, :string
      add :card_display_line2, :string
      add :card_display_line3, :string
      add :card_display_line4, :string
      add :letter, :string
      add :letter_instruction, :string
      add :brochure, :string
      add :brochure_instruction, :string
      add :booklet, :string
      add :booklet_instruction, :string
      add :summary_coverage, :string
      add :summary_coverage_instruction, :string
      add :envelope, :string
      add :envelope_instruction, :string
      add :no_years_after_issuance, :string
      add :replacement_letter_mailer, :string
      add :replacement_letter_mailer_instruction, :string
      add :replacement_card_details, :string
      add :replacement_card_details_instruction, :string
      add :lost_letter_mailer, :string
      add :lost_letter_mailer_instruction, :string
      add :lost_card_details, :string
      add :lost_card_details_instruction, :string
      add :step, :integer

      timestamps()
    end

  end
end
