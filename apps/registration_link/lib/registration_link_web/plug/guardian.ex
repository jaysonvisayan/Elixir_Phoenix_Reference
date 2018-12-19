defmodule RegistrationLink.Guardian do
  @moduledoc false

  use Guardian, otp_app: :registration_link

  alias Innerpeace.Db.{Repo, Schemas.User}

  def subject_for_token(resource, _claims) do
    {:ok, to_string(resource.id)}
  end

  def subject_for_token(_, _) do
    {:error, :reason_for_error}
  end

  def resource_from_claims(claims) do
    # raise claims["sub"]

    {:ok, find_me_a_resource(claims["sub"])}
  end

  def resource_from_claims(_claims) do
    {:error, :reason_for_error}
  end

  def find_me_a_resource(id) do
    Repo.get(User, id)
  end
end
