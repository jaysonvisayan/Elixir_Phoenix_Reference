defmodule Innerpeace.Db.Datatables.AcuScheduleDatatable do
  @moduledoc false

  import Ecto.{
      Query,
      Changeset
  }, warn: false

  alias Innerpeace.Db
  alias Innerpeace.Db.{
    Repo,
    Schemas.AcuSchedule,
    Schemas.AcuScheduleMember,
    Schemas.Account,
    Schemas.AccountGroup,
    Schemas.AccountProduct,
    Schemas.Product,
    Schemas.Member,
    Schemas.MemberProduct,
    Schemas.AccountProductBenefit,
    Schemas.ProductBenefit,
    Schemas.Benefit,
    Schemas.BenefitPackage,
    Schemas.Package,
    Schemas.PackageFacility,
    Schemas.AcuScheduleProduct
  }


  def new_get_clean_asm_count(params, acu_schedule_id) do
    AcuScheduleMember
    |> join(:left, [asm], m in Member, m.id == asm.member_id)
    |> join(:left, [asm, m], as in AcuSchedule, as.id == asm.acu_schedule_id)
    |> where([asm, m, as], asm.acu_schedule_id == ^acu_schedule_id and is_nil(asm.status))
    |> where(
      [asm, m, as],
      ilike(m.card_no, ^"%#{params}%") or
      ilike(m.gender, ^"%#{params}%") or
      ilike(asm.package_code, ^"%#{params}%") or
      ilike(fragment("lower(?)", fragment("concat(?, ' ', ?)", m.first_name, m.last_name)), ^"%#{params}%") or
      ilike(fragment("TO_CHAR(?, 'yyyy-mm-dd')", m.birthdate), ^"%#{params}%") or
      ilike(fragment("EXTRACT(year FROM age(current_date,?)) :: int :: text", m.birthdate), ^"%#{params}%") or
      ilike(m.card_no, ^"%#{params}%")
    )
    |> select([asm, m, as], %{id: asm.id, member_id: m.id, card_no: m.card_no, first_name: m.first_name, middle_name: m.middle_name, last_name: m.last_name, gender: m.gender, birthdate: m.birthdate, package: asm.package_code, status: asm.status})
    |> Repo.all()
    |> Enum.count()
  end

  def new_get_clean_asm(offset, limit, params, acu_schedule_id) do
    AcuScheduleMember
    |> join(:left, [asm], m in Member, m.id == asm.member_id)
    |> join(:left, [asm, m], as in AcuSchedule, as.id == asm.acu_schedule_id)
    |> where([asm, m, as], asm.acu_schedule_id == ^acu_schedule_id and is_nil(asm.status))
    |> where(
      [asm, m, as],
      ilike(m.card_no, ^"%#{params}%") or
      ilike(m.gender, ^"%#{params}%") or
      ilike(asm.package_code, ^"%#{params}%") or
      ilike(fragment("lower(?)", fragment("concat(?, ' ', ?)", m.first_name, m.last_name)), ^"%#{params}%") or
      ilike(fragment("TO_CHAR(?, 'yyyy-mm-dd')", m.birthdate), ^"%#{params}%") or
      ilike(fragment("EXTRACT(year FROM age(current_date,?)) :: int :: text", m.birthdate), ^"%#{params}%") or
      ilike(m.card_no, ^"%#{params}%")
    )
    |> select([asm, m, as], %{id: asm.id, member_id: m.id, card_no: m.card_no, first_name: m.first_name, middle_name: m.middle_name, last_name: m.last_name, gender: m.gender, birthdate: m.birthdate, package: asm.package_code, status: asm.status})
    |> offset(^offset)
    |> limit(^limit)
    |> Repo.all
    |> convert_to_tbl_cols([])
  end

  ##
  def new_get_clean_removed_asm_count(params, acu_schedule_id) do
    AcuScheduleMember
    |> join(:left, [asm], m in Member, m.id == asm.member_id)
    |> where([asm, m, as, asp, mp, ap, pr, pb, b, bp, p], asm.acu_schedule_id == ^acu_schedule_id and asm.status == ^"removed")
    |> where(
      [asm, m],
      ilike(m.card_no, ^"%#{params}%") or
      ilike(m.gender, ^"%#{params}%") or
      ilike(asm.package_code, ^"%#{params}%") or
      ilike(fragment("lower(?)", fragment("concat(?, ' ', ?)", m.first_name, m.last_name)), ^"%#{params}%") or
      ilike(m.card_no, ^"%#{params}%") or
      ilike(fragment("to_char(?, 'YYYY-MM-DD')", m.birthdate), ^"%#{params}%") or
      ilike(fragment("to_char(extract(year from age(cast(? as date))), ?)", m.birthdate, "9999"), ^"%#{params}%")
    )
    |> order_by([asm, m], asm.id)
    |> select([asm, m], %{
      id: asm.id,
      member_id: m.id,
      card_no: m.card_no,
      first_name: m.first_name,
      middle_name: m.middle_name,
      last_name: m.last_name,
      gender: m.gender,
      birthdate: m.birthdate,
      package: asm.package_code,
      status: asm.status
    })
    |> Repo.all()
    |> Enum.count()
  end

  ##
  def new_get_clean_removed_asm(offset, limit, params, acu_schedule_id) do
    AcuScheduleMember
    |> join(:left, [asm], m in Member, m.id == asm.member_id)
    |> where([asm, m, as, asp, mp, ap, pr, pb, b, bp, p], asm.acu_schedule_id == ^acu_schedule_id and asm.status == ^"removed")
    |> where(
      [asm, m],
      ilike(m.card_no, ^"%#{params}%") or
      ilike(m.gender, ^"%#{params}%") or
      ilike(asm.package_code, ^"%#{params}%") or
      ilike(fragment("lower(?)", fragment("concat(?, ' ', ?)", m.first_name, m.last_name)), ^"%#{params}%") or
      ilike(m.card_no, ^"%#{params}%") or
      ilike(fragment("to_char(?, 'YYYY-MM-DD')", m.birthdate), ^"%#{params}%") or
      ilike(fragment("to_char(extract(year from age(cast(? as date))), ?)", m.birthdate, "9999"), ^"%#{params}%")
    )
    |> order_by([asm, m], asm.id)
    |> select([asm, m], %{
      id: asm.id,
      member_id: m.id,
      card_no: m.card_no,
      first_name: m.first_name,
      middle_name: m.middle_name,
      last_name: m.last_name,
      gender: m.gender,
      birthdate: m.birthdate,
      package: asm.package_code,
      status: asm.status
    })
    |> offset(^offset)
    |> limit(^limit)
    |> Repo.all
    |> convert_to_tbl_asm_removed_cols([])
  end

  def new_get_clean_asm_show(offset, limit, params, acu_schedule_id) do
    AcuScheduleMember
    |> join(:left, [asm], m in Member, m.id == asm.member_id)
    |> join(:left, [asm, m], as in AcuSchedule, as.id == asm.acu_schedule_id)
    |> where([asm, m, as], asm.acu_schedule_id == ^acu_schedule_id and is_nil(asm.status))
    |> where(
      [asm, m, as],
      ilike(m.card_no, ^"%#{params}%") or
      ilike(m.gender, ^"%#{params}%") or
      ilike(asm.package_code, ^"%#{params}%") or
      ilike(fragment("lower(?)", fragment("concat(?, ' ', ?)", m.first_name, m.last_name)), ^"%#{params}%") or
      ilike(fragment("TO_CHAR(?, 'yyyy-mm-dd')", m.birthdate), ^"%#{params}%") or
      ilike(fragment("EXTRACT(year FROM age(current_date,?)) :: int :: text", m.birthdate), ^"%#{params}%") or
      ilike(m.card_no, ^"%#{params}%")
    )
    |> select([asm, m, as], %{id: asm.id, member_id: m.id, card_no: m.card_no, first_name: m.first_name, middle_name: m.middle_name, last_name: m.last_name, gender: m.gender, birthdate: m.birthdate, package: asm.package_code, status: asm.status})
    |> offset(^offset)
    |> limit(^limit)
    |> Repo.all
    |> convert_to_tbl_cols([])
  end

  defp convert_to_tbl_cols([head | tails], tbl) do
    delete_button = generate_delete_button(head.id)
    tbl =
      tbl ++ [[
        #head.member_id <> "|" <> head.card_no,
        "<a href='/web/members/#{head.member_id}'>#{head.card_no}</a>",
        Enum.join([head.first_name, head.middle_name, head.last_name], " "),
        head.gender,
        head.birthdate,
        get_age(head.birthdate),
        head.package,
        delete_button
      ]]

    convert_to_tbl_cols(tails, tbl)
  end
  defp convert_to_tbl_cols([], tbl), do: tbl

  defp generate_delete_button(id),
    do:
      "<a class='clickable-row asm_update_status' asm_id='#{id}' id='asm_update_status' ><i class='red trash icon'></i></a>"

  defp convert_to_tbl_asm_removed_cols([head | tails], tbl) do
    # checkbox = generate_checkbox(head)
    tbl =
      tbl ++ [[
        head.id,
        head.card_no,
        Enum.join([head.first_name, head.middle_name, head.last_name], " "),
        head.gender,
        head.birthdate,
        get_age(head.birthdate),
        head.package
      ]]

      convert_to_tbl_asm_removed_cols(tails, tbl)
  end
  defp convert_to_tbl_asm_removed_cols([], tbl), do: tbl

  def get_age(date) do
    year_of_date = to_string(date)
    year_today =  Date.utc_today
    year_today = to_string(year_today)
    datediff1 = Timex.parse!(year_of_date, "%Y-%m-%d", :strftime)
    datediff2 = Timex.parse!(year_today, "%Y-%m-%d", :strftime)
    diff_in_years = Timex.diff(datediff2, datediff1, :years)
    diff_in_years
  end

  defp generate_checkbox(data),
    do:
    "<input id='#{data.id}' type='checkbox' value='#{data.id}' card_no='#{data.card_no}' fullname='#{Enum.join([data.first_name, data.middle_name, data.last_name], " ")}' package_code='#{data.package}' class='selection'>"
end
