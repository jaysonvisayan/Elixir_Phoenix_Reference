defmodule Innerpeace.PayorLink.Web.Api.V1.Migration.MigrationController do
  use Innerpeace.PayorLink.Web, :controller
  import Ecto.{Query, Changeset}, warn: false
  alias Innerpeace.Db.Base.Api.{
    BenefitContext,
    UtilityContext
  }
  alias Innerpeace.Db.Base.{
    MigrationContext
  }

  alias Innerpeace.Worker.Job.{
    BenefitMigrationJob,
    MemberMigrationJob,
    MemberExistingMigrationJob
  }

  alias Innerpeace.Db.Worker.Job.CreateAccountJob

  alias PayorLink.Guardian, as: PG

  def urg_migrate(conn, params) do
    user_id = PG.current_resource_api(conn).id
    with {:valid} <- validate_params(params),
         false <- is_nil(user_id)
    do
      members_count =
        params["members"]
        |> Enum.count()

      {:ok, migration} =
      user_id
      |> MigrationContext.start_of_migration(members_count)

      params =
        params
        |> Map.put("migration_id", migration.id)

      Exq.Enqueuer.start_link
      Exq.Enqueuer
      |> Exq.Enqueuer.enqueue(
        "member_batch_migration_job",
        "Innerpeace.Db.Worker.Job.MemberBatchMigrationJob",
        [params, user_id, members_count])

      url =
        if Application.get_env(:payor_link, :env) == :prod do
          Atom.to_string(conn.scheme) <> "://" <> Innerpeace.PayorLink.Web.Endpoint.struct_url.host
        else
          Innerpeace.PayorLink.Web.Endpoint.url
        end

        render(conn, "link.json", link: "#{url}/migration/#{migration.id}/results")

    else
      {:error, changeset} ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "changeset_error.json", changeset: changeset)

      true ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Please Login Again to refresh Bearer Token")

    end
  end

  defp validate_params(params) do
    dummy_data = %{}
    general_types = %{
      members: {:array, :map}
    }

    changeset =
      {dummy_data, general_types}
      |> Ecto.Changeset.cast(params, Map.keys(general_types))
      |> validate_required([
        :members
      ])

    if changeset.valid? do
      {:valid}
    else
      {:error, changeset}
    end

  end

  ###Migrate member with card_no

  def urg_existing_migrate(conn, params) do
    user_id = PG.current_resource_api(conn).id
    with {:valid} <- validate_uem_params(params),
         false <- is_nil(user_id)
    do
      members_count =
        params["members"]
        |> Enum.count()

      {:ok, migration} =
        user_id
        |> MigrationContext.start_of_migration(members_count)

      params =
        params
        |> Map.put("migration_id", migration.id)

      url =
        if Application.get_env(:payor_link, :env) == :prod do
          Atom.to_string(conn.scheme) <> "://" <> Innerpeace.PayorLink.Web.Endpoint.struct_url.host
        else
          Innerpeace.PayorLink.Web.Endpoint.url
        end

      Exq.Enqueuer.start_link

      Exq.Enqueuer
      |> Exq.Enqueuer.enqueue(
        "member_existing_migration_job",
        "Innerpeace.Db.Worker.Job.MemberExistingBatchMigrationJob",
        ["Member", url, params, members_count])

        render(conn, "links.json", url: url, migration_id: migration.id)

    else
      {:error, changeset} ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "changeset_error.json", changeset: changeset)

      true ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Please Login Again to refresh Bearer Token")

    end
  end

  def urg_existing_migrate_v2(conn, params) do
    urg_existing_migrate(conn, Map.put(params, "version", "v2"))
  end

  defp validate_uem_params(params) do
    dummy_data = %{}
    general_types = %{
      members: {:array, :map}
    }

    changeset =
      {dummy_data, general_types}
      |> Ecto.Changeset.cast(params, Map.keys(general_types))
      |> validate_required([
        :members
      ])

    if changeset.valid? do
      {:valid}
    else
      {:error, changeset}
    end
  end
  ### for APD's
  def benefit_migrate(conn, params) do
    user = PG.current_resource_api(conn)
    with false <- is_nil(user),
         {:valid} <- validate_benefit_params(params)
    do
      benefits_count =
        params["benefits"]
        |> Enum.count()

      module = "Benefit"

      {:ok, migration} =
        user.id
      |> MigrationContext.start_post(module)

      params =
        params
        |> Map.put("migration_id", migration.id)


      url =
        if Application.get_env(:payor_link, :env) == :prod do
          Atom.to_string(conn.scheme) <> "://" <> Innerpeace.PayorLink.Web.Endpoint.struct_url.host
        else
          Innerpeace.PayorLink.Web.Endpoint.url
        end

      Exq.Enqueuer.start_link

      Exq.Enqueuer
      |> Exq.Enqueuer.enqueue(
        "benefit_batch_migration_job",
        "Innerpeace.Db.Worker.Job.BenefitBatchMigrationJob",
        ["Benefit", url, params, user.id, benefits_count])

        render(conn, "link.json", link: "#{url}/migration/#{migration.id}/results")

    else
      {:error, changeset} ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "changeset_error.json", changeset: changeset)

      true ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Please Login Again to refresh Bearer Token")

    end
  end

  defp validate_benefit_params(params) do
    dummy_data = %{}
    general_types = %{
      benefits: {:array, :map}
    }

    changeset =
      {dummy_data, general_types}
      |> Ecto.Changeset.cast(params, Map.keys(general_types))
      |> validate_required([
        :benefits
      ])

    if changeset.valid? do
      {:valid}
    else
      {:error, changeset}
    end

  end

  def product_migrate(conn, params) do
    user_id = PG.current_resource_api(conn).id
    with {:valid} <- validate_product_params(params),
         false <- is_nil(user_id)
    do
      products_count =
        params["products"]
        |> Enum.count()

      module = "Product"

      {:ok, migration} =
        user_id
        |> MigrationContext.start_post(module)

      params =
        params
        |> Map.put("migration_id", migration.id)

      url =
        if Application.get_env(:payor_link, :env) == :prod do
          Atom.to_string(conn.scheme) <> "://" <> Innerpeace.PayorLink.Web.Endpoint.struct_url.host
        else
          Innerpeace.PayorLink.Web.Endpoint.url
        end

      Exq.Enqueuer.start_link

      Exq.Enqueuer
      |> Exq.Enqueuer.enqueue(
        "product_batch_migration_job",
        "Innerpeace.Db.Worker.Job.ProductBatchMigrationJob",
        ["Product", url, params, user_id, products_count])

        render(conn, "link.json", link: "#{url}/migration/#{migration.id}/results")

    else
      {:error, changeset} ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "changeset_error.json", changeset: changeset)

      true ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Please Login Again to refresh Bearer Token")

    end
  end

  defp validate_product_params(params) do
    dummy_data = %{}
    general_types = %{
      products: {:array, :map}
    }

    changeset =
      {dummy_data, general_types}
      |> Ecto.Changeset.cast(params, Map.keys(general_types))
      |> validate_required([
        :products
      ])

    if changeset.valid? do
      {:valid}
    else
      {:error, changeset}
    end

  end

  def account_migrate(conn, params) do
    user_id = PG.current_resource_api(conn).id
    with {:valid} <- validate_account_params(params),
         false <- is_nil(user_id)
    do
      accounts_count =
        params["accounts"]
        |> Enum.count()

      module = "Account"

      {:ok, migration} =
        user_id
      |> MigrationContext.start_post(module)

      params =
        params
        |> Map.put("migration_id", migration.id)

      url =
        if Application.get_env(:payor_link, :env) == :prod do
          Atom.to_string(conn.scheme) <> "://" <> Innerpeace.PayorLink.Web.Endpoint.struct_url.host
        else
          Innerpeace.PayorLink.Web.Endpoint.url
        end

      Exq.Enqueuer.start_link

      Exq.Enqueuer
      |> Exq.Enqueuer.enqueue(
        "account_migration_job",
        "Innerpeace.Db.Worker.Job.AccountMigrationJob",
         ["Account", url, params, user_id, accounts_count])

        conn
        |> render("link.json", link: "#{url}/migration/#{migration.id}/results")

    else
      {:error, changeset} ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "changeset_error.json", changeset: changeset)

      true ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Please Login Again to refresh Bearer Token")

    end
  end

  defp validate_account_params(params) do
    dummy_data = %{}
    general_types = %{
      accounts: {:array, :map}
    }

    changeset =
      {dummy_data, general_types}
      |> Ecto.Changeset.cast(params, Map.keys(general_types))
      |> validate_required([
        :accounts
      ])

    if changeset.valid? do
      {:valid}
    else
      {:error, changeset}
    end
  end

  # Public: API for creating a single account
  #
  # url: api/v1/accounts
  # method: POST
  #
  # parameters:
  # conn - API connection
  # params - JSON parameters to create an account in {"params": {"column": "value"}} format.
  #
  # Example
  # account_single_migration(%{Plug.conn{}}, %{params => %{"data" => "val"}})
  #
  # Returns json response

  def account_single_migration(conn, params) do
    user_id = PG.current_resource_api(conn).id
    with {:valid} <- validate_single_account_params(params),
         false <- is_nil(user_id)
    do
      accounts_count =
        params
        |> Enum.count()

      {:ok, migration} =
        user_id
      |> MigrationContext.start_post("Account")

      params =
        params
        |> Map.put("migration_id", migration.id)

      Exq.Enqueuer.start_link

      Exq.Enqueuer
      |> Exq.Enqueuer.enqueue(
        "account_single_migration_job",
        "Innerpeace.Db.Worker.Job.AccountSingleMigrationJob",
        [params, user_id, accounts_count])

      url =
        if Application.get_env(:payor_link, :env) == :prod do
          Atom.to_string(conn.scheme) <> "://" <> Innerpeace.PayorLink.Web.Endpoint.struct_url.host
        else
          Innerpeace.PayorLink.Web.Endpoint.url
        end

        conn
        |> render("link.json", link: "#{url}/migration/#{migration.id}/result/#{accounts_count}")
    else
      {:error, changeset} ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "changeset_error.json", changeset: changeset)

      true ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Please Login Again to refresh Bearer Token")

    end
  end

  defp validate_single_account_params(params) do
    dummy_data = %{}
    general_types = %{
      params: :map
    }

    changeset =
      {dummy_data, general_types}
      |> Ecto.Changeset.cast(params, Map.keys(general_types))
      |> validate_required([
        :params
      ])

    if changeset.valid? do
      {:valid}
    else
      {:error, changeset}
    end
  end

end

