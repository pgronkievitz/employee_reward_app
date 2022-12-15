defmodule EmployeeRewardAppWeb.UserSettingsAdminController do
  use EmployeeRewardAppWeb, :controller

  alias EmployeeRewardApp.Repo
  alias EmployeeRewardApp.Accounts.User
  alias EmployeeRewardApp.Accounts
  alias EmployeeRewardApp.Transactions.Transaction
  import Ecto.Query, warn: false

  def index(conn, _params) do
    render(conn, "index.html", users: Repo.all(User))
  end

  def edit(conn, params) do
    user = Accounts.get_user!(params["id"])
    changeset = Accounts.change_user_transaction_limit(user)

    conn
    |> render("edit.html", params: params, limit_changeset: changeset)
  end

  def update(conn, %{"action" => "update_limit"} = params) do
    %{"id" => id, "user" => user_params} = params
    user_orig = Accounts.get_user!(id)

    case Accounts.update_transaction_limit(user_orig, user_params) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Transaction limit updated successfully.")
        |> redirect(to: Routes.user_settings_admin_path(conn, :index))

      {:error, changeset} ->
        render(conn, "edit.html", params: params, limit_changeset: changeset)
    end
  end

  def show(conn, params) do
    user = Accounts.get_user!(params["id"])

    data =
      from(Transaction)
      |> where([t], t.from == ^user.id)
      |> join(:inner, [t], u in User, on: t.to == u.id)
      |> group_by([t, u], [
        u.email,
        fragment("date_part('month', ?)", t.inserted_at),
        fragment("date_part('year', ?)", t.inserted_at)
      ])
      |> select(
        [t, u],
        %{
          email: u.email,
          value: sum(t.value),
          month: fragment("date_part('month', ?)", t.inserted_at),
          year: fragment("date_part('year', ?)", t.inserted_at)
        }
      )
      |> Repo.all()

    render(conn, "show.html", data: data, user: user)
  end
end
