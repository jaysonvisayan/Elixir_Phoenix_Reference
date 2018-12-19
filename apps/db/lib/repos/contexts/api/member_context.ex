defmodule Innerpeace.Db.Base.Api.MemberContext do
  @moduledoc false

  import Ecto.{Query, Changeset}, warn: false

  alias Innerpeace.Db.{
    Repo,
    Schemas.Member,
    Schemas.AccountGroup,
    Schemas.Product,
    Schemas.AccountProduct,
    Schemas.MemberProduct,
    Schemas.Account,
    Schemas.AccountHierarchyOfEligibleDependent,
    Schemas.AuthorizationProcedureDiagnosis,
    Schemas.AuthorizationDiagnosis,
    Schemas.Authorization,
    Schemas.Diagnosis,
    Schemas.ProductBenefit,
    Schemas.Benefit,
    Schemas.Coverage,
    Schemas.AccountHierarchyOfEligibleDependent,
    Schemas.PemeMember,
    Schemas.Peme,
    Schemas.MemberDocument,
    Schemas.User
  }

  alias Timex
  alias Timex.Duration, as: TD
  alias Ecto.Changeset, as: Changeset
  alias Ecto.UUID, as: UUID

  alias Innerpeace.Db.Base.Api.{
    UtilityContext,
    AccountContext
  }

  alias Innerpeace.Db.Base.{
    MemberContext,
    FacilityContext,
    AuthorizationContext,
    CoverageContext,
    UserContext,
    ProductContext
  }

  def validate_member_movement_retraction(_user, params) do
    with {:ok, changeset} <- validate_member_movement_field(params),
         {:ok, retraction} <- update_movement(changeset)
    do
      {:ok, retraction}
    else
      {:error, changeset} ->
        {:error, changeset}
      _ ->
        {:not_found}
    end
  end

  defp validate_member_movement_field(params) do
    data = %{}
    general_types = %{
      card_number: :string,
      type: :string
    }

    changeset =
      {data, general_types}
      |> cast(params, Map.keys(general_types))
      |> validate_required([
        :card_number,
        :type
      ])
      |> validate_card_number()
      |> validate_types()

    if changeset.valid? do
      {:ok, changeset}
    else
      {:error, changeset}
    end
  end

  defp validate_card_number(changeset) do
    if is_nil(changeset.changes[:card_number]) do
      changeset
    else
      member = get_member_details_by_card_number(changeset.changes.card_number)
      if is_nil(member) do
        add_error(changeset, :card_number, "Card Number doesn't exist!")
      else
        changeset
      end
    end
  end

  defp validate_types(changeset) do
    if is_nil(changeset.changes[:type]) or is_nil(changeset.changes[:card_number]) do
      changeset
    else
      date_today = Ecto.Date.utc()
      member = get_member_details_by_card_number(changeset.changes.card_number)
      if is_nil(member) do
        changeset
      else
        validate_movement_type(changeset, member, date_today)
      end
    end
  end

  defp validate_movement_type(changeset, member, date_today) do
    movement_type = changeset.changes.type
    if movement_type == "Suspension" or movement_type == "Reactivation" or movement_type == "Cancellation" do
      case movement_type do
        "Suspension" ->
          suspension_movement(changeset, member, date_today)
        "Reactivation" ->
          reactivation_movement(changeset, member, date_today)
        "Cancellation" ->
          cancellation_movement(changeset, member, date_today)
      end
      else
        add_error(changeset, :type, "Movement type is not valid")
    end
  end

  defp suspension_movement(changeset, member, date_today) do
    if is_nil(member.suspend_date) do
      add_error(changeset, :type, "No Future Movement yet for Suspension.")
    else
      suspend_date_compare = Ecto.Date.compare(member.suspend_date, date_today)
      if suspend_date_compare == :lt or suspend_date_compare == :eq do
        add_error(changeset, :type, "Suspension Date cannot be retract because its already been suspended.")
      else
        changeset
      end
    end
  end

  defp reactivation_movement(changeset, member, date_today) do
    if is_nil(member.reactivate_date) do
      add_error(changeset, :type, "No Future Movement yet for Reactivation.")
    else
      reactivate_date_compare = Ecto.Date.compare(member.reactivate_date, date_today)
      if reactivate_date_compare == :lt or reactivate_date_compare == :eq do
        add_error(changeset, :type, "Reactivation Date cannot be retract because its already been reactivate.")
      else
        changeset
      end
    end
  end

  defp cancellation_movement(changeset, member, date_today) do
    if is_nil(member.cancel_date) do
      add_error(changeset, :type, "No Future Movement yet for Cancellation.")
    else
      cancel_date_compare = Ecto.Date.compare(member.cancel_date, date_today)
      if cancel_date_compare == :lt or cancel_date_compare == :eq do
        add_error(changeset, :type, "Cancellation Date cannot be retract because its already been cancelled.")
      else
        changeset
      end
    end
  end

  defp update_movement(changeset) do
    if is_nil(changeset.changes[:type]) do
      changeset
    else
      date_today = Ecto.Date.utc()
      member = get_member_details_by_card_number(changeset.changes.card_number)
      if is_nil(member) do
        add_error(changeset, :type, "Card Number doesn't exist!")
      else
        update_movement_checker(changeset, member, date_today)
      end
    end
  end

  defp update_movement_checker(changeset, member, date_today) do
    case changeset.changes.type do
      "Suspension" ->
        update_suspension(changeset, member, date_today)
      "Reactivation" ->
        update_reactivation(changeset, member, date_today)
      "Cancellation" ->
        update_cancellation(changeset, member, date_today)
    end
  end

  defp update_suspension(changeset, member, date_today) do
    if is_nil(member.suspend_date) do
      {:suspend_error}
    else
      suspend_date_compare = Ecto.Date.compare(member.suspend_date, date_today)
      if suspend_date_compare == :lt or suspend_date_compare == :eq do
        add_error(changeset, :type, "Suspension Date cannot be retract because its already been suspended.")
      else
        suspend_params = %{
          suspend_date: nil,
          suspend_reason: nil,
          suspend_remarks: nil
        }
        update_member_suspension(member, suspend_params)
        {:ok, changeset}
      end
    end
  end

  defp update_reactivation(changeset, member, date_today) do
    if is_nil(member.reactivate_date) do
      {:reactivate_error}
    else
      reactivate_date_compare = Ecto.Date.compare(member.reactivate_date, date_today)
      if reactivate_date_compare == :lt or reactivate_date_compare == :eq do
        add_error(changeset, :type, "Reactivation Date cannot be retract because its already been reactivate.")
      else
        reactivate_params = %{
          reactivate_date: nil,
          reactivate_reason: nil,
          reactivate_remarks: nil
        }
        update_member_reactivation(member, reactivate_params)
        {:ok, changeset}
      end
    end
  end

  defp update_cancellation(changeset, member, date_today) do
    if is_nil(member.cancel_date) do
      {:cancellation_error}
    else
      cancel_date_compare = Ecto.Date.compare(member.cancel_date, date_today)
      if cancel_date_compare == :lt or cancel_date_compare == :eq do
        add_error(changeset, :type, "Cancellation Date cannot be retract because its already been cancelled.")
      else
        cancelled_params = %{
          cancel_date: nil,
          cancel_reason: nil,
          cancel_remarks: nil
        }
        update_member_cancellation(member, cancelled_params)
        {:ok, changeset}
      end
    end
  end

  defp update_member_suspension(member, member_params) do
    member
    |> Member.changeset_suspend(member_params)
    |> Repo.update()
  end

  defp update_member_reactivation(member, member_params) do
    member
    |> Member.changeset_reactivate(member_params)
    |> Repo.update()
  end

  defp update_member_cancellation(member, member_params) do
    member
    |> Member.changeset_cancel(member_params)
    |> Repo.update()
  end

  defp get_member_details_by_card_number(card_number) do
    Member
    |> where([m], m.card_no == ^card_number)
    |> Repo.one()
  end

  def validate_details(params) do
    if UtilityContext.validate_yyyymmdd_format(params.birth_date) do
      {year, month, day} =
        params.birth_date
        |> String.split("-")
        |> List.to_tuple()
        birth_date = "#{month}/#{day}/#{year}"

        with true <- UtilityContext.transform_birth_date(birth_date),
             {:ok, members} <- validate_member_details(params.full_name, params.birth_date)
        do
          {:ok, members}
        else
          _ ->
            {:error, "Please enter valid member name/birthdate to avail ACU."}
        end
    else
      {:error, "Please enter valid member name/birthdate to avail ACU."}
    end
  end

  defp validate_member_details(full_name, birth_date) do
    full_name = String.downcase(full_name)
    birth_date = Ecto.Date.cast!(birth_date)
    query =
      from m in Member,
      where: fragment("to_tsvector(concat(?, ' ', ?, ' ', ?)) @@ plainto_tsquery(?)", m.first_name, m.middle_name, m.last_name, ^"#{full_name}")
    and fragment("? = coalesce(?, ?)", m.birthdate, ^birth_date, m.birthdate)
    members =
      query
      |> Repo.all()
      |> Repo.preload([:emergency_contact, :peme])
      |> preload()

    if Enum.empty?(members) do
      {:member_not_found}
    else
      {:ok, members}
    end
  end

  def validate_card(number, bdate) do
    Member
    |> where([m], m.card_no == ^number)
    |> where([m], m.birthdate == ^bdate)
    |> limit(1)
    |> Repo.one()
    |> Repo.preload([
      :files,
      :user,
      :principal,
      :created_by,
      :updated_by,
      :emergency_hospital,
      :emergency_contact,
      :peme,
      dependents: :skipped_dependents,
      products: [
        account_product: [
          product: [
            product_benefits: [
              benefit: :benefit_diagnoses
            ],
            product_coverages: [
              :coverage,
              [product_coverage_risk_share: :product_coverage_risk_share_facilities]
            ]
          ]
        ]
      ],
      account_group: [
        :payment_account,
        account: [
          account_products: [
            product: :product_benefits
          ]
        ]
      ],
      member_contacts: [contact: [:phones, :emails]],
    ])
  rescue
    _ ->
      nil
  end

  def validate_active_card(card_number) do
    Member
    |> Repo.get_by(%{card_no: card_number, status: "Active"})
    |> Repo.preload([
      :files,
      :user,
      :principal,
      :created_by,
      :updated_by,
      :emergency_hospital,
      :emergency_contact,
      :peme,
      dependents: :skipped_dependents,
      products: [
        account_product: [
          product: [
            product_benefits: [
              benefit: :benefit_diagnoses
            ],
            product_coverages: [
              :coverage,
              [product_coverage_risk_share: :product_coverage_risk_share_facilities]
            ]
          ]
        ]
      ],
      account_group: [
        :payment_account,
        account: [
          account_products: [
            product: :product_benefits
          ]
        ]
      ],
      member_contacts: [contact: [:phones, :emails]],
    ])
  end

  def validate_evoucher_field(params) do
    data = %{}
    general_types = %{
      evoucher_number: :string
    }

    changeset =
      {data, general_types}
      |> cast(params, Map.keys(general_types))
      |> validate_required([
        :evoucher_number
      ])

    if changeset.valid? do
      {:ok, changeset}
    else
      {:error, changeset}
    end
  end

  def validate_evoucher(evoucher_number) do
    Member
    |> Repo.get_by(evoucher_number: evoucher_number)
    |> Repo.preload([
      :files,
      :user,
      :principal,
      :created_by,
      :updated_by,
      :emergency_hospital,
      :emergency_contact,
      :peme,
      dependents: :skipped_dependents,
      products: [
        account_product: [
          product: [
            product_benefits: [
              benefit: :benefit_diagnoses
            ],
            product_coverages: [
              :coverage,
              [product_coverage_risk_share: :product_coverage_risk_share_facilities]
            ]
          ]
        ]
      ],
      account_group: [
        :payment_account,
        account: [
          account_products: [
            product: :product_benefits
          ]
        ]
      ],
      member_contacts: [contact: [:phones, :emails]],
    ])
  end

  def create(params) do
       with {:ok, changeset} <- validate_member_fields(params),
         {:ok, member} <- insert_member(changeset),
         {:ok} <- insert_member_products(changeset, member.id),
         %Member{} = member <- MemberContext.get_member(member.id)
    do
      {:ok, member}
    else
      {:changeset_error, changeset} ->
        # {:error, UtilityContext.changeset_errors_to_string(changeset.errors)}
        {:error, changeset}
      _ ->
        {:error, "Not found"}
    end
  end

  def create_with_user(params, current_user) do
    with {:ok, changeset} <- validate_member_fields_with_user(params),
         {:ok, member} <- insert_member(changeset),
         {:ok} <- insert_member_products(changeset, member.id),
         %Member{} = member <- MemberContext.get_member(member.id),
         {:ok, %User{}} <- register_member_user(member, params, current_user)
    do
      {:ok, member}
    else
      {:changeset_error, changeset} ->
        {:changeset_error, changeset}

      {:error, changeset} ->
        {:error, changeset}

      _ ->
        {:error, "Not found"}
    end
  end

  def create_batch(params) do
    with {:ok, changeset} <- validate_member_fields(params),
         {:ok, member} <- insert_member(changeset),
         {:ok} <- insert_member_products(changeset, member.id),
         %Member{} = member <- MemberContext.get_member(member.id)
    do
      member
    else
      {:changeset_error, changeset} ->
        Map.put(changeset.changes, :errors, UtilityContext.changeset_errors_to_string(changeset.errors))
      _ ->
        {:error, "Not found"}
    end
  end


  def create_batch_with_user(params, current_user) do
    with {:ok, changeset} <- validate_member_fields_with_user(params),
         {:ok, member} <- insert_member(changeset),
         {:ok} <- insert_member_products(changeset, member.id),
         %Member{} = member <- MemberContext.get_member(member.id),
         {:ok, %User{}} <- register_member_user(member, params, current_user)
    do
      member
    else

      {:changeset_error, changeset} ->
        Map.put(changeset.changes, :errors, UtilityContext.changeset_errors_to_string(changeset.errors))

      {:error, changeset} ->
        Map.put(changeset.changes, :errors, UtilityContext.changeset_errors_to_string(changeset.errors))

      _ ->
        {:error, "Not found"}
    end
  end

  defp register_member_user(member, params, current_user) do
    if is_nil(member.id) do
      {:error, "Not found"}
    else
      params = %{
        member_id: member.id,
        username: params["username"],
        email: params["email"],
        mobile: params["mobile"],
        first_name: params["first_name"],
        last_name: params["last_name"],
        middle_name: params["middle_name"],
        suffix: params["suffix"],
        birthday: params["birthdate"],
        gender: params["gender"],
        created_by_id: current_user.id,
        updated_by_id: current_user.id,
        password: params["password"]
      } |> UserContext.register_member()
    end
  end

  defp register_member_user(member, params) do
    if is_nil(member.id) do
      {:error, "Not found"}
    else
      params = %{
        member_id: member.id,
        username: params["username"],
        email: params["email"],
        mobile: params["mobile"],
        first_name: params["first_name"],
        last_name: params["last_name"],
        middle_name: params["middle_name"],
        suffix: params["suffix"],
        birthday: params["birthdate"],
        gender: params["gender"],
        password: params["password"]
      } |> UserContext.register_member()
    end
  end

  defp insert_member_products(changeset, member_id) do
    if Map.has_key?(changeset.changes, :products) do
      for {product_id, tier} <- Enum.with_index(changeset.changes.products, 1) do
        %MemberProduct{}
        |> MemberProduct.changeset(%{member_id: member_id, account_product_id: product_id, tier: tier})
        |> Repo.insert()
      end
      {:ok}
      else
      {:ok}
    end
  end

  defp insert_member(changeset) do
    {:ok, member} =
      %Member{}
      |> Member.changeset_api(changeset.changes)
      |> Repo.insert()

    member
    |> Member.changeset_card()
    |> Repo.update()
  end

  def validate_member_fields(params) do
    types = %{
      account_code: :string,
      type: :string,
      principal_id: :binary_id,
      relationship: :string,
      effectivity_date: Ecto.Date,
      expiry_date: Ecto.Date,
      first_name: :string,
      middle_name: :string,
      last_name: :string,
      suffix: :string,
      gender: :string,
      civil_status: :string,
      birthdate: Ecto.Date,
      employee_no: :string,
      date_hired: Ecto.Date,
      regularization_date: Ecto.Date,
      is_regular: :boolean,
      tin: :string,
      philhealth: :string,
      philhealth_type: :string,
      for_card_issuance: :boolean,
      products: {:array, :string},
      email: :string,
      email2: :string,
      mcc: :string,
      mobile: :string,
      mcc2: :string,
      mobile2: :string,
      ##
      tcc: :string,
      tac: :string,
      telephone: :string,
      tlc: :string,
      ##
      fcc: :string,
      fac: :string,
      fax: :string,
      flc: :string,
      ##
      postal: :string,
      unit_no: :string,
      building_name: :string,
      street_name: :string,
      city: :string,
      province: :string,
      region: :string,
      country: :string,
      policy_no: :string,
      principal_product_code: :string,
      step: :integer,
      integration_id: :string
    }
    changeset =
      {%{}, types}
      |> cast(params, Map.keys(types))
      |> validate_required([
        :account_code,
        :type,
        :first_name,
        # :last_name,
        :effectivity_date,
        :expiry_date,
        # :mcc,
        # :mobile,
        # :email,
        :civil_status,
        :gender,
        :birthdate,
        :for_card_issuance,
        :philhealth_type,
        :products,
        :is_regular,
        :regularization_date,
      ], message: "is required")
      validate_member_changeset(changeset)
  end

  defp validate_member_fields_with_user(params) do
    types = %{
      account_code: :string,
      type: :string,
      principal_id: :binary_id,
      relationship: :string,
      effectivity_date: Ecto.Date,
      expiry_date: Ecto.Date,
      first_name: :string,
      middle_name: :string,
      last_name: :string,
      suffix: :string,
      gender: :string,
      civil_status: :string,
      birthdate: Ecto.Date,
      employee_no: :string,
      date_hired: Ecto.Date,
      regularization_date: Ecto.Date,
      is_regular: :boolean,
      tin: :string,
      philhealth: :string,
      philhealth_type: :string,
      for_card_issuance: :boolean,
      products: {:array, :string},
      email: :string,
      email2: :string,
      mcc: :string,
      mobile: :string,
      mcc2: :string,
      mobile2: :string,
      ##
      tcc: :string,
      tac: :string,
      telephone: :string,
      tlc: :string,
      ##
      fcc: :string,
      fac: :string,
      fax: :string,
      flc: :string,
      ##
      postal: :string,
      unit_no: :string,
      building_name: :string,
      street_name: :string,
      city: :string,
      province: :string,
      region: :string,
      country: :string,
      policy_no: :string,
      principal_product_code: :string,
      step: :integer,
      ##
      username: :string,
      password: :string,
      card_no: :string,
      status: :string
    }
    changeset =
      {%{}, types}
      |> cast(params, Map.keys(types))
      |> validate_required([
        :account_code,
        :type,
        :first_name,
        :last_name,
        :effectivity_date,
        :expiry_date,
        # :mcc,
        # :mobile,
        # :email,
        :civil_status,
        :gender,
        :birthdate,
        :for_card_issuance,
        :philhealth_type,
        :username,
        :password,
        :card_no,
        :is_regular,
        :regularization_date,
      ], message: "is required")

      validate_member_changeset2(changeset)
  end

  defp validate_member_changeset2(changeset) do
    changeset =
      changeset
      |> validate_inclusion(:type, [
        "Principal",
        "Dependent",
        "Guardian"
      ], message: "is invalid")
      |> validate_inclusion(:relationship, [
        "Child",
        "Parent",
        "Sibling",
        "Partner"
      ], message: "is invalid")
      |> validate_inclusion(:gender, ["Male", "Female"], message: "is invalid")
      |> validate_inclusion(:account_code, get_all_account_codes(), message: "is invalid")
      |> validate_inclusion(:principal_id, get_all_principal_ids(), message: "is invalid")
      |> validate_inclusion(:civil_status, [
        "Single",
        "Married",
        "Single Parent",
        "Widowed",
        "Annulled",
        "Separated"
      ], message: "is invalid")
      |> validate_inclusion(:philhealth_type, [
        "Required to file",
        "Not Covered",
        "Optional to file"
      ], message: "is invalid")
      |> validate_format(:email, ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
      |> validate_format(:email2, ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
      |> validate_format(:tin, ~r/^[0-9]*$/)
      ### Mobile and Mobile2
      |> validate_format(:mcc, ~r/^\+?\d{1,10}$/)
      |> validate_length(:mcc, max: 5, message: "should be at most 4 digit")
      |> validate_format(:mobile, ~r/^[0-9]*$/)
      |> validate_length(:mobile, is: 10, message: "should be 10 characters")
      |> validate_format(:mcc2, ~r/^\+?\d{1,10}$/)
      |> validate_length(:mcc2, max: 5, message: "should be at most 4 digit")
      |> validate_format(:mobile2, ~r/^[0-9]*$/)
      |> validate_length(:mobile2, is: 10, message: "should be 10 characters")
      ### Tel
      |> validate_format(:tcc, ~r/^\+?\d{1,10}$/)
      |> validate_length(:tcc, max: 5, message: "should be at most 4 digit")
      |> validate_format(:tac, ~r/^[0-9]*$/)
      |> validate_length(:tac, max: 5, message: "should be at most 5 digit")
      |> validate_format(:telephone, ~r/^[0-9]*$/)
      |> validate_length(:telephone, is: 7, message: "should be 7 characters")
      |> validate_format(:tlc, ~r/^[0-9]*$/)
      |> validate_length(:tlc, max: 5, message: "should be at most 5 digit")
      ### Fax
      |> validate_format(:fcc, ~r/^\+?\d{1,10}$/)
      |> validate_length(:fcc, max: 5, message: "should be at most 4 digit")
      |> validate_format(:fac, ~r/^[0-9]*$/)
      |> validate_length(:fac, max: 5, message: "should be at most 5 digit")
      |> validate_format(:fax, ~r/^[0-9]*$/)
      |> validate_length(:fax, is: 7, message: "should be 7 characters")
      |> validate_format(:flc, ~r/^[0-9]*$/)
      |> validate_length(:flc, max: 5, message: "should be at most 5 digit")
      ###################################################################################################
      |> validate_format(:first_name, ~r/^[a-zA-Z ,.Ññ-]+$/)
      |> validate_format(:middle_name, ~r/^[a-zA-Z ,.Ññ-]+$/)
      |> validate_format(:last_name, ~r/^[a-zA-Z ,.Ññ-]+$/)
      |> validate_format(:suffix, ~r/^[a-zA-Z ,.Ññ-]+$/)
      |> validate_length(:first_name, max: 150, message: "should be at most 150 character(s)")
      |> validate_length(:middle_name, max: 150, message: "should be at most 150 character(s)")
      |> validate_length(:last_name, max: 150, message: "should be at most 150 character(s)")
      |> validate_length(:suffix, max: 10, message: "should be at most 10 character(s)")
      |> validate_length(:tin, is: 12, message: "should be 12 characters")
      # |> validate_length(:postal, is: 4, message: "should be 4 characters")
      |> validate_length(:philhealth, is: 12, message: "should be 12 characters")
      |> validate_format(:philhealth, ~r/^[0-9]*$/)
      |> validate_length(:card_no, is: 16, message: "should be 16 characters")
      |> validate_format(:card_no, ~r/^[0-9]*$/)
      |> validate_inclusion(:status, [
        "Active",
        "Cancelled",
        "Suspended",
        "Lapsed",
        "For Approval",
        "Disapprove",
        "Pending",
      ], message: "[Active, Cancelled, Suspended, Lapsed, For Approval, Disapprove, Pending] is the only allowed value in status param")
      |> validate_member_type()
      |> validate_products()
      |> validate_effective_expiry()
      |> validate_employee_no()
      |> validate_account_effective_date()
      |> validate_account_expiry_date()
      |> validate_age()
      |> is_regular_checker()
      |> setup_is_regular()
      |> validate_active_account()
      |> validate_dependent_civil_status()
      #|> validate_philhealth()
      # |> validate_status()
      |> put_change(:step, 5)
      |> put_change(:country, "Philippines")
      |> validate_mobile(:mobile)
      |> validate_mobile(:mobile2)
      |> validate_country_code(:mcc)
      |> validate_country_code(:mcc2)
      |> validate_country_code(:tcc)
      |> validate_country_code(:fcc)
      |> country_code_existing?(:mcc2, :mobile2)
      |> country_code_existing?(:tcc, :telephone)
      |> country_code_existing?(:fcc, :fax)
      |> mobile2_tel_fax_existing?(:mobile2, :mcc2)
      |> mobile2_tel_fax_existing?(:telephone, :tcc)
      |> mobile2_tel_fax_existing?(:fax, :fcc)
      |> validate_mobile_prefix(:mobile)
      |> validate_mobile_prefix(:mobile2)
      |> validate_username()
      |> validate_card_no()
      if changeset.valid? do
        {:ok, changeset}
      else
        {:changeset_error, changeset}
      end
  end

  defp validate_card_no(changeset) do
    with true <- Map.has_key?(changeset.changes, :card_no) do
      member =
        changeset.changes.card_no
        |> MemberContext.get_member_by_card_no()

      if is_nil(member) do
        changeset
      else
        add_error(changeset, :card_no, "already exists")
      end
    else
      _ ->
        changeset
    end
  end

  defp validate_card_no_refactored(changeset) do
    with true <- Map.has_key?(changeset.changes, :card_no) do
      member = changeset.changes.card_no

      if is_nil(check_card_no(member)) do
        changeset
      else
        add_error(changeset, :card_no, "already exists")
      end
    else
      _ ->
        changeset
    end
  end

  defp check_card_no(card_no) do
      Member
      |> where([m], m.card_no == ^card_no)
      |> Repo.one()
  end


  defp validate_username(changeset) do
    with true <- Map.has_key?(changeset.changes, :username) do
      user = UserContext.get_username(changeset.changes.username)
      if is_nil(user) do
        changeset
      else
        add_error(changeset, :username, "is already taken")
      end
    else
      _ ->
        changeset
    end
  end

  defp validate_member_existing_changeset_v2(changeset) do
    changeset =
      changeset
      |> validate_length(:products, min: 1, message: "at least one is required")
      |> if_employee_no_unsupplied(:employee_no, :type, :policy_no)
      |> validate_card_no_refactored
      |> validate_employee_no_refactored
      |> validate_member_type_refactored_v2()
      |> validate_products()
      |> put_change(:step, 5)
      |> put_change(:country, "Philippines")
      if changeset.valid? do
        {:ok, changeset}
      else
        {:changeset_error, changeset}
      end
  end

  defp validate_member_existing_changeset(changeset) do
    changeset =
      changeset
      |> validate_inclusion(:type, [
        "Principal",
        "Dependent",
        "Guardian"
      ], message: "is invalid")
      |> validate_inclusion(:relationship, [
        "Child",
        "Parent",
        "Sibling",
        "Partner",
        ## Added Relationship status for migration 06/13/18 3:47 pm
        "Others",
        "Partners"
      ], message: "is invalid")
      |> validate_inclusion(:gender, ["Male", "Female"], message: "is invalid")
      ## refactored 06/14/18 12:07 pm
      # |> validate_inclusion(:account_code, get_all_account_codes(), message: "is invalid")
      |> validate_member_account_codes()
      ## as per sir joseph principal id is not needed(06/14/2018)3:42pm
      # |> validate_inclusion(:principal_id, get_all_principal_ids(), message: "is invalid")
      # |> validate_principal_ids()
      |> validate_inclusion(:civil_status, [
        "Single",
        "Married",
        "Single Parent",
        "Widowed",
        "Annulled",
        "Separated"
      ], message: "is invalid")
      |> validate_inclusion(:philhealth_type, [
        "Required to file",
        "Not Covered",
        "Optional to file"
      ], message: "is invalid")
      |> validate_format(:email, ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
      |> validate_format(:email2, ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
      |> validate_format(:tin, ~r/^[0-9]*$/)
      ### Mobile and Mobile2
      |> validate_format(:mcc, ~r/^\+?\d{1,10}$/)
      |> validate_length(:mcc, max: 5, message: "should be at most 4 digit")
      |> validate_format(:mobile, ~r/^[0-9]*$/)
      |> validate_length(:mobile, is: 10, message: "should be 10 characters")
      |> validate_format(:mcc2, ~r/^\+?\d{1,10}$/)
      |> validate_length(:mcc2, max: 5, message: "should be at most 4 digit")
      |> validate_format(:mobile2, ~r/^[0-9]*$/)
      |> validate_length(:mobile2, is: 10, message: "should be 10 characters")
      ### Tel
      |> validate_format(:tcc, ~r/^\+?\d{1,10}$/)
      |> validate_length(:tcc, max: 5, message: "should be at most 4 digit")
      |> validate_format(:tac, ~r/^[0-9]*$/)
      |> validate_length(:tac, max: 5, message: "should be at most 5 digit")
      |> validate_format(:telephone, ~r/^[0-9]*$/)
      |> validate_length(:telephone, is: 7, message: "should be 7 characters")
      |> validate_format(:tlc, ~r/^[0-9]*$/)
      |> validate_length(:tlc, max: 5, message: "should be at most 5 digit")
      ### Fax
      |> validate_format(:fcc, ~r/^\+?\d{1,10}$/)
      |> validate_length(:fcc, max: 5, message: "should be at most 4 digit")
      |> validate_format(:fac, ~r/^[0-9]*$/)
      |> validate_length(:fac, max: 5, message: "should be at most 5 digit")
      |> validate_format(:fax, ~r/^[0-9]*$/)
      |> validate_length(:fax, is: 7, message: "should be 7 characters")
      |> validate_format(:flc, ~r/^[0-9]*$/)
      |> validate_length(:flc, max: 5, message: "should be at most 5 digit")
      ###################################################################################################
      |> validate_format(:first_name, ~r/^[a-zA-Z0-9 ,.'Ññz-]+$/)
      |> validate_format(:middle_name, ~r/^[a-zA-Z ,.Ññ-]+$/)
      |> validate_format(:last_name, ~r/^[a-zA-Z ,.Ññ-]+$/)
      |> validate_format(:suffix, ~r/^[a-zA-Z ,.Ññ-]+$/)
      |> validate_length(:first_name, max: 150, message: "should be at most 150 character(s)")
      |> validate_length(:middle_name, max: 150, message: "should be at most 150 character(s)")
      |> validate_length(:last_name, max: 150, message: "should be at most 150 character(s)")
      |> validate_length(:suffix, max: 10, message: "should be at most 10 character(s)")
      |> validate_length(:tin, is: 12, message: "should be 12 characters")
      |> validate_length(:postal, is: 4, message: "should be 4 characters")
      |> validate_length(:philhealth, is: 12, message: "should be 12 characters")
      |> validate_format(:philhealth, ~r/^[0-9]*$/)
      |> validate_length(:products, min: 1, message: "at least one is required")
      |> validate_length(:card_no, is: 16, message: "should be 16 characters")
      |> validate_format(:card_no, ~r/^[0-9]*$/)
      |> validate_inclusion(:status, [
        "Active",
        "Cancelled",
        "Suspended",
        "Lapsed",
        "For Approval",
        "Disapprove",
        "Pending",
      ], message: "[Active, Cancelled, Suspended, Lapsed, For Approval, Disapprove, Pending] is the only allowed value in status param")
      # |> validate_card_no()
      ## relaxing validation if member dependent doesn't have an employee_no, 2nd catch  would be, get its policy number
      ## and use it as a reference principal policy no.
      |> if_employee_no_unsupplied(:employee_no, :type, :policy_no)
      ################################################################################# edited asof 07022018AM
      |> validate_card_no_refactored
      |> validate_member_type_refactored()
      |> validate_products()
      |> validate_effective_expiry()
      # |> validate_employee_no()
      |> validate_employee_no_refactored
      ############################################### disabling changeset, edited asof 06292018 01:30PM
      # |> validate_account_effective_date()
      # |> validate_account_expiry_date()
      ## As per sir Rey and Ma'am Esther adopts accounts expiry when member expiry is higher
      |> validate_expiry_member_expiry_account()
      |> validate_age()
      |> is_regular_checker()
      |> setup_is_regular()
      |> validate_active_account()
      |> validate_dependent_civil_status()
      #|> validate_philhealth()
      # |> validate_status()
      ########################### relaxing validation for status of member that has not included in the account range
      |> validate_member_status(:status, :account_code, :effectivity_date, :expiry_date)
      ################################################################################# edited asof 06282018PM
      |> put_change(:step, 5)
      |> put_change(:country, "Philippines")
      |> validate_mobile(:mobile)
      |> validate_mobile(:mobile2)
      |> validate_country_code(:mcc)
      |> validate_country_code(:mcc2)
      |> validate_country_code(:tcc)
      |> validate_country_code(:fcc)
      |> country_code_existing?(:mcc2, :mobile2)
      |> country_code_existing?(:tcc, :telephone)
      |> country_code_existing?(:fcc, :fax)
      |> mobile2_tel_fax_existing?(:mobile2, :mcc2)
      |> mobile2_tel_fax_existing?(:telephone, :tcc)
      |> mobile2_tel_fax_existing?(:fax, :fcc)
      |> validate_mobile_prefix(:mobile)
      |> validate_mobile_prefix(:mobile2)
      if changeset.valid? do
        {:ok, changeset}
      else
        {:changeset_error, changeset}
      end
  end

  #################################### start: newly added asof 07022018AM ###############################################

  defp if_employee_no_unsupplied(changeset, employee_no, type, policy_no) do
    with false <- Map.has_key?(changeset.changes, employee_no),
         true <- Map.has_key?(changeset.changes, type),
         true <- Map.has_key?(changeset.changes, policy_no),
         "Dependent" <- changeset.changes.type,

         changeset <- changeset.changes.policy_no |> trace_by_policy_no(changeset)
    do
      changeset
    else
      "Principal" ->
        changeset
        |> validate_required([:employee_no])
      true ->
        changeset
        |> validate_required([:employee_no])
      false ->
        changeset
        |> validate_required([
          :employee_no,
          :policy_no
        ])
      _ ->
        changeset
    end
  end

  defp trace_by_policy_no(policy_no, changeset) do
    with  %Member{} = member  <- Member |> Repo.get_by(policy_no: transform_policy_no(policy_no)) do
      changeset |> put_change(:principal_id, member.id)
    else
      nil ->
        changeset |> add_error(:policy_no, "Principal Policy Number Reference is not existing")
    end

    rescue
      _ ->
       changeset |> add_error(:policy_no, "Invalid Policy Number")
  end

  defp transform_policy_no(policy_no) do
    policy_no
    |> String.split("", trim: true)
    |> Enum.drop(-2)
    |> List.insert_at(-1, "0")
    |> List.insert_at(-1, "0")
    |> Enum.join()
  end

  #################################### end: newly added asof 07022018AM ###############################################

  #################################### start: newly added asof 06282018PM ###############################################

  defp validate_member_status(changeset, field1, field2, field3, field4) do
    with true <- Map.has_key?(changeset.changes, field1),
         true <- Map.has_key?(changeset.changes, field2),
         true <- Map.has_key?(changeset.changes, field3),
         true <- Map.has_key?(changeset.changes, field4),
         changeset <- status_checker(changeset, changeset.changes.status)
    do
      changeset
    else
      false ->
        changeset
      _ ->
        changeset
    end
  end

  defp status_checker(changeset, "Active"), do: validate_active_status(changeset)
  defp status_checker(changeset, "Cancelled"), do: validate_cancelled_status(changeset)
  defp status_checker(changeset, "Suspended"), do: validate_suspended_status(changeset)
  defp status_checker(changeset, "Pending"), do: validate_pending_status(changeset)
  defp status_checker(changeset, "Lapsed"), do: validate_lapsed_status(changeset)
  defp status_checker(changeset, status), do: add_error(changeset, :status, "Invalid Status Value")

  defp validate_active_status(changeset) do
    with %AccountGroup{} = acg <- get_accountgroup(changeset.changes.account_code),
         %Account{} = account <- get_active_account_from_account_group(acg.id),
         changeset <- compare_member_account_dates(String.downcase(changeset.changes.status), changeset, account)
    do
      changeset
    else
      nil ->
        ### it doesnt have at least 1 active account version, do force lapsed
        put_change(changeset, :status, "Lapsed")
    end
  end
  defp validate_cancelled_status(changeset) do
    with %AccountGroup{} = acg <- get_accountgroup(changeset.changes.account_code),
         %Account{} = account <- get_active_account_from_account_group(acg.id),
         changeset <- compare_member_account_dates(String.downcase(changeset.changes.status), changeset, account)
    do
      changeset
    else
      nil ->
        ### it doesnt have at least 1 active account version, do force lapsed
        put_change(changeset, :status, "Lapsed")
    end
  end
  defp validate_suspended_status(changeset) do
    with %AccountGroup{} = acg <- get_accountgroup(changeset.changes.account_code),
         %Account{} = account <- get_active_account_from_account_group(acg.id),
         changeset <- compare_member_account_dates(String.downcase(changeset.changes.status), changeset, account)
    do
      changeset
    else
      nil ->
        ### it doesnt have at least 1 active account version, do force lapsed
        put_change(changeset, :status, "Lapsed")
    end
  end
  defp validate_pending_status(changeset) do
    with %AccountGroup{} = acg <- get_accountgroup(changeset.changes.account_code),
         %Account{} = account <- get_active_account_from_account_group(acg.id),
         changeset <- compare_member_account_dates(String.downcase(changeset.changes.status), changeset, account)
    do
      changeset
    else
      nil ->
        ### it doesnt have at least 1 active account version, do force lapsed
        put_change(changeset, :status, "Lapsed")
    end
  end
  defp validate_lapsed_status(changeset) do
    with %AccountGroup{} = acg <- get_accountgroup(changeset.changes.account_code),
         %Account{} = account <- get_active_account_from_account_group(acg.id),
         changeset <- compare_member_account_dates(String.downcase(changeset.changes.status), changeset, account)
    do
      changeset
    else
      nil ->
        ### it doesnt have at least 1 active account version, do force lapsed
        put_change(changeset, :status, "Lapsed")
    end
  end

  defp get_accountgroup(account_code) do
    AccountGroup
    |> where([ag], ag.code == ^account_code)
    |> Repo.one
  end
  defp get_active_account_from_account_group(acg_id) do
    Account
    |> where([a], a.account_group_id == ^acg_id)
    |> where([a], a.status == ^"Active")
    |> limit(1)
    |> Repo.one
  end
  defp today_vs_acc_enddate(acc_end_date), do: Ecto.Date.utc() |> Ecto.Date.compare(acc_end_date)
  defp compare_member_account_dates(status, changeset, account) do
    case today_vs_acc_enddate(account.end_date) do
      :gt ->
        ### Account already lapsed
        changeset |> put_change(:status, "Lapsed") ### member also inherits the lapsed status of his/her account
      :lt ->
        ### Account is still active
        changeset =
          account.start_date
          |> Ecto.Date.compare(Ecto.Date.cast!(changeset.changes.effectivity_date))
          |> date_results(status, "a_sdate_vs_m_effdate", changeset)

          account.end_date
          |> Ecto.Date.compare(Ecto.Date.cast!(changeset.changes.effectivity_date))
          |> date_results(status, "a_edate_vs_m_effdate", changeset)

      :eq ->
        ### Account's Last day, tom would be lapsed
        changeset =
          account.start_date
          |> Ecto.Date.compare(Ecto.Date.cast!(changeset.changes.effectivity_date))
          |> date_results(status, "a_sdate_vs_m_effdate", changeset)

          account.end_date
          |> Ecto.Date.compare(Ecto.Date.cast!(changeset.changes.effectivity_date))
          |> date_results(status, "a_edate_vs_m_effdate", changeset)
    end
  end

  defp date_results(:gt, "active", "a_sdate_vs_m_effdate", changeset), do: changeset |> put_change(:status, "Lapsed")
  defp date_results(:lt, "active", "a_sdate_vs_m_effdate", changeset), do: is_pending?(changeset)
  defp date_results(:eq, "active", "a_sdate_vs_m_effdate", changeset), do: changeset |> put_change(:status, "Active")
  defp date_results(:gt, "active", "a_edate_vs_m_effdate", changeset) do
    case changeset.changes.status do
      "Lapsed" -> changeset
      "Pending" -> changeset
      _ -> changeset |> put_change(:status, "Active")
    end
  end
  defp date_results(:lt, "active", "a_edate_vs_m_effdate", changeset), do: changeset |> put_change(:status, "Lapsed")
  defp date_results(:eq, "active", "a_edate_vs_m_effdate", changeset) do
    if changeset.changes.status == "Pending", do: changeset, else: changeset |> put_change(:status, "Active")
  end

  defp date_results(:gt, "cancelled", "a_sdate_vs_m_effdate", changeset), do: changeset |> put_change(:status, "Cancelled")
  defp date_results(:lt, "cancelled", "a_sdate_vs_m_effdate", changeset), do: changeset |> put_change(:status, "Cancelled")
  defp date_results(:eq, "cancelled", "a_sdate_vs_m_effdate", changeset), do: changeset |> put_change(:status, "Cancelled")
  defp date_results(:gt, "cancelled", "a_edate_vs_m_effdate", changeset) do
    changeset |> put_change(:status, "Cancelled")
  end
  defp date_results(:lt, "cancelled", "a_edate_vs_m_effdate", changeset), do: changeset |> put_change(:status, "Cancelled")
  defp date_results(:eq, "cancelled", "a_edate_vs_m_effdate", changeset), do: changeset |> put_change(:status, "Cancelled")

  defp date_results(:gt, "suspended", "a_sdate_vs_m_effdate", changeset), do: changeset |> put_change(:status, "Lapsed")
  defp date_results(:lt, "suspended", "a_sdate_vs_m_effdate", changeset), do: changeset |> put_change(:status, "Suspended")
  defp date_results(:eq, "suspended", "a_sdate_vs_m_effdate", changeset), do: changeset |> put_change(:status, "Suspended")
  defp date_results(:gt, "suspended", "a_edate_vs_m_effdate", changeset) do
    if changeset.changes.status == "Lapsed", do: changeset, else: changeset |> put_change(:status, "Suspended")
  end
  defp date_results(:lt, "suspended", "a_edate_vs_m_effdate", changeset), do: changeset |> put_change(:status, "Lapsed")
  defp date_results(:eq, "suspended", "a_edate_vs_m_effdate", changeset), do: changeset |> put_change(:status, "Suspended")

  defp date_results(:gt, "pending", "a_sdate_vs_m_effdate", changeset), do: changeset |> put_change(:status, "Lapsed")
  defp date_results(:lt, "pending", "a_sdate_vs_m_effdate", changeset), do: is_pending?(changeset)
  defp date_results(:eq, "pending", "a_sdate_vs_m_effdate", changeset), do: changeset |> put_change(:status, "Active")
  defp date_results(:gt, "pending", "a_edate_vs_m_effdate", changeset) do
    case changeset.changes.status do
      "Lapsed" -> changeset
      "Pending" -> changeset
      _ -> changeset |> put_change(:status, "Active")
    end
  end
  defp date_results(:lt, "pending", "a_edate_vs_m_effdate", changeset), do: changeset |> put_change(:status, "Lapsed")
  defp date_results(:eq, "pending", "a_edate_vs_m_effdate", changeset) do
    if changeset.changes.status == "Pending", do: changeset, else: changeset |> put_change(:status, "Active")
  end

  defp date_results(:gt, "lapsed", "a_sdate_vs_m_effdate", changeset), do: changeset |> put_change(:status, "Lapsed")
  defp date_results(:lt, "lapsed", "a_sdate_vs_m_effdate", changeset), do: is_pending?(changeset)
  defp date_results(:eq, "lapsed", "a_sdate_vs_m_effdate", changeset), do: changeset |> put_change(:status, "Active")
  defp date_results(:gt, "lapsed", "a_edate_vs_m_effdate", changeset) do
    case changeset.changes.status do
      "Lapsed" -> changeset
      "Pending" -> changeset
      _ -> changeset |> put_change(:status, "Active")
    end
  end
  defp date_results(:lt, "lapsed", "a_edate_vs_m_effdate", changeset), do: changeset |> put_change(:status, "Lapsed")
  defp date_results(:eq, "lapsed", "a_edate_vs_m_effdate", changeset) do
    if changeset.changes.status == "Pending", do: changeset, else: changeset |> put_change(:status, "Active")
  end

  defp is_pending?(changeset) do
    case changeset.changes.effectivity_date |> Ecto.Date.compare(Ecto.Date.utc()) do
      :gt ->
        changeset |> put_change(:status, "Pending")
      :lt ->
        changeset |> put_change(:status, "Active")
      :eq ->
        changeset |> put_change(:status, "Active")
    end
  end

  #################################### end: newly added asof 06282018PM ###############################################

  defp validate_member_changeset(changeset) do
    changeset =
      changeset
      |> validate_inclusion(:type, [
        "Principal",
        "Dependent",
        "Guardian"
      ], message: "is invalid")
      |> validate_inclusion(:relationship, [
        "Child",
        "Parent",
        "Sibling",
        "Partner"
      ], message: "is invalid")
      |> validate_inclusion(:gender, ["Male", "Female"], message: "is invalid")
      |> validate_inclusion(:account_code, get_all_account_codes(), message: "is invalid")
      |> validate_inclusion(:principal_id, get_all_principal_ids(), message: "is invalid")
      |> validate_inclusion(:civil_status, [
        "Single",
        "Married",
        "Single Parent",
        "Widowed",
        "Annulled",
        "Separated"
      ], message: "is invalid")
      |> validate_inclusion(:philhealth_type, [
        "Required to file",
        "Not Covered",
        "Optional to file"
      ], message: "is invalid")
      |> validate_format(:email, ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
      |> validate_format(:email2, ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
      |> validate_format(:tin, ~r/^[0-9]*$/)
      ### Mobile and Mobile2
      |> validate_format(:mcc, ~r/^\+?\d{1,10}$/)
      |> validate_length(:mcc, max: 5, message: "should be at most 4 digit")
      |> validate_format(:mobile, ~r/^[0-9]*$/)
      |> validate_length(:mobile, is: 10, message: "should be 10 characters")
      |> validate_format(:mcc2, ~r/^\+?\d{1,10}$/)
      |> validate_length(:mcc2, max: 5, message: "should be at most 4 digit")
      |> validate_format(:mobile2, ~r/^[0-9]*$/)
      |> validate_length(:mobile2, is: 10, message: "should be 10 characters")
      ### Tel
      |> validate_format(:tcc, ~r/^\+?\d{1,10}$/)
      |> validate_length(:tcc, max: 5, message: "should be at most 4 digit")
      |> validate_format(:tac, ~r/^[0-9]*$/)
      |> validate_length(:tac, max: 5, message: "should be at most 5 digit")
      |> validate_format(:telephone, ~r/^[0-9]*$/)
      |> validate_length(:telephone, is: 7, message: "should be 7 characters")
      |> validate_format(:tlc, ~r/^[0-9]*$/)
      |> validate_length(:tlc, max: 5, message: "should be at most 5 digit")
      ### Fax
      |> validate_format(:fcc, ~r/^\+?\d{1,10}$/)
      |> validate_length(:fcc, max: 5, message: "should be at most 4 digit")
      |> validate_format(:fac, ~r/^[0-9]*$/)
      |> validate_length(:fac, max: 5, message: "should be at most 5 digit")
      |> validate_format(:fax, ~r/^[0-9]*$/)
      |> validate_length(:fax, is: 7, message: "should be 7 characters")
      |> validate_format(:flc, ~r/^[0-9]*$/)
      |> validate_length(:flc, max: 5, message: "should be at most 5 digit")
      ###################################################################################################
      |> validate_format(:first_name, ~r/^[a-zA-Z٠١٢٣٤٥٦٧٨٩ ,.'Ññ-]+$/)
      |> validate_format(:middle_name, ~r/^[a-zA-Z٠١٢٣٤٥٦٧٨٩ ,.'Ññ-]+$/)
      |> validate_format(:last_name, ~r/^[a-zA-Z٠١٢٣٤٥٦٧٨٩ ,.'Ññ-]+$/)
      |> validate_format(:suffix, ~r/^[a-zA-Z٠١٢٣٤٥٦٧٨٩ ,.'Ññ-]+$/)
      |> validate_length(:first_name, max: 150, message: "should be at most 150 character(s)")
      |> validate_length(:middle_name, max: 150, message: "should be at most 150 character(s)")
      |> validate_length(:last_name, max: 150, message: "should be at most 150 character(s)")
      |> validate_length(:suffix, max: 10, message: "should be at most 10 character(s)")
      |> validate_length(:tin, is: 12, message: "should be 12 characters")
      |> validate_length(:postal, is: 4, message: "should be 4 characters")
      |> validate_length(:philhealth, is: 12, message: "should be 12 characters")
      |> validate_format(:philhealth, ~r/^[0-9]*$/)
      |> validate_length(:products, min: 1, message: "at least one is required")
      |> validate_last_name(:last_name)
      |> validate_member_type()
      |> validate_products()
      |> validate_effective_expiry()
      |> validate_employee_no()
      |> validate_account_effective_date()
      |> validate_account_expiry_date()
      |> validate_age()
      |> is_regular_checker()
      |> setup_is_regular()
      |> validate_active_account()
      |> validate_dependent_civil_status()
      #|> validate_philhealth()
      |> validate_status()
      |> put_change(:step, 5)
      |> put_change(:country, "Philippines")
      |> validate_mobile(:mobile)
      |> validate_mobile(:mobile2)
      |> validate_country_code(:mcc)
      |> validate_country_code(:mcc2)
      |> validate_country_code(:tcc)
      |> validate_country_code(:fcc)
      |> country_code_existing?(:mcc2, :mobile2)
      |> country_code_existing?(:tcc, :telephone)
      |> country_code_existing?(:fcc, :fax)
      |> mobile2_tel_fax_existing?(:mobile2, :mcc2)
      |> mobile2_tel_fax_existing?(:telephone, :tcc)
      |> mobile2_tel_fax_existing?(:fax, :fcc)
      |> validate_mobile_prefix(:mobile)
      |> validate_mobile_prefix(:mobile2)

      if changeset.valid? do
        {:ok, changeset}
      else
        {:changeset_error, changeset}
      end
  end

  defp validate_last_name(changeset, field) do
    if is_nil(changeset.changes[field]) do
      changeset =
      changeset
      |> put_change(:last_name, ".")
    else
      changeset
    end
  end

  def validate_mobile(changeset, field) do
    with true <- Map.has_key?(changeset.changes, field) do
      if String.starts_with?(changeset.changes[field], "9") do
        changeset
      else
        add_error(changeset, "#{field}", "number must start with '9'")
      end
    else
      _ ->
        changeset
    end
  end

  def validate_mobile_prefix(changeset, field) do
    with true <- Map.has_key?(changeset.changes, field),
         sliced_value <- mobile_no_slice(changeset, field),
         {:valid_prefix} <- prefix_checker(sliced_value)
    do
      changeset
    else
      false ->
        changeset

      {:invalid_prefix} ->
        add_error(changeset, "#{field}", "number got invalid prefix")
    end
  end

  def mobile_no_slice(changeset, field) do
    String.slice(changeset.changes[field], 0..2)
  end

  def prefix_checker(value) do
    case Enum.member?(mobile_prefix, value) do
      true ->
        {:valid_prefix}
      false ->
        {:invalid_prefix}
    end
  end

  def validate_country_code(changeset, field) do
    with true <- Map.has_key?(changeset.changes, field),
         changeset <- check_plus_sign(changeset, field)
    do
      changeset
    else
      _ ->
        changeset
    end
  end

  def check_plus_sign(changeset, field) do
    if String.starts_with?(changeset.changes[field], "+") do
      changeset
    else
      add_error(changeset, "#{field}", "country code must start with '+' sign")
    end
  end

  def country_code_existing?(changeset, field, field2) do
    with true <- Map.has_key?(changeset.changes, field),
         {true, index} <- optional_key_checker(changeset, field, 1),
         {true, index} <- optional_key_checker(changeset, field2, 2)
    do
      changeset
    else
      {false, index} ->
        if index == 2 do
          add_error(changeset, "#{field}", "already set, #{field2} is missing")
        else
          add_error(changeset, "#{field2}", "already set, #{field} is missing")
        end

                        _ ->
                          changeset
    end
  end

  def mobile2_tel_fax_existing?(changeset, field, field2) do
    with true <- Map.has_key?(changeset.changes, field),
         {true, index} <- optional_key_checker(changeset, field, 1),
         {true, index} <- optional_key_checker(changeset, field2, 2)
    do
      changeset
    else
      {false, index} ->
        if index == 2 do
          add_error(changeset, "#{field}", "already set, #{field2} is missing")
        else
          add_error(changeset, "#{field2}", "already set, #{field} is missing")
        end

                        _ ->
                          changeset
    end
  end

  def optional_key_checker(changeset, field, index) do
    case Map.has_key?(changeset.changes, field) do
      true ->
        {true, index}
      false ->
        {false, index}
    end
  end

  defp validate_status(changeset) do
    with true <- Map.has_key?(changeset.changes, :effectivity_date) do
      case Ecto.Date.compare(changeset.changes.effectivity_date, Ecto.Date.utc()) do
        :lt ->
          put_change(changeset, :status, "Active")
        :eq ->
          put_change(changeset, :status, "Active")
        _ ->
          changeset
      end
                                                                    else
                                                                      _ ->
                                                                        changeset
    end
  end

  defp validate_philhealth(changeset) do
    with true <- Map.has_key?(changeset.changes, :philhealth_type) do
      if changeset.changes.philhealth_type == "Required to file" or changeset.changes.philhealth_type == "Optional to file" do
        validate_required(changeset, [:philhealth], message: "is required")
      else
        put_change(changeset, :philhealth, "")
      end
    else
      _ ->
        changeset
    end
  end

  defp validate_dependent_civil_status(changeset) do
    with true <- Map.has_key?(changeset.changes, :type),
         true <- Map.has_key?(changeset.changes, :relationship),
         "Dependent" <- changeset.changes.type
    do
      case changeset.changes.relationship do
        ## Relaxed validation as per sir Rey and Ma'am Esther 06/13/18 8:08 pm
        # "Sibling" ->
          #   validate_inclusion(changeset, :civil_status, ["Single"], message: "Sibling dependents should be Single")
        # "Parent" ->
          #   validate_inclusion(changeset, :civil_status, ["Married"], message: "Parent dependents should be Married")
        "Partner" ->
          validate_inclusion(changeset, :civil_status, ["Married"], message: "Partner dependent should be Married")
        "Partners" ->
          validate_inclusion(changeset, :civil_status, ["Others"], message: "Partners dependent should be Others")
        # "Child" ->
          #   validate_inclusion(changeset, :civil_status, ["Single"], message: "Child dependents should be Single")
        _ ->
          changeset
      end
    else
      _ ->
        changeset
    end
  end

  defp validate_active_account(changeset) do
    with true <- Map.has_key?(changeset.changes, :account_code),
         %AccountGroup{} = account_group <- get_account_group(changeset.changes.account_code)
    do
      if is_nil(List.first(account_group.account)) do
        add_error(changeset, :account_code, "is invalid")
      else
        changeset
      end
    else
      _ ->
        changeset
    end
  end

  defp setup_is_regular(changeset) do
    with true <- Map.has_key?(changeset.changes, :is_regular) do
      case changeset.changes.is_regular do
        true ->
          regularization_date_checker(changeset)
        false ->
          regularization_date_checker(changeset)
        _ ->
          changeset
      end
                                                              else
                                                                _ ->
                                                                  changeset
    end
  end

  defp regularization_date_checker(changeset) do
    with true <- Map.has_key?(changeset.changes, :date_hired),
         true <- Map.has_key?(changeset.changes, :regularization_date)
    do
      case Ecto.Date.compare(changeset.changes.date_hired, changeset.changes.regularization_date) do
        :lt ->
          changeset
        :eq ->
          changeset
        _ ->
          add_error(changeset, :regularization_date, "cannot be less than date_hired")
      end
    else
      _ ->
        changeset
    end
  end

  defp is_regular_checker(changeset) do
    with true <- Map.has_key?(changeset.changes, :account_code),
         true <- Map.has_key?(changeset.changes, :type),
         %AccountGroup{} = account_group <- get_account_group(changeset.changes.account_code),
         "Corporate" <- account_group.segment,
         "Principal" <- changeset.changes.type
    do
      validate_required(changeset, :is_regular)
    else
      _ ->
        changeset
    end
  end

  defp validate_age(changeset) do
    with true <- Map.has_key?(changeset.changes, :birthdate) do
      if UtilityContext.age(changeset.changes.birthdate) > 99 do
        add_error(changeset, :birthdate, "maximum age is 99")
      else
        changeset
      end
    else
      _ ->
        changeset
    end
  end

  #defp validate_effectivity_date(changeset) do
  #  with true <- Map.has_key?(changeset.changes, :effectivity_date) do
  #    if Ecto.Date.compare(Ecto.Date.utc(), changeset.changes.effectivity_date) != :lt do
  #      add_error(changeset, :effectivity_date, "must be future dated")
  #    else
  #      changeset
  #    end
  #  else
  #    _ ->
  ##      changeset
  #  end
  #end

  defp validate_products(changeset) do
    with true <- Map.has_key?(changeset.changes, :account_code),
         true <- Map.has_key?(changeset.changes, :products)
    do
      result = get_account_products(changeset.changes.account_code, changeset.changes.products)
      codes = Enum.map(result, fn({code, id}) -> code end)
      ids = Enum.map(result, fn({code, id}) -> id end)
      invalid_codes = Enum.uniq(changeset.changes.products) -- codes
      if Enum.empty?(invalid_codes) do
        put_change(changeset, :products, ids)
      else
        add_error(changeset, :products, "is invalid: plan that has been picked is not included to a given account")
      end
    else
      _ ->
        changeset
    end
  end

  defp validate_products2(changeset) do
    with true <- Map.has_key?(changeset.changes, :account_code),
         true <- Map.has_key?(changeset.changes, :products)
    do
      if mp_ids = validate_account_product(changeset) do
        put_change(changeset, :products, mp_ids)
      else
        add_error(changeset, :products, "is invalid: plan that has been picked is not included to a given account")
      end
    else
      _ ->
        changeset
    end
  end

  defp get_account_products(account_group_code, products) do
    AccountGroup
    |> join(:inner, [ag], a in Account, ag.id == a.account_group_id)
    |> join(:inner, [ag, a], ap in AccountProduct, a.id == ap.account_id)
    |> join(:inner, [ag, a, ap], p in Product, ap.product_id == p.id)
    |> where([ag, a, ap, p], a.status == "Active" or a.status == "Pending")
    |> where([ag, a, ap, p], p.code in ^products)
    |> where([ag, a, ap, p], ag.code == ^account_group_code)
    |> select([ag, a, ap, p], {p.code, ap.id})
    |> Repo.all()
  end

  defp validate_account_product(changeset) do
    # need to clarify to vicky regards on list.first
    account_code = changeset.changes.account_code
    with %AccountGroup{} = account_group <- get_account_group(account_code),
         %Account{} = active_account <- List.first(account_group.account)
    do
      account_product_ids = Enum.map(active_account.account_products, &(&1.id))
      member_product_ids = Enum.map(changeset.changes.products, &(get_account_product(active_account.id, &1)))
      if Enum.empty?(member_product_ids -- account_product_ids) do
        member_product_ids
      else
        false
      end
    else
      _ ->
        false
    end
  end

  defp get_account_product(account_id, product_code) do
    AccountProduct
    |> join(:inner, [ap], p in Product, p.id == ap.product_id)
    |> where([ap, p], ap.account_id == ^account_id and p.code == ^product_code)
    |> select([ap], ap.id)
    |> Repo.one()
  end

  defp validate_employee_no(changeset) do
    with true <- Map.has_key?(changeset.changes, :account_code),
         true <- Map.has_key?(changeset.changes, :employee_no),
         true <- Map.has_key?(changeset.changes, :type)
    do
      if changeset.changes.type != "Dependent" do
        if Enum.member?(get_account_employee_nos(changeset.changes.account_code), changeset.changes.employee_no) do
          add_error(changeset, :employee_no, "already exists within the account")
        else
          changeset
        end
      else
        changeset
      end
    else
      _ ->
        changeset
    end
  end

 defp validate_employee_no_refactored(changeset) do
    with true <- Map.has_key?(changeset.changes, :account_code),
         true <- Map.has_key?(changeset.changes, :employee_no),
         true <- Map.has_key?(changeset.changes, :type)
    do
      if changeset.changes.type != "Dependent" do
        if is_nil(get_account_employee_nos_refactored(changeset.changes.account_code, changeset.changes.employee_no)) do
          changeset
        else
          add_error(changeset, :employee_no, "already exists within the account")
        end
      else
        changeset
      end
    else
      _ ->
        changeset
    end
  end


  defp validate_account_effective_date(changeset) do
    with true <- Map.has_key?(changeset.changes, :effectivity_date),
         true <- Map.has_key?(changeset.changes, :account_code),
         {:ok, account_group} <- validate_ag_code(changeset.changes.account_code),
         %Account{} = account <- List.first(account_group.account)
    do
      if in_range?(account.start_date, account.end_date, changeset.changes.effectivity_date) do
        changeset
      else
        add_error(changeset, :effectivity_date, "should be in range of the given account")
      end
    else
      _ ->
        changeset
    end
  end

  defp validate_account_expiry_date(changeset) do
    with true <- Map.has_key?(changeset.changes, :expiry_date),
         true <- Map.has_key?(changeset.changes, :account_code),
         {:ok, account_group} <- validate_ag_code(changeset.changes.account_code),
         %Account{} = account <- List.first(account_group.account)
    do
      if in_range?(account.start_date, account.end_date, changeset.changes.expiry_date) do
        changeset
      else
       ## as per discussed with ma'am Esther and sir Rey for Migration
        changeset =
           put_change(changeset, :expiry_date, account.end_date)
  # add_error(changeset, :expiry_date, "should be in range of the given account")
      end
    else
      _ ->
        changeset
    end
  end

  defp validate_expiry_member_expiry_account(changeset) do
    with true <- Map.has_key?(changeset.changes, :expiry_date),
         true <- Map.has_key?(changeset.changes, :account_code),
         changeset <- checker_date_account_and_member(changeset, changeset.changes.expiry_date, get_account_expiry_date(changeset.changes.account_code))

    do
      changeset
    else
      _ ->
        add_error(changeset, :expiry_date, "is invalid")

    end
  end

  def checker_date_account_and_member(changeset, med, aed) do
    case Ecto.Date.compare(med, aed) do
      :lt ->
        changeset
      :eq ->
        changeset
      :gt ->
        changeset =
          put_change(changeset, :expiry_date, aed)
    end
  end

  defp get_account_expiry_date(account_code) do
    acg_id =
    AccountGroup
    |> select([ag], ag.id)
    |> where([ag], ag.code == ^account_code)
    |> Repo.one

    Account
    |> select([a], a.end_date)
    |> where([a], a.account_group_id == ^acg_id)
    # |> order_by([a], desc: a.inserted_at)
    |> where([a], a.status == ^"Active")
    |> limit(1)
    |> Repo.one
  end


  defp in_range?(effective_date, expiry_date, date) do
    case Ecto.Date.compare(effective_date, date) do
      :lt ->
        compare_effective_expiry(expiry_date, date)
      :eq ->
        compare_effective_expiry(expiry_date, date)
      _ ->
        false
    end
  end

  defp compare_effective_expiry(d1, d2) do
    case Ecto.Date.compare(d1, d2) do
      :gt ->
        true
      :eq ->
        true
      _ ->
        false
    end
  end

  defp validate_effective_expiry(changeset) do
    with true <- Map.has_key?(changeset.changes, :effectivity_date),
         true <- Map.has_key?(changeset.changes, :expiry_date)
         #
    do
      case Ecto.Date.compare(changeset.changes.expiry_date, changeset.changes.effectivity_date) do
        :gt ->
          changeset
        _ ->
          add_error(changeset, :expiry_date, "must be greater than effectivity_date")
      end
    else
      _ ->
        changeset
    end
  end

  defp validate_ag_code(account_code) do
    account_group = get_account_group(account_code)
    if account_group do
      {:ok, account_group}
    else
      {:error}
    end
  end

  defp validate_member_type(changeset) do
    with true <- Map.has_key?(changeset.changes, :type),
         true <- Map.has_key?(changeset.changes, :account_code),
         true <- Enum.member?(["Principal", "Dependent", "Guardian"], changeset.changes.type),
         true <- Map.has_key?(changeset.changes, :effectivity_date),
         true <- Map.has_key?(changeset.changes, :expiry_date),
         %AccountGroup{} = account_group <- get_account_group(changeset.changes.account_code),
         {:ok, changeset} <- member_type_validations(changeset, account_group)
    do
      changeset
    else
      _ ->
        changeset
    end
  end

  defp validate_member_type_refactored(changeset) do
    with true <- Map.has_key?(changeset.changes, :type),
         true <- Map.has_key?(changeset.changes, :account_code),
         true <- Enum.member?(["Principal", "Dependent", "Guardian"], changeset.changes.type),
         true <- Map.has_key?(changeset.changes, :effectivity_date),
         true <- Map.has_key?(changeset.changes, :expiry_date),
         %AccountGroup{} = account_group <- get_account_group(changeset.changes.account_code),
         {:ok, changeset} <- member_type_validations_refactored(changeset, account_group)
    do
      changeset
    else
      _ ->
        changeset
    end
  end

  defp validate_member_type_refactored_v2(changeset) do
    with true <- Map.has_key?(changeset.changes, :type),
         true <- Map.has_key?(changeset.changes, :account_code),
         true <- Enum.member?(["Principal", "Dependent", "Guardian"], changeset.changes.type),
         true <- Map.has_key?(changeset.changes, :effectivity_date),
         true <- Map.has_key?(changeset.changes, :expiry_date),
         %AccountGroup{} = account_group <- get_account_group(changeset.changes.account_code),
         {:ok, changeset} <- member_type_validations_refactored_v2(changeset, account_group)
    do
      changeset
    else
      _ ->
        changeset
    end
  end

  defp member_type_validations(changeset, account) do
    case changeset.changes.type do
      "Principal" ->
        new_changeset = put_change(changeset, :relationship, "")
        {:ok, merge(changeset, validate_principal_fields(new_changeset, account))}
      "Dependent" ->
        {:ok, merge(changeset, validate_dependent_fields(changeset))}
      "Guardian" ->
        {:ok, merge(changeset, validate_guardian_fields(changeset))}
        # ## as per Sir rey added others in relationship 06/13/18 3:51 pm
      # "Others" ->
        # new_changeset = put_change(changeset, :relationship, "Others")
        # {:ok, merge(changeset, new_changeset)}
      _ ->
        new_changeset = put_change(changeset, :relationship, "")
        {:ok, new_changeset}
    end
  end

  defp member_type_validations_refactored(changeset, account) do
    case changeset.changes.type do
      "Principal" ->
        new_changeset = put_change(changeset, :relationship, "")
        {:ok, merge(changeset, validate_principal_fields(new_changeset, account))}
      "Dependent" ->
        {:ok, validate_dependent_fields(changeset)}
      "Guardian" ->
        {:ok, merge(changeset, validate_guardian_fields(changeset))}
        ## as per Sir rey added others in relationship 06/13/18 3:51 pm
      "Others" ->
        new_changeset = put_change(changeset, :relationship, "Others")
        {:ok, merge(changeset, new_changeset)}
      _ ->
        new_changeset = put_change(changeset, :relationship, "")
        {:ok, new_changeset}
    end
  end

  defp member_type_validations_refactored_v2(changeset, account) do
    case changeset.changes.type do
      # "Principal" ->
      #   new_changeset = put_change(changeset, :relationship, "")
      #   {:ok, merge(changeset, validate_principal_fields(new_changeset, account))}
      "Dependent" ->
        {:ok, validate_dependent_fields_v2(changeset)}
      # "Guardian" ->
      #   {:ok, merge(changeset, validate_guardian_fields(changeset))}
      #   ## as per Sir rey added others in relationship 06/13/18 3:51 pm
      # "Others" ->
      #   new_changeset = put_change(changeset, :relationship, "Others")
      #   {:ok, merge(changeset, new_changeset)}
      _ ->
        new_changeset = put_change(changeset, :relationship, "")
        {:ok, new_changeset}
    end
  end

  defp validate_guardian_fields(changeset) do
    changeset
    |> validate_required([
      :employee_no
    ], message: "is required")
  end

  defp validate_dependent_fields_v2(changeset) do
    changeset
    |> validate_dependent_employee_no()
  end

  defp validate_dependent_fields(changeset) do
    changeset
    |> validate_required([
      # :employee_no,
      :relationship,
      :principal_product_code
    ], message: "is required")
    |> validate_child_age()
    |> validate_parent_age()
    |> validate_sibling_age()
    |> validate_dependent_gender()
    |> validate_dependent_employee_no()
    |> validate_principal_product()
    |> validate_principal_product_skipping()
  end

  defp validate_principal_product(changeset) do
    with true <- Map.has_key?(changeset.changes, :principal),
         true <- Map.has_key?(changeset.changes, :principal_product_code)
    do
      if Enum.member?(map_principal_product_codes(changeset), changeset.changes.principal_product_code) do
        principal_product = get_principal_product(changeset)
        changeset
        |> put_change(:principal_product_id, principal_product.id)
        |> put_change(:principal_product, principal_product)
      else
        add_error(changeset, :principal_product_code, "is invalid")
      end
    else
      _ ->
        changeset
    end
  end

  defp validate_principal_product_skipping(changeset) do
    with true <- Map.has_key?(changeset.changes, :principal_product) do
      case changeset.changes.principal_product.account_product.product.hierarchy_waiver do
        "Waive" ->
          changeset
        _ ->
          validate_hierarchy(changeset)
      end
                                                                     else
                                                                       _ ->
                                                                         changeset
    end
  end

  defp get_principal_product(changeset) do
    Enum.find(changeset.changes.principal.products, fn(member_product) ->
      member_product.account_product.product.code == changeset.changes.principal_product_code
    end)
  end

  defp map_principal_product_codes(changeset) do
    Enum.map(
      changeset.changes.principal.products,
      &(&1.account_product.product.code)
    )
  end

  defp validate_dependent_gender(changeset) do
    with true <- Map.has_key?(changeset.changes, :relationship),
         true <- Map.has_key?(changeset.changes, :employee_no),
         true <- Map.has_key?(changeset.changes, :account_code),
         true <- Map.has_key?(changeset.changes, :gender),
         %Member{} = principal <- get_member_by_emp_no(changeset.changes.employee_no, changeset.changes.account_code)
    do
      principal = MemberContext.get_member!(principal.id)
      validate_gender_relationship(changeset, principal)
    else
      _ ->
        changeset
    end
  end

  defp validate_gender_relationship(changeset, principal) do
    if changeset.changes.relationship == "Parent" do
      parents = get_parent_dependents(principal.dependents)
      if Enum.empty?(parents) do
        changeset
      else
        validate_parent_gender(changeset, parents)
      end
    else
      changeset
    end
  end

  defp validate_parent_gender(changeset, parents) do
    case List.first(parents).gender do
      "Female" ->
        validate_inclusion(changeset, :gender, ["Male"])
      "Male" ->
        validate_inclusion(changeset, :gender, ["Female"])
      _ ->
        validate_inclusion(changeset, :gender, ["Male", "Female"])
    end
  end

  defp get_parent_dependents(dependents), do: for %{relationship: "Parent"} = dependent <- dependents, do: dependent

  defp validate_child_age(changeset) do
    with true <- Map.has_key?(changeset.changes, :relationship),
         true <- Map.has_key?(changeset.changes, :employee_no),
         true <- Map.has_key?(changeset.changes, :account_code),
         true <- Map.has_key?(changeset.changes, :birthdate),
         "Child" <- changeset.changes.relationship,
         %Member{} = principal <- get_member_by_emp_no(changeset.changes.employee_no, changeset.changes.account_code)
    do
      if Enum.empty?(principal.dependents) do
        if Ecto.Date.compare(
          changeset.changes.birthdate,
          principal.birthdate
        ) == :lt or Ecto.Date.compare(
          changeset.changes.birthdate,
          principal.birthdate
        ) == :eq do
          add_error(changeset, :birthdate, "cannot be older than principal")
        else
          changeset
        end
      else
        last_enrolled_child = List.first(principal.dependents)
        if Ecto.Date.compare(
          changeset.changes.birthdate,
          last_enrolled_child.birthdate
        ) == :lt or Ecto.Date.compare(
          changeset.changes.birthdate,
          last_enrolled_child.birthdate
        ) == :eq do
          add_error(changeset, :birthdate, "cannot be older than previously enrolled child")
        else
          changeset
        end
      end
    else
      _ ->
        changeset
    end
  end

  defp validate_parent_age(changeset) do
    with true <- Map.has_key?(changeset.changes, :relationship),
         true <- Map.has_key?(changeset.changes, :employee_no),
         true <- Map.has_key?(changeset.changes, :account_code),
         true <- Map.has_key?(changeset.changes, :birthdate),
         "Parent" <- changeset.changes.relationship,
         %Member{} = principal <- get_member_by_emp_no(changeset.changes.employee_no, changeset.changes.account_code)
    do
      # if Ecto.Date.compare(
        # changeset.changes.birthdate,
        # principal.birthdate
      # ) == :gt or Ecto.Date.compare(
        # changeset.changes.birthdate,
        # principal.birthdate
      # ) == :eq do
        # add_error(changeset, :birthdate, "cannot be younger than principal")
      # else
        changeset
      # end
    else
      _ ->
        changeset
    end
  end

  defp validate_sibling_age(changeset) do
    with true <- Map.has_key?(changeset.changes, :relationship),
         true <- Map.has_key?(changeset.changes, :employee_no),
         true <- Map.has_key?(changeset.changes, :account_code),
         true <- Map.has_key?(changeset.changes, :birthdate),
         "Sibling" <- changeset.changes.relationship,
         %Member{} = principal <- get_member_by_emp_no(changeset.changes.employee_no, changeset.changes.account_code)
    do
      if Ecto.Date.compare(
        changeset.changes.birthdate,
        principal.birthdate
      ) == :lt or Ecto.Date.compare(
        changeset.changes.birthdate,
        principal.birthdate
      ) == :eq do
        add_error(changeset, :birthdate, "cannot be older than principal")
      else
        changeset
      end
    else
      _ ->
        changeset
    end
  end

  defp check_key_if_existing(changes, key) do
    if Map.has_key?(changes, key) do
      true
    else
      {:invalid_params}
    end
  end

  defp validate_relationship(relationship) do
    hierarchies = ["Partner", "Sibling", "Child", "Parent"]
    if Enum.member?(hierarchies, relationship) do
      true
    else
      {:invalid_params}
    end
  end

  defp check_child_age(changeset) do
    account_code = changeset.changes.account_code
    employee_no = changeset.changes.employee_no
    birthdate = changeset.changes.birthdate
    relationship = changeset.changes.relationship

    principal =
      Member
      |> Repo.get!(changeset.changes.principal_id)

    if principal do
      if relationship == "Child" do
        case Ecto.Date.compare(principal.birthdate, birthdate) do
          :lt ->
            true
          _ ->
            {:error_age}
        end
    else
      true
      end
      else
        false
    end
  end

  defp validate_hierarchy(changeset) do
    with true <- changeset.changes.type == "Dependent",
         true <- check_key_if_existing(changeset.changes, :principal_id),
         true <- check_key_if_existing(changeset.changes, :relationship),
         true <- check_key_if_existing(changeset.changes, :birthdate),
         true <- check_key_if_existing(changeset.changes, :account_code),
         true <- validate_relationship(changeset.changes.relationship),
         true <- check_child_age(changeset)
    do
      account_code = changeset.changes.account_code
      employee_no = changeset.changes.employee_no
      relationship = changeset.changes.relationship

      # Check all members enrolled in principal
      members =
        Member
        |> where([m], m.employee_no == ^employee_no)
        |> Repo.all
      principal =
        Member
        |> Repo.get!(changeset.changes.principal_id)

      if is_nil(principal) do
        add_error(changeset, :relationship, " -- Employee number doesn't exist.")
      else
        principal_id = principal.id
        civil_status = principal.civil_status

        # Get hierarchy type by civil status
        hierarchy_type = case String.downcase(civil_status) do
          "single" ->
            "Single Employee"
          "married" ->
            "Married Employee"
          _ ->
            "Single Parent Employee"
        end

        # Get last member
        member_query = (
          from m in Member,
          where: m.principal_id == ^principal_id and m.account_code == ^account_code,
          order_by: [asc: m.inserted_at]
        )

        last_member =
          member_query
          |> Repo.all
          |> List.last

          # Check if there are other dependents to its principal
          if is_nil(last_member) do
            # Check current relation if it is on top of the account's hierarchy
            account_group =
              AccountGroup
              |> Repo.get_by(%{code: account_code})

              ahoed_first =
                AccountHierarchyOfEligibleDependent
                |> where([ahoed],
                         ahoed.account_group_id == ^account_group.id and
                       ahoed.hierarchy_type == ^hierarchy_type and
                         ahoed.ranking == 1)
                         |> Repo.one

                         if is_nil(ahoed_first) do
                           add_error(changeset, :relationship, " -- " <> relationship  <> " doesn't belong to dependents of Principal's civil status.")
                         else
                          relationship2 =
                            if String.downcase(relationship) == "partner" do
                              "Spouse"
                            else
                              relationship
                            end

                           if ahoed_first.dependent == relationship2 do
                             changeset
                           else
                             add_error(changeset, :relationship, " error -- You can add a " <> ahoed_first.dependent <>  " instead.")
                           end
                         end
          else
            relationship2 =
              if String.downcase(relationship) == "partner" do
                "Spouse"
              else
                relationship
              end
            # Check the relationship of the member to be enrolled
            if relationship2 == last_member.relationship do
              # Check if last_member's relation is not beyond its limitation
              if check_relationship_count(relationship, civil_status, members, principal_id) do
                changeset
              else
                add_error(changeset, :relationship, " error -- Cannot add member with " <> relationship  <> ".")
              end
            else
              # Check last member's relation and get its ranking in heirarchy
              account_group =
                AccountGroup
                |> Repo.get_by(%{code: account_code})

                _ahoed_list =
                  AccountHierarchyOfEligibleDependent
                  |> where([ahoed], ahoed.account_group_id == ^account_group.id and ahoed.hierarchy_type == ^hierarchy_type)
                  |> Repo.all

                  last_ahoed =
                    AccountHierarchyOfEligibleDependent
                    |> where([ahoed],
                             ahoed.account_group_id == ^account_group.id and
                             ahoed.dependent == ^last_member.relationship and
                             ahoed.hierarchy_type == ^hierarchy_type)
                             |> Repo.one

                          relationship2 =
                            if String.downcase(relationship) == "partner" do
                              "Spouse"
                            else
                              relationship
                            end

                             current_ahoed =
                               AccountHierarchyOfEligibleDependent
                               |> where([ahoed],
                                        ahoed.account_group_id == ^account_group.id and
                                        ahoed.dependent == ^relationship2 and
                                        ahoed.hierarchy_type == ^hierarchy_type)
                              |> Repo.one

                             if current_ahoed == nil do
                               add_error(changeset, :relationship, " -- " <> relationship  <> " doesn't belong to dependents of Principal's civil status.")
                             else
                               last_ahoed_ranking = last_ahoed.ranking + 1
                               if current_ahoed.ranking == last_ahoed_ranking do
                                 changeset
                               else
                                relationship2 =
                                  if current_ahoed.dependent == "Spouse" do
                                    "Partner"
                                  else
                                    current_ahoed.dependent
                                  end

                                 add_error(changeset, :relationship, " -- Cannot add member with " <> relationship2 <> ".")
                               end
                             end
            end
          end
      end
      else
      {:invalid_params} ->
        add_error(changeset, :relationship, " -- Invalid parameters.")
        _ ->
          changeset
    end
  end

  defp count_hierarchy(member, relationship, principal_id) do
    _member =
      Member
      |> where([m], m.relationship == ^relationship and m.principal_id == ^principal_id)
      |> Repo.all
      |> Enum.count
  end

  defp check_relationship_count(relationship, civil_status, members, principal_id) do
    # Check relationship limits
    case relationship do
      "Partner" ->
        count = if civil_status == "Married", do: count_hierarchy(members, "Spouse", principal_id), else: 0
        if count < 1, do: true, else:  false
          "Parent" ->
            count = count_hierarchy(members, "Parent", principal_id)
            if count < 2, do: true, else:  false
              _ ->
                true
    end
  end

  defp validate_dependent_employee_no(changeset) do
    with true <- Map.has_key?(changeset.changes, :account_code),
         true <- Map.has_key?(changeset.changes, :employee_no)
    do
      if principal = get_member_by_emp_no(changeset.changes.employee_no, changeset.changes.account_code) do
        # if principal.status != "Active" do
        #   add_error(changeset, :principal, "is not yet active")
        # else
        changeset
        |> put_change(:principal_id, principal.id)
        |> put_change(:principal, principal)
        |> put_change(:employee_no, "")

        # end
      else
        add_error(changeset, :employee_no, "is not existing to a given account")
      end
    else
      _ ->
        changeset
    end
  end

  defp get_member_by_emp_no(employee_number) do
    Member
    |> where([m], m.employee_no == ^employee_number and m.type == "Principal")
    |> Repo.one()
    |> Repo.preload([dependents: from(m in Member, order_by: [desc: m.birthdate])])
  end

  defp get_member_by_emp_no(employee_number, account_code) do
    Member
    |> where([m],
             m.account_code == ^account_code and
             m.employee_no == ^employee_number and
             (m.type == "Principal" or m.type == "Guardian"))
             |> Repo.one()
             |> Repo.preload([
               dependents: from(m in Member, order_by: [desc: m.birthdate]),
               products: [
                 account_product: :product
               ]
             ])
  end

  defp validate_principal_fields(changeset, account) do
    case account.segment do
      "Corporate" ->
        validate_corporate_principal(changeset)
      _ ->
        changeset
    end
  end

  defp validate_corporate_principal(changeset) do
    changeset
    |> validate_required([
      :employee_no,
      :date_hired
    ], message: "is required")
  end

  defp get_account_group(code) do
    AccountGroup
    |> where([ag], ag.code == ^code)
    |> Repo.one()
    |> Repo.preload(account: {from(a in Account, where: a.status == "Active" or a.status == "Pending"), :account_products})
  end

  defp get_all_account_codes do
    AccountGroup
    |> select([ag], ag.code)
    |> Repo.all()
  end

  defp validate_member_account_codes(changeset) do
    with true <- Map.has_key?(changeset.changes, :account_code) do
    # with code <- changeset.changes[:account_code] do
      code = changeset.changes.account_code
      if is_nil(check_account_group(code)) do
        changeset =
          add_error(changeset, :account_code, "invalid code")
     else
        changeset
      end
        changeset
    else
      _ ->
        add_error(changeset, :account_code, "invalid account code")
    end
  end

  defp check_account_group(code) do
    AccountGroup
    |> select([ag], ag.code)
    |> where([ag], ag.code == ^code)
    |> Repo.one()
  end

  defp get_all_principal_ids do
    Member
    |> select([m], m.id)
    |> Repo.all()
  end

  defp validate_principal_ids(changeset) do

    p_ids = changeset.changes.principal_id
    if is_nil(check_principal_id(p_ids)) do
       changeset =
         add_error(changeset, :principal_id, "is invalid")
    else
        changeset
    end
  end

  defp check_principal_id(p_ids) do
    Member
    |> select([m], m.id)
    |> where([m], m.id == ^p_ids)
    |> Repo.one()
  end

  defp get_all_account_product_ids do
    AccountProduct
    |> select([ap], ap.id)
    |> Repo.all()
  end

  defp get_all_account_product_ids(account_id) do
    AccountProduct
    |> where([ap], ap.account_id == ^account_id)
    |> select([ap], ap.id)
    |> Repo.all()
  end

  defp get_account_employee_nos(account_code) do
    Member
    |> where([m], m.account_code == ^account_code)
    |> select([m], m.employee_no)
    |> Repo.all()
  end

  defp get_account_employee_nos_refactored(account_code, employee_nos) do
    Member
    |> where([m], m.account_code == ^account_code)
    |> select([m], m.employee_no)
    |> where([m], m.employee_no == ^employee_nos)
    |> Repo.one()
  end


  def get_member_by_card_no(nil), do: nil
  def get_member_by_card_no(card_no) do
    Member
    |> where([m], m.card_no == ^card_no)
    |> limit(1)
    |> Repo.one()
  end

  #################################### member movement cancel #######################################

  def validate_member_cancellation(user, params) do
    with {:ok, changeset} <- validate_member_cancellation_changeset(params),
         {:ok, member} <- cancel_member(user, changeset.changes)
    do
      {:ok, member}
    else
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp cancel_member(_user, params) do
    member = get_member_by_card_number(params.card_no)

    case member |> Member.changeset_cancel(params) |> Repo.update() do
      {:ok, member} ->
        {:ok, member}
      {:error, changeset} ->
        {:error, changeset}
    end

  end

  defp validate_member_cancellation_changeset(params) do

    data = %{}
    member_cancellation_types = %{
      card_no: :string,
      cancel_date: Ecto.Date,
      cancel_reason: :string,
      cancel_remarks: :string
    }
    changeset =
      {data, member_cancellation_types}
      |> cast(params, Map.keys(member_cancellation_types))
      |> validate_required([
        :card_no,
        :cancel_date,
        :cancel_reason
      ])
      |> validate_inclusion(:card_no, card_no_checker(), message: "card no. not existing")
    changeset =
      if Map.has_key?(changeset.changes, :card_no) do
        changeset =
          changeset
          |> validate_member_status_for_cancel()
          if changeset.valid? do
            _changeset =
              changeset
              |> validate_cancel_date()
          else
            changeset
          end
      else
        changeset
      end

      if changeset.valid? do
        {:ok, changeset}
      else
        {:error, changeset}
      end
  end

  defp validate_member_status_for_cancel(changeset) do
    if member = get_member_by_card_number(changeset.changes.card_no) do
      if member.status == "Active" or member.status == "Suspended" do
        changeset
      else
        add_error(changeset, :card_no, "Member should cancel only if status is Active or Suspended")
      end
    else
      changeset
    end
  end

  defp validate_cancel_date(changeset) do
    with true <- Map.has_key?(changeset.changes, :cancel_date),
         {:ok, cancel_date} <- Ecto.Date.cast(changeset.changes.cancel_date)
    do
      casted_cancel_date = cancel_date
      cancel_date =
        cancel_date
        |> Ecto.Date.compare(Ecto.Date.utc)

      if member = get_member_by_card_number(changeset.changes.card_no) do

        ## for tom day
        today = Ecto.Date.utc()
        duration_one = TD.from_days(1)
        tomorrow = Timex.add(today, duration_one)
        incremented = Ecto.Date.cast!(tomorrow)

        ## for decrementing of expiry_date.day
        expiry_date = member.expiry_date
        duration_one = TD.from_days(1)
        expiry_date = Timex.subtract(expiry_date, duration_one)
        decremented = Ecto.Date.cast!(expiry_date)

        cond do
          not is_nil(member.cancel_date) == true and
          not is_nil(member.suspend_date) == true and
          not is_nil(member.suspend_reason) == true and
          not is_nil(member.reactivate_date) == true and
          not is_nil(member.reactivate_reason) == true and
          not is_nil(member.cancel_reason) == true ->
            add_error(changeset, :dates, "cancel date and suspension date reactivation date already been set!")

            ### if cancel_date_inputted and (member.suspend_date or member.reactivate_date) are equal
            (
              not is_nil(member.suspend_date) and
              Ecto.Date.compare(changeset.changes.cancel_date, member.suspend_date) == :eq
            ) or (
              not is_nil(member.reactivate_date) and
              Ecto.Date.compare(changeset.changes.cancel_date, member.reactivate_date) == :eq
            ) ->
              cond do
                not is_nil(member.reactivate_date) and not is_nil(member.suspend_date) ->
                  compared_date = Ecto.Date.compare(member.reactivate_date, member.suspend_date)
                  if compared_date == :gt do
                    reactivate_date = member.reactivate_date
                    duration_one = TD.from_days(1)
                    reactivate_date = Timex.add(reactivate_date, duration_one)
                    reactivate_date_incremented = Ecto.Date.cast!(reactivate_date)
                    add_error(changeset, :cancel_date, "cancellation date should be in range of above reactivate1 date(#{reactivate_date_incremented}) and below expiry date(#{decremented})")
                  else
                    suspend_date = member.suspend_date
                    duration_one = TD.from_days(1)
                    suspend_date = Timex.add(suspend_date, duration_one)
                    suspend_date_incremented = Ecto.Date.cast!(suspend_date)
                    add_error(changeset, :cancel_date, "cancellation date should be in range of above suspend1 date(#{suspend_date_incremented}) and below expiry date(#{decremented})")
                  end
                not is_nil(member.reactivate_date) ->
                  reactivate_date = member.reactivate_date
                  duration_one = TD.from_days(1)
                  reactivate_date = Timex.add(reactivate_date, duration_one)
                  reactivate_date_incremented = Ecto.Date.cast!(reactivate_date)
                  add_error(changeset, :cancel_date, "cancellation date should be in range of above reactivate1 date(#{reactivate_date_incremented}) and below expiry date(#{decremented})")
                not is_nil(member.suspend_date) ->
                  suspend_date = member.suspend_date
                  duration_one = TD.from_days(1)
                  suspend_date = Timex.add(suspend_date, duration_one)
                  suspend_date_incremented = Ecto.Date.cast!(suspend_date)
                  add_error(changeset, :cancel_date, "cancellation date should be in range of above suspend1 date(#{suspend_date_incremented}) and below expiry date(#{decremented})")
              end

              ### if cancel_date_inputted is less than member.suspend_date or member.reactivate_date
              (
                not is_nil(member.suspend_date) and
                Ecto.Date.compare(
                  changeset.changes.cancel_date,
                  member.suspend_date
                ) == :lt) or
                (
                  not is_nil(member.reactivate_date) and
                  Ecto.Date.compare(
                    changeset.changes.cancel_date,
                    member.reactivate_date
                  ) == :lt) ->
                    cond do
                      not is_nil(member.reactivate_date) and not is_nil(member.suspend_date) ->
                        compared_date = Ecto.Date.compare(member.reactivate_date, member.suspend_date)
                        if compared_date == :gt do
                          reactivate_date = member.reactivate_date
                          duration_one = TD.from_days(1)
                          reactivate_date = Timex.add(reactivate_date, duration_one)
                          reactivate_date_incremented = Ecto.Date.cast!(reactivate_date)
                          add_error(changeset, :cancel_date, "cancellation date should be in range of above reactivate2 date(#{reactivate_date_incremented}) and below expiry date(#{decremented})")
                        else
                          suspend_date = member.suspend_date
                          duration_one = TD.from_days(1)
                          suspend_date = Timex.add(suspend_date, duration_one)
                          suspend_date_incremented = Ecto.Date.cast!(suspend_date)
                          add_error(changeset, :cancel_date, "cancellation date should be in range of above suspend2 date(#{suspend_date_incremented}) and below expiry date(#{decremented})")
                        end
                      not is_nil(member.reactivate_date) ->
                        reactivate_date = member.reactivate_date
                        duration_one = TD.from_days(1)
                        reactivate_date = Timex.add(reactivate_date, duration_one)
                        reactivate_date_incremented = Ecto.Date.cast!(reactivate_date)
                        add_error(changeset, :cancel_date, "cancellation date should be in range of above reactivate2 date(#{reactivate_date_incremented}) and below expiry date(#{decremented})")
                      not is_nil(member.suspend_date) ->
                        suspend_date = member.suspend_date
                        duration_one = TD.from_days(1)
                        suspend_date = Timex.add(suspend_date, duration_one)
                        suspend_date_incremented = Ecto.Date.cast!(suspend_date)
                        add_error(changeset, :cancel_date, "cancellation date should be in range of above suspend2 date(#{suspend_date_incremented}) and below expiry date(#{decremented})")
                    end

                    ### if inputted canceldate are greater than member.expiry_date
                    (
                      not is_nil(member.suspend_date) or
                      not is_nil(member.reactivate_date)
                    ) and Ecto.Date.compare(
                      changeset.changes.cancel_date,
                      member.expiry_date
                    ) == :gt ->
                      cond do
                        not is_nil(member.reactivate_date) and not is_nil(member.suspend_date) ->
                          compared_date = Ecto.Date.compare(member.reactivate_date, member.suspend_date)
                          if compared_date == :gt do
                            reactivate_date = member.reactivate_date
                            duration_one = TD.from_days(1)
                            reactivate_date = Timex.add(reactivate_date, duration_one)
                            reactivate_date_incremented = Ecto.Date.cast!(reactivate_date)
                            add_error(changeset, :cancel_date, "cancellation date should be in range of above reactivate3 date(#{reactivate_date_incremented}) and below expiry date(#{decremented})")
                          else
                            suspend_date = member.suspend_date
                            duration_one = TD.from_days(1)
                            suspend_date = Timex.add(suspend_date, duration_one)
                            suspend_date_incremented = Ecto.Date.cast!(suspend_date)
                            add_error(changeset, :cancel_date, "cancellation date should be in range of above suspend3 date(#{suspend_date_incremented}) and below expiry date(#{decremented})")
                          end
                        not is_nil(member.reactivate_date) ->
                          reactivate_date = member.reactivate_date
                          duration_one = TD.from_days(1)
                          reactivate_date = Timex.add(reactivate_date, duration_one)
                          reactivate_date_incremented = Ecto.Date.cast!(reactivate_date)
                          add_error(changeset, :cancel_date, "cancellation date should be in range of above reactivate3 date(#{reactivate_date_incremented}) and below expiry date(#{decremented})")
                        not is_nil(member.suspend_date) ->
                          suspend_date = member.suspend_date
                          duration_one = TD.from_days(1)
                          suspend_date = Timex.add(suspend_date, duration_one)
                          suspend_date_incremented = Ecto.Date.cast!(suspend_date)
                          add_error(changeset, :cancel_date, "cancellation date should be in range of above suspend3 date(#{suspend_date_incremented}) and below expiry date(#{decremented})")
                      end

                      ### if expiry date and canceldate_inputted are equal
                      (
                        not is_nil(member.suspend_date) or
                        not is_nil(member.reactivate_date)
                      ) and Ecto.Date.compare(
                        changeset.changes.cancel_date,
                        member.expiry_date
                      ) == :eq ->
                        cond do
                          not is_nil(member.reactivate_date) and not is_nil(member.suspend_date) ->
                            compared_date = Ecto.Date.compare(member.reactivate_date, member.suspend_date)
                            if compared_date == :gt do
                              reactivate_date = member.reactivate_date
                              duration_one = TD.from_days(1)
                              reactivate_date = Timex.add(reactivate_date, duration_one)
                              reactivate_date_incremented = Ecto.Date.cast!(reactivate_date)
                              add_error(changeset, :cancel_date, "cancellation date should be in range of above reactivate4 date(#{reactivate_date_incremented}) and below expiry date(#{decremented})")
                            else
                              suspend_date = member.suspend_date
                              duration_one = TD.from_days(1)
                              suspend_date = Timex.add(suspend_date, duration_one)
                              suspend_date_incremented = Ecto.Date.cast!(suspend_date)
                              add_error(changeset, :cancel_date, "cancellation date should be in range of above suspend4 date(#{suspend_date_incremented}) and below expiry date(#{decremented})")
                            end
                          not is_nil(member.reactivate_date) ->
                            reactivate_date = member.reactivate_date
                            duration_one = TD.from_days(1)
                            reactivate_date = Timex.add(reactivate_date, duration_one)
                            reactivate_date_incremented = Ecto.Date.cast!(reactivate_date)
                            add_error(changeset, :cancel_date, "cancellation date should be in range of above reactivate4 date(#{reactivate_date_incremented}) and below expiry date(#{decremented})")
                          not is_nil(member.suspend_date) ->
                            suspend_date = member.suspend_date
                            duration_one = TD.from_days(1)
                            suspend_date = Timex.add(suspend_date, duration_one)
                            suspend_date_incremented = Ecto.Date.cast!(suspend_date)
                            add_error(changeset, :cancel_date, "cancellation date should be in range of above suspend4 date(#{suspend_date_incremented}) and below expiry date(#{decremented})")
                        end

                        ### already checked , check first
                        not is_nil(member.cancel_date) == true ->
                          add_error(changeset, :cancel_date, "cancel date already been set!")

                          ### already checked
                          Ecto.Date.compare(casted_cancel_date, member.expiry_date) == :eq ->
                            add_error(changeset, :cancel_date, "cancellation date should be in range of date tomorrow(#{incremented}) up to below expiry date(#{decremented })")

                            ### already checked
                            Ecto.Date.compare(casted_cancel_date, member.expiry_date) == :gt ->
                              add_error(changeset, :cancel_date, "cancellation date should be in range of date tomorrow(#{incremented}) up to below expiry date(#{decremented })")

                              ### already checked
                              cancel_date == :eq or cancel_date == :lt ->
                                add_error(changeset, :cancel_date, "cancelltaion date should be in range of date tomorrow(#{incremented}) up to below expiry date(#{decremented })")

                                true ->
                                  changeset
        end
        else
        changeset
      end

      else
      _ ->
        changeset
    end
  end

  def card_no_checker do
    Member
    |> select([m], m.card_no)
    |> Repo.all()
  end

  def get_member_by_id(id) do
    Member
    |> where([m], m.id == ^id)
    |> Repo.one()
    |> Repo.preload([
      :acu_schedule_members,
      :principal,
      :created_by,
      :updated_by,
      dependents: :skipped_dependents,
      products: {from(mp in MemberProduct, order_by: mp.tier), [
        :member,
        account_product: [
          product: [
            [
              product_exclusions: [
                exclusion: [
                  :exclusion_durations,
                  exclusion_procedures: :procedure,
                  exclusion_diseases: :disease
                ]
              ]
            ],
            [
              product_benefits: [
                [product: [product_coverages: :coverage]],
                :product_benefit_limits,
                benefit: [
                  benefit_ruvs: :ruv,
                  benefit_diagnoses: :diagnosis,
                  benefit_coverages: :coverage,
                  benefit_packages: [package: [package_payor_procedure: [payor_procedure: :procedure], package_facility: :facility]],
                  benefit_procedures: :procedure
                ]
              ]
            ],
            product_coverages: [
              :product_coverage_facilities,
              :coverage,
              [
                product_coverage_risk_share: [
                  product_coverage_risk_share_facilities: [
                    product_coverage_risk_share_facility_payor_procedures: :facility_payor_procedure
                  ]
                ]
              ]
            ]
          ]
        ]
      ]},
      account_group: [
        :payment_account,
        account: [
          account_products: [
            product: :product_benefits
          ]
        ]
      ],
      member_contacts: [contact: [:phones, :emails]],
    ])
  end

  def get_member_by_card_number(card_no) do
    Member
    |> where([m], m.card_no == ^card_no)
    |> Repo.one()
    |> Repo.preload([
      :acu_schedule_members,
      :principal,
      :created_by,
      :updated_by,
      dependents: :skipped_dependents,
      products: {from(mp in MemberProduct, order_by: mp.tier), [
        :member,
        account_product: [
          product: [
            [
              product_exclusions: [
                exclusion: [
                  :exclusion_durations,
                  exclusion_procedures: :procedure,
                  exclusion_diseases: :disease
                ]
              ]
            ],
            [
              product_benefits: [
                [product: [product_coverages: :coverage]],
                :product_benefit_limits,
                benefit: [
                  benefit_ruvs: :ruv,
                  benefit_diagnoses: :diagnosis,
                  benefit_coverages: :coverage,
                  benefit_packages: [package: [package_payor_procedure: [payor_procedure: :procedure], package_facility: :facility]],
                  benefit_procedures: :procedure
                ]
              ]
            ],
            product_coverages: [
              :product_coverage_facilities,
              :coverage,
              [
                product_coverage_risk_share: [
                  product_coverage_risk_share_facilities: [
                    product_coverage_risk_share_facility_payor_procedures: :facility_payor_procedure
                  ]
                ]
              ]
            ]
          ]
        ]
      ]},
      account_group: [
        :payment_account,
        account: [
          account_products: [
            product: :product_benefits
          ]
        ]
      ],
      member_contacts: [contact: [:phones, :emails]],
    ])
  end

  def get_member_by_card_num(card_no) do
    Member
    |> where([m], m.card_no == ^card_no)
    |> Repo.one()
    |> Repo.preload(:dependents)
  end

  #################################### member movement suspension #######################################

  def validate_member_suspension(user, params) do
    with {:ok, changeset} <- validate_member_suspension_changeset(params),
         {:ok, member} <- suspend_member(user, changeset.changes)
    do
      {:ok, member}
    else
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp suspend_member(_user, params) do
    member = get_member_by_card_number(params.card_no)

    case member |> Member.changeset_suspend(params) |> Repo.update() do
      {:ok, member} ->
        {:ok, member}
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp validate_member_suspension_changeset(params) do

    data = %{}
    member_suspension_types = %{
      card_no: :string,
      suspend_date: Ecto.Date,
      suspend_reason: :string,
      suspend_remarks: :string
    }
    changeset =
      {data, member_suspension_types}
      |> cast(params, Map.keys(member_suspension_types))
      |> validate_required([
        :card_no,
        :suspend_date,
        :suspend_reason
      ])
      |> validate_inclusion(:card_no, card_no_checker(), message: "card no. not existing")
    changeset =
      if Map.has_key?(changeset.changes, :card_no) do
        changeset =
          changeset
          |> validate_member_status_for_suspend()
          if changeset.valid? do
            _changeset =
              changeset
              |> validate_suspend_date()
          else
            changeset
          end
      else
        changeset
      end
      if changeset.valid? do
        {:ok, changeset}
      else
        {:error, changeset}
      end
  end

  defp validate_member_status_for_suspend(changeset) do
    if member = get_member_by_card_number(changeset.changes.card_no) do
      if member.status == "Active" do
        changeset
      else
        add_error(changeset, :card_no, "Member should suspend only if status is Active")
      end
    else
      changeset
    end
  end

  defp validate_suspend_date(changeset) do
    with true <- Map.has_key?(changeset.changes, :suspend_date),
         {:ok, suspend_date} <- Ecto.Date.cast(changeset.changes.suspend_date)
    do
      casted_suspend_date = suspend_date
      suspend_date =
        suspend_date
        |> Ecto.Date.compare(Ecto.Date.utc)

      if member = get_member_by_card_number(changeset.changes.card_no) do

        ## for tom day
        today = Ecto.Date.utc()
        duration_one = TD.from_days(1)
        tomorrow = Timex.add(today, duration_one)
        incremented = Ecto.Date.cast!(tomorrow)

        ## for decrementing of expiry_date.day
        expiry_date = member.expiry_date
        duration_one = TD.from_days(1)
        expiry_date = Timex.subtract(expiry_date, duration_one)
        decremented = Ecto.Date.cast!(expiry_date)

        cond do
          not is_nil(member.cancel_date) == true and
          not is_nil(member.suspend_date) == true and
          not is_nil(member.suspend_reason) == true and
          not is_nil(member.cancel_reason) == true ->
            add_error(changeset, :dates, "cancel date and suspension date already been set!")

            ### if member.cancel_date == tomorrow
          not is_nil(member.cancel_date) and member.cancel_date == incremented ->
            add_error(changeset, :suspend_date, "unable to insert suspend date because tomorrow is the date of cancellation")

            ### if member.cancel_date is existing and suspend_date == date_today or less than
          not is_nil(member.cancel_date) and (suspend_date == :eq or suspend_date == :lt) ->
            cancel_date = member.cancel_date
            duration_one = TD.from_days(1)
            decremented_cancel_date = Timex.subtract(cancel_date, duration_one)
            cancel_date_decremented = Ecto.Date.cast!(decremented_cancel_date)
            add_error(changeset, :suspend_date, "suspension date should be in range of date tomorrow(#{incremented}) up to below cancel1 date(#{cancel_date_decremented})")

            ###  if inputted suspend_date > member.cancel_date
            not is_nil(member.cancel_date) and
            Ecto.Date.compare(
              changeset.changes.suspend_date,
              member.cancel_date
            ) == :gt ->
              cancel_date = member.cancel_date
              duration_one = TD.from_days(1)
              decremented_cancel_date = Timex.subtract(cancel_date, duration_one)
              cancel_date_decremented = Ecto.Date.cast!(decremented_cancel_date)
              add_error(changeset, :suspend_date, "suspension date should be in range of date tomorrow(#{incremented}) up to below cancel2 date(#{cancel_date_decremented })")

              ### if inputted suspend_date == member.cancel_date
              not is_nil(member.cancel_date) and
              Ecto.Date.compare(
                changeset.changes.suspend_date,
                member.cancel_date
              ) == :eq ->
                cancel_date = member.cancel_date
                duration_one = TD.from_days(1)
                decremented_cancel_date = Timex.subtract(cancel_date, duration_one)
                cancel_date_decremented = Ecto.Date.cast!(decremented_cancel_date)
                add_error(changeset, :suspend_date, "suspension date should be in range of date tomorrow(#{incremented}) up to below cancel3 date(#{cancel_date_decremented })")

                ### already checked
                not is_nil(member.suspend_date) == true ->
                  add_error(changeset, :suspend_date, "suspension date already been set!")

                  ### if inputted suspend_date == member.expiry_Date
                  Ecto.Date.compare(casted_suspend_date, member.expiry_date) == :eq ->
                    add_error(changeset, :suspend_date, "suspension date should be in range of date tomorrow(#{incremented}) up to below expiry date (#{decremented })")

                    ### if inputted suspend_date is > member.expiry_date
                    Ecto.Date.compare(casted_suspend_date, member.expiry_date) == :gt ->
                      add_error(changeset, :suspend_date, "suspension date should be in range of date tomorrow(#{incremented}) up to below expiry date (#{decremented })")

                      ### if today or below
                      suspend_date == :eq or suspend_date == :lt ->
                        add_error(changeset, :suspend_date, "suspension date should be in range of date tomorrow(#{incremented}) up to below expiry date(#{decremented })")

                        true ->
                          changeset
        end
    else
    changeset
      end

      else
      _ ->
        changeset
    end
  end

  defp if_cancel_already_been_set(changeset) do
    member = get_member_by_card_number(changeset.changes.card_no)
    today = Ecto.Date.utc()
    if not is_nil(member.cancel_date) do
      if changeset.changes.suspend_date > member.cancel_date do
        add_error(changeset, :suspend_date, "suspension date should be greater than today(#{today}) up to cancel date(#{member.cancel_date})")
      else
        changeset
      end
    else
      changeset
    end

  end

  defp if_suspend_already_been_set(changeset) do
    member = get_member_by_card_number(changeset.changes.card_no)
    today = Ecto.Date.utc()
    if not is_nil(member.suspend_date) do
      if changeset.changes.cancel_date < member.suspend_date do
        add_error(changeset, :cancel_date, "cancel date should be greater than suspend date(#{member.suspend_date}) up to expiry date(#{member.expiry_date})")
      else
        changeset
      end
    else
      changeset
    end

  end

  def get_all_member_facility(member_id) do
    facilities = FacilityContext.get_facility_by_member_id(member_id)
    if Enum.empty?(facilities) do
      []
    else
      {facility_codes, _} =
        facilities
        |> Enum.map_reduce("name", fn(code_n_name, key) ->
          {code_n_name
          |> Map.delete(key)
          |> Map.values, key}
        end)
        Enum.concat(facility_codes)
    end
  end

  def validate_loa_facility_fields(params) do
    data_types = %{
      card_number: :string,
      facility_code: :string
    }
    changeset =
      {%{}, data_types}
      |> cast(params, Map.keys(data_types))
      |> validate_required([
        :card_number,
        :facility_code
      ], message: "is required")

    if changeset.valid? do
      {:ok}
    else
      changeset_errors =
        changeset.errors
        |> Enum.into(
          [],
          fn{field, {_, validation}} ->
            if validation |> Keyword.get(:validation) == :required do
              field_name =
                field
                |> Atom.to_string
                |> String.replace("_", " ")

                {field, {"Please enter #{field_name}", [validation: :required]}}
            end
          end
        )

        changeset =
          changeset
          |> Map.put(:errors, changeset_errors)

          {:error, changeset}
    end

  end

  def validate_reactivate(params) do
    with {:ok} <- validate_reactivate_fields(params),
         %Member{} = member <- get_member_by_card_number(params["card_number"]),
         true <- member.status == "Suspended",
         true <- validate_reactivation_date(params),
         {:ok, member} <- reactivate(member, params)
    do
      {:ok, MemberContext.get_member(member.id)}
    end
  end

  def validate_reactivation_date(params) do
    with true <- Map.has_key?(params, "card_number"),
         true <- Map.has_key?(params, "reactivate_date")
    do
      member = get_member_by_card_no(params["card_number"])
      cancellation_date = member.cancel_date
      expiry_date = member.expiry_date
      effectivity_date = member.effectivity_date

      if expiry_date != nil do
        if validate_date(params["reactivate_date"]) == true do
          reactivation_date = Ecto.Date.cast!(params["reactivate_date"])
          current_date =
            Date.utc_today
            |> Date.to_string
            |> Ecto.Date.cast!

            with true <- validate_reactivate_cancellation_date(reactivation_date, cancellation_date),
                 true <- validate_reactivate_expiry_date(reactivation_date, expiry_date),
                 true <- validate_reactivate_effectivity_date(reactivation_date, effectivity_date),
                 true <- validate_reactivate_current_date(reactivation_date, current_date)
            do
              true
            end
        end
      else
        {:no_expiry_date}
      end

    else
      _ ->
        true
    end
  end

  defp validate_reactivate_cancellation_date(rd, cd) do
    if is_nil(cd) do
      true
    else
      case Ecto.Date.compare(rd, cd) do
        :gt ->
          {:cancellation_gt, cd}
        :eq ->
          {:cancellation_eq, cd}
        :lt ->
          true
      end
    end
  end

  defp validate_reactivate_current_date(rd, cd) do
    case Ecto.Date.compare(rd, cd) do
      :gt ->
        true
      :eq ->
        {:current_eq, cd}
      :lt ->
        {:current_prior, cd}
    end
  end

  defp validate_reactivate_expiry_date(rd, ed) do
    case Ecto.Date.compare(rd, ed) do
      :gt ->
        {:expiry_gt, ed}
      :eq ->
        {:expiry_eq, ed}
      :lt ->
        true
    end
  end

  defp validate_reactivate_effectivity_date(rd, ed) do
    case Ecto.Date.compare(rd, ed) do
      :gt ->
        true
      :eq ->
        {:effectivity_prior, rd}
      :lt ->
        {:effectivity_lt, ed}
    end
  end

  defp validate_date(date) do
    date_array = String.split(date, "-")

    with true <- String.length(Enum.at(date_array, 0)) == 4,
         true <- String.length(Enum.at(date_array, 1)) == 2,
         true <- String.length(Enum.at(date_array, 2)) == 2,
         true <- validate_number(Enum.at(date_array, 0)),
         true <- validate_number(Enum.at(date_array, 1)),
         true <- validate_number(Enum.at(date_array, 2)),
         true <- String.to_integer(Enum.at(date_array, 1)) <= 12,
         true <- String.to_integer(Enum.at(date_array, 2)) <= 31
    do
      true
    else
      false ->
        {:invalid_date}
    end
  end

  defp validate_number(string) do
    Regex.match?(~r/^[0-9]*$/, string)
  end

  def validate_reactivate_fields(params) do
    data_types = %{
      card_number: :string,
      reactivate_date: Ecto.Date,
      reactivate_reason: :string,
      reactivate_remarks: :string
    }
    changeset =
      {%{}, data_types}
      |> cast(params, Map.keys(data_types))
      |> validate_required([
        :card_number,
        :reactivate_date,
        :reactivate_remarks,
        :reactivate_reason
      ], message: "is required")

    if changeset.valid? do
      {:ok}
    else
      {:error, changeset}
    end
  end

  def mobile_prefix do
    [
      "905", "906", "907", "908",
      "909", "910", "912", "915",
      "916", "917", "918", "919",
      "920", "921", "922", "923",
      "926", "927", "928", "929",
      "930", "932", "933", "935",
      "936", "937", "938", "939",
      "942", "943", "947", "948",
      "949", "973", "974", "979",
      "989", "996", "997", "999",
      "977", "978", "945", "955",
      "956", "994", "976", "975",
      "995", "817", "940", "946",
      "950", "992", "813", "911",
      "913", "914", "981", "998",
      "951", "970", "934", "941",
      "944", "925", "924", "931"
    ]
  end

  def reactivate(member, params) do
    Repo.update(Member.changeset_reactivate(member, params))
  end

  def preload(member) do
    member
    |> Repo.preload([
      account_group: [
        account: from(a in Account, where: a.status == "Active")
      ]
    ])
    |> Repo.preload([
      :files,
      :user,
      :created_by,
      :updated_by,
      :emergency_hospital,
      :principal,
      dependents: :skipped_dependents,
      products: [
        account_product: [
          product: [
            product_benefits: [
              benefit: :benefit_diagnoses
            ],
            product_coverages: [
              :coverage,
              [product_coverage_risk_share:
               :product_coverage_risk_share_facilities]
            ]
          ]
        ]
      ],
      account_group: [
        :payment_account,
        account: [
          account_products: [
            product: :product_benefits
          ]
        ]
      ],
      member_contacts: [contact: [:phones, :emails]],
    ])
  end

  def validate_mobile_no(nil, mobile_no), do: {:invalid_id}
  def validate_mobile_no(member_id, nil), do: {:empty_mobile}
  def validate_mobile_no(nil, nil), do: {:empty_fields}

  def validate_mobile_no(member_id, mobile_no) do
    with {true, member_id} <- valid_uuid?(member_id),
         member = %Member{} <- get_member(member_id),
         {:not_same} <- same_mobile_no(member, mobile_no),
         {:not_taken} <- check_if_already_taken(mobile_no, member),
         {:ok, member} <- update_mobile_no(member, mobile_no)
    do
      {:updated, MemberContext.get_member!(member.id)}
    end
  end

  def valid_uuid?(id) do
    case UUID.cast(id) do
      {:ok, id} ->
        {true, id}
      :error ->
        {:invalid_id}
    end
  end

  def get_member(id), do: Repo.get(Member, id)

  def same_mobile_no(member, mobile_no) do
    if member.mobile == mobile_no || member.mobile2 == mobile_no do
      {:same}
    else
      {:not_same}
    end
  end

  def check_if_already_taken(mobile_no, member) do
    case String.downcase("#{member.type}") do
      "dependent" ->
        mobile_nos = get_all_mobile_no(member.principal_id)
        existing_no(mobile_nos, mobile_no)
      _ ->
        mobile_nos = get_all_mobile_no()
        existing_no(mobile_nos, mobile_no)
    end
  end

  def existing_no(mobile_nos, mobile_no) do
    if Enum.member?(mobile_nos, mobile_no) do
      {:already_taken}
    else
      {:not_taken}
    end
  end

  def get_all_mobile_no do
    Member
    |> select([m], [m.mobile, m.mobile2])
    |> Repo.all()
    |> Enum.concat()
    |> Enum.reject(&(is_nil(&1)))
  end

  def get_all_mobile_no(member_id) do
    Member
    |> Repo.all()
    |> Enum.reject(&(&1.id == member_id or &1.principal_id == member_id))
    |> Enum.into([], &[&1.mobile, &1.mobile2])
    |> Enum.concat()
    |> Enum.reject(&(is_nil(&1)))
  end

  def update_mobile_no(member, mobile_no) do
    Repo.update(Changeset.change member, mobile: mobile_no)
  end

  def create_existing_member(params) do
    with {:ok, changeset} <- validate_member_existing_fields(params),
         {:ok, member} <- insert_member_existing(changeset),
         {:ok} <- insert_member_products(changeset, member.id),
         %Member{} = member <- MemberContext.get_member(member.id)
    do
      {:ok, member}
    else
      {:changeset_error, changeset} ->
        {:error, UtilityContext.changeset_errors_to_string(changeset.errors)}
      _ ->
        {:error, "Not found"}
    end
  end

  def create_existing_member_v2(params) do
    with {:ok, changeset} <- validate_member_existing_fields_v2(params),
         {:ok, member} <- insert_member_existing(changeset),
         {:ok} <- insert_member_products(changeset, member.id),
         %Member{} = member <- MemberContext.get_member(member.id)
    do
      {:ok, member}
    else
      {:changeset_error, changeset} ->
        {:error, UtilityContext.changeset_errors_to_string(changeset.errors)}
      {:error, changeset} ->
        {:error, UtilityContext.changeset_errors_to_string(changeset.errors)}
      _ ->
        {:error, "Not found"}
    end
  end

  def validate_member_existing_fields_v2(params) do
    general_types = %{
      account_code: :string,
      type: :string,
      principal_id: :binary_id,
      relationship: :string,
      effectivity_date: Ecto.Date,
      expiry_date: Ecto.Date,
      first_name: :string,
      middle_name: :string,
      last_name: :string,
      suffix: :string,
      gender: :string,
      civil_status: :string,
      birthdate: Ecto.Date,
      employee_no: :string,
      date_hired: Ecto.Date,
      regularization_date: Ecto.Date,
      is_regular: :boolean,
      tin: :string,
      philhealth: :string,
      philhealth_type: :string,
      for_card_issuance: :boolean,
      products: {:array, :string},
      email: :string,
      email2: :string,
      mcc: :string,
      mobile: :string,
      mcc2: :string,
      mobile2: :string,
      ##
      tcc: :string,
      tac: :string,
      telephone: :string,
      tlc: :string,
      ##
      fcc: :string,
      fac: :string,
      fax: :string,
      flc: :string,
      ##
      postal: :string,
      unit_no: :string,
      building_name: :string,
      street_name: :string,
      city: :string,
      province: :string,
      region: :string,
      country: :string,
      policy_no: :string,
      principal_product_code: :string,
      step: :integer,
      card_no: :string,
      status: :string,
      integration_id: :string
    }
    changeset =
      {%{}, general_types}
      |> cast(params, Map.keys(general_types))
      |> validate_required([
        :account_code
      ], message: "is required")

      validate_member_existing_changeset_v2(changeset)
  end

  def validate_member_existing_fields(params) do
    general_types = %{
      account_code: :string,
      type: :string,
      principal_id: :binary_id,
      relationship: :string,
      effectivity_date: Ecto.Date,
      expiry_date: Ecto.Date,
      first_name: :string,
      middle_name: :string,
      last_name: :string,
      suffix: :string,
      gender: :string,
      civil_status: :string,
      birthdate: Ecto.Date,
      employee_no: :string,
      date_hired: Ecto.Date,
      regularization_date: Ecto.Date,
      is_regular: :boolean,
      tin: :string,
      philhealth: :string,
      philhealth_type: :string,
      for_card_issuance: :boolean,
      products: {:array, :string},
      email: :string,
      email2: :string,
      mcc: :string,
      mobile: :string,
      mcc2: :string,
      mobile2: :string,
      ##
      tcc: :string,
      tac: :string,
      telephone: :string,
      tlc: :string,
      ##
      fcc: :string,
      fac: :string,
      fax: :string,
      flc: :string,
      ##
      postal: :string,
      unit_no: :string,
      building_name: :string,
      street_name: :string,
      city: :string,
      province: :string,
      region: :string,
      country: :string,
      policy_no: :string,
      principal_product_code: :string,
      step: :integer,
      card_no: :string,
      status: :string,
      integration_id: :string
    }
    changeset =
      {%{}, general_types}
      |> cast(params, Map.keys(general_types))
      |> validate_required([
        :card_no,
        :account_code,
        :type,
        :first_name,
        :last_name,
        :effectivity_date,
        :expiry_date,
        # :mcc,
        # :mobile,
        ## as per sir Rey: Relax validation for migration 06/13/18 3:46pm
        # :email,
        :civil_status,
        :gender,
        :birthdate,
        :for_card_issuance,
        :philhealth_type,
        :is_regular,
        :regularization_date,
      ], message: "is required")

      validate_member_existing_changeset(changeset)
  end

  defp insert_member_existing(changeset) do
    %Member{}
    |> Member.changeset_api_existing(changeset.changes)
    |> Repo.insert()
  end

  def get_member_status(card_no) do
    Member
    |> select([m], [m.philhealth_type])
    |> where([m], m.card_no == ^card_no)
    |> Repo.one()
  end

  def check_card_number(card_number) do
    Member
    |> where([m], m.card_no == ^card_number)
    |> Repo.one()
    |> Repo.preload([
      [
        products: {from(mp in MemberProduct, order_by: mp.tier), [
          account_product: [
            product: [
              product_benefits: [
                :product_benefit_limits,
                benefit: [
                  :benefit_limits,
                  :benefit_diagnoses
                ]
              ],
              product_exclusions: [
                exclusion: :exclusion_diseases
              ],
              product_coverages: [
                :coverage,
                [product_coverage_risk_share:
                 :product_coverage_risk_share_facilities]
              ]
            ]
          ],
          member: [
            account_group: [account: from(a in Account, where: a.status == "Active")]
          ]
        ]}
      ],
      [
        authorizations: [
          :facility,
          :special_approval,
          :room,
          :created_by,
          :authorization_amounts,
          #:authorization_diagnosis,
          authorization_practitioners: :practitioner,
          authorization_diagnosis: [:diagnosis, product_benefit: :benefit],
          coverage: [coverage_benefits: :benefit],
          authorization_procedure_diagnoses: [:diagnosis, product_benefit: :benefit],
          authorization_benefit_packages: [benefit_package: [:benefit, :package]]
        ]
      ]
    ])
  end

  def list_remaining_product_limits(member) do
    Enum.map(member.products, fn(member_product) ->
      product = member_product.account_product.product
      if product.limit_type == "ABL" do
        show_abl_product(member_product)
      else
        show_mbl_product(member_product)
      end
    end)
  end

  defp show_abl_product(member_product) do
    product = member_product.account_product.product
    %{
      product_code: product.code,
      type: product.limit_type,
      product_limit: product.limit_amount,
      utilized_annual_limit: get_used_limit_per_product(member_product.id)
    }
  end

  defp show_mbl_product(member_product) do
    product = member_product.account_product.product
    %{
      product_code: product.code,
      type: product.limit_type,
      product_limit: product.limit_amount,
      benefits: list_benefit_limits(member_product),
      icd: get_used_icds(member_product),
      utilized_annual_limit: get_used_limit_per_product(member_product.id)
    }
  end

  defp get_used_icds(member_product) do
    used_icds = get_used_icds_per_product(member_product.id)
    grouped_icds = Enum.group_by(used_icds, fn(icd) -> String.slice(icd.code, 0, 3) end)
    grouped_icds
    |> Enum.map(fn({icd_group, icds}) ->
      icd = List.first(icds)
      total_utilized =
        icds
        |> Enum.map(&(&1.payor_pays))
        |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
        %{
          icd_group: icd_group,
          icd_description: icd.group_description,
          actual_utilized: 0,
          ibnr: total_utilized
        }
    end)
  end

  defp list_benefit_limits(member_product) do
    product = member_product.account_product.product
    Enum.map(product.product_benefits, fn(product_benefit) ->
      benefit = product_benefit.benefit
      %{
        benefit_code: benefit.code,
        icd: list_used_icds(product_benefit, member_product),
        coverages: list_benefit_coverages(product_benefit, member_product)
      }
    end)
  end

  defp list_benefit_coverages(benefit, member_product) do
    active_account = List.first(member_product.member.account_group.account)
    start_date = active_account.start_date
    end_date = active_account.end_date
    Enum.map(benefit.product_benefit_limits, fn(benefit_limit) ->
      %{
        coverage: benefit_limit.coverages,
        limit_amount: display_benefit_limit(benefit_limit, member_product),
        limit_type: benefit_limit.limit_type,
        limit_classification: benefit_limit.limit_classification,
        utilized_limit: get_utilized_benefit_limit(benefit_limit, member_product, start_date, end_date)
      }
    end)
  end

  defp get_utilized_benefit_limit(benefit_limit, member_product, start_date, end_date) do
    if benefit_limit.limit_classification == "Per Transaction" do
      nil
    else
      case benefit_limit.limit_type do
        "Peso" ->
          utilized_limit_peso(benefit_limit, member_product, start_date, end_date)
        "Plan Limit Percentage" ->
          utilized_limit_peso(benefit_limit, member_product, start_date, end_date)
        "Sessions" ->
          utilized_limit_sessions(benefit_limit, member_product, start_date, end_date)
        _ ->
          0
      end
    end
  end

  defp utilized_limit_peso(benefit_limit, member_product, start_date, end_date) do
    coverages = String.split(benefit_limit.coverages, ", ")
    coverage_ids = Enum.map(coverages, &(CoverageContext.get_coverage_by_code(&1).id))
    used_icds = get_used_icds_per_benefit_coverages(
      benefit_limit.product_benefit_id,
      member_product.id,
      coverage_ids,
      start_date,
      end_date
    )
    total_utilized =
      used_icds
      |> Enum.map(&(&1.payor_pays))
      |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
  end

  defp utilized_limit_sessions(benefit_limit, member_product, start_date, end_date) do
    coverages = String.split(benefit_limit.coverages, ", ")
    coverage_ids = Enum.map(coverages, &(CoverageContext.get_coverage_by_code(&1).id))
    used_icds = get_used_icds_per_benefit_coverages(
      benefit_limit.product_benefit_id,
      member_product.id,
      coverage_ids,
      start_date,
      end_date
    )
    total_utilized =
      used_icds
      |> Enum.count()
      |> Decimal.new()
  end

  defp display_benefit_limit(benefit_limit, member_product) do
    case benefit_limit.limit_type do
      "Peso" ->
        benefit_limit.limit_amount
      "Plan Limit Percentage" ->
        product_limit = member_product.account_product.product.limit_amount
        percent = benefit_limit.limit_percentage / 100
        percent_decimal = Decimal.new(percent)
        Decimal.mult(product_limit, percent_decimal)
      "Sessions" ->
        benefit_limit.limit_session
      _ ->
        0
    end
  end

  defp list_used_icds(product_benefit, member_product) do
    used_icds = get_used_icds_per_benefit(product_benefit.id, member_product.id)
    grouped_icds = Enum.group_by(used_icds, fn(icd) -> String.slice(icd.code, 0, 3) end)
    grouped_icds
    |> Enum.map(fn({icd_group, icds}) ->
      icd = List.first(icds)
      total_utilized =
        icds
        |> Enum.map(&(&1.payor_pays))
        |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
        %{
          icd_group: icd_group,
          icd_description: icd.group_description,
          actual_utilized: 0,
          ibnr: total_utilized
        }
    end)
  end

  defp get_used_limit_per_product(member_product_id) do
    AuthorizationDiagnosis
    |> join(:inner, [apd], a in Authorization, apd.authorization_id == a.id)
    |> where(
      [apd, a],
      #a.admission_datetime >= ^effectivity_date and
      #a.admission_datetime < ^expiry_date and
      apd.member_product_id == ^member_product_id and
      a.status == "Approved" and
      is_nil(apd.payor_pay) == false
    )
    |> select([apd, a], apd.payor_pay)
    |> Repo.all()
    |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
  end

  defp get_used_icds_per_product(member_product_id) do
    AuthorizationDiagnosis
    |> join(:inner, [apd], a in Authorization, apd.authorization_id == a.id)
    |> join(:inner, [apd, a], d in Diagnosis, apd.diagnosis_id == d.id)
    |> join(:inner, [apd, a, d], pb in ProductBenefit, apd.product_benefit_id == pb.id)
    |> join(:inner, [apd, a, d, pb], b in Benefit, pb.benefit_id == b.id)
    |> where(
      [apd, a],
      apd.member_product_id == ^member_product_id and
      a.status == "Approved" and
      is_nil(apd.payor_pay) == false
    )
    |> select([apd, a, d, pb, b], %{
      code: d.code,
      group_description: d.group_description,
      payor_pays: apd.payor_pay,
      benefit_code: b.code
    })
    |> Repo.all()
  end

  defp get_used_icds_per_benefit(product_benefit_id, member_product_id) do
    AuthorizationDiagnosis
    |> join(:inner, [apd], a in Authorization, apd.authorization_id == a.id)
    |> join(:inner, [apd, a], d in Diagnosis, apd.diagnosis_id == d.id)
    |> join(:inner, [apd, a, d], pb in ProductBenefit, apd.product_benefit_id == pb.id)
    |> join(:inner, [apd, a, d, pb], b in Benefit, pb.benefit_id == b.id)
    |> where(
      [apd, a],
      apd.member_product_id == ^member_product_id and
      apd.product_benefit_id == ^product_benefit_id and
      a.status == "Approved" and
      is_nil(apd.payor_pay) == false
    )
    |> select([apd, a, d, pb, b], %{
      code: d.code,
      group_description: d.group_description,
      payor_pays: apd.payor_pay,
      benefit_code: b.code
    })
    |> Repo.all()
  end

  defp get_used_icds_per_benefit_coverages(product_benefit_id, member_product_id, coverage_ids, start_date, end_date) do
    start_date = Ecto.DateTime.from_date(start_date)
    end_date = Ecto.DateTime.from_date(end_date)
    AuthorizationDiagnosis
    |> join(:inner, [apd], a in Authorization, apd.authorization_id == a.id)
    |> join(:inner, [apd, a], d in Diagnosis, apd.diagnosis_id == d.id)
    |> join(:inner, [apd, a, d], pb in ProductBenefit, apd.product_benefit_id == pb.id)
    |> join(:inner, [apd, a, d, pb], b in Benefit, pb.benefit_id == b.id)
    |> where(
      [apd, a],
      a.admission_datetime >= ^start_date and
      a.admission_datetime < ^end_date and
      apd.member_product_id == ^member_product_id and
      apd.product_benefit_id == ^product_benefit_id and
      a.coverage_id in ^coverage_ids and
      a.status == "Approved" and
      is_nil(apd.payor_pay) == false
    )
    |> select([apd, a, d, pb, b], %{
      code: d.code,
      group_description: d.group_description,
      payor_pays: apd.payor_pay,
      benefit_code: b.code
    })
    |> Repo.all()
  end

  def get_member_peme_by_evoucher(evoucher) do
    Peme
    |> Repo.get_by(evoucher_number: evoucher)
    |> Repo.preload([
      [package: :package_payor_procedure],
      [member: [:authorizations, products:
                [account_product:
                 [product: [product_benefits:
                            [benefit: [benefit_packages:
                                       [package: :package_payor_procedure]]]]]]]]
    ])
  end

  def update_peme_member(member, params) do
    member
    |> Member.changeset_peme_member(params)
    |> Repo.update()
  end

  def update_approved_peme(member) do
    member.peme_members.peme
    |> Ecto.Changeset.change(%{status: "Approved"})
    |> Repo.update

    member.peme_members
    |> Ecto.Changeset.change(%{approved_datetime: Ecto.DateTime.utc(), status: "Approved"})
    |> Repo.update
  end

  # add product api
  def validate_insert_product(params) do
    with {:ok, changeset} <- validate_general_product(params),
         {:ok, member} <- validate_member(changeset),
         {:ok, member} <- validate_member_products(changeset, member) do
           member =
             member
             |> Map.put(:product_codes, changeset.changes.product_codes)
    else
      {:error, changeset} ->
        Map.put(changeset.changes, :errors, UtilityContext.changeset_errors_to_string2(changeset.errors))
         end
  end

  def validate_general_product(params) do
    data = %{}
    general_types = %{
      card_number: :string,
      product_codes: {:array, :string}
    }
    changeset =
      {data, general_types}
      |> Changeset.cast(params, Map.keys(general_types))
      |> Changeset.validate_required([
        :card_number,
        :product_codes
      ])
    if changeset.valid? do
      {:ok, changeset}
    else
      {:error, changeset}
    end
  end

  defp validate_member(changeset) do
    member = MemberContext.get_member_by_card_no(changeset.changes.card_number)
    if is_nil(member) do
      changeset =
        add_error(changeset, :card_number, "#{changeset.changes.card_number} does not exist")
        {:error, changeset}
    else
      {:ok, member}
    end
  end

  defp validate_member_products(changeset, member) do
    product_ids = Enum.map(changeset.changes.product_codes,
                           &(AccountContext.get_product_by_code(&1)))
    products = for {product_id, tier} <- Enum.with_index(product_ids) do
      cond do
        is_nil(product_id) ->
          "#{Enum.at(changeset.changes.product_codes, tier)} not found! "
        not Enum.member?(Enum.map(Enum.at(member.account_group.account, 0).account_products, fn(x) -> x.product.code end), ProductContext.get_product(product_id).code) ->
          "#{Enum.at(changeset.changes.product_codes, tier)} is not at member's account_product! "
        Enum.member?(Enum.map(member.products, fn(x) -> x.account_product.product.code end), ProductContext.get_product(product_id).code) ->
          "#{Enum.at(changeset.changes.product_codes, tier)} is already member's plan! "
        true ->
          {:ok}
      end
    end

    products =
      products
      |> Enum.uniq()
      |> List.delete({:ok})

    if Enum.empty?(products) do
      changeset
    else
      changeset =
        add_error(changeset, :Product_code, "#{products}")
    end

    if changeset.valid? do
      {:ok, member}
    else
      {:error, changeset}
    end
  end

  def insert_member_products2(params) do
    with {:ok, changeset} <- validate_general_product(params),
         {:ok, member} <- validate_member(changeset) do
           product_ids = Enum.map(changeset.changes.product_codes,
                                  &(AccountContext.get_product_by_code(&1)))
                                                       products = for {product_id, tier} <- Enum.with_index(product_ids) do
                                                         account_product_id = Enum.at(ProductContext.get_product(product_id).account_products, 0).id
                                                                                                                           %MemberProduct{}
                                                                                                                           |> MemberProduct.changeset(%{member_id: member.id, account_product_id: account_product_id, tier: tier})
                                                                                                                           |> Repo.insert()
                                                       end
           else
           {:error, changeset} ->
             {:error, changeset}
         end
  end

  def get_member_by_id_and_product_id(member_id, product_id) do
    MemberProduct
    |> where([mp], mp.member_id == ^member_id and mp.account_product_id == ^product_id)
    |> Repo.one()
  end

  # remove product api
  def validate_remove_product(params) do
    with {:ok, changeset} <- validate_general_product(params),
         {:ok, member} <- validate_member(changeset),
         {:ok, member} <- validate_remove_member_products(changeset, member) do
           member =
             member
             |> Map.put(:product_codes, changeset.changes.product_codes)
    else
      {:error, changeset} ->
        Map.put(changeset.changes, :errors, UtilityContext.changeset_errors_to_string2(changeset.errors))
         end
  end

  defp validate_remove_member_products(changeset, member) do
    product_ids = Enum.map(changeset.changes.product_codes,
                           &(AccountContext.get_product_by_code(&1)))
    products = for {product_id, tier} <- Enum.with_index(product_ids) do

      cond do
        is_nil(product_id) ->
          "#{Enum.at(changeset.changes.product_codes, tier)} not found! "
        not Enum.member?(Enum.map(member.products, fn(x) -> x.account_product.product.code end), ProductContext.get_product(product_id).code) ->
          "#{Enum.at(changeset.changes.product_codes, tier)} is not at list of member's product! "
        not Enum.empty?(Enum.at(Enum.at(ProductContext.get_product(product_id).account_products, 0).member_products, 0).authorization_procedure_diagnoses) ->
          "#{Enum.at(changeset.changes.product_codes, tier)} is already used in authorization! "
        not Enum.empty?(Enum.at(Enum.at(ProductContext.get_product(product_id).account_products, 0).member_products, 0).authorization_diagnosis) ->
          "#{Enum.at(changeset.changes.product_codes, tier)} is already used in authorization! "
        true ->
          {:ok}
      end
    end

    products =
      products
      |> Enum.uniq()
      |> List.delete({:ok})

    if Enum.empty?(products) do
      changeset
    else
      changeset =
        add_error(changeset, :Product_code, "#{products}")
    end

    if changeset.valid? do
      {:ok, member}
    else
      {:error, changeset}
    end
  end

  def remove_member_products(params) do
    with {:ok, changeset} <- validate_general_product(params),
         {:ok, member} <- validate_member(changeset) do
           product_ids = Enum.map(changeset.changes.product_codes,
           &(AccountContext.get_product_by_code(&1)))
           products = for {product_id, tier} <- Enum.with_index(product_ids) do
           account_product_id = Enum.at(ProductContext.get_product(product_id).account_products, 0).id
           get_member_by_mid_and_pid = get_member_by_id_and_product_id(member.id, account_product_id)
           get_member_by_mid_and_pid
            |> Repo.delete()
         end
           else
           {:error, changeset} ->
             {:error, changeset}
         end
  end

  def update_status_n_date(card_number, status) do
    member = Repo.get_by(Member, card_no: card_number)
    if not is_nil(member) do
      Repo.update(Ecto.Changeset.change member, effectivity_date: Ecto.Date.utc(), status: status)
    end
  end

  def add_member_attempt(member) do
    attempts =
      if is_nil(member.attempts) do
        0
      else
        member.attempts
      end

    member
    |> Ecto.Changeset.change(%{
        attempts: attempts + 1,
        last_attempted: Ecto.DateTime.utc()
      })
    |> Repo.update()

  end

  def block_member(member) do
   attempt_expiry = Timex.add(Timex.now, Timex.Duration.from_days(1))
   attempt_expiry
    |> Ecto.DateTime.cast!
    member
    |> Ecto.Changeset.change(%{attempt_expiry: attempt_expiry})
    |> Repo.update()
  end

  def check_last_attempt(nil), do: nil
  def check_last_attempt(member) do
    member.last_attempted
    |> check_date()
    |> reset_attempt(member)
  end

  def check_date(nil), do: nil
  def check_date(datetime) do
    [d1, d2] = String.split(Ecto.DateTime.to_string(datetime), " ")
    [t1, t2, t3] = String.split(d2, ":")
    time = String.to_integer(t1) + 8
    get_date(datetime, time)
  end

  defp get_date(_, nil), do: nil
  defp get_date(datetime, time) when time >= 24 do
    dt =
      datetime
      |> Ecto.DateTime.to_erl
      |> :calendar.datetime_to_gregorian_seconds
      |> Kernel.+(86400)
      |> :calendar.gregorian_seconds_to_datetime
      |> Ecto.DateTime.from_erl

      dt
      |> Ecto.DateTime.to_date()
      |> Ecto.Date.compare(Ecto.Date.cast!(Ecto.DateTime.utc()))
  end

  defp get_date(datetime, _) do
    datetime
    |> Ecto.DateTime.to_date()
    |> Ecto.Date.compare(Ecto.Date.cast!(Ecto.DateTime.utc()))
  end

  def reset_attempt(nil, member), do: member
  def reset_attempt(:lt, member) do
    {:ok, member} =
      member
      |> Ecto.Changeset.change(%{
          last_attempted: Ecto.DateTime.utc(),
          attempts: 0
        })
      |> Repo.update()

    member
  end
  def reset_attempt(_, member), do: member

  def add_last_attempted(member) do
    member
    |> Ecto.Changeset.change(%{
        last_attempted: Ecto.DateTime.utc()
      })
    |> Repo.update()
  end

  def remove_member_attempt(member) do
    member
    |> Ecto.Changeset.change(%{attempts: 0})
    |> Repo.update()
  end

  def forced_lapsed(member) do
    status = String.downcase("#{member.status}")
    member = Repo.preload(member, [account_group: :account])
      account = List.first(member.account_group.account)
      start_date =
        account.start_date
        |> Ecto.Date.cast!()
        |> Ecto.Date.compare(Ecto.Date.cast!(member.effectivity_date))

      end_date =
        account.end_date
        |> Ecto.Date.cast!()
        |> Ecto.Date.compare(Ecto.Date.cast!(member.effectivity_date))

      if start_date == :eq || start_date == :lt && end_date == :gt || end_date == :eq && status != "cancelled" do
        Repo.update(Changeset.change member, status: "Lapsed")
      end
    # rescue
    #   _ ->
    #   Repo.update(Changeset.change member, status: member.status)
  end

  def validate_document(params) do
    with {:ok, changeset} <- validate_document_fields(params),
         {:ok, member_document} <- insert_member_document(changeset)
    do
      {:ok, member_document}
    else
      {:changeset_error, changeset} ->
        {:changeset_error, changeset}

      _ ->
        {:error, "Error"}
    end
  end

  defp validate_document_fields(params) do
    %MemberDocument{}
    |> MemberDocument.changeset(params)
    |> is_valid?()
  end
  defp is_valid?(changeset),
    do: if changeset.valid?, do: {:ok, changeset},
    else: {:changeset_error, changeset}

  defp insert_member_document(changeset) do
    changeset |> Repo.insert()
  end

  def create_with_user(params) do
    with {:ok, changeset} <- validate_member_user_fields(params),
         {:ok, member} <- insert_member_existing(changeset),
         {:ok} <- insert_member_products(changeset, member.id),
         {:ok, %User{}} <- register_member_user(member, params)
    do
      {:ok, member}
    else
      {:changeset_error, changeset} ->
        {:error, UtilityContext.changeset_errors_to_string(changeset.errors)}
      {:error, changeset} ->
        {:error, UtilityContext.changeset_errors_to_string(changeset.errors)}
      _ ->
        {:error, "Not found"}
    end
  end

  def validate_member_user_fields(params) do
    general_types = %{
      account_code: :string,
      type: :string,
      principal_id: :binary_id,
      relationship: :string,
      effectivity_date: Ecto.Date,
      expiry_date: Ecto.Date,
      first_name: :string,
      middle_name: :string,
      last_name: :string,
      suffix: :string,
      gender: :string,
      civil_status: :string,
      birthdate: Ecto.Date,
      employee_no: :string,
      date_hired: Ecto.Date,
      regularization_date: Ecto.Date,
      is_regular: :boolean,
      tin: :string,
      philhealth: :string,
      philhealth_type: :string,
      for_card_issuance: :boolean,
      products: {:array, :string},
      email: :string,
      email2: :string,
      mcc: :string,
      mobile: :string,
      mcc2: :string,
      mobile2: :string,
      ##
      tcc: :string,
      tac: :string,
      telephone: :string,
      tlc: :string,
      ##
      fcc: :string,
      fac: :string,
      fax: :string,
      flc: :string,
      ##
      postal: :string,
      unit_no: :string,
      building_name: :string,
      street_name: :string,
      city: :string,
      province: :string,
      region: :string,
      country: :string,
      policy_no: :string,
      principal_product_code: :string,
      step: :integer,
      card_no: :string,
      status: :string,
      integration_id: :string,
      username: :string,
      password: :string
    }
    changeset =
      {%{}, general_types}
      |> cast(params, Map.keys(general_types))
      |> validate_required([
        :account_code,
        :username,
        :password
      ], message: "is required")
      |> validate_username()

      validate_member_existing_changeset_v2(changeset)
  end

end
