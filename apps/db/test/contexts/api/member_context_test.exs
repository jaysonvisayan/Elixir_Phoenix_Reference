defmodule Innerpeace.Db.Base.Api.MemberContextTest do
  use Innerpeace.Db.SchemaCase
  alias Innerpeace.Db.Schemas.{
    Member
  }
  alias Innerpeace.Db.Base.Api.MemberContext
  alias Innerpeace.Db.Base.MemberContext, as: Mc
  alias Innerpeace.Db.Repo

  setup do
    member = insert(:member, first_name: "Jon", birthdate: Ecto.Date.cast!("1995-12-12"), card_no: "1168011034280092", evoucher_number: "ACU-123456")
    member =
      member
      |> Repo.preload([:files, :emergency_contact])

    {:ok, %{member: member}}
  end

  test "validate_details/1 returns member using valid attributes" do
    member = insert(:member, birthdate: Ecto.Date.cast!("1997-01-30"), first_name: "Daniel Eduard", last_name: "Andal", middle_name: "Murao", card_no: "1168011034280092")

    member =
      member
      |> Repo.preload([:files, :emergency_contact])

    params = %{
      full_name: "Daniel Eduard Murao Andal",
      birth_date: "1997-01-30"
    }

    member = Mc.get_member(member.id)

    assert {:ok, [member]} == MemberContext.validate_details(params)
    assert member.first_name == "Daniel Eduard"
    assert member.middle_name == "Murao"
    assert member.last_name == "Andal"
    assert member.card_no == "1168011034280092"
  end

  test "validate_details/1 returns not found using invalid attributes" do
    params = %{
      full_name: "Jollibee Mcdonald",
      birth_date: "1997-01-30"
    }
    assert {:error, "Please enter valid member name/birthdate to avail ACU."} == MemberContext.validate_details(params)
  end

  test "validate_details/1 returns error when birthdate does not match format date" do
    member = insert(:member, birthdate: Ecto.Date.cast!("1997-01-30"), first_name: "Daniel Eduard", last_name: "Andal", middle_name: "Murao", card_no: "1168011034280092")

    member =
      member
      |> Repo.preload([:files, :emergency_contact])

    params = %{
      full_name: "Daniel Eduard Murao Andal",
      birth_date: "acu_schedules"
    }

    Mc.get_member(member.id)
    result = MemberContext.validate_details(params)

    assert result == {:error, "Please enter valid member name/birthdate to avail ACU."}
  end

  test "validate_card/1 with valid card_no returns member", %{member: member} do
    result = MemberContext.validate_card(member.card_no, member.birthdate)

    assert result.card_no == member.card_no
  end

  test "validate_card/1 with valid card_no returns nil" do
    result = MemberContext.validate_card("2168011034280092", "1990-01-01")

    assert is_nil(result)
  end

  test "get_member_by_card_no/1, load member with no search parameter" do
    assert MemberContext.get_member_by_card_no(nil) == nil
  end

  test "get_member_by_card_no/1, load member with search parameter" do
    insert(:member, card_no: "123")
    query = "%123%"
    m_query = (
      from m in Member,
      where: ilike(m.card_no, ^query),
      select: m
    )

    result =
      m_query
      |> limit(1)
      |> Repo.one()
      |> MemberContext.preload()

    assert result.card_no == MemberContext.get_member_by_card_no("123").card_no
  end

  ########################### start of member cancellation ###############################

  # test "validate_member_cancellation/2, validates params for cancellation of selected member through card no." do
  #   user = insert(:user)
  #   test = Ecto.Date.utc()
  #   increment_year = test.year + 1
  #   month =
  #     if String.length(Integer.to_string(test.month)) == 1 do
  #       "0#{test.month}"
  #     else
  #       test.month
  #     end
  #   cancel_date = Ecto.Date.cast!("#{increment_year}-#{month}-08")
  #   member = insert(:member, card_no: "9999993333311111", expiry_date: Ecto.Date.cast!("#{increment_year}-#{month}-28"), status: "Active")
  #   params = %{
  #     card_no: "9999993333311111",
  #     cancel_date: Ecto.Date.to_string(cancel_date),
  #     cancel_reason: "test cancel",
  #     cancel_remarks: "test remarks"
  #   }
  #   {:ok, result} = MemberContext.validate_member_cancellation(user, params)
  #   member = Repo.get(Member, member.id)
  #   assert member == result
  # end

  test "validate_member_cancellation/2, validates params with invalid card_no" do
    user = insert(:user)
    test = Ecto.Date.utc()
    increment_year = test.year + 1
    month =
      if String.length(Integer.to_string(test.month)) == 1 do
        "0#{test.month}"
      else
        test.month
      end
    cancel_date = Ecto.Date.cast!("#{increment_year}-#{month}-08")
    insert(:member, card_no: "9999993333311111", expiry_date: Ecto.Date.cast!("#{increment_year}-#{month}-28"), status: "Active")
    params = %{
      card_no: "9999993333311111werkljhs",
      cancel_date: Ecto.Date.to_string(cancel_date),
      cancel_reason: "test cancel",
      cancel_remarks: "test remarks"
    }
    {:error, result} = MemberContext.validate_member_cancellation(user, params)
    assert result.errors == [card_no: {"card no. not existing", [validation: :inclusion]}]
  end

  test "validate_member_cancellation/2, validates params with invalid cancel date" do
    user = insert(:user)
    test = Ecto.Date.utc()
    increment_year = test.year + 1
    month =
      if String.length(Integer.to_string(test.month)) == 1 do
        "0#{test.month}"
      else
        test.month
      end
    # cancel_date = Ecto.Date.cast!("#{increment_year}-#{month}-08")
    insert(:member, card_no: "9999993333311111", expiry_date: Ecto.Date.cast!("#{increment_year}-#{month}-28"), status: "Active")
    params = %{
      card_no: "9999993333311111",
      cancel_date: "2017-11-15sroptijh",
      cancel_reason: "test cancel",
      cancel_remarks: "test remarks"
    }
    {:error, result} = MemberContext.validate_member_cancellation(user, params)
    assert result.errors == [cancel_date: {"is invalid", [type: Ecto.Date, validation: :cast]}]

  end

  test "validate_member_cancellation/2, validates params with invalid cancel reason" do
    user = insert(:user)
    test = Ecto.Date.utc()
    increment_year = test.year + 1
    month =
      if String.length(Integer.to_string(test.month)) == 1 do
        "0#{test.month}"
      else
        test.month
      end
    cancel_date = Ecto.Date.cast!("#{increment_year}-#{month}-08")
    insert(:member, card_no: "9999993333311111", expiry_date: Ecto.Date.cast!("#{increment_year}-#{month}-28"), status: "Active")
    params = %{
      card_no: "9999993333311111",
      cancel_date: Ecto.Date.to_string(cancel_date),
      cancel_reason: "",
      cancel_remarks: "test remarks"
    }
    {:error, result} = MemberContext.validate_member_cancellation(user, params)
    assert result.errors == [cancel_reason: {"can't be blank", [validation: :required]}]

  end

  ### if suspend_date already been set
  test "validate_member_cancellation/2, if suspend_date already been set, user must input cancel_date in between suspend_date and date expiry" do
    user = insert(:user)
    test = Ecto.Date.utc()
    increment_year = test.year + 1
    month =
      if String.length(Integer.to_string(test.month)) == 1 do
        "0#{test.month}"
      else
        test.month
      end
    _cancel_date = Ecto.Date.cast!("#{increment_year}-#{month}-08")

    cancel_date = Ecto.Date.utc()
    duration = Timex.Duration.from_days(60)
    cancel_date = Timex.add(cancel_date, duration)
    cancel_incremented = Ecto.Date.cast!(cancel_date)

    suspend_date = Ecto.Date.utc()
    duration = Timex.Duration.from_days(30)
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

    assert {:ok, _result} = MemberContext.validate_member_cancellation(user, params)

  end

  test "validate_member_cancellation/2, if suspend_date already exist, inputting cancel_date == suspend_date" do
    user = insert(:user)
    test = Ecto.Date.utc()
    increment_year = test.year + 1

    month =
      if String.length(Integer.to_string(test.month)) == 1 do
        "0#{test.month}"
      else
        test.month
      end
    _cancel_date = Ecto.Date.cast!("#{increment_year}-#{month}-08")

    cancel_date = Ecto.Date.utc()
    duration = Timex.Duration.from_days(30)
    cancel_date = Timex.add(cancel_date, duration)
    cancel_incremented = Ecto.Date.cast!(cancel_date)

    suspend_date = Ecto.Date.utc()
    duration = Timex.Duration.from_days(30)
    suspend_date = Timex.add(suspend_date, duration)
    utc_incremented = Ecto.Date.cast!(suspend_date)

    add_one_suspend_date =
      suspend_date
      |> Timex.add(Timex.Duration.from_days(1))
      |> Ecto.Date.cast!()
      |> Ecto.Date.to_string()

    member = insert(:member, card_no: "9999993333311111", expiry_date: Ecto.Date.cast!("#{increment_year}-#{month}-20"), suspend_date: utc_incremented, status: "Active")
    ### %{expiry_date: member.expiry_date, suspend_date: member.suspend_date, cancel_date: cancel_incremented}

    minus_one_expiry_date =
      member.expiry_date
      |> Timex.subtract(Timex.Duration.from_days(1))
      |> Ecto.Date.cast!()
      |> Ecto.Date.to_string()

    params = %{
      card_no: "9999993333311111",
      cancel_date: Ecto.Date.to_string(cancel_incremented),
      cancel_reason: "test_reason",
      cancel_remarks: "test remarks"
    }

    {:error, changeset} = MemberContext.validate_member_cancellation(user, params)
    assert changeset.errors == [cancel_date: {"cancellation date should be in range of above suspend1 date(#{add_one_suspend_date}) and below expiry date(#{minus_one_expiry_date})", []}]

  end

  test "validate_member_cancellation/2, if suspend_date already exist, inputting cancel_date < suspend_date" do
    user = insert(:user)
    test = Ecto.Date.utc()
    increment_year = test.year + 1

    month =
      if String.length(Integer.to_string(test.month)) == 1 do
        "0#{test.month}"
      else
        test.month
      end
    _cancel_date = Ecto.Date.cast!("#{increment_year}-#{month}-08")

    cancel_date = Ecto.Date.utc()
    duration = Timex.Duration.from_days(29)
    cancel_date = Timex.add(cancel_date, duration)
    cancel_incremented = Ecto.Date.cast!(cancel_date)

    suspend_date = Ecto.Date.utc()
    duration = Timex.Duration.from_days(30)
    suspend_date = Timex.add(suspend_date, duration)
    utc_incremented = Ecto.Date.cast!(suspend_date)

    add_one_suspend_date =
      suspend_date
      |> Timex.add(Timex.Duration.from_days(1))
      |> Ecto.Date.cast!()
      |> Ecto.Date.to_string()

    member = insert(:member, card_no: "9999993333311111", expiry_date: Ecto.Date.cast!("#{increment_year}-#{month}-20"), suspend_date: utc_incremented, status: "Active")
    ### %{expiry_date: member.expiry_date, suspend_date: member.suspend_date, cancel_date: cancel_incremented}

    minus_one_expiry_date =
      member.expiry_date
      |> Timex.subtract(Timex.Duration.from_days(1))
      |> Ecto.Date.cast!()
      |> Ecto.Date.to_string()

    params = %{
      card_no: "9999993333311111",
      cancel_date: Ecto.Date.to_string(cancel_incremented),
      cancel_reason: "test_reason",
      cancel_remarks: "test remarks"
    }

    {:error, changeset} = MemberContext.validate_member_cancellation(user, params)
    assert changeset.errors == [cancel_date: {"cancellation date should be in range of above suspend2 date(#{add_one_suspend_date}) and below expiry date(#{minus_one_expiry_date})", []}]

  end

  test "validate_member_cancellation/2, if suspend_date already exist, inputting cancel_date == expiry_date" do
    user = insert(:user)
    test = Ecto.Date.utc()
    increment_year = test.year + 1

    month =
      if String.length(Integer.to_string(test.month)) == 1 do
        "0#{test.month}"
      else
        test.month
      end
    _cancel_date = Ecto.Date.cast!("#{increment_year}-#{month}-08")

    cancel_date = Ecto.Date.utc()
    duration = Timex.Duration.from_days(358)
    cancel_date = Timex.add(cancel_date, duration)
    _cancel_incremented = Ecto.Date.cast!(cancel_date)

    suspend_date = Ecto.Date.utc()
    duration = Timex.Duration.from_days(30)
    suspend_date = Timex.add(suspend_date, duration)
    utc_incremented = Ecto.Date.cast!(suspend_date)

    add_one_suspend_date =
      suspend_date
      |> Timex.add(Timex.Duration.from_days(1))
      |> Ecto.Date.cast!()
      |> Ecto.Date.to_string()

    member = insert(:member, card_no: "9999993333311111", expiry_date: Ecto.Date.cast!("#{increment_year}-#{month}-20"), suspend_date: utc_incremented, status: "Active")
    ### %{expiry_date: member.expiry_date, suspend_date: member.suspend_date, cancel_date: cancel_incremented}

    minus_one_expiry_date =
      member.expiry_date
      |> Timex.subtract(Timex.Duration.from_days(1))
      |> Ecto.Date.cast!()
      |> Ecto.Date.to_string()

    params = %{
      card_no: "9999993333311111",
      cancel_date: member.expiry_date,
      cancel_reason: "test_reason",
      cancel_remarks: "test remarks"
    }

    {:error, changeset} = MemberContext.validate_member_cancellation(user, params)
    assert changeset.errors == [cancel_date: {"cancellation date should be in range of above suspend4 date(#{add_one_suspend_date}) and below expiry date(#{minus_one_expiry_date})", []}]

  end

  test "validate_member_cancellation/2, if suspend_date already exist, inputting cancel_date > expiry_date" do
    user = insert(:user)
    test = Ecto.Date.utc()
    increment_year = test.year + 1

    month =
      if String.length(Integer.to_string(test.month)) == 1 do
        "0#{test.month}"
      else
        test.month
      end
    _cancel_date = Ecto.Date.cast!("#{increment_year}-#{month}-08")

    cancel_date = Ecto.Date.utc()
    duration = Timex.Duration.from_days(365)
    cancel_date = Timex.add(cancel_date, duration)
    _cancel_incremented = Ecto.Date.cast!(cancel_date)

    suspend_date = Ecto.Date.utc()
    duration = Timex.Duration.from_days(30)
    suspend_date = Timex.add(suspend_date, duration)
    utc_incremented = Ecto.Date.cast!(suspend_date)
    add_one_suspend_date =
      suspend_date
      |> Timex.add(Timex.Duration.from_days(1))
      |> Ecto.Date.cast!()
      |> Ecto.Date.to_string()
    member = insert(:member, card_no: "9999993333311111", expiry_date: Ecto.Date.cast!("#{increment_year}-#{month}-20"), suspend_date: utc_incremented, status: "Active")
    ### %{expiry_date: member.expiry_date, suspend_date: member.suspend_date, cancel_date: cancel_incremented}

    minus_one_expiry_date =
      member.expiry_date
      |> Timex.subtract(Timex.Duration.from_days(1))
      |> Ecto.Date.cast!()
      |> Ecto.Date.to_string()
    plus_one_expiry_date =
      member.expiry_date
      |> Timex.add(Timex.Duration.from_days(1))
      |> Ecto.Date.cast!()
      |> Ecto.Date.to_string()
    params = %{
      card_no: "9999993333311111",
      cancel_date: plus_one_expiry_date,
      cancel_reason: "test_reason",
      cancel_remarks: "test remarks"
    }
    {:error, changeset} = MemberContext.validate_member_cancellation(user, params)
    assert changeset.errors == [cancel_date: {"cancellation date should be in range of above suspend3 date(#{add_one_suspend_date}) and below expiry date(#{minus_one_expiry_date})", []}]

  end

  ########################### end of member cancellation ###############################

  ########################### start of member suspension ###############################

  # test "validate_member_suspension/2, validates params for suspension of selected member through card no." do
  #   user = insert(:user)
  #   test = Ecto.Date.utc()
  #   increment_year = test.year + 1
  #   month =
  #     if String.length(Integer.to_string(test.month)) == 1 do
  #       "0#{test.month}"
  #     else
  #       test.month
  #     end
  #   suspend_date = Ecto.Date.cast!("#{increment_year}-#{month}-08")
  #   member = insert(:member, card_no: "9999993333311111", expiry_date: Ecto.Date.cast!("#{increment_year}-#{month}-28"), status: "Active")
  #   params = %{
  #     card_no: "9999993333311111",
  #     suspend_date: Ecto.Date.to_string(suspend_date),
  #     suspend_reason: "test cancel",
  #     suspend_remarks: "test remarks"
  #   }
  #   {:ok, result} = MemberContext.validate_member_suspension(user, params)
  #   member = Repo.get(Member, member.id)
  #   assert member == result
  # end

  test "validate_member_suspension/2, validates params with invalid card_no" do
    user = insert(:user)
    test = Ecto.Date.utc()
    increment_year = test.year + 1
    month =
      if String.length(Integer.to_string(test.month)) == 1 do
        "0#{test.month}"
      else
        test.month
      end
    suspend_date = Ecto.Date.cast!("#{increment_year}-#{month}-08")
    insert(:member, card_no: "9999993333311111", expiry_date: Ecto.Date.cast!("#{increment_year}-#{month}-28"), status: "Active")

    params = %{
      card_no: "9999993333311111qweiourh",
      suspend_date: Ecto.Date.to_string(suspend_date),
      suspend_reason: "test cancel",
      suspend_remarks: "test remarks"
    }
    {:error, result} = MemberContext.validate_member_suspension(user, params)
    assert result.errors == [card_no: {"card no. not existing", [validation: :inclusion]}]
  end

  test "validate_member_suspension/2, validates params with invalid date" do
    user = insert(:user)
    test = Ecto.Date.utc()
    increment_year = test.year + 1

    month =
      if String.length(Integer.to_string(test.month)) == 1 do
        "0#{test.month}"
      else
        test.month
      end
    # suspend_date = Ecto.Date.cast!("#{increment_year}-#{month}-08")
    insert(:member, card_no: "9999993333311111", expiry_date: Ecto.Date.cast!("#{increment_year}-#{month}-28"), status: "Active")

    params = %{
      card_no: "9999993333311111",
      suspend_date: "2017-11-05dfylij",
      suspend_reason: "test cancel",
      suspend_remarks: "test remarks"
    }
    {:error, result} = MemberContext.validate_member_suspension(user, params)
    assert result.errors == [suspend_date: {"is invalid", [type: Ecto.Date, validation: :cast]}]
  end

  test "validate_member_suspension/2, validates params with invalid reason" do
    user = insert(:user)
    test = Ecto.Date.utc()
    increment_year = test.year + 1

    month =
      if String.length(Integer.to_string(test.month)) == 1 do
        "0#{test.month}"
      else
        test.month
      end
    suspend_date = Ecto.Date.cast!("#{increment_year}-#{month}-08")
    insert(:member, card_no: "9999993333311111", expiry_date: Ecto.Date.cast!("#{increment_year}-#{month}-28"), status: "Active")

    params = %{
      card_no: "9999993333311111",
      suspend_date: Ecto.Date.to_string(suspend_date),
      suspend_reason: "",
      suspend_remarks: "test remarks"
    }
    {:error, result} = MemberContext.validate_member_suspension(user, params)
    assert result.errors == [suspend_reason: {"can't be blank", [validation: :required]}]
  end

  ### if cancel_date already been set
  test "post /member_suspension, if cancel_date already exist, user must input suspend_date in between tomorrow_date and cancellation_date" do
    user = insert(:user)
    test = Ecto.Date.utc()
    increment_year = test.year + 1

    month =
      if String.length(Integer.to_string(test.month)) == 1 do
        "0#{test.month}"
      else
        test.month
      end
    _cancel_date = Ecto.Date.cast!("#{increment_year}-#{month}-08")

    cancel_date = Ecto.Date.utc()
    duration = Timex.Duration.from_days(60)
    cancel_date = Timex.add(cancel_date, duration)
    cancel_incremented = Ecto.Date.cast!(cancel_date)

    suspend_date = Ecto.Date.utc()
    duration = Timex.Duration.from_days(2)
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

    assert {:ok, _result} = MemberContext.validate_member_suspension(user, params)
  end

  test "post /member_suspension, if cancel_date already exist, if suspend_date == date_today" do
    user = insert(:user)
    test = Ecto.Date.utc()
    increment_year = test.year + 1

    month =
      if String.length(Integer.to_string(test.month)) == 1 do
        "0#{test.month}"
      else
        test.month
      end
    _cancel_date = Ecto.Date.cast!("#{increment_year}-#{month}-08")


    cancel_date = Ecto.Date.utc()
    duration = Timex.Duration.from_days(60)
    cancel_date = Timex.add(cancel_date, duration)
    cancel_incremented = Ecto.Date.cast!(cancel_date)

    suspend_date = Ecto.Date.utc()
    duration = Timex.Duration.from_days(0)
    suspend_date = Timex.add(suspend_date, duration)
    suspend_incremented = Ecto.Date.cast!(suspend_date)

    member = insert(:member, card_no: "9999993333311111", expiry_date: Ecto.Date.cast!("#{increment_year}-#{month}-20"), cancel_date: cancel_incremented, status: "Active")
    %{expiry_date: member.expiry_date, suspend_date: suspend_incremented, cancel_date: member.cancel_date}

    tom_date = Ecto.Date.utc()
    duration = Timex.Duration.from_days(1)
    tom_date = Timex.add(tom_date, duration)
    tom_date = Ecto.Date.cast!(tom_date)

    member_cancel_date = member.cancel_date
    duration = Timex.Duration.from_days(1)
    member_cancel_date = Timex.subtract(member_cancel_date, duration)
    member_cancel_date = Ecto.Date.cast!(member_cancel_date)

    params = %{
      card_no: "9999993333311111",
      suspend_date: Ecto.Date.to_string(suspend_incremented),
      suspend_reason: "test_reason",
      suspend_remarks: "test remarks"
    }

    {:error, changeset} = MemberContext.validate_member_suspension(user, params)
    assert changeset.errors == [suspend_date: {"suspension date should be in range of date tomorrow(#{tom_date}) up to below cancel1 date(#{member_cancel_date})", []}]
  end

  test "post /member_suspension, if cancel_date already exist, if suspend_date < date_today" do
    user = insert(:user)
    test = Ecto.Date.utc()
    increment_year = test.year + 1

    month =
      if String.length(Integer.to_string(test.month)) == 1 do
        "0#{test.month}"
      else
        test.month
      end
    _cancel_date = Ecto.Date.cast!("#{increment_year}-#{month}-08")

    cancel_date = Ecto.Date.utc()
    duration = Timex.Duration.from_days(60)
    cancel_date = Timex.add(cancel_date, duration)
    cancel_incremented = Ecto.Date.cast!(cancel_date)

    suspend_date = Ecto.Date.utc()
    duration = Timex.Duration.from_days(-11)
    suspend_date = Timex.add(suspend_date, duration)
    suspend_incremented = Ecto.Date.cast!(suspend_date)

    member = insert(:member, card_no: "9999993333311111", expiry_date: Ecto.Date.cast!("#{increment_year}-#{month}-20"), cancel_date: cancel_incremented, status: "Active")
    %{expiry_date: member.expiry_date, suspend_date: suspend_incremented, cancel_date: member.cancel_date}

    tom_date = Ecto.Date.utc()
    duration = Timex.Duration.from_days(1)
    tom_date = Timex.add(tom_date, duration)
    tom_date = Ecto.Date.cast!(tom_date)

    member_cancel_date = member.cancel_date
    duration = Timex.Duration.from_days(1)
    member_cancel_date = Timex.subtract(member_cancel_date, duration)
    member_cancel_date = Ecto.Date.cast!(member_cancel_date)

    params = %{
      card_no: "9999993333311111",
      suspend_date: Ecto.Date.to_string(suspend_incremented),
      suspend_reason: "test_reason",
      suspend_remarks: "test remarks"
    }

    {:error, changeset} = MemberContext.validate_member_suspension(user, params)
    assert changeset.errors == [suspend_date: {"suspension date should be in range of date tomorrow(#{tom_date}) up to below cancel1 date(#{member_cancel_date})", []}]
  end

  test "post /member_suspension, if cancel_date already exist, if suspend_date == cancel_date" do
    user = insert(:user)
    test = Ecto.Date.utc()
    increment_year = test.year + 1

    month =
      if String.length(Integer.to_string(test.month)) == 1 do
        "0#{test.month}"
      else
        test.month
      end
    _cancel_date = Ecto.Date.cast!("#{increment_year}-#{month}-08")

    cancel_date = Ecto.Date.utc()
    duration = Timex.Duration.from_days(60)
    cancel_date = Timex.add(cancel_date, duration)
    cancel_incremented = Ecto.Date.cast!(cancel_date)

    suspend_date = Ecto.Date.utc()
    duration = Timex.Duration.from_days(60)
    suspend_date = Timex.add(suspend_date, duration)
    suspend_incremented = Ecto.Date.cast!(suspend_date)

    member = insert(:member, card_no: "9999993333311111", expiry_date: Ecto.Date.cast!("#{increment_year}-#{month}-20"), cancel_date: cancel_incremented, status: "Active")
    %{expiry_date: member.expiry_date, suspend_date: suspend_incremented, cancel_date: member.cancel_date}

    tom_date = Ecto.Date.utc()
    duration = Timex.Duration.from_days(1)
    tom_date = Timex.add(tom_date, duration)
    tom_date = Ecto.Date.cast!(tom_date)

    member_cancel_date = member.cancel_date
    duration = Timex.Duration.from_days(1)
    member_cancel_date = Timex.subtract(member_cancel_date, duration)
    member_cancel_date = Ecto.Date.cast!(member_cancel_date)

    params = %{
      card_no: "9999993333311111",
      suspend_date: Ecto.Date.to_string(suspend_incremented),
      suspend_reason: "test_reason",
      suspend_remarks: "test remarks"
    }

    {:error, changeset} = MemberContext.validate_member_suspension(user, params)
    assert changeset.errors == [suspend_date: {"suspension date should be in range of date tomorrow(#{tom_date}) up to below cancel3 date(#{member_cancel_date})", []}]
  end

  test "post /member_suspension, if cancel_date already exist, if suspend_date > cancel_date" do
    user = insert(:user)
    test = Ecto.Date.utc()
    increment_year = test.year + 1

    month =
      if String.length(Integer.to_string(test.month)) == 1 do
        "0#{test.month}"
      else
        test.month
      end
    _cancel_date = Ecto.Date.cast!("#{increment_year}-#{month}-08")

    cancel_date = Ecto.Date.utc()
    duration = Timex.Duration.from_days(60)
    cancel_date = Timex.add(cancel_date, duration)
    cancel_incremented = Ecto.Date.cast!(cancel_date)

    suspend_date = Ecto.Date.utc()
    duration = Timex.Duration.from_days(65)
    suspend_date = Timex.add(suspend_date, duration)
    suspend_incremented = Ecto.Date.cast!(suspend_date)

    member = insert(:member, card_no: "9999993333311111", expiry_date: Ecto.Date.cast!("#{increment_year}-#{month}-20"), cancel_date: cancel_incremented, status: "Active")
    %{expiry_date: member.expiry_date, suspend_date: suspend_incremented, cancel_date: member.cancel_date}

    tom_date = Ecto.Date.utc()
    duration = Timex.Duration.from_days(1)
    tom_date = Timex.add(tom_date, duration)
    tom_date = Ecto.Date.cast!(tom_date)

    member_cancel_date = member.cancel_date
    duration = Timex.Duration.from_days(1)
    member_cancel_date = Timex.subtract(member_cancel_date, duration)
    member_cancel_date = Ecto.Date.cast!(member_cancel_date)

    params = %{
      card_no: "9999993333311111",
      suspend_date: Ecto.Date.to_string(suspend_incremented),
      suspend_reason: "test_reason",
      suspend_remarks: "test remarks"
    }

    {:error, changeset} = MemberContext.validate_member_suspension(user, params)
    assert changeset.errors == [suspend_date: {"suspension date should be in range of date tomorrow(#{tom_date}) up to below cancel2 date(#{member_cancel_date})", []}]
  end

  ########################### end of member suspension ###############################

  test "get_all_member_facility/1 with valid parameters" do
    member = insert(:member)
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

    facility_codes = MemberContext.get_all_member_facility(member.id)

    assert Enum.member?(facility_codes, "Code111")
  end

  test "get_all_member_facility/2 with nil parameters" do
    {_, member_id} = Ecto.UUID.load(Ecto.UUID.bingenerate())
    facility_codes = MemberContext.get_all_member_facility(member_id)

    refute Enum.member?(facility_codes, "")
  end

  test "get_all_member_facility/2 with invalid card_no" do
    {_, member_id} = Ecto.UUID.load(Ecto.UUID.bingenerate())
    facility_codes = MemberContext.get_all_member_facility(member_id)

    refute Enum.member?(facility_codes, "Code111")
  end

  test "get_all_member_facility/2 with invalid facility code" do
    member = insert(:member)
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


    facility_codes = MemberContext.get_all_member_facility(member.id)

    refute Enum.member?(facility_codes, "1Code111")
  end

  test "validate_evoucher/1 with valid evoucher_no returns member", %{member: member} do
    member = Mc.get_member(member.id)
    result = MemberContext.validate_evoucher(member.evoucher_number)
    assert result == member
  end

  test "validate_evoucher/1 with valid evocher_no returns nil" do
    result = MemberContext.validate_evoucher("ACU-123446")

    assert is_nil(result)
  end

  test "get_all_mobile_no/0 returns list of numbers" do
    insert(:member, mobile: "09210053023", mobile2: "09210053024")
    insert(:member, mobile: "09210053025", mobile2: "09210053026")

    refute Enum.empty?(MemberContext.get_all_mobile_no())
  end

  test "get_all_mobile_no/0 returns empty list" do
    assert Enum.empty?(MemberContext.get_all_mobile_no())
  end

  test "get_all_mobile_no/1 returns list of numbers" do
    principal = insert(:member, mobile: "09210053027", mobile2: "09210053028")
    insert(:member, mobile: "09210053023", mobile2: "09210053024", principal: principal)
    insert(:member, mobile: "09210053029", mobile2: "09210053030", principal: principal)
    insert(:member, mobile: "09210053025", mobile2: "09210053026")

    refute Enum.empty?(MemberContext.get_all_mobile_no(principal.id))
  end

  test "forced_lapsed/1 success" do
    account_group = insert(:account_group)
    insert(:account, start_date: Ecto.Date.cast!("2018-01-03"), account_group: account_group, status: "Active", end_date: Ecto.Date.cast!("2019-01-03"))
    member = insert(:member, account_group: account_group, effectivity_date: Ecto.Date.cast!("2019-01-02"))

    {:ok, member} = MemberContext.forced_lapsed(member)

    assert member.effectivity_date == Ecto.Date.cast!("2019-01-02")
    assert member.status == "Lapsed"
  end

  test "forced_lapsed/1 failed" do
    account_group = insert(:account_group)
    insert(:account, start_date: Ecto.Date.cast!("2018-01-03"), account_group: account_group, status: "Active", end_date: Ecto.Date.cast!("2019-01-03"))
    member = insert(:member, account_group: account_group, effectivity_date: Ecto.Date.cast!("2019-02-01"))
    assert is_nil(MemberContext.forced_lapsed(member))
  end

  ########################### start member_existing_migration related #################################

  test "create_member_existing_v2/1 with valida parameters" do
    product = insert(:product, code: "PRD-799407")
    account_group = insert(:account_group, name: "Starbucks Worldwide", code: "C0050")
    account = insert(:account, account_group: account_group, status: "Active")
    insert(:account_product, account: account, product: product)
    member_params = member_principal_parameters()
    assert {:ok, member} = MemberContext.create_existing_member_v2(member_params)
    assert member == (%Member{} = member)
  end

  test "create_member_existing_v2/1 without account_code" do
    product = insert(:product, code: "PRD-799407")
    account_group = insert(:account_group, name: "Starbucks Worldwide", code: "C0050")
    account = insert(:account, account_group: account_group, status: "Active")
    insert(:account_product, account: account, product: product)
    member_params = member_principal_parameters() |> Map.delete("account_code")
    assert {:error, message} = MemberContext.create_existing_member_v2(member_params)
    assert message == "account_code is required"
  end

  test "create_member_existing_v2/1 with existing card no using principal type" do
    product = insert(:product, code: "PRD-799407")
    account_group = insert(:account_group, name: "Starbucks Worldwide", code: "C0050")
    account = insert(:account, account_group: account_group, status: "Active")
    insert(:account_product, account: account, product: product)
    insert(:member, card_no: "1168011044771783", status: "Active")

    member_params =
      member_principal_parameters()
      |> Map.delete("first_name")
      |> Map.delete("last_name")
      |> Map.put("first_name", "Joseph")
      |> Map.put("last_name", "Canilao")

    assert {:error, message} = MemberContext.create_existing_member_v2(member_params)
    assert message == "card_no already exists"
  end

  test "create_member_existing_v2/1 with existing card no using dependent type" do
    product = insert(:product, code: "PRD-799407")
    account_group = insert(:account_group, name: "Starbucks Worldwide", code: "C0050")
    account = insert(:account, account_group: account_group, status: "Active")
    insert(:account_product, account: account, product: product)
    insert(:member, card_no: "1168011039921617", status: "Active", policy_no: "180227669500")

    member_params =
      member_dependent_parameters()
      |> Map.delete("first_name")
      |> Map.delete("last_name")
      |> Map.delete("employee_no")
      |> Map.put("first_name", "Joseph")
      |> Map.put("last_name", "Canilao")

    assert {:error, message} = MemberContext.create_existing_member_v2(member_params)
    assert message == "card_no already exists"
  end

  test "create_member_existing_v2/1 with empty product: []" do
    product = insert(:product, code: "PRD-799407")
    account_group = insert(:account_group, name: "Starbucks Worldwide", code: "C0050")
    account = insert(:account, account_group: account_group, status: "Active")
    insert(:account_product, account: account, product: product)
    member_params = member_principal_parameters() |> Map.put("products", [])
    assert {:error, message} = MemberContext.create_existing_member_v2(member_params)
    assert "products at least one is required" == message
  end

  test "create_member_existing_v2/1 without employee_no, then trace by policy_no" do
    product = insert(:product, code: "PRD-799407")
    account_group = insert(:account_group, name: "Starbucks Worldwide", code: "C0050")
    account = insert(:account, account_group: account_group, status: "Active")
    insert(:account_product, account: account, product: product)
    principal = insert(:member, card_no: "1168011044771733", status: "Active", policy_no: "180227669500")

    member_params = member_dependent_parameters() |> Map.delete("employee_no")
    assert {:ok, member_dependent} = MemberContext.create_existing_member_v2(member_params)
    assert member_dependent == (%Member{} = member_dependent)
    assert is_nil(member_dependent.employee_no)
    assert member_dependent.principal_id == principal.id
  end

  test "create_member_existing_v2/1 without employee_no and without existing principal policy_no" do
    product = insert(:product, code: "PRD-799407")
    account_group = insert(:account_group, name: "Starbucks Worldwide", code: "C0050")
    account = insert(:account, account_group: account_group, status: "Active")
    insert(:account_product, account: account, product: product)
    insert(:member, card_no: "1168011039921611", status: "Active", policy_no: "111111111")

    member_params =
      member_dependent_parameters()
      |> Map.delete("first_name")
      |> Map.delete("last_name")
      |> Map.delete("employee_no")
      |> Map.put("first_name", "Joseph")
      |> Map.put("last_name", "Canilao")

    assert {:error, message} = MemberContext.create_existing_member_v2(member_params)
    assert message == "policy_no Principal Policy Number Reference is not existing"
  end

  test "create_member_existing_v2/1 validates employee_no if it is already exists within the account" do
    product = insert(:product, code: "PRD-799407")
    account_group = insert(:account_group, name: "Starbucks Worldwide", code: "C0050")
    account = insert(:account, account_group: account_group, status: "Active")
    insert(:account_product, account: account, product: product)
    insert(:member, account_code: account_group.code, card_no: "1168011039921611", status: "Active", policy_no: "111111111", employee_no: "Medilink-576-16", )

    member_params =
      member_principal_parameters()
      |> Map.put("employee_no", "Medilink-576-16")

    assert {:error, message} = MemberContext.create_existing_member_v2(member_params)
    assert message == "employee_no already exists within the account"
  end

  test "create_member_existing_v2/1 validates dependent employee_no if it is not existing to a given account" do
    product = insert(:product, code: "PRD-799407")
    account_group = insert(:account_group, name: "Starbucks Worldwide", code: "C0050")
    account = insert(:account, account_group: account_group, status: "Active")
    insert(:account_product, account: account, product: product)
    insert(:member, account_code: account_group.code, card_no: "1168011039921611", status: "Active", policy_no: "111111111", employee_no: "Medilink-576-16", )

    member_params =
      member_dependent_parameters()
      |> Map.put("employee_no", "Medilink-576-88")

    assert {:error, message} = MemberContext.create_existing_member_v2(member_params)
    assert message == "employee_no is not existing to a given account"
  end

  test "create_member_existing_v2/1 validates products: [] if it is included to the account product" do
    product = insert(:product, code: "PRD-799407")
    account_group = insert(:account_group, name: "Starbucks Worldwide", code: "C0050")
    account = insert(:account, account_group: account_group, status: "Active")
    insert(:account_product, account: account, product: product)
    insert(:member, account_code: account_group.code, card_no: "1168011039921611", status: "Active", policy_no: "111111111", employee_no: "Medilink-576-16", )

    member_params =
      member_principal_parameters()
      |> Map.put("products", ["Wrong-PRD-111111", "Wrong-PRD-222222"])

    assert {:error, message} = MemberContext.create_existing_member_v2(member_params)
    assert message == "products is invalid: plan that has been picked is not included to a given account"
  end

  def member_principal_parameters() do
    %{
      "mcc" => "+63",
      "account_code" => "C0050",
      "first_name" => "GAVINA",
      "effectivity_date" => "2018-07-25",
      "employee_no" => "MXC201801084996757",
      "fax" => "",
      "regularization_date" => "2019-07-24 00:00:00",
      "last_name" => "MAXI P MEMBER",
      "middle_name" => nil,
      "relationship" => nil,
      "fcc" => "",
      "telephone" => "",
      "date_hired" => "2018-07-25 00:00:00",
      "type" => "Principal",
      "philhealth_type" => "Required to file",
      "philhealth" => "000000000001",
      "street_name" => "",
      "products" => ["PRD-799407"],
      "mcc2" => "",
      "suffix" => "",
      "principal_product_code" => nil,
      "tin" => "",
      "region" => "",
      "birthdate" => "1997-02-25 00:00:00",
      "status" => "Active",
      "version" => "v2",
      "unit_no" => "",
      "policy_no" => "180227668500",
      "province" => "",
      "building_name" => "",
      "postal" => "",
      "for_card_issuance" => true,
      "city" => "",
      "email" => "medilinktest@yahoo.com",
      "gender" => "Male",
      "card_no" => "1168011044771783",
      "email2" => "",
      "is_regular" => true,
      "mobile" => "9260000001",
      "expiry_date" => "2019-07-25",
      "civil_status" => "Single",
      "mobile2" => "",
      "tcc" => ""
    }
  end

  def member_dependent_parameters() do
    %{
        "type" => "Dependent",
        "account_code" => "C0050",
        "effectivity_date" => "2018-07-25",
        "expiry_date" => "2019-07-25",
        "first_name" => "ZULUETO",
        "middle_name" => nil,
        "last_name" => "MAXI D MEMBER",
        "suffix" => "",
        "gender" => "Male",
        "civil_status" => "Married",
        "date_hired" => "2018-07-25",
        "is_regular" => true,
        "regularization_date" => "2019-07-24",
        "tin" => "",
        "philhealth" => "000000000001",
        "for_card_issuance" => true,
        "email" => "medilinktest@yahoo.com",
        "email2" => "",
        "mcc" => "+63",
        "mobile" => "9260000001",
        "mcc2" => "",
        "mobile2" => "",
        "tcc" => "",
        "telephone" => "",
        "fcc" => "",
        "fax" => "",
        "postal" => "",
        "unit_no" => "",
        "building_name" => "",
        "street_name" => "",
        "city" => "",
        "province" => "",
        "region" => "",
        "policy_no" => "180227669502",
        "relationship" => "Parent",
        "birthdate" => "1980-02-26",
        "philhealth_type" => "Required to file",
        "principal_product_code" => "PRD-799407",
        "products" => ["PRD-799407"],
        "employee_no" => "MC201801084996767",
        "card_no" => "1168011039921617",
        "status" => "Active"
    }
  end

  ########################### end member_existing_migration related #################################

end
