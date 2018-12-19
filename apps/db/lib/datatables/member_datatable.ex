defmodule Innerpeace.Db.Datatables.MemberDatatable do
  @moduledoc """
    Payorlink Index Table
      Rows:
        ID,
        Name,
        Card No ,
        Account,
        Status

    Accountlink Index Table
      Rows:
        ID,
        Name,
        Card No ,
        Type,
        Status,
        Menu rows

    Batch Upload Table
      Rows:
        Batch No,
        Account Type,
        File Name,
        Total Members,
        Processed Members,
        Successful,
        Failed,
        Date Uploaded,
        Date Finished

    Member Document Table
      Rows:
        Batch No,
        Account Type,
        File Name,
        Total Members,
        Processed Members,
        Successful,
        Failed,
        Date Uploaded,
        Date Finished
  """

  import Ecto.Query
  alias Plug.CSRFProtection
  alias Phoenix.View
  alias AccountLinkWeb.MemberView
  alias Innerpeace.Db.{
    Repo,
    Schemas.Member,
    Schemas.Authorization,
    Schemas.MemberDocument,
    Schemas.AccountGroup,
    Schemas.MemberUploadFile,
    Schemas.MemberUploadLog
  }

  def member_count do
    # Returns total count of data without filter and search value.

    initialize_query
    |> select([m, ag], count(m.id))
    |> Repo.one()
  end

  def member_data(
    offset,
    limit,
    search_value,
    order
  ) do
    # Returns table data according to table's offset and limit.

    initialize_query
    |> where([m, ag],
        ilike(fragment("CAST(? AS TEXT)", m.id), ^"%#{search_value}%") or
        ilike(fragment("lower(?)",
    fragment("concat(?, ' ', ?)", m.first_name, m.last_name)),

    ^"%#{search_value}%") or
    ilike(fragment("lower(?)",
    fragment("concat(?, ' ', ?)", m.last_name, m.first_name)),
    ^"%#{search_value}%") or
    ilike(m.card_no, ^"%#{search_value}%") or
    ilike(ag.name, ^"%#{search_value}%") or
    ilike(m.status, ^"%#{search_value}%")
    )
    |> select([m, ag], %{
      id: m.id,
      first_name: m.first_name,
      middle_name: m.middle_name,
      last_name: m.last_name,
      card_no: m.card_no,
      account: ag.name,
      status: m.status,
      step: m.step
    })
    |> order_datatable(
      order["column"],
      order["dir"]
    )
    |> offset(^offset)
    |> limit(^limit)
    |> Repo.all()
    |> insert_table_cols([])
  end

  def member_filtered_count(
    search_value
  ) do
    # Returns count of data filtered according to search value, type, and added id.

    initialize_query
    |> where([m, ag],
        ilike(fragment("CAST(? AS TEXT)", m.id), ^"%#{search_value}%") or
        ilike(fragment("lower(?)",
    fragment("concat(?, ' ', ?)", m.first_name, m.last_name)),

    ^"%#{search_value}%") or
    ilike(fragment("lower(?)",
    fragment("concat(?, ' ', ?)", m.last_name, m.first_name)),
    ^"%#{search_value}%") or
    ilike(m.card_no, ^"%#{search_value}%") or
    ilike(ag.name, ^"%#{search_value}%") or
    ilike(m.status, ^"%#{search_value}%")
    )
    |> select([m, ag], count(m.id))
    |> Repo.one()
  end

  defp order_datatable(query, nil, nil), do: query

  # Ascending
  defp order_datatable(query, column, order) when column == "0" and order == "asc", do: query |> order_by([m, ag], asc: m.id)
  defp order_datatable(query, column, order) when column == "1" and order == "asc", do: query |> order_by([m, ag], asc: m.first_name)
  defp order_datatable(query, column, order) when column == "2" and order == "asc", do: query |> order_by([m, ag], asc: m.card_no)
  defp order_datatable(query, column, order) when column == "3" and order == "asc", do: query |> order_by([m, ag], asc: ag.name)
  defp order_datatable(query, column, order) when column == "4" and order == "asc", do: query |> order_by([m, ag], asc: m.status)

  # Descending
  defp order_datatable(query, column, order) when column == "0" and order == "desc", do: query |> order_by([m, ag], desc: m.id)
  defp order_datatable(query, column, order) when column == "1" and order == "desc", do: query |> order_by([m, ag], desc: m.first_name)
  defp order_datatable(query, column, order) when column == "2" and order == "desc", do: query |> order_by([m, ag], desc: m.card_no)
  defp order_datatable(query, column, order) when column == "3" and order == "desc", do: query |> order_by([m, ag], desc: ag.name)
  defp order_datatable(query, column, order) when column == "4" and order == "desc", do: query |> order_by([m, ag], desc: m.status)

  defp initialize_query do
    # Sets initial query of the table.

    Member
    |> join(:inner, [m], ag in AccountGroup, m.account_code == ag.code)
  end

  defp insert_table_cols([head | tails], tbl) do
    step = head.step
    link = generate_member_link(head.id, step)
    status = head.status
    pending = status_change(head.id, status)

    tbl =
      tbl ++
        [
          [
            link,
            "#{head.first_name} #{head.middle_name} #{head.last_name}",
            head.card_no,
            head.account,
            pending
          ]
        ]

    insert_table_cols(tails, tbl)
  end
  defp insert_table_cols([], tbl), do: tbl

  defp generate_member_link(id, step) when step < 4,
    do:
      "<a href='/web/members/#{id}/setup?step=#{step}'>#{id}(Draft)</a>"

  defp generate_member_link(id, step), do: "<a href='/web/members/#{id}'>#{id}</a>"

  defp status_change(id, status) when status == nil,
    do:
      "<p> Pending for Activation </p>"

  defp status_change(id, status), do: "#{status}"

  def batch_count do
    initialize_batch_query
    |> select([muf, mul], count(muf.id))
    |> Repo.one()
  end

  def batch_data(
    offset,
    limit,
    search_value
  ) do

    search_value = get_search_value(search_value)
    count_val =
    with {val, _} <- search_value
      |> Integer.parse() do
      val
    else
      _ ->
      -1
    end

    initialize_batch_query
    |> where([muf, mul],
      ilike(muf.batch_no, ^"%#{search_value}%") or
      ilike(muf.upload_type, ^"%#{search_value}%") or
      ilike(muf.filename, ^"%#{search_value}%") or
      muf.count == ^count_val or
      ilike(fragment("to_char(?, 'Mon dd, yyyy')", muf.inserted_at), ^"%#{search_value}%") or
      ilike(fragment("to_char(?, 'Mon dd, yyyy')", muf.updated_at), ^"%#{search_value}%")
    )
    |> select([muf, mul], %{
      batch_no: muf.batch_no,
      upload_type: muf.upload_type,
      filename: muf.filename,
      count: muf.count,
      batch_count: muf.count,
      inserted_at: fragment("to_char(?, 'Mon dd, yyyy')", muf.inserted_at),
      updated_at: fragment("to_char(?, 'Mon dd, yyyy')", muf.updated_at),
      id: muf.id
    })
    |> order_by([muf, mul], asc: muf.batch_no)
    |> offset(^offset)
    |> limit(^limit)
    |> Repo.all()
    |> insert_batch_table_cols([])

  end

  def batch_data_account_type_asc(
    offset,
    limit,
    search_value
  ) do
    count_val =
    with {val, _} <- search_value
      |> Integer.parse() do
      val
    else
      _ ->
        -1
    end

    initialize_batch_query
    |> where([muf, mul],
      ilike(muf.batch_no, ^"%#{search_value}%") or
      ilike(muf.upload_type, ^"%#{search_value}%") or
      ilike(muf.filename, ^"%#{search_value}%") or
      muf.count == ^count_val or
      ilike(fragment("to_char(?, 'Mon dd, yyyy')", muf.inserted_at), ^"%#{search_value}%") or
      ilike(fragment("to_char(?, 'Mon dd, yyyy')", muf.updated_at), ^"%#{search_value}%")
    )
    |> select([muf, mul], %{
      batch_no: muf.batch_no,
      upload_type: muf.upload_type,
      filename: muf.filename,
      count: muf.count,
      batch_count: muf.count,
      inserted_at: fragment("to_char(?, 'Mon dd, yyyy')", muf.inserted_at),
      updated_at: fragment("to_char(?, 'Mon dd, yyyy')", muf.updated_at),
      id: muf.id
    })
    |> order_by([muf, mul], asc: muf.upload_type)
    |> offset(^offset)
    |> limit(^limit)
    |> Repo.all()
    |> insert_batch_table_cols([])

  end

  def batch_data_account_type_desc(
    offset,
    limit,
    search_value
  ) do
    count_val =
    with {val, _} <- search_value
      |> Integer.parse() do
      val
    else
      _ ->
        -1
    end

    initialize_batch_query
    |> where([muf, mul],
      ilike(muf.batch_no, ^"%#{search_value}%") or
      ilike(muf.upload_type, ^"%#{search_value}%") or
      ilike(muf.filename, ^"%#{search_value}%") or
      muf.count == ^count_val or
      ilike(fragment("to_char(?, 'Mon dd, yyyy')", muf.inserted_at), ^"%#{search_value}%") or
      ilike(fragment("to_char(?, 'Mon dd, yyyy')", muf.updated_at), ^"%#{search_value}%")
    )
    |> select([muf, mul], %{
      batch_no: muf.batch_no,
      upload_type: muf.upload_type,
      filename: muf.filename,
      count: muf.count,
      batch_count: muf.count,
      inserted_at: fragment("to_char(?, 'Mon dd, yyyy')", muf.inserted_at),
      updated_at: fragment("to_char(?, 'Mon dd, yyyy')", muf.updated_at),
      id: muf.id
    })
    |> order_by([muf, mul], desc: muf.upload_type)
    |> offset(^offset)
    |> limit(^limit)
    |> Repo.all()
    |> insert_batch_table_cols([])

  end

  def batch_data_inserted_at_asc(
    offset,
    limit,
    search_value
  ) do
    count_val =
    with {val, _} <- search_value
      |> Integer.parse() do
      val
    else
      _ ->
        -1
    end

    initialize_batch_query
    |> where([muf, mul],
      ilike(muf.batch_no, ^"%#{search_value}%") or
      ilike(muf.upload_type, ^"%#{search_value}%") or
      ilike(muf.filename, ^"%#{search_value}%") or
      muf.count == ^count_val or
      ilike(fragment("to_char(?, 'Mon dd, yyyy')", muf.inserted_at), ^"%#{search_value}%") or
      ilike(fragment("to_char(?, 'Mon dd, yyyy')", muf.updated_at), ^"%#{search_value}%")
    )
    |> select([muf, mul], %{
      batch_no: muf.batch_no,
      upload_type: muf.upload_type,
      filename: muf.filename,
      count: muf.count,
      batch_count: muf.count,
      inserted_at: fragment("to_char(?, 'Mon dd, yyyy')", muf.inserted_at),
      updated_at: fragment("to_char(?, 'Mon dd, yyyy')", muf.updated_at),
      id: muf.id
    })
    |> order_by([muf, mul], asc: muf.inserted_at)
    |> offset(^offset)
    |> limit(^limit)
    |> Repo.all()
    |> insert_batch_table_cols([])

  end

  def batch_data_inserted_at_desc(
    offset,
    limit,
    search_value
  ) do
    count_val =
    with {val, _} <- search_value
      |> Integer.parse() do
      val
    else
      _ ->
        -1
    end

    initialize_batch_query
    |> where([muf, mul],
      ilike(muf.batch_no, ^"%#{search_value}%") or
      ilike(muf.upload_type, ^"%#{search_value}%") or
      ilike(muf.filename, ^"%#{search_value}%") or
      muf.count == ^count_val or
      ilike(fragment("to_char(?, 'Mon dd, yyyy')", muf.inserted_at), ^"%#{search_value}%") or
      ilike(fragment("to_char(?, 'Mon dd, yyyy')", muf.updated_at), ^"%#{search_value}%")
    )
    |> select([muf, mul], %{
      batch_no: muf.batch_no,
      upload_type: muf.upload_type,
      filename: muf.filename,
      count: muf.count,
      batch_count: muf.count,
      inserted_at: fragment("to_char(?, 'Mon dd, yyyy')", muf.inserted_at),
      updated_at: fragment("to_char(?, 'Mon dd, yyyy')", muf.updated_at),
      id: muf.id
    })
    |> order_by([muf, mul], desc: muf.inserted_at)
    |> offset(^offset)
    |> limit(^limit)
    |> Repo.all()
    |> insert_batch_table_cols([])

  end

  def batch_data_updated_at_asc(
    offset,
    limit,
    search_value
  ) do
    count_val =
    with {val, _} <- search_value
      |> Integer.parse() do
      val
    else
      _ ->
        -1
    end

    initialize_batch_query
    |> where([muf, mul],
      ilike(muf.batch_no, ^"%#{search_value}%") or
      ilike(muf.upload_type, ^"%#{search_value}%") or
      ilike(muf.filename, ^"%#{search_value}%") or
      muf.count == ^count_val or
      ilike(fragment("to_char(?, 'Mon dd, yyyy')", muf.inserted_at), ^"%#{search_value}%") or
      ilike(fragment("to_char(?, 'Mon dd, yyyy')", muf.updated_at), ^"%#{search_value}%")
    )
    |> select([muf, mul], %{
      batch_no: muf.batch_no,
      upload_type: muf.upload_type,
      filename: muf.filename,
      count: muf.count,
      batch_count: muf.count,
      inserted_at: fragment("to_char(?, 'Mon dd, yyyy')", muf.inserted_at),
      updated_at: fragment("to_char(?, 'Mon dd, yyyy')", muf.updated_at),
      id: muf.id
    })
    |> order_by([muf, mul], asc: muf.updated_at)
    |> offset(^offset)
    |> limit(^limit)
    |> Repo.all()
    |> insert_batch_table_cols([])

  end

  def batch_data_updated_at_desc(
    offset,
    limit,
    search_value
  ) do
    count_val =
    with {val, _} <- search_value
      |> Integer.parse() do
      val
    else
      _ ->
        -1
    end

    initialize_batch_query
    |> where([muf, mul],
      ilike(muf.batch_no, ^"%#{search_value}%") or
      ilike(muf.upload_type, ^"%#{search_value}%") or
      ilike(muf.filename, ^"%#{search_value}%") or
      muf.count == ^count_val or
      ilike(fragment("to_char(?, 'Mon dd, yyyy')", muf.inserted_at), ^"%#{search_value}%") or
      ilike(fragment("to_char(?, 'Mon dd, yyyy')", muf.updated_at), ^"%#{search_value}%")
    )
    |> select([muf, mul], %{
      batch_no: muf.batch_no,
      upload_type: muf.upload_type,
      filename: muf.filename,
      count: muf.count,
      batch_count: muf.count,
      inserted_at: fragment("to_char(?, 'Mon dd, yyyy')", muf.inserted_at),
      updated_at: fragment("to_char(?, 'Mon dd, yyyy')", muf.updated_at),
      id: muf.id
    })
    |> order_by([muf, mul], desc: muf.updated_at)
    |> offset(^offset)
    |> limit(^limit)
    |> Repo.all()
    |> insert_batch_table_cols([])

  end

  def batch_filtered_count(
    search_value
  ) do

    search_value = get_search_value(search_value)
    count_val =
    with {val, _} <- search_value
      |> Integer.parse() do
      val
    else
      _ ->
        -1
    end

    initialize_batch_query
    |> where([muf, mul],
      ilike(muf.batch_no, ^"%#{search_value}%") or
      ilike(muf.upload_type, ^"%#{search_value}%") or
      ilike(muf.filename, ^"%#{search_value}%") or
      muf.count == ^count_val or
      ilike(fragment("to_char(?, 'Mon dd, yyyy')", muf.inserted_at), ^"%#{search_value}%") or
      ilike(fragment("to_char(?, 'Mon dd, yyyy')", muf.updated_at), ^"%#{search_value}%")
    )
    |> select([muf, mul], count(muf.id))
    |> Repo.one()
  end

  defp initialize_batch_query do
    MemberUploadFile
    |> where([muf], muf.upload_type in ^["Corporate", "Individual, Family, Group (IFG)", "Change of Plan"])
    #|> join(:left, [muf], mul in MemberUploadLog, mul.member_upload_file_id == muf.id)
  end

  defp insert_batch_table_cols([head | tails], tbl) do

    mul_count = get_mul_count(head.id)
    mul_success = get_mul_success(head, mul_count["success"])
    mul_failed = get_mul_failed(head, mul_count["failed"])

    tbl =
      tbl ++
      [
        [
          head.batch_no,
          head.upload_type,
          head.filename,
          head.count,
          "<span class='total'>#{mul_count['total']}</span>",
          mul_success,
          mul_failed,
          "<span>#{head.inserted_at}</span>",
          "<span>#{head.updated_at}</span>
          <input type='hidden' value='#{head.id}'>"
        ]
      ]
      insert_batch_table_cols(tails, tbl)
  end
  defp insert_batch_table_cols([], tbl), do: tbl

  defp get_mul_count(id) do
    result =
      MemberUploadLog
      |> where([mul], mul.member_upload_file_id == ^id)
      |> select([mul], mul.status)
      |> Repo.all()

    %{
      "success" => Enum.count(result, &(&1 == "success")),
      "failed" => Enum.count(result, &(&1 == "failed")),
      "total" => Enum.count(result)
    }
  end

  defp get_mul_success(logs, count) when count > 0 do
    "
    <span class='mul_success'>#{count}</span>
    #{logs['success']}<br>
    <u><a id='success' style='cursor: pointer' class='member_download_success_button isDisabled' member_upload_logs_id='#{logs.id}' status='success' file_name='#{logs.filename}' type='#{logs.upload_type}' batch_no='#{logs.batch_no}'>Download</a></u>
    "
  end

  defp get_mul_success(logs, count) do
    "
    <span class='mul_success'>#{count}</span> <br>
    <a id='success' class='isDisabled' style='color:#7f8187'>Download</a>
    "
  end

  defp get_mul_failed(logs, count) when count > 0 do
    "
    <span class='mul_failed'>#{count}</span>
    #{logs['failed']}<br>
    <u><a id='failed' style='cursor: pointer' class='member_download_success_button isDisabled' member_upload_logs_id='#{logs.id}' file_name='#{logs.filename}' status='failed' type='#{logs.upload_type}' batch_no='#{logs.batch_no}'>Download</a></u>
    "
  end

  defp get_mul_failed(logs, count) do
    "
    <span class='mul_failed'>#{count}</span> <br>
    <a id='failed' style='color:#7f8187' class='isDisabled'>Download</a>
    "
  end

  #AccountLink Functions
  def accountlink_member_count(ag) do
    # Returns total count of data without filter and search value.

    initialize_query
    |> where([m, ag], ag.id == ^ag.id)
    |> select([m, ag], count(m.id))
    |> Repo.one()
  end

  def accountlink_member_data(
    offset,
    limit,
    search_value,
    ag,
    locale
  ) do
    account = Enum.map(ag.account, & (if &1.status == "Active", do: &1))
    account =
      account
      |> Enum.uniq()
      |> List.delete(nil)
      |> List.first()

    # Returns table data according to table's offset and limit.

    initialize_query
    |> where([m, ag], ag.id == ^ag.id)
    |> where([m, ag],
        ilike(fragment("CAST(? AS TEXT)", m.id), ^"%#{search_value}%") or
        ilike(fragment("lower(?)",
        fragment("concat(?, ' ', ?)", m.first_name, m.last_name)),
        ^"%#{search_value}%") or
        ilike(m.card_no, ^"%#{search_value}%") or
        ilike(ag.name, ^"%#{search_value}%") or
        ilike(m.status, ^"%#{search_value}%")
    )
    |> select([m, ag], m)
    |> offset(^offset)
    |> limit(^limit)
    |> Repo.all()
    |> accountlink_insert_table_cols([], locale, account)
  end

  def accountlink_member_filtered_count(
    search_value,
    ag
  ) do
    # Returns count of data filtered according to search value, type, and added id.

    initialize_query
    |> where([m, ag], ag.id == ^ag.id)
    |> where([m, ag],
        ilike(fragment("CAST(? AS TEXT)", m.id), ^"%#{search_value}%") or
        ilike(fragment("lower(?)",
        fragment("concat(?, ' ', ?)", m.first_name, m.last_name)),
        ^"%#{search_value}%") or
        ilike(m.card_no, ^"%#{search_value}%") or
        ilike(ag.name, ^"%#{search_value}%") or
        ilike(m.status, ^"%#{search_value}%")
    )
    |> select([m, ag], count(m.id))
    |> Repo.one()
  end

  defp accountlink_insert_table_cols([head | tails], tbl, locale, account) do
    link = accountlink_generate_member_link(head.id, head.step)
    pending = status_change(head.id, head.status)

    tbl =
      tbl ++
        [
          [
            link,
            member_full_name(head),
            head.card_no,
            head.type,
            pending,
            menu_rows(head, locale, account)
          ]
        ]

    accountlink_insert_table_cols(tails, tbl, locale, account)
  end
  defp accountlink_insert_table_cols([], tbl, locale, account), do: tbl

  defp accountlink_generate_member_link(id, step) when step < 4 do
    "#{id} (Draft)"
    # "<a href='/#{locale}/members/#{id}/setup?step=#{step}'>#{id}(Draft)</a>"
  end

  defp accountlink_generate_member_link(id, step) do
    "#{id}"
    # "<a href='/#{locale}/members/#{id}'>#{id}</a>"
  end

  defp member_full_name(member) do
    if is_nil(member.middle_name) == false do
      if is_nil(member.suffix) == false do
        "#{member.first_name} #{member.middle_name} #{member.last_name} #{member.suffix}"
      else
        "#{member.first_name} #{member.middle_name} #{member.last_name}"
      end
    else
      if is_nil(member.suffix) == false do
        "#{member.first_name} #{member.last_name} #{member.suffix}"
      else
        "#{member.first_name} #{member.last_name}"
      end
    end
  end

  defp menu_rows(member, locale, account) do
    View.render_to_string(
      MemberView,
      "dropdown_index.html",
      member: member,
      locale: locale,
      account: account
    )

  end

  defp get_search_value(nil), do: ""
  defp get_search_value(search_value), do: search_value

  def member_document_data(offset, limit, search_value, member_id) do
    # Returns table data according to table's offset and limit.
    Member
    |> join(:left, [m], md in MemberDocument, md.member_id == m.id)
    |> where([m, md], m.id == ^member_id)
    |> where([m, md],
      ilike(md.filename, ^"%#{search_value}%") or
      ilike(md.purpose, ^"%#{search_value}%") or
      ilike(md.uploaded_from, ^"%#{search_value}%") or
      ilike(fragment("to_char(?, 'MON DD, YYYY')", md.date_uploaded), ^"%#{search_value}%")
    )
    |> select([m, md], %{
      filename: md.filename,
      purpose: md.purpose,
      uploaded_from: md.uploaded_from,
      date_uploaded: md.inserted_at,
      id: md.id,
      content_type: md.content_type,
      link: md.link,
      uploaded_by: md.uploaded_by,
      authorization_id: md.authorization_id,
    })
    |> offset(^offset)
    |> limit(^limit)
    |> Repo.all()
    |> md_insert_table_cols([])
  end

  def md_filtered_count(search_value, member_id) do
    Member
    |> join(:left, [m], md in MemberDocument, md.member_id == m.id)
    |> where([m, md], m.id == ^member_id)
    |> where([m, md],
      ilike(md.filename, ^"%#{search_value}%") or
      ilike(md.purpose, ^"%#{search_value}%") or
      ilike(md.uploaded_from, ^"%#{search_value}%") or
      ilike(fragment("to_char(?, 'MON DD, YYYY')", md.date_uploaded), ^"%#{search_value}%")
    )
    |> select([m, md], count(md.id))
    |> Repo.one()
  end

  def member_document_count(member_id) do
    Member
    |> join(:left, [m], md in MemberDocument, md.member_id == m.id)
    |> where([m, md], m.id == ^member_id)
    |> select([m, md], count(md.id))
    |> Repo.one()
  end

  defp md_insert_table_cols([head | tails], tbl) do
    tbl =
      tbl ++
        [
          [
            html_elem(head.filename, "b"),
            head.purpose,
            head.uploaded_from,
            head.date_uploaded,
            head.id,
            head.content_type,
            head.link,
            head.uploaded_by,
            head.filename,
            get_loa_no(head.authorization_id)
          ]
        ]

    md_insert_table_cols(tails, tbl)
  end
  defp md_insert_table_cols([], tbl), do: tbl
  defp html_elem(data, element), do: "<#{element} style='color:green;'>#{data}</#{element}>"
  defp get_loa_no(authorization_id), do: Repo.get(Authorization, authorization_id).number
end
