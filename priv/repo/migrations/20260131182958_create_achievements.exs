defmodule Todos.Repo.Migrations.CreateAchievements do
  use Ecto.Migration

  def change do
    create table(:achievements, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, :id, null: false
      add :achievement_type, :string, null: false
      add :title, :string, null: false
      add :description, :text
      add :unlocked_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:achievements, [:user_id])
    create unique_index(:achievements, [:user_id, :achievement_type])
  end
end
