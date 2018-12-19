defmodule Innerpeace.Db.Base.PackageContext do
  @moduledoc false

  import Ecto.{Query, Changeset}, warn: false

  alias Innerpeace.{
    Db.Repo,
    Db.Schemas.Package,
    # Db.Schemas.PayorProcedure,
    Db.Schemas.PackagePayorProcedure,
    Db.Schemas.Benefit,
    Db.Schemas.BenefitPackage,
    Db.Schemas.PackageFacility,
    Db.Schemas.PayorProcedure,
    Db.Schemas.Procedure,
    Db.Schemas.Facility,
    Db.Schemas.PackageLog

  }

  alias Innerpeace.Db.Base.ProcedureContext
  alias Innerpeace.Db.Base.FacilityContext

  def get_package_payor_procedure_count(package_id) do
    PackagePayorProcedure
    |> where([ac], ac.package_id == ^package_id)
    |> Repo.all
    |> Enum.count
  end

  def get_package_payor_procedures(package_id) do
    PackagePayorProcedure
    |> where([pp], pp.package_id == ^package_id)
    |> Repo.all
    |> Repo.preload([:package, payor_procedure: [:procedure]])
  end

  def get_package_facility(package_id) do
    PackageFacility
    |> where([pp], pp.package_id == ^package_id)
    |> Repo.all
    |> Repo.preload([:package, :facility])
  end

  def get_package_payor_procedure(id) do
    PackagePayorProcedure
    |> Repo.get!(id)
  end

  def get_one_package_payor_procedure(package_id) do
    PackagePayorProcedure
    |> where([ppp], ppp.package_id == ^package_id)
    |> Repo.all
    |> Repo.preload([:payor_procedure, :package])
  end

  def get_package_facilities(id) do
    PackageFacility
    |> Repo.get!(id)
    |> Repo.preload([:facility, :package])
  end

  def get_all_packages do
    Package
    |> Repo.all
    |> Repo.preload([package_payor_procedure: [payor_procedure: [:procedure]]])
  end

  def get_all_package_payor_procedures do
    PackagePayorProcedure
    |> Repo.all
    |> Repo.preload(:package)
    |> Repo.preload([payor_procedure: :procedure])
  end

  def list_all_package_payor_procedures do
    PackagePayorProcedure
    |> Repo.all
    |> Repo.preload([:package, payor_procedure: [:procedure]])
  end

  def list_all_package_facility do
    PackageFacility
    |> Repo.all
    |> Repo.preload([:package, :facility])
  end

  def list_all_packages do
    Package
    |> Repo.all
  end

  def list_package!(id), do: Repo.get!(Package, id)

  def insert_package_payor_procedures(package_id, params) do
    params =
      params
      |> Map.put("package_id", package_id)

    %PackagePayorProcedure{}
    |> PackagePayorProcedure.changeset(params)
    |> Repo.insert()
  end

  def insert_package_facilities(package_id, params) do
    params =
      params
      |> Map.put("package_id", package_id)

    %PackageFacility{}
    |> PackageFacility.changeset(params)
    |> Repo.insert()
  end

  def get_package(id) do
    Package
    |> Repo.get(id)
    |> Repo.preload([:package_log, package_facility: [:facility], package_payor_procedure: [payor_procedure: [:procedure]]])
  end

  def get_package_log(package_id, message) do
    PackageLog
    |> where([pl], pl.package_id == ^package_id and like(pl.message, ^"%#{message}%"))
    |> order_by(desc: :inserted_at)
    |> Repo.all
  end

  def get_all_package_log(package_id) do
    PackageLog
    |> where([pl], pl.package_id == ^package_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all
  end

  def create_package(attrs \\ %{}) do
    %Package{}
    |> Package.changeset(attrs)
    |> Repo.insert()
  end

  def update_package(%Package{} = package, attrs) do
    package
    |> Package.changeset(attrs)
    |> Repo.update()
  end

  def update_package_facility(id, package_param) do
    id
    |> get_package_facilities()
    |> PackageFacility.changeset(package_param)
    |> Repo.update
  end

  def update_a_package(id, package_param) do
    id
    |> get_package()
    |> Package.changeset(package_param)
    |> Repo.update
  end

  def update_package_step(%Package{} = package, attrs) do
    package
    |> Package.changeset_step(attrs)
    |> Repo.update()
  end

  def delete_package(id) do
    id
    |> get_package()
    |> Repo.delete()
  end

  def delete_a_package_payor_procedure(id) do
    id
    |> get_package_payor_procedure()
    |> Repo.delete()
  end

  def delete_a_package_facility(id) do
    id
    |> get_package_facilities()
    |> Repo.delete()
  end

  def change_package(%Package{} = package) do
    Package.changeset(package, %{})
  end

  def change_package_payor_procedure(%PackagePayorProcedure{} = accountpackage) do
    PackagePayorProcedure.changeset(accountpackage, %{})
  end

  def select_all_package_code do
    Package
    |> select([:code])
    |> Repo.all
  end

  def get_all_package_code_and_name do
    Package
    |> select([:code, :name])
    |> Repo.all
  end

  def get_one_facility(name) do
    Facility
    |> where([f], f.name == ^name)
    |> Repo.all
  end

  def check_one_facility(name) do
    facility = get_one_facility(name)
    facility
    |> Repo.preload([:category, :type, facility_location_groups: :location_group])
  end

  def create_package_log(user, changeset, tab) do
    if Enum.empty?(changeset.changes) == false do
      changes = changes_to_string(changeset)
      message = "#{user.username} edited #{changes} in #{tab} tab."
      insert_log(%{
        package_id: changeset.data.id,
        user_id: user.id,
        message: message
      })
    end
  end

  def create_package_logs(package, user, params, step) do
      changes = insert_changes_to_string_package(params)
      message = "#{user.username} created this package where #{changes} in #{step} step."
      insert_log(%{
        package_id: package.id,
        user_id: user.id,
        message: message
      })
  end

  def create_procedure_log(package, user, changeset, tab) do
    if Enum.empty?(changeset.changes) == false do

      changes = insert_changes_to_string_payor_procedure(changeset)
      message = "#{user.username} added a new procedure where #{changes} in #{tab} tab."
      insert_log(%{
        package_id: package.id,
        user_id: user.id,
        message: message
      })
    end
  end

  def create_procedure_logs(package, user, changeset, step) do
    if Enum.empty?(changeset.changes) == false do

      changes = insert_changes_to_string_payor_procedure(changeset)
      message = "#{user.username} created a procedure where #{changes} in #{step} step."
      insert_log(%{
        package_id: package.id,
        user_id: user.id,
        message: message
      })
    end
  end

  def create_facility_log(package, user, changeset, tab) do
    if Enum.empty?(changeset.changes) == false do

      changes = insert_changes_to_string_facility(changeset)
      message = "#{user.username} added a new facility where #{changes} in #{tab} tab"
      insert_log(%{
        package_id: package.id,
        user_id: user.id,
        message: message
      })
    end
  end

  def create_facility_log_update(package, user, changeset, tab) do
    if Enum.empty?(changeset.changes) == false do
      changes = update_changes_to_string_facility(changeset)
      message = "#{user.username} edited #{changes} in #{tab} tab."
      insert_log(%{
        package_id: package.id,
        user_id: user.id,
        message: message
      })
    end
  end

  def delete_facility_log(package, user, params, tab) do
      params = delete_changes_to_string(params)
      message = "#{user.username} removed a facility where #{params} in #{tab} tab."
      insert_log(%{
        package_id: package,
        user_id: user.id,
        message: message
      })
  end

  def delete_payor_procedure_log(package, user, params, tab) do
      params = delete_procedure_changes_to_string(params)
      message = "#{user.username} removed a procedure where #{params} in #{tab} tab."
      insert_log(%{
        package_id: package,
        user_id: user.id,
        message: message
      })
  end

  def delete_payor_procedure_logs(package, user, params, step) do
      params = delete_procedure_changes_to_string(params)
      message = "#{user.username} removed a procedure where #{params} in #{step} step."
      insert_log(%{
        package_id: package,
        user_id: user.id,
        message: message
      })
  end

  def delete_procedure_changes_to_string(params) do
    payor_procedure = ProcedureContext.get_payor_procedure!(params.payor_procedure_id)
    changes = params
    changes =
      changes
      |> Map.delete(:payor_procedure_id)
    changes =
      changes
      |> Map.merge(%{payor_procedure_code: payor_procedure.code, payor_procedure_name: payor_procedure.description})
    changes = for {key, new_value} <- changes, into: [] do
      "#{transform_atom(key)} is #{new_value}"
    end
    changes |> Enum.join(", ")
  end

  def insert_changes_to_string_package(params) do
    changes = params
    changes =
      changes
      |> Map.delete("created_by")
      |> Map.delete("updated_by")
      |> Map.delete("step")
    params = %{package_code: changes["code"], package_name: changes["name"]}
    changes = for {key, new_value} <- params, into: [] do
      "#{transform_atom(key)} is #{new_value}"
    end
    changes |> Enum.join(", ")
  end

  # Duplicate function
  # def delete_procedure_changes_to_string(params) do
  #   payor_procedure = ProcedureContext.get_payor_procedure!(params.payor_procedure_id)
  #   changes = params
  #   changes =
  #     changes
  #     |> Map.delete(:payor_procedure_id)
  #   changes =
  #     changes
  #     |> Map.merge(%{payor_procedure_code: payor_procedure.code, payor_procedure_name: payor_procedure.description})
  #   changes = for {key, new_value} <- changes, into: [] do
  #     "<b> <i> #{transform_atom(key)} </b> </i> is <b> <i> #{new_value} </b> </i>"
  #   end
  #   changes |> Enum.join(", ")
  # end

  def delete_changes_to_string(params) do
    changes = params
    rate_val = changes.facility_rate
    rate = to_string(rate_val) <> " PHP"

    changes =
      changes
      |> Map.delete(:facility_rate)

    changes =
      changes
      |> Map.merge(%{facility_rate: rate})

    changes = for {key, new_value} <- changes, into: [] do
      "#{transform_atom(key)} is #{new_value}"
    end
    changes |> Enum.join(", ")
  end

  def update_changes_to_string_facility(changeset) do
    changes = changeset.changes
    changes =
      changes
      |> Map.delete(:package_id)
      |> Map.delete(:facility_id)

    changes = for {key, new_value} <- changes, into: [] do
      "Facility #{transform_atom(key)} from #{Map.get(changeset.data, key)} php to #{new_value} php"
    end
    changes |> Enum.join(", ")
  end

  def insert_changes_to_string_facility(changeset) do
    facility = FacilityContext.get_facility!(changeset.changes.facility_id)
    changes = changeset.changes
    rate_val = changes.rate
    rate =  to_string(rate_val) <> " PHP"
    changes =
      changes
      |> Map.delete(:package_id)
      |> Map.delete(:facility_id)
      |> Map.delete(:rate)
    changes =
      changes
      |> Map.merge(%{facility_code: facility.code, facility_name: facility.name, facility_rate: rate})

    changes = for {key, new_value} <- changes, into: [] do
      "#{transform_atom(key)} is #{new_value}"
    end
    changes |> Enum.join(", ")
  end

  def insert_changes_to_string_payor_procedure(changeset) do
    payor_procedure = ProcedureContext.get_payor_procedure!(changeset.changes.payor_procedure_id)
    changes = changeset.changes
    changes =
      changes
      |> Map.delete(:payor_procedure_id)
    changes =
      changes
      |> Map.merge(%{payor_procedure_code: payor_procedure.code, payor_procedure_description: payor_procedure.description})

    age_from = changes.age_from
    age_to = changes.age_to
    age =  to_string(age_from) <> " to " <> to_string(age_to) <> " y/o"
    changes =
      changes
      |> Map.delete(:age_from)
      |> Map.delete(:age_to)
    changes =
      changes
      |> Map.merge(%{ages: age})

      female =
        changes
        |> Map.get(:female)
      male =
        changes
        |> Map.get(:male)

      if male != nil and female == nil do
        changes
        |> Map.delete(:male)
        |> Map.merge(%{gender: "Male"})
      end

      if male == nil and female != nil do
        changes
        |> Map.delete(:female)
        |> Map.merge(%{gender: "Female"})
      end

      if male != nil and female != nil do
        changes
        |> Map.delete(:female)
        |> Map.delete(:male)
        |> Map.merge(%{gender: "Male & Female"})
      end

    changes = for {key, new_value} <- changes, into: [] do
      "#{transform_atom(key)} is#{new_value}"
    end
    changes |> Enum.join(", ")
  end

  def changes_to_string(changeset) do
    changes = for {key, new_value} <- changeset.changes, into: [] do
      "#{transform_atom(key)} from #{Map.get(changeset.data, key)} to #{new_value}"
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
    changeset = PackageLog.changeset(%PackageLog{}, params)
    Repo.insert!(changeset)
  end

  def get_package_facility_by_package_and_facility(package_id, facility_id) do
    PackageFacility
    |> where([pf], pf.package_id == ^package_id and pf.facility_id == ^facility_id)
    |> Repo.one()
  end

  def load_package_dropdown do
    Package
    |> where([p], p.step != 2)
    |> select([p],
      %{
        id: p.id,
        name: p.name,
        code: p.code
      }
    )
    |> Repo.all()
    |> transform_dropdown_params([])
  end

  defp transform_dropdown_params([head | tails], data) do

    data =
      data ++ [
        %{
          "value" => head.id,
          "name" => "#{head.code} #{head.name}"
        }
      ]

    transform_dropdown_params(tails, data)
  end
  defp transform_dropdown_params([], data), do: data

  def load_package(id) do
    Package
    |> where([p], p.id == ^id)
    |> join(:left, [p], ppp in PackagePayorProcedure, ppp.package_id == p.id)
    |> join(:left, [p, ppp], pp in PayorProcedure, pp.id == ppp.payor_procedure_id)
    |> join(:left, [p, ppp, pp, sp], sp in Procedure, sp.id == pp.procedure_id)
    |> select([p, ppp, pp, sp],
      %{
        "package_id" => p.id,
        "package_code" => p.code,
        "package_name" => p.name,
        "sp_code" => sp.code,
        "sp_id" => sp.id,
        "pp_id" => pp.id,
        "sp_description" => sp.description,
        "pp_code" => pp.code,
        "pp_description" => pp.description,
        "age_from" => ppp.age_from,
        "age_to" => ppp.age_to,
        "male" => ppp.male,
        "female" => ppp.female
      }
    )
    |> Repo.all()
  end

end
