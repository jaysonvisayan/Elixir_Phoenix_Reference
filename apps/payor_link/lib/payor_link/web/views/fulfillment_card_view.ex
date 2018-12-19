defmodule Innerpeace.PayorLink.Web.FulfillmentCardView do
  use Innerpeace.PayorLink.Web, :view
  alias Innerpeace.PayorLink.Web.LayoutView

  def get_data_file(params) do
    data = []
    for files <- params do
      get_data_file_1(files, data)
    end
  end

  def get_data_file_1(files, data) do
    if files.file.name == "file_letter" do
      data = data ++ [files.file.name]
    end
    if files.file.name == "file_brochure" do
      data = data ++ [files.file.name]
    end
    if files.file.name == "file_booklet" do
      data = data ++ [files.file.name]
    end
    if files.file.name == "file_summary_coverage" do
      data = data ++ [files.file.name]
    end
    if files.file.name == "file_envelope" do
      data = data ++ [files.file.name]
    end
    if files.file.name == "file_replace_letter_pin_mailer" do
      data = data ++ [files.file.name]
    end
    if files.file.name == "file_replace_card_details" do
      data = data ++ [files.file.name]
    end
    if files.file.name == "file_lost_letter_pin_mailer" do
      data = data ++ [files.file.name]
    end
    if files.file.name == "file_lost_card_details" do
      data = data ++ [files.file.name]
    end
    data = data ++ [","]
  end

  def get_file_letter(fulfillment) do
    for cf <- fulfillment.card_files do
      if cf.file.name == "file_letter" do
        [cf.file]
      else
      end
    end
  end

  def render("fulfillment.json", %{fulfillment: fulfillment}) do
    for cf <- fulfillment.card_files do
      %{
        id: cf.file.id,
        name: cf.file.name,
        file_name: cf.file.type.file_name,
        link:
        Innerpeace.FileUploader
        |> LayoutView.file_url_for(cf.file.type, cf.file)
        |> String.replace("/apps/payor_link/assets/static", "")
      }
    end
  end
end
