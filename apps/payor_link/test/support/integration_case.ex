defmodule Innerpeace.PayorLink.Web.IntegrationCase do
  use ExUnit.CaseTemplate
  use Hound.Helpers

  using do
    quote do
      use Hound.Helpers

      import Ecto
      import Ecto.Query, only: [from: 2]
      import Innerpeace.PayorLink.Web.Router.Helpers
      import Innerpeace.Db.Factories
      import Innerpeace.PayorLink.Web.IntegrationCase

      alias Innerpeace.Db.Repo

      # The default endpoint for testing
      @endpoint Innerpeace.PayorLink.Web.Endpoint

      hound_session()

      def sign_in(url) do
        navigate_to("http://payorlink-ip-staging.medilink.com.ph/sign_in")

        form = find_element(:name, "LoginValidation")
        username = find_within_element(form, :name, "session[username]")
        password = find_within_element(form, :name, "session[password]")
        submit = find_within_element(form, :tag, "button")

        username |> fill_field("masteradmin")
        password |> fill_field("P@ssw0rd")
        submit |> click()
      end
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Innerpeace.Db.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Innerpeace.Db.Repo, {:shared, self()})
    end

    :ok
  end
end
