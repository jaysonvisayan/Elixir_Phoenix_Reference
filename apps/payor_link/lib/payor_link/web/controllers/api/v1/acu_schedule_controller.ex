defmodule Innerpeace.PayorLink.Web.Api.V1.AcuScheduleController do
  @moduledoc false

  use Innerpeace.PayorLink.Web, :controller
  alias Ecto.Changeset

  alias Innerpeace.Db.{
    Schemas.Batch,
    Repo,
    Base.AcuScheduleContext,
    Base.BatchContext,
    Base.AuthorizationContext,
    Base.Api.UtilityContext,
    Schemas.AcuSchedule
  }
  alias Innerpeace.Db.Base.Api.AcuScheduleContext, as: ApiAcuScheduleContext
  alias Innerpeace.Db.Base.Api.AuthorizationContext, as: ApiAuthorizationContext
  alias Innerpeace.Db.Parsers.{
    MemberParser
  }
  alias PayorLink.Guardian

  def create_schedule_api(conn, %{"params" => params}) do
    user = Guardian.current_resource(conn)
    AcuScheduleContext.view_acu_schedule_api(conn, user.id, params)
  end

  def acu_schedule_create_batch(conn, params) do
    user = Guardian.current_resource_api(conn)
    with nil <- BatchContext.get_batch_by_batch_no(params["batch_no"]),
         as = %AcuSchedule{} <- ApiAcuScheduleContext.get_acu_schedule_by_batch_no(params["as_batch_no"]),
         {:ok, batch} <- create_batch_for_acu_schedule(user, as, params)
    do
      create_batch_authorizations(as, params, batch, user)
      ApiAuthorizationContext.update_all_authorization_to_availed(params["verified_ids"])
      ApiAuthorizationContext.update_all_authorization_to_forfeited(params["forfeited_ids"])
      create_batch_claims(as, params, batch, user)
      attached_batch_in_acu_schedule(as, batch)
      if Application.get_env(:db, :env) != :test do
        ApiAuthorizationContext.create_claim_in_providerlink(batch.batch_no, "")
      end

      conn
      |> put_status(200)
      |> render(Innerpeace.PayorLink.Web.Api.V1.StatusView, "success.json")
    else
      nil ->
      conn
      |> put_status(404)
      |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: "Acu Schedule not found")
      %Batch{} = batch ->
      conn
      |> put_status(400)
      |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: "Duplicate batch number has been found.")
      _ ->
      conn
      |> put_status(400)
      |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: "Error creating batch")
    end
  rescue
    _ ->
      conn
      |> put_status(400)
      |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: "Error encountered when creating batch. Please try again later!")
  end

  defp create_batch_for_acu_schedule(user, as, params) do
    date_due = Date.add(Date.utc_today(), 1)
    {:ok, date_received} = Ecto.Date.cast(Date.utc_today() |> Date.to_erl)
    {:ok, date_due} = Ecto.Date.cast(date_due |> Date.to_erl)
    batch_params =
      %{
        "batch_no" => params["batch_no"],
        "type" => "HB",
        "date_received" => date_received,
        "date_due" => date_due,
        "facility_id" => as.facility_id,
        "coverage" => "ACU",
        "soa_ref_no" => params["soa_ref_no"],
        "soa_amount" => params["soa_amount"],
        "edited_soa_amount" => params["edited_soa_amount"],
        "estimate_no_of_claims" => params["estimate_no_of_claims"],
        "mode_of_receiving" => "Sample 1",
        "status" => "Submitted",
        "acu_schedule_id" => as.id
      }
    BatchContext.create_hb_batch(batch_params, user.id, params["batch_no"])
  end

  defp create_batch_authorizations(as, params, batch, user) do
    #65535 maximum parameters can handle insert_all
    batch_loa_params =
      Enum.map(params["verified_ids"], fn(auth_id) ->
          %{
            authorization_id: auth_id,
            batch_id: batch.id,
            inserted_at: Ecto.DateTime.utc(),
            updated_at: Ecto.DateTime.utc(),
            created_by_id: user.id,
            updated_by_id: user.id
          }
      end)

    batch_loa_count =
      batch_loa_params
      |> Enum.count()

    if batch_loa_count > 10000 do
      lists =
        batch_loa_params
        |> UtilityContext.partition_list(10000, [])

      Enum.map(lists, fn(x) ->
        BatchContext.insert_all_batch_authorization(x)
      end)
    else
      BatchContext.insert_all_batch_authorization(batch_loa_params)
    end
  end

  defp create_batch_claims(as, params, batch, user) do
    #65535 maximum parameters can handle insert_all
    authorizations =  ApiAuthorizationContext.get_authorization_by_list_ids(params["verified_ids"])
    claim_params =
      Enum.map(authorizations, fn(auth) ->
        record = auth

        map = claim_key(auth)
        acu_p = get_auth_packages(record)
        auth_d = get_auth_diagnosis(record)
        auth_pr = get_auth_procedure(record)

        map
        |> Map.put(:authorization_id, auth.id)
        |> Map.put(:batch_no, batch.batch_no)
      end)

    claims_count =
      claim_params
      |> Enum.count()

    if claims_count >= 2000 do
     lists =
      claim_params
      |> UtilityContext.partition_list(1999, [])

      Enum.map(lists, fn(x) ->
        ApiAuthorizationContext.insert_all_claim(claim_params)
      end)
    else
        ApiAuthorizationContext.insert_all_claim(claim_params)
    end
  end

  defp claim_key(map) do
    Map.take(map,
             [:status,
              :version,
              :step,
              :admission_datetime,
              :number,
              :valid_until,
              :origin,
              :approved_datetime,
              :transaction_no,
              :is_claimed?,
              :created_by_id,
              :updated_by_id,
              :inserted_at,
              :updated_at,
              :batch_no,
              :approved_by_id,
              :member_id,
              :facility_id,
              :coverage_id]
    )
  end

  defp drop_keys(map) do
    Map.drop(map, [
      :__struct__,
      :id,
      :coverage,
      :batch_authorization,
      :authorization_amounts,
      :logs,
      :authorization_files,
      :authorization_benefit_packages
    ])
  end

  defp get_auth_packages(package) do
    package.authorization_benefit_packages
    |> Enum.map(&(&1.benefit_package))
    |> List.flatten()
    |> Enum.map(&(&1.package))
    |> List.flatten()
    |> Enum.uniq_by(&(&1.id))
    |> auth_packages
  end

  defp auth_packages(packages) do
    packages
    |> Enum.map(fn(package) ->
       %{
        code:  package.code,
        name: package.name,
        package_id: package.id
       }
    end)
  end

  defp get_auth_diagnosis(diagnosis) do
    diagnoses = diagnosis.authorization_diagnosis
                |> Enum.map(&(&1.diagnosis))
                |> Enum.uniq_by(&(&1.id))
                |> List.flatten()

    diagnoses
    |> Enum.map(fn(d) ->
      %{
        code: d.code,
        name: d.name,
        diagnosis_id: d.id,
        type: d.type,
        group_description: d.group_description,
        description: d.description,
        congenital: d.congenital,
        group_code: d.group_code,
      }
    end)
  end

  defp get_auth_procedure(package) do
    package.authorization_benefit_packages
    |> Enum.map(&(&1.benefit_package))
    |> List.flatten()
    |> Enum.map(&(&1.package))
    |> List.flatten()
    |> Enum.map(&(&1.package_payor_procedure))
    |> List.flatten()
    |> Enum.map(&(&1.payor_procedure))
    |> List.flatten()
    |> Enum.map(&(&1.procedure))
    |> Enum.uniq_by(&(&1.code))
    |> auth_procedure
  end

  defp auth_procedure(procedures) do
    procedures
    |> Enum.map(fn(p) ->
      %{
        code: p.code,
        type: p.type,
        description: p.description,
        procedure_id: p.id
      }
    end)
  end

  defp attached_batch_in_acu_schedule(acu_schedule, batch) do
    Repo.update(Changeset.change acu_schedule, status: "Submitted", batch_id: batch.id)
  end

  def acu_schedule_member_upload_image(conn, params) do
    user = Guardian.current_resource_api(conn)
    photo_file = %{
      "file_name" => params["file_name"],
      "base_64_encoded" => params["base_64_encoded"],
      "content_type" => params["content_type"],
      "extension" => params["extension"]
    }
    member_photo(params["member_id"], photo_file, user)
    conn
    |> put_status(200)
    |> render(Innerpeace.PayorLink.Web.Api.V1.StatusView, "success.json")
  rescue
    _ ->
      conn
      |> put_status(400)
      |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: "Error uploading ACU schedule member image.")
  end

  defp member_photo(nil, nil, user), do: nil
  defp member_photo(member_id, nil, user), do: nil
  defp member_photo(nil, photo_file, user), do: nil
  defp member_photo(member_id, photo_file, user) do
    MemberParser.upload_a_photo(member_id, photo_file, user)
  end
end
