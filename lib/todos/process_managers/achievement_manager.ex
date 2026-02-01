defmodule Todos.ProcessManagers.AchievementManager do
  use Commanded.ProcessManagers.ProcessManager,
    application: Todos.CommandedApp,
    name: "AchievementManager"

  @derive Jason.Encoder
  defstruct user_id: nil, completed_count: 0, unlocked: []

  alias Commanded.UUID
  alias Todos.Events.{TodoCompleted, AchievementUnlocked}
  alias Todos.Commands.UnlockAchievement

  # Route events to process manager instance by user_id
  def interested?(%TodoCompleted{user_id: user_id}), do: {:start, user_id}
  def interested?(%AchievementUnlocked{user_id: user_id}), do: {:continue!, user_id}
  def interested?(_event), do: false

  # Update state from events (event-driven state changes - called first)
  def apply(%__MODULE__{} = state, %TodoCompleted{user_id: user_id}) do
    %{state |
      user_id: state.user_id || user_id,
      completed_count: state.completed_count + 1
    }
  end

  def apply(%__MODULE__{unlocked: unlocked} = state, %AchievementUnlocked{achievement_type: type}) do
    %{state | unlocked: [type | unlocked]}
  end

  # Dispatch commands based on current state (called before apply/2)
  def handle(
        %__MODULE__{
          user_id: user_id,
          completed_count: count,
          unlocked: unlocked
        },
        %TodoCompleted{user_id: event_user_id}
      ) do
    new_count = count + 1
    actual_user_id = user_id || event_user_id

    check_achievements(actual_user_id, new_count, unlocked)
  end

  # Handle command dispatch errors
  def error({:error, :already_unlocked}, _failed_command, _failure_context) do
    # Achievement already exists, continue processing
    :skip
  end

  def error(error, _command, _context) do
    # Stop on unknown errors
    {:stop, error}
  end

  # Generate achievement unlock commands based on milestones
  defp check_achievements(user_id, count, already_unlocked) do
    [
      {5, "first_five", "Getting Started", "Complete 5 todos"},
      {25, "twenty_five", "Task Master", "Complete 25 todos"},
      {100, "one_hundred", "Century Club", "Complete 100 todos"}
    ]
    |> Enum.filter(fn {threshold, type, _, _} ->
      count == threshold && type not in already_unlocked
    end)
    |> Enum.map(fn {_threshold, type, title, description} ->
      %UnlockAchievement{
        achievement_id: UUID.uuid4(),
        user_id: user_id,
        achievement_type: type,
        title: title,
        description: description
      }
    end)
  end
end
