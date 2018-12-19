defmodule RegistrationLinkWeb.Permission.Mock do
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
      "manage_pfbatch",
      "manage_hbbatch"
    ]
  end

  defp access_permissions do
    [
      "access_pfbatch",
      "access_hbbatch"
    ]
  end
end
