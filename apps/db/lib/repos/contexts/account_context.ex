defmodule Innerpeace.Db.Base.AccountContext do
  @moduledoc false

  import Ecto.{Query, Changeset}, warn: false
  alias Innerpeace.{
    Db.Repo,
    Db.Schemas.Account,
    Db.Schemas.AccountComment,
    Db.Schemas.AccountGroup,
    Db.Schemas.AccountGroupApproval,
    Db.Schemas.AccountGroupAddress,
    Db.Schemas.AccountGroupApproval,
    Db.Schemas.AccountGroupContact,
    Db.Schemas.AccountLog,
    Db.Schemas.AccountProduct,
    Db.Schemas.AccountProductBenefit,
    Db.Schemas.Bank,
    Db.Schemas.BankBranch,
    Db.Schemas.Contact,
    Db.Schemas.Fax,
    Db.Schemas.PaymentAccount,
    Db.Schemas.Phone,
    Db.Schemas.Product,
    Db.Schemas.ProductBenefit,
    Db.Schemas.Industry,
    Db.Schemas.AccountGroupCluster,
    Db.Schemas.Cluster,
    Db.Schemas.User,
    Db.Schemas.AccountHierarchyOfEligibleDependent,
    Db.Schemas.Member,
    Db.Schemas.AccountGroupCoverageFund,
    Db.Schemas.ProductCoverage,
    Db.Schemas.Coverage,
    Db.Schemas.MemberProduct
  }

  alias Ecto.UUID

  def list_accounts do
    Account
    |> Repo.all
    |> Repo.preload([:account_group, :account_logs])
  end

  def list_active_accounts do
    Account
    |> where([a], a.status == "Active")
    |> Repo.all()
    |> Repo.preload([:account_group])
  end

  def list_account_groups do
    account = (
      from a in Account,
      where: not a.status in [
        "For Renewal",
        "For Activation",
        "Renewal Cancelled"],
      group_by: a.account_group_id,
      select: %{
        account_group_id: a.account_group_id,
        version: max(fragment("concat(?,'.',?,'.',?)",
                      a.major_version,
                      a.minor_version,
                      a.build_version))
      }
    )

    account_group = (
      from ag in AccountGroup,
      join: s in subquery(account), on: s.account_group_id == ag.id,
      join: a in Account, on: a.account_group_id == ag.id
      and (fragment("concat(?,'.',?,'.',?)",
            a.major_version,
            a.minor_version,
            a.build_version)) == s.version,
      order_by: ag.code,
      select: %{
        id: ag.id, code: ag.code, name: ag.name,
        start_date: a.start_date, end_date: a.end_date, status: a.status,
        version: s.version
      }
    )

    Repo.all(account_group)

    # AccountGroup
    # |> Repo.all()
    # |> Repo.preload([:account])
  end

  def list_versions(account_group_id) do
    Account
    |> where([a], a.account_group_id == ^account_group_id)
    |> Repo.all
    |> Repo.preload([:account_group, :account_logs])
  end

  def list_industry do
    Repo.all(Innerpeace.Db.Schemas.Industry)
  end

  def list_organization do
    Repo.all(Innerpeace.Db.Schemas.Organization)
  end

  def list_all_products do
    Product
    |> where([p], p.step == ^"8")
    |> Repo.all()
    |> Repo.preload([
      :product_benefits,
      :benefits,
      [
        product_coverages: :product_coverage_room_and_board,
        account_products: :member_products
      ]
    ])
  end

  def list_all_account_products(account_id) do
    query = (
      from ap in AccountProduct,
      where: ap.account_id == ^account_id,
      order_by: ap.rank,
      select: ap
    )
    query
    |> Repo.all
    |> Repo.preload([
        :member_products,
        account: [
          account_group: :members
        ],
        product: :benefits
      ])
  end

  def list_all_approver(account_group_id) do
    AccountGroupApproval
    |> where([aga], aga.account_group_id == ^account_group_id)
    |> Repo.all()
  end

  def preload_account_group(account) do
    account
    |> Repo.preload([:account, :account_hierarchy_of_eligible_dependents])
  end

  def preload_payment_account(account) do
    account
    |> Repo.preload([:payment_account])
  end

  def get_contact!(id), do: Contact |> Repo.get!(id)

  def get_account!(id) do
    Account
    |> Repo.get(id)
    |> Repo.preload([[account_products: :product], :account_logs, [account_group: :account_group_coverage_funds]])

    rescue
      e in RuntimeError -> nil
      Ecto.NoResultsError -> nil
      Ecto.MultipleResultsError -> nil
  end

  def get_account_group!(id), do: Repo.get_by(Account, account_group_id: id)

  def get_account_group(id) do
    AccountGroup
    |> Repo.get(id)
    |> check_accg()
  end

  defp check_accg(ag) when is_nil(ag), do: {:error, "Account not found"}

  defp check_accg(ag) do
    ag
    |> Repo.preload([
      :account,
      :account_logs,
      :account_group_address,
      :contacts,
      :payment_account,
      :members,
      :industry,
      :bank,
      account_group_contacts: [
        contact: [:phones, :fax]]
    ])
  end

  def get_account_with_account_group(account_id, account_group_id) do
    Account
    |> where([a], a.account_group_id == ^account_group_id
             and a.id == ^account_id)
    |> Repo.one()
  end

  def get_all_account_name do
    AccountGroup
    |> select([:name])
    |> Repo.all
  end

  def get_all_account_tin do
    PaymentAccount
    |> select([:account_tin])
    |> Repo.all
  end

  def get_all_account_group_address(account_group_id) do
    AccountGroupAddress
    |> where([aa], aa.account_group_id == ^account_group_id)
    |> Repo.all
  end

  def get_account_contact!(contact_id) do
    ac = Repo.get_by!(AccountGroupContact, contact_id: contact_id)
    Repo.get!(AccountGroup, ac.account_group_id)
  end

  def get_all_contacts(account_group_id) do
    ac =
      AccountGroupContact
      |> where([ac], ac.account_group_id == ^account_group_id)
      |> Repo.all

    if Enum.empty?(ac) do
      []
    else
      ac
      |> Ecto.assoc(:contact)
      |> Repo.all
      |> Repo.preload([:phones])
    end
  end

  def get_account_payment!(account_group_id) do
    PaymentAccount
    |> Repo.get_by(account_group_id: account_group_id)
    |> Repo.preload([:account_group, :account_logs])
  end

  def get_bank(account_group_id) do
    Bank
    |> Repo.get_by(account_group_id: account_group_id)
    |> Repo.preload([:account_group, :account_logs])
  end

  def get_summary_account(account) do
    AccountGroup
    |> Repo.get!(account.account_group_id)
    |> Repo.preload([
        :payment_account,
        :bank,
        :industry,
        :account_hierarchy_of_eligible_dependents,
        account_group_address: from(aga in AccountGroupAddress,
                                  order_by: aga.type),
        account_group_fulfillments: [fulfillment: [card_files: :file]],
        account_group_contacts:
        [contact: [:phones, :fax]],
        account_group_coverage_funds: :coverage
    ])
  end

  def get_product(id) do
    Product
    |> Repo.get(id)
    |> Repo.preload([
      :account_products,
      :payor,
      :logs,
      :product_condition_hierarchy_of_eligible_dependents,
      product_benefits: [
        :product_benefit_limits,
        benefit: [
          :created_by,
          :updated_by,
          :benefit_limits,
          benefit_procedures: :procedure,
          benefit_coverages: :coverage
        ]
      ],
      product_coverages: [
        :coverage,
        :product_coverage_room_and_board,
        product_coverage_limit_threshold: [
          product_coverage_limit_threshold_facilities: [:facility]
        ],
        product_coverage_facilities: [facility: [:category, :type]],
        product_coverage_risk_share: [
          product_coverage_risk_share_facilities: [
            :facility,
            product_coverage_risk_share_facility_payor_procedures: [:facility_payor_procedure]
          ]
        ]
      ],
      product_exclusions: [exclusion: [:exclusion_diseases, :exclusion_procedures]]
    ])
  end

  def get_account_group_address!(account_group_id, type) do
    AccountGroupAddress
    |> where([aa], aa.account_group_id == ^account_group_id
             and aa.type == ^type)
    |> Repo.one()
    |> Repo.preload([:account_group, :account_logs])
  end

  def get_account_product!(id) do
    AccountProduct
    |> Repo.get!(id)
    |> Repo.preload([product: :benefits])

    rescue
      e in RuntimeError -> nil
      Ecto.NoResultsError -> nil
      Ecto.MultipleResultsError -> nil
  end

  def get_all_account_product(account_id) do
    AccountProduct
    |> where([ap], ap.account_id == ^account_id)
    |> Repo.all
  end

  def get_approver!(id), do: Repo.get!(AccountGroupApproval, id)

  def get_product_benefit!(product_id) do
    ProductBenefit
    |> where([pb], pb.product_id == ^product_id)
    |> select([pb], %{product_benefit_id: pb.id})
    |> Repo.all
  end

  def create_account_group(attrs \\ %{}) do
    %AccountGroup{}
    |> AccountGroup.changeset(attrs)
    |> Repo.insert()
  end

  def create_account(attrs \\ %{}) do
    %Account{}
    |> Account.changeset(attrs)
    |> Repo.insert()
  end

  def create_address(attrs \\ %{}) do
    %AccountGroupAddress{}
    |> AccountGroupAddress.changeset(attrs)
    |> Repo.insert()
  end

  def create_renew(attrs \\ %{}) do
    %Account{}
    |> Account.changeset_renew(attrs)
    |> Repo.insert()
  end

  def create_renew_cluster(attrs \\ %{}) do
    %Account{}
    |> Account.changeset_renew_cluster(attrs)
    |> Repo.insert()
  end

  def create_contact(attrs \\ %{}) do
    %Contact{}
    |> Contact.changeset(attrs)
    |> Repo.insert()
  end

  def create_account_contact(attrs \\ %{}) do
    %AccountGroupContact{}
    |> AccountGroupContact.changeset(attrs)
    |> Repo.insert()
  end

  def create_contact_no(attrs \\ %{}) do
    %Phone{}
    |> Phone.changeset(attrs)
    |> Repo.insert()
  end

  def create_fax(attrs \\ %{}) do
    %Fax{}
    |> Fax.changeset(attrs)
    |> Repo.insert()
  end

  def create_payment(attrs \\ %{}) do
    %PaymentAccount{}
    |> PaymentAccount.changeset_account(attrs)
    |> Repo.insert()
  end

  def create_payment_v2(attrs \\ %{}) do
    %PaymentAccount{}
    |> PaymentAccount.changeset_account_v2(attrs)
    |> Repo.insert()
  end

  def create_bank_account(attrs \\ %{}) do
    %Bank{}
    |> Bank.changeset(attrs)
    |> Repo.insert()
  end

  def create_account_product(attrs \\ %{}) do
    {:ok, account_product} =
      %AccountProduct{}
      |> AccountProduct.changeset(attrs)
      |> Repo.insert()

    if Enum.empty?(get_product_benefit!(account_product.product_id)) == false do
      Enum.each(get_product_benefit!(account_product.product_id), fn(product_benefit) ->
        product_benefit
        |> Map.merge(%{account_product_id: account_product.id})
        |> create_account_product_benefit
      end)
    end
  end

  def create_account_product_benefit(attrs \\ %{}) do
    %AccountProductBenefit{}
    |> AccountProductBenefit.changeset(attrs)
    |> Repo.insert()
  end

  def create_account_approver(attrs \\ %{}) do
    %AccountGroupApproval{}
    |> AccountGroupApproval.changeset(attrs)
    |> Repo.insert()
  end

  def update_photo(%AccountGroup{} = account_group, attrs) do
    account_group
    |> AccountGroup.changeset_photo(attrs)
    |> Repo.update()
  end

  def update_account(%Account{} = account, attrs) do
    account
    |> Account.changeset(attrs)
    |> Repo.update()
  end

  def update_account_group(%AccountGroup{} = account_group, attrs) do
    account_group
    |> AccountGroup.changeset(attrs)
    |> Repo.update()
  end

  def update_account_step(nil, attrs), do: nil
  def update_account_step(%Account{} = account, attrs) do
    account
    |> Account.changeset_step(attrs)
    |> Repo.update()
  end

  def update_account_group_address(%AccountGroupAddress{} = a_address, attrs) do
    a_address
    |> AccountGroupAddress.changeset(attrs)
    |> Repo.update()
  end

  def update_account_contact(%Contact{} = contact, attrs) do
    contact
    |> Contact.changeset(attrs)
    |> Repo.update()
  end

  def update_account_payment(%PaymentAccount{} = payment_account, attrs) do
    payment_account
    |> PaymentAccount.changeset_account(attrs)
    |> Repo.update()
  end

  def update_account_payment_v2(%PaymentAccount{} = payment_account, attrs) do
    payment_account
    |> PaymentAccount.changeset_account_v2(attrs)
    |> Repo.update()
  end

  def update_account_product(%AccountProduct{} = account_product, attrs) do
    account_product
    |> AccountProduct.changeset(attrs)
    |> Repo.update()
  end

  def update_bank_account(%Bank{} = bank, attrs, account_group_id) do
    bank
    |> Bank.changeset(attrs)
    |> Repo.update()
  end

  def update_bank_account(nil, attrs, account_group_id) do
    attrs
    |> Map.merge(%{"account_group_id" => account_group_id})
    |> create_bank_account
  end

  def update_account_version(%Account{} = account, attrs) do
    account
    |> Account.changeset_version(attrs)
    |> Repo.update()
  end

  def update_account_group_financial(%AccountGroup{} = account_group, attrs) do
    account_group
    |> AccountGroup.changeset_financial(attrs)
    |> Repo.update()
  end

  def delete_account(account_group_id) do
    account_group =
      account_group_id
      |> get_account_group()
      |> Repo.preload([:members])

      if Enum.empty?(account_group.members) do
        account_group
        |> Repo.delete!
      else
        false
      end
  end

  def delete_account_group_address(%AccountGroupAddress{} = account_address) do
    Repo.delete(account_address)
  end

  def delete_all_account_group_ddress(%AccountGroupAddress{} = a_address) do
    Repo.delete_all(a_address)
  end

  def delete_contact(account_group_id, contact_id) do
    AccountGroupContact
    |> where([ac], ac.account_group_id == ^account_group_id
             and ac.contact_id == ^contact_id)
    |> Repo.delete_all()
  end

  def delete_number(contact_id) do
    Phone
    |> where([p], p.contact_id == ^contact_id)
    |> Repo.delete_all()
  end

  def delete_fax(contact_id) do
    Fax
    |> where([f], f.contact_id == ^contact_id)
    |> Repo.delete_all()
  end

  def delete_payment_account(account_group_id) do
    PaymentAccount
    |> where([pa], pa.account_group_id == ^account_group_id)
    |> Repo.delete_all()
  end

  def delete_bank(account_group_id) do
    bank =
      Bank
      |> Repo.get_by(account_group_id: account_group_id)
      |> Repo.preload(:practitioner)

    cond do
      is_nil(bank) == false && is_nil(bank.practitioner) == false ->
        Repo.update(change bank, account_group_id: nil)
      is_nil(bank) == false ->
        Repo.delete(bank)
      true ->
        nil
    end
  end

  def delete_account_product!(%AccountProduct{} = account_product) do
    account_product
    |> Repo.delete()
  end

  def delete_all_account_product(account_id, standard) do
    AccountProduct
    |> where([ap], ap.account_id == ^account_id
             and ap.standard_product == ^standard)
    |> Repo.delete_all
  end

  def delete_approver!(%AccountGroupApproval{} = account_group_approval) do
    Repo.delete(account_group_approval)
  end

  def change_account(%Account{} = account) do
    Account.changeset(account, %{})
  end

  def change_account_group(%AccountGroup{} = account_group) do
    AccountGroup.changeset(account_group, %{})
  end

  # Extend Account in Account Page
  def update_account_expiry(%Account{} = account, attrs) do
    account
    |> Account.changeset_account_expiry(attrs)
    |> Repo.update()
  end

  def update_account_cancel(%Account{} = account, attrs) do
    account
    |> Account.changeset_cancel_account(attrs)
    |> Repo.update()
  end
  # End of Extend Account in Account Page

  # Suspend Account in Account Page
  def suspend_account(%Account{} = account, attrs) do
    account
    |> Account.changeset_suspend_account(attrs)
    |> Repo.update()
  end
  # End of Suspend Account in Account Page

  # Account Logs in Account Page

  def create_account_log(user, changeset, tab) do
    if Enum.empty?(changeset.changes) == false do
      changes = changes_to_string(changeset)
      message = "#{user.username} edited #{changes} in #{tab} tab."

      insert_log(%{
        account_group_id: changeset.data.id,
        user_id: user.id,
        message: message
      })
    end
  end

  def create_account_group_log(user, changeset, tab) do
    if Enum.empty?(changeset.changes) == false do
      changes = changes_to_string(changeset)
      message = "#{user.username} edited #{changes} in #{tab} tab."

      insert_log(%{
        account_group_id: changeset.data.account_group.id,
        user_id: user.id,
        message: message
      })
    end
  end

  def create_contact_log(account_group_id, user, changeset, tab) do
    if Enum.empty?(changeset.changes) == false do
      changes = changes_to_string(changeset)
      message = "#{user.username} edited #{changes} in #{tab} tab."
      insert_log(%{
        account_group_id: account_group_id,
        contact_id: changeset.data.id,
        user_id: user.id,
        message: message
      })
    end
  end

  def create_payment_log(user, changeset, tab) do
    if Enum.empty?(changeset.changes) == false do
      changes = bank_changes_to_string(changeset)
      message = "#{user.username} edited #{changes} in #{tab} tab."

      insert_log(%{
        account_group_id: changeset.data.account_group.id,
        user_id: user.id,
        message: message
      })
    end
  end

  def create_bank_log(user, changeset, tab) do
    if Enum.empty?(changeset.changes) == false do
      changes = bank_changes_to_string(changeset)
      message = "#{user.username} edited #{changes} in #{tab} tab."

      insert_log(%{
        account_group_id: changeset.data.account_group.id,
        user_id: user.id,
        message: message
      })
    end
  end

  def create_added_contact_log(account_group_id, user, contact, tab) do
      message = "#{user.username} added Contact with Name #{contact.last_name} and Contact Type #{contact.type} in #{tab} tab."
      insert_log(%{
        account_group_id: account_group_id,
        contact_id: contact.id,
        user_id: user.id,
        message: message
      })
  end

  def create_deleted_contact_log(account_group_id, user, contact) do
      message = "#{user.username} deleted Contact with Name #{contact.last_name} and Contact Type #{contact.type} in Contacts tab."
      insert_log(%{
        account_group_id: account_group_id,
        contact_id: contact.id,
        user_id: user.id,
        message: message
      })
  end

  def create_added_approver_log(account_group_id, user, changeset) do
      message = "#{user.username} added Approver with Name #{changeset.name}, Department #{changeset.department}, Mobile No. #{changeset.mobile} and Email address #{changeset.email} in Financial tab."
      insert_log(%{
        account_group_id: account_group_id,
        user_id: user.id,
        message: message
      })
  end

  def create_deleted_approver_log(account_group_id, user, changeset) do
      message = "#{user.username} deleted Approver with Name #{changeset.name}, Department #{changeset.department}, Mobile No. #{changeset.mobile} and Email address #{changeset.email} in Financial tab."
      insert_log(%{
        account_group_id: account_group_id,
        user_id: user.id,
        message: message
      })
  end

  def create_photo_log(user, changeset, tab) do
    if Enum.empty?(changeset.changes) == false do
      message = "#{user.username} updated Account Photo to #{changeset.changes.photo.file_name} in #{tab} tab."
      insert_log(%{
        account_group_id: changeset.data.id,
        user_id: user.id,
        message: message
      })
    end
  end

  def create_delete_photo_log(user, account_group_id, photo) do
      message = "#{user.username} removed Account Photo #{photo} in General tab."
      insert_log(%{
        account_group_id: account_group_id,
        user_id: user.id,
        message: message
      })
  end

  def create_suspend_logs(account_group_id, user, params) do
      changes = insert_changes_to_string(params)
      message = "#{user.username} suspended an account where #{changes}."
      insert_log(%{
        account_group_id: account_group_id,
        user_id: user.id,
        message: message
      })
  end

  def create_reactivate_logs(account_group_id, user, params) do
      changes = insert_changes_to_string(params)
      message = "#{user.username} reactivated an account where #{changes}."
      insert_log(%{
        account_group_id: account_group_id,
        user_id: user.id,
        message: message
      })
  end

  def create_cancel_logs(account_group_id, user, params) do
      changes = insert_changes_to_string(params)
      message = "#{user.username} cancelled an account where #{changes}."
      insert_log(%{
        account_group_id: account_group_id,
        user_id: user.id,
        message: message
      })
  end

  def create_extend_logs(account_group_id, user, params) do
      changes = insert_changes_to_string(params)
      message = "#{user.username} extended an account expiry date where #{changes}."
      insert_log(%{
        account_group_id: account_group_id,
        user_id: user.id,
        message: message
      })
  end

  def create_renew_logs(account_group_id, user, params) do
      changes = insert_changes_to_string(params)
      message = "#{user.username} renewed an account where #{changes}. New account version is created."
      insert_log(%{
        account_group_id: account_group_id,
        user_id: user.id,
        message: message
      })
  end

  def create_retract_logs(account_group_id, user, params) do
      changes = insert_changes_to_string(params)
      message = "#{user.username} retracted a movement where #{changes}."
      insert_log(%{
        account_group_id: account_group_id,
        user_id: user.id,
        message: message
      })
  end

  def create_activation_logs(account_group_id, user, params) do
    changes = insert_changes_to_string(params)
    message = "#{user.username} activated an account where #{changes}."
    insert_log(%{
      account_group_id: account_group_id,
      user_id: user.id,
      message: message
    })
  end

  def create_cancelled_renewal_logs(account_group_id, user, params) do
    changes = insert_changes_to_string(params)
    message = "#{user.username} cancelled renewal of an account where #{changes}."
    insert_log(%{
      account_group_id: account_group_id,
      user_id: user.id,
      message: message
    })
  end

  def create_reactivate_logs(account_group_id, user, params) do
    changes = insert_changes_to_string(params)
    message = "#{user.username} reactivated an account where #{changes}."
    insert_log(%{
      account_group_id: account_group_id,
      user_id: user.id,
      message: message
    })
end

  def create_cancel_logs(account_group_id, user, params) do
      changes = insert_changes_to_string(params)
      message = "#{user.username} cancelled an account where #{changes}."
      insert_log(%{
        account_group_id: account_group_id,
        user_id: user.id,
        message: message
      })
  end

  def create_extend_logs(account_group_id, user, params) do
      changes = insert_changes_to_string(params)
      message = "#{user.username} extended an account where #{changes}."
      insert_log(%{
        account_group_id: account_group_id,
        user_id: user.id,
        message: message
      })
  end

  def create_renew_logs(account_group_id, user, params) do
      changes = insert_changes_to_string(params)
      message = "#{user.username} renewed an account where #{changes}. New account version is created."
      insert_log(%{
        account_group_id: account_group_id,
        user_id: user.id,
        message: message
      })
  end

  def create_retract_logs(account_group_id, user, params) do
      changes = insert_changes_to_string(params)
      message = "#{user.username} retracted a movement where #{changes}."
      insert_log(%{
        account_group_id: account_group_id,
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

  def insert_changes_to_string(params) do
    changes = for {key, new_value} <- params, into: [] do
      "#{transform_atom(key)} is #{new_value}"
    end
    changes |> Enum.join(", ")
  end

  def bank_changes_to_string(changeset) do
    changes = for {key, new_value} <- changeset.changes, into: [] do
      if transform_atom(key) == "Account Name" do
        "Bank Name from #{Map.get(changeset.data, key)} to #{new_value}"
      end
      if transform_atom(key) == "Account No" do
        "Bank No. from #{Map.get(changeset.data, key)} to #{new_value}"
      else
        "#{transform_atom(key)} from #{Map.get(changeset.data, key)} to #{new_value}"
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
    changeset = AccountLog.changeset(%AccountLog{}, params)
    Repo.insert!(changeset)
  end

  # End of Account Logs in Account Page

  def get_all_account_groups do
    AccountGroup
    |> Repo.all
    |> Repo.preload(account: from(a in Account, where: a.status == "Active"))
  end

  # Add Comment in Account Page

  def create_comment(attrs \\ %{}) do
    %AccountComment{}
    |> AccountComment.changeset(attrs)
    |> Repo.insert()
  end

  def get_all_comments(account_id) do
    AccountComment
    |> where([a], a.account_id == ^account_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all
    |> Repo.preload([:user, :account])
  end

  def get_comment_count(account_id) do
    AccountComment
    |> where([a], a.account_id == ^account_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all
    |> Enum.count
  end

  def change_account_comment(%AccountComment{} = account_comment) do
    AccountComment.changeset(account_comment, %{})
  end

  # End of Add Comment in Account Page

  def account_code_checker(code) do
    count = Enum.count(list_accounts)
    acc_code = Enum.join([code, "00#{count}"])

    empty =
      AccountGroup
      |> where([ag], ag.code == ^acc_code)
      |> Repo.all

    if Enum.empty?(empty) do
     acc_code
    else
      count = count + 2
      Enum.join([code, "00#{count}"])
    end
  end

  def insert_or_update_account(params) do
    account = get_account_by_account_group(params.account_group_id)
    if is_nil(account) do
      create_an_account(params)
    else
      update_an_accounts(account.id, params)
    end
  end

  def get_account_by_account_group(account_group_id) do
    Account
    # |> Repo.get_by(account_group_id: account_group, major_version: 1)
    |> where([a], a.account_group_id == ^account_group_id
             and a.status == ^"Active")
    |> limit(1)
    |> Repo.one
    |> Repo.preload([account_products:
                     [product:
                      [product_benefits:
                       [benefit: [
                         :created_by,
                         :updated_by,
                         :benefit_limits,
                         benefit_procedures: :procedure,
                         benefit_coverages: :coverage]
                       ],
                      product_coverages: [
                        :coverage,
                        product_coverage_facilities: [facility: [:category, :type]]
                      ]
                      ]
                     ]
    ])
  end

  def get_account(id) do
    Account
    |> Repo.get!(id)
    |> Repo.preload([account_products:
                     [product:
                      [product_benefits:
                       [benefit: [
                         :created_by,
                         :updated_by,
                         :benefit_limits,
                         benefit_procedures: :procedure,
                         benefit_coverages: :coverage]
                       ],
                      product_coverages: [
                        :coverage,
                        product_coverage_facilities: [facility: [:category, :type]]
                      ]
                      ]
                     ]
    ])
  end

  def create_an_account(account_param) do
    %Account{}
    |> Account.changeset(account_param)
    |> Repo.insert
  end

  def update_an_accounts(id, account_param) do
    id
    |> get_account()
    |> Account.changeset(account_param)
    |> Repo.update
  end

  def activate_status(%Account{} = account, attrs) do
    account
    |> Account.changeset_status(attrs)
    |> Repo.update()
  end

  def renewal_cancel(%Account{} = account, attrs) do
    account
    |> Account.changeset_status(attrs)
    |> Repo.update()
  end

  def get_latest_account(account_group_id) do
    Account
    |> where([a], a.account_group_id == ^account_group_id)
    |> order_by([a], desc: a.inserted_at)
    |> limit(1)
    |> Repo.one
  end

  def update_all_active(%Account{} = account) do
    start_date =
      account.start_date
      |> Ecto.Date.cast!()
      |> Ecto.Date.compare(Ecto.Date.utc)

    if start_date == :eq || start_date == :lt do
      Account
      |> where([a], a.account_group_id == ^account.account_group_id
               and a.status == ^"Active")
      |> Repo.update_all(set: [status: "Lapsed"])

      Account
      |> where([a], a.id == ^account.id)
      |> Repo.update_all(set: [status: "Active"])
    end
  end

  def clone_account_product(old_account, new_account) do
    ap =
      AccountProduct
      |> where([ap], ap.account_id == ^old_account.id)
      |> select([ap], %{product_id: ap.product_id})
      |> Repo.all()
    if Enum.empty?(ap) == false do
      Enum.each(ap, fn(product) ->
        product.product_id
        |> get_product()
        |> Map.from_struct
        |> Map.put(:product_id, product.product_id)
        |> Map.put(:account_id, new_account.id)
        |> create_account_product
      end)
    end
  end

  def reactivate_account(%Account{} = account, attrs) do
    account
    |> Account.changeset_reactivate_account(attrs)
    |> Repo.update()
  end

  # Seeds for Account Group Address

  def insert_or_update_account_group_address(params) do
    account_group_address =
      get_account_group_address_by_account_group(params.account_group_id)
    if is_nil(account_group_address) do
      create_one_account_group_address(params)
    else
      update_one_account_group_address(account_group_address.id, params)
    end
  end

  def get_account_group_address_by_account_group(account_group) do
    AccountGroupAddress
    |> Repo.get_by(account_group_id: account_group)
  end

  def create_one_account_group_address(attrs \\ %{}) do
    %AccountGroupAddress{}
    |> AccountGroupAddress.changeset(attrs)
    |> Repo.insert()
  end

  def update_one_account_group_address(id, account_group_address_param) do
    id
    |> get_one_account_group_address()
    |> AccountGroupAddress.changeset(account_group_address_param)
    |> Repo.update
  end

  def get_one_account_group_address(id) do
    AccountGroupAddress
    |> Repo.get!(id)
  end

  # End of Seeds for Account Group Address

  # Seeds for Account Group Contact

  def insert_or_update_account_group_contact(params) do
    account_group_contact =
      get_account_group_contact(params.account_group_id, params.contact_id)
    if is_nil(account_group_contact) do
      create_one_account_group_contact(params)
    else
      update_one_account_group_contact(account_group_contact.id, params)
    end
  end

  def get_account_group_contact(account_group, contact) do
    AccountGroupContact
    |> Repo.get_by(account_group_id: account_group, contact_id: contact)
  end

  def create_one_account_group_contact(attrs \\ %{}) do
    %AccountGroupContact{}
    |> AccountGroupContact.changeset(attrs)
    |> Repo.insert()
  end

  def update_one_account_group_contact(id, account_group_contact_param) do
    id
    |> get_one_account_group_contact()
    |> AccountGroupContact.changeset(account_group_contact_param)
    |> Repo.update
  end

  def get_one_account_group_contact(id) do
    AccountGroupContact
    |> Repo.get!(id)
  end

  # End of Seeds for Account Group Contact

  # Seeds for Payment Account

  def insert_or_update_payment_account(params) do
    payment_account =
      get_payment_account_by_account_group_io(params.account_group_id)
    if is_nil(payment_account) do
      create_one_payment_account(params)
    else
      update_one_payment_account(payment_account.id, params)
    end
  end

  def get_payment_account_by_account_group_io(account_group) do
    PaymentAccount
    |> Repo.get_by(account_group_id: account_group)
  end

  def create_one_payment_account(attrs \\ %{}) do
    %PaymentAccount{}
    |> PaymentAccount.changeset_account(attrs)
    |> Repo.insert()
  end

  def update_one_payment_account(id, payment_account_param) do
    id
    |> get_one_payment_account()
    |> PaymentAccount.changeset_account(payment_account_param)
    |> Repo.update
  end

  def get_one_payment_account(id) do
    PaymentAccount
    |> Repo.get!(id)
  end

  # End of Seeds for Payment Account

  def expired_account(account_group_id) do
    accounts =
      Account
      |> where([a], a.account_group_id == ^account_group_id
               and a.status == ^"Active")
      |> Repo.all()

    for account <- accounts do
      end_date =
        account.end_date
        |> Ecto.Date.cast!()
        |> Ecto.Date.compare(Ecto.Date.utc)

      if end_date == :eq || end_date == :lt do
        Account
        |> where([a], a.id == ^account.id)
        |> Repo.update_all(set: [status: "Lapsed"])

        update_member_status(account_group_id, "Lapsed")
      end
    end
  end

  def update_account_status() do
    accounts =
      Account
      |> where([a],
        a.start_date == ^Ecto.Date.utc() and
        a.status == "Pending" or
        a.status == "For Renewal")
      |> Repo.update_all(set: [status: "Active"])

  end


  def active_account(account_group_id) do
    accounts =
      Account
      |> where([a],
          a.account_group_id == ^account_group_id and
          a.status == ^"Pending" or
          a.status == ^"For Renewal")
      |> Repo.all()

    for account <- accounts do
      start_date =
        account.start_date
        |> Ecto.Date.cast!()
        |> Ecto.Date.compare(Ecto.Date.utc)

      if start_date == :eq || start_date == :lt do
        Account
        |> where([a], a.account_group_id == ^account_group_id
                 and a.status == ^"Active")
        |> Repo.update_all(set: [status: "Lapsed"])

        Account
        |> where([a], a.id == ^account.id)
        |> Repo.update_all(set: [status: "Active"])
      end
    end
  end

  def reactivation_account(account_group_id) do
    accounts =
      Account
      |> where([a], a.account_group_id == ^account_group_id
               and a.status == ^"Suspended")
      |> Repo.all()

    for account <- accounts do

     if is_nil(account.reactivate_date) == false do
       reactivate_date =
         account.reactivate_date
         |> Ecto.Date.cast!()
         |> Ecto.Date.compare(Ecto.Date.utc)

        if reactivate_date == :eq || reactivate_date == :lt do
          Account
          |> where([a], a.account_group_id == ^account_group_id
                   and a.id == ^account.id)
          |> Repo.update_all(set: [status: "Active"])
        end
     end
    end
  end

  def suspension_account(account_group_id) do
    accounts =
      Account
      |> where([a], a.account_group_id == ^account_group_id
               and a.status == ^"Active")
      |> Repo.all()

    for account <- accounts do

     if not is_nil (account.suspend_date) do
       suspend_date =
         account.suspend_date
         |> Ecto.Date.cast!()
         |> Ecto.Date.compare(Ecto.Date.utc)

        if suspend_date == :eq || suspend_date == :lt do
          Account
          |> where([a], a.account_group_id == ^account_group_id
                   and a.id == ^account.id)
          |> Repo.update_all(set: [status: "Suspended"])

          update_member_status(account_group_id, "Suspended")
        end
     end
    end
  end

  def cancellation_account(account_group_id) do
    accounts =
      Account
      |> where([a], a.account_group_id == ^account_group_id
               and a.status == ^"Active" or a.status == ^"Suspended")
      |> Repo.all()

    for account <- accounts do

     if not is_nil (account.cancel_date) do
       cancel_date =
         account.cancel_date
         |> Ecto.Date.cast!()
         |> Ecto.Date.compare(Ecto.Date.utc)

        if cancel_date == :eq || cancel_date == :lt do
          Account
          |> where([a], a.account_group_id == ^account_group_id
                   and a.id == ^account.id)
          |> Repo.update_all(set: [status: "Cancelled"])

          update_member_status(account_group_id, "Cancelled")
        end
     end
    end
  end

  def update_member_status(account_group_id, status) do
    account =
      Account
      |> join(:inner, [a], ag in AccountGroup, a.account_group_id == ag.id)
      |> where([a, ag], ag.id == ^account_group_id and a.status == ^"Active")
      |> Repo.all()

    if Enum.empty?(account) do
      Member
      |> join(:inner, [m], ag in AccountGroup, m.account_code == ag.code)
      |> where([m, ag], ag.id == ^account_group_id)
      |> Repo.update_all(set: [status: status])
    end
    # FP: latest version status
  end

  def forced_status(account, params) do
    cond do
      params["remarks"] == "This Account is Active." ->
        account
        |> Account.changeset_status(%{status: "Active"})
        |> Repo.update()
      params["remarks"] == "This Account is Lapsed." ->
        account
        |> Account.changeset_status(%{status: "Lapsed"})
        |> Repo.update()
      params["remarks"] == "This Account is Suspended." ->
        account
        |> Account.changeset_status(%{status: "Suspended"})
        |> Repo.update()
      params["remarks"] == "This Account is Cancelled." ->
        account
        |> Account.changeset_status(%{status: "Cancelled"})
        |> Repo.update()
      true ->
        "Do nothing"
    end
  end

  def check_contact_type(account_group_id, type) do
    AccountGroupContact
    |> join(:inner, [agc], c in Contact, agc.contact_id == c.id)
    |> where([agc, c], agc.account_group_id == ^account_group_id
             and c.type == ^type)
    |> Repo.all()
    |> Enum.count
  end

  def get_active_account(account_group_id) do
    Account
    |> where([a], a.account_group_id == ^account_group_id
             and a.status == ^"Active")
    |> limit(1)
    |> Repo.one
    |> Repo.preload([:account_group, :account_logs])
  end

  def get_active_or_pending_account(account_group_id) do
    Account
    |> where([a], a.account_group_id == ^account_group_id
             and a.status == ^"Active" or a.status == ^"Pending")
    |> limit(1)
    |> Repo.one
    |> Repo.preload([:account_group, :account_logs])
  end

  def get_for_renewal_account_version(account_group_id) do
    Account
    |> where([a], a.account_group_id == ^account_group_id
             and a.status == ^"For Renewal")
    |> order_by([a], desc: a.inserted_at)
    |> limit(1)
    |> Repo.one
  end

  def download_accounts(params) do
    account_codes = params["params"]

    first_version = (
      from a in Account,
      where: a.major_version == 1
    )

    latest_version = (
      from a in Account,
      where: not a.status in [
        "For Renewal",
        "For Activation",
        "Renewal Cancelled",
        "Draft"],
      group_by: a.account_group_id,
      select: %{
        account_group_id: a.account_group_id,
        version: max(
          fragment("concat(?,'.',?,'.',?)",
          a.major_version,
          a.minor_version,
          a.build_version)
        )
      }
    )

    query = (
      from ag in AccountGroup,
      join: fv in subquery(first_version), on: fv.account_group_id == ag.id,
      join: lv in subquery(latest_version), on: lv.account_group_id == ag.id,
      join: a in Account, on: a.account_group_id == ag.id
      and (fragment("concat(?,'.',?,'.',?)",
           a.major_version,
           a.minor_version,
           a.build_version)) == lv.version,
      join: pa in PaymentAccount, on: pa.account_group_id == ag.id,
      join: i in Industry, on: i.id == ag.industry_id,
      left_join: ac in AccountGroupCluster, on: ac.account_group_id == ag.id,
      left_join: c in Cluster, on: c.id == ac.cluster_id,
      left_join: u in User, on: u.id == fv.created_by,
      where: ag.code in ^account_codes,
      order_by: ag.code,
      select: %{
        code: ag.code, name: ag.name, segment: ag.segment, industry: i.code,
        funding: pa.funding_arrangement, cluster_code: c.code,
        cluster_name: c.name, start_date: a.start_date,
        end_date: a.end_date, status: a.status, version: lv.version,
        created_by: u.username, date_created: fv.inserted_at
      }
    )

    query = Repo.all(query)
  end

  def retract_movement(movement, account_id) do
    account = get_account!(account_id)
    case movement do
      "Cancellation" ->
        Repo.update(change account, cancel_date: nil)
      "Reactivation" ->
        Repo.update(change account, reactivate_date: nil)
      "Suspension" ->
        Repo.update(change account, suspend_date: nil)
      _ ->
        {:error, "Movement not found."}
    end
  end

  defp valid_uuid?(id) do
    case UUID.cast(id) do
      {:ok, id} ->
        {true, id}
      :error ->
        {:invalid_id}
    end
  end

  # Product Tier
  def update_product_tier(id, rank) do
    with {true, id} <- valid_uuid?(id)
    do
      try do
        rank = String.to_integer(rank)
      rescue
        ArgumentError ->
          {:error, "Error in Updating Product Tier"}
      end

      account_product =
        get_account_product!(id)

      if is_nil(account_product) do
        {:error, "No Product Tier Found"}
      else
        account_product
        |> AccountProduct.changeset_update_tier(%{rank: rank})
        |> Repo.update()
      end
    else
      {:invalid_id} ->
          {:error, "Invalid UUID"}
    end
  end

  def check_last_ap_rank(id) do
    query = (
      from ap in AccountProduct,
      where: ap.account_id == ^id,
      select: ap.rank
    )

    ap_last_rank =
      query
      |> Repo.all
      |> List.last

    if ap_last_rank != nil do
      ap_last_rank + 1
    else
      1
    end
  end

  # Member Batch Upload
  def get_account_by_code(code) do
    ag =
      AccountGroup
      |> where([ag], ag.code == ^code)
      |> Repo.all()
      |> List.first()

    if is_nil(ag) do
      {:account_not_found}
    else
      ag
    end
  end

  def get_hoed(account_group, civil_status) do
    ag = account_group
    case String.downcase(civil_status) do
      "separated" ->
         civil_status = "Married"
      "annulled" ->
         civil_status = "Single Parent"

      "widow/widower" ->
         civil_status = "Single Parent"
      _ ->
        civil_status
    end

    hierarchy_type = [civil_status, "employee"]

    htype =
      hierarchy_type
      |> Enum.join(" ")
      |> String.downcase()

    query =
      from ahoed in Ecto.assoc(ag, :account_hierarchy_of_eligible_dependents),
       where: fragment("lower(?)", ahoed.hierarchy_type) == ^htype,
       order_by: [asc: ahoed.ranking]

    Repo.all(query)
  end

  def get_account_product_by_code(account_id, product_code) do
    AccountProduct
    |> join(:inner, [ap], a in Account, ap.account_id == a.id)
    |> join(:inner, [ap, a], p in Product, ap.product_id == p.id)
    |> where([ap, a, p], a.id == ^account_id and p.code == ^product_code)
    |> Repo.all()
  end

  def get_member_product_by_code(product_code) do
    MemberProduct
    |> join(:inner, [mp], ap in AccountProduct, mp.account_product_id == ap.id)
    |> join(:inner, [mp, ap], p in Product, ap.product_id == p.id)
    |> where([mp, ap, p], p.product_code == ^product_code)
    |> Repo.all()
  end

  def insert_or_update_account_hoed(params) do
    account_hoed =
      AccountHierarchyOfEligibleDependent
      |> where([ahoed], ahoed.account_group_id == ^params.account_group_id
               and ahoed.hierarchy_type == ^params.hierarchy_type
               and ahoed.dependent == ^params.dependent)
      |> Repo.one()

    if is_nil(account_hoed) do
      create_an_account_hoed(params)
    else
      update_an_account_hoed(account_hoed.id, params)
    end
  end

  def create_an_account_hoed(account_hoed_param) do
    %AccountHierarchyOfEligibleDependent{}
    |> AccountHierarchyOfEligibleDependent.changeset(account_hoed_param)
    |> Repo.insert
  end

  def update_an_account_hoed(id, account_hoed_param) do
    account_hoed =
      AccountHierarchyOfEligibleDependent
      |> Repo.get(id)

    account_hoed
    |> AccountHierarchyOfEligibleDependent.changeset(account_hoed_param)
    |> Repo.update
  end

  def clear_account_hierarchy(account_id) do
    account = get_account!(account_id)
    AccountHierarchyOfEligibleDependent
    |> where([ahoed], ahoed.account_group_id == ^account.account_group_id)
    |> Repo.delete_all()
  end

  def insert_account_hierarchy(account_group_id, hierarchy_type, dependent, ranking) do
    params = %{
      account_group_id: account_group_id,
      hierarchy_type: hierarchy_type,
      dependent: dependent,
      ranking: ranking
    }
    changeset = AccountHierarchyOfEligibleDependent.changeset(%AccountHierarchyOfEligibleDependent{}, params)
    Repo.insert(changeset)
  end

  def update_account_step(account_group_id, step) do
    Account
    |> Repo.get(account_group_id)
    |> Account.changeset_step(%{step: step})
    |> Repo.update
  end

  def get_all_account(account_group_id) do
    Account
    |> where([a], a.account_group_id == ^account_group_id)
    |> order_by([a], desc: a.inserted_at)
    |> Repo.all()
  end
  #account product seed
  def insert_or_update_account_product(params) do
    account_product = get_ap_by_account_product(params.account_id, params.product_id)
    if is_nil(account_product) do
      create_an_account_product(params)
    else
      update_an_account_product(account_product.id, params)
    end
  end

  def get_ap_by_account_product(account_id, product_id) do
    AccountProduct
    |> Repo.get_by(account_id: account_id, product_id: product_id)
  end

  def get_account_product(id) do
    AccountProduct
    |> Repo.get!(id)
  end

  def create_an_account_product(account_product_param) do
    %AccountProduct{}
    |> AccountProduct.changeset(account_product_param)
    |> Repo.insert
  end

  def update_an_account_product(id, account_product_param) do
    id
    |> get_account_product()
    |> AccountProduct.changeset(account_product_param)
    |> Repo.update
  end

  def insert_or_update_account_product_benefit(params) do
    account_product_benefit = get_apb_by_account_product_benefit(params)
    if is_nil(account_product_benefit) do
      create_an_account_product_benefit(params)
    else
      update_an_account_product_benefit(account_product_benefit.id, params)
    end
  end

  def get_apb_by_account_product_benefit(params) do
    AccountProductBenefit
    |> Repo.get_by(account_product_id: params.account_product_id, product_benefit_id: params.product_benefit_id)
  end

  def get_account_product_benefit(id) do
    AccountProductBenefit
    |> Repo.get!(id)
  end

  def create_an_account_product_benefit(account_product_benefit_param) do
    %AccountProductBenefit{}
    |> AccountProductBenefit.changeset(account_product_benefit_param)
    |> Repo.insert
  end

  def update_an_account_product_benefit(id, account_product_benefit_param) do
    id
    |> get_account_product_benefit()
    |> AccountProductBenefit.changeset(account_product_benefit_param)
    |> Repo.update
  end

  def insert_enrollment_period(account_group_id, params) do
    account_group =
      account_group_id
      |> get_account_group
      |> preload_account_group
    params = %{
      principal_enrollment_period: params["pep"],
      dependent_enrollment_period: params["dep"],
      pep_day_or_month: params["pep_dom"],
      dep_day_or_month: params["dep_dom"]
    }
    account_group
    |> AccountGroup.enrollment_period_changeset(params)
    |> Repo.update()
  end

  def get_all_ag_coverage_fund(account_group_id) do
    AccountGroupCoverageFund
    |> where([agcf], agcf.account_group_id == ^account_group_id)
    |> Repo.all()
    |> Repo.preload(:coverage)
  end

  def insert_coverage_fund(params) do
    coverage_ids = Enum.uniq(params.coverage_id)
    Enum.each(coverage_ids, fn(coverage_id) ->
      params = Map.put(params, :coverage_id, coverage_id)
      funds = get_coverage_funds(params)
      if Enum.empty?(funds) do
        insert_account_coverage_fund(params)
      end
    end)
  end

  def insert_account_coverage_fund(params) do
    %AccountGroupCoverageFund{}
    |> AccountGroupCoverageFund.changeset(params)
    |> Repo.insert()
  end

  def get_coverage_funds(params) do
    AccountGroupCoverageFund
    |> where([agcf],
             agcf.coverage_id == ^params.coverage_id and
             agcf.replenish_threshold == ^params.replenish_threshold and
             agcf.revolving_fund == ^params.revolving_fund and
             agcf.account_group_id == ^params.account_group_id
            )
    |> Repo.all()
  end

  def delete_coverage_fund(coverage_fund) do
    Repo.delete(coverage_fund)
  end

  def get_coverage_fund(id) do
    Repo.get(AccountGroupCoverageFund, id)
  end

  #For ACU Scheduling

  def get_acu_schedule_account_by_code(code) do
    ag =
      AccountGroup
      |> where([ag], ag.code == ^code)
      |> Repo.all()
      |> List.first()

    if is_nil(ag) do
      {:account_not_found}
    else
      account = get_active_account(ag.id)
    end
  end
  #end of ACU Scheduling
end
