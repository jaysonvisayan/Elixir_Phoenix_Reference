defmodule MemberLinkWeb.MemberView do
  use MemberLinkWeb, :view

  def display_emergency_info(member, key) do
  	if is_nil(member.emergency_contact) do
  		""
  	else
  		Map.get(member.emergency_contact, key)
  	end
  end

  def display_evoucher_details(member, key) do
  	if member.first_name == "Temporary" and member.last_name == "Member" do
  		""
  	else
  		Map.get(member, key)
  	end
  end

  def format_datetime(datetime) when not is_nil(datetime) do
	date = datetime
		   |> Ecto.DateTime.to_date()
		   |> Ecto.Date.to_string()
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
  def format_datetime(datetime), do: ""

  def format_new_date(date) when not is_nil(date) do
	date = date
	       |> Ecto.Date.to_string()
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
  def format_new_date(date), do: ""

  def member_full_name(member) do
    if is_nil(member.middle_name) == false do
      if is_nil(member.suffix) == false do
        "#{member.first_name} #{member.middle_name} #{member.last_name} #{member.suffix}"
      else
        "#{member.first_name} #{member.middle_name} #{member.last_name}"
      end
    else
      if is_nil(member.suffix) == false do
        "#{member.first_name} #{member.last_name} #{member.suffix}"
      else
        "#{member.first_name} #{member.last_name}"
      end
    end
  end

  def get_age(date) do
    year_of_date = to_string(date)
    year_today =  Date.utc_today()
    year_today = to_string(year_today)
    datediff1 = Timex.parse!(year_of_date, "%Y-%m-%d", :strftime)
    datediff2 = Timex.parse!(year_today, "%Y-%m-%d", :strftime)
    diff_in_years = Timex.diff(datediff2, datediff1, :years)
    diff_in_years
  end

#   def get_age(birth_date, date_today) do
#     birth_year = birth_date.year
#     birth_month = birth_date.month
#     birth_day = birth_date.day
#     date_year = date_today.year
#     date_month = date_today.month
#     date_day = date_today.day
#     age = date_year - birth_year
#     if birth_month >= date_month && birth_day > date_day do
#       age - 1
#     else
#       age
#     end
#   end

  def p_display_complete_address(facility) do
    "#{facility.line_1}, #{facility.line_2}, #{facility.city},
    #{facility.province}, #{facility.region}, #{facility.country}"
  end

  def convert_to_word(nil), do: nil
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

  def get_auth_key_value(nil, _key), do: nil
  def get_auth_key_value(pcdrs, key) do
    {_, value} = Map.fetch(pcdrs, key)
    value
  end

  def add(nil, _), do: nil
  def add(_, nil), do: nil
  def add(val1, val2) do
    Decimal.add(val1, val2)
  end
end
