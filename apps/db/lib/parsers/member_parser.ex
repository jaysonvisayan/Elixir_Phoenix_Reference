defmodule Innerpeace.Db.Parsers.MemberParser do
  @moduledoc false

  import Ecto.{Query, Changeset}, warn: false

  alias Innerpeace.Db.{
    Repo,
    Schemas.Account,
    Schemas.AccountGroup,
    Schemas.Member,
    Schemas.Product,
    Schemas.MemberUploadLog,
    Schemas.MemberUploadFile
  }

  alias Innerpeace.Db.Base.{
    Api.UtilityContext,
    ProductContext,
    AccountContext,
    MemberContext,
    AccountContext
  }

  alias Innerpeace.Db.Schemas.File, as: UploadFile
  alias Innerpeace.Db.Repo
  import Ecto.Query

  #MEMBER PHOTO FILE UPLOAD

  def upload_a_photo(member_id, param, user) do
    pathsample = case Application.get_env(:db, :env) do
      :test ->
        Path.expand('./../../uploads/images/')
      :dev ->
        Path.expand('./uploads/images/')
      :prod ->
        Path.expand('./uploads/images/')
      _ ->
        nil
    end

    File.mkdir_p!(Path.expand('./uploads/images'))
    File.write!(pathsample <> "/ACUScheduleMember_#{param["file_name"]}.#{param["extension"]}", Base.decode64!(param["base_64_encoded"]))

    {:ok, member} = update_a_photo(member_id, param, user)

    File.rm_rf(pathsample <> "/ACUScheduleMember_#{param["file_name"]}.#{param["extension"]}")
    {:ok, member}
  end

  def update_a_photo(member_id, param, user) do
    member = MemberContext.get_member!(member_id)

    path = case Application.get_env(:db, :env) do
      :test ->
        Path.expand('./../../uploads/images/')
      :dev ->
        Path.expand('./uploads/images/')
      :prod ->
        Path.expand('./uploads/images/')
      _ ->
        nil
    end

    file_path = "ACUScheduleMember_#{param["file_name"]}.#{param["extension"]}"
    member_params =
      %{
        photo: %Plug.Upload{
          content_type: param["content_type"],
          path: "#{path}/#{file_path}",
          filename: file_path
        }
      }

    MemberContext.update_member_photo(member, member_params)
  end

  def parse_data(data, filename, user_id, upload_type, account_code) do
    data = Enum.drop(data, 1)
    batch_no =
      MemberContext.get_member_upload_logs()
      |> Enum.count()
      |> MemberContext.generate_batch_no()

    file_params = %{
      filename: filename,
      created_by_id: user_id,
      batch_no: batch_no,
      upload_type: upload_type,
      remarks: "ok"
    }
    {:ok, member_file_upload} = MemberContext.create_member_upload_file(file_params)

    # Batch Upload
    # Enum.each(data, fn({_, data}) ->

    data |> Enum.each(fn(data) ->
      data = Map.put_new(data, "Account Code", account_code)

      if upload_type == "Individual, Family, Group (IFG)" do
        principal_number = data["Principal Number"]
        data =
          data
          |> Map.put("Employee No", principal_number)
          |> Map.delete("Principal Number")
      end

       data =
         data
         |> Map.put("member_file_upload_id", member_file_upload.id)
         |> Map.put("upload_type", upload_type)

       with {:passed} <- validations(1, data, []) do
          member =
            data
            |> Map.put("created_by_id", user_id)
            |> Map.put("updated_by_id", user_id)
            |> member_params()

          case member do
            {:error, message} ->
               insert_log_failed(data, filename, member_file_upload.id, user_id, message)
            _ ->
              with {:ok, member} <- insert_member(member) do
                insert_products(member.id, member.account_code, data["Plan Code"])
                insert_log_success(data, filename, member_file_upload.id, user_id, member.card_no)

                remarks = %{
                  "comment" => "Member successfully enrolled"
                }
                insert_member_comment(member.id, remarks, user_id)
                MemberContext.update_member_status(member.account_code)
                activate_member_on_effectivity_date(member)
              else
                _ ->
                  message = join_message("Error inserting member")
                  insert_log_failed(data, filename, member_file_upload.id, user_id, message)
              end
          end
        else
          {:failed, message} ->
            message = join_message(message)
            insert_log_failed(data, filename, member_file_upload.id, user_id, message)
          {:ignored} ->
            "If all columns are empty"
        end
    end)
  end

  def insert_log_failed(data, filename, member_file_upload_id, user_id, message) do
    data
    |> logs_params("")
    |> Map.put(:member_upload_file_id, member_file_upload_id)
    |> Map.put(:product_code, "#{data["Plan Code"]}")
    |> Map.put(:filename, filename)
    |> Map.put(:created_by_id, user_id)
    |> insert_log("failed", message)
  end

  def insert_log_success(data, filename, member_file_upload_id, user_id, card_no) do
    data
    |> logs_params(card_no)
    |> Map.put(:member_upload_file_id, member_file_upload_id)
    |> Map.put(:product_code, "#{data["Plan Code"]}")
    |> Map.put(:filename, filename)
    |> Map.put(:created_by_id, user_id)
    |> insert_log("success", "Member successfully enrolled")
  end

  def insert_log_successv2(data, filename, member_file_upload_id, user_id, member_id) do
    data
    |> logs_paramsv2()
    |> Map.put(:member_upload_file_id, member_file_upload_id)
    |> Map.put(:member_id, member_id)
    |> Map.put(:product_code, "#{data["Plan Code"]}")
    |> Map.put(:filename, filename)
    |> Map.put(:created_by_id, user_id)
    |> insert_log("success", "Member successfully enrolled")
  end

  def join_message(message) do
    message
    |> Enum.uniq()
    |> Enum.join(", ")
  end

  def validations(step, data, message), do: step(step, data, message)

  defp step(step, data, message) when step == 1 do
    # validate columns
    if {:complete} == validate_columns(data) do
      validations(2, data, message)
    else
      {:missing, empty} = validate_columns(data)
      count_empty = empty |> String.split(",") |> Enum.count

      if count_empty >= 13 do
        {:ignored}
      else
        message = message ++ [empty]
        validations(2, data, message)
      end
    end
  end

  defp step(step, data, message) when step == 2 do
    # validate account code
    code = data["Account Code"]
    with false <- code == "",
         {:valid_code} <- validate_account_code(code)
    do
      # On success returns no error
      validations(3, data, message)
    else
      true ->
        # if Account Code is empty
        validations(3, data, message)

      {:account_not_found} ->
        # if Account does not exist
        message = message ++ ["Account Code does not exist"]
        validations(3, data, message)

      nil ->
        # if AccountGroup does not have an Account
        message = message ++ ["Account Code does not exist"]
        validations(3, data, message)

      {false, status} ->
        # if Account is not Active
        message = message ++ ["The account you entered is #{String.downcase(status)}"]
        validations(3, data, message)
    end
  end

  defp step(step, data, message) when step == 3 do
    # validate member type (Principal, Dependent, Guardian)
    member_type = String.downcase(data["Member Type"])
    employee_no = data["Employee No"]

    with false <- member_type == "",
         {:valid_employee_no} <- validate_member_type(member_type, employee_no)
    do
      # On success returns no error
      if member_type == "principal" or member_type == "guardian" do
        validations(5, data, message)
      else
        validations(4, data, message)
      end
    else
      true ->
        # if Member Type is empty
        validations(5, data, message)

      {:used} ->
        # if Employee no is already used
        message = message ++ [
          "This employee no cannot be enrolled because it is used by another principal member"
        ]
        validations(5, data, message)

      {:empty_employee_no} ->
        # Employee No is nil
        validations(5, data, message)

      {:employee_no_not_found} ->
        # if Employee no not found
        message = message ++ ["Employee No does not exist"]
        validations(4, data, message)

      {:not_active, status} ->
      # if Member is not active
      message = message ++ ["The principal you entered is #{String.downcase(status)}"]
      validations(4, data, message)

      {:invalid_member_type} ->
      # if Member Type parameter
      message = message ++ ["Invalid Member Type. Valid Member Type includes PRINCIPAL, DEPENDENT and GUARDIAN"]
      validations(5, data, message)
    end
  end

  defp step(step, data, message) when step == 4 do
    # validate Relationship (Dependent only)
    relationship = data["Relationship"]
    account_code = data["Account Code"]
    birthdate = data["Birthdate"]
    employee_no = data["Employee No"]
    gender = data["Gender"]
    civil_status = data["Civil Status"]

    params = %{
      relationship: relationship,
      account_code: account_code,
      birthdate: birthdate,
      employee_no: employee_no,
      gender: gender,
      civil_status: civil_status
    }

    with false <- relationship == "",
         {:valid_relationship} <- validate_relationship(relationship),
         {true, birthdate} <- validate_date(birthdate),
         {:valid_relationship} <- validate_step_4(Map.put(params, :birthdate, birthdate), message)
    do
      validations(5, data, message)
    else
      true ->
        # Relationship is empty
        message = message ++ ["Please enter Relationship"]
        validations(5, data, message)

      {:invalid_relationship} ->
        # Invalid Relationship
        message = message ++ [
          "Invalid Relationship, valid relationship includes Child, Sibling, Parent, and Spouse"
        ]
        validations(5, data, message)

      {:invalid_date} ->
        # Invalid Birthdate cant check the dependent birthdate
        validations(5, data, message)

      {:error, true} ->
        # Invalid Account Code
        validations(5, data, message)

      false ->
        # Employee no does not exist
        validations(5, data, message)

      nil ->
      # Member doesnt have product
      message = message ++ [
        "Member Plan does not exist"
      ]
      validations(5, data, message)

      {:invalid_dependent} ->
      # Number of dependent is empty
      message = message ++ [
        "Number of dependent in plan is not set"
      ]
      validations(5, data, message)

      {:dependent_exceeded} ->
      # Number of dependent enrolled in principal is at maximum
      message = message ++ [
        "Number of dependent exceeded"
      ]
      validations(5, data, message)

      {:invalid_same_gender_parent} ->
      # Invalid same gender parent
      message = message ++ [
        "Gender of parent must not be the same with the existing parent"
      ]
      validations(5, data, message)

      {:invalid_parent} ->
      # 2 parents are allowed to enroll
      message = message ++ [
        "Number of Parent dependent exceeded, you are only allowed to enroll two (2) parent dependent"
      ]
      validations(5, data, message)

      {:invalid_parent_civil_status} ->
      # Only married civil status
      message = message ++ [
        "Invalid CIVIL STATUS, parent must only be MARRIED"
      ]
      validations(5, data, message)

      {:invalid_spouse_civil_status} ->
      # Only married civil status
      message = message ++ [
        "Invalid CIVIL STATUS, spouse must only be MARRIED"
      ]
      validations(5, data, message)

      {:invalid_spouse} ->
      # Only 1 spouse can enroll as dependent
      message = message ++ [
        "Number of spouse dependent exceeded, you are only allowed to enroll one (1) spouse dependent"
      ]
      validations(5, data, message)

      {:invalid_child} ->
      # Invalid Child
      message = message ++ [
        "You have already enrolled the youngest child hierarchy of enrollment is from eldest to youngest"
      ]
      validations(5, data, message)

      {:invalid_child_civil_status} ->
      # Single only
      message = message ++ [
        "Invalid CIVIL STATUS, child must only be SINGLE"
      ]
      validations(5, data, message)

      {:invalid_sibling_civil_status} ->
      # Single only
      message = message ++ [
        "Invalid CIVIL STATUS, sibling must only be SINGLE"
      ]
      validations(5, data, message)

      {:invalid_sibling} ->
      # Invalid Sibling
      message = message ++ [
        "You have already enrolled the youngest sibling hierarchy of enrollment is from eldest to youngest"
      ]
      validations(5, data, message)

      _ ->
      # Catcher
      validations(5, data, message)
    end
  end

  defp step(step, data, message) when step == 5 do
    # validate Effectivity Date
    effective_date = data["Effective Date"]
    member_type = data["Member Type"]

    with false <- effective_date == "",
         {:true, date} <- validate_date(effective_date),
         false <- member_type == "",
         true <- Enum.member?(["principal", "dependent", "guardian"], String.downcase(member_type)),
         {:ok, false} <- error_account(message, member_type, effective_date),
         {:valid_effective_date} <- validate_effective_date(data, message)
    do
      # On success returns no error
      validations(6, data, message)
    else

      true ->
        # if Effective Date and Member Type are emtpy
        validations(6, data, message)
      false ->
        # if Member type is invalid
        validations(6, data, message)

      {:invalid_date} ->
        validations(6, data, message)
        message = message ++ ["Invalid effective date, date must be in mmm dd yyyy format"]
        validations(6, data, message)

      {:error, true} ->
        # if Account Code is error
        validations(6, data, message)

      {:not_within_coverage} ->
        # if Effective Date is not within the coverage of Account
        message = message ++ ["Effective date must be within the coverage of the account"]
        validations(6, data, message)

      {:invalid_employee_no} ->
      # Invalid Employee no.(dependent)
      validations(6, data, message)

      {:employee_no_not_found} ->
      # Employee no is not existing.(dependent)
      validations(6, data, message)

      {:invalid_effective_date} ->
        # Effective date is not within the coverage of Principal effective date and expiry date (dependent)
        message = message ++ [
          "Effective date of dependent must be within the effective and expiry date of the principal"
        ]
        validations(6, data, message)

      _ ->
        validations(6, data, message)
    end
  end

  defp step(step, data, message) when step == 6 do
    # validate Expiry Date
    expiry_date = data["Expiry Date"]
    member_type = data["Member Type"]

    with false <- expiry_date == "",
         false <- member_type == "",
         true <- Enum.member?(["principal", "dependent", "guardian"], String.downcase(member_type)),
         {:ok, false} <- error_account(message, member_type, expiry_date),
         {:valid_expiry_date} <- validate_expiry_date(data, message)
    do
      # On success returns no error
      validations(7, data, message)
    else
      true ->
        # Expiry Date and Member Type are emtpy
        validations(7, data, message)

      false ->
        # Member type is invalid
        validations(7, data, message)

      {:invalid_date} ->
        # Expiry Date is invalid format
        message = message ++ ["Invalid expiry date, date must be in mmm dd yyyy format"]
        validations(7, data, message)

      {:error, true} ->
        # Account Code is error
        validations(7, data, message)

      {:not_within_coverage} ->
        # if Epxiry Date is not within the coverage of Account
        message = message ++ ["Expiry date must be within the coverage of the account"]
        validations(7, data, message)

      {:invalid_employee_no} ->
      # Invalid Employee no.(dependent)
      validations(7, data, message)

      {:employee_no_not_found} ->
      # Employee no is not existing.(dependent)
      validations(7, data, message)

      {:invalid_expiry_date} ->
      # Expiry date is not within the coverage of Principal effective date and expiry date (dependent)
      message = message ++ [
        "Expiry date of dependent must be within the effective and expiry date of the principal"
      ]
      validations(7, data, message)
    end
  end

  defp step(step, data, message) when step == 7 do
    # validate First Name
    first_name = data["First Name"]
    with false <- first_name == "",
         {:valid_name} <- validate_name(first_name, "First Name")
    do
      # On success returns no error
      validations(8, data, message)
    else
      true ->
        # First name is empty
        validations(8, data, message)

      {:invalid_name, messages} ->
        # Invalid First Name
        message = message ++ [messages]
        validations(8, data, message)
    end
  end

  defp step(step, data, message) when step == 8 do
    # validate Middle Name
    middle_name = data["Middle Name / Initial"]
    with {:valid_name} <- validate_name(middle_name, "Middle Name / Initial")
    do
      # On success returns no error
      validations(9, data, message)
    else
      true ->
        # Middle name is empty
        validations(9, data, message)

      {:invalid_name, messages} ->
        # Invalid Middle Name
        message = message ++ [messages]
        validations(9, data, message)
    end
  end

  defp step(step, data, message) when step == 9 do
    # validate Last Name
    last_name = data["Last Name"]
    with false <- last_name == "",
         {:valid_name} <- validate_name(last_name, "Last Name")
    do
      # On success returns no error
      validations(10, data, message)
    else
      true ->
        # Last name is empty
        validations(10, data, message)

      {:invalid_name, messages} ->
        # Invalid Last Name
        message = message ++ [messages]
        validations(10, data, message)
    end
  end

  defp step(step, data, message) when step == 10 do
    # validate Suffix
    suffix = data["Suffix"]
    with false <- suffix == "",
         {:valid_name} <- validate_name(suffix, "Suffix")
    do
      # On success returns no error
      validations(11, data, message)
    else
      true ->
        # Suffix is empty
        validations(11, data, message)

      {:invalid_name, messages} ->
        # Invalid Suffix
        message = message ++ [messages]
        validations(11, data, message)
    end
  end

  defp step(step, data, message) when step == 11 do
    # validate Gender
    gender = data["Gender"]
    member_type = data["Member Type"]
    employee_no = data["Employee No"]
    relationship = data["Relationship"]

    with false <- gender == "",
         {:valid_gender} <- validate_step_11(gender, member_type, employee_no, relationship, message)
    do
      # On success returns no error
      validations(12, data, message)
    else
      true ->
        # Gender is empty
        validations(12, data, message)

      {:invalid_gender} ->
        # Invalid Gender
        message = message ++ ["Invalid Gender. Valid Gender includes Male and Female"]
        validations(12, data, message)

      {:invalid_employee_no} ->
        # Invalid Employee no.(dependent)
        validations(12, data, message)

      {:employee_no_not_found} ->
        # Employee no is not existing.(dependent)
        validations(12, data, message)

      {:empty_relationship} ->
        # relationship is nil
        validations(12, data, message)

      {:invalid_relationship} ->
        # Invalid Relationship
        validations(12, data, message)

      {:invalid_spouse_gender} ->
      # Invalid Spouse gender
      message = message ++ [
        "The gender of the spouse dependent must not be the same with the principal"
      ]
      validations(12, data, message)
    end
  end

  defp step(step, data, message) when step == 12 do
    # validate Civil Status
    upload_type = data["upload_type"]
    civil_status = data["Civil Status"]
    relationship = data["Relationship"]
    member_type = data["Member Type"]

    with false <- civil_status == "",
         {:valid_civil_status} <- validate_step_12(member_type, civil_status, relationship, upload_type)
    do
      # On success returns no error
      validations(13, data, message)
    else
      true ->
        # Civil status is empty
        validations(13, data, message)

      {:invalid_civil_status} ->
        # Invalid Civil status
        message = message ++ [
          "Invalid civil status. Valid CIVIL STATUS includes ANNULLED, MARRIED, SINGLE, SEPARATED, SINGLE PARENT and WIDOWED"
        ]
        validations(13, data, message)

      {:invalid_relationship} ->
        # Invalid Relationship
        validations(13, data, message)

      {:invalid_child_civil_status} ->
        # Invalid Child civil status
        message = message ++ [
          "Invalid CIVIL STATUS, child must only be SINGLE"
        ]
        validations(13, data, message)

      {:invalid_sibling_civil_status} ->
        # Invalid Sibling civil status
        message = message ++ [
          "Invalid CIVIL STATUS, sibling must only be SINGLE"
        ]
        validations(13, data, message)

        {:invalid_spouse_civil_status} ->
        # Invalid Spouse civil status
        message = message ++ [
          "Invalid CIVIL STATUS, spouse must only be MARRIED"
        ]
        validations(13, data, message)

        {:invalid_parent_civil_status_corporate} ->
        # Only married civil status for corporate
        message = message ++ [
          "Invalid CIVIL STATUS, parent must only be MARRIED"
        ]
        validations(13, data, message)

        {:invalid_parent_civil_status} ->
        # Invalid Parent civil status
        message = message ++ [
          "Invalid CIVIL STATUS, parent must be ANNULLED, SEPARATED, WIDOWED or MARRIED only"
        ]
        validations(13, data, message)
    end
  end

  defp step(step, data, message) when step == 13 do
    # validate Birthdate
    birthdate = data["Birthdate"]
    member_type = data["Member Type"]
    employee_no = data["Employee No"]
    account_code = data["Account Code"]
    relationship = data["Relationship"]

    params = %{
      birthdate: birthdate,
      member_type: member_type,
      employee_no: employee_no,
      account_code: account_code,
      relationship: relationship,
    }

    with false <- birthdate == "",
         {:valid_birthdate, _birthdate} <- validate_step_13(params, message)
    do
      # On success returns no error
      validations(14, data, message)
    else
      true ->
        # Birthdate is empty
        validations(14, data, message)

      {:invalid_birthdate} ->
        # Invalid Date format
        message = message ++ [
          "Invalid birthdate, date must be in mmm dd yyyy format"
        ]
        validations(14, data, message)

      {:invalid_member_product} ->
        # Cant proceed due to member does not have product
        validations(14, data, message)

      {:invalid_employee_no} ->
        # Cant check member product due to invalid employee no
        validations(14, data, message)

      {:invalid_birthdate_dependent, product_code} ->
        # Invalid Dependent date
        message = message ++ [
          "This birthdate is not within the age limit of the product of the principal"
        ]
        validations(14, data, message)

      {:invalid_relationship} ->
      # relationship is invalid and check the dependent age
      validations(14, data, message)

      {:no_member_product} ->
      # No product is set in member or no tier is set in member product
      validations(14, data, message)

      _ ->
      validations(14, data, message)
    end
  end

  defp step(step, data, message) when step == 14 do
    # validate mobile no
    mobile = data["Mobile No"]

    with false <- mobile == "",
         {:valid_mobile_no} <- validate_mobile_no(mobile)
    do
      # On success returns no error
      validations(15, data, message)
    else
      true ->
        # Mobile no is empty
        validations(15, data, message)

      {:invalid_length} ->
        # Invalid Mobile No length
        message = message ++ [
          "Mobile no must be 11 digits"
        ]
        validations(15, data, message)

      false ->
        # Invalid Mobile No
        message = message ++ [
          "Invalid mobile no"
        ]
        validations(15, data, message)

      _ ->
        # Invalid Mobile No
        message = message ++ [
          "Invalid mobile no"
        ]
        validations(15, data, message)
    end
  end

  defp step(step, data, message) when step == 15 do
    # validate email address
    email = data["Email"]
    result = error_member_type?(message)

    with {:result, false} <- {:result, result},
         false <- email == "",
         {:valid_email} <- validate_email(email)
    do
      # On success returns no error
      validations(16.1, data, message)
    else
      true ->
        # Email address is empty
        validations(16.1, data, message)

      {:result, true} ->
        message = drop_email_n_mobile(message)
        validations(16.1, data, message)

      false ->
        # Invalid Email address
        message = message ++ [
          "Invalid email address"
        ]
        validations(16.1, data, message)

      _ ->
        # Invalid Email address
        message = message ++ [
          "Invalid email address"
        ]
        validations(16.1, data, message)
    end
  end

  defp step(step, data, message) when step == 16.1 do
    # Account type checker
    if data["upload_type"] == "Corporate" do
      validations(16, data, message)
    else
      validations(17, data, message)
    end
  end

  defp step(step, data, message) when step == 16 do
    # validate date hired and regularization date
    date_hired = data["Date Hired"]
    regularization_date = data["Regularization Date"]
    member_type = data["Member Type"]

    with {:valid_dates, messages} <- validate_step_16(date_hired, regularization_date, member_type) do
      # Add prompt if there's an error message
      message = message ++ [messages]
      validations(17, data, message)
    else
      {:empty_dates_principal} ->
        # Date hired and Regularization date is required in principal member type
        message = message ++ ["Please enter Date Hired, Please enter Regularization Date"]
        validations(17, data, message)

      {:empty_dates} ->
        # Not required to dependent
        validations(17, data, message)

      {:invalid_date_hired} ->
        # Invalid date hired format
        message = message ++ [
          "Invalid date hired, date must be in mmm dd yyyy format"
        ]
        validations(17, data, message)

      {:invalid_regularization_date} ->
        # Invalid Regularization Format
        message = message ++ [
          "Invalid regularization date, date must be in mmm dd yyyy format"
        ]
        validations(17, data, message)

      {:invalid_date_hired_n_regularization_date} ->
        # Invalid Date hired and Regularization Format
        message = message ++ ["Invalid Date Hired format, Invalid Regularization Date format"]
        validations(17, data, message)

        {:invalid_dates} ->
        # Date hired must not be greater than regularization date
        message = message ++ [
          "Date Hired must not be greater than regularization date"
        ]
        validations(17, data, message)

        {:invalid_date_format} ->
        # Invalid Date hired and Regularization Format
        message = message ++ [
          "Invalid date hired, date must be in mmm dd yyyy format,
          Invalid regularization date, date must be in mmm dd yyyy format"
        ]
        validations(17, data, message)
    end
  end

  defp step(step, data, message) when step == 17 do
    product_codes = data["Plan Code"]
    account_code = data["Account Code"]
    birthdate = data["Birthdate"]
    member_type = data["Member Type"]
    relationship = data["Relationship"]

    with false <- product_codes == "",
         true <- error_member_type?(message) == false,
         {:ok, false} <- error_account(message),
         {:valid_product_codes} <- validate_step_17(
                                    product_codes,
                                    account_code,
                                    birthdate,
                                    member_type,
                                    relationship
                                  )
    do
      # On success returns no error
      validations(18, data, message)
    else
      true ->
        # Plan Code is empty
        validations(18, data, message)

      false ->
        # Invalid member type
        validations(18, data, message)

      {:error, true} ->
        # Invalid Account code cant product code
        validations(18, data, message)

      {:invalid_product_code_format} ->
        # Plan Code column is invalid format
        message = message ++ ["Invalid Plan Code format"]
        validations(18, data, message)

      {:invalid_product_codes, messages} ->
      # All Products that not within the account
      message = message ++ messages
      validations(18, data, message)

      {:invalid_date} ->
      # invalid birthdate
      validations(18, data, message)

      {:invalid_members_age, messages} ->
      # All Products that not within the account
      message = message ++ messages
      validations(18, data, message)

      _ ->
      validations(18, data, message)
    end
  end

  defp step(step, data, message) when step == 18 do
    # validate for card issuance
    for_card_issuance = data["For Card Issuance"]

    with false <- for_card_issuance == "",
         {:valid, _boolean} <- validate_step_18(for_card_issuance)
    do
      # On success returns no error
      validations(19, data, message)
    else
      true ->
        # For Card Issuance is empty
        validations(19, data, message)

      {:invalid_data} ->
        message = message ++ [
          "Invalid For Card Issuance. Valid For card issuance is “Yes” or “No”"
        ]
        validations(19, data, message)

      _ ->
        message = message ++ [
          "Invalid For Card Issuance. Valid For card issuance is “Yes” or “No”"
        ]
        validations(19, data, message)
    end
  end

  defp step(step, data, message) when step == 19 do
    # validate employee no
    account_code = data["Account Code"]
    employee_no = data["Employee No"]
    member_type = data["Member Type"]

    error_employee_no? =
      message
      |> Enum.join(", ")
      |> String.contains?(["Employee No does not exist"])

    with false <- employee_no == "",
         true <- error_employee_no? == false,
         {:ok, false} <- error_account(message),
         {:valid_employee_no} <- validate_employee_no(account_code, employee_no, member_type)
    do
      validations(20, data, message)
    else
      true ->
        # employee no is empty
        validations(20, data, message)

      false ->
        # employee no does not exist
        validations(20, data, message)

      {:error, true} ->
        # account code is empty
        validations(20, data, message)

      {:invalid_employee_no} ->
        # Account code and employee no are already exist
        message = message ++ [
          "No principal member found using Account Code and Employee No"
        ]
        validations(20, data, message)

      _ ->
        message = message ++ [
          "No principal member found using Account Code and Employee No"
        ]
        validations(20, data, message)
    end
  end

  defp step(step, data, message) when step == 20 do
    # Validate TIN
    tin_no = data["Tin No"]

    with false <- tin_no == "",
         {:valid_tin_no} <- validate_tin(tin_no)
    do
      validations(21, data, message)
    else
      true ->
        # TIN is not required
        validations(21, data, message)

      {:invalid_tin_no} ->
        message = message ++ ["Invalid Tin"]
        validations(21, data, message)

      {:invalid_tin_count} ->
        message = message ++ [
          "Tax Identification Number (TIN) must be 12 digits "
        ]
        validations(21, data, message)

      _ ->
        message = message ++ ["Invalid Tin"]
        validations(21, data, message)
    end
  end

  defp step(step, data, message) when step == 21 do
    # Validate Philhealth
    philhealth = data["Philhealth"]

    with false <- philhealth == "" or is_nil(philhealth),
         {:valid_philhealth} <- validate_philhealth(philhealth)
    do
      validations(22, data, message)
    else
      true ->
        validations(22, data, message)

      {:invalid_philhealth} ->
        message = message ++ [
          "Invalid PhilHealth, Valid PhilHealth include Required to file, optional to file and not covered"
        ]
        validations(22, data, message)

      _ ->
        message = message ++ [
          "Invalid PhilHealth, Valid PhilHealth include Required to file, optional to file and not covered"
        ]
        validations(22, data, message)
    end
  end

  defp step(step, data, message) when step == 22 do
    philhealth = data["Philhealth"]
    phil_no = data["Philhealth No"]

    with false <- philhealth == "",
         {:valid_phil_no, data} <- validate_phil_no(philhealth, phil_no, data)
    do
      validations(23, data, message)
    else
      true ->
        validations(23, data, message)

      # {:is_nil} ->
      #   message = message ++ ["Please enter Philhealth Number"]
      #   validations(23, data, message)

      {:invalid_phil_no} ->
        message = message ++ ["Invalid PhilHealth Number"]
        validations(23, data, message)

      {:invalid_phil_count} ->
        message = message ++ ["PhilHealth Number must be 12 digits"]
        validations(23, data, message)

      {:not_covered} ->
        validations(23, data, message)

      _ ->
        message = message ++ ["Invalid PhilHealth Number"]
        validations(23, data, message)
    end
  end

  defp step(step, data, message) when step == 23 do
    # validate younger sibling and child
    relationship = String.downcase(data["Relationship"])
    member_type = String.downcase(data["Member Type"])
    account_code = data["Account Code"]
    employee_no = data["Employee No"]
    birthdate = data["Birthdate"]
    member_file_upload_id = data["member_file_upload_id"]

    params = %{
      account_code: account_code,
      employee_no: employee_no,
      relationship: relationship,
      birthdate: birthdate
    }

    with false <- invalid_dependent?(message),
         true <- member_type == "dependent",
         true <- Enum.member?(["sibling", "child"], relationship),
         {:valid_dependent} <- validate_younger_dependent(member_file_upload_id, params)
    do
      # valid dependent proceed to next step
      validations(24, data, message)
    else
      true ->
        # Invalid dependent proceed to next step
        validations(24, data, message)

      false ->
        # Invalid relationship or member type  proceed to next step
        validations(24, data, message)

      {:error_older} ->
        # Older dependent already failed in the template
        message = message ++ [
          "Older #{relationship} has error in template"
        ]
        validations(24, data, message)

      _ ->
        # Catcher
        validations(24, data, message)
    end
  end

  defp step(step, data, message) when step == 24 do
    # validate hierarchy
    relationship = String.downcase(data["Relationship"])
    member_type = String.downcase(data["Member Type"])
    account_code = data["Account Code"]
    employee_no = data["Employee No"]

    params = %{
      account_code: account_code,
      employee_no: employee_no,
      relationship: relationship,
      member_type: member_type
    }

    with false <- invalid_step_24?(message),
         true <- member_type == "dependent",
         {:valid_hierarchy} <- validate_step_24(params)
    do
      validations(25, data, message)
    else
      true ->
        # Invalid dependent proceed to next step
        validations(25, data, message)

      false ->
        # Member type  proceed to next step
        validations(25, data, message)

      {:no_hierarchy_set} ->
        # Hierarchy is not set
        message = message ++ [
          "No hierarchy found in account"
        ]
        validations(25, data, message)

      {:skip_spouse_first} ->
        # Spouse is last to enroll
        message = message ++ [
          "Please skip the spouse first"
        ]
        validations(25, data, message)

      {:skipped_dependents, skipped} ->
        # Skipped dependents
        message = message ++ [
          "Please enroll #{Enum.join(skipped, ", ")} first"
        ]
      validations(25, data, message)

      {:not_found_relationship, relationship} ->
      # Relationship not found in hierachy
      message = message ++ [
        "Please enroll #{Enum.join(relationship, ", ")} only"
      ]
      validations(25, data, message)

      _ ->
      # Catcher
      validations(25, data, message)
    end
  end

  defp step(step, data, message) when step == 25 do
    # validate remarks/comment
    remarks = data["Remarks"]
    with false <- remarks == "",
         {:valid_remarks} <- validate_step_25(remarks)
    do
      validations(26, data, message)
    else
      true ->
        validations(26, data, message)

      {:invalid_remarks} ->
        message = message ++ [
          "Remarks must only be 250 characters."
        ]
        validations(26, data, message)
    end
  end

  defp step(step, data, message) when step == 26  do
    # Final Step
    message =
      message
      |> Enum.join(",")
      |> String.split(",")
      |> Enum.into([], &(String.trim(&1)))
      |> Enum.reject(&(&1 == "Please enter Mobile No"))
      |> Enum.reject(&(&1 == "Please enter Email"))
      |> Enum.reject(&(&1 == ""))
      |> Enum.filter(fn(msg) -> msg != "" end)

    if Enum.member?(["dependent"], String.downcase(data["Member Type"])) do
      message =
        message
        |> Enum.join(",")
        |> String.split(",")
        |> Enum.into([], &(String.trim(&1)))
        |> Enum.reject(&(&1 == "valid_date"))
        |> Enum.reject(&(&1 == ""))
        |> Enum.filter(fn(msg) -> msg != "" end)
    else
      message = Enum.filter(message, fn(msg) -> msg != "valid_date" end)
    end

    cond do
      Enum.empty?(message) or message == [""] ->
        {:passed}
      data["upload_type"] == "Individual, Family, Group (IFG)" ->
        message = replace_msg(message)
        {:failed, message}
      true ->
        {:failed, message}
    end
  end

  defp drop_email_n_mobile(message) do
    message
    |> Enum.join(",")
    |> String.split(",")
    |> Enum.into([], &(String.trim(&1)))
    |> Enum.reject(&(&1 == "Please enter Mobile No"))
    |> Enum.reject(&(&1 == "Please enter Email"))
  end

  defp error_member_type?(message) do
    message
    |> Enum.join(", ")
    |> String.contains?([
        "Please enter Member Type",
        "Invalid Member Type.",
        "Please enter Relationship",
        "Invalid Relationship"
      ])
  end

  defp replace_msg(message) do
    Enum.into(message, [], fn(msg) ->
      msg
      |> String.replace("Employee No", "Principal Number")
      |> String.replace("employee no", "principal number")
    end)
  end

  # step 1
  def validate_columns(params) do
    values =
      params
      |> Map.delete("member_file_upload_id")
      |> Map.delete("upload_type")
      |> Map.drop(optional_keys())
      |> Map.values()

    if Enum.any?(values, fn(val) -> is_nil(val) or val == "" end) do
      empty =
        params
        |> Map.drop(optional_keys())
        |> Enum.filter(fn({_k, v}) -> is_nil(v) or v == "" end)
        |> Enum.into(%{}, fn({k, v}) -> {Enum.join(["Please enter ", k]), v} end)
        |> Map.keys
        |> Enum.join(", ")

      {:missing, empty}
    else
      {:complete}
    end
  end

  # step 2
  def validate_account_code(code) do
    with ag = %AccountGroup{} <- AccountContext.get_account_by_code(code),
         true <- is_active?(ag.id)
    do
      {:valid_code}
    end
  end

  defp is_active?(account_group_id) do
    account = AccountContext.get_active_account(account_group_id)
    is_active?(account, account_group_id)
  end

  defp is_active?(nil, account_group_id) do
    account = AccountContext.get_latest_account(account_group_id)
    cond  do
      is_nil(account) ->
        nil
      invalid_account_status?(account.status) == false ->
        account = get_account_second_version(account_group_id)
        if account.status == "Active" do
          true
        else
          {false, account.status}
        end
      true ->
        {false, account.status}
    end
  end

  defp is_active?(account, account_group_id), do: true

  defp invalid_account_status?(status) do
    Enum.member?(account_status(), String.downcase(status))
  end

  defp get_account_second_version(account_group_id) do
    account_group_id
    |> AccountContext.get_all_account()
    |> Enum.at(1)
  end

  defp account_status do
    ["suspended", "cancelled", "lapsed", "pending"]
  end

  # step 3
  def validate_member_type(type, employee_no) do
    case String.downcase(type) do
      "principal" ->
        validate_principal_type(employee_no)
      "guardian" ->
        validate_principal_type(employee_no)
      "dependent" ->
        validate_dependent_type(employee_no)
       _ ->
        {:invalid_member_type}
    end
  end

  defp validate_principal_type(employee_no) do
    employee_no_not_used? = Enum.empty?(MemberContext.get_employee_no(employee_no))
    if employee_no_not_used? do
      {:valid_employee_no}
    else
      {:used}
    end
  end

  defp validate_dependent_type(employee_no) do
    member =
      employee_no
      |> MemberContext.get_employee_no()
      |> List.first()

    with  false <- employee_no == "",
         %Member{} <- member,
         true <- member.status == "Active" || member.status == "Pending"
    do
      {:valid_employee_no}
    else
      true ->
        {:empty_employee_no}
      nil ->
        {:employee_no_not_found}
      false ->
        if is_nil(member.status) do
          {:not_active, "null"}
        else
          {:not_active, member.status}
        end
    end
  end

  # step 4
  def validate_step_4(params, message) do
    with {:ok, false} <- error_account(message),
         # {:valid_number_dependent} <- validate_number_dependent(
         #                               params.account_code,
         #                               params.employee_no,
         #                               message),
         {:valid_relationship} <- validate_relationship_by_type(params)
    do
      {:valid_relationship}
    end
  end

  def validate_number_dependent(account_code, employee_no, message) do
    error_employee_no? =
      message
      |> Enum.join(", ")
      |> String.contains?(["Employee No does not exist"])

    with true <- error_employee_no? == false,
         product = %Product{} <- MemberContext.get_member_product_tier(account_code, employee_no)
    do
      if is_nil(product.nem_dependent) do
        {:invalid_dependent}
      else
        dependents =
          account_code
          |> MemberContext.get_number_of_dependent(employee_no)
          |> Enum.count()

        if product.nem_dependent > dependents do
          {:valid_number_dependent}
        else
          {:dependent_exceeded}
        end
      end
    end
  end

  defp validate_relationship_by_type(params) do
    relationship = String.downcase(params.relationship)
    civil_status = String.downcase(params.civil_status)
    gender = params.gender
    employee_no = params.employee_no
    account_code = params.account_code
    birthdate = params.birthdate

    case relationship do
      "parent" ->
        parent_relationship(account_code, employee_no, gender)
      "spouse" ->
        spouse_relationship(account_code, employee_no, civil_status)
      _ ->
        child_or_sibling_relationship(account_code, employee_no, civil_status, birthdate, relationship)
    end
  end

  defp parent_relationship(account_code, employee_no, gender) do
    member = MemberContext.get_member_by_relationship_n_code(account_code, "Parent", employee_no)
    if Enum.count(member) <= 1 do
      if Enum.count(member) == 1 && String.downcase(List.first(member).gender) == String.downcase(gender) do
        {:invalid_same_gender_parent}
      else
        {:valid_relationship}
      end
    else
      {:invalid_parent}
    end
  end

  defp spouse_relationship(account_code, employee_no, civil_status) do
    member = MemberContext.get_member_by_relationship_n_code(account_code, "Spouse", employee_no)
    if Enum.count(member) == 0 do
      if String.downcase(civil_status) == "married" do
        {:valid_relationship}
      else
        {:invalid_spouse_civil_status}
      end
    else
      {:invalid_spouse}
    end
  end

  defp child_or_sibling_relationship(account_code, employee_no, civil_status, birthdate, relationship) do
    members =
      account_code
      |> MemberContext.get_member_by_relationship_n_code(String.capitalize(relationship), employee_no)

    if Enum.count(members) == 0 do
      check_relationship(civil_status, relationship)
    else
      check_relationship(members, birthdate, civil_status, relationship)
    end
  end

  defp check_relationship(civil_status, relationship) do
    cond do
      civil_status == "single" ->
        {:valid_relationship}
      civil_status == "" ->
        {:invalid}
      Enum.member?(valid_civil_status(), civil_status) == false ->
        {:invalid}
      true ->
        {String.to_atom(Enum.join(["invalid_", relationship, "_civil_status"]))}
    end
  end

  defp check_relationship(members, birthdate, civil_status, relationship) do
    dependent =
      for member <- members do
        birthdate
        |> Ecto.Date.cast!()
        |> Ecto.Date.compare(Ecto.Date.cast!(member.birthdate))
      end
    dependent_valid? = Enum.member?(Enum.uniq(dependent), :lt) == false

    if dependent_valid? do
      cond do
        civil_status == "single" ->
          {:valid_relationship}
        civil_status == "" ->
          {:invalid}
        Enum.member?(valid_civil_status(), civil_status) == false ->
          {:invalid}
        true ->
          {String.to_atom(Enum.join(["invalid_", relationship, "_civil_status"]))}
      end
    else
        {String.to_atom(Enum.join(["invalid_", relationship]))}
    end
  end

  # step 5
  def validate_effective_date(data, message) do
    with {true, effective_date} <- validate_date(data["Effective Date"]),
        {:valid_effective_date} <- member_type_date(effective_date, data, message, :effective)
    do
      {:valid_effective_date}
    end
  end

  def error_account(message, member_type, effective_date) do
    member_type = String.downcase(member_type)
    error_account? =
      message
      |> Enum.join(", ")
      |> String.contains?(["Account Code", "account"])

    member_type? = Enum.member?(["principal", "guardian"], member_type)

    if error_account? && member_type? do
      case validate_date(effective_date) do
        {:true, _date} ->
          {:error, true}
        _ ->
          {:invalid_date}
      end
    else
      {:ok, false}
    end
  end

  def transform_to_datetime(date) do
    Ecto.DateTime.cast!("#{date} 00:00:00")
  end

  defp validate_date(date) do
    date_string_format(date)
  rescue
    MatchError ->
      {:invalid_date}
    ArgumentError ->
      {:invalid_date}
    Ecto.CastError ->
      {:invalid_date}
    FunctionClauseError ->
      {:invalid_date}
    _ ->
      {:invalid_date}
  end

  defp date_slash_format(date) do
      [mm, dd, yyyy] = String.split(date, "/")
      if String.length(dd) == 1, do: dd = "0#{dd}"
      if String.length(mm) == 1, do: mm = "0#{mm}"
      if String.length(yyyy) == 2, do: yyyy = "20#{yyyy}"
      date = Ecto.Date.cast!("#{yyyy}-#{mm}-#{dd}")
      {:true, date}
    rescue
      _ ->
        {:invalid_date}
  end

  defp date_string_format(date) do
      date = UtilityContext.transform_string_dates(date)
      {:true, Ecto.Date.cast!(date)}
    rescue
      _ ->
        date_slash_format(date)
  end

  def member_type_date(date, data, message, :effective) do
    case String.downcase(data["Member Type"]) do
      "dependent" ->
        dependent_effective_date(message, data, date)
       _ ->
        principal_effective_date(message, data, date)
    end
  end

  defp check_employee_no_if_error?(message) do
    message
    |> Enum.join(", ")
    |> String.contains?(["Employee No does not exist", "principal", "employee no cannot be enrolled"])
  end

  defp dependent_effective_date(message, data, date) do
    error_employee_no? = check_employee_no_if_error?(message)
    with false <- error_employee_no?,
         member = %Member{} <- get_member_by_employee_n_account_code(data),
         {:valid_effective_date} <- within_the_coverage_date_of_principal(date, member, :effective)
    do
      {:valid_effective_date}
    else
      true ->
        {:invalid_employee_no}
      nil ->
        {:employee_no_not_found}
      {:not_within_coverage} ->
        {:invalid_effective_date}
    end
  end

  defp within_the_coverage_date_of_principal(date, member, :effective) do
    start_date =
      member.effectivity_date
      |> Ecto.Date.cast!
      |> Ecto.Date.compare(Ecto.Date.cast!(date))
    end_date =
      member.expiry_date
      |> Ecto.Date.cast!
      |> Ecto.Date.compare(Ecto.Date.cast!(date))
    validate_effective_within_the_coverage_date(start_date, end_date)
  end

  defp principal_effective_date(message, data, date) do
    case error_account(message) do
      {:ok, false} ->
        ag = AccountContext.get_account_by_code(data["Account Code"])
        account = AccountContext.get_active_account(ag.id)
        start_date =
          account.start_date
          |> Ecto.Date.cast!
          |> Ecto.Date.compare(Ecto.Date.cast!(date))
        end_date =
          account.end_date
          |> Ecto.Date.cast!
          |> Ecto.Date.compare(Ecto.Date.cast!(date))
        validate_effective_within_the_coverage_date(start_date, end_date)
      _ ->
        {:error, true}
    end
  end

  defp get_member_by_employee_n_account_code(data) do
    data["Employee No"]
    |> MemberContext.get_employee_no_by_account_code(data["Account Code"])
    |> List.first()
  end

  defp validate_effective_within_the_coverage_date(start_date, end_date) do
    if start_date == :eq || start_date == :lt && end_date == :gt || end_date == :eq do
      {:valid_effective_date}
    else
      {:not_within_coverage}
    end
  end

  # step 6
  def validate_expiry_date(data, message) do
    with {true, expiry_date} <- validate_date(data["Expiry Date"]),
        {:valid_expiry_date} <- member_type_date(expiry_date, data, message, :expiry)
    do
      {:valid_expiry_date}
    end
  end

  def member_type_date(date, data, message, :expiry) do
    case String.downcase(data["Member Type"]) do
      "dependent" ->
        dependent_expiry_date(message, data, date)
       _ ->
        principal_expiry_date(message, data, date)
    end
  end

  defp dependent_expiry_date(message, data, date) do
    error_employee_no? = check_employee_no_if_error?(message)
    with false <- error_employee_no?,
         member = %Member{} <- get_member_by_employee_n_account_code(data),
         {:valid_expiry_date} <- within_the_coverage_date_of_principal(date, member, :expiry)
    do
      {:valid_expiry_date}
    else
      true ->
        {:invalid_employee_no}
      nil ->
        {:employee_no_not_found}
      {:not_within_coverage} ->
        {:invalid_expiry_date}
    end
  end

  defp within_the_coverage_date_of_principal(date, member, :expiry) do
    start_date =
      member.effectivity_date
      |> Ecto.Date.cast!
      |> Ecto.Date.compare(Ecto.Date.cast!(date))
    end_date =
      member.expiry_date
      |> Ecto.Date.cast!
      |> Ecto.Date.compare(Ecto.Date.cast!(date))
    validate_expiry_within_the_coverage_date(start_date, end_date)
  end

  defp principal_expiry_date(message, data, date) do
    case error_account(message) do
      {:ok, false} ->
        ag = AccountContext.get_account_by_code(data["Account Code"])
        account = AccountContext.get_active_account(ag.id)
        start_date =
          account.start_date
          |> Ecto.Date.cast!
          |> Ecto.Date.compare(Ecto.Date.cast!(date))
        end_date =
          account.end_date
          |> Ecto.Date.cast!
          |> Ecto.Date.compare(Ecto.Date.cast!(date))
        validate_expiry_within_the_coverage_date(start_date, end_date)
      _ ->
        {:error, true}
    end
  end

  defp validate_expiry_within_the_coverage_date(start_date, end_date) do
    if start_date == :eq || start_date == :lt && end_date == :gt || end_date == :eq do
      {:valid_expiry_date}
    else
      {:not_within_coverage}
    end
  end

  # step 7, 8, 9, 10 (Firstname, Lastname, Middlename, Suffix)
  def validate_name(name, type) do
    # name = String.duplicate("a.", 150)
    char = String.codepoints("=/[``~<>^\"'{}[\]\;':?!@#$%&*()_+=]|/")

    with false <- String.contains?(name, char),
         {:valid_name} <- validate_name_length(name, type)
    do
      {:valid_name}
    else
      {:invalid_name, message} ->
        {:invalid_name, message}
      true ->
        {:invalid_name,
          "Invalid #{type}, please follow the format (#{type} must consist of letters, numbers and dot (.) comma (,) and hyphen (-).)"
        }
    end
  end

  defp validate_name_length(name, type) do
    if type == "Suffix" do
      max_length = 10
    else
      max_length = 150
    end

    if String.length(name) > max_length do
      {:invalid_name, "#{type} must only be #{max_length} characters"}
    else
      {:valid_name}
    end

  end

  # step 11
  defp validate_step_11(gender, member_type, employee_no, relationship, message) do
    gender = String.downcase(gender)
    member_type = String.downcase(member_type)
    if member_type == "dependent" do
      validate_gender_dependent(gender, employee_no, relationship, message)
    else
      validate_gender(gender)
    end
  end

  def validate_gender(gender) do
    valid_gender? = Enum.member?(["male", "female"], gender)

    if valid_gender? do
      {:valid_gender}
    else
      {:invalid_gender}
    end
  end

  def validate_gender_dependent(gender, employee_no, relationship, message) do
    error_employee_no? =
      message
      |> Enum.join(", ")
      |> String.contains?(["Employee No does not exist", "principal", "employee no cannot be enrolled"])

    error_relationship? =
      message
      |> Enum.join(", ")
      |> String.contains?(["Please enter Relationship"])

    with {:valid_gender} <- validate_gender(gender),
         false <- error_employee_no?,
         member = %Member{} <- List.first(MemberContext.get_employee_no(employee_no)),
         true <- error_relationship? == false,
         {:valid_relationship} <- validate_relationship(relationship),
         {:valid_spouse_gender} <- validate_spouse(member, relationship, gender)
    do
      {:valid_gender}
    else
      {:invalid_gender} ->
        {:invalid_gender}

      true ->
        {:invalid_employee_no}

      nil ->
        {:employee_no_not_found}

      false ->
        {:empty_relationship}

      {:invalid_relationship} ->
        {:invalid_relationship}

      {:invalid_spouse_gender} ->
        {:invalid_spouse_gender}
    end
  end

  defp validate_relationship(relationship) do
    relationship = String.downcase(relationship)
    if Enum.member?(valid_relationship, relationship) do
      {:valid_relationship}
    else
      {:invalid_relationship}
    end
  end

  defp validate_spouse(member, relationship, gender) do
    if String.downcase(relationship) == "spouse" do
      if String.downcase(member.gender) == gender do
        {:invalid_spouse_gender}
      else
        {:valid_spouse_gender}
      end
    else
      {:valid_spouse_gender}
    end
  end

  defp valid_relationship do
    ["child", "spouse", "parent", "sibling"]
  end

  # step 12
  defp validate_step_12(member_type, civil_status, relationship, upload_type) do
    member_type = String.downcase(member_type)
    civil_status = String.downcase(civil_status)

    if member_type == "dependent" do
      validate_civil_status_dependent(civil_status, relationship, upload_type)
    else
      validate_civil_status(civil_status)
    end
  end

  def validate_civil_status(civil_status) do
    if Enum.member?(valid_civil_status(), civil_status) do
      {:valid_civil_status}
    else
      {:invalid_civil_status}
    end
  end

  def validate_civil_status_dependent(civil_status, relationship, upload_type) do
    with {:valid_civil_status} <- validate_civil_status(civil_status),
        {:valid_relationship} <- validate_relationship(relationship),
        {:valid_civil_status} <- check_civil_status(relationship, civil_status, upload_type)
    do
      {:valid_civil_status}
    end
  end

  defp check_civil_status(relationship, civil_status, upload_type) do
    relationship = String.downcase(relationship)

    case relationship do
      "child" ->
          if civil_status == "single" do
            {:valid_civil_status}
          else
            {:invalid_child_civil_status}
          end

      "sibling" ->
          if civil_status == "single" do
            {:valid_civil_status}
          else
            {:invalid_sibling_civil_status}
          end

      "spouse" ->
          if civil_status == "married" do
            {:valid_civil_status}
          else
            {:invalid_spouse_civil_status}
          end

      "parent" ->
          check_parent_civil_status(civil_status, upload_type)

      _ ->
        {:valid_civil_status}
    end
  end

  defp check_parent_civil_status(civil_status, upload_type) do
    cond do
      upload_type == "Corporate" ->
        if civil_status == "married" do
          {:valid_civil_status}
        else
          {:invalid_parent_civil_status_corporate}
        end

      Enum.member?(["annulled", "widowed", "separated", "married"], civil_status) ->
        {:valid_civil_status}

      true ->
        {:invalid_parent_civil_status}
    end
  end

  defp valid_civil_status do
    [
      "single", "married", "annulled",
      "separated", "widowed",
      "single parent"
    ]
  end

  # step 13
  defp validate_step_13(params, message) do
    birthdate = params.birthdate
    employee_no = params.employee_no
    account_code = params.account_code
    relationship = params.relationship
    member_type = String.downcase(params.member_type)

    if member_type == "dependent" do
      validate_birthdate_dependent(birthdate, employee_no, account_code, relationship, message)
    else
      validate_birthdate(birthdate)
    end
  end

  def validate_birthdate(birthdate) do
    with {:true, birthdate} <- validate_date(birthdate) do
      {:valid_birthdate, birthdate}
    else
      _ ->
        {:invalid_birthdate}
    end
  end

  def validate_birthdate_dependent(birthdate, employee_no, account_code, relationship, message) do
    error_employee_no? =
      message
      |> Enum.join(", ")
      |> String.contains?(["Employee No does not exist", "principal", "employee no cannot be enrolled"])

    error_relationship? =
      message
      |> Enum.join(", ")
      |> String.contains?(["Invalid Relationship,"])

    with false <- error_employee_no?,
         {:ok, false} <- error_member_product(message),
         {:valid_birthdate, birthdate} <- validate_birthdate(birthdate)
    do
      product = MemberContext.get_member_product_tier(account_code, employee_no)
      with false <- error_relationship?,
           %Product{} <- product,
           {:valid_birthdate} <- validate_dependent_age(relationship, birthdate, product)
      do
        {:valid_birthdate, birthdate}
      else
        true ->
          {:invalid_relationship}
        nil ->
          {:no_member_product}
        {:invalid_birthdate_dependent, product_code} ->
          {:invalid_birthdate_dependent, product_code}
      end
    else
      true ->
        {:invalid_employee_no}

      {:error, true} ->
        {:invalid_member_product}

      {:invalid_birthdate} ->
        {:invalid_birthdate}
    end
  end

  defp error_member_product(message) do
    error_member_product? =
      message
      |> Enum.join(", ")
      |> String.contains?(["Member Plan does not exist"])

    if error_member_product? do
      {:error, true}
    else
      {:ok, false}
    end
  end

  defp validate_dependent_age(relationship, birthdate, product) do
    relationship = String.downcase(relationship)
    if Enum.member?(["spouse", "parent"], relationship) do
      try do
        check_product_age_eligibility(birthdate, product)
      rescue
        _ ->
          {:invalid_birthdate_dependent, product.code}
      end
    else
      min_age = product.minor_dependent_min_age
      max_age = product.minor_dependent_max_age

      minor_min_type =
        product.minor_dependent_min_type
        |> String.downcase()
        |> String.to_atom()

      minor_max_type =
        product.minor_dependent_max_type
        |> String.downcase()
        |> String.to_atom()

      min_max_type = {minor_min_type, minor_max_type}

      minor_dependent_age_checker(min_max_type, min_age, max_age, birthdate, product.code)
    end
  end

  def check_product_age_eligibility(birthdate, product) do
    member_age = age(birthdate)
    if member_age >= product.adult_dependent_min_age and member_age <= product.adult_dependent_max_age do
      {:valid_birthdate}
    else
      {:invalid_birthdate_dependent, product.code}
    end
  end

  def check_product_age_eligibility_principal(birthdate, product) do
    member_age = age(birthdate)
    if member_age >= product.principal_min_age and member_age <= product.principal_max_age do
      {:valid_birthdate}
    else
      {:invalid_birthdate_dependent, product.code}
    end
  end

  def age(%Ecto.Date{day: d, month: m, year: y}, as_of \\ :now) do
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

  defp minor_dependent_age_checker(min_max_type, min_age, max_age, birthdate, product_code) do
    age_in_years = age(birthdate)
    {y, m, d} = Ecto.Date.to_erl(Ecto.Date.cast!(birthdate))
    {:ok, birthdate} = Date.new(y, m, d)

    # members age by type
    age_in_days = Date.diff(Date.utc_today(), birthdate)
    age_in_weeks = Integer.floor_div(age_in_days, 7)
    age_in_months = Integer.floor_div(age_in_days, 30)

    with {:days, :days} <- min_max_type do
      check_min_max_age(age_in_days, age_in_days, min_age, max_age, product_code)
    else
      {:days, :weeks} ->
        check_min_max_age(age_in_days, age_in_weeks, min_age, max_age, product_code)

      {:days, :months} ->
        check_min_max_age(age_in_days, age_in_months, min_age, max_age, product_code)

      {:days, :years} ->
        check_min_max_age(age_in_days, age_in_years, min_age, max_age, product_code)

      {:weeks, :weeks} ->
        check_min_max_age(age_in_weeks, age_in_weeks, min_age, max_age, product_code)

      {:weeks, :months} ->
        check_min_max_age(age_in_weeks, age_in_months, min_age, max_age, product_code)

      {:weeks, :years} ->
        check_min_max_age(age_in_weeks, age_in_years, min_age, max_age, product_code)

      {:months, :months} ->
        check_min_max_age(age_in_months, age_in_months, min_age, max_age, product_code)

      {:months, :years} ->
        check_min_max_age(age_in_months, age_in_years, min_age, max_age, product_code)

      {:years, :years} ->
        check_min_max_age(age_in_years, age_in_years, min_age, max_age, product_code)
    end
  end

  defp check_min_max_age(age1, age2, min_age, max_age, product_code) do
    if age1 >= min_age and age2 <= max_age do
      {:valid_birthdate}
    else
      {:invalid_birthdate_dependent, product_code}
    end
  end

  # step 14
  def validate_mobile_no(mobile) do
    mobile = String.downcase("#{mobile}")
    char = String.codepoints("=/[``~<>^\"'{}[\]\;':?!@#$%&*()_+=]|/abcdefghijklmnopqrstuvwxyz")
    valid_mobile? = String.contains?(mobile, char) == false

    with true <- valid_mobile?,
         {:valid_length} <- validate_mobile_length(mobile),
         true <- String.starts_with?(mobile, "09")
    do
      {:valid_mobile_no}
    end
  end

  defp validate_mobile_length(mobile) do
    if String.length(mobile) == 11 do
      {:valid_length}
    else
      {:invalid_length}
    end
  end

  # step 15
  def validate_email(email) do
    char = String.codepoints("=/[``~<>^\"'{}[\]\;':?!#$%&*()+=]|/")
    valid_email? = String.contains?(email, char) == false

    with true <- String.contains?(email, "@"),
         true <- String.contains?(email, "."),
         true <- valid_email?
    do
      {:valid_email}
    end
  end

  # step 16
  def validate_step_16(date_hired, regularization_date, member_type) do
    member_type = String.downcase(member_type)
    empty_date_hired? = date_hired == ""
    empty_regularization_date? = regularization_date == ""

    case member_type do
      "principal" ->
        cond do
          empty_date_hired? && empty_regularization_date? ->
            {:valid_dates, "valid_date"}

          empty_date_hired? == false && empty_regularization_date? == false ->
           validate_hired_n_regularization(date_hired, regularization_date)

          empty_date_hired? ->
            validate_regularization_date(regularization_date)

          true ->
            validate_hired(date_hired)
        end

      _ ->
        {:valid_dates, "valid_date"}
        # cond do
        #  empty_date_hired? == false && empty_regularization_date? == false ->
        #    validate_hired_n_regularization(date_hired, regularization_date)

        #  empty_date_hired? && empty_regularization_date? ->
        #   {:empty_dates}

        #  empty_date_hired? ->
        #    case validate_regularization_date(regularization_date) do
        #      {:valid_dates, message} ->
        #        {:valid_dates, "valid_date"}
        #      _ ->
        #        {:invalid_regularization_date}
        #    end

        #  empty_regularization_date? ->
        #    case validate_date_hired(date_hired) do
        #      {:valid_dates, message} ->
        #        {:valid_dates, "valid_date"}
        #      _ ->
        #        {:invalid_date_hired}
        #    end

        #  true ->
        #   {:empty_dates}
        # end
    end
  end

  defp validate_hired_n_regularization(date_hired, regularization_date) do
    with {:valid_date_hired, date_hired} <- date_cast_checker(date_hired, "date_hired"),
         {:valid_regularization_date, regularization_date} <- date_cast_checker(regularization_date, "regularization_date"),
         :lt <- compare_date(date_hired, regularization_date)
    do
      {:valid_dates, "valid_date"}
    else
      {:invalid_date_hired} ->
        regularization_date = date_cast_checker(regularization_date, "regularization_date")
        case regularization_date do
          {:valid_regularization_date, _date} ->
            {:invalid_date_hired}
          _ ->
            {:invalid_date_hired_n_regularization_date}
        end

      {:invalid_regularization_date} ->
        {:invalid_regularization_date}

      :eq ->
        {:valid_dates, "valid_date"}

      :gt ->
        {:invalid_dates}

      _ ->
        {:invalid_date_format}
    end
  end

  defp validate_hired(date_hired) do
    case date_cast_checker(date_hired, "date_hired") do
      {:valid_date_hired, _date_hired} ->
        {:valid_dates, "valid_date"}
      _ ->
        {:invalid_date_hired}
    end
  end

  defp validate_date_hired(date_hired) do
    with {:true, date} <- validate_date(date_hired) do
      {:valid_dates, "Please enter Regularization Date"}
    else
      _ ->
        {:invalid_date_hired}
    end
  end

  defp validate_regularization_date(regularization_date) do
    with {:true, date} <- validate_date(regularization_date) do
      {:valid_dates, "Please enter Date Hired"}
    else
      _ ->
        {:invalid_regularization_date}
    end
  end

  defp date_cast_checker(date, type) do
    with {:true, date} <- validate_date(date) do
      {String.to_atom(Enum.join(["valid_", type])), date}
    else
      _ ->
        {String.to_atom(Enum.join(["invalid_", type]))}
    end
  end

  defp compare_date(date1, date2) do
    date1
    |> Ecto.Date.cast!()
    |> Ecto.Date.compare(Ecto.Date.cast!(date2))
  rescue
    Ecto.CastError ->
      {:invalid_date}
    _ ->
      {:invalid_date}
  end

  # step 17
  def validate_step_17(product_code, account_code, birthdate, member_type, relationship) do
    with {:valid_product_code, product_codes} <- validate_product_code(product_code),
         {:valid_all_product_codes} <- validate_products(product_codes, account_code),
         {:true, birthdate} <- validate_date(birthdate),
         {:valid_all_product_codes} <- validate_age_eligibility(
                                         product_codes,
                                         account_code,
                                         birthdate,
                                         member_type,
                                         relationship)
    do
      {:valid_product_codes}
    end
  end

  defp validate_product_code(product_code) do
    {:valid_product_code, String.split(product_code, ",")}
  rescue
    _ ->
      {:invalid_product_code_format}
  end

  defp validate_products(product_codes, account_code) do
    account_group = AccountContext.get_account_by_code(account_code)
    account = AccountContext.get_active_account(account_group.id)

    product = for product_code <- product_codes do
     product = AccountContext.get_account_product_by_code(account.id, product_code)

     if Enum.empty?(product) do
        product_code
     end
   end

    p = Enum.filter(product, fn(product) -> is_nil(product) == false end)

    if Enum.empty?(p) do
      {:valid_all_product_codes}
    else
      products = Enum.into(p, [], fn(product_code) -> Enum.join(["This ", product_code, " is not within the account"]) end)
      {:invalid_product_codes, products}
    end
  end

  defp validate_age_eligibility(product_codes, account_code, birthdate, member_type, relationship) do
#    if String.downcase(member_type) == "dependent" do
#      {:valid_all_product_codes}
#    else
      account_group = AccountContext.get_account_by_code(account_code)
      account = AccountContext.get_active_account(account_group.id)

      product = for product_code <- product_codes do
       product = AccountContext.get_account_product_by_code(account.id, product_code)
        account_product = Enum.at(product, 0)
        product = MemberContext.get_product(account_product.product_id)
        if String.downcase(member_type) == "dependent" do
          if Enum.member?(["spouse", "parent"], String.downcase(relationship)) do
            min_age = product.adult_dependent_min_age
            max_age = product.adult_dependent_max_age
            min_type =
              product.adult_dependent_min_type
              |> String.downcase()
              |> String.to_atom()

            max_type =
              product.adult_dependent_max_type
              |> String.downcase()
              |> String.to_atom()
          else
            min_age = product.minor_dependent_min_age
            max_age = product.minor_dependent_max_age
            min_type =
              product.minor_dependent_min_type
              |> String.downcase()
              |> String.to_atom()

            max_type =
              product.minor_dependent_max_type
              |> String.downcase()
              |> String.to_atom()
          end

          min_max_type = {min_type, max_type}

          case minor_dependent_age_checker(min_max_type, min_age, max_age, birthdate, product_code) do
            {:valid_birthdate} ->
              nil
            _ ->
              product_code
          end
        else
          case check_product_age_eligibility_principal(birthdate, product) do
            {:valid_birthdate} ->
              nil
            _ ->
              product_code
          end
        end
     end
      p = Enum.filter(product, fn(product) -> is_nil(product) == false end)

      if Enum.empty?(p) do
        {:valid_all_product_codes}
      else
        products = Enum.into(p, [], fn(product_code) -> Enum.join(["Member's age is not eligible for ", product_code]) end)
        {:invalid_members_age, products}
      end
#    end
  end

  defp error_account(message) do
    #member_type = String.downcase(member_type)
    error_account? =
      message
      |> Enum.join(", ")
      |> String.contains?(["Account Code", "account"])

      #member_type? = Enum.member?(["principal", "guardian"], member_type)

    if error_account? do
      {:error, true}
    else
      {:ok, false}
    end
  end

  # step 18
  def validate_step_18(for_card_issuance) do
    with {:valid, boolean} <- transform_to_boolean(for_card_issuance) do
      {:valid, boolean}
    end
  end

  defp transform_to_boolean(params) do
    case String.downcase("#{params}") do
      "yes" ->
        {:valid, true}
      "no" ->
        {:valid, false}
      _ ->
        {:invalid_data}
    end
  end

  # step 19
  def validate_employee_no(account_code, employee_no, member_type) do
    case String.downcase(member_type) do
      "dependent" ->
        member = MemberContext.get_member_by_code_n_employee(account_code, employee_no)
        if Enum.empty?(member) do
          {:invalid_employee_no}
        else
          {:valid_employee_no}
        end

      _ ->
        {:valid_employee_no}
    end
  end

  # step 20
  def validate_tin(tin_no) do
    if is_nil(tin_no) or tin_no == "" do
      {:valid_tin_no}
    else
      validate_tin = Enum.map(String.split(tin_no, "-"), & (if String.length(&1) != 3, do: true))
      cond do
        #Regex.match?(~r/\d{3}-*$/, tin_no) == false ->
          #  {:invalid_tin_no}
        Regex.match?(~r/^[0-9]*$/, String.replace(tin_no, "-", "")) == false ->
          {:invalid_tin_no}
        String.length(String.replace(tin_no, "-", "")) != 12 ->
          {:invalid_tin_count}
        Enum.count(validate_tin) != 1 && Enum.member?(validate_tin, true) ->
          {:invalid_tin_no}
        true ->
          {:valid_tin_no}
      end
    end
  end

  # step 21
  def validate_philhealth(philhealth) do
    philhealth = String.downcase(philhealth)

    valid_philhealth = [
      "required to file",
      "optional to file",
      "not covered"
    ]

    if Enum.member?(valid_philhealth, philhealth) do
      {:valid_philhealth}
    else
      {:invalid_philhealth}
    end

  end

  # step 22
  def validate_phil_no(philhealth, phil_no, data) do
    philhealth = String.downcase(philhealth)
    # if Enum.member?(["required to file", "optional to file"], philhealth) do
    if phil_no != "" do
      cond do
        # phil_no == "" ->
        #   {:is_nil}
        Regex.match?(~r/^[0-9]*$/, phil_no) == false ->
          {:invalid_phil_no}
        String.length(phil_no) != 12 ->
          {:invalid_phil_count}
        true ->
          {:valid_phil_no, data}
      end
    else
      {:valid_phil_no, Map.put(data, "Philhealth No", "")}
    end
  end

  # step 23
  def invalid_dependent?(message) do
    error_messages = [
      "Please enter Account Code",
      "Please enter Member Type",
      "Please enter Employee No",
      "Please enter Relationship",
      "Please enter Birthdate",
      "Invalid Relationship",
      "Invalid Member Type",
      "Invalid birthdate",
      "Employee No does not exist",
      "Account Code does not exist",
      "This employee no cannot be enrolled",
      "The account you entered"
    ]

    message
    |> Enum.join(", ")
    |> String.contains?(error_messages)
  end

  def validate_younger_dependent(member_file_upload_id, params) do
    file_logs = MemberContext.get_member_file_logs(member_file_upload_id, params)

    with false <- Enum.empty?(file_logs),
         {:ok, birthdate} <- filter_logs(file_logs),
         :gt <- validate_older_dependent_birthdate(birthdate, params.birthdate)
    do
      {:error_older}
    else
      _ ->
       {:valid_dependent}
    end
  end

  defp filter_logs(file_logs) do
    birthdate =
      file_logs
      |> filter_logs_by_birthdate()
      |> get_logs_birthdate()
      |> Enum.sort()
      |> List.first()

    if is_nil(birthdate) do
      birthdate
    else
      {:ok, birthdate}
    end
  end

  defp filter_logs_by_birthdate(file_logs) do
    Enum.reject(file_logs, fn(file_log) ->
      String.contains?(file_log.upload_status, ["Invalid birthdate", "Please enter Birthdate"])
    end)
  end

  defp get_logs_birthdate(file_logs) do
    Enum.into(file_logs, [], fn(file_log) ->
      {:true, birthdate} =
        file_log
        |> Map.delete(:upload_status)
        |> Map.values
        |> List.first()
        |> validate_date()
        Ecto.Date.to_string(birthdate)
    end)
  end

  defp validate_older_dependent_birthdate(older_birthdate, birthdate) do
    {:true, birthdate} = validate_date(birthdate)
    older_birthdate = Ecto.Date.cast!(older_birthdate)

    birthdate
    |> Ecto.Date.cast!()
    |> Ecto.Date.compare(older_birthdate)
  end

  # step 24
  def invalid_step_24?(message) do
    error_messages = [
      "Please enter Account Code",
      "Please enter Member Type",
      "Please enter Employee No",
      "Please enter Relationship",
      "Invalid Relationship",
      "Invalid Member Type",
      "Invalid birthdate",
      "Employee No does not exist",
      "Account Code does not exist",
      "This employee no cannot be enrolled",
      "The account you entered"
    ]

    message
    |> Enum.join(", ")
    |> String.contains?(error_messages)
  end

  # HOED: Hierarchy of Eligible Dependent
  def validate_step_24(params) do
    member = MemberContext.get_employee_no_by_account_code(params.employee_no, params.account_code)
    with ag = %AccountGroup{} <- AccountContext.get_account_by_code(params.account_code),
         member = %Member{} <- List.first(member),
         false <- Enum.empty?(hoeds = AccountContext.get_hoed(ag, member.civil_status))
    do
      if String.downcase(member.civil_status) == "separated" do
        validate_step_24_2(hoeds, member, params)
      else
        validate_step_24_1(hoeds, member, params)
      end
    else
      nil ->
        {:member_not_found}
      {:account_not_found} ->
        {:account_not_found}
      true ->
        {:no_hierarchy_set}
    end
  end

  defp validate_step_24_1(hoeds, member, params) do
    relationship = get_hoed_relationships(hoeds)
    with true <- Enum.member?(relationship, params.relationship),
         [ahoed] <- filter_hoed(hoeds, params)
    do
      if ahoed.ranking == 1 do
        {:valid_hierarchy}
      else
        dependents = get_hoeds_dependent(hoeds, ahoed)
        member_dependents = get_member_dependents(member)
        skipped = dependents -- member_dependents

        if Enum.empty?(skipped) do
          {:valid_hierarchy}
        else
          {:skipped_dependents, skipped}
        end
      end
    else
      false ->
        {:not_found_relationship, relationship}
    end
  end

  defp get_hoed_relationships(hoeds) do
    Enum.into(hoeds, [], fn(hoed) ->
      String.downcase(hoed.dependent)
    end)
  end

  defp filter_hoed(hoeds, params) do
    Enum.filter(hoeds, fn(hoed) ->
      String.downcase(hoed.dependent) == params.relationship
    end)
  end

  defp get_hoeds_dependent(hoeds, ahoed) do
    hoeds
    |> Enum.filter(fn(hoed) ->
      hoed.ranking < ahoed.ranking
    end)
    |> Enum.into([], fn(hoed) ->
      String.downcase(hoed.dependent)
    end)
  end

  defp get_member_dependents(member) do
    member
    |> MemberContext.preload_dependents()
    |> Enum.into([], fn(member) ->
        String.downcase(member.relationship)
       end)
  end

  defp validate_step_24_2(hoeds, member, params) do
    relationship =
      Enum.into(hoeds, [], fn(hoed) ->
        String.downcase(hoed.dependent)
      end)

    with true <- Enum.member?(relationship, params.relationship),
         [ahoed] <- filter_hoed(hoeds, params)
    do
      cond do
        params.relationship == "spouse" ->
#          dependents =
#            hoeds
#            |> Enum.filter(fn(hoed) ->
#                String.downcase(hoed.dependent) != "spouse"
#               end)
#            |> Enum.into([], fn(hoed) ->
#                String.downcase(hoed.dependent)
#               end)
#          member_dependents =
#            member
#            |> MemberContext.preload_dependents()
#            |> Enum.into([], fn(member) ->
#                String.downcase(member.relationship)
#               end)
#
#          skipped = dependents -- member_dependents
#
#          if Enum.empty?(skipped) do
#            {:valid_hierarchy}
#          else
#            {:skip_spouse_first}
#          end
            {:skip_spouse_first}

        ahoed.ranking == 1 ->
          {:valid_hierarchy}

        true ->
          dependents = get_hoeds_dependent(hoeds, ahoed)
          dependents = dependents -- ["spouse"]
          member_dependents = get_member_dependents(member)
          skipped = dependents -- member_dependents

          if Enum.empty?(skipped) do
            {:valid_hierarchy}
          else
            {:skipped_dependents, skipped}
          end
      end
    else
      false ->
        {:not_found_relationship, relationship}
    end
  end

  # validate remarks
  def validate_step_25(remarks) do
    if is_nil(remarks) or remarks == "" do
      {:valid_remarks}
    else
      if String.length(remarks) > 250 do
        {:invalid_remarks}
      else
        {:valid_remarks}
      end
    end
  end

  defp optional_keys do
    [
      "Policy No",
      "Date Hired",
      "Regularization Date",
      "Address",
      "City",
      "Middle Name",
      "Suffix",
      "Relationship",
      "Tin No",
      "Philhealth No",
      "Expiry Date",
      "Remarks",
      "Middle Name / Initial"
    ]
  end

  def member_params(data) do
    # Optional for Dependent member type
    {:true, date_hired} = date_hired_value(data)
    {:true, regularization_date} = regularization_date_value(data)
    {:true, birthdate} = validate_date(data["Birthdate"])
    {:true, effective_date} = validate_date(data["Effective Date"])
    {:true, expiry_date} = expiry_date_value(data)
    {:valid, for_card_issuance} = transform_to_boolean(data["For Card Issuance"])
    card_no = Member.changeset_card(%Member{}, %{card_no: ""})

    if card_no.valid? do
      card_no = card_no.changes.card_no
      tin_no = String.replace(data["Tin No"], "-", "")
      %{
        account_code: data["Account Code"],
        employee_no: data["Employee No"],
        type: transform_case(data["Member Type"]),
        relationship: transform_case(data["Relationship"]),
        effectivity_date: effective_date,
        expiry_date: expiry_date,
        first_name: data["First Name"],
        middle_name: data["Middle Name / Initial"],
        last_name: data["Last Name"],
        suffix: data["Suffix"],
        gender: transform_case(data["Gender"]),
        civil_status: transform_case(data["Civil Status"]),
        birthdate: birthdate,
        address: data["Address"],
        mobile: data["Mobile No"],
        email: data["Email"],
        date_hired: date_hired,
        regularization_date: regularization_date,
        city: data["City"],
        for_card_issuance: for_card_issuance,
        created_by_id: data["created_by_id"],
        updated_by_id: data["updated_by_id"],
        card_no: card_no,
        step: 5,
        tin: tin_no,
        philhealth_type: data["Philhealth"],
        philhealth: data["Philhealth No"],
        enrollment_date: effective_date,
        status: "Pending"
      }
    else
      {error, _} = Keyword.get(card_no.errors, :card_no)
      {:error, error}
    end
  end

  def member_paramsv2(data) do
    # Optional for Dependent member type
    {:true, date_hired} = date_hired_value(data)
    {:true, regularization_date} = regularization_date_value(data)
    {:true, birthdate} = validate_date(data["Birthdate"])
    {:true, effective_date} = validate_date(data["Effective Date"])
    {:true, expiry_date} = expiry_date_value(data)
    {:valid, for_card_issuance} = transform_to_boolean(data["For Card Issuance"])

      tin_no = String.replace(data["Tin No"], "-", "")
      %{
        account_code: data["Account Code"],
        employee_no: data["Employee No"],
        type: transform_case(data["Member Type"]),
        relationship: transform_case(data["Relationship"]),
        effectivity_date: effective_date,
        expiry_date: expiry_date,
        first_name: data["First Name"],
        middle_name: data["Middle Name / Initial"],
        last_name: data["Last Name"],
        suffix: data["Suffix"],
        gender: transform_case(data["Gender"]),
        civil_status: transform_case(data["Civil Status"]),
        birthdate: birthdate,
        address: data["Address"],
        mobile: data["Mobile No"],
        email: data["Email"],
        date_hired: date_hired,
        regularization_date: regularization_date,
        city: data["City"],
        for_card_issuance: for_card_issuance,
        created_by_id: data["created_by_id"],
        updated_by_id: data["updated_by_id"],
        # card_no: card_no,
        step: 5,
        tin: tin_no,
        philhealth_type: data["Philhealth"],
        philhealth: data["Philhealth No"],
        enrollment_date: effective_date,
        status: "Pending"
      }
  end

  defp date_hired_value(data) do
    cond do
      data["Member Type"] == "Dependent" ->
        {:true, nil}
      String.downcase(data["upload_type"]) == "individual, family, group (ifg)" ->
        {:true, nil}
      data["Date Hired"] == "" ->
        {:true, nil}
      true ->
        {:true, date_hired} = validate_date(data["Date Hired"])
    end
  end

  defp regularization_date_value(data) do
    cond do
      data["Member Type"] == "Dependent" ->
        {:true, nil}
      String.downcase(data["upload_type"]) == "individual, family, group (ifg)" ->
        {:true, nil}
      data["Regularization Date"] == "" ->
        {:true, nil}
      true ->
        {:true, regularization_date} = validate_date(data["Regularization Date"])
    end
  end

  defp expiry_date_value(data) do
    if data["Expiry Date"] == "" or is_nil(data["Expiry Date"]) do
      account_group = AccountContext.get_account_by_code(data["Account Code"])
      account = AccountContext.get_active_account(account_group.id)
      {:true, account.end_date}
    else
      validate_date(data["Expiry Date"])
    end
  rescue
    _ ->
     {:true,  data["Expiry Date"]}
  end

  defp transform_case(data) do
    data
    |> String.downcase()
    |> String.capitalize()
  end

  defp logs_params(data, card_no) do
    {:true, date_hired} = date_hired_log_value(data)
    {:true, regularization_date} = regularization_date_log_value(data)
    {:true, expiry_date} = expiry_date_log_value(data)

    %{
      account_code: data["Account Code"],
      employee_no: data["Employee No"],
      type: data["Member Type"],
      relationship: data["Relationship"],
      first_name: data["First Name"],
      middle_name: data["Middle Name / Initial"],
      last_name: data["Last Name"],
      suffix: data["Suffix"],
      gender: data["Gender"],
      civil_status: data["Civil Status"],
      address: data["Address"],
      mobile: data["Mobile No"],
      email: data["Email"],
      city: data["City"],
      birthdate: "#{data["Birthdate"]}",
      effectivity_date: "#{data["Effective Date"]}",
      expiry_date: "#{expiry_date}",
      date_hired: "#{date_hired}",
      regularization_date: "#{regularization_date}",
      for_card_issuance: data["For Card Issuance"],
      tin_no: data["Tin No"],
      philhealth: data["Philhealth"],
      philhealth_no: data["Philhealth No"],
      card_no: card_no,
      remarks: data["Remarks"]
    }
  end

  defp logs_paramsv2(data) do
    {:true, date_hired} = date_hired_log_value(data)
    {:true, regularization_date} = regularization_date_log_value(data)
    {:true, expiry_date} = expiry_date_log_value(data)

    %{
      account_code: data["Account Code"],
      employee_no: data["Employee No"],
      type: data["Member Type"],
      relationship: data["Relationship"],
      first_name: data["First Name"],
      middle_name: data["Middle Name / Initial"],
      last_name: data["Last Name"],
      suffix: data["Suffix"],
      gender: data["Gender"],
      civil_status: data["Civil Status"],
      address: data["Address"],
      mobile: data["Mobile No"],
      email: data["Email"],
      city: data["City"],
      birthdate: "#{data["Birthdate"]}",
      effectivity_date: "#{data["Effective Date"]}",
      expiry_date: "#{expiry_date}",
      date_hired: "#{date_hired}",
      regularization_date: "#{regularization_date}",
      for_card_issuance: data["For Card Issuance"],
      tin_no: data["Tin No"],
      philhealth: data["Philhealth"],
      philhealth_no: data["Philhealth No"],
      remarks: data["Remarks"]
    }
  end

  defp date_hired_log_value(data) do
    cond do
      data["Member Type"] == "Dependent" ->
        {:true, nil}
      String.downcase(data["upload_type"]) == "individual, family, group (ifg)" ->
        {:true, nil}
      data["Date Hired"] == "" ->
        {:true, nil}
      true ->
        {:true, data["Date Hired"]}
    end
  end

  defp regularization_date_log_value(data) do
    cond do
      data["Member Type"] == "Dependent" ->
        {:true, nil}
      String.downcase(data["upload_type"]) == "individual, family, group (ifg)" ->
        {:true, nil}
      data["Regularization Date"] == "" ->
        {:true, nil}
      true ->
        {:true, data["Regularization Date"]}
    end
  end

  defp expiry_date_log_value(data) do
    expiry_date = data["Expiry Date"]
    if String.trim("#{expiry_date}") == "" do
      with {:true, expiry_date} <- expiry_date_value(data) do
        {:true, expiry_date}
      else
        {:invalid_date} ->
          {:true, expiry_date}
        _ ->
          {:true, expiry_date}
      end
    else
      {:true, expiry_date}
    end
  end

  def insert_member(data) do
    case String.downcase(data.type) do
      "dependent" ->
          member =
            data.employee_no
            |> MemberContext.get_employee_no_by_account_code(data.account_code)
            |> List.first()

            data
            |> Map.put(:principal_id, member.id)
            |> Map.put(:employee_no, nil)
            |> MemberContext.create_member_parsed()
      _ ->
        data
        |> Map.delete(:relationship)
        |> MemberContext.create_member_parsed()
    end
  end

  def insert_products(member_id, account_code, product_codes) do
    account_group = AccountContext.get_account_by_code(account_code)
    account = AccountContext.get_active_account(account_group.id)

    Enum.each(String.split(product_codes, ","), fn(product_code) ->
     account_product =
       account.id
       |> AccountContext.get_account_product_by_code(product_code)
       |> List.first()

      MemberContext.set_member_products(member_id, [account_product.id], :batch_upload)
    end)
  end

  defp insert_log(params, status, upload_status) do
    params
    |> Map.put(:status, status)
    |> Map.put(:upload_status, upload_status)
    |> MemberContext.create_member_upload_log()
  end

  def insert_member_comment(member_id, comment, user_id) do
    MemberContext.insert_single_comment(member_id, comment, user_id)
  end

  defp insert_error(data, filename, member_file_upload_id, user_id, error) do
    data
    |> logs_params()
    |> Map.put(:member_upload_file_id, member_file_upload_id)
    |> Map.put(:product_code, "#{data["Plan Code"]}")
    |> Map.put(:filename, filename)
    |> Map.put(:created_by_id, user_id)
    |> insert_log("failed", error)
  end
  # Dev: R.Navarro Creator
  # Dev: J.Visayan Additional Validations

  def parse_cop_data(
    data,
    filename,
    user_id,
    upload_type,
    account_code
  ) do
    data = Enum.drop(data, 1)
    batch_no =
      MemberContext.get_member_upload_logs()
      |> Enum.count()
      |> MemberContext.generate_batch_no()

    file_params = %{
      filename: filename,
      created_by_id: user_id,
      batch_no: batch_no,
      upload_type: upload_type,
      remarks: "ok"
    }
    {:ok, member_file_upload} = MemberContext.create_member_upload_file(file_params)

    Enum.each(data, fn({_, data}) ->
      params = %{
        coped: data["Change of Plan Effective Date"],
        member_id: data["Member ID"],
        new_product_code: data["New Plan Code"],
        old_product_code: data["Old Plan Code"],
        reason: data["Reason"],
        error: []
      }

      general_types = %{
        coped: :string,
        member_id: :string,
        new_product_code: :string,
        old_product_code: :string,
        reason: :string,
        error: {:array, :string}
      }

      changeset =
        {%{}, general_types}
        |> cast(params, Map.keys(general_types))
        |> validate_if_required(:coped, "Change of Plan Effective Date")
        |> validate_if_required(:member_id, "Member ID")
        |> validate_if_required(:new_product_code, "New Plan Code")
        |> validate_if_required(:old_product_code, "Old Plan Code")
        |> validate_if_required(:reason, "Reason")

      level1_errors =
        changeset.changes[:error]
        |> List.flatten

      if Enum.empty?(level1_errors) do
        changeset =
          changeset
          |> validate_member_id

        level2_errors =
          changeset.changes[:error]
          |> List.flatten

        if Enum.empty?(level2_errors) do
          changeset =
            changeset
              |> validate_reason
              |> validate_coped
              |> validate_new_product
              |> validate_old_product

          errors =
            changeset.changes[:error]
            |> List.flatten

          if Enum.empty?(errors) do
            insert_cop(changeset)
            member = MemberContext.get_member!(changeset.changes[:member_id])
            cop_log = ProductContext.insert_change_of_product_log(
              %{
                change_of_product_effective_date: changeset.changes[:old_product_code],
                member_id: member.id,
                reason: changeset.changes[:reason],
                user: user_id
              }
            )
            ProductContext.insert_changed_member_product(
              %{
                cop_log_id: cop_log.id,
                new_product_code: changeset.changes[:new_product_code],
                old_product_code: changeset.changes[:old_product_code]
              }
            )
            MemberContext.delete_cop_member_products(
              changeset.changes[:old_product_code],
              member
            )
            MemberContext.reassign_tier_cop_mp(
              member.id
            )
            MemberContext.update_cop_member_products(
              changeset.changes[:new_product_code],
              member
            )
            insert_log_cop_success(data, filename, member_file_upload.id, user_id, member.card_no)
            remarks = %{
              "comment" => "Member successfully updated"
            }
            insert_member_comment(member.id, remarks, user_id)
          else
            errors =
              changeset.changes[:error]
              |> List.flatten
              |> Enum.join(", ")
            insert_log_cop_failed(data, filename, member_file_upload.id, user_id, errors)
          end
        else
          errors =
            changeset.changes[:error]
            |> List.flatten
            |> Enum.join(", ")
          insert_log_cop_failed(data, filename, member_file_upload.id, user_id, errors)
        end
      else
        errors =
          changeset.changes[:error]
          |> List.flatten
          |> Enum.join(", ")
        insert_log_cop_failed(data, filename, member_file_upload.id, user_id, errors)
      end
    end)
  end

  defp insert_log_cop_success(data, filename, member_file_upload_id, user_id, card_no) do
    data
    |> cop_logs_params(card_no)
    |> Map.put(:member_upload_file_id, member_file_upload_id)
    |> Map.put(:member_id, "#{data["Member ID"]}")
    |> Map.put(:filename, filename)
    |> Map.put(:created_by_id, user_id)
    |> insert_cop_log("success", "Plan of this member was successfully updated")
  end

  defp insert_log_cop_failed(data, filename, member_file_upload_id, user_id, message) do
    data
    |> cop_logs_params("")
    |> Map.put(:member_upload_file_id, member_file_upload_id)
    |> Map.put(:member_id, "#{data["Member ID"]}")
    |> Map.put(:filename, filename)
    |> Map.put(:created_by_id, user_id)
    |> insert_cop_log("failed", message)
  end

  defp cop_logs_params(data, card_no) do
    %{
      change_of_product_effective_date: data["Change of Plan Effective Date"],
      new_product_code: data["New Plan Code"],
      old_product_code: data["Old Plan Code"],
      reason: data["Reason"]
    }
  end

  defp insert_cop_log(params, status, upload_status) do
    params
    |> Map.put(:status, status)
    |> Map.put(:upload_status, upload_status)
    |> MemberContext.create_member_cop_upload_log()
  end

  defp validate_reason(changeset) do
    reason_count =
      changeset.changes[:reason]
      |> String.split("")
      |> Enum.count

    if reason_count > 255 do
      error_val = changeset.changes[:error] ++ ["Reason must only be 255 characters"]
      put_change(changeset, :error, error_val)
    else
      changeset
    end
  end

  defp validate_if_required(changeset, field, field_name) do
    value = changeset.changes[field]
    if value == "" or is_nil(value) do
      error_val = changeset.changes[:error] ++ ["Please enter #{field_name}"]
      put_change(changeset, :error, error_val)
    else
      changeset
    end
  end

  defp insert_cop(changeset) do
    {:true, coped} =
      changeset.changes[:coped]
      |> validate_date

    member = MemberContext.get_member!(changeset.changes[:member_id])
    member =
      member
      |> Member.update_cop_changeset(%{cop_effective_date: coped})
      |> Repo.update!
  end

  defp validate_member_id(changeset) do
    member_id = changeset.changes[:member_id]

    case UtilityContext.valid_uuid?(member_id) do
      {true, id} ->
        result = Repo.get(Member, member_id)
        if not is_nil(result) do
          validate_member_id_level2(changeset)
        else
          error_val = changeset.changes[:error] ++ ["Member does not exist"]
          put_change(changeset, :error, error_val)
        end
      {:invalid_id} ->
        error_val = changeset.changes[:error] ++ ["Invalid member id"]
        put_change(changeset, :error, error_val)
    end
  end

  defp validate_member_id_level2(changeset) do
    member =
      Member
      |> Repo.get(changeset.changes[:member_id])

    case String.upcase(member.status) do
      "CANCELLED" ->
        error_val = changeset.changes[:error] ++ ["The member you entered is cancelled"]
        put_change(changeset, :error, error_val)
      "SUSPENDED" ->
        error_val = changeset.changes[:error] ++ ["The member you entered is suspended"]
        put_change(changeset, :error, error_val)
      _ ->
        changeset
    end
  end

  defp validate_coped(changeset) do
    coped = changeset.changes[:coped]

    with {:true, date} <- validate_date(coped)
    do
      validate_coped_level2(changeset)
    else
      _ ->
        error_val = changeset.changes[:error] ++ ["Invalid effective date, date must be in mmm dd yyyy format"]
        put_change(changeset, :error, error_val)
    end
  end

  defp validate_coped_level3(changeset) do
    member =
      Member
      |> Repo.get(changeset.changes[:member_id])

    coped =
      changeset.changes[:coped]
      |> String.split("/")

    today = Date.utc_today()

    with true <- cti(Enum.at(coped, 0)) >= today.month,
         true <- validate_cop_day(coped, today.day, today.month),
         true <- cti(Enum.at(coped, 2)) >= today.year
    do
      changeset
    else
      _ ->
        error_val = changeset.changes[:error] ++ ["Date must be current date or future dated"]
        put_change(changeset, :error, error_val)
    end
  end

  defp validate_cop_day(coped, current_day, current_month) do
    month = cti(Enum.at(coped, 0))
    day = cti(Enum.at(coped, 1))

    if month == current_month do
      if day >= current_day do
        true
      else
        false
      end
    else
      true
    end
  end

  defp cti(str), do: String.to_integer(str)

  defp validate_coped_level2(changeset) do
    member =
      Member
      |> Repo.get(changeset.changes[:member_id])

    {:true, coped_date} =
      changeset.changes[:coped]
      |> validate_date

    member =
      Member
      |> Repo.get(changeset.changes[:member_id])

    with true <- validate_member_date(
                  coped_date,
                  member.effectivity_date,
                  member.expiry_date
                ),
         true <- validate_member_date(
                  coped_date,
                  member.cancel_date
                ),
         true <- validate_member_date(
                  coped_date,
                  member.suspend_date
                )
    do
      validate_coped_level3(changeset)
    else
      {:invalid_member_range} ->
        error_val = changeset.changes[:error] ++ ["Date must be within the coverage period of the member"]
        put_change(changeset, :error, error_val)
      {:invalid_cancel_suspend} ->
        error_val = changeset.changes[:error] ++ ["Date must not be greater than future cancellation and/or suspension date of the member"]
        put_change(changeset, :error, error_val)
    end
  end

  def validate_member_date(
    coped_date,
    effectivity_date,
    expiry_date
  ) do
    result_effectivity =
      case Ecto.Date.compare(coped_date, effectivity_date) do
        :lt ->
          false
        _ ->
          true
      end

    result_expiry =
      case Ecto.Date.compare(coped_date, expiry_date) do
        :gt ->
          false
        _ ->
          true
      end

    result = [result_effectivity, result_expiry]

    if Enum.member?(result, false) do
      {:invalid_member_range}
    else
      true
    end
  end

  def validate_member_date(
    coped_date,
    date
  ) do
    if not is_nil(date) do
      case Ecto.Date.compare(coped_date, date) do
        :gt ->
          {:invalid_cancel_suspend}
        _ ->
          true
      end
    else
      true
    end
  end

  defp validate_old_product(changeset) do
    member = MemberContext.get_member!(changeset.changes[:member_id])

    if changeset.changes[:old_product_code] == "ALL" do
      member_products =
        member.products
        |> Enum.map(
          &(
            if &1.is_archived != true, do: &1.account_product.product.code
          )
        )
        |> Enum.join(";")

      put_change(changeset, :old_product_code, member_products)
    else
      old_product_code =
        changeset.changes[:old_product_code]
        |> String.split(";")
        |> Enum.map(&(String.upcase(&1)))

      existing_product = for mp <- member.products do
        if mp.is_archived != true do
          mp.account_product.product.code
          |> String.upcase
        end
      end
      |> Enum.filter(&(not is_nil(&1)))

      result = old_product_code -- existing_product

      if Enum.empty?(result) do
        changeset
      else
        errors =
          for error <- result do
            "This #{error} is not within the member"
          end
          |> Enum.join(",")

        error_val = changeset.changes[:error] ++ [errors]
        put_change(changeset, :error, error_val)
      end
    end
  end

  defp validate_new_product(changeset) do
    member = MemberContext.get_member!(changeset.changes[:member_id])
    new_product_code =
      changeset.changes[:new_product_code]
      |> String.split(";")
      |> Enum.map(&(String.upcase(&1)))

    old_product_code =
      changeset.changes[:old_product_code]
      |> String.split(";")
      |> Enum.map(&(String.upcase(&1)))

    account =
      member.account_group.id
      |> AccountContext.get_latest_account
      |> Repo.preload([
        account_products: [
          :product
        ]
      ])

    products = for ap <- account.account_products do
      ap.product.code
      |> String.upcase
    end

    result = new_product_code -- products

    if Enum.empty?(result) do
      validate_new_product_level2(changeset)
    else
      errors =
        for error <- result do
          "This #{error} is not within the account"
        end
        |> Enum.join(",")

      error_val = changeset.changes[:error] ++ [errors]
      put_change(changeset, :error, error_val)
    end
  end

  defp validate_new_product_level2(changeset) do
    member = MemberContext.get_member!(changeset.changes[:member_id])
    new_product_code =
      changeset.changes[:new_product_code]
      |> String.split(";")
      |> Enum.map(&(String.upcase(&1)))

    old_product_code =
      member.products
      |> Enum.map(
        &(
          if &1.is_archived != true, do: &1.account_product.product.code
        )
      )
      |> Enum.join(";")
      |> String.split(";")
      |> Enum.map(&(String.upcase(&1)))

    new_product_count = Enum.count(new_product_code)
    duplicate_result = new_product_code -- old_product_code

    if Enum.count(duplicate_result) == new_product_count do
      validate_new_product_level3(changeset)
    else
      errors =
        for error <- new_product_code do
          if Enum.member?(old_product_code, error) do
            "#{error} already exists in the member"
          end
        end
        |> Enum.filter(&(not is_nil(&1)))
        |> Enum.join(",")

      error_val = changeset.changes[:error] ++ [errors]
      put_change(changeset, :error, error_val)
    end
  end

  defp validate_new_product_level3(changeset) do
    member = MemberContext.get_member!(changeset.changes[:member_id])
    new_product_code =
      changeset.changes[:new_product_code]
      |> String.split(";")
      |> Enum.map(&(String.upcase(&1)))

    account =
      member.account_group.id
      |> AccountContext.get_latest_account
      |> Repo.preload([
        account_products: [
          :product
        ]
      ])

    member = MemberContext.get_member!(changeset.changes[:member_id])

    member_age =
      member.birthdate
      |> age

    products = for ap <- account.account_products do
      if Enum.member?(new_product_code, String.upcase(ap.product.code)) do
        ap.product
      end
    end
    |> Enum.filter(&(not is_nil(&1)))

    result = for p <- products do
      age_result =
        case member.type do
          "Principal" ->
            min_age =
              p.principal_min_age
              |> convert_age_to_year(p.principal_min_type)

            max_age =
              p.principal_max_age
              |> convert_age_to_year(p.principal_max_type)

            check_mp_age_eligibility(member_age, min_age, max_age)
          "Dependent" ->
            adult_min_age =
              p.adult_dependent_min_age
              |> convert_age_to_year(p.adult_depdendent_min_type)

            adult_max_age =
              p.adult_dependent_max_age
              |> convert_age_to_year(p.adult_dependent_max_type)

            minor_min_age =
              p.minor_dependent_min_age
              |> convert_age_to_year(p.minor_depdendent_min_type)

            minor_max_age =
              p.minor_dependent_max_age
              |> convert_age_to_year(p.minor_dependent_max_type)

            overage_min_age =
              p.overage_dependent_min_age
              |> convert_age_to_year(p.overage_depdendent_min_type)

            overage_max_age =
              p.overage_dependent_max_age
              |> convert_age_to_year(p.overage_dependent_max_type)

            adult_result = check_mp_age_eligibility(member_age, adult_min_age, adult_max_age)
            minor_result = check_mp_age_eligibility(member_age, minor_min_age, minor_max_age)
            overage_result = check_mp_age_eligibility(member_age, overage_min_age, overage_max_age)

            overall_result = [
              adult_result,
              minor_result,
              overage_result
            ]

            if Enum.member?(overall_result, true) do
              true
            else
              false
            end
          "Guardian" ->
            min_age =
              p.principal_min_age
              |> convert_age_to_year(p.principal_min_type)

            max_age =
              p.principal_max_age
              |> convert_age_to_year(p.principal_max_type)

            check_mp_age_eligibility(member_age, min_age, max_age)
        end

      if age_result do
        nil
      else
        "Member's age is not eligible for #{p.code}"
      end
    end
    |> Enum.filter(&(not is_nil(&1)))

    if Enum.empty?(result) do
      changeset
      |> validate_new_product_level4()
    else
      result
      |> Enum.join(",")

      error_val = changeset.changes[:error] ++ [result]
      put_change(changeset, :error, error_val)
    end
  end

  defp validate_new_product_level4(changeset) do
    new_product_code =
      changeset.changes[:new_product_code]
      |> String.split(";")
      |> Enum.map(&(String.upcase(&1)))

    result = for pc <- new_product_code do
      product =
        Product
        |> where([p], ilike(p.code, ^pc))
        |> Repo.one()
        |> Repo.preload([
          product_coverages: :coverage
        ])

      coverage_result =
        for pc <- product.product_coverages do
          if pc.coverage.name == "ACU" do
            "ACU"
          end
        end

      if Enum.member?(coverage_result, "ACU") do
        {:has_acu}
      else
        nil
      end
    end
    |> Enum.filter(&(&1 == {:has_acu}))
    |> Enum.count

    if result > 1 do
      error_val = changeset.changes[:error] ++ ["You are only allowed to enter 1 plan with ACU Benefit"]
      put_change(changeset, :error, error_val)
    else
      changeset
    end
  end

  defp convert_age_to_year(age, type) do
    case String.upcase(type) do
      "YEARS" ->
        age
      "MONTHS" ->
        age / 12
      "WEEKS" ->
        age / 52
      "DAYS" ->
        age / 365
    end
  end

  defp check_mp_age_eligibility(
    age,
    age_from,
    age_to
  ) do
    if age >= age_from and age <= age_to do
      true
    else
      false
    end
  end

  def activate_member_on_effectivity_date(member) do
    {_, {year, month, day}} =
      member.effectivity_date
      |> Ecto.Date.dump()

    schedule = %DateTime{
      year: year,
      month: month,
      day: day,
      zone_abbr: "SGT",
      hour: 0,
      minute: 0,
      second: 0,
      microsecond: {0, 0},
      utc_offset: 28_800,
      std_offset: 0,
      time_zone: "Singapore"
    }

    Exq.Enqueuer.start_link

    # Insert in job queue
    Exq.Enqueuer
    |> Exq.Enqueuer.enqueue_at(
      "member_activation_job",
      schedule,
      "Innerpeace.Db.Worker.Job.ActivateMemberJob",
      [member.id]
    )
  end
end
