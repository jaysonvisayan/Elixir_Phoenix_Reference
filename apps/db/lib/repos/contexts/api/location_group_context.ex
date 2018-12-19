defmodule Innerpeace.Db.Base.Api.LocationGroupContext do
  @moduledoc """
    Contexts for Location Group API
  """

  alias Innerpeace.Db.{
    Repo,
    Schemas.LocationGroup,
    Schemas.LocationGroupRegion,
    Base.LocationGroupRegionContext,
    Base.LocationGroupContext
  }

  import Ecto.{Query, Changeset}, warn: false

  def create(user, params) do
    data = %{}
    parameter_type = %{
      name: :string,
      description: :string,
      region: {:array, :string}
    }
    changeset =
      {data, parameter_type}
      |> cast(params, Map.keys(parameter_type))
      |> validate_required([
        :name,
        :description,
        :region
      ])

    changeset =
      changeset
      |> validate_string(changeset.changes[:name], :name)
      |> validate_string(changeset.changes[:description], :description)
      |> validate_lg(changeset.changes[:region], :region)

    if changeset.valid? do
      validate_lg_level2(changeset, user, params)
    else
      {:error, changeset}
    end
  end

  defp validate_string(changeset, params, field) do
    if is_nil(params) do
     changeset
    else
      if Regex.match?(~r/^[ a-zA-Z0-9:()-]*$/, params) == true do
        changeset
      else
        add_error(
          changeset,
          field,
          "Format is not allowed."
        )
      end
    end
  end

  defp validate_lg(changeset, lg, field) do
    valid_lg = [
      "region i - ilocos region",
      "region ii - cagayan valley",
      "region iii - central luzon",
      "region iv-a - calabarzon",
      "region iv-b mimaropa - southwestern tagalog region",
      "car - cordillera administrative region",
      "ncr - national capital region",
      "region v - bicol region",
      "region vi - western visayas",
      "region vii - central visayas",
      "region viii - eastern visayas",
      "region ix - zamboanga peninsula",
      "region x - northern mindanao",
      "region xi - davao region",
      "region xii - soccsksargen",
      "region xiii - caraga region",
      "armm - autonomous region in muslim mindanao",
      # "mimaropa - southwestern tagalog region"
    ]

    result = for lg_record <- lg do
      if Enum.member?(valid_lg, String.downcase(lg_record)) do
        nil
      else
        add_error(
          changeset,
          field,
          "#{lg_record} is invalid."
        )
      end
    end
    |> Enum.uniq
    |> List.delete(nil)

    if not Enum.empty?(result) do
      merge_changeset_errors(result, changeset)
    else
      downcased_lg = for lg_record <- lg do
        String.downcase(lg_record)
      end

      lgs = downcased_lg -- valid_lg

      if Enum.empty?(lgs) do
        changeset
      else
        add_error(
          changeset,
          field,
          "Regions must not be duplicated."
        )
      end
    end

  end

  defp validate_lg_level2(changeset, user, params) do
    changeset =
      changeset
      |> validate_casing_lg

    if changeset.valid? do
      case insert_lg(changeset, user) do
        {:ok, lg} ->
          insert_location_group_region(changeset, lg.id, user)
          {:ok, LocationGroupContext.get_location_group(lg.id)}
        {:error, changeset} ->
          {:error, changeset}
      end

    else
      {:error, changeset}
    end
  end

  defp validate_casing_lg(changeset) do
    location_group =
      changeset.changes[:region]
      |> Enum.map(fn(x) -> String.downcase(x) end)

    lg = for lg <- location_group do
      case lg do
        "ncr" ->
          "NCR"
        "car" ->
          "CAR"
        "armm" ->
          "ARMM"
          lg
        _ ->
          words =
            lg
            |> String.split(" ")
            |> Enum.map(fn(x) -> capitalize_word(x) end)
            |> Enum.join(" ")
            |> find_region
      end
    end

    put_change(changeset, :region, lg)
  end

  defp find_region(word) do
    string_array =
      word
      |> String.split(" ")

    if Enum.at(string_array, 0) == "Region" do
      region = String.upcase(Enum.at(string_array, 1))

      word =
        string_array
        |> List.replace_at(1, region)

      check_island_group(region, word)
    else
      region = String.upcase(Enum.at(string_array, 0))

      word =
        string_array
        |> List.replace_at(0, region)

      check_island_group(region, word)
    end
  end

  defp check_island_group(region, word) do
    word = Enum.join(word, " ")
    valid_luzon = ["I", "II", "III", "IV-A", "IV-B", "V", "CAR", "NCR"]
    valid_visayas = ["VI", "VII", "VIII"]
    valid_mindanao = ["IX", "X", "XI", "XII", "XIII", "ARMM"]
    cond do
      Enum.member?(valid_luzon, region) ->
        "#{word}:Luzon"
      Enum.member?(valid_visayas, region) ->
        "#{word}:Visayas"
      Enum.member?(valid_mindanao, region) ->
        "#{word}:Mindanao"
    end
  end

  defp capitalize_word(word) do
    field =
      word
      |> String.split("")
      |> List.delete("")

    first_letter =
      field
      |> List.first
      |> String.upcase

    field
    |> List.replace_at(0, first_letter)
    |> List.to_string
  end

  defp insert_lg(changeset, user) do
    params =
      changeset.changes
      |> Map.put(:step , "4")
      |> Map.put(:created_by_id, user.id)
      |> Map.put(:updated_by_id, user.id)

    result =
      %LocationGroup{}
      |> LocationGroup.changeset_create(params)
      |> Repo.insert
  end

  defp insert_location_group_region(changeset, lg_id, user) do
    location_group_id = lg_id
    Enum.each(changeset.changes.region, fn region ->

      [a, b] = String.split(region, ":", trim: true)
      location_group_params = %{
        region_name: "#{a}",
        island_group: "#{b}",
        location_group_id: location_group_id,
        created_by_id: user.id,
        updated_by_id: user.id
      }
      location_group_params
      |> LocationGroupRegionContext.create_location_group_region()
    end)
  end

  defp merge_changeset_errors([head | tails], changeset) do
    # Merges errors in changeset.

    prev_changeset = changeset
    new_changeset = head
    merge_changeset_errors(tails, merge(prev_changeset, new_changeset))
  end

  defp merge_changeset_errors([], changeset), do: changeset
end
