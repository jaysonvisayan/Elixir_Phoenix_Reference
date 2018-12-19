defmodule Innerpeace.Db.Validators.IPValidator do

  import Ecto.{
      Query,
      Changeset
  }, warn: false

  alias Decimal

  alias Innerpeace.Db.{
    Repo,
    Schemas.ProductCoverage,
    Schemas.ProductCoverageFacility,
    Schemas.Facility,
    Schemas.FacilityPayorProcedure,
    Schemas.FacilityPayorProcedureRoom,
    Schemas.Benefit,
    Schemas.BenefitProcedure,
    Schemas.PayorProcedure,
    Schemas.CaseRate,
    Schemas.Diagnosis,
    Schemas.Embedded.OPLab,
    Schemas.Procedure,
    Schemas.MemberProduct,
    Schemas.AccountProduct,
    Schemas.Product,
    Schemas.ProductCoverage,
    Schemas.ProductCoverageRiskShare,
    Schemas.ProductCoverageRiskShareFacility,
    Schemas.ProductCoverageRiskShareFacilityPayorProcedure,
    Schemas.Coverage,
    Schemas.FacilityRoomRate,
    Schemas.Room,
    Schemas.FacilityRUV,
    Schemas.ProductExclusion,
    Schemas.ExclusionProcedure,
    Schemas.ExclusionDisease,
    Schemas.BenefitRUV
  }

  alias Innerpeace.Db.Base.{
    AuthorizationContext,
    PractitionerContext,
    MemberContext,
    ProductContext,
    BenefitContext,
    CoverageContext,
    FacilityContext
  }

  def request_ip(params) do
    # TODO: Setup
  end

end
