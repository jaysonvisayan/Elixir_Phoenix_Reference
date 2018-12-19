defmodule Innerpeace.Db.Base.Api.Vendor.PractitionerContext do
    @moduledoc false

    import Ecto.{Query, Changeset}, warn: false
    alias Ecto.Changeset

    alias Innerpeace.Db.{
      Repo,
      Schemas.Practitioner,
      Schemas.Facility,
      Schemas.PractitionerFacility
    }

    def get_practitioner_by_code(code) do
      Practitioner
      |> Repo.get_by(code: code)
    end

    def get_facility_by_code(code) do
      Facility
      |> Repo.get_by(code: code)
    end

    def get_practitioner_facility_by_code(p_id, f_id) do
      PractitionerFacility
      |> where(
        [pf],
        pf.practitioner_id == ^p_id and
        pf.facility_id == ^f_id
      )
      |> Repo.one
      |> Repo.preload([:practitioner_status])
    end

    def get_practitioner(practitioner) do
      Practitioner
      |> where([p],
               ilike(fragment("lower(?)", fragment("concat(?, ' ', ?, ' ', ?)", p.first_name, p.middle_name, p.last_name)), ^"%#{practitioner}%")
               or ilike(fragment("lower(?)", fragment("concat(?, ' ', ?)", p.first_name, p.last_name)), ^"%#{practitioner}%")
               or ilike(p.code, ^"%#{practitioner}%"))
      |> Repo.all
      |> Repo.preload([
        practitioner_specializations: :specialization,
        practitioner_facilities: :facility
      ])
    end

    def get_practitioner do
      Practitioner
      |> Repo.all
      |> Repo.preload([
        practitioner_specializations: :specialization,
        practitioner_facilities: :facility
      ])
    end
end
