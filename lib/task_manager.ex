defmodule TaskManager do
  use GenServer
  alias TaskEntry

  @save_file "tasks.json"

  ## API pública

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def add_task(attrs) do
    GenServer.call(__MODULE__, {:add_task, attrs})
  end

  def complete_task(id) do
    GenServer.call(__MODULE__, {:complete_task, id})
  end

  def list_tasks do
    GenServer.call(__MODULE__, :list_tasks)
  end

  def list_by_priority do
    GenServer.call(__MODULE__, :list_by_priority)
  end

  def list_by_due_date do
    GenServer.call(__MODULE__, :list_by_due_date)
  end

  ## Callbacks

  def init(_) do
    state = load_tasks()
    schedule_reminder()
    {:ok, state}
  end

  def handle_call({:add_task, attrs}, _from, state) do
    id = attrs.id

    task = %TaskEntry{
      id: id,
      description: attrs.description,
      priority: attrs.priority,
      due_date: attrs.due_date,
      completed: false
    }

    new_state = Map.put(state, id, task)
    save_tasks(new_state)
    {:reply, {:ok, task}, new_state}
  end

  def handle_call({:complete_task, id}, _from, state) do
    new_state = Map.update!(state, id, fn t -> %{t | completed: true} end)
    save_tasks(new_state)
    {:reply, :ok, new_state}
  end

  def handle_call(:list_tasks, _from, state) do
    {:reply, Map.values(state), state}
  end

  def handle_call(:list_by_priority, _from, state) do
    sorted =
      state
      |> Map.values()
      |> Enum.sort_by(& &1.priority)

    {:reply, sorted, state}
  end

  def handle_call(:list_by_due_date, _from, state) do
    sorted =
      state
      |> Map.values()
      |> Enum.sort_by(& &1.due_date, Date)

    {:reply, sorted, state}
  end

  def handle_info(:recordatorio, state) do
    hoy = Date.utc_today()

    urgentes =
      state
      |> Map.values()
      |> Enum.filter(fn t -> !t.completed and Date.compare(t.due_date, hoy) in [:lt, :eq] end)
      |> Enum.sort_by(& &1.due_date)

    if urgentes != [] do
      tarea = hd(urgentes)

      IO.puts(
        "\e[31m\n ! Recordatorio: Tarea urgente '#{tarea.description}' vence el #{tarea.due_date}\e[0m"
      )
    end

    schedule_reminder()
    {:noreply, state}
  end

  ## Auxiliares

  defp schedule_reminder do
    Process.send_after(self(), :recordatorio, 20_000)
  end

  defp save_tasks(tasks) do
    json =
      tasks
      |> Map.values()
      |> Enum.map(fn t ->
        Map.update!(Map.from_struct(t), :due_date, &Date.to_iso8601/1)
      end)
      |> Jason.encode!()

    File.write(@save_file, json)
  end

  defp load_tasks do
    case File.read(@save_file) do
      {:ok, json} ->
        json
        |> Jason.decode!()
        |> Enum.map(fn map ->
          map = Enum.into(map, %{})

          due_date =
            case map["due_date"] do
              %Date{} = d -> d
              date_str when is_binary(date_str) -> Date.from_iso8601!(date_str)
            end

          {
            map["id"],
            %TaskEntry{
              id: map["id"],
              description: map["description"],
              priority: map["priority"],
              due_date: due_date,
              completed: map["completed"]
            }
          }
        end)
        |> Enum.into(%{})

      _ ->
        %{}
    end
  end
end
