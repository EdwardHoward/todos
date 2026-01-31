defmodule Todos.Aggregates.Todo do
  defstruct [
    :todo_id,
    :user_id,
    :content,
    :status
  ]

  alias Todos.Commands.{CreateTodo, CompleteTodo, ReopenTodo}
  alias Todos.Events.{TodoCreated, TodoCompleted, TodoReopened}

  def execute(%__MODULE__{todo_id: nil}, %CreateTodo{} = cmd),
    do: %TodoCreated{
      todo_id: cmd.todo_id,
      user_id: cmd.user_id,
      content: cmd.content
    }

  def execute(%__MODULE__{status: :in_progress, todo_id: todo_id, user_id: user_id}, %CompleteTodo{}),
    do: %TodoCompleted{
      todo_id: todo_id,
      user_id: user_id
    }

  def execute(%__MODULE__{status: :done, todo_id: todo_id}, %ReopenTodo{}),
    do: %TodoReopened{
      todo_id: todo_id
    }

  def execute(_, _) do
    {:error, :invalid_state}
  end

  def apply(%__MODULE__{}, %TodoCreated{} = event),
    do: %__MODULE__{
      todo_id: event.todo_id,
      user_id: event.user_id,
      content: event.content,
      status: :in_progress
    }

  def apply(%__MODULE__{} = todo, %TodoCompleted{}),
    do: %__MODULE__{
      todo
      | status: :done
    }

  def apply(%__MODULE__{} = todo, %TodoReopened{}),
    do: %__MODULE__{
      todo
      | status: :in_progress
    }
end
