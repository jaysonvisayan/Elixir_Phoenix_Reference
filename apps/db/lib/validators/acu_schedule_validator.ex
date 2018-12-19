defmodule Innerpeace.Db.Validators.ACUScheduleValidator do
  @moduledoc false

  import Ecto.{
    Changeset
  }, warn: false

  alias Innerpeace.Db.Base.{
    AuthorizationContext,
    DiagnosisContext
  }

  alias Innerpeace.Db.Repo
  alias Innerpeace.Db.Schemas.{
    Authorization,
    AuthorizationBenefitPackage,
    AuthorizationDiagnosis,
    AuthorizationAmount
  }

  def put_changeset(changeset, key, value) do
    Ecto.Changeset.put_change(changeset, key, value)
  end

  def insert_acu_details(params) do
    user_id = params.user_id
    diagnosis = DiagnosisContext.get_diagnosis_by_code("Z00.0")
    acu_details = %{
      "benefit_package_id" => params.benefit_package_id,
      "payor_covered" => params.package_rate,
      "member_covered" => Decimal.new(0),
      "payor_pays" => params.package_rate,
      "member_pays" => Decimal.new(0),
      "total_amount" => params.package_rate,
      "package_rate" => params.package_rate,
      "member_product_id" => params.member_product_id,
      "product_benefit_id" => params.product_benefit_id,
      "diagnosis_id" => diagnosis.id,
      "authorization_id" => params.authorization.id,
      "created_by_id" => user_id,
      "updated_by_id" => user_id
    }
    create_authorization_benefit_package(acu_details)
    create_authorization_amount(acu_details)
    create_authorization_diagnosis(acu_details)
    {:ok}
  end

  defp create_authorization_diagnosis(params) do
    %AuthorizationDiagnosis{}
    |> AuthorizationDiagnosis.changeset(params)
    |> Repo.insert()
  end

  defp create_authorization_benefit_package(params) do
    %AuthorizationBenefitPackage{}
    |> AuthorizationBenefitPackage.changeset(params)
    |> Repo.insert()
  end

  defp create_authorization_amount(params) do
    %AuthorizationAmount{}
    |> AuthorizationAmount.changeset(params)
    |> Repo.insert()
  end

end
