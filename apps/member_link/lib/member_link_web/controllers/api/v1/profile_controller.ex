defmodule MemberLinkWeb.Api.V1.ProfileController do
  use MemberLinkWeb, :controller

  alias Guardian.Plug
  alias MemberLinkWeb.Api.ErrorView
  alias Innerpeace.Db.Base.{
    MemberContext,
    UserContext,
    Api.KycContext,
    Api.ProfileCorrectionContext
  }

  alias Innerpeace.Db.Base.Api.{
    UtilityContext
  }

  alias Innerpeace.Db.Schemas.{
    Member,
    User,
    ProfileCorrection
  }

  alias Innerpeace.Db.Parsers.MemberLinkParser
  alias MemberLink.Guardian, as: MG

  def get_member(conn, _params) do
    user = MG.current_resource_api(conn)
    if user.member_id == "" || user.member_id == nil do
      conn
      |> put_status(400)
      |> render(ErrorView, "error.json", message: "Wrong User and Password", code: 400)
    else
      case MemberContext.get_member(user.member_id) do
        member = %Innerpeace.Db.Schemas.Member{} ->
          render(conn, "show.json", member: member)
        nil ->
          conn
          |> put_status(400)
          |> render(ErrorView, "error.json", message: "Wrong User and Password", code: 400)
        _ ->
          conn
          |> put_status(500)
          |> render(ErrorView, "error.json", message: "Server Error", code: 500)
      end
    end
  end

  def update_member_profile(conn, params) do
    user = MG.current_resource_api(conn)
    if user.member_id == "" || user.member_id == nil do
      conn
      |> put_status(400)
      |> render(ErrorView, "error.json", message: "Wrong User and Password", code: 400)
    else
      with {:ok, prof_cor} <-
        ProfileCorrectionContext.create_request_prof_cor(
          user.id, params
        )
      do
        render(conn, "request_cor.json", prof_cor: prof_cor)
      else
        {:error_upload_params} ->
          conn
          |> put_status(400)
          |> render(ErrorView, "error.json", message: "Invalid Upload Parameters", code: 400)
        {:error_base_64} ->
          conn
          |> put_status(400)
          |> render(ErrorView, "error.json", message: "Invalid Upload Base 64", code: 400)
        {:error, changeset} ->
          conn
          |> put_status(400)
          |> render(ErrorView, "changeset_error_api.json", changeset: changeset)
        {:atleast_one} ->
          conn
          |> put_status(400)
          |> render(ErrorView, "error.json", message: "One of these fields must be present: [Name, Birth Date, Gender]", code: 400)
        _ ->
          conn
          |> put_status(500)
          |> render(ErrorView, "error.json", message: "Server Error", code: 500)
      end
    end
  end

  def update_member_profile_photo(conn, params) do
    user = MG.current_resource_api(conn)
    member = MemberContext.get_member(user.member_id)
    if params["photo"] do
      with {:ok, "uploads"} <- KycContext.validate_upload_profile(params["photo"]) do
        member = MemberLinkParser.upload_an_image_profile(member.id, params["photo"])
        render(conn, "show_photo.json", photo: member)
      else
        {:error_upload_params} ->
          conn
          |> put_status(400)
          |> render(ErrorView, "error.json", message: "Invalid Upload Parameters", code: 400)
        {:error_base_64} ->
          conn
          |> put_status(400)
          |> render(ErrorView, "error.json", message: "Invalid Upload Base 64", code: 400)
      end
    else
      render(conn, "show_photo.json", photo: member)
    end
  end

  def get_dependents(conn, _params) do
    user = MG.current_resource_api(conn)
    if user.member_id == "" || user.member_id == nil do
      conn
      |> put_status(400)
      |> render(ErrorView, "error.json", message: "Wrong User and Password", code: 400)
    else
      cond do
        [] == MemberContext.get_dependents_by_member_id(user.member_id) ->
          conn
          |> put_status(400)
          |> render(ErrorView, "error.json", message: "No dependents found", code: 400)
        member = MemberContext.get_dependents_by_member_id(user.member_id) ->
          render(conn, "dependents.json", member: member)
        true ->
          conn
          |> put_status(500)
          |> render(ErrorView, "error.json", message: "Server Error", code: 500)
      end
    end
  end

  def register_dependent(conn, params) do
    user = MG.current_resource_api(conn)
    if user.member_id == "" || user.member_id == nil do
      conn
      |> put_status(400)
      |> render(ErrorView, "error.json", message: "Wrong User and Password", code: 400)
    else
      birthdate = params["birth_date"]
      params = Map.delete(params, "birth_date")
      with _member = %Member{} <- MemberContext.get_member(user.member_id),
           {:ok, date} <- UtilityContext.birth_date_transform(birthdate),
           {:ok, member} <- MemberContext.create_dependent(Map.merge(params, %{"birthdate" => date}))
      do
        render(conn, "dependent.json", member: member)
      else
        {:invalid_datetime_format} ->
          conn
          |> put_status(400)
          |> render(ErrorView, "error.json", message: "Invalid Birth Date Format", code: 400)
        nil ->
          conn
          |> put_status(400)
          |> render(ErrorView, "error.json", message: "Wrong User and Password", code: 400)
        {:error, changeset} ->
          conn
          |> put_status(400)
          |> render(ErrorView, "changeset_error.json", message: changeset, code: 400)
        _ ->
          conn
          |> put_status(500)
          |> render(ErrorView, "error.json", message: "Server Error", code: 500)
      end
    end
  end

  def create_emergency_contact(conn, params) do
    user = MG.current_resource_api(conn)
    if user.member_id == "" || user.member_id == nil do
      conn
      |> put_status(400)
      |> render(ErrorView, "error.json", message: "Wrong User and Password", code: 400)
    else
      member = MemberContext.get_member(user.member_id)
      emergency_params = Map.merge(params["contact_person"], params["hospital"])
      with {:ok, member} <- MemberContext.insert_member_info(member, params["info"]),
           {:ok, member_emergency_info} <- MemberContext.insert_or_update_member_emergency_info(member, emergency_params)
      do
        member = MemberContext.get_member(member_emergency_info.member_id)
        render(conn, "emergency_contact.json", contact: member)
      else
        nil ->
          conn
          |> put_status(400)
          |> render(ErrorView, "error.json", message: "Wrong User and Password", code: 400)
        {:error, changeset} ->
          conn
          |> put_status(400)
          |> render(ErrorView, "changeset_error_api.json", changeset: changeset)
        _ ->
          conn
          |> put_status(500)
          |> render(ErrorView, "error.json", message: "Server Error", code: 500)
      end
    end
  end

  def update_emergency_contact(conn, params) do
    user = MG.current_resource_api(conn)
    if user.member_id == "" || user.member_id == nil do
      conn
      |> put_status(400)
      |> render(ErrorView, "error.json", message: "Wrong User and Password", code: 400)
    else
      member = MemberContext.get_member(user.member_id)
      emergency_params = Map.merge(params["contact_person"], params["hospital"])
      with {:ok, member} <- MemberContext.insert_member_info(member, params["info"]),
           {:ok, member_emergency_info} <- MemberContext.insert_or_update_member_emergency_info(member, emergency_params)
      do
        member = MemberContext.get_member(member_emergency_info.member_id)
        render(conn, "update_emergency_contact.json", contact: member)
      else
        nil ->
          conn
          |> put_status(400)
          |> render(ErrorView, "error.json", message: "Wrong User and Password", code: 400)
        {:error, changeset} ->
          conn
          |> put_status(400)
          |> render(ErrorView, "changeset_error_api.json", changeset: changeset)
        _ ->
          conn
          |> put_status(500)
          |> render(ErrorView, "error.json", message: "Server Error", code: 500)
      end
    end
  end

  def get_emergency_contact(conn, _parmas) do
    user = MG.current_resource_api(conn)
    if user.member_id == "" || user.member_id == nil do
      conn
      |> put_status(400)
      |> render(ErrorView, "error.json", message: "Wrong User and Password", code: 400)
    else
      case MemberContext.get_member(user.member_id) do
        member = %Member{} ->
          if member.emergency_contact == nil do
            conn
            |> put_status(400)
            |> render(ErrorView, "error.json", message: "No Emergency Contact Found", code: 404)
          else
            render(conn, "member_emergency_contact.json", emergency_contact: member)
          end
        nil ->
          conn
          |> put_status(400)
          |> render(ErrorView, "error.json", message: "Wrong User and Password", code: 400)
        _ ->
          conn
          |> put_status(500)
          |> render(ErrorView, "error.json", message: "Server Error", code: 500)
      end
    end
  end

  def update_contact_details(conn, params) do
    user = MG.current_resource_api(conn)
    if user.member_id == "" || user.member_id == nil do
      conn
      |> put_status(400)
      |> render(ErrorView, "error.json", message: "Wrong User and Password", code: 400)
    else
      with {:ok, %User{} = user} <-
        UserContext.update_contact_details(
          user,
          params)
      do
        render(conn, "update_contact_details.json", user: user)
      else
        {:error, changeset} ->
          conn
          |> put_status(400)
          |> render(ErrorView, "changeset_error_api.json", changeset: changeset)
        _ ->
          conn
          |> put_status(500)
          |> render(ErrorView, "error.json", message: "Server Error", code: 500)
      end
    end
  end

  # defp validate_upload(params) do
  #   types = %{
  #     base_64_encoded: :string,
  #     type: :string,
  #     extension: :string,
  #     link: :string
  #   }

  #   changeset =
  #     {%{}, types}
  #     |> Ecto.Changeset.cast(params, Map.keys(types))
  #     |> Ecto.Changeset.validate_required([
  #       :base_64_encoded,
  #       :type,
  #       :extension,
  #       :link
  #     ], message: "is required")

  #   if changeset.valid? and (params["type"] == "file" or params["type"] == "image") do
  #     {:ok, "upload"}
  #   else
  #     {:error, "upload error"}
  #   end
  # end

  # defp error_msg(conn, status, message) do
  #   conn
  #   |> put_status(status)
  #   |> render(ErrorView, "error.json", message: message, code: status)
  # end

  # defp changeset_error_msg(conn, status, message) do
  #   conn
  #   |> put_status(status)
  #   |> render(ErrorView, "changeset_error.json", message: message, code: status)
  # end
end
