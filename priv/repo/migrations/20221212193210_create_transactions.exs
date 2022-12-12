defmodule EmployeeRewardApp.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  def change do
    create table(:transactions) do
      add :value, :integer
      add :from, references(:users, on_delete: :nothing)
      add :to, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:transactions, [:from])
    create index(:transactions, [:to])
  end
end
