defmodule TodosWeb.Live.TodoLive.Index do
  use TodosWeb, :live_view

  import Ecto.Query, only: [from: 2]

  alias Todos.Repo
  alias Todos.CommandedApp
  alias Commanded.UUID
  alias Todos.Projections.Todo

  alias Todos.Commands.{
    CreateTodo,
    CompleteTodo,
    ReopenTodo
  }

  def mount(
        _params,
        _session,
        %{
          assigns: %{current_scope: %{user: %{id: user_id}}}
        } = socket
      ) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Todos.PubSub, "todos")
      Phoenix.PubSub.subscribe(Todos.PubSub, "achievements:#{user_id}")
    end

    query =
      from(t in Todo,
        where: t.user_id == ^user_id
      )

    todos = Repo.all(query)

    {:ok, assign(socket, todos: todos, form: to_form(%{"content" => ""}))}
  end

  def handle_info(
        :todos_updated,
        %{
          assigns: %{current_scope: %{user: %{id: user_id}}}
        } = socket
      ) do
    query =
      from(t in Todo,
        where: t.user_id == ^user_id
      )

    todos = Repo.all(query)

    {:noreply, assign(socket, todos: todos)}
  end

  def handle_info({:achievement_unlocked, event}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "🎉 Achievement Unlocked: #{event.title}! #{event.description}")}
  end

  def handle_event(
        "create_todo",
        %{"content" => content},
        %{
          assigns: %{current_scope: %{user: %{id: user_id}}}
        } = socket
      ) do
    todo_id = UUID.uuid4()

    command = %CreateTodo{
      todo_id: todo_id,
      user_id: user_id,
      content: content
    }

    case CommandedApp.dispatch(command) do
      :ok ->
        {:noreply, push_event(socket, "clear-form", %{})}

      {:error, _reason} ->
        {:noreply, socket}
    end
  end

  def handle_event("toggle_status", %{"id" => todo_id}, socket) do
    todo = Repo.get(Todo, todo_id)

    command =
      case todo.status do
        :done -> %ReopenTodo{todo_id: todo_id}
        :in_progress -> %CompleteTodo{todo_id: todo_id}
      end

    case CommandedApp.dispatch(command) do
      :ok ->
        # PubSub will trigger update when projection completes
        {:noreply, socket}

      {:error, _reason} ->
        {:noreply, socket}
    end
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="container mx-auto p-4 max-w-2xl" phx-hook="TodoForm" id="todo-container">
        <h1 class="text-2xl font-bold mb-6">Todos</h1>

        <.form for={@form} phx-submit="create_todo" class="mb-6" id="todo-form">
          <div class="flex gap-2">
            <input
              type="text"
              name="content"
              placeholder="What needs to be done?"
              class="input input-bordered flex-1"
              id="todo-input"
              required
            />
            <button type="submit" class="btn btn-primary">
              Add Todo
            </button>
          </div>
        </.form>
        <ul class="space-y-2">
          <li :for={todo <- @todos} id={"todo-#{todo.id}"} class="p-4 border rounded flex items-center gap-3">
            <input
              type="checkbox"
              checked={todo.status == :done}
              phx-click="toggle_status"
              phx-value-id={todo.id}
              class="checkbox"
            />
            <div class="flex-1">
              <p class={if todo.status == :done, do: "line-through text-gray-400", else: ""}>
                <%= todo.content %>
              </p>
            </div>
          </li>
        </ul>
      </div>
    </Layouts.app>
    """
  end
end
