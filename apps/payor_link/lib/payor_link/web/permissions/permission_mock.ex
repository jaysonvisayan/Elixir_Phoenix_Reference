defmodule Innerpeace.Permission.Mock do
  @moduledoc false

  def get_permission(_conn) do
    manage_permissions() ++ access_permissions()
  end

  def get_applications(_conn) do
    [
      "AccountLink",
      "MemberLink",
      "PayorLink",
      "RegistrationLink",
      "FacilityLink"
    ]
  end

  defp manage_permissions do
    [
      "manage_users",
      "manage_accounts",
      "manage_products",
      "manage_benefits",
      "manage_roles",
      "manage_diseases",
      "manage_procedures",
      "manage_clusters",
      "manage_coverages",
      "manage_exclusions",
      "manage_facilities",
      "manage_packages",
      "manage_caserates",
      "manage_ruvs",
      "manage_authorizations",
      "manage_rooms",
      "manage_practitioners",
      "manage_members",
      "manage_pfbatch",
      "manage_hbbatch"
    ]
  end

  defp access_permissions do
    [
      "access_users",
      "access_accounts",
      "access_products",
      "access_benefits",
      "access_roles",
      "access_diseases",
      "access_procedures",
      "access_clusters",
      "access_coverages",
      "access_exclusions",
      "access_facilities",
      "access_packages",
      "access_caserates",
      "access_ruvs",
      "access_authorizations",
      "access_rooms",
      "access_practitioners",
      "access_members",
      "access_pfbatch",
      "access_hbbatch"
    ]
  end
end
