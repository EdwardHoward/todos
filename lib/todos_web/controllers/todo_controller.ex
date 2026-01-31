defmodule TodosWeb.TodosController do
  use TodosWeb, :controller

  alias Todos.CommandedApp
  alias Commanded.UUID
  alias Todos.Repo
  alias Todos.Projections.Todo
  alias Todos.Commands.{CreateTodo, CompleteTodo, ReopenTodo}

  def index(conn, _params) do
    todos = Repo.all(Todo)

    json(conn, todos)
  end

  def show(conn, %{"todo_id" => todo_id}) do
    case Repo.get_by(Todo, id: todo_id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Todo doesn't exist"})

      todo ->
        json(conn, todo)
    end
  end

  def create(conn, %{"content" => content, "user_id" => user_id}) do
    todo_id = UUID.uuid4()

    command = %CreateTodo{
      todo_id: todo_id,
      user_id: user_id,
      content: content
    }

    case CommandedApp.dispatch(command) do
      :ok ->
        conn
        |> put_status(:created)
        |> json(%{todo_id: todo_id})

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: inspect(reason)})
    end
  end

  def complete(conn, %{"todo_id" => todo_id}) do
    dispatch(conn, %CompleteTodo{
      todo_id: todo_id
    })
  end

  def reopen(conn, %{"todo_id" => todo_id}) do
    dispatch(conn, %ReopenTodo{
      todo_id: todo_id
    })
  end

  defp dispatch(conn, command) do
    case CommandedApp.dispatch(command) do
      :ok ->
        json(conn, %{todo_id: command.todo_id})

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: inspect(reason)})
    end
  end
end
