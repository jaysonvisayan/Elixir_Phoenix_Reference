defmodule Innerpeace.Db.Base.LoginIpAddressContext do
  @moduledoc """
  """

  import Ecto.{Query, Changeset}, warn: false
  alias Innerpeace.Db.Repo
  alias Innerpeace.Db.Schemas.LoginIpAddress

  def get_ip_address(ip_address) do
    LoginIpAddress
    |> Repo.get_by(ip_address: ip_address)
  end

  def create_ip_address(ip_address) do
    params =
    %{
      ip_address: ip_address,
      attempts: 0
    }
    %LoginIpAddress{}
    |> LoginIpAddress.changeset(params)
    |> Repo.insert()
  end

  def create_verify_ip_address(ip_address) do
    params =
    %{
      ip_address: ip_address,
      verify_attempts: 0
    }
    %LoginIpAddress{}
    |> LoginIpAddress.changeset_verify(params)
    |> Repo.insert()
  end

  def update_ip_address(ip, params) do
    ip
    |> LoginIpAddress.changeset(params)
    |> Repo.update()
  end

  def update_verify_ip_address(ip, params) do
    ip
    |> LoginIpAddress.changeset_verify(params)
    |> Repo.update()
  end

  def add_attempt(ip_address) do
    ip_address
    |> generate_attempt(ip_address.attempts)
  end

  defp generate_attempt(ip_address, attempt) when is_nil(attempt), do: ip_address |> update_ip_address(%{attempts: 1})
  defp generate_attempt(ip_address, attempt), do: ip_address |> update_ip_address(%{attempts: attempt + 1})

  def add_verify_attempt(ip_address) do
    ip_address
    |> update_verify_ip_address(%{
      verify_attempts: ip_address.verify_attempts + 1}
    )
  end

  def remove_attempt(ip) do
    ip
    |> Ecto.Changeset.change(%{attempts: 0})
    |> Repo.update()
  end

  def remove_verify_attempt(ip) do
    ip
    |> Ecto.Changeset.change(%{verify_attempts: 0})
    |> Repo.update()
  end

end
