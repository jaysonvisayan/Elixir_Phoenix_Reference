defmodule Innerpeace.Worker.Job.TriggerGenerateClaimsFileJob do
  @moduledoc "This module activates member on it's effectivity date"

  def perform do
    generate_claims()
  end

  def generate_claims do
    # 2hrs
    Exq
    |> Exq.enqueue_in(
      "generate_claims_file_job",
      7200,
      "Innerpeace.Worker.Job.GenerateClaimsFileJob",
      []
    )
    # 4hrs
    Exq
    |> Exq.enqueue_in(
      "generate_claims_file_job",
      14_400,
      "Innerpeace.Worker.Job.GenerateClaimsFileJob",
      []
    )
    # 6hrs
    Exq
    |> Exq.enqueue_in(
      "generate_claims_file_job",
      21_600,
      "Innerpeace.Worker.Job.GenerateClaimsFileJob",
      []
    )
    # 8hrs
    Exq
    |> Exq.enqueue_in(
      "generate_claims_file_job",
      28_800,
      "Innerpeace.Worker.Job.GenerateClaimsFileJob",
      []
    )
    # 10hrs
    Exq
    |> Exq.enqueue_in(
      "generate_claims_file_job",
      36_000,
      "Innerpeace.Worker.Job.GenerateClaimsFileJob",
      []
    )
    # 12hrs
    Exq
    |> Exq.enqueue_in(
      "generate_claims_file_job",
      43_200,
      "Innerpeace.Worker.Job.GenerateClaimsFileJob",
      []
    )
  end

end
