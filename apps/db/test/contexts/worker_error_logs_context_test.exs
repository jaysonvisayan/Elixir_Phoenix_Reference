defmodule Innerpeace.Db.Base.WorkerErrorLogContextTest do
  use Innerpeace.Db.SchemaCase
  alias Innerpeace.Db.Base.WorkerErrorLogContext, as: WELC

  # test "get_all_logs/0, with valid params" do
  #   log = insert(:worker_error_log,
  #          job_name: "testJob",
  #          module_name: "testModule",
  #          function_name: "testFunction",
  #          error_description: "testDescription",
  #          inserted_at: "2018-08-09 12:41:36.789128+08"
  #   )
  #   log2 = insert(:worker_error_log,
  #          job_name: "testJob2",
  #          module_name: "testModule2",
  #          function_name: "testFunction2",
  #          error_description: "testDescription2",
  #          inserted_at: "2018-08-09 13:41:36.789128+08"
  #   )
  #   logs = WELC.get_all_logs()

  #   assert log.id == List.first(logs).id
  #   assert 2 == Enum.count(logs)
  # end

  # test "get_all_logs/0i, with nil as result" do
  #   insert(:worker_error_log,
  #          job_name: "testJob",
  #          module_name: "testModule",
  #          function_name: "testFunction",
  #          error_description: "testDescription"
  #   )

  #   logs = WELC.get_all_logs()

  #   assert [] == logs
  # end

  test "insert_log/1, insert worker error log with valid params" do
    params = %{
      job_name: "testJob",
      module_name: "testModule",
      function_name: "testFunction",
      error_description: "testDescription"
    }

    {:ok, wel} = WELC.insert_log(params)
    assert wel.job_name == "testJob"
    assert wel.module_name == "testModule"
    assert wel.function_name == "testFunction"
  end

 test "insert_log/1, insert worker error log with invalid params" do
    params = %{
      job_name: 1,
      module_name: 2,
      function_name: 3,
      error_description: 4
    }

    {:error, wel} = WELC.insert_log(params)
    assert wel.valid? == false
 end

#  test "email_error_logs/0 emails error logs" do
#     date = Ecto.DateTime.utc()
#            |> Ecto.DateTime.to_erl
#            |> :calendar.datetime_to_gregorian_seconds
#            |> Kernel.-(86400)
#            |> :calendar.gregorian_seconds_to_datetime
#            |> Ecto.DateTime.from_erl
#            |> Ecto.DateTime.to_erl
#            |> NaiveDateTime.from_erl!
#            |> DateTime.from_naive!("Etc/UTC")

#     insert(:worker_error_log,
#            job_name: "testJob",
#            module_name: "testModule",
#            function_name: "testFunction",
#            error_description: "testDescription",
#            inserted_at: date
#     )

#    insert(:api_address,
#     address: "http://localhost:4000",
#     name: "PAYORLINK_2",
#     username: "masteradmin",
#     password: "P@ssw0rd"
#    )

#   WELC.email_error_logs()
#  end

 # test "email_error_logs/0, does not send email when there is no valid error log" do
 #    insert(:worker_error_log,
 #           job_name: "testJob",
 #           module_name: "testModule",
 #           function_name: "testFunction",
 #           error_description: "testDescription"
 #    )
 #    assert nil == WELC.email_error_logs
 # end
end

