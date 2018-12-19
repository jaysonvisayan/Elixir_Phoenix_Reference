defmodule MemberLinkWeb.TranslationController do
  use MemberLinkWeb, :controller

  # alias Innerpeace.Db.Repo
  # alias MemberLink.Guardian.Plug
  alias Innerpeace.Db.Base.{
    TranslationContext
  }
  alias Innerpeace.Db.Schemas.{
    Translation
  }

  def index(conn, _params) do
    translation = TranslationContext.get_all_translation()
    render(conn, "index.html", translations: translation, locale: conn.assigns.locale)
  end

  def new(conn, _params) do
    changeset = Translation.changeset(%Translation{})
    render(conn, "new.html", changeset: changeset, locale: conn.assigns.locale)
  end

  def create(conn, %{"translation" => translation_params}) do
    case TranslationContext.create_a_translation(translation_params) do
      {:ok, _translation} ->
        conn
        |> put_flash(:info, "Translation Successfully Created")
        |> redirect(to: translation_path(conn, :index, conn.assigns.locale))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    translation = TranslationContext.get_translation!(id)
    render(conn, "show.html", translation: translation)
  end

  def edit(conn, %{"id" => id}) do
    translation = TranslationContext.get_translation!(id)
    changeset = Translation.changeset(translation)
    render(conn, "edit.html", translation: translation, changeset: changeset)
  end

  def update(conn, %{"id" => id, "translation" => translation_params}) do
    translation = TranslationContext.get_translation!(id)

    case TranslationContext.update_a_translation(id, translation_params) do
      {:ok, _translation} ->
        conn
        |> put_flash(:info, "Translation updated successfully.")
        |> redirect(to: translation_path(conn, :index, conn.assigns.locale))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", translation: translation, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    {:ok, _translation} = TranslationContext.delete_translation(id)

    conn
    |> put_flash(:info, "Coverage deleted successfully.")
    |> redirect(to: translation_path(conn, :index, conn.assigns.locale))
  end

  def get_base_value(conn, _params) do
    translation = TranslationContext.get_all_translation()
    render(conn, "translation.json", translations: translation)
  end

end
