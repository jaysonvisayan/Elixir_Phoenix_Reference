defmodule MemberLinkWeb.UserView do
  use MemberLinkWeb, :view

  # alias Innerpeace.Db.Base.MemberContext

  def list_years() do
    Enum.into(1920..2000, [], &(&1))
  end

  def list_days() do
    Enum.into(1..31, [], &(&1))
  end

  def list_months() do
    _x = [{"JAN", "01"},
         {"FEB", "02"},
         {"MAR", "03"},
         {"APR", "04"},
         {"MAY", "05"},
         {"JUN", "06"},
         {"JUL", "07"},
         {"AUG", "08"},
         {"SEP", "09"},
         {"OCT", "10"},
         {"NOV", "11"},
         {"DEC", "12"}
    ]
  end

  def attempts_checker(attempts) do
    cond do
      attempts == 1 ->
        attempts = 3
      attempts == 2 ->
        attempts = 1
      true ->
        attempts = 0
    end
  end

  def get_img_url(member) do
    Innerpeace.ImageUploader
    |> MemberLinkWeb.LayoutView.image_url_for(member.photo, member, :original)
    |> String.replace("/apps/member_link/assets/static", "")
  end

  def format_name_first(name) do
    if name.suffix == "" || is_nil(name.suffix) do
      "#{name.first_name} #{name.middle_name} #{name.last_name}"
    else
      "#{name.first_name} #{name.middle_name} #{name.last_name}, #{name.suffix}"
    end
  end

  def format_date(date) do
    if date == "" || is_nil(date) do
      date
    else
      Timex.format!(date, "{Mshort} {D}, {YYYY}")
    end
  end

  def format_card_no(card_no) do
    "#{String.slice(card_no, 0, 4)} #{String.slice(card_no, 4, 4)} #{String.slice(card_no, 8, 4)} #{String.slice(card_no, 12, 4)}"
  end
end
