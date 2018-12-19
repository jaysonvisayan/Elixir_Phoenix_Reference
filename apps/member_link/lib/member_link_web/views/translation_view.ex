defmodule MemberLinkWeb.TranslationView do
  use MemberLinkWeb, :view

  def render("translation.json", %{translations: translations}) do
    for translation <- translations do
      %{
        base_value: translation.base_value,
        translated_value: translation.translated_value,
        language: translation.language
      }
    end
  end

end
