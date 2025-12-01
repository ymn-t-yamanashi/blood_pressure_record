defmodule BloodPressureRecordWeb.PageController do
  use BloodPressureRecordWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
