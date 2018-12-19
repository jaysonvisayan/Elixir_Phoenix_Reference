defmodule Innerpeace.Db.PayorRepo do

  def context do
    quote do
      import Innerpeace.Db.Base.{
        AccountContext,
        ApplicationContext,
        BenefitContext,
        PermissionContext,
        RoleContext,
        ApplicationContext,
        DiagnosisContext,
        UserContext,
        CoverageContext,
        ProcedureContext,
        ExclusionContext,
        ProductContext,
        ClusterContext,
        FacilityContext,
        PractitionerContext,
        RoomContext,
        FacilityRoomRateContext,
        PayorContext,
        MemberContext,
        ProcedureCategoryContext,
        IndustryContext,
        PayorContext,
        ContactContext,
        EmailContext,
        PhoneContext,
        DropdownContext,
        BankBranchContext,
        BankContext,
        FulfillmentCardContext,
        UserContext,
        AccountGroupContext,
        PackageContext
      }
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

end
