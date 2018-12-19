defmodule Innerpeace.PayorLink.Web.UserChannel do
  @moduledoc false

  use Innerpeace.PayorLink.Web, :channel

  def join("user:lobby", _payload, socket) do
    {:ok, socket}
  end

  def join("user:" <> _user_id, _params, _socket) do
    {:error, %{reason: "unauthorized"}}
  end

  def handle_in("new_msg", %{"body" => body}, socket) do
    broadcast! socket, "new_msg", %{body: body}
    {:noreply, socket}
  end

  def handle_out("new_msg", payload, socket) do
    push socket, "new_msg", payload
    {:noreply, socket}
  end
end
