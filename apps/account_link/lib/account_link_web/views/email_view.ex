defmodule AccountLinkWeb.EmailView do
  use AccountLinkWeb, :view

  def invite_url(url, password_token) do
    test = String.split(url, ":")
    test =
      test
      |> Enum.at(1)
    case Mix.env do
      :dev ->
        "/create?password_token=#{password_token}"
      :prod ->
        "http:#{test}/create?password_token=#{password_token}"
      :test ->
        "/create?password_token=#{password_token}"
      _ ->
        raise "Invalid ENV!"
    end
  end

end
