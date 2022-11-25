defmodule EmployeeRewardAppWeb.PageController do
  use EmployeeRewardAppWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
