defmodule RegistrationLinkWeb.BatchView do
  use RegistrationLinkWeb, :view
  alias Innerpeace.Db.Schemas.BatchAuthorization

  def assessed_amount_for_consult(%{__struct__: _} = batch_auth, consult_fee) do
    if is_nil(batch_auth) or is_nil(batch_auth.assessed_amount) do
      consult_fee
    else
      batch_auth.assessed_amount
    end
  end

  def assessed_amount_for_consult([], consult_fee), do: consult_fee
  def assessed_amount_for_consult(nil, consult_fee), do: consult_fee

  def assessed_amount_for_consult(batch_auth, consult_fee) do
    amount = List.first(batch_auth).assessed_amount
    if is_nil(amount) do
      consult_fee
    else
      amount
    end
  end

  # ACU
  def assessed_amount_for_acu(%{__struct__: _} = batch_auth, acu_fee) do
    if is_nil(batch_auth) or is_nil(batch_auth.assessed_amount) do
      acu_fee
    else
      batch_auth.assessed_amount
    end
  end

  def display_funding_arrangement(acu_product) do
    product_coverage = acu_product.product_coverages |> List.first()
    product_coverage.funding_arrangement
  end

  def assessed_amount_for_acu([], acu_fee), do: acu_fee
  def assessed_amount_for_acu(nil, acu_fee), do: acu_fee

  def assessed_amount_for_acu(batch_auth, acu_fee) do
    amount = List.first(batch_auth).assessed_amount
    if is_nil(amount) do
      acu_fee
    else
      amount
    end
  end

  def availment_date_for_acu(batch_authorizations) do
    if batch_authorizations == []do
      nil
    else
      batch_authorizations.availment_date
    end
  end

  def check_batch_authorization(batch_authorizations, authorization) do
    Enum.any?(batch_authorizations, &(&1.authorization_id == authorization.id))
  end

  def display_practitioner_name(batch) do
  	if is_nil(batch.practitioner_id) do
  		"N/A"
  	else
  		"#{batch.practitioner.first_name} #{batch.practitioner.middle_name} #{batch.practitioner.last_name}"
  	end
  end

  def display_created_by(batch) do
  	if is_nil(batch.created_by_id) do
  		"N/A"
  	else
  		batch.created_by.username
  	end
  end

  def is_disabled(status) do
    if not is_nil(status) do
      if String.downcase(status) == "submitted" || String.downcase(status) == "draft" do
        "disabled"
      else
        ""
      end
    else
      ""
    end
  end

  def actual_user(struct) do
    "#{struct.created_by.first_name} #{struct.created_by.middle_name} #{struct.created_by.last_name}"
  end

  def display_product_code(authorization) do
    test = for diagnosis <- authorization.authorization_diagnosis do
      if is_nil(diagnosis.member_product) do
        []
      else
        diagnosis.member_product.account_product.product.code
      end
    end

    test =
      test
      |> List.flatten()
      |> List.first()
  end

  def display_batch_authorization_reason(batch_authorization) do
    if is_nil(batch_authorization) or batch_authorization == [] do
      ""
    else
      batch_authorization.reason
    end
  end

  def display_batch_authorization_assessed_amount(batch_authorization) do
    if is_nil(batch_authorization) or batch_authorization == [] do
      ""
    else
      batch_authorization.assessed_amount
    end
  end

  def filter_batch_authorization_status(batch_authorizations) do
    batch_authorizations =
      batch_authorizations
      |> List.first()

  end

  def format_date(date) do
    if is_nil(date) do
      ""
    else
      date =
        date
        |> Ecto.Date.cast!()
        |> to_string()
        |> String.split("-")

      year = Enum.at(date, 0)
      month = Enum.at(date, 1)
      day = Enum.at(date, 2)

      month = case month do
        "01" ->
          "January"
        "02" ->
          "February"
        "03" ->
          "March"
        "04" ->
          "April"
        "05" ->
          "May"
        "06" ->
          "June"
        "07" ->
          "July"
        "08" ->
          "August"
        "09" ->
          "September"
        "10" ->
          "October"
        "11" ->
          "November"
        "12" ->
          "December"
      end

      "#{month} #{day}, #{year}"
    end
  end

  def check_batch_balance(batch) do
    if batch.edited_soa_amount == batch.soa_amount do
      "Balanced"
    else
      "Unbalanced"
    end
  end

  def get_batch_total_amount(batch) do
    loa_amounts = Enum.map(batch.batch_authorizations, &(&1.authorization.authorization_amounts.total_amount))
    Enum.reduce(loa_amounts, Decimal.new(0), &Decimal.add/2)
  end

  def check_count_status(batch) do
    if batch.estimate_no_of_claims == Integer.to_string(Enum.count(batch.batch_authorizations)) do
      "Complete"
    else
      "Incomplete"
    end
  end

  def display_member_name(member) do
    "#{member.first_name} #{member.middle_name} #{member.last_name}"
  end

  def loa_count_checker(batch, coverage) do
    case coverage do
      "Processed" ->
        loas = Enum.filter(batch.batch_authorizations, &(&1.authorization.coverage.code == "OPC"))
        amount = Enum.reduce(Enum.map(loas, &(&1.authorization.authorization_amounts.total_amount)), Decimal.new(0), &Decimal.add/2)
      _ ->
        loas = Enum.reject(batch.batch_authorizations, &(&1.authorization.coverage.code == "OPC"))
        amount = Enum.reduce(Enum.map(loas, &(&1.authorization.authorization_amounts.total_amount)), Decimal.new(0), &Decimal.add/2)
    end
    %{count: Enum.count(loas), amount: amount}
  end

  def get_total_actual(batch) do
    count = loa_count_checker(batch, "Processed").count + loa_count_checker(batch, "For Processing").count
    amount = Decimal.add(loa_count_checker(batch, "Processed").amount, loa_count_checker(batch, "For Processing").amount)
    %{count: count, amount: amount}
  end

  def get_variance(batch) do
    actual_count = loa_count_checker(batch, "Processed").count + loa_count_checker(batch, "For Processing").count
    variance_count = String.to_integer(batch.estimate_no_of_claims) - actual_count
    actual_amount = amount = Decimal.add(loa_count_checker(batch, "Processed").amount, loa_count_checker(batch, "For Processing").amount)
    soa_amount = Decimal.new(batch.soa_amount)
    variance_amount = Decimal.sub(soa_amount, actual_amount)
    %{count: variance_count, amount: variance_amount}
  end

  def render("loas.json", %{loas: loas}) do
    %{
      loas: render_many(loas, RegistrationLinkWeb.BatchView, "loa.json", as: :loa)
    }
  end
  def render("loa.json", %{loa: loa}) do
      %{
        number: loa.number,
        id: loa.id,
        member: Enum.join([loa.member.first_name, loa.member.middle_name, loa.member.last_name, loa.member.suffix], " "),
        card_number: loa.member.card_no,
        coverage: loa.coverage.name,
        draftadmission_datetime: loa.admission_datetime
      }
  end

  def aging_checker(status) do
    if is_nil(status) do
      "aging"
    else
      ""
    end
  end
end
