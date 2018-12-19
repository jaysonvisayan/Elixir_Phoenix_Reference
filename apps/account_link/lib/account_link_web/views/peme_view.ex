defmodule AccountLinkWeb.PemeView do
  use AccountLinkWeb, :view
  alias Innerpeace.Db.Repo
  alias Innerpeace.Db.Schemas.ApiAddress
  alias AccountLinkWeb.Plug.NumberToWord

  def get_img_url(member) do
    image = Innerpeace.PayorLink.Web.LayoutView.image_url_for(Innerpeace.ImageUploader, member.photo, member, :original)
    String.replace(image, "/apps/account_link/assets/static", "")
  end

  def return_tab_status(member, member_tab, tab) do
    if member == %{} do
      if member_tab == tab do
        " active"
      end
    else
      if member_tab == tab do
        " active"
      else
        " link"
      end
    end
  end

  def load_procedures(ppp_records) do
    ppp_list = [] ++ for ppp <- ppp_records do
      ppp.payor_procedure.procedure.description
    end

    Enum.join(ppp_list, ", ")
  end

  def load_name(member) do
    first_name = if is_nil(member.first_name), do: "", else: member.first_name
    middle_name = if is_nil(member.middle_name), do: "", else: member.middle_name
    last_name = if is_nil(member.last_name), do: "", else: member.last_name
    suffix = if is_nil(member.suffix), do: "", else: member.suffix
    first_name <> "  " <> middle_name <> "  " <> last_name <> "  " <> suffix
  end

  def load_facility(peme_loa) do
    with false <- is_nil(peme_loa),
         false <- is_nil(peme_loa.package),
         false <- is_nil(peme_loa.package.package_facility),
         false <- is_nil(Enum.at(peme_loa.package.package_facility, 0)),
         false <- is_nil(Enum.at(peme_loa.package.package_facility, 0).facility),
         false <- is_nil(Enum.at(peme_loa.package.package_facility, 0).facility.name)
    do
      Enum.at(peme_loa.package.package_facility, 0).facility.name
    else
      _ ->
        ""
    end
  end

  def get_link(member, member_tab, tab) do
    if member == %{} do
      "#!"
    else
      if member_tab == tab do
        "#!"
      else
        case tab do
          "general" ->
            "/peme/" <> member.id <> "/single?step=1"
          "contact" ->
            "/peme/" <> member.id <> "/single?step=2"
          "request_loa" ->
            "/peme/" <> member.id <> "/single?step=3"
        end
      end
    end
  end

  def render("package.json", %{params: params}) do
    package = params.package
    facility_ids = filter_facilities(params.facilities)
    facilities = Enum.map(package.package_facility, & (if Enum.member?(facility_ids, &1.facility.id), do: &1.facility))
    # Refactor this. Currently gets the first record.
    facility_name = Enum.at(package.package_facility, 0)
    facilities =
      facilities
      |> Enum.uniq()
      |> List.delete(nil)
    %{
      id: package.id,
      name: package.name,
      code: package.code,
      procedures: render_many(package.package_payor_procedure, AccountLinkWeb.PemeView, "package_procedure.json", as: :package_procedure),
      facilities: render_many(facilities, AccountLinkWeb.PemeView, "package_facility.json", as: :package_facility)
    }
  end

  def render("package_procedure.json", %{package_procedure: pp}) do
    %{
      code: pp.payor_procedure.procedure.code,
      description: pp.payor_procedure.procedure.description
    }
  end

  def render("package_facility.json", %{package_facility: pf}) do
    %{
      id: pf.id,
      code: pf.code,
      name: pf.name
    }
  end

  def filter_packages(packages) do
    Enum.map(packages, &({&1.name, &1.id}))
  end

  def filter_facilities(facilities) do
    Enum.map(facilities, &(&1.id))
  end


  def member_full_name(member) do
    with false <- is_nil(member.middle_name), is_nil(member.suffix)
    do
         "#{member.first_name} #{member.middle_name} #{member.last_name} #{member.suffix}"
    else
      true ->
        "#{member.first_name} #{member.last_name}"
      {:nil} ->
      "Temporary Member"
      _ ->
        "N/A"
    end
  end

  def get_memberlink_url_evoucher do
    ApiAddress
    |> Repo.get_by(name: "PORTAL")
  end

  # def member_full_name(member) do
  #   if is_nil(member.middle_name) == false do
  #     if is_nil(member.suffix) == false do
  #       "#{member.first_name} #{member.middle_name} #{member.last_name} #{member.suffix}"
  #     else
  #       "Temporary Member"
  #     end
  #   else
  #     if is_nil(member.suffix) == false do
  #       "#{member.first_name} #{member.last_name} #{member.suffix}"
  #     else
  #       "Temporary Member"
  #     end
  #   end
  # end

  def p_display_complete_address(facility) do
    "#{facility.line_1}, #{facility.line_2}, #{facility.city},
    #{facility.province}, #{facility.region}, #{facility.country}"
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

  def check_if_male(nil), do: false
  def check_if_male(peme), do: check_if_male_v2(peme.package)
  def check_if_male_v2(nil), do: false
  def check_if_male_v2(package), do: check_if_male_v3(package.package_payor_procedure)
  def check_if_male_v3([]), do: false
  def check_if_male_v3(ppp), do: Enum.into(ppp, [], &(&1.male))|> Enum.member?(true)

  def check_if_female(nil), do: false
  def check_if_female(peme), do: check_if_female_v2(peme.package)
  def check_if_female_v2(nil), do: false
  def check_if_female_v2(package), do: check_if_female_v3(package.package_payor_procedure)
  def check_if_female_v3([]), do: false
  def check_if_female_v3(ppp), do: Enum.into(ppp, [], &(&1.female))|> Enum.member?(true)

end
