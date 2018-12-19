defmodule MemberLinkWeb.LayoutView do
  use MemberLinkWeb, :view
  import Phoenix.Naming
  alias MemberLink.Guardian, as: MG

  @doc """
  Renders current locale.
  """
  def locale do
    Gettext.get_locale(MemberLinkWeb.Gettext)
  end

  @doc """
  Provides tuples for all alternative languages supported.
  """
  def fb_locales do
    MemberLinkWeb.Gettext.supported_locales
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
    MemberLinkWeb.Gettext.supported_locales
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

    Phoenix.Router.Helpers.url(MemberLinkWeb.Router, conn) <> path
  end

  def image_url_for(uploader, path, resource, version \\ :original) do
    sanitize_url uploader.url({path, resource}, version)
  end

  defp sanitize_url("apps/member_link/assets/static" <> url), do: url
  defp sanitize_url(url), do: url  |> String.replace("/apps/member_link/assets/static", "")


  def file_url_for(file, id) do
    if is_nil(file) do
      "None"
    else
      "/uploads/files/#{id}/#{file.file_name}"
    end
  end

  def version do
    Application.spec(:member_link, :vsn)
  end

  def get_img_url(member) do
    Innerpeace.ImageUploader
    |> MemberLinkWeb.LayoutView.image_url_for(member.photo, member, :original)
    |> String.replace("/apps/member_link/assets/static", "")
  end

  def member_image_load(user) do
    user
    |> Innerpeace.Db.Repo.preload(:member)
  end

  def current_user(conn) do
    MG.current_resource(conn)
  end
end
