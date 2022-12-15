defmodule EmployeeRewardAppWeb.DashboardController do
  use EmployeeRewardAppWeb, :controller
  alias EmployeeRewardApp.Repo
  alias EmployeeRewardApp.Transactions.Transaction
  alias EmployeeRewardApp.Accounts.User
  import Ecto.Query, warn: false

  def index(conn, _params) do
    if conn.assigns.current_user.is_admin do
      transactions =
        from(transaction in Transaction,
          join: from in User,
          on: transaction.from == from.id,
          join: to in User,
          on: transaction.to == to.id,
          select: [transaction: transaction, from: from, to: to]
        )
        |> Repo.all()

      render(conn, "admin_dashboard.html", transactions: transactions)
    else
      transactions =
        from(transaction in Transaction,
          join: to in User,
          on: transaction.to == to.id,
          where: transaction.from == ^conn.assigns.current_user.id,
          select: [transaction: transaction, to: to]
        )
        |> Repo.all()

      render(conn, "dashboard.html", transactions: transactions)
    end
  end
end
