defmodule EmployeeRewardApp.TransactionsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `EmployeeRewardApp.Transactions` context.
  """

  @doc """
  Generate a transaction.
  """
  def transaction_fixture(attrs \\ %{}) do
    {:ok, transaction} =
      attrs
      |> Enum.into(%{
        value: 42
      })
      |> EmployeeRewardApp.Transactions.create_transaction()

    transaction
  end
end
