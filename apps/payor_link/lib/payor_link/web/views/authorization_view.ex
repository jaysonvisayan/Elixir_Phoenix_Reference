defmodule Innerpeace.PayorLink.Web.AuthorizationView do
  use Innerpeace.PayorLink.Web, :view

  import Ecto.{
    Query,
    Changeset
  }, warn: false

  alias Decimal

  alias Timex.Duration

  alias Innerpeace.Db.{
    Repo,
    Schemas.User,
    Base.AccountContext,
    Base.DropdownContext,
    Base.PractitionerContext,
    Base.AcuScheduleContext,
    Schemas.Product,
    Schemas.AccountProduct,
    Schemas.MemberProduct,
    Schemas.AuthorizationProcedureDiagnosis,
    Schemas.FacilityRoomRate,
    Schemas.Room,
    Schemas.AuthorizationRoom
  }

  alias Innerpeace.PayorLink.NumberToWord
  alias Ecto.Date
  alias Timex.Duration

  def select_practitioners(practitioners) do
    _practitioner_result = for practitioner <- practitioners do
      ps_result = for practitioner_specialization <- practitioner.practitioner_specializations do
        practitioner_specialization.specialization.name
      end

      specialization = Enum.join(ps_result, " - ")
      {"#{practitioner.code} | #{practitioner.first_name}
        #{practitioner.middle_name} #{practitioner.last_name}
        #{practitioner.suffix} | #{specialization}", practitioner.id}
    end
  end

  def select_ruvs(ruvs) do
    _ruv_result = for ruv <- ruvs do
      {"#{ruv.code} | #{ruv.description}" , ruv.id}
    end
  end

  # Uncomment when risk share is added
  # defp risk_share(product, facility_id) do
  #   risk_share_type = for product_coverage <- product.product_coverages do
  #     if product_coverage.coverage.code == "OPC" do
  #       rs = product_coverage.product_coverage_risk_share
  #       pcr = product_coverage.product_coverage_risk_share
  #       rs_facilities = pcr.product_coverage_risk_share_facilities
  #       if Enum.count(rs_facilities) > 0 do
  #         for rs_facility <- rs_facilities do
  #           if rs_facility.facility_id == facility_id do
  #             %{type: rs_facility.type, copayment_value: rs_facility.value_amount,
  #               coinsurance: rs_facility.value_percentage,
  #               covered_percentage: rs_facility.covered}
  #           else
  #             %{type: rs.af_type, copayment_value: rs.af_value_amount,
  #             coinsurance: rs.af_value_percentage,
  #             copayment_value_percentage: rs.af_covered_amount,
  #             coinsurance_covered_percentage: rs.af_covered_percentage}
  #           end
  #         end
  #       else
  #       %{type: rs.af_type, copayment_value: rs.af_value_amount,
  #         coinsurance: rs.af_value_percentage,
  #         copayment_value_percentage: rs.af_covered_amount,
  #         coinsurance_covered_percentage: rs.af_covered_percentage}
  #       end
  #     end
  #   end

  #   risk_share_type
  #   |> Enum.uniq()
  #   |> List.delete(nil)
  #   |> List.flatten()
  #   |> List.first()
  # end

  # defp risk_share_checker(product, facility_id, coverage_name) do
  #   risk_share_type = for product_coverage <- product.product_coverages do
  #     if product_coverage.coverage.code ==  coverage_name do
  #       rs = product_coverage.product_coverage_risk_share
  #       pcr = product_coverage.product_coverage_risk_share
  #       rs_facilities = pcr.product_coverage_risk_share_facilities
  #       if Enum.count(rs_facilities) > 0 do
  #         for rs_facility <- rs_facilities do
  #           if rs_facility.facility_id == facility_id do
  #             %{type: rs_facility.type, copayment_value: rs_facility.value_amount,
  #               coinsurance: rs_facility.value_percentage,
  #               copayment_value_percentage: rs_facility.value_percentage,
  #               covered_percentage: rs_facility.covered}
  #           else
  #             %{type: rs.af_type, copayment_value: rs.af_value_amount,
  #             coinsurance: rs.af_value_percentage,
  #             copayment_value_percentage: rs.af_covered_amount,
  #             coinsurance_covered_percentage: rs.af_covered_percentage}
  #           end
  #         end
  #       else
  #       %{type: rs.af_type, copayment_value: rs.af_value_amount,
  #         coinsurance: rs.af_value_percentage,
  #         copayment_value_percentage: rs.af_covered_amount,
  #         coinsurance_covered_percentage: rs.af_covered_percentage}
  #       end
  #     end
  #   end

  #   risk_share_type
  #   |> Enum.uniq()
  #   |> List.delete(nil)
  #   |> List.flatten()
  #   |> List.first()
  # end

  def member_full_name(member) do
    if is_nil(member.suffix) do
      if is_nil(member.middle_name) do
        "#{member.last_name}, #{member.first_name}"
      else
        "#{member.last_name}, #{member.first_name} #{member.middle_name}"
      end
    else
      if is_nil(member.middle_name) do
        "#{member.last_name} #{member.suffix}, #{member.first_name}"
      else
        "#{member.last_name} #{member.suffix}, #{member.first_name} #{member.middle_name}"
      end
    end
  end

  def map_payor_procedure(payor_procedures) do
    payors_procedure = [] ++ for payor_procedure <- payor_procedures do
      for list_payor <- payor_procedure.facility_payor_procedure_rooms do
        %{
          id: list_payor.facility_payor_procedure.payor_procedure.id,
          code: list_payor.facility_payor_procedure.payor_procedure.code,
          description: list_payor.facility_payor_procedure.payor_procedure.description,
          amount: Decimal.to_integer(list_payor.amount)
        }
      end
    end

    payors_procedure =
      payors_procedure
      |> Enum.uniq()
      |> List.delete(nil)
      |> List.flatten
  end

  def map_payor_procedures(authorization_procedures, payor_procedures) do
    payors_procedure = [] ++ for payor_procedure <- payor_procedures do
      for list_payor <- payor_procedure.facility_payor_procedure_rooms do
       list_payor.facility_payor_procedure.payor_procedure
      end
    end

    payors_procedure =
      payors_procedure
      |> Enum.uniq()
      |> List.delete(nil)
      |> List.flatten

    for map_procedure <- payors_procedure do
      {"#{map_procedure.code} | #{map_procedure.description}" , map_procedure.id}
    end
  end

  def map_practitioners(authorization_practitioner_specializations) do
    authorization_practitioner_specializations =
      authorization_practitioner_specializations
      |> Enum.uniq()
      |> List.delete(nil)
      |> List.flatten

    for map_practitioner <- authorization_practitioner_specializations do
      {"#{map_practitioner.practitioner_specialization.practitioner.first_name} #{map_practitioner.practitioner_specialization.practitioner.last_name}" , map_practitioner.practitioner_specialization.id}
    end
    |> Enum.uniq()
  end

  def map_diagnoses(authorization_diagnoses, diagnoses) do
    diagnosis_list = [] ++ for diagnosis <- diagnoses do
      {"#{diagnosis.code} | #{diagnosis.description}" , diagnosis.id}
    end

    authorization_list = [] ++ for authorization_diagnosis <- authorization_diagnoses do
      {"#{authorization_diagnosis.diagnosis.code} | #{authorization_diagnosis.diagnosis.description}" , authorization_diagnosis.diagnosis.id}
    end

    list = diagnosis_list -- authorization_list

    list =
      list
    [{"Select diagnosis", ""}] ++ list
  end

  def display_authorization_amounts(authorization, key) do
    if is_nil(authorization.authorization_amounts) do
      0
    else
      Map.get(authorization.authorization_amounts, key)
    end
  end

  def display_authorization_total_amount(authorization) do
    if is_nil(authorization.authorization_amounts) do
      0
    else
      am1 = authorization.authorization_amounts.member_covered
      am2 = authorization.authorization_amounts.payor_covered
      am3 = authorization.authorization_amounts.company_covered
      [am1, am2] |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
    end
  end

  # ACU
  def package_facility_rate(package_facilities, facility_id) do
    if Enum.count(package_facilities) > 1 do
      rate = for package_facility <- package_facilities do
        if package_facility.facility_id == facility_id do
          package_facility.rate
        end
      end

      rate =
        rate
        |> Enum.uniq()
        |> List.delete(nil)
        |> List.first()
    else
      package_facility = List.first(package_facilities)
      rate = package_facility.rate
    end
  end

  def payor_procedures(package, member) do
    age = age(member.birthdate)

    payor_procedure = for ppp <- package.package_payor_procedure do
      if (ppp.male == true and member.gender == "Male") or (ppp.female == true and member.gender == "Female") do
        if age >= ppp.age_from and age <= ppp.age_to do
          ppp.payor_procedure
        end
      end
    end

    _payor_procedure =
      payor_procedure
      |> Enum.uniq()
      |> List.delete(nil)
      |> List.flatten
  end

  def age(%Date{day: d, month: m, year: y}, as_of \\ :now) do
    do_age({y, m, d}, as_of)
  end

  def do_age(birthday, :now) do
    {today, _time} = :calendar.now_to_datetime(:erlang.now)
    calc_diff(birthday, today)
  end

  def do_age(birthday, date), do: calc_diff(birthday, date)

  def calc_diff({y1, m1, d1}, {y2, m2, d2}) when m2 > m1 or (m2 == m1 and d2 >= d1) do
    y2 - y1
  end

  def calc_diff({y1, _, _}, {y2, _, _}), do: (y2 - y1) - 1

  def load_user(user_id) do
    user =
      User
      |> Repo.get(user_id)
    user.username
  end

  def load_date(date_time) do
    date = DateTime.to_date(date_time)
    month = append_zeros(Integer.to_string(date.month))
    day = append_zeros(Integer.to_string(date.day))
    year = Integer.to_string(date.year)

    _result = month <> "/" <> day <> "/" <> year
  end

  # def display_date(date) do
  # "#{date.day}/#{date.month}/#{date.year} #{date.hour}:#{date.minute}"
  # end

  # def display_date1(date) do
  # "#{date.day}/#{date.month}/#{date.year} #{date.hour}:#{date.min}"
  # end

  def append_zeros(string) do
    _string =
      if String.length(string) == 1 do
        "0" <> string
      else
        string
      end
  end

  # Default RNB
  # def room_rate(facility_rooms, rnb) do
  #   room_rate = for facility_room_rate <- facility_rooms do
  #     if facility_room_rate.room.id == rnb.room_type do
  #       facility_room_rate.facility_room_rate
  #     end
  #   end

  #   room_rate =
  #     room_rate
  #     |> Enum.uniq()
  #     |> List.delete(nil)
  #     |> List.first()
  # end
  # End Default RNB
  # End ACU

  def get_age(date) do
    year_of_date = to_string(date)
    year_today =  Date.utc
    year_today = to_string(year_today)
    datediff1 = Timex.parse!(year_of_date, "%Y-%m-%d", :strftime)
    datediff2 = Timex.parse!(year_today, "%Y-%m-%d", :strftime)
    diff_in_years = Timex.diff(datediff2, datediff1, :years)
    diff_in_years
  end

  def format_birthdate(date) do
    date = to_string(date)
    date =
      date
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

  def format_date(date) do
    date = Date.cast!(date)
    date = to_string(date)
    date =
      date
      |> String.split("-")
    year = Enum.at(date, 0)
    month = Enum.at(date, 1)
    day = Enum.at(date, 2)

    month = case month do
      "01" ->
        "Jan"
      "02" ->
        "Feb"
      "03" ->
        "Mar"
      "04" ->
        "Apr"
      "05" ->
        "May"
      "06" ->
        "Jun"
      "07" ->
        "Jul"
      "08" ->
        "Aug"
      "09" ->
        "Sep"
      "10" ->
        "Oct"
      "11" ->
        "Nov"
      "12" ->
        "Dec"
    end

    "#{day}-#{month}-#{year}"
  end

  def format_authorization_date(date) do
    if is_nil(date) do
      ""
    else
      date |> DateTime.to_date() |> Date.to_string()
    end
  end

  def map_facility_ruvs(facility_ruvs, authorization_ruvs) do
    authorization_ruvs =
      authorization_ruvs
      |> Enum.map(&{"#{&1.facility_ruv.ruv.code} - #{&1.facility_ruv.ruv.description}", &1.facility_ruv.id})
      |> Enum.sort()
    facility_ruvs =
      facility_ruvs
      |> Enum.map(&{"#{&1.ruv.code} - #{&1.ruv.description}", &1.id})
      |> Enum.sort()
    facility_ruvs -- authorization_ruvs
  end

  def get_account_status(account_group_id) do
    active_account =
      AccountContext.get_active_account(account_group_id)

    if is_nil(active_account), do: "Inactive", else: active_account.status
  end

  # DIAGNOSIS

  def filter_philhealth_pays_with_product(authorization) do
    _haha =
      authorization.authorization_procedure_diagnoses
      |> Enum.filter(&((!is_nil(&1.philhealth_pay))))
      |> Enum.filter(&(!is_nil(&1.member_product_id)))
      |> Enum.filter(&((&1.philhealth_pay) != Decimal.new(0)))
      |> Enum.filter(&((&1.philhealth_pay) != Decimal.new(0.0)))
      |> Enum.group_by(&(&1.member_product.account_product.product.code))
  end

  def filter_philhealth_pays_without_product(authorization) do
    _haha =
      authorization.authorization_procedure_diagnoses
      |> Enum.filter(&(!is_nil(&1.philhealth_pay)))
      |> Enum.filter(&(is_nil(&1.member_product_id)))
      |> Enum.filter(&((&1.philhealth_pay) != Decimal.new(0)))
      |> Enum.filter(&((&1.philhealth_pay) != Decimal.new(0.0)))
  end

  #RUV

  def filter_ruv_philhealth_pays_with_product(authorization) do
    _haha =
      authorization.authorization_facility_ruvs
      |> Enum.filter(&(!is_nil(&1.philhealth_pay)))
      |> Enum.filter(&(!is_nil(&1.member_product_id)))
      |> Enum.filter(&((&1.philhealth_pay) != Decimal.new(0)))
      |> Enum.filter(&((&1.philhealth_pay) != Decimal.new(0.0)))
      |> Enum.group_by(&(&1.member_product.account_product.product.code))
  end

  def filter_ruv_philhealth_pays_without_product(authorization) do
    _haha =
      authorization.authorization_facility_ruvs
      |> Enum.filter(&(!is_nil(&1.philhealth_pay)))
      |> Enum.filter(&(is_nil(&1.member_product_id)))
      |> Enum.filter(&((&1.philhealth_pay) != Decimal.new(0) && (&1.member_pay) == Decimal.new(0)))
  end

  def filter_ruv_philhealth_member_pays_without_product(authorization) do
    _haha =
      authorization.authorization_facility_ruvs
      |> Enum.filter(&(!is_nil(&1.philhealth_pay)))
      |> Enum.filter(&(is_nil(&1.member_product_id)))
      |> Enum.filter(&((&1.philhealth_pay) != Decimal.new(0) && (&1.member_pay) != Decimal.new(0)))
  end

  def get_total_philpays_with_product(authorization) do
    philhealth_pay = for {_product_id, diagnosis_procedures} <- filter_philhealth_pays_with_product(authorization) do
       for _diagnosis_procedure <- diagnosis_procedures do
         hehe = Enum.group_by(diagnosis_procedures, &(&1.diagnosis.code))
         for {_diagnosis_code, diagnosis_procedure2} <- hehe do
           for diagnosis_procedure23 <- diagnosis_procedure2 do
            diagnosis_procedure23.philhealth_pay
           end
         end
       end
     end

     _philhealth_pay =
      philhealth_pay
      |> List.flatten()
      |> List.delete(nil)
      |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
  end

  def get_total_philpays_without_product(authorization) do
    philhealth_pay = for diagnosis_procedures <- filter_philhealth_pays_without_product(authorization) do
      diagnosis_procedures_list = [diagnosis_procedures]
       for _diagnosis_procedure <- diagnosis_procedures_list do
         hehe = Enum.group_by(diagnosis_procedures_list, &(&1.diagnosis.code))
         for {_diagnosis_code, diagnosis_procedure2} <- hehe do
           for diagnosis_procedure23 <- diagnosis_procedure2 do
            diagnosis_procedure23.philhealth_pay
           end
         end
       end
     end

     _philhealth_pay =
      philhealth_pay
      |> List.flatten()
      |> List.delete(nil)
      |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
  end

  def get_ruv_total_philpays_with_product(authorization) do
    philhealth_pay = for {_product_id, authorization_ruvs} <- filter_ruv_philhealth_pays_with_product(authorization) do
       for authorization_ruv <- authorization_ruvs do
          authorization_ruv.philhealth_pay
       end
     end

     _philhealth_pay =
      philhealth_pay
      |> List.flatten()
      |> List.delete(nil)
      |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
  end

  def get_ruv_total_philpays_without_product(authorization) do
    philhealth_pay = for authorization_ruvs <- filter_ruv_philhealth_pays_without_product(authorization) do
      authorization_ruvs_list = [authorization_ruvs]
       for authorization_ruv <- authorization_ruvs_list do
          authorization_ruv.philhealth_pay
       end
     end

     philhealth_pay =
      philhealth_pay
      |> List.flatten()
      |> List.delete(nil)
      |> Enum.reduce(Decimal.new(0), &Decimal.add/2)

    philhealth_pay2 = for authorization_ruvs <- filter_ruv_philhealth_member_pays_without_product(authorization) do
      authorization_ruvs_list = [authorization_ruvs]
       for authorization_ruv <- authorization_ruvs_list do
          authorization_ruv.philhealth_pay
       end
     end

     _philhealth_pay2 =
      philhealth_pay2
      |> List.flatten()
      |> List.delete(nil)
      |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
      |> Decimal.add(philhealth_pay)
  end

  # END OF PHILHEALTH RUV

  # MEMBER PAYS

  #RUV MEMBER PAYS

  def filter_ruv_member_pays_with_product(authorization) do
    _haha =
      authorization.authorization_facility_ruvs
      |> Enum.filter(&(!is_nil(&1.member_pay)))
      |> Enum.filter(&(!is_nil(&1.member_product_id)))
      |> Enum.filter(&((&1.member_pay) != Decimal.new(0)))
      |> Enum.filter(&((&1.member_pay) != Decimal.new(0.0)))
      |> Enum.group_by(&(&1.member_product.account_product.product.code))
  end

  def filter_ruv_member_pays_without_product(authorization) do
    _haha =
      authorization.authorization_facility_ruvs
      |> Enum.filter(&(!is_nil(&1.member_pay)))
      |> Enum.filter(&(is_nil(&1.member_product_id)))
      |> Enum.filter(&((&1.member_pay) != Decimal.new(0)))
      |> Enum.filter(&((&1.member_pay) != Decimal.new(0.0)))
  end

  def get_total_ruv_memberpays_by_product(authorization, product_code) do
    query = (
      from p in Product,
      join: ap in AccountProduct, on: ap.product_id == p.id,
      join: mp in MemberProduct, on: mp.account_product_id == ap.id,
      join: apd in AuthorizationProcedureDiagnosis, on: apd.member_product_id == mp.id,
      where: p.code == ^product_code,
      select: apd
    )
    member_product = Repo.all query
    apd =
      member_product
      |> List.first()

    haha =
      authorization.authorization_facility_ruvs
      |> Enum.filter(&((!is_nil(&1.member_pay))))
      |> Enum.filter(&(!is_nil(&1.member_product_id)))
      |> Enum.filter(&((&1.member_pay) != Decimal.new(0)))
      |> Enum.filter(&((&1.member_pay) != Decimal.new(0.0)))
      |> Enum.group_by(&(&1.member_product.id))

    procedures = for {_product_id, diagnosis_procedures} <- haha do
      Enum.filter(diagnosis_procedures, &(&1.member_product_id == apd.member_product_id))
    end
    member_pay = for procedure <- procedures do
      for x <- procedure do
        x.member_pay
      end
    end

    _member_pay =
      member_pay
      |> List.flatten()
      |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
  end

  #END OF RUV MEMBER PAYS

  def filter_member_pays_with_product(authorization) do
    _haha =
      authorization.authorization_procedure_diagnoses
      |> Enum.filter(&((!is_nil(&1.member_pay))))
      |> Enum.filter(&(!is_nil(&1.member_product_id)))
      |> Enum.filter(&((&1.member_pay) != Decimal.new(0)))
      |> Enum.filter(&((&1.member_pay) != Decimal.new(0.0)))
      |> Enum.group_by(&(&1.member_product.account_product.product.code))
  end

  def filter_member_pays_without_product(authorization) do
    _haha =
      authorization.authorization_procedure_diagnoses
      |> Enum.filter(&((!is_nil(&1.member_pay))))
      |> Enum.filter(&(is_nil(&1.member_product_id)))
      |> Enum.filter(&((&1.member_pay) != Decimal.new(0)))
      |> Enum.filter(&((&1.member_pay) != Decimal.new(0.0)))
  end

  def get_total_memberpays_with_product(authorization) do
    member_pay = for {_product_id, diagnosis_procedures} <- filter_member_pays_with_product(authorization) do
       for diagnosis_procedure <- diagnosis_procedures do
         diagnosis_procedure.member_pay
       end
     end

     _member_pay =
      member_pay
      |> List.flatten()
      |> List.delete(nil)
      |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
  end

  def get_total_memberpays_by_product(authorization, product_code) do
    query = (
      from p in Product,
      join: ap in AccountProduct, on: ap.product_id == p.id,
      join: mp in MemberProduct, on: mp.account_product_id == ap.id,
      join: apd in AuthorizationProcedureDiagnosis, on: apd.member_product_id == mp.id,
      where: p.code == ^product_code,
      select: apd
    )
    member_product = Repo.all query
    apd =
      member_product
      |> List.first()

    haha =
      authorization.authorization_procedure_diagnoses
      |> Enum.filter(&((!is_nil(&1.member_pay))))
      |> Enum.filter(&(!is_nil(&1.member_product_id)))
      |> Enum.filter(&((&1.member_pay) != Decimal.new(0)))
      |> Enum.filter(&((&1.member_pay) != Decimal.new(0.0)))
      |> Enum.group_by(&(&1.member_product.id))

    procedures = for {_product_id, diagnosis_procedures} <- haha do
      Enum.filter(diagnosis_procedures, &(&1.member_product_id == apd.member_product_id))
    end
    member_pay = for procedure <- procedures do
      for x <- procedure do
        x.member_pay
      end
    end

    _member_pay =
      member_pay
      |> List.flatten()
      |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
  end

  def get_total_memberpays_without_product(authorization) do
    member_pay = for diagnosis_procedures <- filter_member_pays_without_product(authorization) do
      diagnosis_procedures_list = [diagnosis_procedures]
       for diagnosis_procedure <- diagnosis_procedures_list do
         diagnosis_procedure.member_pay
       end
     end

     _member_pay =
      member_pay
      |> List.flatten()
      |> List.delete(nil)
      |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
  end

  # END OF MEMBER PAYS

  # PAYOR PAYS

  def filter_payor_pays_with_product(authorization) do
    _haha =
      authorization.authorization_procedure_diagnoses
      |> Enum.filter(&((!is_nil(&1.payor_pay))))
      |> Enum.filter(&(!is_nil(&1.member_product_id)))
      |> Enum.filter(&((&1.payor_pay) != Decimal.new(0)))
      |> Enum.filter(&((&1.payor_pay) != Decimal.new(0.0)))
      |> Enum.group_by(&(&1.member_product.account_product.product.code))
  end

  def filter_payor_pays_without_product(authorization) do
    _haha =
      authorization.authorization_procedure_diagnoses
      |> Enum.filter(&((!is_nil(&1.payor_pay))))
      |> Enum.filter(&(is_nil(&1.member_product_id)))
      |> Enum.filter(&((&1.payor_pay) != Decimal.new(0)))
      |> Enum.filter(&((&1.payor_pay) != Decimal.new(0.0)))
  end

  def get_total_payorpays_with_product(authorization) do
    payor_pay = for {_product_id, diagnosis_procedures} <- filter_payor_pays_with_product(authorization) do
       for diagnosis_procedure <- diagnosis_procedures do
         diagnosis_procedure.payor_pay
       end
     end

     _payor_pay =
      payor_pay
      |> List.flatten()
      |> List.delete(nil)
      |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
  end

  def get_total_payorpays_without_product(authorization) do
    payor_pay = for diagnosis_procedures <- filter_payor_pays_without_product(authorization) do
      diagnosis_procedures_list = [diagnosis_procedures]
       for diagnosis_procedure <- diagnosis_procedures_list do
         diagnosis_procedure.payor_pay
       end
     end

     _payor_pay =
      payor_pay
      |> List.flatten()
      |> List.delete(nil)
      |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
  end

  # def get_total_memberpays_with_product(authorization) do
  #   member_pay = for {product_id, diagnosis_procedures} <- filter_member_pays_with_product(authorization) do
  #      for diagnosis_procedure <- diagnosis_procedures do
  #        diagnosis_procedure.member_pay
  #      end
  #    end

  #    member_pay =
  #     member_pay
  #     |> List.flatten()
  #     |> List.delete(nil)
  #     |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
  # end

  def get_total_payorpays_by_product(authorization, product_code) do
    query = (
      from p in Product,
      join: ap in AccountProduct, on: ap.product_id == p.id,
      join: mp in MemberProduct, on: mp.account_product_id == ap.id,
      join: apd in AuthorizationProcedureDiagnosis, on: apd.member_product_id == mp.id,
      where: p.code == ^product_code,
      select: apd
    )
    member_product = Repo.all query
    apd =
      member_product
      |> List.first()

    haha =
      authorization.authorization_procedure_diagnoses
      |> Enum.filter(&((!is_nil(&1.payor_pay))))
      |> Enum.filter(&(!is_nil(&1.member_product_id)))
      |> Enum.filter(&((&1.payor_pay) != Decimal.new(0)))
      |> Enum.filter(&((&1.payor_pay) != Decimal.new(0.0)))
      |> Enum.group_by(&(&1.member_product.id))

    procedures = for {_product_id, diagnosis_procedures} <- haha do
      Enum.filter(diagnosis_procedures, &(&1.member_product_id == apd.member_product_id))
    end
    payor_pay = for procedure <- procedures do
      for x <- procedure do
        x.payor_pay
      end
    end

    _payor_pay =
      payor_pay
      |> List.flatten()
      |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
  end

  def filter_ruv_payor_pays_with_product(authorization) do
    _haha =
      authorization.authorization_facility_ruvs
      |> Enum.filter(&(!is_nil(&1.payor_pay)))
      |> Enum.filter(&(!is_nil(&1.member_product_id)))
      |> Enum.filter(&((&1.payor_pay) != Decimal.new(0)))
      |> Enum.filter(&((&1.payor_pay) != Decimal.new(0.0)))
      |> Enum.group_by(&(&1.member_product.account_product.product.code))
  end

  def filter_ruv_payor_pays_without_product(authorization) do
    _haha =
      authorization.authorization_facility_ruvs
      |> Enum.filter(&(!is_nil(&1.payor_pay)))
      |> Enum.filter(&(is_nil(&1.member_product_id)))
      |> Enum.filter(&((&1.payor_pay) != Decimal.new(0)))
      |> Enum.filter(&((&1.payor_pay) != Decimal.new(0.0)))
  end

  def get_total_ruv_payorpays_by_product(authorization, product_code) do
    query = (
      from p in Product,
      join: ap in AccountProduct, on: ap.product_id == p.id,
      join: mp in MemberProduct, on: mp.account_product_id == ap.id,
      join: apd in AuthorizationProcedureDiagnosis, on: apd.member_product_id == mp.id,
      where: p.code == ^product_code,
      select: apd
    )
    member_product = Repo.all query
    apd =
      member_product
      |> List.first()

    haha =
      authorization.authorization_facility_ruvs
      |> Enum.filter(&((!is_nil(&1.payor_pay))))
      |> Enum.filter(&(!is_nil(&1.member_product_id)))
      |> Enum.filter(&((&1.payor_pay) != Decimal.new(0)))
      |> Enum.filter(&((&1.payor_pay) != Decimal.new(0.0)))
      |> Enum.group_by(&(&1.member_product.id))

    procedures = for {_product_id, diagnosis_procedures} <- haha do
      Enum.filter(diagnosis_procedures, &(&1.member_product_id == apd.member_product_id))
    end
    payor_pay = for procedure <- procedures do
      for x <- procedure do
        x.payor_pay
      end
    end

    _payor_pay =
      payor_pay
      |> List.flatten()
      |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
  end

  # END OF PAYOR PAYS

  def laboratory_risk_share_checker(authorization_procedure_diagnoses) do
    type = authorization_procedure_diagnoses.risk_share_type
    unit  = Decimal.new(authorization_procedure_diagnoses.unit) || Decimal.new(0)
    procedure_fee = Decimal.mult(Decimal.new(authorization_procedure_diagnoses.amount), Decimal.new(unit))
    if type != "Copayment" and type != "CoInsurance" do
      %{
        amount: authorization_procedure_diagnoses.risk_share_amount,
        covered: Decimal.new(100),
        op_copay_val: authorization_procedure_diagnoses.member_pay,
        uncovered_after_rs: nil,
        uncovered_percentage: nil,
        type: nil,
        setup: nil,
        fee: procedure_fee,
        pec: authorization_procedure_diagnoses.pec,
        payor: authorization_procedure_diagnoses.payor_pay
      }
    else
      rsamount = Decimal.new(authorization_procedure_diagnoses.risk_share_amount) || Decimal.new(0)
      setup = authorization_procedure_diagnoses.risk_share_setup
      covered = Decimal.new(authorization_procedure_diagnoses.percentage_covered)
      pec = Decimal.new(authorization_procedure_diagnoses.pec)
      divider = Decimal.new(100)

      cond do
      type == "Copayment" ->
          if pec > Decimal.new(0) do
            outpatient_copay_val = rsamount
            uncovered = Decimal.sub(Decimal.new(100), covered)
            covered_percentage = Decimal.div(pec, divider)
            op_copay_deduction = Decimal.sub(procedure_fee, rsamount)
            payor = Decimal.mult(op_copay_deduction, covered_percentage)
            uncovered_after_rs = Decimal.sub(op_copay_deduction, payor)

            %{
              amount: rsamount,
              covered: covered,
              op_copay_val: outpatient_copay_val,
              uncovered_after_rs: uncovered_after_rs,
              uncovered_percentage: uncovered,
              type: type,
              setup: setup,
              fee: procedure_fee,
              pec: pec,
              payor: payor
            }
          else
            compare_amount = Decimal.compare(rsamount, procedure_fee)
            covered_percentage = Decimal.div(covered, divider)
          outpatient_copay_val =
            if compare_amount == Decimal.new(-1) do
              rsamount
            else
              # compare_amount == Decimal.new(1)
                Decimal.new(0)
            end
          uncovered =
            if compare_amount == Decimal.new(-1) do
                Decimal.sub(Decimal.new(100), covered)
            else
              # compare_amount == Decimal.new(1)
                Decimal.new(100)
            end
          op_copay_deduction =
            if compare_amount == Decimal.new(-1) do
              Decimal.sub(procedure_fee, rsamount)
            else
              # compare_amount == Decimal.new(1)
              authorization_procedure_diagnoses.member_pay
            end
          payor =
            if compare_amount == Decimal.new(-1) do
              Decimal.mult(op_copay_deduction, covered_percentage)
            else
              # compare_amount == Decimal.new(1)
              authorization_procedure_diagnoses.payor_pay
            end
          uncovered_after_rs =
            if compare_amount == Decimal.new(-1) do
              Decimal.sub(op_copay_deduction, payor)
            else
              # compare_amount == Decimal.new(1)
              authorization_procedure_diagnoses.member_pay
            end

            %{
              amount: rsamount,
              covered: covered,
              op_copay_val: outpatient_copay_val,
              uncovered_after_rs: uncovered_after_rs,
              uncovered_percentage: uncovered,
              type: type,
              setup: setup,
              fee: procedure_fee,
              pec: pec,
              payor: payor
            }
           end
        type == "Coinsurance" ->

        if pec > Decimal.new(0) do
          outpatient_copay_val = rsamount
          uncovered = Decimal.sub(Decimal.new(100), covered)
          covered_percentage = Decimal.div(pec, divider)
          op_copay_deduction = Decimal.sub(procedure_fee, rsamount)
          payor = Decimal.mult(op_copay_deduction, covered_percentage)
          uncovered_after_rs = Decimal.sub(op_copay_deduction, payor)

          %{
            amount: rsamount,
            covered: covered,
            op_copay_val: outpatient_copay_val,
            uncovered_after_rs: uncovered_after_rs,
            uncovered_percentage: uncovered,
            type: type,
            setup: setup,
            fee: procedure_fee,
            pec: pec,
            payor: payor
          }
        else
          compare_amount = Decimal.compare(rsamount, procedure_fee)
          covered_percentage = Decimal.div(covered, divider)
          test = Decimal.mult(procedure_fee, Decimal.div(rsamount, divider))

          uncovered =
            if compare_amount == Decimal.new(-1) do
              Decimal.sub(Decimal.new(100), covered)
            else
              # compare_amount == Decimal.new(1)
                Decimal.new(100)
            end
          op_copay_deduction =
            if compare_amount == Decimal.new(-1) do
              Decimal.sub(procedure_fee, test)
            else
              # compare_amount == Decimal.new(1)
              authorization_procedure_diagnoses.member_pay
            end
          outpatient_copay_val =
            if compare_amount == Decimal.new(-1) do
              test
            else
              # compare_amount == Decimal.new(1)
              Decimal.new(0)
            end
          payor =
            if compare_amount == Decimal.new(-1) do
              Decimal.mult(op_copay_deduction, covered_percentage)
            else
              # compare_amount == Decimal.new(1)
              authorization_procedure_diagnoses.payor_pay
            end
          result =
            if compare_amount == Decimal.new(-1) do
              nil
            else
              # compare_amount == Decimal.new(1)
                rsamount
                  |> Decimal.div(divider)
                  |> Decimal.mult(procedure_fee)
            end
          uncovered_after_rs =
          if compare_amount == Decimal.new(-1) do
            Decimal.sub(op_copay_deduction, payor)
          else
            # compare_amount == Decimal.new(1)
            Decimal.sub(authorization_procedure_diagnoses.member_pay, result)
          end

          %{
            amount: rsamount,
            covered: covered,
            op_copay_val: result,
            uncovered_after_rs: uncovered_after_rs,
            uncovered_percentage: uncovered,
            type: type,
            setup: setup,
            fee: procedure_fee,
            pec: pec,
            payor: payor
          }
         end

        type == "CoInsurance" ->

        if pec > Decimal.new(0) do
          outpatient_copay_val = rsamount
          uncovered = Decimal.sub(Decimal.new(100), covered)
          covered_percentage = Decimal.div(pec, divider)
          op_copay_deduction = Decimal.sub(procedure_fee, rsamount)
          payor = Decimal.mult(op_copay_deduction, covered_percentage)
          uncovered_after_rs = Decimal.sub(op_copay_deduction, payor)

          %{
            amount: rsamount,
            covered: covered,
            op_copay_val: outpatient_copay_val,
            uncovered_after_rs: uncovered_after_rs,
            uncovered_percentage: uncovered,
            type: type,
            setup: setup,
            fee: procedure_fee,
            pec: pec,
            payor: payor
          }
        else
          compare_amount = Decimal.compare(rsamount, procedure_fee)
          covered_percentage = Decimal.div(covered, divider)
          test = Decimal.mult(procedure_fee, Decimal.div(rsamount, divider))

          uncovered =
            if compare_amount == Decimal.new(-1) do
              Decimal.sub(Decimal.new(100), covered)
            else
              # compare_amount == Decimal.new(1)
                Decimal.new(100)
            end
          op_copay_deduction =
            if compare_amount == Decimal.new(-1) do
              Decimal.sub(procedure_fee, test)
            else
              # compare_amount == Decimal.new(1)
              authorization_procedure_diagnoses.member_pay
            end
          outpatient_copay_val =
            if compare_amount == Decimal.new(-1) do
              test
            else
              # compare_amount == Decimal.new(1)
              Decimal.new(0)
            end
          payor =
            if compare_amount == Decimal.new(-1) do
              Decimal.mult(op_copay_deduction, covered_percentage)
            else
              # compare_amount == Decimal.new(1)
              authorization_procedure_diagnoses.payor_pay
            end
          result =
            if compare_amount == Decimal.new(-1) do
              nil
            else
              # compare_amount == Decimal.new(1)
                rsamount
                  |> Decimal.div(divider)
                  |> Decimal.mult(procedure_fee)
            end
          uncovered_after_rs =
          if compare_amount == Decimal.new(-1) do
            Decimal.sub(op_copay_deduction, payor)
          else
            # compare_amount == Decimal.new(1)
            Decimal.sub(authorization_procedure_diagnoses.member_pay, result)
          end

          %{
            amount: rsamount,
            covered: covered,
            op_copay_val: result,
            uncovered_after_rs: uncovered_after_rs,
            uncovered_percentage: uncovered,
            type: type,
            setup: setup,
            fee: procedure_fee,
            pec: pec,
            payor: payor
          }
         end
        end
    end
  end

  def laboratory_risk_share_checker_ruv(authorization_ruvs, facility_id) do
    op_room =
      FacilityRoomRate
      |> join(:inner, [frr], r in Room,  frr.room_id == r.id)
      |> where([frr, r], frr.facility_id == ^facility_id and r.code == "16")
      |> Repo.one()
    ruv_fee =
      if authorization_ruvs.facility_ruv.ruv.type == "Unit" do
        Decimal.mult(authorization_ruvs.facility_ruv.ruv.value, Decimal.new(op_room.facility_room_rate))
      else
        authorization_ruvs.facility_ruv.ruv.value
      end

    type = authorization_ruvs.risk_share_type

    if type != "Copayment" and type != "CoInsurance" do
      %{
        op_copay_val: authorization_ruvs.member_pay,
        uncovered_after_rs: nil,
        uncovered_percentage: nil,
        type: nil,
        setup: nil,
        fee: ruv_fee,
        pec: authorization_ruvs.pec,
        payor: authorization_ruvs.payor_pay
      }
    else
      rsamount = Decimal.new(authorization_ruvs.risk_share_amount) || Decimal.new(0)
      setup = authorization_ruvs.risk_share_setup
      covered = Decimal.new(authorization_ruvs.percentage_covered)
      pec = Decimal.new(authorization_ruvs.pec)
      divider = Decimal.new(100)

      cond do
      type == "Copayment" ->
        if pec > Decimal.new(0) do
          outpatient_copay_val = rsamount
          uncovered = Decimal.sub(Decimal.new(100), covered)
          covered_percentage = Decimal.div(pec, divider)
          op_copay_deduction = Decimal.sub(ruv_fee, rsamount)
          payor = Decimal.mult(op_copay_deduction, covered_percentage)
          uncovered_after_rs = Decimal.sub(op_copay_deduction, payor)

          %{
            amount: rsamount, covered: covered, op_copay_val: outpatient_copay_val,
            uncovered_after_rs: uncovered_after_rs,
            uncovered_percentage: uncovered, type: type,
            setup: setup, fee: ruv_fee, pec: pec, payor: payor
          }
        else
          compare_amount = Decimal.compare(rsamount, ruv_fee)
          covered_percentage = Decimal.div(covered, divider)
          outpatient_copay_val =
            if compare_amount == Decimal.new(-1) do
              rsamount
            else
              # compare_amount == Decimal.new(1)
              Decimal.new(0)
            end
          uncovered =
            if compare_amount == Decimal.new(-1) do
              Decimal.sub(Decimal.new(100), covered)
            else
              # compare_amount == Decimal.new(1)
              Decimal.new(100)
            end
          op_copay_deduction =
            if compare_amount == Decimal.new(-1) do
              Decimal.sub(ruv_fee, rsamount)
            else
              # compare_amount == Decimal.new(1)
              authorization_ruvs.member_pay
            end
          payor =
            if compare_amount == Decimal.new(-1) do
              Decimal.mult(op_copay_deduction, covered_percentage)
            else
              # compare_amount == Decimal.new(1)
              authorization_ruvs.member_pay
            end
          uncovered_after_rs =
            if compare_amount == Decimal.new(-1) do
              Decimal.sub(op_copay_deduction, payor)
            else
              # compare_amount == Decimal.new(1)
              authorization_ruvs.member_pay
            end

            %{
              amount: rsamount,
              covered: covered,
              op_copay_val: outpatient_copay_val,
              uncovered_after_rs: uncovered_after_rs,
              uncovered_percentage: uncovered,
              type: type,
              setup: setup,
              fee: ruv_fee,
              pec: pec,
              payor: payor
            }
           end
        type == "Coinsurance" ->

        if pec > Decimal.new(0) do
          outpatient_copay_val = rsamount
          uncovered = Decimal.sub(Decimal.new(100), covered)
          covered_percentage = Decimal.div(pec, divider)
          op_copay_deduction = Decimal.sub(ruv_fee, rsamount)
          payor = Decimal.mult(op_copay_deduction, covered_percentage)
          uncovered_after_rs = Decimal.sub(op_copay_deduction, payor)

          %{
            amount: rsamount,
            covered: covered,
            op_copay_val: outpatient_copay_val,
            uncovered_after_rs: uncovered_after_rs,
            uncovered_percentage: uncovered,
            type: type,
            setup: setup,
            fee: ruv_fee,
            pec: pec,
            payor: payor
          }
        else
          compare_amount = Decimal.compare(rsamount, ruv_fee)
          covered_percentage = Decimal.div(covered, divider)
          uncovered =
            if compare_amount == Decimal.new(-1) do
              Decimal.sub(Decimal.new(100), covered)
            else
              # compare_amount == Decimal.new(1)
              Decimal.new(100)
            end
          op_copay_deduction =
            if compare_amount == Decimal.new(-1) do
              Decimal.mult(ruv_fee, Decimal.div(rsamount, divider))
            else
              # compare_amount == Decimal.new(1)
              authorization_ruvs.member_pay
            end
          payor =
            if compare_amount == Decimal.new(-1) do
              Decimal.mult(op_copay_deduction, covered_percentage)
            else
              # compare_amount == Decimal.new(1) ->
              authorization_ruvs.payor_pay
            end
          outpatient_copay_val =
            if compare_amount == Decimal.new(-1) do
              rsamount
            else
              # compare_amount == Decimal.new(1)
              Decimal.new(0)
            end
          uncovered_after_rs =
            if compare_amount == Decimal.new(-1) do
              Decimal.sub(op_copay_deduction, payor)
            else
              # compare_amount == Decimal.new(1)
              authorization_ruvs.member_pay
            end

            %{
              amount: rsamount,
              covered: covered,
              op_copay_val: outpatient_copay_val,
              uncovered_after_rs: uncovered_after_rs,
              uncovered_percentage: uncovered,
              type: type,
              setup: setup,
              fee: ruv_fee,
              pec: pec,
              payor: payor
            }
         end

        type == "CoInsurance" ->

        if pec > Decimal.new(0) do
          outpatient_copay_val = rsamount
          uncovered = Decimal.sub(Decimal.new(100), covered)
          covered_percentage = Decimal.div(pec, divider)
          op_copay_deduction = Decimal.sub(ruv_fee, rsamount)
          payor = Decimal.mult(op_copay_deduction, covered_percentage)
          uncovered_after_rs = Decimal.sub(op_copay_deduction, payor)

          %{
            amount: rsamount,
            covered: covered,
            op_copay_val: outpatient_copay_val,
            uncovered_after_rs: uncovered_after_rs,
            uncovered_percentage: uncovered,
            type: type,
            setup: setup,
            fee: ruv_fee,
            pec: pec,
            payor: payor
          }
        else
          compare_amount = Decimal.compare(rsamount, ruv_fee)
          covered_percentage = Decimal.div(covered, divider)
          uncovered =
            if compare_amount == Decimal.new(-1) do
              Decimal.sub(Decimal.new(100), covered)
            else
              # compare_amount == Decimal.new(1)
              Decimal.new(100)
            end
          op_copay_deduction =
            if compare_amount == Decimal.new(-1) do
              Decimal.mult(ruv_fee, Decimal.div(rsamount, divider))
            else
              # compare_amount == Decimal.new(1)
              authorization_ruvs.member_pay
            end
          payor =
            if compare_amount == Decimal.new(-1) do
              Decimal.mult(op_copay_deduction, covered_percentage)
            else
              # compare_amount == Decimal.new(1) ->
              authorization_ruvs.payor_pay
            end
          outpatient_copay_val =
            if compare_amount == Decimal.new(-1) do
              rsamount
            else
              # compare_amount == Decimal.new(1)
              Decimal.new(0)
            end
          uncovered_after_rs =
            if compare_amount == Decimal.new(-1) do
              Decimal.sub(op_copay_deduction, payor)
            else
              # compare_amount == Decimal.new(1)
              authorization_ruvs.member_pay
            end

            %{
              amount: rsamount,
              covered: covered,
              op_copay_val: outpatient_copay_val,
              uncovered_after_rs: uncovered_after_rs,
              uncovered_percentage: uncovered,
              type: type,
              setup: setup,
              fee: ruv_fee,
              pec: pec,
              payor: payor
            }
         end
        end
    end
  end

  def check_validity(nil), do: true
  def check_validity(valid_until), do: check_compare(Date.compare(valid_until, Date.utc()))

  defp check_compare(:gt), do: true
  defp check_compare(:eq), do: true
  defp check_compare(_), do: false

  # print
  def p_display_account_date(accounts) do
    account = [] ++ for account <- accounts do
      account
    end
    account =
      account
      |> Enum.uniq()
      |> List.first()

    "#{format_date(account.start_date)} to #{format_date(account.end_date)}"
  end

  def p_display_numbers(contacts) do
    raise contacts
    contact = [] == for contact <- contacts do
      contact
    end
    _contact =
      contact
      |> raise()
  end

  def p_display_complete_address(facility) do
    "#{facility.line_1}, #{facility.line_2}, #{facility.city},
    #{facility.province}, #{facility.region}, #{facility.country}"
  end

  def consult_valid_until(date) do
    if not is_nil(date) do
      date = Date.cast!(date)
      date = to_string(date)
      date =
        date
        |> String.split("-")
        year = Enum.at(date, 0)
        month = Enum.at(date, 1)
        day = Enum.at(date, 2)
        month = case month do
          "01" ->
            "Jan"
          "02" ->
            "Feb"
          "03" ->
            "Mar"
          "04" ->
            "Apr"
          "05" ->
            "May"
          _ ->
            consult_valid_until1(month)
        end

        "#{day}-#{month}-#{year}"
    end
  end

  def consult_valid_until1(month) do
    case month do
      "06" ->
        "Jun"
      "07" ->
        "Jul"
      "08" ->
        "Aug"
      "09" ->
        "Sep"
      "10" ->
        "Oct"
      "11" ->
        "Nov"
      "12" ->
        "Dec"
    end
  end

  def display_print_total_amount(authorization) do
    if is_nil(authorization.authorization_amounts) do
      0
    else
      am1 = authorization.authorization_amounts.member_covered
      am2 = authorization.authorization_amounts.payor_covered
      am3 = authorization.authorization_amounts.company_covered
      decimal = [am1, am2, am3] |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
      decimal = decimal |> Decimal.to_string()
        if String.contains?(decimal, ".") do
          {int, dec} = decimal |> String.split(".") |> List.to_tuple()
          int = int |> String.to_integer()
          dec = dec |> String.to_integer()
          NumberToWord.say(int) <> " pesos and " <> NumberToWord.say(dec) <> " centavos only"
        else
          decimal = decimal |> String.to_integer()
          if decimal == 0 do
            "Zero pesos only"
          else
            NumberToWord.say(decimal) <> " pesos only" |> String.capitalize()
          end
        end
      end
    end

  def display_authorization_print_amounts(authorization, key) do
    if is_nil(authorization.authorization_amounts) do
      0
    else
      decimal = Map.get(authorization.authorization_amounts, key)
      decimal = decimal |> Decimal.to_string()
      if String.contains?(decimal, ".") do
        {int, dec} = decimal |> String.split(".") |> List.to_tuple()
        int = int |> String.to_integer()
        dec = dec |> String.to_integer()
        NumberToWord.say(int) <> " pesos and " <> NumberToWord.say(dec) <> " centavos only"
      else
        decimal = decimal |> String.to_integer()
        if decimal == 0 do
          "Zero pesos only"
        else
          NumberToWord.say(decimal) <> " pesos only" |> String.capitalize()
        end
      end
    end
  end

  def format_birthdate_print(birthdate) do
    birthdate = to_string(birthdate)
    birthdate =
      birthdate
      |> String.split("-")
    year = Enum.at(birthdate, 0)
    month = Enum.at(birthdate, 1)
    day = Enum.at(birthdate, 2)

    month = case month do
      "01" ->
        "Jan"
      "02" ->
        "Feb"
      "03" ->
        "Mar"
      "04" ->
        "Apr"
      "05" ->
        "May"
      "06" ->
        "Jun"
      "07" ->
        "Jul"
      "08" ->
        "Aug"
      "09" ->
        "Sep"
      "10" ->
        "Oct"
      "11" ->
        "Nov"
      "12" ->
        "Dec"
    end

    "#{day}-#{month}-#{year}"
  end

  def convert_to_word(number) do
    number =
      if number == 0 do
        "0"
      else
        Decimal.to_string(number)
      end
    if number =~ "." do
      number =
        number
        |> String.split(".")

      first_num =
        number
        |> Enum.at(0)
        |> Decimal.new()
        |> Decimal.to_integer()
        |> NumberToWord.say()
      second_num =
        number
        |> Enum.at(1)
        |> Decimal.new()
        |> Decimal.to_integer()
      if second_num == 0 do
        String.capitalize("#{first_num} pesos only")
      else
        second_num = NumberToWord.say(second_num)
        String.capitalize("#{first_num} pesos and #{second_num} centavos only")
      end

    else

      integer = Decimal.to_integer(Decimal.new(number))
      if integer == 0 do
        "Zero pesos only"
      else
        number = integer |> NumberToWord.say()
        String.capitalize("#{number} pesos only")
      end
    end
  end

  def display_complaint_and_diagnosis(authorization) do
    diagnosis = for authorization_diagnosis <- authorization.authorization_diagnosis do
      authorization_diagnosis.diagnosis
    end
    diagnosis =
      diagnosis
      |> List.first()
    "CHIEF COMPLAINT: #{authorization.chief_complaint} / DIAGNOSIS: #{diagnosis.code} ( #{diagnosis.description} )"
  end

  def display_card_number(card_number) do
    first = String.slice(card_number, 0..3)
    second = String.slice(card_number, 4..7)
    third = String.slice(card_number, 8..11)
    fourth = String.slice(card_number, 12..15)
    "#{first}-#{second}-#{third}-#{fourth}"

  end

  #end of print

  def get_auth_ps_name(aps) do
    ps = aps.practitioner_specialization
    p = ps.practitioner

    full_name = "#{p.first_name} #{p.middle_name} #{p.last_name}"
    code = p.code
    specialization = ps.specialization.name

    "#{code} | #{full_name} | #{specialization}"
  end

  def get_member_pays(val, special_approval_amount) do
    val = if is_nil(val), do: "0", else: val
    saa = if is_nil(special_approval_amount), do: "0", else: special_approval_amount

    Decimal.add(Decimal.new(val), Decimal.new(saa))
  end

  def check_nil(val) do
    if is_nil(val), do: "0", else: val
  end

  def check_saa_state(ad, a) do
    if ad == [] do
      "hidden"
    else
      if not is_nil(List.first(ad).special_approval_amount) do
        if is_nil(a.special_approval_id) do
          "hidden"
        else
          ""
        end
      else
        "hidden"
      end
    end
  end

  def check_mpf_state2(ad) do
    if ad != [] do
     # if Decimal.to_float(List.first(ad).member_pay) != Decimal.to_float(Decimal.new(0)) do
      if not is_nil(List.first(ad).member_pay) and
         Decimal.to_float(List.first(ad).member_pay) != Decimal.to_float(Decimal.new(0))
      do
        ""
      else
        "hidden"
      end
    else
      "hidden"
    end
  end

  def check_mpf_state(ad) do
    if ad != [] do
     # if Decimal.to_float(List.first(ad).member_pay) != Decimal.to_float(Decimal.new(0)) do
      if not is_nil(List.first(ad).member_pay)
      do
        ""
      else
        "hidden"
      end
    else
      "hidden"
    end
  end

  def get_member_product(member_product_id) do
    if is_nil(member_product_id) do
      nil
    else
      MemberProduct
      |> Repo.get_by(id: member_product_id)
      |> Repo.preload([account_product: :product])
    end
  end

  def get_vat_status(authorizations) do
   aps = authorizations.authorization_practitioner_specializations |> List.first()
   if is_nil(aps) do
    nil
   else
    DropdownContext.get_dropdown(aps.practitioner_specialization.practitioner.vat_status_id).value
   end
  end

  def render("message.json", %{message: message}) do
    %{
      message: message
    }
  end

  def filter_practitioners(practitioners) do
    for p <- practitioners do
        {"#{p.code} | #{p.first_name} #{p.middle_name} #{p.last_name}", p.id}
    end
  end

  def load_specializations(practitioners) do
    ps = for p <- practitioners do
      for ps <- p.practitioner_specializations do
        ps.specialization.name
      end
    end
    ps
    |> List.flatten()
    |> Enum.uniq()
  end

  def transform_date(date) do
    {year, month, day} =
    date
    |> Ecto.Date.to_string()
    |> String.split("-")
    |> List.to_tuple()

    "#{month}/#{day}/#{year}"
  end

  def pr_fee(aps_facilities, facility_id) do
    Enum.map(aps_facilities, fn(x) ->
      if x.facility_id == facility_id do
        "sir anton"
      end
    end)
    |> List.first()
  end

  def load_facility_room(room_id, facility_id) do
    FacilityRoomRate
    |> where([frr], frr.room_id == ^room_id and frr.facility_id == ^facility_id)
    |> Repo.one()
  end

  def get_latest_authorization_room(authorization_id) do
    authorization_room =
      AuthorizationRoom
      |> where([ar], ar.authorization_id == ^authorization_id)
      |> order_by([ar], desc: ar.inserted_at)
      |> Repo.all()
    unless Enum.empty?(authorization_room) do
      authorization_room = authorization_room
                           |> List.first()
      authorization_room.id
    end
  end

  def get_package_rate_of_acu_schedule(acu_schedule_id, product_id, package_id) do
    acu_package = AcuScheduleContext.get_acu_package(acu_schedule_id, product_id, package_id)

    if is_nil(acu_package) do
      "N/A"
    else
      acu_package.rate
    end
  end

  def get_valid_until(nil), do: valid_until()
  def get_valid_until(member), do: get_valid_until_v2(member.peme)
  defp get_valid_until_v2(nil), do: valid_until()
  defp get_valid_until_v2(peme), do: get_valid_until_v3(peme.date_to)
  defp get_valid_until_v3(nil), do: valid_until()
  defp get_valid_until_v3(date_to), do: "#{date_to}"
  defp valid_until, do: Date.to_string(Date.add(Date.utc_today(), 2))

end
