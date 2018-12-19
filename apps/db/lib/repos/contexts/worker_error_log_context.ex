defmodule Innerpeace.Db.Base.WorkerErrorLogContext do
  @moduledoc """
  This module provides a user context.
  """

  import Ecto.{Query, Changeset}, warn: false
  alias Innerpeace.{
    Db.Repo,
    Db.Schemas.WorkerErrorLog,
    PayorLink.EmailSmtp,
    PayorLink.Mailer,
  }
  alias Innerpeace.Db.Base.Api.UtilityContext, as: UC

  def insert_log(params) do
    %WorkerErrorLog{}
    |> WorkerErrorLog.changeset(params)
    |> Repo.insert()
  end

  def get_all_logs() do
    WorkerErrorLog
    |> select([w], %{
      id: w.id,
      job_name: w.job_name,
      job_params: w.job_params,
      module_name: w.module_name,
      function_name: w.function_name,
      error_description: w.error_description
    })
    |> where(
      [w],
      fragment(
        "to_char(?::date, 'YYYYMMDD') = to_char((now() - interval '1 day'), 'YYYYMMDD')",
        w.inserted_at
      )
    )
    |> order_by([w], w.inserted_at)
    |> Repo.all()
  end

  def email_error_logs() do
    emails = [
      "shane_delarosa@medilink.com.ph",
      "anton_santiago@medilink.com.ph",
      "raymond_navarro@medilink.com.ph",
      "abby_bahatan@medilink.com.ph",
      "israel_delacruz@medilink.com.ph",
      "janna_delacruz@medilink.com.ph"
      # "esther_go@medilink.com.ph",

    ]

    logs = get_all_logs()

    params = %{
      "params" => %{
        "logs" => logs,
        "emails" => emails
      }
    }

    unless Enum.empty?(logs) do
      with {:ok, response} <- UC.send_error_log_email(params) do
        {:ok, response}
      else
        {:error, response} ->
          {:error, response}
        _ ->
          nil
      end
    end
  end

end
