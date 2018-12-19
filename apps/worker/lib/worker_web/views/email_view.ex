defmodule WorkerWeb.EmailView do
  use WorkerWeb, :view

  def count_result(migration_notifications, boolean) do
    migration_notifications
    |> Enum.filter(&(&1.is_success == boolean))
    |> Enum.count()
  end

end
