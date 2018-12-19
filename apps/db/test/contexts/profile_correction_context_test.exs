defmodule Innerpeace.Db.Base.ProfileCorrectionContextTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Base.ProfileCorrectionContext

  # test "create_request_prof_cor with valid params" do
  #   user =
  #     :user
  #     |> insert()

  #   params = %{
  #     "birth_date" => %{
  #       "day" => "12",
  #       "month" => "12",
  #       "year" => "2012"
  #     },
  #     "id_card" => %Plug.Upload{
  #     content_type: "image/jpeg",
  #     filename: "balloon_flight_plant_91681_1920x1080.jpg",
  #     path: "/tmp/plug-1516/multipart-1516938004-564503958156687-6"}
  #   }

  #   raise ProfileCorrectionContext.create_request_prof_cor(user.id, params)

  # end

  test "create_request_prof_cor with invalid params" do
    user =
      :user
      |> insert()

    params = %{
      "birth_date" => %{
        "day" => "41",
        "month" => "12",
        "year" => "2012"
      },
      "id_card" => %Plug.Upload{content_type: "image/jpeg", filename: "balloon_flight_plant_91681_1920x1080.jpg", path: "/tmp/plug-1516/multipart-1516938004-564503958156687-6"}
    }

    {status, result} =
      user.id
      |> ProfileCorrectionContext.create_request_prof_cor(params)

    assert status == :error
    refute result.valid?
  end

  test "insert_request_prof_cor with valid params" do

  end

  test "insert_request_prof_cor with invalid params" do
    params = %{
      "birth_date" => %{
        "day" => "41",
        "month" => "12",
        "year" => "2012"
      },
      "id_card" => %Plug.Upload{content_type: "image/jpeg", filename: "balloon_flight_plant_91681_1920x1080.jpg", path: "/tmp/plug-1516/multipart-1516938004-564503958156687-6"},
      "status" => "for approval"
    }

    {status, result} =
      params
      |> ProfileCorrectionContext.insert_request_prof_cor()

    assert status == :error
    refute result.valid?
  end
end
