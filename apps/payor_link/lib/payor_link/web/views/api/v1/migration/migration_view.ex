defmodule Innerpeace.PayorLink.Web.Api.V1.Migration.MigrationView do
  use Innerpeace.PayorLink.Web, :view

  alias Innerpeace.Db.Repo

  def render("worker.json", %{message: message}) do
    %{
      message: message
    }
  end

  def render("link.json", %{link: link}) do
    %{
      link: link
    }
  end

  def render("links.json", %{url: url, migration_id: migration_id}) do
    %{
      json_link: "#{url}/migration/#{migration_id}/json/result",
      web_page_link: "#{url}/migration/#{migration_id}/results"
    }
  end

end
