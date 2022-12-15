defmodule EmployeeRewardApp.Transactions.Transaction do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false
  alias EmployeeRewardApp.Transactions.Transaction
  alias EmployeeRewardApp.Accounts
  alias EmployeeRewardApp.Repo

  schema "transactions" do
    field :value, :integer
    field :from, :id
    field :to, :id

    timestamps()
  end

  def verify_monthly_limit(changeset, user_field, value_field) do
    {_, user_field} = fetch_field(changeset, user_field)
    {_, value} = fetch_field(changeset, value_field)

    {:ok, month_beginning} =
      NaiveDateTime.new(Date.beginning_of_month(Date.utc_today()), ~T[00:00:00])

    sent_amount =
      from(transaction in Transaction,
        where: transaction.from == ^user_field,
        where: transaction.inserted_at >= ^month_beginning,
        select: sum(transaction.value)
      )
      |> Repo.one() || 0

    user_limit = Accounts.get_user!(user_field).transaction_limit

    if sent_amount + value <= user_limit do
      changeset
    else
      changeset
      |> add_error(
        :value,
        "You'll exceed your limit - %{sent_amount}/%{user_limit} sent. You can send only %{max_send}",
        sent_amount: sent_amount,
        user_limit: user_limit,
        max_send: user_limit - sent_amount
      )
    end
  end

  @doc false
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:value, :from, :to])
    |> validate_required([:value, :from, :to])
    |> validate_number(:value, greater_than: 0)
  end

  def changeset_val(transaction, attrs) do
    transaction
    |> changeset(attrs)
    |> verify_monthly_limit(:from, :value)
  end
end
