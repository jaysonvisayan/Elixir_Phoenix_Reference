defmodule Innerpeace.Db.Base.ProcedureContext do
  @moduledoc false

  import Ecto.{Query}, warn: false
  alias Innerpeace.Db.{
    Repo,
    Schemas.Procedure,
    Schemas.PayorProcedure,
    Schemas.Payor,
    Schemas.ProcedureLog,
    Schemas.User,
    Schemas.FacilityPayorProcedure,
    Schemas.FacilityRoomRate,
    Parsers.ProcedureParser,
    # Schemas.PayorProcedureUploadLog,
    # Schemas.PayorProcedureUploadFile,
    Schemas.ProcedureUploadLog,
    Schemas.ProcedureUploadFile,
    Schemas.Room,
    Schemas.ProcedureCategory
  }
  alias Innerpeace.Db.Base.{
    PayorContext,
    BenefitContext,
    Api.UtilityContext
  }
  alias Ecto.Changeset

  def insert_or_update_payor_procedure(params) do
    payor_procedure = get_payor_procedure_by_code(params["code"])
    if is_nil(payor_procedure) do
      create_payor_procedure(params)
    else
      update_payor_procedure(payor_procedure.id, params)
    end
  end

  def get_payor_procedure_by_code(code) do
    PayorProcedure
    |> Repo.get_by(code: code)
  end

  def get_payor_procedure_by_code2(code) do
    PayorProcedure
    |> Repo.get_by(code: code)
    |> Repo.preload([facility_payor_procedures: [facility: [:category, :type]]])
  end

  def insert_or_update_procedure(params) do
    procedure = get_procedure_by_code(params.code)
    if is_nil(procedure) do
      create_procedure(params)
    else
      update_procedure(procedure.id, params)
    end
  end

  def get_procedure_by_code(code) do
    Procedure
    |> Repo.get_by(code: code)
    |> Repo.preload(:procedure_category)
    |> Repo.preload(:procedure_logs)
  end

  def get_all_procedures do
    Procedure
    |> Repo.all
    |> Repo.preload([:procedure_category])
  end

  def get_all_tagged_procedures do
    PayorProcedure
    |> where([pp], pp.exclusion_type == "General Exclusion")
    |> Repo.all()
  end

  def get_all_payor_procedures do
    PayorProcedure
    |> where([p], p.is_active == true)
    |> Repo.all
    |> Repo.preload([
      :package_payor_procedures,
      :payor,
      :procedure_logs,
      procedure: :procedure_category,
      facility_payor_procedures: [facility: [:category, :type]]
    ])
  end

  def get_all_payor_procedures_oplab do
    PayorProcedure
    |> where([p], p.is_active == true)
    |> Repo.all
    |> Repo.preload([facility_payor_procedures: [facility: [:category, :type]]])
  end

  defp get_room_by_code do
    Room
    |> where([b], b.code == "16" and b.type == "OP")
    |> select([b], b.id)
    |> Repo.one()
  end

  def get_payor_procedure_by_facility(facility_id) do
    room_id = get_room_by_code()
    FacilityRoomRate
    |> where([frr], frr.facility_id == ^facility_id and frr.room_id == ^room_id)
    |> Repo.all
    |> Repo.preload([facility_payor_procedure_rooms: [facility_payor_procedure: [:payor_procedure]]])
  end

  # def get_all_payor_procedure_upload_logs do
  #   PayorProcedureUploadLog
  #   |> Repo.all
  # end

  def get_all_procedure_upload_logs do
    ProcedureUploadLog
    |> Repo.all
  end

  def get_procedure(id) do
    Procedure
    |> Repo.get!(id)
    |> Repo.preload(:procedure_category)
    |> Repo.preload(:procedure_logs)
  end

  def get_payor_procedure!(id) do
    PayorProcedure
    |> Repo.get!(id)
    |> Repo.preload([:package_payor_procedures, :exclusion_procedures])
    |> Repo.preload([
      facility_payor_procedures: [
        [
          facility: [
            :category,
            :type
          ]
        ],
        [
          facility_payor_procedure_rooms: [
            facility_room_rate: [
              facility: [
                :category,
                :type
              ]
            ]
          ]
        ]
      ]
    ])
  end

  def get_payor_procedure_by_procedure_id(procedure_id, payor_procedure_id) do
    PayorProcedure
    |> Repo.get_by(procedure_id: procedure_id, id: payor_procedure_id)
    |> Repo.preload(facility_payor_procedures: [facility: [:category, :type]])
    |> Repo.preload(:procedure_logs)
  end

  def create_procedure(procedure_params) do
    changeset = Procedure.changeset(%Procedure{}, procedure_params)
    changeset
    |> Repo.insert()
  end

  def update_procedure(id, procedure_params) do
    procedure = get_procedure(id)
    procedure
    |> Procedure.changeset(procedure_params)
    |> Repo.update()
  end

  def delete_procedure(id) do
    procedure = get_procedure(id)
    procedure
    |> Repo.delete()
  end

  def create_payor_procedure(procedure_params) do
    payor = Repo.get_by!(Payor, name: "Maxicare")
    procedure_params =
      procedure_params
      |> Map.put("payor_id", payor.id)
    changeset = PayorProcedure.changeset(%PayorProcedure{}, procedure_params)
    changeset
    |> Repo.insert()
  end

  def update_payor_procedure(payor_procedure_id, procedure_params) do
    payor_procedure_id
    |> get_payor_procedure!()
    |> Procedure.update_changeset(procedure_params)
    |> Repo.update
  end

  def delete_payor_procedure(payor_procedure_id) do
    payor_procedure = get_payor_procedure!(payor_procedure_id)
    payor_procedure
    |> Repo.delete()
  end

  def deactivate_payor_procedure(payor_procedure_id) do
    FacilityPayorProcedure
    |> where([fpp], fpp.payor_procedure_id == ^payor_procedure_id)
    |> Repo.delete_all()
    payor_procedure = get_payor_procedure!(payor_procedure_id)
    payor_procedure
    |> PayorProcedure.changeset(%{is_active: false,
                                  deactivation_date: Ecto.Date.utc()})
    |> Repo.update()
  end

  def get_deactivated_cpts(payor_procedure_id) do
    PayorProcedure
    |> where([pp], pp.procedure_id == ^payor_procedure_id and
                   pp.is_active == false)
    |> Repo.all()
    |> Repo.preload([facility_payor_procedures:
                    [facility: [:category, :type]],
                     procedure: :procedure_logs])
    |> Repo.preload([:procedure_logs])
  end

   # Procedure Logs in Procedure Page

def create_updated_procedure_log(user, changeset) do
  if Enum.empty?(changeset.changes) == false do
    changes = procedure_changes_to_string(changeset)
    message = "#{user.username} updated #{changes}."
    insert_log(%{
        payor_procedure_id: changeset.data.id,
        procedure_id: changeset.data.procedure_id,
        user_id: user.id,
        message: message
      })
    end
end

  def create_mapped_procedure_log(user, procedure, payor_procedure) do
      message = "<b>#{user.username}</b> mapped <b>Payor CPT Code</b> '#{payor_procedure["code"]}' to <b>Standard CPT Code</b> '#{procedure.code}' and <b>Payor CPT Description</b> '#{payor_procedure["description"]}' to <b>Standard CPT Description</b> '#{procedure.description}'."
      insert_log(%{
        procedure_id: procedure.id,
        user_id: user.id,
        message: message
      })
  end

  def create_deactivated_procedure_log(user, payor_procedure) do
      message = "<b>#{user.username}</b> deactivated <b>Payor CPT Code</b> '#{payor_procedure.code}' and <b>Payor CPT Description</b> '#{payor_procedure.description}'."
      insert_log(%{
        payor_procedure_id: payor_procedure.id,
        procedure_id: payor_procedure.procedure_id,
        user_id: user.id,
        message: message
      })
  end

  def changes_to_string(changeset) do
    changes = for {key, new_value} <- changeset.changes, into: [] do
      "#{transform_atom(key)} from #{Map.get(changeset.data, key)} to #{new_value}"
    end
    changes |> Enum.join(", ")
  end

  def procedure_changes_to_string(changeset) do
    changes = for {key, new_value} <- changeset.changes, into: [] do
      if transform_atom(key) == "Description" do
        "Description from #{Map.get(changeset.data, key)} to #{new_value}"
      else
        if transform_atom(key) == "Exclusion Type" do
          "Exclusion Type from #{Map.get(changeset.data, key)} to #{new_value}"
        end
      end
    end
    changes |> Enum.join(", ")
  end

  defp transform_atom(atom) do
    atom
    |> Atom.to_string()
    |> String.split("_")
    |> Enum.map(&(String.capitalize(&1)))
    |> Enum.join(" ")
  end

  defp insert_log(params) do
    changeset = ProcedureLog.changeset(%ProcedureLog{}, params)
    Repo.insert!(changeset)
  end

  def get_procedure_logs(payor_procedure_id) do
    ProcedureLog
    |> where([rl], rl.payor_procedure_id == ^payor_procedure_id)
    |> Repo.all()
  end

  # End of Procedure Logs in Procedure Page

  def download_procedures(params) do
    param = params["search_value"]
    query = (
      from p in Procedure,
      join: pp in PayorProcedure, on: pp.procedure_id == p.id,
      where: ilike(p.code, ^("%#{param}%")) or ilike(p.description, ^("%#{param}%")) or
      ilike(pp.code, ^("%#{param}%")) or ilike(pp.description, ^("%#{param}%")),
      where: pp.is_active == true,
      order_by: p.code,
      group_by: p.code,
      group_by: p.description,
      group_by: pp.code,
      group_by: pp.description,
      select: ([
        p.code,
        p.description,
        pp.code,
        pp.description
      ])
    )
    query = Repo.all(query)
  end

  def create_procedure_import(procedure_params, user_id) do
    procedure_params["file"].path
    |> File.stream!()
    |> CSV.decode(headers: true)
    |> ProcedureParser.parse_data(procedure_params["file"].filename, user_id)
  end

  def get_payor_procedure(code) do
    PayorProcedure
    |> Repo.get_by(code: code)
    |> Repo.preload(facility_payor_procedures: [facility: [:category, :type]])
    |> Repo.preload(:procedure_logs)
  end

  def get_procedure_upload_logs(p_id, p_status) do
    procedures =
      ProcedureUploadLog
      |> select([p], [p.remarks, p.cpt_code,
                      p.cpt_description,
                      p.cpt_type
                      ])
      |> where([p], p.status == ^p_status
        and p.procedure_upload_file_id == ^p_id)
      |> Repo.all
  end

  def get_payor_procedure_by_procedure_id_only(procedure_id) do
    PayorProcedure
    |> Repo.get_by(procedure_id: procedure_id, is_active: true)
    |> Repo.preload(facility_payor_procedures: [facility: [:category, :type]])
    |> Repo.preload(:procedure_logs)
  end

  def get_procedure_upload_file do
    query =
      from pf in ProcedureUploadFile,
      join: u in User, on: u.id == pf.created_by_id,
      join: pl in ProcedureUploadLog,
      on: pf.id == pl.procedure_upload_file_id,
      select: (%{:id => pf.id, :filename => pf.filename,
        :created_by => u.username,
        :batch_number => pf.batch_number,
        :total_count => (fragment("(SELECT count(*) FROM procedure_upload_logs
          where procedure_upload_file_id = ?)", pl.procedure_upload_file_id)),
        :success => (fragment("(SELECT count(*) FROM procedure_upload_logs
          where status = ? and procedure_upload_file_id = ?)", "success", pl.procedure_upload_file_id)),
        :failed => (fragment("(SELECT count(*) FROM procedure_upload_logs
          where status = ? and procedure_upload_file_id = ?)", "failed", pl.procedure_upload_file_id)),
        :inserted_at => (fragment("to_char(?, 'MM/DD/YYYY HH24:MI:SS')", pf.inserted_at)),
        :date_finished => (fragment("(SELECT to_char(inserted_at,'MM/DD/YYYY HH24:MI:SS')
          FROM procedure_upload_logs where procedure_upload_file_id = ? order by inserted_at desc limit 1)", pl.procedure_upload_file_id))
      }),
      group_by: [pl.procedure_upload_file_id,
                 pf.id, pf.filename, u.username]

    Repo.all(query)
  end

  def generate_batch_no(batch_no) do
    origin = batch_no

    case Enum.count(Integer.digits(batch_no + 1)) do
      1 ->
        batch_no = "000#{batch_no}"
      2 ->
        batch_no = "00#{batch_no}"
      3 ->
        batch_no = "0#{batch_no}"
      4 ->
        batch_no
      _ ->
        batch_no
    end

    with nil <- Repo.get_by(ProcedureUploadFile, batch_number: batch_no) do
      batch_no
    else
     %ProcedureUploadFile{} ->
        generate_batch_no(origin + 1)
    end
  end

  def get_pp_upload_logs do
    ProcedureUploadFile
    |> Repo.all()
    |> Repo.preload(:procedure_upload_logs)
  end

  def get_procedure_by_code_and_is_active(code) do
    PayorProcedure
    |> Repo.get_by(code: code, is_active: true)
    |> Repo.preload(facility_payor_procedures:
                    [facility: [:category, :type]])
    |> Repo.preload(:procedure_logs)

  end

  def get_procedure_by_code_and_desc(code, desc) do
    Procedure
    |> where([p], ilike(p.code, ^("#{code}")) and ilike(p.description, ^("#{desc}")))
    |> Repo.all()
  end

  def cpt_clear_tagging(payor_procedure) do
    params = %{exclusion_type: nil}
    payor_procedure
    |> PayorProcedure.changeset_exclusion_type_nil(params)
    |> Repo.update()
  end

  def get_payor_procedure_by_facility_emergency(facility_id) do
    room_id = get_emergency_room_by_code()
    FacilityRoomRate
    |> where([frr], frr.facility_id == ^facility_id and frr.room_id == ^room_id)
    |> Repo.all
    |> Repo.preload([facility_payor_procedure_rooms: [facility_payor_procedure: [:payor_procedure]]])
  end

  def get_emergency_payor_procedure_by_facility(facility_id) do
    room_id = get_emergency_room_by_code()
    FacilityRoomRate
    |> where([frr], frr.facility_id == ^facility_id and frr.room_id == ^room_id)
    |> Repo.all
    |> Repo.preload([facility_payor_procedure_rooms: [facility_payor_procedure: [:payor_procedure]]])
  end

  defp get_emergency_room_by_code do
    Room
    |> where([b], b.code == "31" and b.type == "ER")
    |> select([b], b.id)
    |> Repo.one()
  end

  def get_all_procedure_query(params, offset) do
    PayorProcedure
    |> join(:inner, [pp], p in Procedure, pp.procedure_id == p.id)
    |> where([pp, p],
             ilike(p.code, ^"%#{params}%") or
             ilike(p.description, ^"%#{params}%")
    )
    |> order_by([pp, p], p.code)
    |> limit(100)
    |> offset(^offset)
    |> Repo.all()
    |> Repo.preload([:procedure])
  end

  def load_procedures_table(ids) when ids == [""] do
    PayorProcedure
    |> join(:inner, [pp], p in Procedure, pp.procedure_id == p.id)
    |> select([p, pp],
      %{
        id: p.id,
        sp_code: pp.code,
        sp_name: pp.description,
        pp_code: p.code,
        pp_name: p.description,
      }
    )
    |> Repo.all()
    |> insert_table_buttons([])
  end

  def load_procedures_table(ids) when ids != [""] do
    PayorProcedure
    |> join(:inner, [pp], p in Procedure, pp.procedure_id == p.id)
    |> where([p, pp], p.id not in ^ids)
    |> select([p, pp],
      %{
        id: p.id,
        sp_code: pp.code,
        sp_name: pp.description,
        pp_code: p.code,
        pp_name: p.description,
      }
    )
    |> Repo.all()
    |> insert_table_buttons([])
  end

  defp insert_table_buttons([head | tails], tbl) do
    tbl =
      tbl ++ [[
        "<input type='checkbox' style='width:20px; height:20px' class='procedure_chkbx' pp_id='#{head.id}' sp_code='#{head.sp_code}' sp_name='#{head.sp_name}' pp_code='#{head.pp_code}' pp_name='#{head.pp_name}' />",
        "<span class='green'>#{head.sp_code}</span>",
        "#{head.sp_name}",
        "#{head.pp_code}",
        "#{head.pp_name}"
      ]]

    insert_table_buttons(tails, tbl)
  end
  defp insert_table_buttons([], tbl), do: tbl

  def get_procedures_modal_benefit(offset, limit, params, benefit_id) do
    bp_ids = BenefitContext.get_benefit_procedure_ids(benefit_id)
    PayorProcedure
    |> join(:left, [pp], p in Procedure, pp.procedure_id == p.id)
    |> join(:left, [pp, p], pc in ProcedureCategory, pc.id == p.procedure_category_id)
    |> where([pp, p, pc],
      ilike(pp.code, ^"%#{params}%") or
      ilike(pp.description, ^"%#{params}%") or
      ilike(p.code, ^"%#{params}%") or
      ilike(p.description, ^"%#{params}%") or
      ilike(pc.name, ^"%#{params}%"))
    |> where([pp, p, pc], pp.id not in ^bp_ids)
    |> select([pp, p, pc], %{
        id: pp.id,
        code: pp.code,
        description: pp.description,
        procedure_code: p.code,
        procedure_description: p.description,
        procedure_category: pc.name
        })
    |> offset(^offset)
    |> limit(^limit)
    |> Repo.all()
  end

  def get_procedures_modal(offset, limit, params, benefit_id) do
    bp_ids = BenefitContext.get_benefit_procedure_ids(benefit_id)
    PayorProcedure
    |> join(:left, [pp], p in Procedure, pp.procedure_id == p.id)
    |> join(:left, [pp, p], pc in ProcedureCategory, pc.id == p.procedure_category_id)
    |> where([pp, p, pc],
      ilike(pp.code, ^"%#{params}%") or
      ilike(pp.description, ^"%#{params}%") or
      ilike(p.code, ^"%#{params}%") or
      ilike(p.description, ^"%#{params}%") or
      ilike(pc.name, ^"%#{params}%"))
    |> where([pp, p, pc], pp.id not in ^bp_ids)
    |> select([pp, p, pc], %{
        id: pp.id,
        code: pp.code,
        description: pp.description,
        procedure_code: p.code,
        procedure_description: p.description,
        procedure_category: pc.name
        })
    |> offset(^offset)
    |> limit(^limit)
    |> Repo.all()
    |> convert_to_tbl_procedure_cols([])
  end

  def get_procedures_modal_count(params, benefit_id) do
    bp_ids = BenefitContext.get_benefit_procedure_ids(benefit_id)
    PayorProcedure
    |> join(:left, [pp], p in Procedure, pp.procedure_id == p.id)
    |> join(:left, [pp, p], pc in ProcedureCategory, pc.id == p.procedure_category_id)
    |> where([pp, p, pc], pp.id not in ^bp_ids)
    |> where([pp, p, pc],
      ilike(pp.code, ^"%#{params}%") or
      ilike(pp.description, ^"%#{params}%") or
      ilike(p.code, ^"%#{params}%") or
      ilike(p.description, ^"%#{params}%") or
      ilike(pc.name, ^"%#{params}%"))
    |> select([pp, p, pc], count(pp.id))
    |> Repo.one()
  end

  defp convert_to_tbl_procedure_cols([head | tails], tbl) do
    tbl =
      tbl ++ [[
        head.id,
        head.code,
        head.description,
        head.procedure_code,
        head.procedure_description,
        head.procedure_category
      ]]

    convert_to_tbl_procedure_cols(tails, tbl)
  end
  defp convert_to_tbl_procedure_cols([], tbl), do: tbl

end
