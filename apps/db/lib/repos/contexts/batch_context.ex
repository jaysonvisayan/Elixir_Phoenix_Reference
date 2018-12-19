defmodule Innerpeace.Db.Base.BatchContext do
  @moduledoc """
  Provides batch-related functions.
  """

  import Ecto.{Query, Changeset}, warn: false
  alias Innerpeace.Db.{
    Repo,
    Schemas.Batch,
    Schemas.Sequence,
    Schemas.Comment,
    Schemas.Facility,
    Schemas.Practitioner,
    Schemas.User,
    Schemas.File,
    Schemas.BatchAuthorizationFile,
    Schemas.BatchAuthorization,
    Schemas.PractitionerFacility,
    Schemas.User,
    Schemas.Authorization,
    Schemas.Member,
    Schemas.AcuSchedule,
    Schemas.AcuScheduleMember,
    Base.CoverageContext,
    Base.AuthorizationContext,
    Schemas.BatchFile
  }
  alias Ecto.Changeset, as: EC

  def get_batch!(id) do
    Batch
    |> Repo.get(id)
    |> Repo.preload([
      :facility,
      :practitioner,
      :created_by,
      [
        batch_authorizations: [
          authorization: [
            :authorization_amounts,
            :member,
            :coverage
          ]
        ]
      ],
      comments: {from(c in Comment, order_by: [desc: c.inserted_at]), [:updated_by, :created_by]},
    ])
  end

  def get_all_batch do
    Batch
    |> Repo.all()
    |> Repo.preload([:facility, :created_by])
  end

  def get_all_batch_authorization do
    BatchAuthorization
    |> Repo.all()
    |> Repo.preload([:authorization])
  end

  def get_all_saved_batch_authorization do
    BatchAuthorization
    |> where([ba], ba.status == "Save")
    |> Repo.all()
    |> Repo.preload([authorization: [:member, :coverage]])
  end

  def create_hb_batch(params, user_id, nil) do
    sequence = get_sequence("batch_no")

    batch_no = batch_no(sequence.number)

    params =
      params
      |> Map.put("batch_no", batch_no)
      |> Map.put("type", "HB")
      |> Map.put("created_by_id", user_id)
      |> Map.put("updated_by_id", user_id)

    batch =
      %Batch{}
      |> Batch.changeset(params)
      |> Repo.insert()

    with {:ok, batch} <- batch do
      insert_comment(batch.id, params["comment"], user_id)
      {:ok, batch}
    end
  end

  def create_hb_batch(params, user_id, batch_no) do
    batch =
      %Batch{}
      |> Batch.changeset(params)
      |> Repo.insert()
    with {:ok, batch} <- batch do
      insert_comment(batch.id, params["comment"], user_id)
      {:ok, batch}
    end
  end

  def update_hb_batch(batch, batch_params, user_id) do
    insert_comment(batch.id, batch_params["comment"], user_id)

    batch
    |> Batch.changeset(batch_params)
    |> Repo.update()

  end

  defp batch_no do
    {year, month, _}  = Ecto.Date.to_erl(Ecto.Date.utc())
    if String.length("#{month}") == 1, do: month = "0#{month}"
    prefix = Enum.join([month, String.slice("#{year}", 2..-1)])
    batch_no = get_batch_no()
    batch_no = if is_nil(batch_no) do
      Enum.join([prefix, "-", "P001000101"])
    else
      data = String.split(batch_no, "-")
      if Enum.count(String.split(Enum.at(data, 1), "P")) < 2 do
        Enum.join([prefix, "-", "P001000101"])
      else
        number = Enum.at(String.split(Enum.at(data, 1), "P"), 1)
        updated_number = Integer.to_string(String.to_integer(number) + 1)
        number = cond do
          String.length(updated_number) == 7 ->
            "00#{updated_number}"
          String.length(updated_number) == 8 ->
            "0#{updated_number}"
          true ->
            updated_number
        end
        Enum.join([prefix, "-", "P", number])
      end
    end
  end

  defp batch_no(number) do
    {year, month, _}  = Ecto.Date.to_erl(Ecto.Date.utc())
    if String.length("#{month}") == 1, do: month = "0#{month}"
    prefix = Enum.join([month, String.slice("#{year}", 2..-1)])
    updated_number = Integer.to_string(String.to_integer(number) + 1)
    number =
      cond do
        String.length(updated_number) == 7 ->
          "00#{updated_number}"
        String.length(updated_number) == 8 ->
          "0#{updated_number}"
        true ->
          updated_number
      end
    Enum.join([prefix, "-", "P", number])
  end

  def create_pf_batch(params, user_id) do
    batch_no = batch_no()
    with nil <- get_batch_no(batch_no()) do
      params =
        params
        |> Map.put("batch_no", batch_no)
        |> Map.put("type", "PF")
        |> Map.put("created_by_id", user_id)
        |> Map.put("updated_by_id", user_id)

      batch =
        %Batch{}
        |> Batch.changeset_pf(params)
        |> Repo.insert()

      with {:ok, batch} <- batch do
        insert_comment(batch.id, params["comment"], user_id)
        {:ok, batch}
      end
    else
      _ ->
       create_pf_batch(params, user_id)
    end
  end

  def update_pf_batch(batch, params, user_id) do
    insert_comment(batch.id, params["comment"], user_id)

    batch
    |> Batch.changeset_pf(params)
    |> Repo.update()
  end

  def get_batch_no(batch_no) do
    Repo.get_by(Batch, batch_no: batch_no)
  end

  def list_facility do
    Facility
    |> where([f], f.status == ^"Affiliated" and f.step == 7)
    |> select([f],
      %{
        "id" => f.id,
        "code" => f.code,
        "name" => f.name,
        "title" => fragment("concat(?,' : ', ?)", f.code, f.name),
        "description" => f.name,
        "line_1" => f.line_1,
        "line_2" => f.line_2,
        "city" => f.city,
        "province" => f.province,
        "region" => f.region,
        "country" => f.country,
        "postal_code" => f.postal_code,
        "phone_no" => f.phone_no,
        "latitude" => f.latitude,
        "longitude" => f.longitude
      })
    |> order_by([f], f.name)
    |> Repo.all()
  end

  def get_facility_address(facility_id) do
    Facility
    |> where([f], f.id == ^facility_id)
    |> select([f], %{
        name: f.name,
        code: f.code,
        line_1: f.line_1,
        line_2: f.line_2,
        city: f.city,
        province: f.province,
        prescription_term: f.prescription_term
       })
    |> Repo.one()
  end

  def get_practitioner_details(practitioner_id) do
    Practitioner
    |> where([f], f.id == ^practitioner_id)
    |> Repo.one()
    |> Repo.preload([
      practitioner_specializations: :specialization
    ])
  end

  def get_affiliated_practitioner(facility_id) do
    PractitionerFacility
    |> where([pf], pf.facility_id == ^facility_id)
    |> Repo.all()
    |> Repo.preload([
      practitioner: [practitioner_specializations: :specialization]
    ])
  end

  def insert_comment(batch_id, comments) do
    if !is_nil(comments) && Enum.empty?(comments) == false do
      Enum.each(comments, fn(comment) ->
        %Comment{}
        |> Comment.changeset(%{batch_id: batch_id, comment: comment})
        |> Repo.insert()
      end)
    end
  end

  def insert_comment(batch_id, comments, user_id) do
    if !is_nil(comments) && Enum.empty?(comments) == false do
      Enum.each(comments, fn(comment) ->
        %Comment{}
        |> Comment.changeset(
          %{
            batch_id: batch_id,
            comment: comment,
            created_by_id: user_id,
            updated_by_id: user_id
          }
        )
        |> Repo.insert()
      end)
    end
  end

  def download_batch(params) do
    if params["search_value"] == "" do
      query = (
        from b in Batch,
        left_join: f in Facility, on: b.facility_id == f.id,
        left_join: u in User, on: b.created_by_id == u.id,
        select: ([
          b.batch_no,
          f.name,
          b.coverage,
          b.type,
          b.status,
          b.aso,
          b.inserted_at,
          u.username
        ])
      )
      Repo.all(query)
    else
    param = params["search_value"]
      query = (
        from b in Batch,
        left_join: f in Facility, on: b.facility_id == f.id,
        left_join: u in User, on: b.created_by_id == u.id,
        where: ilike(b.batch_no, ^("%#{param}%")) or ilike(f.name, ^("%#{param}%")) or
        ilike(b.type, ^("%#{param}%")) or ilike(b.coverage, ^("%#{param}%"))
        or ilike(b.estimate_no_of_claims, ^("%#{param}%")) or ilike(b.status, ^("%#{param}%"))
        or ilike(fragment("to_char(?, 'YYYY-MM-DD')", b.inserted_at), ^("%#{param}%")),
        select: ([
          b.batch_no,
          f.name,
          b.coverage,
          b.type,
          b.status,
          b.aso,
          b.inserted_at,
          u.username
        ])
      )
      Repo.all(query)
    end
  end

  # BATCH AUTHORIZATION

  def get_batch_authorization_by_auth_id(a_id) do
    BatchAuthorization
    |> where([ba], ba.authorization_id == ^a_id)
    |> Repo.one()
    |> Repo.preload([:batch, :authorization])
  end

  def get_batch_authorization_by_ids(a_id, b_id) do
    BatchAuthorization
    |> Repo.get_by(authorization_id: a_id, batch_id: b_id)
  end

  def get_batch_authorization_by_authorization_id(a_id, b_id) do
    BatchAuthorization
    |> where([ba], ba.authorization_id == ^a_id and ba.batch_id != ^b_id)
    |> Repo.one()
  end

  def get_batch_authorization_by_id(a_id, b_id) do
    BatchAuthorization
    |> Repo.get_by!(authorization_id: a_id, batch_id: b_id)
  end

  def get_batch_authorization_file_by_id(batch_authorization_id) do
    BatchAuthorizationFile
    |> where([baf], baf.batch_authorization_id == ^batch_authorization_id)
    |> Repo.all()
    |> Repo.preload([:file])
  end

  def get_batch_authorization_file_by_id_one(batch_authorization_id) do
    BatchAuthorizationFile
    |> where([baf], baf.batch_authorization_id == ^batch_authorization_id)
    |> Repo.one()
    |> Repo.preload([:file])
  end

  def get_a_batch_authorization_file_by_id(batch_authorization_id) do
    BatchAuthorizationFile
    |> Repo.get!(batch_authorization_id)
    |> Repo.preload([:batch_authorization, :file])
  end

  def get_all_batch_authorization_file_by_id(batch_authorization_id) do
    BatchAuthorizationFile
    |> where([baf], baf.batch_authorization_id == ^batch_authorization_id)
    |> Repo.all()
    |> Repo.preload([:batch_authorization, :file])
  end

  def get_a_batch_authorization(batch_authorization_id) do
    BatchAuthorization
    |> where([ba], ba.id == ^batch_authorization_id)
    |> Repo.one()
  end

  def get_file_by_id(file_id) do
    File
    |> Repo.get!(file_id)
  end

  def insert_authorization_file(attrs \\ %{}) do
    %File{}
    |> File.changeset(attrs)
    |> Repo.insert!()
    |> File.changeset_file(attrs)
    |> Repo.update!()
  end

  def create_batch_authorization_file(attrs \\ %{}) do
    %BatchAuthorizationFile{}
    |> BatchAuthorizationFile.changeset(attrs)
    |> Repo.insert()
  end

  def create_batch_authorization_files(params, user_id, files) do
    batch_authorization = get_batch_authorization_by_ids(params["authorization_id"], params["batch_id"])

    batch_files_ids = [] ++ for file <- files do
      insert_authorization_file(file)
    end

    {:ok, batch_authorization} = [] ++ if is_nil(batch_authorization) do
      params =
        params
        |> Map.put("created_by_id", user_id)
        |> Map.put("updated_by_id", user_id)

      %BatchAuthorization{}
      |> BatchAuthorization.changeset(params)
      |> Repo.insert()
    else
      params =
        params
        |> Map.put("created_by_id", batch_authorization.created_by_id)
        |> Map.put("updated_by_id", user_id)

      batch_authorization
      |> BatchAuthorization.changeset(params)
      |> Repo.update()
    end

    batch_files_ids =
      batch_files_ids
      |> Enum.map(&(&1.id))

    for file_id <- batch_files_ids do
      params = %{
        file_id: file_id,
        batch_authorization_id: batch_authorization.id,
        document_type: params["document_type"],
        created_by_id: user_id,
        updated_by_id: user_id
      }

      create_batch_authorization_file(params)
    end

    {:ok, batch_authorization}
  end

  def insert_batch_authorization(params, user_id) do
    batch_authorization = get_batch_authorization_by_ids(params["authorization_id"], params["batch_id"])
    params =
      params
      |> Map.put("created_by_id", user_id)
      |> Map.put("updated_by_id", user_id)

    {:ok, batch_authorization} = [] ++ if is_nil(batch_authorization) do
      %BatchAuthorization{}
      |> BatchAuthorization.changeset(params)
      |> Repo.insert()
    else
      batch_authorization
      |> BatchAuthorization.changeset(params)
      |> Repo.update()
    end

    {:ok, batch_authorization}
  end

  def delete_batch_authorization_file(id) do
    id
    |> get_a_batch_authorization_file_by_id()
    |> Repo.delete()
  end

  def delete_a_batch_authorization_file(batch_authorization_id) do
    if is_nil(get_batch_authorization_file_by_id_one(batch_authorization_id)) do
    else
      batch_authorization_id
      |> get_batch_authorization_file_by_id_one()
      |> Repo.delete()
    end
  end

  def delete_file(id) do
    id
    |> get_file_by_id()
    |> Repo.delete()
  end

  def delete_batch_authorization(a_id, b_id) do
    a_id
    |> get_batch_authorization_by_id(b_id)
    |> Repo.delete()
  end

  def get_batch_authorization_draft do
    BatchAuthorization
    |> where([ba], ba.status == "Add")
    |> select([ba], %{batch_authorization_id: ba.id})
    |> Repo.all()
  end

  def clear_batch_authorization_draft do
    batch_authorization_ids = get_batch_authorization_draft()
    test = for batch_authorization_id <- batch_authorization_ids do
      delete_a_batch_authorization_file(batch_authorization_id.batch_authorization_id)
    end
    BatchAuthorization
    |> where([ba], ba.status == "Add")
    |> Repo.delete_all()
  end

  # END OF BATCH AUTHORIZATION

  def update_batch(batch, params) do
    batch
    |> Batch.changeset(params)
    |> Repo.update()
  end

  def submit_batch(id) do
    batch =
      Batch
      |> where([b], b.id == ^id)
      |> Repo.one
      |> Repo.preload([batch_authorizations: :authorization])

    coverage_ids = for batch_acu <- batch.batch_authorizations do
      batch_acu.authorization.coverage_id
    end
    acu_coverage = CoverageContext.get_coverage_by_name("ACU")
    check_acu_exist = Enum.member?(coverage_ids, acu_coverage.id)

    result = for ba <- batch.batch_authorizations do
      if ba.status == "Save", do: ba, else: nil
    end
    |> Enum.uniq
    |> List.delete(nil)

    if Enum.empty?(result) do
      {:error, "Please add LOA first."}
    else
      batch
      |> Batch.changeset(%{status: "Submitted"})
      |> Repo.update()
    end
  end

  def delete_batch(id) do
    delete_batch_comments(id)

    id
    |> get_batch!()
    |> Repo.delete()
  end

  def delete_batch_comments(batch_id) do
    Comment
    |> where([c], c.batch_id == ^batch_id)
    |> Repo.delete_all()
  end

  def insert_single_comment(batch_id, batch_params, current_user_id) do
    %Comment{}
    |> Comment.changeset(
      %{
        batch_id: batch_id,
        comment: batch_params["comment"],
        created_by_id: current_user_id,
        updated_by_id: current_user_id
      }
    )
    |> Repo.insert()
  end

  def filter_batch_loa(batch_params) do
    batch = get_batch!(batch_params["id"])
    authorizations = AuthorizationContext.list_approved_authorizations()
    batch_authorizations = get_all_saved_batch_authorization()
    if is_nil(batch_authorizations) do
      batch_authorizations = []
    else
      batch_authorizations
    end
    filtered_authorizations = Enum.filter(authorizations, &(&1.facility_id == batch.facility_id))
    filtered_authorizations -- Enum.map(batch_authorizations, &(&1.authorization))
  end

  def create_batch_files(params, user_id) do
    remote_file = params["RemoteFile"]
    name = remote_file.filename
    type = remote_file
    file_params = %{
      name: name,
      type: type
    }

    file =
      %File{}
      |> File.changeset(file_params)
      |> Repo.insert!()
      |> File.changeset_file(file_params)
      |> Repo.update!()

    batch_id = params["id"]
    batch_params = %{
      batch_id: batch_id,
      file_id: file.id,
      created_by_id: user_id,
      updated_by_id: user_id,
      document_type: "SOA"
    }

    batch_file =
      %BatchFile{}
      |> BatchFile.changeset(batch_params)
      |> Repo.insert()
  end

  def get_batch_files_by_batch_id(batch_id) do
    BatchFile
    |> where([bf], bf.batch_id == ^batch_id)
    |> Repo.all()
    |> Repo.preload([:file])
  end

  def get_batch_file(id) do
    BatchFile
    |> Repo.get(id)
    |> Repo.preload([:batch, :file])
  end

  def get_batch_no do
    query =
      from(b in Batch,
      order_by: [desc: b.inserted_at],
      limit: 1,
      select: b.batch_no)
    Repo.one(query)
  end

  def get_sequence(type) do
    query =
      from(s in Sequence,
      order_by: [desc: s.inserted_at],
      limit: 1)

    sequence =
      query
      |> where([s], s.type == ^type)
      |> Repo.one()

    Repo.update(EC.change sequence, number: "#{String.to_integer(sequence.number) + 1}")

    sequence
  end

  def get_batch_by_authorization(authorization_id) do
    Batch
    |> join(:inner, [b], ba in BatchAuthorization, b.id == ba.batch_id)
    |> join(:inner, [b, ba], a in Authorization, ba.authorization_id == a.id)
    |> where([b, ba, a], a.id == ^authorization_id)
    |> distinct([b, ba, a], b.batch_no)
    |> select([b, ba, a], b)
    |> Repo.one()
  end

  def insert_all_batch_authorization(params) do
    BatchAuthorization
    |> Repo.insert_all(params)
  end

  def update_batch_amounts(batch, params) do
    Repo.update(
      EC.change batch,
      edited_soa_amount: params["edited_soa_amount"],
      soa_amount: params["soa_amount"],
      estimate_no_of_claims: params["estimate_no_of_claims"]
      )
  end

  def get_batch_by_batch_no(number) do
    Batch
    |> Repo.get_by(batch_no: number)
  end

end
