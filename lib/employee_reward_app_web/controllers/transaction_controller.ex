defmodule EmployeeRewardAppWeb.TransactionController do
  use EmployeeRewardAppWeb, :controller

  alias EmployeeRewardApp.Transactions
  alias EmployeeRewardApp.Accounts
  alias EmployeeRewardApp.Transactions.Transaction
  alias EmployeeRewardApp.Repo
  import Ecto.Query, warn: false
  alias EmployeeRewardApp.Accounts.User

  defp get_transactions(conn) do
    if conn.assigns.current_user.is_admin do
      from(transaction in Transaction,
        join: user in User,
        on: user.id == transaction.to,
        select: %{user: user, transaction: transaction}
      )
      |> Repo.all()
    else
      from(transaction in Transaction,
        where: transaction.from == ^conn.assigns.current_user.id,
        join: user in User,
        on: user.id == transaction.to,
        select: %{user: user, value: transaction}
      )
      |> Repo.all()
    end
  end

  def index(conn, _params) do
    render(conn, "index.html", transactions: get_transactions(conn))
  end

  @spec new(Plug.Conn.t(), any) :: Plug.Conn.t()
  def new(conn, _params) do
    changeset = Transactions.change_transaction(%Transaction{})

    users =
      from(user in User, where: user.id != ^conn.assigns.current_user.id)
      |> Repo.all()
      |> Enum.map(fn user -> {user.email, user.id} end)

    render(conn, "new.html", changeset: changeset, users: users)
  end

  def create(conn, %{"transaction" => transaction_params}) do
    transaction_params = transaction_params |> Map.put("from", conn.assigns.current_user.id)

    case Transactions.create_transaction(transaction_params) do
      {:ok, transaction} ->
        Accounts.get_user!(transaction.to)
        |> Accounts.UserNotifier.deliver_points_notification(transaction.value)

        conn
        |> put_flash(:info, "Transaction created successfully.")
        |> redirect(to: Routes.transaction_path(conn, :show, transaction))

      {:error, %Ecto.Changeset{} = changeset} ->
        users =
          from(user in User, where: user.id != ^conn.assigns.current_user.id)
          |> Repo.all()
          |> Enum.map(fn user -> {user.email, user.id} end)

        render(conn, "new.html", changeset: changeset, users: users)
    end
  end

  def show(conn, %{"id" => id}) do
    transaction = Transactions.get_transaction!(id)
    from_user = Accounts.get_user!(transaction.from)
    to_user = Accounts.get_user!(transaction.to)
    render(conn, "show.html", transaction: transaction, from_user: from_user, to_user: to_user)
  end

  def edit(conn, %{"id" => id}) do
    transaction = Transactions.get_transaction!(id)
    changeset = Transactions.change_transaction(transaction)

    users =
      from(user in User, where: user.id != ^conn.assigns.current_user.id)
      |> Repo.all()
      |> Enum.map(fn user -> {user.email, user.id} end)

    render(conn, "edit.html", transaction: transaction, changeset: changeset, users: users)
  end

  def update(conn, %{"id" => id, "transaction" => transaction_params}) do
    transaction = Transactions.get_transaction!(id)

    case Transactions.update_transaction(transaction, transaction_params) do
      {:ok, transaction} ->
        conn
        |> put_flash(:info, "Transaction updated successfully.")
        |> redirect(to: Routes.transaction_path(conn, :show, transaction))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", transaction: transaction, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    transaction = Transactions.get_transaction!(id)
    {:ok, _transaction} = Transactions.delete_transaction(transaction)

    conn
    |> put_flash(:info, "Transaction deleted successfully.")
    |> redirect(to: Routes.transaction_path(conn, :index))
  end
end
