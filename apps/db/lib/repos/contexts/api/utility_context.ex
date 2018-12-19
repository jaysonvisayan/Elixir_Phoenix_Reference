defmodule Innerpeace.Db.Base.Api.UtilityContext do
  @moduledoc """
  """
  alias Phoenix.HTML
  alias Innerpeace.{
    Db.Repo,
    Db.Base.ApiAddressContext
  }
 alias Innerpeace.Db.Schemas.{
    ApiAddress,
    SAPNotification,
    User
  }
  alias Ecto.UUID
  # import Cipher
  require Logger

  def valid_uuid?(id) do
    case UUID.cast(id) do
      {:ok, id} ->
        {true, id}
      :error ->
        {:invalid_id}
    end
  end

  def transform_birth_date(birth_date) do
    if is_nil(birth_date) do
      {:invalid_date_format}
    else
      with true <- validate_birth_date_format(birth_date)
    do
      true
    else
      _ ->
        {:invalid_date_format}
    end
    end
  end

  #Birth Date Format MM/DD/YYYY

  defp validate_birth_date_format(string) do
    Regex.match?(~r/((0[13578]|1[02])[\/.]31[\/.](18|19|20)[0-9]{2})|((01|0[3-9]|1[1-2])[\/.](29|30)[\/.](18|19|20)[0-9]{2})|((0[1-9]|1[0-2])[\/.](0[1-9]|1[0-9]|2[0-8])[\/.](18|19|20)[0-9]{2})|((02)[\/.]29[\/.](((18|19|20)(04|08|[2468][048]|[13579][26]))|2000))/, string)
  end

  def changeset_errors_to_string(errors) do
    for {field, {message, opts}} <- errors do
      "#{field} #{message}"
    end
    |> Enum.join(", ")
  end

  def changeset_errors_to_string2(errors) do
    for {field, {message, opts}} <- errors do
      "#{message}"
    end
    |> Enum.join(", ")
  end

  def changeset_errors_string_colon(errors) do
    for {field, {message, opts}} <- errors do
      "#{field}: #{message}"
    end
    |> Enum.join(", ")
  end

  def birth_date_transform(birth_date) do
    if birth_date == "" || is_nil(birth_date) do
      {:empty_birthday}
    else
      with true <- validate_birth_date_format(birth_date),
           {:ok, {year, month, day}} <- get_ymd(birth_date),
           {:ok, ecto_datetime} <- Ecto.DateTime.cast({{year, month, day}, {0, 0, 0}})
      do
        ecto_datetime = Ecto.DateTime.to_date(ecto_datetime)
        {:ok, ecto_datetime}
      else
        _ ->
          {:invalid_datetime_format}
      end
    end
  end

  def transform_datetime(datetime) do
    if is_nil(datetime) do
      {:invalid_datetime_format}
    else
      with true <- validate_datetime_format(datetime),
         {:ok, {year, month, day}} <- get_ymd(datetime),
         {:ok, {hour, min}} <- get_hms(datetime),
         {:ok, ecto_datetime} <- Ecto.DateTime.cast({{year, month, day}, {hour, min, 0}})
    do
      {:ok, ecto_datetime}
    else
      _ ->
        {:invalid_datetime_format}
    end
    end
  end

 def transform_new_datetime(datetime) do
    if is_nil(datetime) do
      {:invalid_datetime_format}
    else
       get_new_hms(datetime)
      with true <- validate_new_datetime_format(datetime),
         {:ok, datetime} <- get_new_hms(datetime)
      do
        {:ok, datetime}
      else
      _ ->
          {:invalid_datetime_format}
      end
    end
 end

  def transform_datetime_request(datetime) do
    if is_nil(datetime) do
      {:invalid_datetime_format}
    else
      with true <- validate_datetime_format(datetime),
         {:ok, {year, month, day}} <- get_ymd(datetime),
         {:ok, {hour, min}} <- get_hms(datetime),
         {:ok, ecto_datetime} <- Ecto.DateTime.cast({{year, month, day}, {hour, min, 0}})
    do
      ecto_datetime
    else
      _ ->
        {:invalid_datetime_format}
    end
    end
  end

  def transform_date_search(date) do
    if is_nil(date) do
      {:invalid_datetime_format}
    else
      with true <- validate_date_format(date),
        {:ok, {year, month, day}} <- get_ymd(date)
      do
         Ecto.Date.cast!({year, month, day})
      else
        _ ->
        {:invalid_datetime_format}
      end
    end

  end

  # returns {year, month, day} tuple
  defp get_ymd(datetime) do
    {month, day, year} =
      datetime
      |> String.slice(0..9)
      |> String.split("/")
      |> List.to_tuple()
    {:ok, {year, month, day}}
  end

  # returns {hour, minute} tuple
  defp get_hms(datetime) do
    {date, time, period} =
      datetime
      |> String.split(" ")
      |> List.to_tuple()
    {hour, minute} =
      time
      |> String.split(":")
      |> Enum.map(&(String.to_integer(&1)))
      |> List.to_tuple()



    case period do
      "PM" ->
        if hour == 12 do
          {:ok, {hour + 1, minute}}
        else
          {:ok, {hour + 12, minute}}
        end
      "AM" ->
        {:ok, {hour, minute}}
      _ ->
        {:invalid_datetime_format}
    end
  end

  defp get_new_hms(datetime) do
    {date, time, period} =
      datetime
      |> String.split(" ")
      |> List.to_tuple()
    {hour, minute} =
      time
      |> String.split(":")
      |> Enum.map(&(String.to_integer(&1)))
      |> List.to_tuple()

    case period do
      "PM" ->
        if hour == 12 do
        datetime = "#{date} #{hour + 1}:#{minute}"
          {:ok, datetime}
        else
       datetime = "#{date} #{hour + 12}:#{minute}"
          {:ok, datetime}
        end
      "AM" ->
         datetime = "#{date} #{hour}:#{minute}"
        {:ok, datetime}
      _ ->
        {:invalid_datetime_format}
    end
  end

  def validate_date_format(string) do
    Regex.match?(~r/^(0?[1-9]|1[012])[\/\-](0?[1-9]|[12][0-9]|3[01])[\/\-]\d{4}$/, string)
  end

  def validate_new_date_formmat(string) do
    Regex.match?(~r/^(0?[1-9]|1[012])[\-](0?[1-9]|[12][0-9]|3[01])[\-]\d{4}$/, string)
  end

  def validate_datetime_format(string) do
    Regex.match?(~r/^(((0[13578]|1[02])[\/\.-](0[1-9]|[12]\d|3[01])[\/\.-]((19|[2-9]\d)\d{2})\s([0-9]|1[0-2]):(0[0-9]|[1-59]\d)\s(AM|am|PM|pm))|((0[13456789]|1[012])[\/\.-](0[1-9]|[12]\d|30)[\/\.-]((19|[2-9]\d)\d{2})\s([0-9]|1[0-2]):(0[0-9]|[1-59]\d)\s(AM|am|PM|pm))|((02)[\/\.-](0[1-9]|1\d|2[0-8])[\/\.-]((19|[2-9]\d)\d{2})\s([0-9]|1[0-2]):(0[0-9]|[1-59]\d)\s(AM|am|PM|pm))|((02)[\/\.-](29)[\/\.-]((1[6-9]|[2-9]\d)(0[48]|[2468][048]|[13579][26])|((16|[2468][048]|[3579][26])00))\s([0-9]|1[0-2]):(0[0-9]|[1-59]\d)\s(AM|am|PM|pm)))$/, string)
  end

  def validate_new_datetime_format(string) do
    Regex.match?(~r/^((((19|[2-9]\d)\d{2})[\-\.-](0[13578]|1[02])[\-\.-](0[1-9]|[12]\d|3[01])\s([0-9]|1[0-2]):(0[0-9]|[1-59]\d)\s(AM|am|PM|pm))|((19|[2-9]\d)\d{2})((0[13456789]|1[012])[\-\.-](0[1-9]|[12]\d|30)\s([0-9]|1[0-2]):(0[0-9]|[1-59]\d)\s(AM|am|PM|pm))|((02)[\-\.-](0[1-9]|1\d|2[0-8])[\-\.-]((19|[2-9]\d)\d{2})\s([0-9]|1[0-2]):(0[0-9]|[1-59]\d)\s(AM|am|PM|pm))|((02)[\-\.-](29)[\-\.-]((1[6-9]|[2-9]\d)(0[48]|[2468][048]|[13579][26])|((16|[2468][048]|[3579][26])00))\s([0-9]|1[0-2]):(0[0-9]|[1-59]\d)\s(AM|am|PM|pm)))$/, string)
  end

  def validate_yyyymmdd_format(string) do
    Regex.match?(~r/^(19|20)[0-9]{2}-((02-(0[1-9]|[1-2][0-9]))|((01|03|05|07|08|10|12)-(0[1-9]|[1-2][0-9]|3[0-1]))|((04|06|09|11)-(0[1-9]|[1-2][0-9]|30)))$/, string)
  end

  def validate_dates_format(string, type) do
    if Regex.match?(~r/^([12]\d{3}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01]))$/, string) == true do
      true
    else
      {false, type}
    end
  end

  # def validate_new_date(date) do
  #     Ecto.Date.cast!(date)
  #   {:ok, date}
  #   # rescue
  #   #   _ ->
  #   #     {:invalid_date}
  # end

  # returns age based on given ecto date
  def age(%Ecto.Date{day: d, month: m, year: y}, as_of \\ :now) do
    do_age({y, m, d}, as_of)
  end

  defp do_age(birthday, :now) do
    {today, _time} = :calendar.now_to_datetime(:erlang.now)
    calc_diff(birthday, today)
  end

  defp do_age(birthday, date), do: calc_diff(birthday, date)

  defp calc_diff({y1, m1, d1}, {y2, m2, d2}) when m2 > m1 or (m2 == m1 and d2 >= d1) do
    y2 - y1
  end

  defp calc_diff({y1, _, _}, {y2, _, _}), do: (y2 - y1) - 1

# API functions start
  def payorlink_one_sign_in(scheme) do
    with %ApiAddress{} = api_address <- ApiAddressContext.get_api_address_by_name("PAYORLINK 1.0")
    do
      api_address
      |> get_payorlink_one_bearer(scheme)
    else
      nil ->
        {:api_address_not_exists}
    end
  end

  def get_payorlink_one_bearer(api_address, scheme) do
    payorlink_one_url = "#{api_address.address}/paylinkapi/TOKEN"
    headers = [{"Content-type", "application/json"}]
    body = "grant_type=password&username=#{api_address.username}&password=#{api_address.password}"

    option =
      if Atom.to_string(scheme) == "http" do
        [ssl: [{:versions, [:'tlsv1.2']}], recv_timeout: 60_000]
      else
        [recv_timeout: 60_000]
      end

    with {:ok, response} <- HTTPoison.post(payorlink_one_url, body, headers, option)
    do
      if response.status_code == 200 do
        decoded =
          response.body
          |> Poison.decode!()

        {:ok, decoded["access_token"]}
      else
        {:unable_to_login, "Unable to login to CVV API"}
      end
    else
      {:error, %HTTPoison.Error{reason: {reason, description}}} ->
        {:unable_to_login, reason}
      _ ->
        {:unable_to_login, "Unable to login to CVV API"}
    end
  end

  def providerlink_sign_in(scheme) do
    with api_address = %ApiAddress{} <- ApiAddressContext.get_api_address_by_name("PROVIDERLINK_2")
    do
      api_address
      |> get_providerlink_token(scheme)
    else
      nil ->
        {:api_address_not_exists}
    end
  end

  def payorlink_one_sign_in_v4(scheme) do
    with %ApiAddress{} = api_address <- ApiAddressContext.get_api_address_by_name("PAYORLINK 1.0")
    do
      api_address
      |> get_payorlink_one_bearer2(scheme)
    else
      nil ->
        {:api_address_not_exists}
    end
  end

  def get_payorlink_one_bearer2(api_address, scheme) do
    payorlink_one_url = "#{api_address.address}/PayorAPI/v4/token"
    headers = [{"Content-type", "application/json"}]
    body = "grant_type=password&username=#{api_address.username}&password=#{api_address.password}"

    option =
      if Atom.to_string(scheme) == "http" do
        [ssl: [{:versions, [:'tlsv1.2']}], recv_timeout: 60_000]
      else
        [recv_timeout: 60_000]
      end

    with {:ok, response} <- HTTPoison.post(payorlink_one_url, body, headers, option)
    do
      if response.status_code == 200 do
        decoded =
          response.body
          |> Poison.decode!()

        {:ok, decoded["access_token"]}
      else
        {:unable_to_login, "Unable to login to PayorAPI/v4/TOKEN"}
      end
    else
      {:error, %HTTPoison.Error{reason: {reason, description}}} ->
        {:unable_to_login, reason}
      _ ->
        {:unable_to_login, "Unable to login to PayorAPI/v4/TOKEN"}
    end
  end

  def save_peme_members_in_payorlink_one(token, member, params) do
    peme_member = create_peme_member_param(member, params)
    api_address = ApiAddressContext.get_api_address_by_name("PAYORLINK 1.0")
    payorlink_one_url = "#{api_address.address}/PayorAPI/v4/api/Migration/PEMESaveMembers"
    headers = [{"Content-type", "application/json"}, {"authorization", "Bearer #{token}"}]
    body = peme_member
    with {:ok, response} <- HTTPoison.post(payorlink_one_url, body, headers, []) do
      resp = Poison.decode!(response.body)
      save_peme_response(resp)
    else
      _ ->
        {:error_api_save_peme_member}
    end
  end

  defp save_peme_response(%{"Message" => message}), do: {:error_member, message}
  defp save_peme_response(response), do: response(response, response["Error"])

  defp response(response, nil), do: {:ok, response["Success"]}
  defp response(response, _error_msg), do: {:error_member, Enum.join(response["Error"], ",")}

  def paylink_sign_in(scheme) do
    # payor = PayorContext.get_payor_by_code(payor_code)
    api_address = ApiAddressContext.get_api_address_by_name("PaylinkAPI")

    paylink_sign_in_url = Enum.join([api_address.address, "TOKEN"], "")
    headers = [{"Content-type", "application/json"}]
    body = "grant_type=password&username=#{api_address.username}&password=#{api_address.password}"
    option =
      if Atom.to_string(scheme) == "http" do
        [ssl: [{:versions, [:'tlsv1.2']}], recv_timeout: 60_000]
      else
        [recv_timeout: 60_000]
      end
    with {:ok, response} <- HTTPoison.post(paylink_sign_in_url,
                                           body, headers, option)
    do
      if response.status_code == 200 do
        decoded = Poison.decode!(response.body)
        {:ok, decoded["access_token"]}
      else
        {:unable_to_login}
      end
    else
      {:error, response} ->
        {:unable_to_login}
    end
  end

  def create_peme_loa_payorlink_one(scheme, params) do
    with {:ok, token} <- paylink_sign_in(scheme) do
      api_address = ApiAddressContext.get_api_address_by_name("PaylinkAPI")
      payorlink_one_url = "#{api_address.address}api/PayLinkLOA/CreateACULOA"
      headers = [{"Content-type", "application/json"}, {"authorization", "Bearer #{token}"}]
      body = Poison.encode!(params)

      with {:ok, response} <- HTTPoison.post(payorlink_one_url, body, headers, []) do
        return_paylink(response)
      else
        _ ->
        {:error_loa, "Error Submitting Loa to Paylink"}
      end
    else
      _ ->
        {:error_loa, "Unable to sign-in in Paylink"}
    end
  end

  defp return_paylink(response) do
    decoded = Poison.decode!(response.body)
    if Enum.count(decoded["Eligibility"]) > 1 do
      {:ok, [decoded]}
    else
      {:error_loa_params, decoded["ErrorMessage"]}
    end
  rescue
    _ ->
    {:error_loa_params, Poison.decode!(response.body)["ErrorMessage"]}
  end

  defp create_peme_member_param(member, params) do
    gender = if member.gender == "Male", do: "M", else: "F"
    name = get_username_by_user_id(member.created_by_id)
    civil_stat = payorlink_one_loa_member_civil_status(member.civil_status)
    a = %{
      # "corpcode": "C63439",
      "corpcode": member.account_code,
      "firstname": member.first_name,
      "lastname":  member.last_name,
      "mi": get_middle_initial_member(member.middle_name),
      "extension": "",
      "gender": gender,
      "birthdate": to_date_slash(member.birthdate),
      "civilstat": civil_stat,
      "address": member_address(member),
      "city_municipal": member.city,
      "province": member.province,
      "zipcode": "",
      "tel_no": member.telephone,
      "bus_telno": "",
      "mobile_no": member.mobile,
      "email": member.email,
      "fax": member.fax,
      "tin": member.tin,
      "remarks": "",
      "provider_code": params.facility_code,
      "start_date": to_date_slash(member.effectivity_date),
      "end_date": to_date_slash(member.expiry_date),
      "card_no": member.card_no,
      "policy_no": "",
      "package_code": params.benefit_code,
      "account_expirydate": to_date_slash(member.expiry_date),
      "link_id": " ",
      "created_by": "masteradmin",
      "endorse_by": "masteradmin",
      "expiry_date": to_date_slash(member.expiry_date),
      "availment_date": to_date_slash(Ecto.Date.utc()),
      "cpt_rate": params.package_facility_rate,
      "effectivedate": to_date_slash(member.effectivity_date),
      "origeffectivedate": to_date_slash(member.effectivity_date),
      "claimstatus": "",
      "MemberType": "P",
      "Relationship": member.type
    }
    |> Poison.encode!()
    # Logger.info(a)
    # a
  end

  def to_date_slash(nil), do: ""
  def to_date_slash(date) do
      [year, month, day] = String.split(Ecto.Date.to_string(date), "-")
      "#{month}/#{day}/#{year}"
    rescue
      _ ->
        ""
  end

  defp member_address(member) do
    Enum.join([
      member.street_name,
      member.building_name,
      member.unit_no,
      member.city,
      member.province,
      member.region,
      member.country
    ], " ")
  end

  defp payorlink_one_loa_member_civil_status(status) do
    cs = case status do
      "Anulled" ->
        "A"

      "Married" ->
        "M"

      "Single" ->
        "S"

      "Separated" ->
        "SE"

      "Widowed" ->
        "W"

      _ ->
        "SP"
    end
  end

  # defp create_peme_loa_params(loa) do
  #  %{
  #     "CardNo" => "sample string 1",
  #     "ProviderCode" => "sample string 2",
  #     "AvailmentDate"=> "2018-08-30T10:30:25.6908379+08:00",
  #     "DischargeDate" => "2018-08-30T10:30:25.6908379+08:00",
  #     "LoaNo" => "sample string 5",
  #     "LoaStatus" => "sample string 6",
  #     "CreatedBy" => "sample string 7",
  #     "ClaimType" => "sample string 8",
  #     "SpecialApproval" => "sample string 9",
  #     "Remarks" => "sample string 10",
  #     "Email" => "sample string 11",
  #     "Mobile" => "sample string 12",
  #     "RefType" => "sample string 13",
  #     "IpAddress" => "sample string 14",
  #     "ICDCode" => [
  #       {
  #         "ICDCode": "sample string 1",
  #         "ICDDesc": "sample string 2",
  #         "EstimatePrice": "sample string 3"
  #       },
  #       {
  #         "ICDCode": "sample string 1",
  #         "ICDDesc": "sample string 2",
  #         "EstimatePrice": "sample string 3"
  #       }
  #     ],
  #     "CPTList" => [
  #       {
  #         "BenefitID": "sample string 1",
  #         "CptCode": "sample string 2",
  #         "CptDesc": "sample string 3",
  #         "EstimatePrice" => "sample string 4",
  #         "IcdCode" => "sample string 5",
  #         "LimitCode" => "sample string 6"
  #       },
  #       {
  #         "BenefitID" => "sample string 1",
  #         "CptCode" => "sample string 2",
  #         "CptDesc" => "sample string 3",
  #         "EstimatePrice" => "sample string 4",
  #         "IcdCode" => "sample string 5",
  #         "LimitCode" => "sample string 6"
  #       }
  #     ],
  #     "PatientName" => "sample string 15",
  #     "AssessedAmnt" => 16.0,
  #     "RejectCode" => "sample string 17",
  #     "RequestedBy" => "sample string 18",
  #     "OtherPhy" => "sample string 19",
  #     "OtherPhyType" => "sample string 20",
  #     "ProviderInstruction" => "sample string 21",
  #     "GeneratedFrom" => "sample string 22",
  #     "Coverage" => "sample string 23",
  #     "AuthorizationCode" => "sample string 24"
  #   }
  # end

  def get_username_by_user_id(user_id) do
   user =
    User
    |> Repo.get(user_id)

    user.username
  end

  defp get_middle_initial_member(nil), do: " "
  defp get_middle_initial_member(""), do: " "
  defp get_middle_initial_member(middle_name) do
    middle_name
    |> String.split("")
    |> Enum.at(1)
  end

  defp get_providerlink_token(api_address, scheme) do
    providerlink_url = "#{api_address.address}/api/v1/sign_in"
    headers = [{"Content-type", "application/json"}]
    params = %{
      username: api_address.username,
      password: api_address.password
    }
    body = Poison.encode!(params)
    option =
      if Atom.to_string(scheme) == "http" do
        [ssl: [{:versions, [:'tlsv1.2']}], recv_timeout: 60_000]
      else
        [recv_timeout: 60_000]
      end

    with {:ok, response} <- HTTPoison.post(providerlink_url, body, headers, option)
    do
      if response.status_code == 200 do
        decoded =
          response.body
          |> Poison.decode!()

        {:ok, decoded["token"]}
      else
        {:unable_to_login, Poison.decode!(response.body)["error_description"]}
      end
    else
      {:error, %HTTPoison.Error{reason: {reason, description}}} ->
        {:unable_to_login, reason}
      _ ->
        {:unable_to_login, "Unable to login to ProviderLink API"}
    end
  end
# API functions end

  def transforms_number(number) do
    "63#{number}"
  end

  def valid_id?(id) do
    case UUID.cast(id) do
      {:ok, id} ->
        true
      :error ->
        false
    end
  end

  # RANDOM STRING GENERATOR
  def randomizer(length, type \\ :all) do
    alphabets = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    numbers = "0123456789"

    lists =
      cond do
        type == :alpha -> alphabets <> String.downcase(alphabets)
        type == :numeric -> numbers
        type == :upcase -> alphabets
        type == :downcase -> String.downcase(alphabets)
        true -> alphabets <> String.downcase(alphabets) <> numbers
      end
    lists = lists |> String.split("", trim: true)
    do_randomizer(length, lists)
  end

  defp get_range(length) when length > 1, do: (1..length)
  defp get_range(length), do: [1]

  def do_randomizer(length, lists) do
    range = get_range(length)
    range
    |> Enum.reduce([], fn(_, acc) -> [Enum.random(lists) | acc] end)
    |> Enum.join("")
  end
  # RANDOM STRING GENERATOR END

  def transform_new_date(datetime) do
      [date, h, t] = String.split(datetime)
        {year, month, day} =
          date
          |> String.split("-")
          |> List.to_tuple()
      {:ok, "#{month}/#{day}/#{year} #{h} #{t}"}
    rescue
     _ ->
       {:invalid_datetime_format}
  end

  def validate_string(string) do
  # false if string is valid
    Regex.match?(~r/^\x00$/, string)
    rescue
      _ ->
    true
  end

  def get_ip(conn) do
    {:ok, ip} = :inet.getif()

    ip =
      ip
      |> Enum.at(0)
      |> Tuple.to_list()
      |> Enum.at(0)
      |> Tuple.to_list()

    "#{Enum.at(ip, 0)}.#{Enum.at(ip, 1)}.#{Enum.at(ip, 2)}.#{Enum.at(ip, 3)}"
  end

  # GET SAP CSRF

  def get_SAP_api_address(address_name) do
    with api_address = %ApiAddress{} <- ApiAddressContext.get_api_address_by_name(address_name)
    do
      api_address
      |> request_csrf_token()
    else
      nil ->
        {:api_address_not_exists}
    end
  end

  defp request_csrf_token(struct) do
    params = %{
      "Accept" => "Application/json, charset=utf-8",
      "x-csrf-token" => "fetch",
      "Authorization" => "Basic " <> Base.encode64("#{struct.username}:#{struct.password}")
    }

    headers = HTTPoison.process_request_headers(params)

    with {:ok, response} <- HTTPoison.get(struct.address, headers, []) do
      check_SAP_status(response)
    else
      {:error, response} ->
        {:error_connecting_api}
    end
  end

  defp check_SAP_status(response) do
    case response.status_code do
      200 ->
        get_csrf_in_header(response.headers)
      401 ->
        {:unable_to_login}
      _ ->
        {:error}
    end
  end

  defp get_csrf_in_header(headers) do
    test = Enum.filter(headers, fn({key, value}) ->
      key == "x-csrf-token"
    end)

    {key, value} =
      test
      |> Enum.uniq()
      |> List.first()

    {:ok, value}
  end

  def sap_update_status(%{"code" => code, "message" => message,
                          "status_code" => status_code, "module" => module,
                          "migration_notification_id" => migration_notification_id})
  do
    case module do
      "Account" ->
        with {:ok, response} <- request_update_SAP_account(code, status_code, message, migration_notification_id) do
          {:ok, response}
        else
          {:error, message} ->
            {:error, message}

          {:invalid_parameters} ->
            {:error, "Invalid Parameters"}

          {:account_code_not_found} ->
            {:error, "Account Code not found"}
        end
      _ ->
        nil
    end

  end

  defp request_update_SAP_account(nil, nil, nil, nil), do: {:invalid_parameters}
  defp request_update_SAP_account(code, nil, message, migration_notification_id), do: {:invalid_parameters}
  defp request_update_SAP_account(code, nil, nil, migration_notification_id), do: {:invalid_parameters}
  defp request_update_SAP_account(nil, status_code, message, migration_notification_id), do:  {:account_code_not_found}
  defp request_update_SAP_account(code, status_code, message, migration_notification_id) do
    with {:ok, csrf_token} <- get_SAP_api_address("SAPCSRF"),
         api_address = %ApiAddress{} <- ApiAddressContext.get_api_address_by_name("SAP-UpdateAccount"),
         {:ok, response} <- update_SAP_account(api_address, csrf_token,
                                                %{code: code,
                                                  status_code: status_code,
                                                  message: message,
                                                  migration_notification_id: migration_notification_id})
    do
      {:ok, response}
    else
      {:api_address_not_exists} ->
        {:error, "API Address does not exists"}

      {:unable_to_login} ->
        {:error, "Unable to Login"}

      _ ->
        {:error, message}
    end

  end

  defp update_SAP_account(api_address, csrf_token, %{code: code,
                          status_code: status_code, message: message,
                          migration_notification_id: migration_notification_id}) do
    header_params = %{
      "X-CSRF-Token" => csrf_token,
      "Content-Type" => "application/json"
    }

    headers = HTTPoison.process_request_headers(header_params)
    params = "?AccountCode='#{code}'&StatusCode='#{status_code}'&Message='#{message}'"
    api_method = Enum.join([api_address.address, params], "")
    options = [ssl: [{:versions, [:'tlsv1.2']}]]

    with {:ok, response} <- HTTPoison.post("#{api_method}", "", headers, options)
    do
      insert_sap_notification(%{
        code: code,
        message: message,
        status_code: status_code,
        response: "#{response.status_code}",
        response_details: response.body,
        migration_notification_id: migration_notification_id
      })

      case response.status_code do
        200 ->
          {:ok, response}

        401 ->
          {:unable_to_login}

        _ ->
          {:error, "Error"}
      end
    else
      {:error, %HTTPoison.Error{reason: {reason, description}}} ->
        {:unable_to_login, reason}

      _ ->
        {:unable_to_login, "Unable to login"}
    end
  end

  def insert_sap_notification(attrs \\ %{}) do
    %SAPNotification{}
    |> SAPNotification.changeset(attrs)
    |> Repo.insert()
  end

  # FOR EMAIL

  def payorlink_v2_sign_in() do
    api_address = ApiAddressContext.get_api_address_by_name("PAYORLINK_2")
    payorlink_sign_in_url = "#{api_address.address}/api/v1/sign_in"
    headers = [{"Content-type", "application/json"}]
    body = Poison.encode!(%{"username": api_address.username, "password": api_address.password})

    with {:ok, response} <- HTTPoison.post(payorlink_sign_in_url, body, headers, []),
         200 <- response.status_code
    do
      decoded =
        response.body
        |> Poison.decode!()

      {:ok, decoded["token"]}
    else
      {:error, response} ->
        {:unable_to_login, response}
      _ ->
        {:unable_to_login, "Error occurs when attempting to login in Payorlink"}
    end
  end

  def payorlinkv2_sign_in_with_address_return() do
    api_address = ApiAddressContext.get_api_address_by_name("PAYORLINK_2")
    payorlink_sign_in_url = "#{api_address.address}/api/v1/sign_in"
    headers = [{"Content-type", "application/json"}]
    body = Poison.encode!(%{"username": api_address.username, "password": api_address.password})

    with {:ok, response} <- HTTPoison.post(payorlink_sign_in_url, body, headers, []),
         200 <- response.status_code
    do
      decoded =
        response.body
        |> Poison.decode!()

      {:ok, decoded["token"], api_address.address}
    else
      {:error, response} ->
        {:unable_to_login, response}
      _ ->
        {:unable_to_login, "Error occurs when attempting to login in Payorlink"}
    end
  end

  def send_error_log_email(params) do
    with {:ok, token} <- payorlink_v2_sign_in() do
      api_address = ApiAddressContext.get_api_address_by_name("PAYORLINK_2")
      api_method = Enum.join([api_address.address, "/api/v1/email/worker_error/logs"], "")
      headers = [{"Content-type", "application/json"}, {"authorization", "Bearer #{token}"}]
      body = Poison.encode!(params)

      with {:ok, response} <- HTTPoison.post(api_method, body, headers, []),
          200 <- response.status_code
      do
        {:ok, response}
      else
        {:error, response} ->
          {:error, response}
        _ ->
          {:error_api_email}
      end
    end
  end

  def authenticate do
    username =  "JQUINGCO"
    password = "appcentric1"

    url = "https://sap-webd.maxicare.com.ph:8081/sap/opu/odata/sap/ZPUBD_SRV/"
    headers = ["Authorization": "Basic #{Base.encode64("#{username}:#{password}")}", "Accept": "Application/json, charset=utf-8", "x-csrf-token": "fetch"]
    options = [ssl: [{:versions, [:'tlsv1.2']}]]
    get(url, headers,  options)
  end

  defp get(url, headers, options) do
    case HTTPoison.get(url, headers, options) do
      {:ok, res} ->
        res
      {:error, reason} ->
        raise reason
    end
  end

  def update_account() do
    response = authenticate()
    csrf_token = get_csrf_token_in_header(response.headers)
    link = "https://sap-webd.maxicare.com.ph:8081/sap/opu/odata/sap/ZPUBD_SRV/UpdateAccountStatus"
    params = "?AccountCode='SAMPLECODE'&StatusCode='200'&Message='SAMPLEMESSAGE'"
    url = Enum.join([link, params], "")

    header_params = %{
      "X-CSRF-Token" => csrf_token,
      "Content-Type" => "application/json"
    }

    headers = HTTPoison.process_request_headers(header_params)
    options = [ssl: [{:versions, [:'tlsv1.2']}]]
    body = %{
    } |> Poison.encode! # put your params here
    post(url, headers, options, body)
  end

  defp post(url, headers, options, body) do
    case HTTPoison.post(url, body, headers, options) do
      {:ok, res} ->
        raise res
        res.body |> Poison.decode!
      {:error, reason} ->
        raise reason
    end
  end

  defp get_csrf_token_in_header(headers) do
    test = Enum.filter(headers, fn({key, value}) ->
      key == "x-csrf-token"
    end)

    {key, value} =
      test
      |> Enum.uniq()
      |> List.first()

    value
  end

  def partition_list([], limit, result), do: result
  def partition_list(list, limit, result) do

    temp = Enum.slice(list, 0..limit)
    result = result ++ [temp]
    temp_result = list -- temp

    partition_list(temp_result, limit, result)
  end

  def get_payorlink_one_token() do
    api_address = Repo.get_by(ApiAddress, name: "PAYORLINK 1.0")
    with payorlink_one_url <- "#{api_address.address}/payorAPI/v5/token",
         headers <- [{"Content-type", "application/json"}],
         body <- "grant_type=password&username=#{api_address.username}&password=#{api_address.password}",
         {:ok, response} <- HTTPoison.post(payorlink_one_url, body, headers)
    do
      if response.status_code == 200 do
        decoded =
          response.body
          |> Poison.decode!()

        {:ok, decoded["access_token"], api_address.address}
      else
        {:unable_to_login, "Unable to login API"}
      end
    else
      {:error, %HTTPoison.Error{reason: {reason, description}}} ->
        {:unable_to_login, reason}
      _ ->
        {:unable_to_login, "Unable to login API"}
    end
  end

  @docp """
    ______________________________________________________________
   |     name      |     card_no      | inserted_at | updated_at |
   |-------------------------------------------------------------|
   | Julie Arcana  | 6011000037841311 | 05102018    | 05102018   |
   | Pedro Gonzalo | 6011000037841311 | 06152018    | 06152018   |
   | Peter Roxas   | 6011000037841311 | 08202018    | 08202018   |
   |               |                  |             |            |
   |-------------------------------------------------------------|

    query = update all card number for duplicated member.card_no without affecting Julie Arcana
    the 1st to have with "6011000037841311" card_no.

    ______________________________________________________________
   |     name      |     card_no      | inserted_at | updated_at |
   |-------------------------------------------------------------|
   | Pedro Gonzalo | 6011000037858473 | 06152018    | 08312018   |
   | Peter Roxas   | 6011000047896836 | 08202018    | 08312018   |
   |               |                  |             |            |
   |-------------------------------------------------------------|
  """

  def remedy_for_duplicated_card_no() do

    query = "select id from members m
    inner join (
      select min(inserted_at) as date, card_no  from members
      where card_no is not null
      and card_no in (
        select card_no from members where card_no is not null
        group by card_no
        having count(*)> 1
      )
      group by card_no
    ) a on m.card_no = a.card_no and m.inserted_at <> a.date"
    {:ok, result} = Ecto.Adapters.SQL.query(Repo, query)

    result.rows
    |> List.flatten()
    |> Enum.map(fn(x) ->
      Member
      |> Repo.get(Ecto.UUID.cast!(x))
      |> update_card_no()
    end)

  end

  defp update_card_no(member) do
    member
    |> Member.changeset_card()
    |> Repo.update()
  end

  def convert_date_format(nil), do: nil
  def convert_date_format(date) do
    {:ok, {year, month, day}} = Ecto.Date.dump(Ecto.Date.cast!(date))
    if Enum.count(String.codepoints("#{day}")) == 1, do: day = "0#{day}"
    "#{month_name(month)} #{day}, #{year}"
  end

  def month_name(index) do
    Enum.at([
      "None",
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ], index)
  end

  def transform_string_dates(nil), do: nil
  def transform_string_dates(date) do
      [month, day, year] = String.split(date)
      [day, _] = String.split(day, ",")
      if Enum.count(String.codepoints(day)) == 1, do: day = "0#{day}"
      month = month_index[String.downcase(month)]
      "#{year}-#{month}-#{day}"
    rescue
      _ ->
        cast_date(date)
  end

  def month_index do
    %{
      "jan" => "01",
      "feb" => "02",
      "mar" => "03",
      "apr" => "04",
      "may" => "05",
      "jun" => "06",
      "jul" => "07",
      "aug" => "08",
      "sep" => "09",
      "oct" => "10",
      "nov" => "11",
      "dec" => "12"
     }
  end

  defp cast_date(date) do
      Ecto.Date.cast!(date)
    rescue
       _ ->
        nil
  end

  def get_client_ip(conn) do
    conn.remote_ip
    |> Tuple.to_list
    |> Enum.join(".")
  end

  def sanitize_value(value) do
    {:safe, data} = HTML.html_escape(value)

    data
    |> HTML.raw()
    |> HTML.safe_to_string()
  end

  def is_valid_string?(param) do
    ~r/^\x00/
      |> Regex.scan(param)
      |> Enum.empty?()
  end

  def check_valid_params(params, required_keys) do
    results = Enum.map(required_keys, fn k -> Map.has_key?(params, k) and params[k] != ""  and params[k] != [] and not is_nil(params[k]) end)

    if Enum.member?(results, false)  do
      keys_not_found =
        Enum.map(Enum.with_index(results), fn({result, i}) ->
          if result == false, do: "#{Enum.at(required_keys, i)} is required"
        end)

      keys_not_found =
        keys_not_found
        |> Enum.uniq()
        |> List.delete(nil)

      {:error_params, Enum.join(keys_not_found, ", ")}
    else
      {:ok, params}
    end
  end

  def beginning_restricting_symbols(graphemes, restricted_values, {key, value}) do
    restricted_values
    |> Enum.member?(graphemes)
    |> is_valid?({key, value})
  end
  defp is_valid?(true, {key, value}), do: {:false, {key, value}} ## restricted value is included
  defp is_valid?(false, {key, value}), do: {:true, {key, value}} ## value is safe

  def restricting_symbols_return_val_only(first_char, restricted_values, orig_value) do
    restricted_values
    |> Enum.member?(first_char)
    |> is_valid?(orig_value)
  end
  defp is_valid?(true, orig_value), do: {:error, orig_value} ## restricted value is included
  defp is_valid?(false, orig_value), do: {:ok, orig_value} ## value is safe

  def unique_list(list) do
    list
    |> Enum.uniq()
    |> Enum.filter(&(not is_nil(&1)))
  end

  ################################################# SAP cloud for customer
  def sap_c4c_ticketing(changeset, request_path, code, env), do: changeset |> access_sap_c4c(request_path, code, env)
  def sap_c4c_ticketing("internal server error" = internal_msg, request_path, code, env) do
    internal_msg |> access_sap_c4c(request_path, code, env)
  end

  def access_sap_c4c(str_value, request_path, code, env) when is_binary(str_value) do
    sap_c4c_get(%{
      username: get_credential().username,
      password: get_credential().password,
      url: get_credential().url,
      subject: "#{env}#{request_path}, code: #{code}",
      errors: str_value
    })
  end
  def access_sap_c4c(%{errors: errors} = changeset, request_path, code, env) do
    sap_c4c_get(%{
      username: get_credential().username,
      password: get_credential().password,
      url: get_credential().url,
      subject:  request_path |> fetch_error_and_details(code, env),
      errors: errors|> changeset_errors_to_string()
    })
  end
  defp fetch_error_and_details(request_path, code, env) do
    "#{env}#{request_path}, code: #{code}"
  end

  defp sap_c4c_get(details) do
    with headers <- [
           {"Accept", "application/json"},
           {"x-csrf-token", "FETCH"},
           {"Authorization", "Basic " <> Base.encode64("#{details.username}:#{details.password}")}
         ],
         {:ok, response} <- HTTPoison.get(details.url, headers)
    do
      concatenated_cookies =
        response.headers
        |> Enum.filter(fn({v1, v2}) -> v1 == "set-cookie" end)
        |> concat_cookie()

      response.headers
      |> Enum.find(fn({v1, v2}) -> v1 == "x-csrf-token" end)
      |> sap_c4c_post(details, concatenated_cookies)
    else
      {:error, response} ->
        {:error_connecting_api}
      _ ->
        {:error_connecting_api}
    end
  end

  defp sap_c4c_post({x_csrf_token, value}, details, concatenated_cookies) do
    with headers <- [
           {"Content-type", "application/json"},
           {"accept", "application/json"},
           {x_csrf_token, value},
           {"Authorization", "Basic " <> Base.encode64("#{details.username}:#{details.password}")},
           {"Cookie", concatenated_cookies}
         ],
         body <- Poison.encode!(
           %{
             "Name" => %{
               "languageCode" => "EN",
               "content" => details.subject
             },
             "ServiceRequestDescription" => [
               %{
                 "Text" => details.errors,
                 "TypeCode" => "10011"
               }
             ]
           }
         ),
         {:ok, response} <- HTTPoison.post(details.url, body, headers, [])
    do
      ## asof now return nothing,
      ## Ask Ma'am Janna if we will gonna implement a DB to check if it is sent to SAPTEAM
      ""
    else
      {:error, response} ->
        {:error_connecting_api}
      _ ->
        {:error_connecting_api}
    end
  end

  defp concat_cookie(set_cookie) do
    set_cookie
    |> Enum.map(fn({v1, v2}) -> v2 |> ignore_path_onwards() end)
    |> Enum.join("; ")
  end

  defp ignore_path_onwards(cookie_with_path) do
    cookie_with_path
    |> String.split(";")
    |> Enum.at(0)
  end

  def get_credential do
    :db |> Application.get_env(Innerpeace.Db.Base.Api.UtilityContext) |> Keyword.get(:credentials) || {}
  end

end
