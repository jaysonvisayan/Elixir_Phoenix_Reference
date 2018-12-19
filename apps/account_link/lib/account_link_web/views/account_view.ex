defmodule AccountLinkWeb.AccountView do
  use AccountLinkWeb, :view

  alias Innerpeace.Db.Repo
  alias Innerpeace.Db.Schemas.{
    Room,
    Coverage
  }

  def get_img_url(account_group) do
    Innerpeace.ImageUploader
    |> AccountLinkWeb.LayoutView.image_url_for(account_group.photo, account_group, :original)
    |> String.replace("/apps/account_link/assets/static", "")
  end

  def render("account_group_2.json", %{account_group: account_group}) do
    dependent_hierarchy = account_group.account_hierarchy_of_eligible_dependents
    %{
      id: account_group.id,
      name: account_group.name,
      code: account_group.code,
      account: render_many(account_group.account, AccountLinkWeb.AccountView,
                           "account.json", as: :account),
      members: render_many(account_group.members, AccountLinkWeb.MemberView,
                           "member.json", as: :member),
      dependent_hierarchy: render_many(dependent_hierarchy,
                                       AccountLinkWeb.AccountView,
                                       "account_dependent_hierarchy.json",
                                       as: :dependent_hierarchy)
    }
  end

  def render("account.json", %{account: account}) do
    %{
      start_date: account.start_date,
      end_date: account.end_date,
      status: account.status,
      major_version: account.major_version,
      minor_version: account.minor_version,
      build_version: account.build_version,
      step: account.step
    }
  end

  def render("account_dependent_hierarchy.json", %{dependent_hierarchy: dependent_hierarchy}) do
    %{
      id: dependent_hierarchy.id,
      hierarchy_type: dependent_hierarchy.hierarchy_type,
      dependent: dependent_hierarchy.dependent,
      ranking: dependent_hierarchy.ranking
    }
  end

  def check_exclusion_genex(product_exclusions) do
    list = [] ++ for product_exclusion <- product_exclusions do
      if product_exclusion.exclusion.coverage == "General Exclusion" do
        product_exclusion
      end
    end

    _list =
      list
      |> Enum.uniq()
      |> List.delete(nil)
  end

  def check_pre_existing(product_exclusions) do
    list = [] ++ for product_exclusion <- product_exclusions do
      if product_exclusion.exclusion.coverage == "Pre-existing Condition" do
        product_exclusion
      end
    end

    _list =
      list
      |> Enum.uniq()
      |> List.delete(nil)
  end

  def preload_room_type(pcrnb_room_type) do
    if is_nil(pcrnb_room_type) do
      ""
    else
      room =
        Room
        |> Repo.get(pcrnb_room_type)

        room.type
    end
  end

  def load_coverages_id(coverages_id) do
    coverage = Repo.get!(Coverage, coverages_id)
    coverage.name
  end

  def checkRiskShareValues(risk_share) do
    af = get_af_values(risk_share)
    naf = get_naf_values(risk_share)

    list = af ++ naf

    result =
      list
      |> Enum.uniq
      |> Enum.member?("true")

    if result == true, do: "true", else: "false"
  end

  def get_af_values(risk_share) do
    type = if risk_share.af_type != nil,
    do: ["true"], else: [nil]
    value_percentage = if risk_share.af_value_percentage != nil,
    do: ["true"], else: [nil]
    value_amount = if risk_share.af_value_amount != nil,
    do: ["true"], else: [nil]
    covered_percentage = if risk_share.af_covered_percentage != nil,
    do: ["true"], else: [nil]

    _list = type ++ value_percentage ++ value_amount ++ covered_percentage
  end

  def get_naf_values(risk_share) do
    reimbursable = if risk_share.naf_reimbursable != nil,
    do: ["true"], else: [nil]
    type = if risk_share.naf_type != nil,
    do: ["true"], else: [nil]
    value_percentage = if risk_share.naf_value_percentage != nil,
    do: ["true"], else: [nil]
    value_amount = if risk_share.naf_value_amount != nil,
    do: ["true"], else: [nil]
    covered_percentage = if risk_share.naf_covered_percentage != nil,
    do: ["true"], else: [nil]

    _list = reimbursable ++ type ++ value_percentage
           ++ value_amount ++ covered_percentage
  end
end
