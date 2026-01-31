defmodule Todos.Projectors.TodoProjector do
  use Commanded.Projections.Ecto,
    application: Todos.CommandedApp,
    repo: Todos.Repo,
    name: "TodoProjector",
    consistency: :strong

  import Ecto.Query

  alias Todos.Events.{TodoCreated, TodoCompleted, TodoReopened}
  alias Todos.Projections.Todo

  project(%TodoCreated{} = event, _metadata, fn multi ->
    Ecto.Multi.insert(
      multi,
      :todo,
      %Todo{
        id: event.todo_id,
        user_id: event.user_id,
        content: event.content,
        status: :in_progress
      }
    )
  end)

  project(%TodoCompleted{todo_id: todo_id}, _metadata, fn multi ->
    Ecto.Multi.update_all(
      multi,
      :todo,
      from(t in Todo, where: t.id == ^todo_id),
      set: [
        status: :done
      ]
    )
  end)

  project(%TodoReopened{todo_id: todo_id}, _metadata, fn multi ->
    Ecto.Multi.update_all(
      multi,
      :todo,
      from(t in Todo, where: t.id == ^todo_id),
      set: [
        status: :in_progress
      ]
    )
  end)

  @impl Commanded.Projections.Ecto
  def after_update(_event, _metadata, _changes) do
    Phoenix.PubSub.broadcast(Todos.PubSub, "todos", :todos_updated)
    :ok
  end
end
