defmodule AccountLinkWeb.LayoutView do
  use AccountLinkWeb, :view
  import Phoenix.Naming
  alias Innerpeace.Db.Base.AccountContext

  def image_url_for(uploader, path, resource, version \\ :original) do
    sanitize_url uploader.url({path, resource}, version)
  end

  defp sanitize_url("apps/account_link/assets/static" <> url), do: url
  defp sanitize_url(url), do: url  |> String.replace("/apps/account_link/assets/static", "")

  @doc """
  Renders current locale.
  """
  def locale do
    Gettext.get_locale(AccountLinkWeb.Gettext)
  end

  @doc """
  Provides tuples for all alternative languages supported.
  """
  def fb_locales do
    AccountLinkWeb.Gettext.supported_locales
    |> Enum.map(fn l ->
      # Cannot call `locale/0` inside guard clause
      current = locale()
      case l do
        l when l == current -> {"og:locale", l}
        l -> {"og:locale:alternate", l}
      end
    end)
  end

  @doc """
  Provides tuples for all alternative languages supported.
  """
  def language_annotations(conn) do
    locale = locale()
    AccountLinkWeb.Gettext.supported_locales
    |> Enum.reject(fn l -> l == locale end)
    |> Enum.concat(["x-default"])
    |> Enum.map(fn l ->
      case l do
        "x-default" -> {"x-default", localized_url(conn, "")}
        l -> {l, localized_url(conn, "/#{l}")}
      end
    end)
  end

  defp localized_url(conn, alt) do
    # Replace current locale with alternative
    locale = locale()
    path = ~r/\/#{locale}(\/(?:[^?]+)?|$)/
    |> Regex.replace(conn.request_path, "#{alt}\\1")

    Phoenix.Router.Helpers.url(AccountLinkWeb.Router, conn) <> path
  end

  def version do
    Application.spec(:account_link, :vsn)
  end

  def check_peme_product(conn) do
    if conn.assigns.current_user.user_account != nil do
      id = conn.assigns.current_user.user_account.account_group_id
      account_group = AccountContext.get_account_group(id)
      if account_group != nil do
        account = AccountContext.get_account_by_account_group(account_group.id)
        check_peme_product_with_account(account)
      end
    end
  end

  def check_peme_product_with_account(account) do
    if account != nil do
      product =
        Enum.map(account.account_products, & (if &1.product.product_category == "PEME Plan", do: &1))
      product =
        product
        |> Enum.uniq()
        |> List.delete(nil)
        if product == [] do
          false
        else
          true
        end
    end
  end

end
