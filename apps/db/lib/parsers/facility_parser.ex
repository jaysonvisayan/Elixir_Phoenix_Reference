 defmodule Innerpeace.Db.Parsers.FacilityParser do
  @moduledoc false

  alias Innerpeace.Db.{
    Repo,
    Schemas.Facility,
    Schemas.FacilityUploadLog,
    Schemas.FacilityUploadFile,
    Schemas.Contact,
    Schemas.Phone,
    Schemas.Email,
    Schemas.FacilityServiceFee
  }

  alias Innerpeace.Db.Base.{
    FacilityContext,
    ProcedureContext,
    Api.UtilityContext,
    LocationGroupContext,
    CoverageContext,
    DropdownContext,
    EmailContext
  }
  import Ecto.{Query, Changeset}, warn: false
  alias Ecto.Changeset
  def loop_facility_general([], filename, user_id, filename_id), do: {:ok}
  def loop_facility_general([{facility, counter} | tail], filename, user_id, filename_id) do
    {status, facility} = facility
    counter = counter + 2
    with {:ok, facility_params} <- validate_required(facility),
         {:ok, facility_params} <- validate_fields(facility_params)
    do
      facility = FacilityContext.get_facility_by_code(facility_params.code)
      if is_nil(facility) do
        {:ok, p} = %Facility{} |>  Facility.changeset_batch_upload(facility_params) |> Repo.insert
        lg = facility_params.location_group |> String.split(",")
        Enum.each(lg, fn(location_group) ->
          location_group_id = LocationGroupContext.get_location_group_by_name(location_group).id
          FacilityContext.insert_facility_location_group(%{
            facility_id: p.id,
            location_group_id: location_group_id
          })
        end)

        if number_count(facility_params.sf_coverage) != 0 do
          sf_coverage = String.split(facility_params.sf_coverage, ",")
          sf_payment_mode = String.split(facility_params.sf_payment_mode, ",")
          service_fee = String.split(facility_params.service_fee, ",")
          sf_rate = String.split(facility_params.sf_rate, ",")

          sf_array =
            Enum.map(sf_coverage, fn(a) ->
              sf_enum =
                Enum.map(service_fee, fn(b) ->
                  sfpm_enum =
                    Enum.map(sf_payment_mode, fn(c) ->
                      sfr_enum =
                        Enum.map(sf_rate, fn(d) ->
                          cond do
                            b == "Fixed Fee" ->
                              rate_fixed = d
                              rate_mdr = ""
                            b == "Discount Rate" ->
                              rate_fixed = ""
                              rate_mdr = d
                            true ->
                              rate_fixed = ""
                              rate_mdr = ""
                          end
                          %{coverage_id: CoverageContext.get_coverage_by_name(a).id,
                            payment_mode: c,
                            service_type_id:
                              Innerpeace.Db.Base.Api.FacilityContext.get_facility_service_type_by_text(b),
                            rate_fixed: rate_fixed,
                            rate_mdr: rate_mdr
                          }
                        end)
                      sfr_enum = sfr_enum |> Enum.uniq
                    end)
                  sfpm_enum = sfpm_enum |> Enum.uniq
                end)
              sf_enum = sf_enum |> Enum.uniq
            end)

            sf_array =
              sf_array
              |> Enum.uniq
              |> Enum.uniq
              |> Enum.concat
              |> Enum.concat
              |> Enum.concat
            Enum.each(sf_array, fn(x) ->
              x =
                x
                |> Map.put(:facility_id, p.id)

              %FacilityServiceFee{}
              |> FacilityServiceFee.changeset(x)
              |> Repo.insert()
            end)
        end

            filename_params = %{
              filename: filename,
              user_id: user_id,
              status: "success",
              row: counter,
              remarks: "Facility successfully added",
              facility_id: p.id,
              facility_upload_file_id: filename_id
            }
            record_upload_log(facility_params, filename_params)
      else
            filename_params = %{
              filename: filename,
              user_id: user_id,
              status: "failed",
              row: counter,
              remarks: Enum.join([facility.code, " already exists"]),
              facility_id: "",
              facility_upload_file_id: filename_id
            }
            record_upload_log(facility_params, filename_params)
      end

    else
      {:invalid, facility_params} ->

        error_remarks = ""

        error_remarks = validate_step1_required(facility_params, error_remarks)
        error_remarks = validate_step2a_required(facility_params, error_remarks)
        error_remarks = validate_step2b_required(facility_params, error_remarks)
        error_remarks = validate_step4a_required(facility_params, error_remarks)
        error_remarks = validate_step4b_required(facility_params, error_remarks)

        error_length = String.length(error_remarks)
        error_remarks = String.slice(error_remarks, 0..error_length - 3)

        filename_params = %{
          filename: filename,
          user_id: user_id,
          status: "failed",
          row: counter,
          remarks: error_remarks,
          facility_id: "",
          facility_upload_file_id: filename_id
        }
        record_upload_log(facility_params, filename_params)
      {:invalid, facility_params, error_remarks} ->
        error_length = String.length(error_remarks)
        error_remarks = String.slice(error_remarks, 0..error_length - 3)

        filename_params = %{
          filename: filename,
          user_id: user_id,
          status: "failed",
          row: counter,
          remarks: error_remarks,
          facility_id: "",
          facility_upload_file_id: filename_id
        }
        record_upload_log(facility_params, filename_params)
    end

      tail
      |> loop_facility_general(filename, user_id, filename_id)
  end

  defp insert_mobile(mobile_array, contact_id) do
    for mobile <- mobile_array do
      params = %{
        type: "mobile",
        number: mobile.number,
        country_code: mobile.country_code,
        contact_id: contact_id
      }

      %Phone{}
      |> Phone.changeset(params)
      |> Repo.insert!()
    end
  end

  defp insert_telephone(telephone_array, contact_id) do
    for telephone <- telephone_array do
      params = %{
        type: "telephone",
        number: telephone.number,
        country_code: telephone.country_code,
        area_code: telephone.area_code,
        local: telephone.local,
        contact_id: contact_id
      }

      %Phone{}
      |> Phone.changeset(params)
      |> Repo.insert!()
    end
  end

  defp insert_fax(fax_array, contact_id) do
    for fax <- fax_array do
      params = %{
        type: "fax",
        number: fax.number,
        country_code: fax.country_code,
        area_code: fax.area_code,
        local: fax.local,
        contact_id: contact_id
      }
      %Phone{}
      |> Phone.changeset(params)
      |> Repo.insert!()
    end
  end

  defp create_email(params) do
    %Email{}
    |> Email.changeset(params)
    |> Repo.insert()
  end

  defp insert_email(email, contact_id) do
      create_email(%{
         contact_id: contact_id,
         address: email,
         type: ""
       })
  end

  def loop_facility_contacts([], filename, user_id, filename_id), do: {:ok}
  def loop_facility_contacts([{facility, counter} | tail], filename, user_id, filename_id) do
    {status, facility} = facility
    counter = counter + 2
    with {:ok, facility_params} <- validate_required_contacts(facility),
         {:ok, facility_params} <- validate_fields_contacts(facility_params)
    do
      facility = FacilityContext.get_facility_by_code(facility_params.facility_code)
      if is_nil(facility) do
            filename_params = %{
              filename: filename,
              user_id: user_id,
              status: "failed",
              remarks: "Facility does not exists.",
              facility_id: "",
              facility_upload_file_id: filename_id
            }
            record_contacts_upload_log(facility_params, filename_params)
      else
        contact_params =
        %{
          first_name: facility_params.first_name,
          last_name: facility_params.last_name,
          department: facility_params.department,
          designation: facility_params.designation,
          email: facility_params.email_address
        }
        contact =
        %Contact{}
        |> Contact.facility_contact_changeset(contact_params)
        |> Repo.insert!()
        params =
            %{
              facility_id: facility.id,
              contact_id: contact.id
            }
        FacilityContext.create_facility_contact(params)

        mobile_no = String.split(facility_params.mobile_no, ",")
        mobile_cc = String.split(facility_params.mobile_cc, ",")
        mobile_array =
          Enum.map(mobile_cc, fn(a) ->
            mno_enum = Enum.map(mobile_no, fn(b) ->
              %{number: b, country_code: a}
            end)
            mno_enum = mno_enum |> Enum.uniq
          end)

        mobile_array = mobile_array |> Enum.concat

        insert_mobile(mobile_array, contact.id)
        if number_count(facility_params.telephone_no) != 0 do
          telephone_no = String.split(facility_params.telephone_no, ",")
          telephone_cc = String.split(facility_params.telephone_cc, ",")
          telephone_ac = String.split(facility_params.telephone_ac, ",")
          telephone_l = String.split(facility_params.telephone_l, ",")

          telephone_array =
            Enum.map(telephone_cc, fn(a) ->
              tno_enum =
                Enum.map(telephone_no, fn(b) ->
                  tac_enum =
                    Enum.map(telephone_ac, fn(c) ->
                      tl_enum =
                        Enum.map(telephone_l, fn(d) ->
                          %{number: b, country_code: a, area_code: c, local: d}
                        end)
                      tl_enum = tl_enum |> Enum.uniq
                    end)
                  tac_enum = tac_enum |> Enum.uniq
                end)
              tno_enum = tno_enum |> Enum.uniq
            end)

            telephone_array =
              telephone_array
              |> Enum.uniq
              |> Enum.uniq
              |> Enum.concat
              |> Enum.concat
              |> Enum.concat

          insert_telephone(telephone_array, contact.id)
        end

        if number_count(facility_params.fax_no) != 0 do
          fax_no = String.split(facility_params.fax_no, ",")
          fax_cc = String.split(facility_params.fax_cc, ",")
          fax_ac = String.split(facility_params.fax_ac, ",")
          fax_l = String.split(facility_params.fax_l, ",")

          fax_array =
            Enum.map(fax_cc, fn(a) ->
              fno_enum =
                Enum.map(fax_no, fn(b) ->
                  fac_enum =
                    Enum.map(fax_ac, fn(c) ->
                      fl_enum =
                        Enum.map(fax_l, fn(d) ->
                          %{number: b, country_code: a, area_code: c, local: d}
                        end)
                      fl_enum = fl_enum |> Enum.uniq
                    end)
                  fac_enum = fac_enum |> Enum.uniq
                end)
              fno_enum = fno_enum |> Enum.uniq
            end)

            fax_array =
              fax_array
              |> Enum.uniq
              |> Enum.uniq
              |> Enum.concat
              |> Enum.concat
              |> Enum.concat

          insert_fax(fax_array, contact.id)
          insert_email(facility_params.email_address, contact.id)
        end

            filename_params = %{
              filename: filename,
              user_id: user_id,
              status: "success",
              remarks: Enum.join(["Successfully added contacts to ", facility.code]),
              row: counter,
              facility_id: "",
              facility_upload_file_id: filename_id
            }
            record_contacts_upload_log(facility_params, filename_params)
      end

    else
      {:invalid, facility_params} ->

        error_remarks = ""

        error_remarks = validate_contacts_required(facility_params, error_remarks)

        error_length = String.length(error_remarks)
        error_remarks = String.slice(error_remarks, 0..error_length - 3)

        filename_params = %{
          filename: filename,
          user_id: user_id,
          status: "failed",
          remarks: error_remarks,
          row: counter,
          facility_id: "",
          facility_upload_file_id: filename_id
        }
        record_contacts_upload_log(facility_params, filename_params)
      {:invalid, facility_params, error_remarks} ->
        error_length = String.length(error_remarks)
        error_remarks = String.slice(error_remarks, 0..error_length - 3)

        filename_params = %{
          filename: filename,
          user_id: user_id,
          status: "failed",
          remarks: error_remarks,
          row: counter,
          facility_id: "",
          facility_upload_file_id: filename_id
        }
        record_contacts_upload_log(facility_params, filename_params)
    end

      tail
      |> loop_facility_contacts(filename, user_id, filename_id)
  end

  defp validate_contacts_required(facility_params, error_remarks) do
    if facility_params.facility_code == "" do
      error_remarks = Enum.join([error_remarks, "Facility Code is required", ", "])
    end

    if facility_params.first_name == "" do
      error_remarks = Enum.join([error_remarks, "First Name is required", ", "])
    end

    if facility_params.last_name == "" do
      error_remarks = Enum.join([error_remarks, "Last Name is required", ", "])
    end

    if facility_params.mobile_cc == "" do
      error_remarks = Enum.join([error_remarks, "Mobile Country Code is required", ", "])
    end

    if facility_params.mobile_no == "" do
      error_remarks = Enum.join([error_remarks, "Mobile Number is required", ", "])
    end

    if facility_params.email_address == "" do
      error_remarks = Enum.join([error_remarks, "Email Address is required", ", "])
    end
      error_remarks
  end

  defp validate_step1_required(facility_params, error_remarks) do
    if facility_params.code == "" do
      error_remarks = Enum.join([error_remarks, "Facility Code is required", ", "])
    end

    if facility_params.name == "" do
      error_remarks = Enum.join([error_remarks, "Facility Name is required", ", "])
    end

    if facility_params.type == "" do
      error_remarks = Enum.join([error_remarks, "Facility Type is required", ", "])
    end

    if facility_params.category == "" do
      error_remarks = Enum.join([error_remarks, "Facility Category is required", ", "])
    end

    if facility_params.status == "" do
      error_remarks = Enum.join([error_remarks, "Status is required", ", "])
    end
      error_remarks
  end

  defp validate_step2a_required(facility_params, error_remarks) do
    if facility_params.line_1 == "" do
      error_remarks = Enum.join([error_remarks, "Addresss Line 1 is required", ", "])
    end

    if facility_params.city == "" do
      error_remarks = Enum.join([error_remarks, "City/Municpal is required", ", "])
    end

    if facility_params.province == "" do
      error_remarks = Enum.join([error_remarks, "Province is required", ", "])
    end

    if facility_params.region == "" do
      error_remarks = Enum.join([error_remarks, "Region is required", ", "])
    end

    if facility_params.country == "" do
      error_remarks = Enum.join([error_remarks, "Country is required", ", "])
    end

    error_remarks
  end

  defp validate_step2b_required(facility_params, error_remarks) do
    if facility_params.postal_code == "" do
      error_remarks = Enum.join([error_remarks, "Postal Code is required", ", "])
    end

    if facility_params.longitude == "" do
      error_remarks = Enum.join([error_remarks, "Longitude is required", ", "])
    end

    if facility_params.latitude == "" do
      error_remarks = Enum.join([error_remarks, "Latitude is required", ", "])
    end

    if facility_params.location_group == "" do
      error_remarks = Enum.join([error_remarks, "Location Group is required", ", "])
    end

    error_remarks
  end

  defp validate_step4a_required(facility_params, error_remarks) do
    if facility_params.tin == "" do
      error_remarks = Enum.join([error_remarks, "TIN is required", ", "])
    end

    if facility_params.vat_status == "" do
      error_remarks = Enum.join([error_remarks, "VAT Status is required", ", "])
    end

    if facility_params.prescription_term == "" do
      error_remarks = Enum.join([error_remarks, "Prescription Term is required", ", "])
    end

    if facility_params.prescription_clause == "" do
      error_remarks = Enum.join([error_remarks, "Prescription Clause is required", ", "])
    end

    if facility_params.credit_term == "" do
      error_remarks = Enum.join([error_remarks, "Credit Term is required", ", "])
    end

    if facility_params.credit_limit == "" do
      error_remarks = Enum.join([error_remarks, "Credit Limit is required", ", "])
    end
      error_remarks
  end

  defp validate_step4b_required(facility_params, error_remarks) do
    if facility_params.payment_mode == "" do
      error_remarks = Enum.join([error_remarks, "Mode of Payment is required", ", "])
    end

    if facility_params.releasing_mode == "" do
      error_remarks = Enum.join([error_remarks, "Mode of Releasing is required", ", "])
    end
    if facility_params.withholding_tax == "" do
      error_remarks = Enum.join([error_remarks, "Withholding Tax is required", ", "])
    end

    if facility_params.authority_to_credit == "" do
      error_remarks = Enum.join([error_remarks, "Authority to Credit is required", ", "])
    end

    if facility_params.balance_biller == "" do
      error_remarks = Enum.join([error_remarks, "Balance Biller is required", ", "])
    end
      error_remarks
  end

  def parse_data(data, upload_type, filename, user_id) do
    batch_no = FacilityContext.get_facility_upload_logs
      |> Enum.count

    file_params = %{
     filename: filename,
      created_by_id: user_id,
      batch_number: FacilityContext.generate_facility_batch_no(batch_no),
      remarks: "ok"
    }
    {:ok, f} = %FacilityUploadFile{} |> FacilityUploadFile.changeset(file_params) |> Repo.insert

    if upload_type == "Contacts" do
      keys =
      ["Facility Code",
      "First Name",
      "Last Name",
      "Department",
      "Designation",
      "Telephone Country Code",
      "Telephone Area Code",
      "Telephone Number",
      "Telephone Local",
      "Mobile Country Code",
      "Mobile Number",
      "Fax Country Code",
      "Fax Area Code",
      "Fax Number",
      "Fax Local",
      "Email Address"
      ]
      with {:ok, map} <- Enum.at(data, 0),
           {:equal} <- column_checker(keys, map)
      do
        facility_array =
          data
          |> Enum.to_list
          |> Enum.with_index
          |> loop_facility_contacts(filename, user_id, f.id)
      else
        false ->
          {:empty}
        nil ->
          {:empty}
        {:not_equal} ->
          {:not_equal}
      end
    else
      keys =
      ["Facility Code",
      "Facility Name",
      "Facility Type",
      "Facility Category",
      "License Name",
      "PHIC Accreditation From",
      "PHIC Accreditation To",
      "PHIC Accreditation Number",
      "Status",
      "Affiliation Date",
      "Phone Number",
      "Email Address",
      "Website",
      "Address Line 1",
      "Address Line 2",
      "City/Municpal",
      "Province",
      "Region",
      "Country",
      "Postal Code",
      "Longitude",
      "Latitude",
      "Location Group",
      "TIN",
      "VAT Status",
      "Prescription Term",
      "Prescription Clause",
      "Credit Term",
      "Credit Limit",
      "Mode of Payment",
      "Mode of Releasing",
      "Withholding Tax",
      "Number of Beds",
      "Bond",
      "Bank Account Number",
      "Payee Name",
      "Balance Biller",
      "Authority to Credit",
      "Service Fee Coverage",
      "Service Fee Mode of Payment",
      "Service Fee",
      "Service Fee Rate"
      ]

      with {:ok, map} <- Enum.at(data, 0),
           {:equal} <- column_checker(keys, map)
      do
        facility_array =
          data
          |> Enum.to_list
          |> Enum.with_index
          |> loop_facility_general(filename, user_id, f.id)
      else
        false ->
          {:empty}
        nil ->
          {:empty}
        {:not_equal} ->
          {:not_equal}
      end
    end
  end

  def record_upload_log(facility_params, filename_params) do
    facility_log_params = %{
      filename: filename_params.filename,
      facility_code: facility_params.code,
      facility_name: facility_params.name,
      row: filename_params.row,
      status: filename_params.status,
      remarks: filename_params.remarks,
      created_by_id: filename_params.user_id,
      facility_id: filename_params.facility_id,
      facility_upload_file_id: filename_params.facility_upload_file_id
    }
    %FacilityUploadLog{} |> FacilityUploadLog.changeset(facility_log_params) |> Repo.insert
  end

  def record_contacts_upload_log(facility_params, filename_params) do
    facility_log_params = %{
      filename: filename_params.filename,
      facility_code: facility_params.facility_code,
      # facility_name: facility_params.facility_name,
      # upload_type: facility_params.upload_type,
      row: filename_params.row,
      status: filename_params.status,
      remarks: filename_params.remarks,
      created_by_id: filename_params.user_id,
      facility_id: filename_params.facility_id,
      facility_upload_file_id: filename_params.facility_upload_file_id
    }
    %FacilityUploadLog{} |> FacilityUploadLog.changeset(facility_log_params) |> Repo.insert
  end

  defp trim_string(string) do
    if is_nil(string) do
      string
    else
      String.trim(string)
    end
  end

  defp validate_required(facility_params) do

    params = %{
      code: trim_string(facility_params["Facility Code"]),
      name: trim_string(facility_params["Facility Name"]),
      type: trim_string(facility_params["Facility Type"]),
      category: trim_string(facility_params["Facility Category"]),
      license_name: trim_string(facility_params["License Name"]),
      phic_accreditation_from: trim_string(facility_params["PHIC Accreditation From"]),
      phic_accreditation_to: trim_string(facility_params["PHIC Accreditation To"]),
      phic_accreditation_no: trim_string(facility_params["PHIC Accreditation Number"]),
      status: trim_string(facility_params["Status"]),
      affiliation_date: trim_string(facility_params["Affiliation Date"]),
      phone_no: trim_string(facility_params["Phone Number"]),
      email_address: trim_string(facility_params["Email Address"]),
      website: trim_string(facility_params["Website"]),
      line_1: trim_string(facility_params["Address Line 1"]),
      line_2: trim_string(facility_params["Address Line 2"]),
      city: trim_string(facility_params["City/Municpal"]),
      province: trim_string(facility_params["Province"]),
      region: trim_string(facility_params["Region"]),
      country: trim_string(facility_params["Country"]),
      postal_code: trim_string(facility_params["Postal Code"]),
      longitude: trim_string(facility_params["Longitude"]),
      latitude: trim_string(facility_params["Latitude"]),
      location_group: trim_string(facility_params["Location Group"]),
      tin: trim_string(facility_params["TIN"]),
      vat_status: trim_string(facility_params["VAT Status"]),
      prescription_term: trim_string(facility_params["Prescription Term"]),
      prescription_clause: trim_string(facility_params["Prescription Clause"]),
      credit_term: trim_string(facility_params["Credit Term"]),
      credit_limit: trim_string(facility_params["Credit Limit"]),
      no_of_beds: trim_string(facility_params["Number of Beds"]),
      bond: trim_string(facility_params["Bond"]),
      payee_name: trim_string(facility_params["Payee Name"]),
      bank_account_no: trim_string(facility_params["Bank Account Number"]),
      payment_mode: trim_string(facility_params["Mode of Payment"]),
      releasing_mode: trim_string(facility_params["Mode of Releasing"]),
      withholding_tax: trim_string(facility_params["Withholding Tax"]),
      balance_biller: trim_string(facility_params["Balance Biller"]),
      authority_to_credit: trim_string(facility_params["Authority to Credit"]),
      sf_coverage: trim_string(facility_params["Service Fee Coverage"]),
      sf_payment_mode: trim_string(facility_params["Service Fee Mode of Payment"]),
      service_fee: trim_string(facility_params["Service Fee"]),
      sf_rate: trim_string(facility_params["Service Fee Rate"])
    }

    data = %{}
    general_types = %{
      code: :string,
      name: :string,
      type: :string,
      category: :string,
      license_name: :string,
      phic_accreditation_from: :string,
      phic_accreditation_to: :string,
      phic_accreditation_no: :string,
      status: :string,
      affiliation_date: :string,
      phone_no: :string,
      email_address: :string,
      website: :string,
      line_1: :string,
      line_2: :string,
      city: :string,
      province: :string,
      region: :string,
      country: :string,
      postal_code: :string,
      longitude: :string,
      latitude: :string,
      location_group: :string,
      tin: :string,
      vat_status: :string,
      prescription_clause: :string,
      prescription_term: :string,
      credit_term: :string,
      credit_limit: :string,
      no_of_beds: :string,
      bond: :decimal,
      payee_name: :string,
      withholding_tax: :string,
      bank_account_no: :string,
      balance_biller: :string,
      authority_to_credit: :string,
      payment_mode: :string,
      releasing_mode: :string,
      sf_coverage: :string,
      sf_rate: :string,
      sf_payment_mode: :string,
      service_fee: :string
    }
    changeset =
      {data, general_types}
      |> Changeset.cast(params, Map.keys(general_types))
      |> Changeset.validate_required([
        :code,
        :name,
        :type,
        :status,
        :city,
        :province,
        :region,
        :country,
        :postal_code,
        :longitude,
        :latitude,
        :tin,
        :prescription_term,
        :credit_term,
        :credit_limit,
        :withholding_tax,
        :balance_biller,
        :authority_to_credit,
        :vat_status,
        :prescription_clause,
        :payment_mode,
        :releasing_mode,
        :category,
        :prescription_clause,
        :location_group
      ])

    if changeset.valid? do
      {:ok, params}
    else
      {:invalid, params}
    end
  end

  defp validate_required_contacts(facility_params) do
    params = %{
      facility_code: trim_string(facility_params["Facility Code"]),
      first_name: trim_string(facility_params["First Name"]),
      last_name: trim_string(facility_params["Last Name"]),
      department: trim_string(facility_params["Department"]),
      designation: trim_string(facility_params["Designation"]),
      telephone_cc: trim_string(facility_params["Telephone Country Code"]),
      telephone_ac: trim_string(facility_params["Telephone Area Code"]),
      telephone_no: trim_string(facility_params["Telephone Number"]),
      telephone_l: trim_string(facility_params["Telephone Local"]),
      mobile_cc: trim_string(facility_params["Mobile Country Code"]),
      mobile_no: trim_string(facility_params["Mobile Number"]),
      fax_cc: trim_string(facility_params["Fax Country Code"]),
      fax_ac: trim_string(facility_params["Fax Area Code"]),
      fax_no: trim_string(facility_params["Fax Number"]),
      fax_l: trim_string(facility_params["Fax Local"]),
      email_address: trim_string(facility_params["Email Address"])
    }

    data = %{}
    general_types = %{
      facility_code: :string,
      first_name: :string,
      last_name: :string,
      department: :string,
      designation: :string,
      telephone_cc: :string,
      telephone_ac: :string,
      telephone_no: :string,
      telephone_l: :string,
      mobile_cc: :string,
      mobile_no: :string,
      fax_cc: :string,
      fax_ac: :string,
      fax_no: :string,
      fax_l: :string,
      email_address: :string
    }
    changeset =
      {data, general_types}
      |> Changeset.cast(params, Map.keys(general_types))
      |> Changeset.validate_required([
        :facility_code,
        :first_name,
        :last_name,
        :mobile_no,
        :email_address
      ])

    if changeset.valid? do
      {:ok, params}
    else
      {:invalid, params}
    end
  end

  def validate_fields(facility_params) do
    error_remarks = ""

    {error_remarks, facility_params} =
      validate_phone_no(facility_params.phone_no, error_remarks, facility_params)
    {error_remarks, facility_params} =
      validate_website(facility_params.website, error_remarks, facility_params)
    {error_remarks, facility_params} =
      validate_email(facility_params.email_address, error_remarks, facility_params)
    {error_remarks, facility_params} =
      validate_status(facility_params.status, error_remarks, facility_params)
    {error_remarks, facility_params} =
      validate_balance_biller(facility_params.balance_biller, error_remarks, facility_params)
    {error_remarks, facility_params} =
      validate_authority(facility_params.authority_to_credit, error_remarks, facility_params)
    {error_remarks, facility_params} =
      validate_category(facility_params.category, error_remarks, facility_params)
    {error_remarks, facility_params} =
      validate_type(facility_params.type, error_remarks, facility_params)
    {error_remarks, facility_params} =
      validate_vat_status(facility_params.vat_status, error_remarks, facility_params)
    {error_remarks, facility_params} =
      validate_prescription_clause(facility_params.prescription_clause, error_remarks, facility_params)
    {error_remarks, facility_params} =
      validate_payment_mode1(facility_params.payment_mode, facility_params.bank_account_no,
        facility_params.payee_name, error_remarks, facility_params)
    {error_remarks, facility_params} =
      validate_payment_mode2(facility_params.payment_mode, facility_params.bank_account_no,
        facility_params.payee_name, error_remarks, facility_params)
    {error_remarks, facility_params} =
      validate_releasing_mode(facility_params.releasing_mode, error_remarks, facility_params)
    {error_remarks, facility_params} =
      validate_affiliation_date(facility_params.affiliation_date, error_remarks, facility_params)
    {error_remarks, facility_params} =
      validate_phc_no(facility_params.phic_accreditation_no, error_remarks, facility_params)
    {error_remarks, facility_params} =
      validate_phic_accreditation_from(facility_params.phic_accreditation_from, error_remarks, facility_params)
    {error_remarks, facility_params} =
      validate_phic_accreditation_to(facility_params.phic_accreditation_to, error_remarks, facility_params)
    {error_remarks, facility_params} =
      validate_tin(facility_params.tin, error_remarks, facility_params)
    {error_remarks, facility_params} =
      validate_location_group(facility_params.location_group, error_remarks, facility_params)
    {error_remarks, facility_params} =
      validate_sf_coverage(facility_params.sf_coverage, error_remarks, facility_params)
    {error_remarks, facility_params} =
      validate_service_fee(facility_params.service_fee, facility_params.sf_coverage, error_remarks, facility_params)
    {error_remarks, facility_params} =
      validate_sf_rate(facility_params.sf_rate, facility_params.sf_coverage, error_remarks, facility_params)
    {error_remarks, facility_params} =
      validate_sf_payment_mode(facility_params.sf_payment_mode,
        facility_params.sf_coverage, error_remarks, facility_params)

    if error_remarks == "" do
      {:ok, facility_params}
    else
      {:invalid, facility_params, error_remarks}
    end
  end

  defp validate_first_name(first_name, error_remarks, facility_params) do
    if Regex.match?(~r/^[-:a-zA-Z0-9() ]+$/, first_name) == false do
      error_remarks = Enum.join([error_remarks, "Invalid First Name", ", "])
    end
    {error_remarks, facility_params}
  end

  defp validate_last_name(last_name, error_remarks, facility_params) do
    if Regex.match?(~r/^[-:a-zA-Z0-9() ]+$/, last_name) == false do
      error_remarks = Enum.join([error_remarks, "Invalid Last Name", ", "])
    end
    {error_remarks, facility_params}
  end

  defp telephone_country_code(telephone_cc, error_remarks) do
    tcc =
      Enum.map(String.split(telephone_cc, ","), fn(x) ->
        if String.length(x) > 4 do
          "invalid"
        else
          "valid"
        end
      end)

    if Enum.member?(tcc, "invalid") do
      error_remarks = Enum.join([error_remarks, "Telephone Country Code must be 4 digits or less", ", "])
    end
    error_remarks
  end

  defp validate_tno(telephone_no) do
    Enum.map(String.split(telephone_no, ","), fn(x) ->
      cond do
        Regex.match?(~r/^[0-9]*$/, x) == false ->
          "invalid number"
        String.length(x) != 7 ->
          "invalid length"
        true ->
          "valid"
        end
    end)
  end

  defp validate_telephone_cc(telephone_no, telephone_cc, error_remarks, facility_params) do
    tno_count = number_count(telephone_no)
    tcc_count = number_count(telephone_cc)
    if telephone_no != "" do
      cond do
        telephone_cc == "" ->
          error_remarks = Enum.join([error_remarks, "Telephone Country Code is required", ", "])
        tno_count > tcc_count ->
          error_remarks = Enum.join([error_remarks, "Telephone Country Code is required", ", "])
        tno_count < tcc_count ->
          error_remarks = Enum.join([error_remarks, "Invalid Telephone Country Code Count", ", "])
        true ->
          error_remarks = telephone_country_code(telephone_cc, error_remarks)
      end
    end
    {error_remarks, facility_params}
  end

  defp validate_telephone_no(telephone_no, error_remarks, facility_params) do
    if telephone_no != "" do
      tno = validate_tno(telephone_no)
      if Enum.member?(tno, "invalid number") do
        error_remarks = Enum.join([error_remarks, "Invalid Telephone Number", ", "])
      else
        if Enum.member?(tno, "invalid length") do
          error_remarks = Enum.join([error_remarks, "Telephone Number should be 7 digits", ", "])
        end
      end
    end
    {error_remarks, facility_params}
  end

  defp validate_telephone_ac(telephone_no, telephone_ac, error_remarks, facility_params) do
    tno_count = number_count(telephone_no)
    tac_count = number_count(telephone_ac)
    if tac_count > tno_count do
      error_remarks = Enum.join([error_remarks, "Invalid Telephone Area Code Count", ", "])
    else
      tac =
        Enum.map(String.split(telephone_ac, ","), fn(x) ->
          cond do
            Regex.match?(~r/^[0-9]*$/, x) == false ->
              "invalid number"
            String.length(x) > 4 ->
              "invalid length"
            true ->
              "valid"
            end
        end)
      if Enum.member?(tac, "invalid number") do
        error_remarks = Enum.join([error_remarks, "Invalid Telephone Area Code", ", "])
      else
        if Enum.member?(tac, "invalid length") do
          error_remarks = Enum.join([error_remarks, "Telephone Area Code should be 3 digits or less", ", "])
        end
      end
    end
    {error_remarks, facility_params}
  end

  defp validate_telephone_l(telephone_no, telephone_l, error_remarks, facility_params) do
    tno_count = number_count(telephone_no)
    tl_count = number_count(telephone_l)
    if tl_count > tno_count do
      error_remarks = Enum.join([error_remarks, "Invalid Telephone Local Count", ", "])
    else
      tl =
        Enum.map(String.split(telephone_l, ","), fn(x) ->
          cond do
            Regex.match?(~r/^[0-9]*$/, x) == false ->
              "invalid number"
            String.length(x) > 3 ->
              "invalid length"
            true ->
              "valid"
            end
        end)
      if Enum.member?(tl, "invalid number") do
        error_remarks = Enum.join([error_remarks, "Invalid Telephone Local", ", "])
      else
        if Enum.member?(tl, "invalid length") do
          error_remarks = Enum.join([error_remarks, "Telephone Local should be 2 digits or less", ", "])
        end
      end
    end
    {error_remarks, facility_params}
  end

  defp validate_mobile_no(mobile_no, error_remarks, facility_params) do
      mno =
        Enum.map(String.split(mobile_no, ","), fn(x) ->
          cond do
            Regex.match?(~r/^[0-9]*$/, x) == false ->
              "invalid number"
            String.length(x) != 10 ->
              "invalid length"
            true ->
              "valid"
            end
        end)
      if Enum.member?(mno, "invalid number") do
        error_remarks = Enum.join([error_remarks, "Invalid Mobile Number", ", "])
      else
        if Enum.member?(mno, "invalid length") do
          error_remarks = Enum.join([error_remarks, "Mobile Number should be 10 digits", ", "])
        end
      end
    {error_remarks, facility_params}
  end

  defp mobile_country_code(mobile_cc, error_remarks) do
    mcc =
      Enum.map(String.split(mobile_cc, ","), fn(x) -> if String.length(x) > 4 do "invalid" else "valid" end end)
    if Enum.member?(mcc, "invalid") do
      error_remarks = Enum.join([error_remarks, "Mobile Country Code must be 4 digits or less", ", "])
    end
    error_remarks
  end

  defp validate_mobile_cc(mobile_no, mobile_cc, error_remarks, facility_params) do
    mno_count = number_count(mobile_no)
    mcc_count = number_count(mobile_cc)
    cond do
      mno_count > mcc_count ->
        error_remarks = Enum.join([error_remarks, "Mobile Country Code is required", ", "])
      mno_count < mcc_count ->
        error_remarks = Enum.join([error_remarks, "Invalid Mobile Country Code Count", ", "])
      true ->
        error_remarks = mobile_country_code(mobile_cc, error_remarks)
    end
    {error_remarks, facility_params}
  end

  defp fax_country_code(fax_cc, error_remarks) do
    fcc =
      Enum.map(String.split(fax_cc, ","), fn(x) -> if String.length(x) > 4 do "invalid" else "valid" end end)
    if Enum.member?(fcc, "invalid") do
      error_remarks = Enum.join([error_remarks, "Fax Country Code must be 4 digits or less", ", "])
    end
    error_remarks
  end

  defp validate_fax_cc(fax_no, fax_cc, error_remarks, facility_params) do
    fno_count = number_count(fax_no)
    fcc_count = number_count(fax_cc)
      cond do
        fax_cc == "" and fax_no != "" ->
          error_remarks = Enum.join([error_remarks, "Fax Country Code is required", ", "])
        fax_cc != "" and fax_no == "" ->
          error_remarks = Enum.join([error_remarks, "Fax Number is required", ", "])
        fno_count > fcc_count ->
          error_remarks = Enum.join([error_remarks, "Fax Country Code is required", ", "])
        fno_count < fcc_count ->
          error_remarks = Enum.join([error_remarks, "Invalid Fax Country Code Count", ", "])
        true ->
          error_remarks = fax_country_code(fax_cc, error_remarks)
      end
    {error_remarks, facility_params}
  end

  defp fax_number(fax_no) do
    Enum.map(String.split(fax_no, ","), fn(x) ->
      cond do
        Regex.match?(~r/^[0-9]*$/, x) == false ->
          "invalid number"
        String.length(x) != 7 ->
          "invalid length"
        true ->
          "valid"
        end
    end)
  end

  defp validate_fax_no(fax_no, error_remarks, facility_params) do
    if fax_no != "" do
      fno = fax_number(fax_no)
      if Enum.member?(fno, "invalid number") do
        error_remarks = Enum.join([error_remarks, "Invalid Fax Number", ", "])
      else
        if Enum.member?(fno, "invalid length") do
          error_remarks = Enum.join([error_remarks, "Fax Number should be 7 digits", ", "])
        end
      end
    end
    {error_remarks, facility_params}
  end

  defp validate_fax_ac(fax_no, fax_ac, error_remarks, facility_params) do
    fno_count = number_count(fax_no)
    fac_count = number_count(fax_ac)
    if fac_count > fno_count do
      error_remarks = Enum.join([error_remarks, "Invalid Fax Area Code Count", ", "])
    else
      fac =
        Enum.map(String.split(fax_ac, ","), fn(x) ->
          cond do
            Regex.match?(~r/^[0-9]*$/, x) == false ->
              "invalid number"
            String.length(x) > 4 ->
              "invalid length"
            true ->
              "valid"
            end
        end)
      if Enum.member?(fac, "invalid number") do
        error_remarks = Enum.join([error_remarks, "Invalid Fax Area Code", ", "])
      else
        if Enum.member?(fac, "invalid length") do
          error_remarks = Enum.join([error_remarks, "Fax Area Code should be 3 digits or less", ", "])
        end
      end
    end
    {error_remarks, facility_params}
  end

  defp validate_fax_l(fax_no, fax_l, error_remarks, facility_params) do
    fno_count = number_count(fax_no)
    tl_count = number_count(fax_l)
    if tl_count > fno_count do
      error_remarks = Enum.join([error_remarks, "Invalid Fax Local Count", ", "])
    else
      tl =
        Enum.map(String.split(fax_l, ","), fn(x) ->
          cond do
            Regex.match?(~r/^[0-9]*$/, x) == false ->
              "invalid number"
            String.length(x) > 3 ->
              "invalid length"
            true ->
              "valid"
            end
        end)
      if Enum.member?(tl, "invalid number") do
        error_remarks = Enum.join([error_remarks, "Invalid Fax Local", ", "])
      else
        if Enum.member?(tl, "invalid length") do
          error_remarks = Enum.join([error_remarks, "Fax Local should be 2 digits or less", ", "])
        end
      end
    end
    {error_remarks, facility_params}
  end

  defp number_count(number) do
    if String.split(number, ",") == [""] do
      0
    else
      Enum.count(String.split(number, ","))
    end
  end

  def validate_fields_contacts(facility_params) do
    error_remarks = ""

    {error_remarks, facility_params} =
      validate_first_name(facility_params.first_name, error_remarks, facility_params)
    {error_remarks, facility_params} =
      validate_last_name(facility_params.last_name, error_remarks, facility_params)
    {error_remarks, facility_params} =
      validate_telephone_cc(facility_params.telephone_no, facility_params.telephone_cc, error_remarks, facility_params)
    {error_remarks, facility_params} =
      validate_telephone_no(facility_params.telephone_no, error_remarks, facility_params)
    {error_remarks, facility_params} =
      validate_telephone_ac(facility_params.telephone_no, facility_params.telephone_ac, error_remarks, facility_params)
    {error_remarks, facility_params} =
      validate_telephone_l(facility_params.telephone_no, facility_params.telephone_l, error_remarks, facility_params)
    {error_remarks, facility_params} =
      validate_mobile_cc(facility_params.mobile_no, facility_params.mobile_cc, error_remarks, facility_params)
    {error_remarks, facility_params} =
      validate_mobile_no(facility_params.mobile_no, error_remarks, facility_params)
    {error_remarks, facility_params} =
      validate_fax_cc(facility_params.fax_no, facility_params.fax_cc, error_remarks, facility_params)
    {error_remarks, facility_params} =
      validate_fax_no(facility_params.fax_no, error_remarks, facility_params)
    {error_remarks, facility_params} =
      validate_fax_ac(facility_params.fax_no, facility_params.fax_ac, error_remarks, facility_params)
    {error_remarks, facility_params} =
      validate_fax_l(facility_params.fax_no, facility_params.fax_l, error_remarks, facility_params)
    {error_remarks, facility_params} =
      validate_email(facility_params.email_address, error_remarks, facility_params)

    if error_remarks == "" do
      {:ok, facility_params}
    else
      {:invalid, facility_params, error_remarks}
    end
  end

  defp validate_category(category, error_remarks, facility_params) do
    category = String.upcase(category)
    category =
      Innerpeace.Db.Base.Api.FacilityContext.get_facility_category_by_text(category)
    if is_nil(category) do
      error_remarks = Enum.join([error_remarks, "Invalid Facility Category", ", "])
    else
      facility_params = Map.put(facility_params, :fcategory_id, category)
    end

    {error_remarks, facility_params}
  end

  defp validate_type(type, error_remarks, facility_params) do
    type = String.upcase(type)
    type =
      Innerpeace.Db.Base.Api.FacilityContext.get_facility_type_by_text(type)
    if is_nil(type) do
      error_remarks = Enum.join([error_remarks, "Invalid Facility Type", ", "])
    else
      facility_params = Map.put(facility_params, :ftype_id, type)
    end

    {error_remarks, facility_params}
  end

  defp validate_vat_status(vat_status, error_remarks, facility_params) do
    vat_status = String.capitalize(vat_status)
    vat_status =
      Innerpeace.Db.Base.Api.FacilityContext.get_vat_status_by_text(vat_status)
    if is_nil(vat_status) do
      error_remarks = Enum.join([error_remarks, "Invalid VAT Status", ", "])
    else
      facility_params = Map.put(facility_params, :vat_status_id, vat_status)
    end
    {error_remarks, facility_params}
  end

  defp validate_prescription_clause(prescription_clause, error_remarks, facility_params) do
    prescription_clause =
      Innerpeace.Db.Base.Api.FacilityContext.get_prescription_clause_by_text(prescription_clause)
    if is_nil(prescription_clause) do
      error_remarks = Enum.join([error_remarks, "Invalid Prescription Clause", ", "])
    else
      facility_params = Map.put(facility_params, :prescription_clause_id, prescription_clause)
    end

    {error_remarks, facility_params}
  end

  defp validate_payment_mode1(payment_mode, bank_account_no, payee_name, error_remarks, facility_params) do
    payment_mode =
      Innerpeace.Db.Base.Api.FacilityContext.get_mode_of_payment_by_text(payment_mode)
    cond do
      is_nil(payment_mode) ->
        error_remarks = Enum.join([error_remarks, "Invalid Mode of Payment", ", "])
      payment_mode == "Bank" and bank_account_no != "" ->
        error_remarks = Enum.join([error_remarks, "Bank Account Number is required", ", "])
      payment_mode == "Check" and payee_name != "" ->
        error_remarks = Enum.join([error_remarks, "Payee Name is required", ", "])
      payment_mode == "Auto-Credit" and bank_account_no != "" ->
        error_remarks = Enum.join([error_remarks, "Bank Account Number is required", ", "])
      true ->
        facility_params = Map.put(facility_params, :payment_mode_id, payment_mode)
    end
      {error_remarks, facility_params}
  end

  defp validate_payment_mode2(payment_mode, bank_account_no, payee_name, error_remarks, facility_params) do
    payment_mode =
      Innerpeace.Db.Base.Api.FacilityContext.get_mode_of_payment_by_text(payment_mode)
    cond do
      payment_mode == "Bank" or "payment_mode" == "Auto-Credit" ->
        facility_params = Map.delete(facility_params, :payee_name)
      payment_mode == "Check" ->
        facility_params = Map.delete(facility_params, :bank_account_no)
      true ->
        facility_params = facility_params
    end
    {error_remarks, facility_params}
  end

  defp validate_releasing_mode(releasing_mode, error_remarks, facility_params) do
    releasing_mode =
      Innerpeace.Db.Base.Api.FacilityContext.get_releasing_mode_by_text(releasing_mode)
    if is_nil(releasing_mode) do
      error_remarks = Enum.join([error_remarks, "Invalid Mode of Releasing", ", "])
    else
      facility_params = Map.put(facility_params, :releasing_mode_id, releasing_mode)
    end

    {error_remarks, facility_params}
  end

  defp validate_affiliation_date(affiliation_date, error_remarks, facility_params) do
    case UtilityContext.birth_date_transform(affiliation_date) do
      {:ok, affiliation_date} ->
        facility_params = Map.put(facility_params, :affiliation_date, affiliation_date)
      {:invalid_datetime_format} ->
        error_remarks = Enum.join([error_remarks, "Invalid Affiliation Date", ", "])
    end
    {error_remarks, facility_params}
  end

  defp validate_phone_no(phone_no, error_remarks, facility_params) do
    if phone_no != "" do
      cond do
        Regex.match?(~r/^[0-9]*$/, phone_no) == false ->
          error_remarks = Enum.join([error_remarks, "Invalid Phone Number", ", "])
        String.length(phone_no) != 7 ->
          error_remarks = Enum.join([error_remarks, "Phone Number should be 7-digits", ", "])
        true ->
          error_remarks = error_remarks
      end
    end
    {error_remarks, facility_params}
  end

  defp validate_website(website, error_remarks, facility_params) do
    if website != "" do
      if Regex.match?(~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/, website) == false do
          error_remarks = Enum.join([error_remarks, "Invalid Website", ", "])
      end
    end
    {error_remarks, facility_params}
  end

  defp validate_email(email, error_remarks, facility_params) do
    if email != "" do
      cond do
        Regex.match?(~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/, email) == false ->
          error_remarks = Enum.join([error_remarks, "Invalid Email Address", ", "])
        Enum.empty?(EmailContext.get_email_by_address(email)) == false ->
          error_remarks = Enum.join([error_remarks, "Email Address already exist", ", "])
        true ->
          error_remarks = error_remarks
      end
    end
    {error_remarks, facility_params}
  end

  defp validate_status(status, error_remarks, facility_params) do
    if status != "Pending" and status != "Affiliated" do
      error_remarks = Enum.join([error_remarks, "Invalid Status", ", "])
    end
    {error_remarks, facility_params}
  end

  defp validate_balance_biller(balance_biller, error_remarks, facility_params) do
    cond do
      String.downcase(balance_biller) == "true" ->
        facility_params = Map.put(facility_params, :balance_biller, true)
      String.downcase(balance_biller) == "false" ->
        facility_params = Map.put(facility_params, :balance_biller, false)
      true ->
        error_remarks = Enum.join([error_remarks, "Invalid Balance Biller", ", "])
    end
    {error_remarks, facility_params}
  end

  defp validate_authority(authority, error_remarks, facility_params) do
    cond do
      String.downcase(authority) == "true" ->
        facility_params = Map.put(facility_params, :authority_to_credit, true)
      String.downcase(authority) == "false" ->
        facility_params = Map.put(facility_params, :authority_to_credit, false)
      true ->
        error_remarks = Enum.join([error_remarks, "Invalid Authority to Credit", ", "])
    end
    {error_remarks, facility_params}
  end

  defp validate_phc_no(phc_no, error_remarks, facility_params) do
    if phc_no != "" do
      cond do
        Regex.match?(~r/^[0-9]*$/, phc_no) == false ->
          error_remarks = Enum.join([error_remarks, "Invalid PHC Accreditation Number", ", "])
        String.length(phc_no) != 12 ->
          error_remarks = Enum.join([error_remarks, "PHC Accreditation Number should be 12-digits", ", "])
        true ->
          error_remarks = error_remarks
      end
    end
    {error_remarks, facility_params}
  end

  defp validate_phic_accreditation_from(phic_accreditation_from, error_remarks, facility_params) do
    if phic_accreditation_from != "" do
      case UtilityContext.birth_date_transform(phic_accreditation_from) do
        {:ok, phic_accreditation_from} ->
          facility_params = Map.put(facility_params, :phic_accreditation_from, phic_accreditation_from)
        {:invalid_datetime_format} ->
          error_remarks = Enum.join([error_remarks, "Invalid PHC Accreditation From", ", "])
      end
    end
    {error_remarks, facility_params}
  end

  defp validate_phic_accreditation_to(phic_accreditation_to, error_remarks, facility_params) do
    if phic_accreditation_to != "" do
      case UtilityContext.birth_date_transform(phic_accreditation_to) do
        {:ok, phic_accreditation_to} ->
          facility_params = Map.put(facility_params, :phic_accreditation_to, phic_accreditation_to)
        {:invalid_datetime_format} ->
          error_remarks = Enum.join([error_remarks, "Invalid PHC Accreditation From", ", "])
      end
    end
    {error_remarks, facility_params}
  end

  defp validate_tin(tin, error_remarks, facility_params) do
    cond do
      Regex.match?(~r/^[0-9]*$/, tin) == false ->
        error_remarks = Enum.join([error_remarks, "Invalid TIN", ", "])
      String.length(tin) != 12 ->
        error_remarks = Enum.join([error_remarks, "TIN should be 12-digits", ", "])
      true ->
        error_remarks = error_remarks
    end
    {error_remarks, facility_params}
  end

  defp validate_location_group(location_group, error_remarks, facility_params) do
    lg = String.split(location_group, ",")
    location_group = Enum.map(lg, fn(x) ->
      LocationGroupContext.get_location_group_by_name(x)
    end)

    if Enum.member?(location_group, nil) do
      error_remarks = Enum.join([error_remarks, "Location Group does not exist", ", "])
    end
    {error_remarks, facility_params}
  end

  defp validate_sf_coverage(service_fee_coverage, error_remarks, facility_params) do
    if number_count(service_fee_coverage) != 0 do
      service_fee_coverage = service_fee_coverage |> String.split(",")
      sf_coverage = Enum.map(service_fee_coverage, fn(x) ->
        CoverageContext.get_coverage_by_name(x)
      end)
      if Enum.member?(sf_coverage, nil) do
        error_remarks = Enum.join([error_remarks, "Invalid Service Fee Coverage", ", "])
      end
    end
    {error_remarks, facility_params}
  end

  defp validate_sf_payment_mode(sf_payment_mode, sf_coverage, error_remarks, facility_params) do
    if number_count(sf_coverage) != 0 do
      cond do
        number_count(sf_coverage) > number_count(sf_payment_mode) ->
          error_remarks = Enum.join([error_remarks, "Service Fee Payment Mode is required", ", "])
        number_count(sf_coverage) < number_count(sf_payment_mode) ->
          error_remarks = Enum.join([error_remarks, "Invalid Service Fee Mode of Payment Count", ", "])
        Enum.member?(check_sf_payment_mode_map(sf_payment_mode), "invalid") ->
          error_remarks = Enum.join([error_remarks, "Invalid Service Fee Payment Mode", ", "])
        true ->
          error_remarks = error_remarks
      end
    end
    {error_remarks, facility_params}
  end

  defp check_map_if_number(map) do
    map = map |> String.split(",")
    Enum.map(map, fn(x) ->
      if Regex.match?(~r/^[0-9]*$/, x) == false do
        "invalid"
      end
    end)
  end

  defp check_sf_payment_mode_map(map) do
    map = map |> String.split(",")
    Enum.map(map, fn(x) ->
      if x != "Umbrella" and x != "Individual" do
        "invalid"
      end
    end)
  end

  defp check_sf_map(map) do
    map = map |> String.split(",")
    Enum.map(map, fn(x) ->
      if x != "Fixed Fee" and x != "No Discount Rate" and x != "Discount Rate" do
        "invalid"
      end
    end)
  end

  defp validate_service_fee(service_fee, sf_coverage, error_remarks, facility_params) do
    if number_count(sf_coverage) != 0 do
      cond do
        number_count(sf_coverage) > number_count(service_fee) ->
          error_remarks = Enum.join([error_remarks, "Service Fee is required", ", "])
        number_count(sf_coverage) < number_count(service_fee) ->
          error_remarks = Enum.join([error_remarks, "Invalid Service Fee Count", ", "])
        Enum.member?(check_sf_map(service_fee), "invalid") ->
          error_remarks = Enum.join([error_remarks, "Invalid Service Fee", ", "])
        true ->
          error_remarks = error_remarks
      end
    end
    {error_remarks, facility_params}
  end

  defp validate_sf_rate(sf_rate, sf_coverage, error_remarks, facility_params) do
    if number_count(sf_coverage) != 0 do
      cond do
        number_count(sf_coverage) > number_count(sf_rate) ->
          error_remarks = Enum.join([error_remarks, "Service Fee Rate is required", ", "])
        number_count(sf_coverage) < number_count(sf_rate) ->
          error_remarks = Enum.join([error_remarks, "Invalid Service Fee Rate Count", ", "])
        Enum.member?(check_map_if_number(sf_rate), "invalid") ->
          error_remarks = Enum.join([error_remarks, "Invalid Service Fee Rate", ", "])
        true ->
          error_remarks = error_remarks
      end
    end
    {error_remarks, facility_params}
  end

  defp column_checker(keys, map) do
    if Enum.sort(keys) == Enum.sort(Map.keys(map)) do
      {:equal}
    else
      {:not_equal}
    end
  end

end
