defmodule Auth.Guardian do
  @moduledoc false

  alias Innerpeace.Db.Base.UserContext

  use Guardian, otp_app: :auth

  def subject_for_token(user, _claims) do
    {:ok, to_string(user.id)}
  end

  def resource_from_claims(claims) do
    user =
      claims["sub"]
      |> UserContext.get_by_id

    if is_nil(user) do
      {:error, :not_found}
    else
      {:ok, user}
    end
  end
end
