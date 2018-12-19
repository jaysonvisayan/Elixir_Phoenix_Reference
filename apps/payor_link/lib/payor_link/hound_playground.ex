defmodule Innerpeace.PayorLink.Web.HoundPlayground do
  @moduledoc false

  use Hound.Helpers

  def fetch_ip do
    Hound.start_session
    navigate_to("http://payorlink-ip-uat.medilink.com.ph")

    IO.inspect page_source()

    Hound.end_session
  end

end
