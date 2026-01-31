defmodule Todos.Repo.Migrations.CreateTodos do
  use Ecto.Migration

  def change do
    create table(:todos, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:content, :string)
      add(:status, :string)
      add(:user_id, references(:users, type: :id, on_delete: :delete_all))

      timestamps(type: :utc_datetime)
    end
  end
end
