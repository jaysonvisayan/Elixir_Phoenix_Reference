defmodule Innerpeace.PayorLink.Web.FulfillmentCardController do
  use Innerpeace.PayorLink.Web, :controller

  alias Innerpeace.Db.Base.{
    FulfillmentCardContext,
    AccountContext
  }
  alias Innerpeace.Db.Schemas.{
    # Account,
    FulfillmentCard
    # AccountFulfillment
  }

  plug :valid_uuid?, %{origin: "accounts"}
  when not action in [:index]

  def new_card(conn, %{"id" => account_id}) do
    changeset =  FulfillmentCardContext.changeset_card(%FulfillmentCard{})
  		render(conn, "new_fulfillment_card.html", changeset: changeset, account_id: account_id)
  end

  def new_card_edit(conn, %{"id" => account_id, "fulfillment_id" => fulfillment_id}) do
    fulfillment = FulfillmentCardContext.get_fulfillment(fulfillment_id)
    changeset = FulfillmentCardContext.changeset_card(fulfillment)
  		render(conn, "new_edit_fulfillment_card.html", changeset: changeset, account_id: account_id, fulfillment: fulfillment)
  end

  def new_edit_card(conn, %{"id" => account_id, "fulfillment_id" => fulfillment_id}) do
    fulfillment = FulfillmentCardContext.get_fulfillment(fulfillment_id)
    if is_nil(fulfillment) do
      conn
      |> put_flash(:error, "Card No Longer/Does Not Exists!")
      |> redirect(
        to: "/accounts/#{account_id}"
      )
    else
      changeset = FulfillmentCardContext.changeset_card(fulfillment)
      render(conn, "edit_fulfillment_card.html", changeset: changeset, account_id: account_id, fulfillment: fulfillment)
    end
  end

  def create_card(conn, %{"id" => id, "fulfillment_card" => fulfillment_params}) do
    if fulfillment_params["card"] == "EMV" do
      fulfillment_params =
        fulfillment_params
        |> Map.merge(%{"card_type" => "", "card_display_line1" => "", "card_display_line2" => "", "card_display_line3" => "", "card_display_line4" => ""})
    end
    case FulfillmentCardContext.create_fulfillment_card(fulfillment_params) do
      {:ok, fulfillment} ->
        FulfillmentCardContext.update_fulfillment_photo(fulfillment, fulfillment_params)
        step = %{"step" => 1}
        FulfillmentCardContext.update_fulfillment_step(fulfillment, step)
        account = AccountContext.get_account!(id)
        account_fulfillment = %{
          fulfillment_id: fulfillment.id,
          account_group_id: account.account_group_id
        }
        FulfillmentCardContext.create_account_fulfillment(account_fulfillment)
        conn
        |> redirect(to: fulfillment_card_path(conn, :new_document, id, fulfillment.id))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new_fulfillment_card.html", changeset: changeset, account_id: id)
    end
  end

  def update_card(conn, %{"id" => id, "fulfillment_id" => fulfillment_id, "fulfillment_card" => fulfillment_params}) do
      if fulfillment_params["card"] == "EMV" do
        fulfillment_params =
          fulfillment_params
          |> Map.merge(%{"card_type" => "", "card_display_line1" => "", "card_display_line2" => "", "card_display_line3" => "", "card_display_line4" => ""})
      end

   fulfillment = FulfillmentCardContext.get_fulfillment(fulfillment_id)
    case FulfillmentCardContext.update_fulfillment_card(fulfillment, fulfillment_params) do
      {:ok, fulfillment} ->
        FulfillmentCardContext.update_fulfillment_photo(fulfillment, fulfillment_params)
        if fulfillment.step == 1 do
        conn
        |> redirect(to: fulfillment_card_path(conn, :new_document, id, fulfillment.id))
        else
        conn
        |> redirect(to: fulfillment_card_path(conn, :edit_document, id, fulfillment.id))
        end
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit_fulfillment_card.html", changeset: changeset, account_id: id, fulfillment: fulfillment)
    end
  end

    def new_document(conn, %{"id" => account_id, "fulfillment_id" => fulfillment_id}) do
    fulfillment = FulfillmentCardContext.get_fulfillment(fulfillment_id)
    changeset = FulfillmentCardContext.changeset_document(fulfillment)
  		render(conn, "new_fulfillment_document.html", changeset: changeset, account_id: account_id, fulfillment: fulfillment)
    end

    def edit_document(conn, %{"id" => account_id, "fulfillment_id" => fulfillment_id}) do
    fulfillment = FulfillmentCardContext.get_fulfillment(fulfillment_id)
    changeset = FulfillmentCardContext.changeset_document(fulfillment)
  		render(conn, "edit_fulfillment_document.html", changeset: changeset, account_id: account_id, fulfillment: fulfillment)
  	end

    defp list_files1(fulfillment_params) do
      list_files = []
      if not is_nil (fulfillment_params["file_letter"]) do
        list_files = list_files ++ [["file_letter", fulfillment_params["file_letter"]]]
      end
      if not is_nil (fulfillment_params["file_brochure"]) do
        list_files = list_files ++ [["file_brochure", fulfillment_params["file_brochure"]]]
      end
      if not is_nil (fulfillment_params["file_booklet"]) do
        list_files = list_files ++ [["file_booklet", fulfillment_params["file_booklet"]]]
      end
      if not is_nil (fulfillment_params["file_summary_coverage"]) do
        list_files = list_files ++ [["file_summary_coverage", fulfillment_params["file_summary_coverage"]]]
      end
      list_files
    end

    defp list_files2(list_files, fulfillment_params) do
      if not is_nil (fulfillment_params["file_envelope"]) do
        list_files = list_files ++ [["file_envelope", fulfillment_params["file_envelope"]]]
      end
      if not is_nil (fulfillment_params["file_replace_letter_pin_mailer"]) do
        list_files = list_files ++ [["file_replace_letter_pin_mailer", fulfillment_params["file_replace_letter_pin_mailer"]]]
      end
      if not is_nil (fulfillment_params["file_replace_card_details"]) do
        list_files = list_files ++ [["file_replace_card_details", fulfillment_params["file_replace_card_details"]]]
      end
      if not is_nil (fulfillment_params["file_lost_letter_pin_mailer"]) do
        list_files = list_files ++ [["file_lost_letter_pin_mailer", fulfillment_params["file_lost_letter_pin_mailer"]]]
      end
      if not is_nil (fulfillment_params["file_lost_card_details"]) do
        list_files = list_files ++ [["file_lost_card_details", fulfillment_params["file_lost_card_details"]]]
      end
      list_files
    end

    def create_document(conn, %{"id" => id, "fulfillment_id" => fulfillment_id, "fulfillment_card" => fulfillment_params}) do
      list_files1 = list_files1(fulfillment_params)
      list_files = list_files2(list_files1, fulfillment_params)
      fulfillment = FulfillmentCardContext.get_fulfillment(fulfillment_id)
      case FulfillmentCardContext.create_fulfillment_document(fulfillment, fulfillment_params) do
        {:ok, fulfillment} ->
          step = %{"step" => 2}
          FulfillmentCardContext.update_fulfillment_step(fulfillment, step)

        for list_file <- list_files do
          params = %{
            name: Enum.at(list_file, 0),
            type: Enum.at(list_file, 1)
          }
          FulfillmentCardContext.delete_fulfillment_card_file(fulfillment_id, params.name)
           file = FulfillmentCardContext.create_fulfillment_file(params)
            params = %{
               file_id: file.id,
               fulfillment_card_id: fulfillment_id
            }
          FulfillmentCardContext.create_card_file(params)
        end
        if fulfillment.step == 2 do
          conn
          |> put_flash(:info, "Fulfillment Card successfully Updated")
          |> redirect(to: account_path(conn, :show, id, active: "fulfillment"))
        else
          conn
          |> put_flash(:info, "Fulfillment Card successfully Created")
          |> redirect(to: account_path(conn, :show, id, active: "fulfillment"))
        end
      {:error, %Ecto.Changeset{} = changeset} ->
        if fulfillment.step == 1 do
          render(conn, "new_fulfillment_document.html", changeset: changeset, account_id: id, fulfillment: fulfillment)
        else
          render(conn, "edit_fulfillment_document.html", changeset: changeset, account_id: id, fulfillment: fulfillment)
        end
      end
    end

    def delete_card(conn, %{"id" => id, "fulfillment_id" => fulfillment_id}) do
      FulfillmentCardContext.delete_all_fulfillment_card_file(fulfillment_id)
      {:ok, _fulfillment_card} = FulfillmentCardContext.delete_fulfillment_card(id, fulfillment_id)
       conn
      |> put_flash(:info, "Fulfillment Successfully Remove")
      |> redirect(to: "/accounts/#{id}?active=fulfillment")
    end

    def remove_fulfillment_photo(_conn, %{"id" => fulfillment_id}) do
      fulfillment = FulfillmentCardContext.get_fulfillment(fulfillment_id)
      FulfillmentCardContext.update_fulfillment_photo(fulfillment, %{"photo" => nil})
    end

    def get_fulfillment_files(conn, %{"id" => id}) do
      fulfillment = FulfillmentCardContext.get_fulfillment(id)
      render(conn, Innerpeace.PayorLink.Web.FulfillmentCardView, "fulfillment.json", fulfillment: fulfillment)
    end

    # def get_fulfillment_photo(conn, %{"id" => fulfillment_id}) do
    # fulfillment = FulfillmentCardContext.get_fulfillment(fulfillment_id)
    # json conn, Poison.encode!(fulfillment)
    #end

end
