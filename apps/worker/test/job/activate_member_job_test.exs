defmodule Innerpeace.Worker.Job.ActivateMemberJobTest do
  use Innerpeace.Db.SchemaCase, async: false
  use WorkerWeb.ConnCase

  # test "enqueue activate member with valid params" do
  #   member = insert(:member)

  #   Exq.start_link(mode: :enqueuer)

  #   {status, result} =
  #   Exq.Enqueuer
  #   |> Exq.Enqueuer.enqueue(
  #     "member_activation_job_test",
  #     "Innerpeace.Worker.Job.ActivateMemberJob",
  #     [member.id])

  #   assert status == :ok
  # end

  # test "EXQ Worker server" do
  #   {status, pid} = Exq.start_link(mode: :api)

  #   assert status == :ok
  # end
end
