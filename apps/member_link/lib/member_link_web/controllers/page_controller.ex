defmodule MemberLinkWeb.PageController do
  use MemberLinkWeb, :controller
  alias Innerpeace.Db.Base.{
    AuthorizationContext,
    MemberContext
  }
  import Ecto.Query
  alias Innerpeace.Db.Repo

  alias MemberLink.Guardian, as: MG
  alias MemberLinkWeb.PageView

  def index(conn, _params) do
    user = MG.current_resource(conn)
    user = user |> Repo.preload(member: :dependents)

    member = user.member
    authorizations = AuthorizationContext.get_all_loa_by_member_id(member.id)

    render conn,
      "dashboard.html",
      authorizations: authorizations,
      member: member
  end

  def export_csv(conn, %{"id" => member_id}) do
    data =
      [[
        'Member', 'Facility/Doctor', 'Service Date',
        'Coverage', 'Type', 'Status', 'Amount'
      ]]
    loa =
      member_id
      |> AuthorizationContext.get_all_loa_by_member_id(:selected)
      |> Enum.into([], fn([r, f, d, c, s, t]) ->
          if is_nil(r) do
            ["Me", f, d, c, "LOA", s, t]
          else
            [r, f, d, c, "LOA", s, t]
          end
         end)
    data =
      data ++ loa
      |> CSV.encode
      |> Enum.to_list
      |> to_string

    conn
    |> json(data)
  end

  def export_pdf(conn, %{"id" => member_id}) do
    member = MemberContext.get_member!(member_id)
    authorizations = AuthorizationContext.get_all_loa_by_member_id(member.id)

    html = Phoenix.View.render_to_string(PageView, "export_pdf.html",
      authorizations: authorizations,
      member: member,
      conn: conn)


    {date, time} = :erlang.localtime
    unique_id = Enum.join(Tuple.to_list(date)) <> Enum.join(Tuple.to_list(time))
    filename = "#{member.last_name}_#{member.first_name}_#{unique_id}"

    with {:ok, content} <- PdfGenerator.generate_binary html, filename: filename, delete_temporary: true
    do
      conn
      |> put_resp_content_type("application/pdf")
      |> put_resp_header("content-disposition", "inline; filename=#{filename}.pdf")
      |> send_resp(200, content)
     else
       {:error, _reason} ->
        raise _reason
         conn
         |> put_flash(:error, "Failed to export pdf.")
         |> redirect(to: "/")
    end
  end

  def smarthealth(conn, _params) do
    user = MG.current_resource(conn)
    render conn, "smarthealth.html", user: user
  end
end
