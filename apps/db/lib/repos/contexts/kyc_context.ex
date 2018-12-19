defmodule Innerpeace.Db.Base.KycContext do
  @moduledoc false

  import Ecto.Query

  alias Innerpeace.Db.{
    Repo,
    Schemas.KycBank,
    Schemas.File
  }

  def index do
    KycBank
    |> Repo.all()
    |> Repo.preload([:member])
  end

  def get_kyc!(id) do
    KycBank
    |> Repo.get(id)
    |> Repo.preload([:phone, :email, :file])
  end

  def create_kyc(kyc_params \\ %{}) do
    %KycBank{}
    |> KycBank.changeset_step1(kyc_params)
    |> Repo.insert()
  end

  def update_kyc(kyc, kyc_params) do
    if kyc_params["source_of_fund"] == "Income" do
      kyc_params = Map.put(kyc_params, "others", "")
      kyc
      |> KycBank.changeset_step1(kyc_params)
      |> Repo.update()
    else
      kyc
      |> KycBank.changeset_step1(kyc_params)
      |> Repo.update()
    end

  end

  def all_countries do
    [
      "Afghanistan": "Afghanistan",
      "Albania": "Albania",
      "Algeria": "Algeria",
      "Andorra": "Andorra",
      "Angola": "Angola",
      "Antigua and Barbuda": "Antigua and Barbuda",
      "Argentina": "Argentina",
      "Armenia": "Armenia",
      "Australia": "Australia",
      "Austria": "Austria",
      "Azerbaijan": "Azerbaijan",
      "Bahamas": "Bahamas",
      "Bahrain": "Bahrain",
      "Bangladesh": "Bangladesh",
      "Barbados": "Barbados",
      "Belarus": "Belarus",
      "Belgium": "Belgium",
      "Belize": "Belize",
      "Benin": "Benin",
      "Bhutan": "Bhutan",
      "Bolivia": "Bolivia",
      "Bosnia and Herzegovina": "Bosnia and Herzegovina",
      "Botswana": "Botswana",
      "Brazil": "Brazil",
      "Brunei": "Brunei",
      "Bulgaria": "Bulgaria",
      "Burkina Faso": "Burkina Faso",
      "Burundi": "Burundi",
      "Cabo Verde": "Cabo Verde",
      "Cambodia": "Cambodia",
      "Cameroon": "Cameroon",
      "Canada": "Canada",
      "Central African Republic (CAR)": "Central African Republic (CAR)",
      "Chad": "Chad",
      "Chile": "Chile",
      "China": "China",
      "Colombia": "Colombia",
      "Comoros": "Comoros",
      "Democratic Republic of the Congo": "Democratic Republic of the Congo",
      "Republic of the Congo": "Republic of the Congo",
      "Costa Rica": "Costa Rica",
      "Cote d'Ivoire": "Cote d'Ivoire",
      "Croatia": "Croatia",
      "Cuba": "Cuba",
      "Cyprus": "Cyprus",
      "Czech Republic": "Czech Republic",
      "Denmark": "Denmark",
      "Djibouti": "Djibouti",
      "Dominica": "Dominica",
      "Dominican Republic": "Dominican Republic",
      "Ecuador": "Ecuador",
      "Egypt": "Egypt",
      "El Salvador": "El Salvador",
      "Equatorial Guinea": "Equatorial Guinea",
      "Eritrea": "Eritrea",
      "Estonia": "Estonia",
      "Ethiopia": "Ethiopia",
      "Fiji": "Fiji",
      "Finland": "Finland",
      "France": "France",
      "Gabon": "Gabon",
      "Gambia": "Gambia",
      "Georgia": "Georgia",
      "Germany": "Germany",
      "Ghana": "Ghana",
      "Greece": "Greece",
      "Grenada": "Grenada",
      "Guatemala": "Guatemala",
      "Guinea": "Guinea",
      "Guinea-Bissau": "Guinea-Bissau",
      "Guyana": "Guyana",
      "Haiti": "Haiti",
      "Honduras": "Honduras",
      "Hungary": "Hungary",
      "Iceland": "Iceland",
      "India": "India",
      "Indonesia": "Indonesia",
      "Iran": "Iran",
      "Iraq": "Iraq",
      "Ireland": "Ireland",
      "Israel": "Israel",
      "Italy": "Italy",
      "Jamaica": "Jamaica",
      "Japan": "Japan",
      "Jordan": "Jordan",
      "Kazakhstan": "Kazakhstan",
      "Kenya": "Kenya",
      "Kiribati": "Kiribati",
      "Kosovo": "Kosovo",
      "Kuwait": "Kuwait",
      "Kyrgyzstan": "Kyrgyzstan",
      "Laos": "Laos",
      "Latvia": "Latvia",
      "Lebanon": "Lebanon",
      "Lesotho": "Lesotho",
      "Liberia": "Liberia",
      "Libya": "Libya",
      "Liechtenstein": "Liechtenstein",
      "Lithuania": "Lithuania",
      "Luxembourg": "Luxembourg",
      "Macedonia (FYROM)": "Macedonia (FYROM)",
      "Madagascar": "Madagascar",
      "Malawi": "Malawi",
      "Malaysia": "Malaysia",
      "Maldives": "Maldives",
      "Mali": "Mali",
      "Malta": "Malta",
      "Marshall Islands": "Marshall Islands",
      "Mauritania": "Mauritania",
      "Mauritius": "Mauritius",
      "Mexico": "Mexico",
      "Micronesia": "Micronesia",
      "Moldova": "Moldova",
      "Monaco": "Monaco",
      "Mongolia": "Mongolia",
      "Montenegro": "Montenegro",
      "Morocco": "Morocco",
      "Mozambique": "Mozambique",
      "Myanmar (Burma)": "Myanmar (Burma)",
      "Namibia": "Namibia",
      "Nauru": "Nauru",
      "Nepal": "Nepal",
      "Netherlands": "Netherlands",
      "New Zealand": "New Zealand",
      "Nicaragua": "Nicaragua",
      "Niger": "Niger",
      "Nigeria": "Nigeria",
      "North Korea": "North Korea",
      "Norway": "Norway",
      "Oman": "Oman",
      "Pakistan": "Pakistan",
      "Palau": "Palau",
      "Palestine": "Palestine",
      "Panama": "Panama",
      "Papua New Guinea": "Papua New Guinea",
      "Paraguay": "Paraguay",
      "Peru": "Peru",
      "Philippines": "Philippines",
      "Poland": "Poland",
      "Portugal": "Portugal",
      "Qatar": "Qatar",
      "Romania": "Romania",
      "Russia": "Russia",
      "Rwanda": "Rwanda",
      "Saint Kitts and Nevis": "Saint Kitts and Nevis",
      "Saint Lucia": "Saint Lucia",
      "Saint Vincent and the Grenadines": "Saint Vincent and the Grenadines",
      "Samoa": "Samoa",
      "San Marino": "San Marino",
      "Sao Tome and Principe": "Sao Tome and Principe",
      "Saudi Arabia": "Saudi Arabia",
      "Senegal": "Senegal",
      "Serbia": "Serbia",
      "Seychelles": "Seychelles",
      "Sierra Leone": "Sierra Leone",
      "Singapore": "Singapore",
      "Slovakia": "Slovakia",
      "Slovenia": "Slovenia",
      "Solomon Islands": "Solomon Islands",
      "Somalia": "Somalia",
      "South Africa": "South Africa",
      "South Korea": "South Korea",
      "South Sudan": "South Sudan",
      "Spain": "Spain",
      "Sri Lanka": "Sri Lanka",
      "Sudan": "Sudan",
      "Suriname": "Suriname",
      "Swaziland": "Swaziland",
      "Sweden": "Sweden",
      "Switzerland": "Switzerland",
      "Syria": "Syria",
      "Taiwan": "Taiwan",
      "Tajikistan": "Tajikistan",
      "Tanzania": "Tanzania",
      "Thailand": "Thailand",
      "Timor-Leste": "Timor-Leste",
      "Togo": "Togo",
      "Tonga": "Tonga",
      "Trinidad and Tobago": "Trinidad and Tobago",
      "Tunisia": "Tunisia",
      "Turkey": "Turkey",
      "Turkmenistan": "Turkmenistan",
      "Tuvalu": "Tuvalu",
      "Uganda": "Uganda",
      "Ukraine": "Ukraine",
      "United Arab Emirates (UAE)": "United Arab Emirates (UAE)",
      "United Kingdom (UK)": "United Kingdom (UK)",
      "United States of America (USA)": "United States of America (USA)",
      "Uruguay": "Uruguay",
      "Uzbekistan": "Uzbekistan",
      "Vanuatu": "Vanuatu",
      "Vatican City (Holy See)": "Vatican City (Holy See)",
      "Venezuela": "Venezuela",
      "Vietnam": "Vietnam",
      "Yemen": "Yemen",
      "Zambia": "Zambia",
      "Zimbabwe": "Zimbabwe"
    ]
  end

  def update_kyc_step2(kyc, kyc_params) do
    kyc
    |> KycBank.changeset_step2(kyc_params)
    |> Repo.update()
  end

  def update_kyc_step3(kyc, kyc_params) do
    kyc
    |> KycBank.changeset_step3(kyc_params)
    |> Repo.update()
  end

  def update_summary_step(kyc, kyc_params) do
    kyc
    |> KycBank.changeset_summary_step(kyc_params)
    |> Repo.update()
  end

  def get_all_files(kyc_id) do
    File
    |> where([f], f.kyc_bank_id == ^kyc_id)
    |> Repo.delete_all()
  end

  def preload_files(kyc), do: Repo.preload(kyc, :file)

  def insert_front_side(kyc, params) do
    kyc_params = %{
      name: "front-side",
      kyc_bank_id: kyc.id
    }

    with false <- Map.has_key?(params, "front_side") do
      {:ok, kyc}
    else
      _ ->
      filed = Repo.get_by(File, kyc_params)
      if is_nil(filed) == false, do: Repo.delete(filed)

      {_, file} = insert_file(kyc_params)

      update_image(file, params["front_side"])
    end
  end

  def insert_back_side(kyc, params) do
    kyc_params = %{
      name: "back-side",
      kyc_bank_id: kyc.id
    }

    with false <- Map.has_key?(params, "back_side") do
      {:ok, kyc}
    else
      _ ->
      filed = Repo.get_by(File, kyc_params)
      if is_nil(filed) == false, do: Repo.delete(filed)

      {_, file} = insert_file(kyc_params)
      update_image(file, params["back_side"])
    end
  end

  def insert_cir_form(kyc, params) do
    kyc_params = %{
      name: "cir-form",
      kyc_bank_id: kyc.id
    }

    with false <- Map.has_key?(params, "cir_form") do
      {:ok, kyc}
    else
      _ ->
      filed = Repo.get_by(File, kyc_params)
      if is_nil(filed) == false, do: Repo.delete(filed)

      {_, file} = insert_file(kyc_params)
      update_file(file, params["cir_form"])
    end
  end

  def insert_terms_form(kyc, params) do
    kyc_params = %{
      name: "terms-form",
      kyc_bank_id: kyc.id
    }

    with false <- Map.has_key?(params, "terms_form") do
      {:ok, kyc}
    else
      _ ->

      filed = Repo.get_by(File, kyc_params)
      if is_nil(filed) == false, do: Repo.delete(filed)

      {_, file} = insert_file(kyc_params)
      update_file(file, params["terms_form"])
    end
  end

  def insert_file(kyc_params) do
    %File{}
    |> File.changeset_kyc_fields(kyc_params)
    |> Repo.insert()
  end

  def update_image(file, params) do
    file
    |> File.changeset_kyc_upload_image(%{image_type: params})
    |> Repo.update()
  end

  def update_file(file, params) do
    file
    |> File.changeset_kyc_upload_file(%{type: params})
    |> Repo.update()
  end

  def all_cities do
    [
      "Caloocan": "Caloocan",
      "Las Pinas": "Las Pinas",
      "Makati": "Makati",
      "Malabon": "Malabon",
      "Mandaluyong": "Mandaluyong",
      "Manila": "Manila",
      "Marikina": "Marikina",
      "Muntinlupa": "Muntinlupa",
      "Navotas": "Navotas",
      "Paranaque": "Paranaque",
      "Pasay": "Pasay",
      "Pasig": "Pasig",
      "Quezon City": "Quezon City",
      "San Juan": "San Juan",
      "Taguig": "Taguig",
      "Valenzuela": "Valenzuela",
      "Cavite City": "Cavite City",
      "Sta Rosa City": "Sta Rosa City"
    ]
  end

  def delete_kyc(kyc_id) do
    kyc = get_kyc!(kyc_id)
    kyc
    |> Repo.delete()
  end

end
