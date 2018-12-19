defmodule AccountLinkWeb.ErrorView do
  use AccountLinkWeb, :view

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

  # def render("changeset_error.json", %{changeset: changeset}) do
  #   # When encoded, the changeset returns its errors
  #   # as a JSON object. So we just pass it forward.
  #   %{errors: translate_errors(changeset)}
  # end

  def translate_errors(changeset) do
    _message = cond do
      is_nil(changeset) || changeset == "" -> "Unknown error."
      is_bitstring(changeset) -> changeset
      true -> error_string_from_changeset(changeset)
    end
  end
end
