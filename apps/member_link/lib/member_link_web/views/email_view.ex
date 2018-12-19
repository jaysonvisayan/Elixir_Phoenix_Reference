defmodule MemberLinkWeb.EmailView do
  use MemberLinkWeb, :view

  def invite_url(url, password_token) do
    test = url
           |> String.split(":")
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
