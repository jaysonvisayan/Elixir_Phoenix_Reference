defmodule Innerpeace.PayorLink.Web.Api.ErrorView do
  use Innerpeace.PayorLink.Web, :view

  alias Ecto.Changeset

  def render("404.html", _assigns) do
    "Page not found"
  end

  def render("500.html", _assigns) do
    "Internal server error"
  end

  # In case no render clause matches or no
  # template is found, let's render it as 500
  def template_not_found(_template, assigns) do
    render "500.html", assigns
  end

  def render("error.json", %{message: message}) do
   %{error: %{message: message}}
  end

  def render("changeset_error.json", %{changeset: changeset}) do
    # When encoded, the changeset returns its errors
    # as a JSON object. So we just pass it forward.
    %{errors: translate_errors(changeset)}
  end

  defp translate_errors(changeset) do
    Changeset.traverse_errors(changeset, &translate_error/1)
  end

  def render("error2.json", %{message: message}) do
    %{message: message}
  end
end
