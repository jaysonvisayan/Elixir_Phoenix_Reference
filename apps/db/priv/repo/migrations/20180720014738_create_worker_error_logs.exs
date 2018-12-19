defmodule Innerpeace.Db.Repo.Migrations.CreateWorkerErrorLogs do
  use Ecto.Migration

  def change do
    create table(:worker_error_logs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :job_name, :string
      add :job_params, :text
      add :module_name, :string
      add :function_name, :string
      add :error_description, :string

      timestamps()
    end
  end
end
