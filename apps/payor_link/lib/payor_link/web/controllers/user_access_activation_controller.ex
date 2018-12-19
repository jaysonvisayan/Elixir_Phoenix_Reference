defmodule Innerpeace.PayorLink.Web.UserAccessActivationController do
  use Innerpeace.PayorLink.Web, :controller

  alias Innerpeace.Db.Schemas.{
    User,
    UserAccessActivationFile,
    UserAccessActivationLog
  }

  alias Innerpeace.Db.Base.{
    UserContext
  }

  def index(conn, _params) do
    uaa_files = UserContext.get_uaa_files()
    render(conn, "index.html", uaa_files: uaa_files)
  end

  def import_activation(conn, %{"activation" => activation_params}) do
    case UserContext.create_activation_import(activation_params, conn.assigns.current_user.id) do
      {:ok} ->
        conn
        |> put_flash(:info, "Batch successfully uploaded.")
        |> redirect(to: "/user_access_activations")
      {:not_found} ->
        conn
        |> put_flash(:error, "File has empty records.")
        |> redirect(to: "/user_access_activations")
      {:not_equal} ->
        conn
        |> put_flash(:error, "Invalid column format")
        |> redirect(to: "/user_access_activations")
      {:not_equal, columns} ->
        conn
        |> put_flash(:error, "File has missing column/s: #{columns}")
        |> redirect(to: "/user_access_activations")
      {:invalid_format} ->
        conn
        |> put_flash(:error, "Acceptable files is .csv")
        |> redirect(to: "/user_access_activations")
      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Oops, something went wrong.")
        |> redirect(to: "/user_access_activations")
    end
  end

  def csv_log_download(conn, %{"id" => uaa_file_id, "status" => status}) do
    data =
      [[
        'Remarks',
        'Code',
        'Employee Name'
      ]]

    data =
      data ++ UserContext.get_uaa_logs(uaa_file_id, status)
      |> CSV.encode
      |> Enum.to_list
      |> to_string

    conn
    |> json(data)
  end

  def download_template(conn, _params) do
    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", "attachment; filename=\"User Access Activation.csv\"")
    |> send_resp(200, template_content())
  end

  defp template_content do
    _csv_content = [[
      'Code',
      'Employee Name'
    ], [
      '(Required)',
      '(Required)'
    ], ['', '', '', '', '', '', '']]
    |> CSV.encode
    |> Enum.to_list
    |> to_string
  end
end
