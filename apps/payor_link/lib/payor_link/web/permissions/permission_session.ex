defmodule Innerpeace.Permission.Session do
  @moduledoc false

  use Phoenix.Controller

  def get_permission(conn) do
    get_session(conn, :permissions) || []
  end

  def get_application(conn) do
    get_session(conn, :applications) || []
  end
end
