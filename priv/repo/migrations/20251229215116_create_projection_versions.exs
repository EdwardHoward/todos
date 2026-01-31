defmodule Todos.Repo.Migrations.CreateProjectionVersions do
  use Ecto.Migration

  def change do
    create table(:projection_versions, primary_key: false) do
      add :projection_name, :text, null: false
      add :last_seen_event_number, :bigint, null: false

      timestamps(type: :naive_datetime_usec)
    end

    create unique_index(:projection_versions, [:projection_name])
  end
end
