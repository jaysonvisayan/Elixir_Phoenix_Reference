defmodule Innerpeace.Db.Repo.Migrations.AlterTableFullfillmentCard do
  use Ecto.Migration

  def change do
    alter table(:fulfillment_cards) do
      remove (:letter)
      remove (:brochure)
      remove (:booklet)
      remove (:summary_coverage)
      remove (:envelope)
      remove (:replacement_letter_mailer)
      remove (:replacement_card_details)
      remove (:lost_letter_mailer)
      remove (:lost_card_details)
    end
  end
end
