defmodule Todos.Projections.Achievement do
  use Ecto.Schema

  @derive {Jason.Encoder, except: [:__meta__]}
  @primary_key {:id, :binary_id, autogenerate: false}
  schema "achievements" do
    field :user_id, :id
    field :achievement_type, :string
    field :title, :string
    field :description, :string
    field :unlocked_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end
end
