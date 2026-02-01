defmodule TodosWeb.Live.AchievementLive.List do
  use TodosWeb, :live_view

  import Ecto.Query, only: [from: 2]

  alias Todos.Repo
  alias Todos.Projections.Achievement

  def mount(
        _params,
        _session,
        %{
          assigns: %{current_scope: %{user: %{id: user_id}}}
        } = socket
      ) do
    query =
      from(t in Achievement,
        where: t.user_id == ^user_id
      )

    achievements = Repo.all(query)

    {:ok, assign(socket, achievements: achievements, form: to_form(%{"content" => ""}))}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="container mx-auto p-4 max-w-2xl" id="achievement-container">
        <h1 class="text-2xl font-bold mb-6">Achievements</h1>
        <ul class="space-y-2">
          <li :for={achievement <- @achievements} id={"achievement-#{achievement.id}"} class="p-4 border rounded flex items-center gap-3">
            <div class="flex-1">
              <p>
                <%= achievement.title %>
              </p>
            </div>
          </li>
        </ul>
      </div>
    </Layouts.app>
    """
  end
end
