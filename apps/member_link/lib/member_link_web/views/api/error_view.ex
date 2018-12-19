defmodule MemberLinkWeb.Api.ErrorView do
  use MemberLinkWeb, :view

  # In case no render clause matches or no
  # template is found, let's render it as 500
  def template_not_found(_template, assigns) do
    render "500.html", assigns
  end

  def render("error.json", %{message: message, code: code}) do
    %{
      "message": message,
      "code": code
    }
  end

  def render("changeset_error.json", %{message: message, code: code}) do
    message = cond do
      is_nil(message) || message == "" -> "Unknown error."
      is_bitstring(message) -> message
      true -> error_string_from_changeset(message)
    end

    %{
      "message": message,
      "code": code
    }
  end

  def render("changeset_error_api.json", %{changeset: changeset}) do
    # When encoded, the changeset returns its errors
    # as a JSON object. So we just pass it forward.
    %{errors: translate_errors(changeset)}
  end

  def render("404.html", _assigns) do
    "Page not found"
  end

  def render("500.html", _assigns) do
    "Internal server error"
  end

  defp translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, &translate_error/1)
  end
end
