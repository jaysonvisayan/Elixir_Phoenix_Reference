defmodule Innerpeace.Db.Schemas.WorkerErrorLog do
  use Innerpeace.Db.Schema

  schema "worker_error_logs" do
    field :job_name, :string
    field :job_params, :string
    field :module_name, :string
    field :function_name, :string
    field :error_description, :string

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :job_name,
      :job_params,
      :module_name,
      :function_name,
      :error_description
    ])
  end
end
