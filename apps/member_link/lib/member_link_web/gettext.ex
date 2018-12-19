defmodule MemberLinkWeb.Gettext do
  @moduledoc """
  A module providing Internationalization with a gettext-based API.

  By using [Gettext](https://hexdocs.pm/gettext),
  your module gains a set of macros for translations, for example:

      import MemberLinkWeb.Gettext

      # Simple translation
      gettext "Here is the string to translate"

      # Plural translation
      ngettext "Here is the string to translate",
               "Here are the strings to translate",
               3

      # Domain-based translation
      dgettext "errors", "Here is the error message to translate"

  See the [Gettext Docs](https://hexdocs.pm/gettext) for detailed usage.
  """
  use Gettext, otp_app: :member_link

  def supported_locales do
    known = Gettext.known_locales(MemberLinkWeb.Gettext)
    allowed = config[:locales]

    locales = Set.intersection(Enum.into(known, HashSet.new), Enum.into(allowed, HashSet.new))
    locales =
      locales
      |> Set.to_list
  end

  defp config, do: Application.get_env(:member_link, __MODULE__)
end
