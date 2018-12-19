defmodule Innerpeace.PayorLink.Web.Api.V1.MemberControllerTest do
  use Innerpeace.PayorLink.Web.ConnCase

  alias PayorLink.Guardian.Plug
  alias Timex.Duration
  alias Innerpeace.Db.Base.Api.MemberContext
  alias Innerpeace.PayorLink.Web.Api.V1.MemberView

  setup do
    user = insert(:user, username: "masteradmin", password: "P@ssw0rd")
    random = Ecto.UUID.generate
    secure_random = "#{user.id}+#{random}"
    conn = PayorLink.Guardian.Plug.sign_in(build_conn(), secure_random)
    jwt = Plug.current_token(conn)

    test = Ecto.Date.utc()
    increment_year = test.year + 1
    month = if String.length(Integer.to_string(test.month)) == 1 do
      "0#{test.month}"
    else
      test.month
    end
    cancel_date = Ecto.Date.cast!("#{increment_year}-#{month}-08")

    member = insert(:member)
    {:ok, %{conn: conn, member: member, jwt: jwt, month: month, increment_year: increment_year, cancel_date: cancel_date}}
  end

  test "validate member details returns member with valid parameters", %{jwt: jwt} do
    account = insert(:account_group)
    insert(:member,
           account_group: account,
           birthdate: Ecto.Date.cast!("1997-01-30"),
           first_name: "Daniel Eduard",
           last_name: "Andal",
           middle_name: "Murao",
           card_no: "1168011034280092"
    )
    params = %{
      "full_name" => "Daniel Eduard Murao Andal",
      "birth_date" => "1997-01-30"
    }
    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> post(api_member_path(build_conn(), :validate_details), params: params)

    assert List.first(json_response(conn, 200))["first_name"] == "Daniel Eduard"
    assert List.first(json_response(conn, 200))["middle_name"] == "Murao"
    assert List.first(json_response(conn, 200))["last_name"] == "Andal"
    assert List.first(json_response(conn, 200))["card_no"] == "1168011034280092"
  end

  test "validate member details does not return member with invalid parameters", %{jwt: jwt} do
    params = %{
      "full_name" => "Wendy Mcdonald",
      "birth_date" => "1997-01-30"
    }
    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> post(api_member_path(build_conn(), :validate_details), params: params)

    assert json_response(conn, 404)["error"]["message"] == "Please enter valid member name/birthdate to avail ACU."
  end

  test "validate member details does not return member with invalid birth date format", %{jwt: jwt} do
    params = %{
      "full_name" => "Wendy Mcdonald",
      "birth_date" => "19978-30-021"
    }
    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> post(api_member_path(build_conn(), :validate_details), params: params)
    assert json_response(conn, 404)["error"]["message"] == "Please enter valid member name/birthdate to avail ACU."
  end

  # test "validate member card with valid card number returns member", %{conn: conn, jwt: jwt} do
  #   account = insert(:account_group)
  #   member = insert(:member, account_group: account, card_no: "1168011034280092", birthdate: "1990-01-01", status: "Active")
  #   conn =
  #     build_conn()
  #     |> put_req_header("authorization", "Bearer #{jwt}")
  #     |> post(api_member_path(conn, :validate_card), %{card_number: member.card_no, birth_date: member.birthdate})
  #   assert json_response(conn, 200)
  # end

  test "validate member card with valid card number and without token returns unauthorized", %{conn: conn} do
    member = insert(:member, card_no: "1168011034280092", birthdate: "1990-01-01")
    conn =
      build_conn()
      |> post(api_member_path(conn, :validate_card), %{card_number: member.card_no, birth_date: member.birthdate})

    assert json_response(conn, 401)["error"]["message"] == "Unauthorized"
  end

  test "validate member card with invalid card number returns not found", %{conn: conn, jwt: jwt} do
    insert(:member, card_no: "2168011034280092")
    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> post(api_member_path(conn, :validate_card), %{card_number: "168011034280092", birth_date: "1990-01-01"})

    assert json_response(conn, 404)["error"]["message"] == "Member not found"
  end

  test "validate member card with invalid card number and without token returns unauthorized", %{conn: conn} do
    insert(:member, card_no: "2168011034280092")
    conn =
      build_conn()
      |> post(api_member_path(conn, :validate_card), %{card_number: "168011034280092", birth_date: "1990-01-01"})

    assert json_response(conn, 401)["error"]["message"] == "Unauthorized"
  end

  ################################# start of member_cancellation #######################################################

  test "post /member_cancellation, cancels member according to card_no", %{month: month, cancel_date: cancel_date, increment_year: increment_year, conn: conn} do
    insert(:member, card_no: "9999993333311111", expiry_date: Ecto.Date.cast!("#{increment_year}-#{month}-20"), status: "Active")
    params = %{
      card_no: "9999993333311111",
      cancel_date: Ecto.Date.to_string(cancel_date),
      cancel_reason: "test cancel",
      cancel_remarks: "test remarks"
    }
    conn =
      conn
      |> post(api_member_path(conn, :member_cancellation, params))
    assert json_response(conn, 200)
  end

  test "post /member_cancellation, with invalid card no param", %{month: month, cancel_date: cancel_date, increment_year: increment_year, conn: conn} do
    insert(:member, card_no: "9999993333311111", expiry_date: Ecto.Date.cast!("#{increment_year}-#{month}-20"), status: "Active")
    params = %{
      card_no: "9999993333311111wotuhj",
      cancel_date: Ecto.Date.to_string(cancel_date),
      cancel_reason: "test cancel",
      cancel_remarks: "test remarks"
    }
    conn =
      conn
      |> post(api_member_path(conn, :member_cancellation, params))
    assert json_response(conn, 400)["errors"] == %{"card_no" => ["card no. not existing"]}
  end

  test "post /member_cancellation, without cancel_reason param", %{month: month, cancel_date: cancel_date, increment_year: increment_year, conn: conn} do
    insert(:member, card_no: "9999993333311111", expiry_date: Ecto.Date.cast!("#{increment_year}-#{month}-20"), status: "Active")
    params = %{
      card_no: "9999993333311111",
      cancel_date: Ecto.Date.to_string(cancel_date),
      cancel_reason: "",
      cancel_remarks: "test remarks"
    }
    conn =
      conn
      |> post(api_member_path(conn, :member_cancellation, params))

    assert json_response(conn, 400)["errors"] == %{"cancel_reason" => ["can't be blank"]}
  end

  test "post /member_cancellation, with invalid date format in cancel_date param", %{month: month, increment_year: increment_year, conn: conn} do
    insert(:member, card_no: "9999993333311111", expiry_date: Ecto.Date.cast!("#{increment_year}-#{month}-20"), status: "Active")
    params = %{
      card_no: "9999993333311111",
      cancel_date: "2017-11-14inveife",
      cancel_reason: "test_reason",
      cancel_remarks: "test remarks"
    }
    conn =
      conn
      |> post(api_member_path(conn, :member_cancellation, params))

    assert json_response(conn, 400)["errors"] == %{"cancel_date" => ["is invalid"]}
  end

  ### if suspend_date already been set
  test "post /member_cancellation, if suspend_date already exist, user must input cancel_date in between suspend_date and date expiry", %{month: month, increment_year: increment_year, conn: conn} do
    cancel_date = Ecto.Date.utc()
    duration = Duration.from_days(60)
    cancel_date = Timex.add(cancel_date, duration)
    cancel_incremented = Ecto.Date.cast!(cancel_date)

    suspend_date = Ecto.Date.utc()
    duration = Duration.from_days(30)
    suspend_date = Timex.add(suspend_date, duration)
    utc_incremented = Ecto.Date.cast!(suspend_date)

    insert(:member, card_no: "9999993333311111", expiry_date: Ecto.Date.cast!("#{increment_year}-#{month}-20"), suspend_date: utc_incremented, status: "Active")
    ### %{expiry_date: member.expiry_date, suspend_date: member.suspend_date, cancel_date: cancel_incremented}
    params = %{
      card_no: "9999993333311111",
      cancel_date: Ecto.Date.to_string(cancel_incremented),
      cancel_reason: "test_reason",
      cancel_remarks: "test remarks"
    }
    conn =
      conn
      |> post(api_member_path(conn, :member_cancellation, params))

    assert json_response(conn, 200)
  end

  test "post /member_cancellation, if suspend_date already exist, inputting cancel_date == suspend_date", %{month: month, increment_year: increment_year, conn: conn} do
    cancel_date = Ecto.Date.utc()
    duration = Duration.from_days(30)
    cancel_date = Timex.add(cancel_date, duration)
    cancel_incremented = Ecto.Date.cast!(cancel_date)

    suspend_date = Ecto.Date.utc()
    duration = Duration.from_days(30)
    suspend_date = Timex.add(suspend_date, duration)
    suspend_date = Ecto.Date.cast!(suspend_date)

    add_one_suspend_date =
      suspend_date
      |> Timex.add(Duration.from_days(1))
      |> Ecto.Date.cast!()
      |> Ecto.Date.to_string()

    member = insert(:member, card_no: "9999993333311111", expiry_date: Ecto.Date.cast!("#{increment_year}-#{month}-20"), suspend_date: suspend_date, status: "Active")

    minus_one_expiry_date =
      member.expiry_date
      |> Timex.subtract(Duration.from_days(1))
      |> Ecto.Date.cast!()
      |> Ecto.Date.to_string()

      ### %{expiry_date: member.expiry_date, suspend_date: member.suspend_date, cancel_date: cancel_incremented}
    params = %{
      card_no: "9999993333311111",
      cancel_date: Ecto.Date.to_string(cancel_incremented),
      cancel_reason: "test_reason",
      cancel_remarks: "test remarks"
    }
    conn =
      conn
      |> post(api_member_path(conn, :member_cancellation, params))

    assert json_response(conn, 400)["errors"] == %{"cancel_date" => ["cancellation date should be in range of above suspend1 date(#{add_one_suspend_date}) and below expiry date(#{minus_one_expiry_date})"]}
  end

  test "post /member_cancellation, if reactivate_date already exist, inputting cancel_date == reactivate_date", %{month: month, increment_year: increment_year, conn: conn} do
    cancel_date = Ecto.Date.utc()
    duration = Duration.from_days(30)
    cancel_date = Timex.add(cancel_date, duration)
    cancel_incremented = Ecto.Date.cast!(cancel_date)

    reactivate_date = Ecto.Date.utc()
    duration = Duration.from_days(30)
    reactivate_date = Timex.add(reactivate_date, duration)
    reactivate_date = Ecto.Date.cast!(reactivate_date)

    add_one_reactivate_date =
      reactivate_date
      |> Timex.add(Duration.from_days(1))
      |> Ecto.Date.cast!()
      |> Ecto.Date.to_string()

    member =
      :member
      |> insert(
        card_no: "9999993333311111",
        expiry_date: Ecto.Date.cast!("#{increment_year}-#{month}-20"),
        reactivate_date: reactivate_date,
        status: "Active"
      )

    minus_one_expiry_date =
      member.expiry_date
      |> Timex.subtract(Duration.from_days(1))
      |> Ecto.Date.cast!()
      |> Ecto.Date.to_string()

      ### %{expiry_date: member.expiry_date, suspend_date: member.suspend_date, cancel_date: cancel_incremented}
    params = %{
      card_no: "9999993333311111",
      cancel_date: Ecto.Date.to_string(cancel_incremented),
      cancel_reason: "test_reason",
      cancel_remarks: "test remarks"
    }
    conn =
      conn
      |> post(api_member_path(conn, :member_cancellation, params))

    assert json_response(conn, 400)["errors"] == %{"cancel_date" => ["cancellation date should be in range of above reactivate1 date(#{add_one_reactivate_date}) and below expiry date(#{minus_one_expiry_date})"]}
  end

  test "post /member_cancellation, if suspend_date already exist, inputting cancel_date < suspend_date", %{month: month, increment_year: increment_year, conn: conn} do
    cancel_date = Ecto.Date.utc()
    duration = Duration.from_days(20)
    cancel_date = Timex.add(cancel_date, duration)
    cancel_incremented = Ecto.Date.cast!(cancel_date)

    suspend_date = Ecto.Date.utc()
    duration = Duration.from_days(30)
    suspend_date = Timex.add(suspend_date, duration)
    suspend_date = Ecto.Date.cast!(suspend_date)

    add_one_suspend_date =
      suspend_date
      |> Timex.add(Duration.from_days(1))
      |> Ecto.Date.cast!()
      |> Ecto.Date.to_string()

    member = insert(:member, card_no: "9999993333311111", expiry_date: Ecto.Date.cast!("#{increment_year}-#{month}-20"), suspend_date: suspend_date, status: "Active")

    minus_one_expiry_date =
      member.expiry_date
      |> Timex.subtract(Duration.from_days(1))
      |> Ecto.Date.cast!()
      |> Ecto.Date.to_string()

      ###  %{expiry_date: member.expiry_date, suspend_date: member.suspend_date, cancel_date: cancel_incremented}
    params = %{
      card_no: "9999993333311111",
      cancel_date: Ecto.Date.to_string(cancel_incremented),
      cancel_reason: "test_reason",
      cancel_remarks: "test remarks"
    }
    conn =
      conn
      |> post(api_member_path(conn, :member_cancellation, params))

    assert json_response(conn, 400)["errors"] == %{"cancel_date" => ["cancellation date should be in range of above suspend2 date(#{add_one_suspend_date}) and below expiry date(#{minus_one_expiry_date})"]}
  end

  test "post /member_cancellation, if reactivate_date already exist, inputting cancel_date < reactivate_date", %{month: month, increment_year: increment_year, conn: conn} do
    insert(:user)
    cancel_date = Ecto.Date.utc()
    duration = Duration.from_days(20)
    cancel_date = Timex.add(cancel_date, duration)
    cancel_incremented = Ecto.Date.cast!(cancel_date)

    reactivate_date = Ecto.Date.utc()
    duration = Duration.from_days(30)
    reactivate_date = Timex.add(reactivate_date, duration)
    reactivate_date = Ecto.Date.cast!(reactivate_date)

    add_one_reactivate_date =
      reactivate_date
      |> Timex.add(Duration.from_days(1))
      |> Ecto.Date.cast!()
      |> Ecto.Date.to_string()

    member =
      :member
      |> insert(
        card_no: "9999993333311111",
        expiry_date: Ecto.Date.cast!("#{increment_year}-#{month}-20"),
        reactivate_date: reactivate_date,
        status: "Suspended"
      )

    minus_one_expiry_date =
      member.expiry_date
      |> Timex.subtract(Duration.from_days(1))
      |> Ecto.Date.cast!()
      |> Ecto.Date.to_string()

      ###  %{expiry_date: member.expiry_date, suspend_date: member.suspend_date, cancel_date: cancel_incremented}
    params = %{
      card_no: "9999993333311111",
      cancel_date: Ecto.Date.to_string(cancel_incremented),
      cancel_reason: "test_reason",
      cancel_remarks: "test remarks"
    }
    conn =
      conn
      |> post(api_member_path(conn, :member_cancellation, params))

    assert json_response(conn, 400)["errors"] == %{"cancel_date" => ["cancellation date should be in range of above reactivate2 date(#{add_one_reactivate_date}) and below expiry date(#{minus_one_expiry_date})"]}
  end

  test "post /member_cancellation, if suspend_date already exist, inputting cancel_date == expiry_date", %{month: month, increment_year: increment_year, conn: conn} do
    cancel_date = Ecto.Date.utc()
    duration = Duration.from_days(365)
    cancel_date = Timex.add(cancel_date, duration)
    cancel_incremented = Ecto.Date.cast!(cancel_date)

    suspend_date = Ecto.Date.utc()
    duration = Duration.from_days(30)
    suspend_date = Timex.add(suspend_date, duration)
    suspend_date = Ecto.Date.cast!(suspend_date)

    add_one_suspend_date =
      suspend_date
      |> Timex.add(Duration.from_days(1))
      |> Ecto.Date.cast!()
      |> Ecto.Date.to_string()

    member = insert(:member, card_no: "9999993333311111", expiry_date: Ecto.Date.cast!("#{increment_year}-#{month}-20"), suspend_date: suspend_date, status: "Suspended")

    %{expiry_date: member.expiry_date, suspend_date: member.suspend_date, cancel_date: cancel_incremented}

    minus_one_expiry_date =
      member.expiry_date
      |> Timex.subtract(Duration.from_days(1))
      |> Ecto.Date.cast!()
      |> Ecto.Date.to_string()

    params = %{
      card_no: "9999993333311111",
      cancel_date: Ecto.Date.to_string(member.expiry_date),
      cancel_reason: "test_reason",
      cancel_remarks: "test remarks"
    }
    conn =
      conn
      |> post(api_member_path(conn, :member_cancellation, params))

    assert json_response(conn, 400)["errors"] == %{"cancel_date" => ["cancellation date should be in range of above suspend4 date(#{add_one_suspend_date}) and below expiry date(#{minus_one_expiry_date})"]}
  end

  test "post /member_cancellation, if reactivate_date already exist, inputting cancel_date == expiry_date", %{month: month, increment_year: increment_year, conn: conn} do
    cancel_date = Ecto.Date.utc()
    duration = Duration.from_days(365)
    cancel_date = Timex.add(cancel_date, duration)
    cancel_incremented = Ecto.Date.cast!(cancel_date)

    reactivate_date = Ecto.Date.utc()
    duration = Duration.from_days(30)
    reactivate_date = Timex.add(reactivate_date, duration)
    reactivate_date = Ecto.Date.cast!(reactivate_date)

    add_one_reactivate_date =
      reactivate_date
      |> Timex.add(Duration.from_days(1))
      |> Ecto.Date.cast!()
      |> Ecto.Date.to_string()

    member =
      :member
      |> insert(
        card_no: "9999993333311111",
        expiry_date: Ecto.Date.cast!("#{increment_year}-#{month}-20"),
        reactivate_date: reactivate_date, status: "Active"
      )

    %{expiry_date: member.expiry_date, reactivate_date: member.reactivate_date, cancel_date: cancel_incremented}

    minus_one_expiry_date =
      member.expiry_date
      |> Timex.subtract(Duration.from_days(1))
      |> Ecto.Date.cast!()
      |> Ecto.Date.to_string()

    params = %{
      card_no: "9999993333311111",
      cancel_date: Ecto.Date.to_string(member.expiry_date),
      cancel_reason: "test_reason",
      cancel_remarks: "test remarks"
    }
    conn =
      conn
      |> post(api_member_path(conn, :member_cancellation, params))

    assert json_response(conn, 400)["errors"] == %{"cancel_date" => ["cancellation date should be in range of above reactivate4 date(#{add_one_reactivate_date}) and below expiry date(#{minus_one_expiry_date})"]}
  end

  test "post /member_cancellation, if suspend_date already exist, inputting cancel_date > expiry_date", %{month: month, increment_year: increment_year, conn: conn} do
    cancel_date = Ecto.Date.utc()
    duration = Duration.from_days(365)
    cancel_date = Timex.add(cancel_date, duration)
    cancel_incremented = Ecto.Date.cast!(cancel_date)

    suspend_date = Ecto.Date.utc()
    duration = Duration.from_days(30)
    suspend_date = Timex.add(suspend_date, duration)
    suspend_date = Ecto.Date.cast!(suspend_date)

    add_one_suspend_date =
      suspend_date
      |> Timex.add(Duration.from_days(1))
      |> Ecto.Date.cast!()
      |> Ecto.Date.to_string()

    member = insert(:member, card_no: "9999993333311111", expiry_date: Ecto.Date.cast!("#{increment_year}-#{month}-20"), suspend_date: suspend_date, status: "Active")

    %{expiry_date: member.expiry_date, suspend_date: member.suspend_date, cancel_date: cancel_incremented}

    minus_one_expiry_date =
      member.expiry_date
      |> Timex.subtract(Duration.from_days(1))
      |> Ecto.Date.cast!()
      |> Ecto.Date.to_string()

    add_one_expiry_date =
      member.expiry_date
      |> Timex.add(Duration.from_days(1))
      |> Ecto.Date.cast!()
      |> Ecto.Date.to_string()

    params = %{
      card_no: "9999993333311111",
      cancel_date: add_one_expiry_date,
      cancel_reason: "test_reason",
      cancel_remarks: "test remarks"
    }
    conn =
      conn
      |> post(api_member_path(conn, :member_cancellation, params))

    assert json_response(conn, 400)["errors"] == %{"cancel_date" => ["cancellation date should be in range of above suspend3 date(#{add_one_suspend_date}) and below expiry date(#{minus_one_expiry_date})"]}
  end

  test "post /member_cancellation, if reactivate_date already exist, inputting reactivate_date > expiry_date", %{month: month, increment_year: increment_year, conn: conn} do
    cancel_date = Ecto.Date.utc()
    duration = Duration.from_days(365)
    cancel_date = Timex.add(cancel_date, duration)
    cancel_incremented = Ecto.Date.cast!(cancel_date)

    reactivate_date = Ecto.Date.utc()
    duration = Duration.from_days(30)
    reactivate_date = Timex.add(reactivate_date, duration)
    reactivate_date = Ecto.Date.cast!(reactivate_date)

    add_one_reactivate_date =
      reactivate_date
      |> Timex.add(Duration.from_days(1))
      |> Ecto.Date.cast!()
      |> Ecto.Date.to_string()

    member =
      :member
      |> insert(
        card_no: "9999993333311111",
        expiry_date: Ecto.Date.cast!("#{increment_year}-#{month}-20"),
        reactivate_date: reactivate_date,
        status: "Active"
      )

    %{expiry_date: member.expiry_date, reactivate_date: member.reactivate_date, cancel_date: cancel_incremented}

    minus_one_expiry_date =
      member.expiry_date
      |> Timex.subtract(Duration.from_days(1))
      |> Ecto.Date.cast!()
      |> Ecto.Date.to_string()

    add_one_expiry_date =
      member.expiry_date
      |> Timex.add(Duration.from_days(1))
      |> Ecto.Date.cast!()
      |> Ecto.Date.to_string()

    params = %{
      card_no: "9999993333311111",
      cancel_date: add_one_expiry_date,
      cancel_reason: "test_reason",
      cancel_remarks: "test remarks"
    }
    conn =
      conn
      |> post(api_member_path(conn, :member_cancellation, params))

    assert json_response(conn, 400)["errors"] == %{"cancel_date" => ["cancellation date should be in range of above reactivate3 date(#{add_one_reactivate_date}) and below expiry date(#{minus_one_expiry_date})"]}
  end

  test "post /member_cancellation, if status is not Active or Suspended", %{month: month, increment_year: increment_year, conn: conn} do
    cancel_date = Ecto.Date.utc()
    duration = Duration.from_days(30)
    cancel_date = Timex.add(cancel_date, duration)
    cancel_incremented = Ecto.Date.cast!(cancel_date)
    insert(:member, card_no: "9999993333311111", expiry_date: Ecto.Date.cast!("#{increment_year}-#{month}-20"), status: "Lapsed")

    params = %{
      card_no: "9999993333311111",
      cancel_date: Ecto.Date.to_string(cancel_incremented),
      cancel_reason: "test_reason",
     cancel_remarks: "test remarks"
    }
    conn =
      conn
      |> post(api_member_path(conn, :member_cancellation, params))

    assert json_response(conn, 400)["errors"] == %{"card_no" => ["Member should cancel only if status is Active or Suspended"]}

  end

  ################################# end of member_cancellation ########################################################

  ################################# start of member_suspension ########################################################

  test "post /member_suspension, cancels member according to card_no", %{month: month, cancel_date: cancel_date, increment_year: increment_year, conn: conn} do
    insert(:member, card_no: "9999993333311111", expiry_date: Ecto.Date.cast!("#{increment_year}-#{month}-20"), status: "Active")
    params = %{
      card_no: "9999993333311111",
      suspend_date: Ecto.Date.to_string(cancel_date),
      suspend_reason: "test cancel",
      suspend_remarks: "test remarks"
    }
    conn =
      conn
      |> post(api_member_path(conn, :member_suspension, params))
    assert json_response(conn, 200)
  end

  test "post /member_suspension, with invalid card no param", %{month: month, cancel_date: cancel_date, increment_year: increment_year, conn: conn} do
    insert(:user)
    insert(:member, card_no: "9999993333311111", expiry_date: Ecto.Date.cast!("#{increment_year}-#{month}-20"), status: "Active")
    params = %{
      card_no: "9999993333311111wotuhj",
      suspend_date: Ecto.Date.to_string(cancel_date),
      suspend_reason: "test cancel",
      suspend_remarks: "test remarks"
    }
    conn =
      conn
      |> post(api_member_path(conn, :member_suspension, params))
    assert json_response(conn, 400)["errors"] == %{"card_no" => ["card no. not existing"]}
  end

  test "post /member_suspension, without cancel_reason param", %{month: month, cancel_date: cancel_date, increment_year: increment_year, conn: conn} do
    insert(:member, card_no: "9999993333311111", expiry_date: Ecto.Date.cast!("#{increment_year}-#{month}-20"), status: "Active")
    params = %{
      card_no: "",
      suspend_date: Ecto.Date.to_string(cancel_date),
      suspend_reason: "Reason 1",
      suspend_remarks: "test remarks"
    }
    conn =
      conn
      |> post(api_member_path(conn, :member_suspension, params))

    assert json_response(conn, 400)["errors"] == %{"card_no" => ["can't be blank"]}
  end

  test "post /member_suspension, with invalid date format in cancel_date param", %{month: month, increment_year: increment_year, conn: conn} do
    insert(:member, card_no: "9999993333311111", expiry_date: Ecto.Date.cast!("#{increment_year}-#{month}-20"), status: "Active")
    params = %{
      card_no: "9999993333311111",
      suspend_date: "2017-11-14inveife",
      suspend_reason: "test_reason",
      suspend_remarks: "test remarks"
    }
    conn =
      conn
      |> post(api_member_path(conn, :member_suspension, params))

    assert json_response(conn, 400)["errors"] == %{"suspend_date" => ["is invalid"]}
  end

  ### if cancel_date already been set
  test "post /member_suspension, if cancel_date already exist, user must input suspend_date in between tomorrow_date and cancellation_date", %{month: month, increment_year: increment_year, conn: conn} do
    cancel_date = Ecto.Date.utc()
    duration = Duration.from_days(60)
    cancel_date = Timex.add(cancel_date, duration)
    cancel_incremented = Ecto.Date.cast!(cancel_date)

    suspend_date = Ecto.Date.utc()
    duration = Duration.from_days(1)
    suspend_date = Timex.add(suspend_date, duration)
    suspend_incremented = Ecto.Date.cast!(suspend_date)

    member = insert(:member, card_no: "9999993333311111", expiry_date: Ecto.Date.cast!("#{increment_year}-#{month}-20"), cancel_date: cancel_incremented, status: "Active")
    %{expiry_date: member.expiry_date, suspend_date: suspend_incremented, cancel_date: member.cancel_date}

    params = %{
      card_no: "9999993333311111",
      suspend_date: Ecto.Date.to_string(suspend_incremented),
      suspend_reason: "test_reason",
      suspend_remarks: "test remarks"
    }

    conn =
      conn
      |> post(api_member_path(conn, :member_suspension, params))

    assert json_response(conn, 200)
  end

  test "post /member_suspension, if cancel_date already exist, if suspend_date == date_today", %{month: month, increment_year: increment_year, conn: conn} do
    cancel_date = Ecto.Date.utc()
    duration = Duration.from_days(60)
    cancel_date = Timex.add(cancel_date, duration)
    cancel_incremented = Ecto.Date.cast!(cancel_date)

    suspend_date = Ecto.Date.utc()
    duration = Duration.from_days(0)
    suspend_date = Timex.add(suspend_date, duration)
    suspend_incremented = Ecto.Date.cast!(suspend_date)

    member = insert(:member, card_no: "9999993333311111", expiry_date: Ecto.Date.cast!("#{increment_year}-#{month}-20"), cancel_date: cancel_incremented, status: "Active")
    %{expiry_date: member.expiry_date, suspend_date: suspend_incremented, cancel_date: member.cancel_date}

    tom_date = Ecto.Date.utc()
    duration = Duration.from_days(1)
    tom_date = Timex.add(tom_date, duration)
    tom_date = Ecto.Date.cast!(tom_date)

    member_cancel_date = member.cancel_date
    duration = Duration.from_days(1)
    member_cancel_date = Timex.subtract(member_cancel_date, duration)
    member_cancel_date = Ecto.Date.cast!(member_cancel_date)

    params = %{
      card_no: "9999993333311111",
      suspend_date: Ecto.Date.to_string(suspend_incremented),
      suspend_reason: "test_reason",
      suspend_remarks: "test remarks"
    }

    conn =
      conn
      |> post(api_member_path(conn, :member_suspension, params))

    assert json_response(conn, 400)["errors"] == %{"suspend_date" => ["suspension date should be in range of date tomorrow(#{tom_date}) up to below cancel1 date(#{member_cancel_date})"]}

  end

  test "post /member_suspension, if cancel_date already exist, if suspend_date < date_today", %{month: month, increment_year: increment_year, conn: conn} do
    cancel_date = Ecto.Date.utc()
    duration = Duration.from_days(60)
    cancel_date = Timex.add(cancel_date, duration)
    cancel_incremented = Ecto.Date.cast!(cancel_date)

    suspend_date = Ecto.Date.utc()
    duration = Duration.from_days(-1)
    suspend_date = Timex.add(suspend_date, duration)
    suspend_incremented = Ecto.Date.cast!(suspend_date)

    member = insert(:member, card_no: "9999993333311111", expiry_date: Ecto.Date.cast!("#{increment_year}-#{month}-20"), cancel_date: cancel_incremented, status: "Active")
    %{expiry_date: member.expiry_date, suspend_date: suspend_incremented, cancel_date: member.cancel_date}

    tom_date = Ecto.Date.utc()
    duration = Duration.from_days(1)
    tom_date = Timex.add(tom_date, duration)
    tom_date = Ecto.Date.cast!(tom_date)

    member_cancel_date = member.cancel_date
    duration = Duration.from_days(1)
    member_cancel_date = Timex.subtract(member_cancel_date, duration)
    member_cancel_date = Ecto.Date.cast!(member_cancel_date)

    params = %{
      card_no: "9999993333311111",
      suspend_date: Ecto.Date.to_string(suspend_incremented),
      suspend_reason: "test_reason",
      suspend_remarks: "test remarks"
    }

    conn =
      conn
      |> post(api_member_path(conn, :member_suspension, params))

    assert json_response(conn, 400)["errors"] == %{"suspend_date" => ["suspension date should be in range of date tomorrow(#{tom_date}) up to below cancel1 date(#{member_cancel_date})"]}

  end

  test "post /member_suspension, if cancel_date already exist, if suspend_date == cancel_date", %{month: month, increment_year: increment_year, conn: conn} do
    cancel_date = Ecto.Date.utc()
    duration = Duration.from_days(60)
    cancel_date = Timex.add(cancel_date, duration)
    cancel_incremented = Ecto.Date.cast!(cancel_date)

    suspend_date = Ecto.Date.utc()
    duration = Duration.from_days(60)
    suspend_date = Timex.add(suspend_date, duration)
    suspend_incremented = Ecto.Date.cast!(suspend_date)

    member = insert(:member, card_no: "9999993333311111", expiry_date: Ecto.Date.cast!("#{increment_year}-#{month}-20"), cancel_date: cancel_incremented, status: "Active")
    %{expiry_date: member.expiry_date, suspend_date: suspend_incremented, cancel_date: member.cancel_date}

    tom_date = Ecto.Date.utc()
    duration = Duration.from_days(1)
    tom_date = Timex.add(tom_date, duration)
    tom_date = Ecto.Date.cast!(tom_date)

    member_cancel_date = member.cancel_date
    duration = Duration.from_days(1)
    member_cancel_date = Timex.subtract(member_cancel_date, duration)
    member_cancel_date = Ecto.Date.cast!(member_cancel_date)

    params = %{
      card_no: "9999993333311111",
      suspend_date: Ecto.Date.to_string(suspend_incremented),
      suspend_reason: "test_reason",
      suspend_remarks: "test remarks"
    }

    conn =
      conn
      |> post(api_member_path(conn, :member_suspension, params))

    assert json_response(conn, 400)["errors"] == %{"suspend_date" => ["suspension date should be in range of date tomorrow(#{tom_date}) up to below cancel3 date(#{member_cancel_date})"]}

  end

  test "post /member_suspension, if cancel_date already exist, if suspend_date > cancel_date", %{month: month, increment_year: increment_year, conn: conn} do
    cancel_date = Ecto.Date.utc()
    duration = Duration.from_days(60)
    cancel_date = Timex.add(cancel_date, duration)
    cancel_incremented = Ecto.Date.cast!(cancel_date)

    suspend_date = Ecto.Date.utc()
    duration = Duration.from_days(62)
    suspend_date = Timex.add(suspend_date, duration)
    suspend_incremented = Ecto.Date.cast!(suspend_date)

    member = insert(:member, card_no: "9999993333311111", expiry_date: Ecto.Date.cast!("#{increment_year}-#{month}-20"), cancel_date: cancel_incremented, status: "Active")
    %{expiry_date: member.expiry_date, suspend_date: suspend_incremented, cancel_date: member.cancel_date}

    tom_date = Ecto.Date.utc()
    duration = Duration.from_days(1)
    tom_date = Timex.add(tom_date, duration)
    tom_date = Ecto.Date.cast!(tom_date)

    member_cancel_date = member.cancel_date
    duration = Duration.from_days(1)
    member_cancel_date = Timex.subtract(member_cancel_date, duration)
    member_cancel_date = Ecto.Date.cast!(member_cancel_date)

    params = %{
      card_no: "9999993333311111",
      suspend_date: Ecto.Date.to_string(suspend_incremented),
      suspend_reason: "test_reason",
      suspend_remarks: "test remarks"
    }

    conn =
      conn
      |> post(api_member_path(conn, :member_suspension, params))

    assert json_response(conn, 400)["errors"] == %{"suspend_date" => ["suspension date should be in range of date tomorrow(#{tom_date}) up to below cancel2 date(#{member_cancel_date})"]}

  end

  test "post /member_suspension, if status is not Active", %{month: month, cancel_date: cancel_date, increment_year: increment_year, conn: conn} do
    insert(:member, card_no: "9999993333311111", expiry_date: Ecto.Date.cast!("#{increment_year}-#{month}-20"), status: "Suspended")

    params = %{
      card_no: "9999993333311111",
      suspend_date: Ecto.Date.to_string(cancel_date),
      suspend_reason: "test cancel",
      suspend_remarks: "test remarks"
    }
    conn =
      conn
      |> post(api_member_path(conn, :member_suspension, params))
    assert json_response(conn, 400)["errors"] == %{"card_no" => ["Member should suspend only if status is Active"]}
  end

  ################################# end of member_suspension ########################################################

  test "get /validate_details with valid parameters", %{jwt: jwt} do
    member = insert(:member, card_no: "101010")
    account = insert(:account)
    product = insert(:product)
    facility = insert(:facility, code: "Code111", name: "test", step: 7, status: "Affiliated")
    facility2 = insert(:facility, code: "Code112", name: "test", step: 7, status: "Affiliated")
    coverage = insert(:coverage)
    account_product = insert(:account_product,
                              account: account,
                              product: product)
    insert(:member_product,
            member: member,
            account_product: account_product)
    product_coverage = insert(:product_coverage,
                              product: product,
                              coverage: coverage,
                              type: "inclusion")
    insert(:product_coverage_facility,
           facility: facility,
           product_coverage: product_coverage)

    insert(:product_coverage_facility,
           facility: facility2,
           product_coverage: product_coverage)

    params = %{
      card_number: "101010",
      facility_code: "Code111"
    }

    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> get("api/v1/loa/validate/facility", params)

    assert json_response(conn, 200)["message"] == "Member is not allowed to access this facility"
  end

  test "get /validate_details with existing facility_code", %{jwt: jwt} do
    member = insert(:member, card_no: "101010")
    account = insert(:account)
    product = insert(:product)
    facility = insert(:facility, code: "Code111", name: "test", step: 7, status: "Affiliated")
    facility2 = insert(:facility, code: "Code112", name: "test", step: 7, status: "Affiliated")
    coverage = insert(:coverage)
    account_product = insert(:account_product,
                              account: account,
                              product: product)
    insert(:member_product,
            member: member,
            account_product: account_product)
    product_coverage = insert(:product_coverage,
                              product: product,
                              coverage: coverage,
                              type: "inclusion")
    insert(:product_coverage_facility,
           facility: facility,
           product_coverage: product_coverage)

    insert(:product_coverage_facility,
           facility: facility2,
           product_coverage: product_coverage)

    params = %{
      card_number: "101010",
      facility_code: "Code114"
    }

    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> get("api/v1/loa/validate/facility", params)

    assert json_response(conn, 404)["message"] == "Facility not found"
  end

  test "get /validate_details with invalid facility_code", %{jwt: jwt} do
    member = insert(:member, card_no: "101010")
    account = insert(:account)
    product = insert(:product)
    facility = insert(:facility, code: "Code111", name: "test", step: 7, status: "Affiliated")
    facility2 = insert(:facility, code: "Code112", name: "test", step: 7, status: "Non-Affiliated")
    coverage = insert(:coverage)
    account_product = insert(:account_product,
                              account: account,
                              product: product)
    insert(:member_product,
            member: member,
            account_product: account_product)
    product_coverage = insert(:product_coverage,
                              product: product,
                              coverage: coverage,
                              type: "inclusion")
    insert(:product_coverage_facility,
           facility: facility,
           product_coverage: product_coverage)

    insert(:product_coverage_facility,
           facility: facility2,
           product_coverage: product_coverage)

    params = %{
      card_number: "101010",
      facility_code: "Code112"
    }

    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> get("api/v1/loa/validate/facility", params)

    assert json_response(conn, 400)["message"] == "Member is not allowed to access this facility"
  end

  test "get /validate_details with invalid card_number", %{jwt: jwt} do
    member = insert(:member, card_no: "101010")
    account = insert(:account)
    product = insert(:product)
    facility = insert(:facility, code: "Code111", name: "test", step: 6, status: "Affiliated")
    facility2 = insert(:facility, code: "Code112", name: "test", step: 6, status: "Affiliated")
    coverage = insert(:coverage)
    account_product = insert(:account_product,
                              account: account,
                              product: product)
    insert(:member_product,
            member: member,
            account_product: account_product)
    product_coverage = insert(:product_coverage,
                              product: product,
                              coverage: coverage,
                              type: "inclusion")
    insert(:product_coverage_facility,
           facility: facility,
           product_coverage: product_coverage)

    insert(:product_coverage_facility,
           facility: facility2,
           product_coverage: product_coverage)

    params = %{
      card_number: "101",
      facility_code: "Code114"
    }

    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> get("api/v1/loa/validate/facility", params)

    assert json_response(conn, 404)["message"] == "Card number not found"
  end

  test "get /validate_details with nil parameters", %{jwt: jwt} do
    params = %{
      card_number: "",
      facility_code: ""
    }

    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> get("api/v1/loa/validate/facility", params)

    assert json_response(conn, 400)["errors"]["card_number"] == ["Please enter card number"]
    assert json_response(conn, 400)["errors"]["facility_code"] == ["Please enter facility code"]
  end

  test "get /validate_details with no parameters", %{jwt: jwt} do
    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> get("api/v1/loa/validate/facility", %{})

    assert json_response(conn, 400)["errors"]["card_number"] == ["Please enter card number"]
    assert json_response(conn, 400)["errors"]["facility_code"] == ["Please enter facility code"]
  end

  test "post /member/movement/reactivation with valid attrs", %{jwt: jwt} do
    account = insert(:account_group)
    insert(
      :member,
      account_group: account,
      first_name: "test",
      card_no: "123",
      status: "Suspended",
      effectivity_date: Ecto.Date.cast!("2016-01-01"),
      expiry_date: Ecto.Date.cast!("9999-01-01")
    )
    _current_date = Date.utc_today
    params = %{
      card_number: "123",
      reactivate_date: "3000-01-01",
      reactivate_remarks: "Remarks",
      reactivate_reason: "Reason"
    }
    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> post("api/v1/member/movement/reactivation", params)

    assert json_response(conn, 200)["first_name"] == "test"
  end

  test "post /member/movement/reactivation with invalid card no", %{jwt: jwt} do
    insert(:user)
    params = %{
      card_number: "1234",
      reactivate_date: "2017-01-01",
      reactivate_remarks: "Remarks",
      reactivate_reason: "Reason"
    }
    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> post("api/v1/member/movement/reactivation", params)

    assert json_response(conn, 404)["error"]["message"] == "Member not found"
  end

  test "post /member/movement/reactivation with non suspended status", %{jwt: jwt} do
    insert(:member, first_name: "test", card_no: "123", status: "Pending")
    params = %{
      card_number: "123",
      reactivate_date: "2017-01-01",
      reactivate_remarks: "Remarks",
      reactivate_reason: "Reason"
    }
    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> post("api/v1/member/movement/reactivation", params)

    assert json_response(conn, 404)["error"]["message"] == "Only Suspended member can reactivate"
  end

  test "validate member evoucher with valid evoucher number returns member", %{conn: conn, jwt: jwt} do
    account = insert(:account_group)
    member = insert(:member, account_group: account, evoucher_number: "ACU-123456")
    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> post(api_member_path(conn, :validate_evoucher), %{evoucher_number: member.evoucher_number})

    assert json_response(conn,200)["evoucher_number"] == member.evoucher_number
  end

  test "validate member evoucher with valid evoucher number and without token returns unauthorized", %{conn: conn} do
    member = insert(:member, evoucher_number: "ACU-123456")
    conn =
      build_conn()
      |> post(api_member_path(conn, :validate_evoucher), %{evoucher_number: member.evoucher_number})

    assert json_response(conn, 401)["error"]["message"] == "Unauthorized"
  end

  test "validate member evoucher with invalid evoucher number returns not found", %{conn: conn, jwt: jwt} do
    insert(:member, card_no: "ACU-123456")
    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> post(api_member_path(conn, :validate_evoucher), %{evoucher_number: "ACU-123455"})

    assert json_response(conn, 404)["error"]["message"] == "eVoucher Number not found!"
  end

  test "validate evoucher card with invalid evoucher number and without token returns unauthorized", %{conn: conn} do
    insert(:member, evoucher_number: "ACU-123456")
    conn =
      build_conn()
      |> post(api_member_path(conn, :validate_evoucher), %{evoucher_number: "ACU-123455"})

    assert json_response(conn, 401)["error"]["message"] == "Unauthorized"
  end

  test "post /member/:id/update_mobile_no", %{jwt: jwt} do
    account_group = insert(:account_group, code: "C001", name: "Name")
    principal = insert(:member, mobile: "09210053027", mobile2: "09210053028")
    insert(:account, account_group: account_group, status: "Active")
    member = insert(:member, mobile: "09210053029", mobile2: "09210053030", type: "Dependent", account_code: "C001", principal: principal)
    insert(:member, mobile: "09210053025", mobile2: "09210053026", principal: principal)

    params = %{mobile_no: "09210053025"}

    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> put("api/v1/member/#{member.id}/update_mobile_no", params)

    assert json_response(conn, 200)["mobile"] == "09210053025"
  end

  defp render_json(template, assigns) do
    assigns = Map.new(assigns)

    template
    |> MemberView.render(assigns)
    |> Poison.encode!
    |> Poison.decode!
  end
end
