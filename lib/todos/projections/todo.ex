defmodule Todos.Projections.Todo do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, except: [:__meta__]}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "todos" do
    field(:user_id, :id)
    field(:content, :string)
    field(:status, Ecto.Enum, values: [:in_progress, :done])

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(todo, attrs) do
    todo
    |> cast(attrs, [:content, :status])
    |> validate_required([:content, :status])
  end
end
