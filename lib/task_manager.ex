defmodule TaskManager do
  # Utiliza GenServer para manejar el estado y la concurrencia
  use GenServer
  # Alias para referirse a TaskEntry
  alias TaskEntry

  # Archivo donde se guardarán las tareas
  @save_file "tasks.json"

  ## API pública

  def start_link(_) do
    # Inicia el GenServer
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def add_task(attrs) do
    # Llama a la función para agregar una tarea
    GenServer.call(__MODULE__, {:add_task, attrs})
  end

  def complete_task(id) do
    # Llama a la función para completar una tarea
    GenServer.call(__MODULE__, {:complete_task, id})
  end

  def list_tasks do
    # Llama a la función para listar todas las tareas
    GenServer.call(__MODULE__, :list_tasks)
  end

  def list_by_priority do
    # Llama a la función para listar tareas por prioridad
    GenServer.call(__MODULE__, :list_by_priority)
  end

  def list_by_due_date do
    # Llama a la función para listar tareas por fecha de vencimiento
    GenServer.call(__MODULE__, :list_by_due_date)
  end

  ## Callbacks

  def init(_) do
    # Carga las tareas desde el archivo
    state = load_tasks()
    # Programa un recordatorio
    schedule_reminder()
    # Devuelve el estado inicial
    {:ok, state}
  end

  def handle_call({:add_task, attrs}, _from, state) do
    # Obtiene el ID de la tarea
    id = attrs.id

    # Crea una nueva tarea
    task = %TaskEntry{
      id: id,
      description: attrs.description,
      priority: attrs.priority,
      due_date: attrs.due_date,
      completed: false
    }

    # Agrega la tarea al estado
    new_state = Map.put(state, id, task)
    # Guarda las tareas en el archivo
    save_tasks(new_state)
    # Responde con la tarea agregada
    {:reply, {:ok, task}, new_state}
  end

  def handle_call({:complete_task, id}, _from, state) do
    # Marca la tarea como completada
    new_state = Map.update!(state, id, fn t -> %{t | completed: true} end)
    # Guarda el nuevo estado
    save_tasks(new_state)
    # Responde con éxito
    {:reply, :ok, new_state}
  end

  def handle_call(:list_tasks, _from, state) do
    # Devuelve todas las tareas
    {:reply, Map.values(state), state}
  end

  def handle_call(:list_by_priority, _from, state) do
    sorted =
      state
      |> Map.values()
      # Ordena las tareas por prioridad
      |> Enum.sort_by(& &1.priority)

    # Devuelve las tareas ordenadas
    {:reply, sorted, state}
  end

  def handle_call(:list_by_due_date, _from, state) do
    sorted =
      state
      |> Map.values()
      # Ordena las tareas por fecha de vencimiento
      |> Enum.sort_by(& &1.due_date, Date)

    # Devuelve las tareas ordenadas
    {:reply, sorted, state}
  end

  def handle_info(:recordatorio, state) do
    # Obtiene la fecha actual
    hoy = Date.utc_today()
    # Calcula la fecha de 1 día hacia adelante
    un_dia_hacia_adelante = Date.add(hoy, 1)

    urgentes =
      state
      |> Map.values()
      |> Enum.filter(fn t ->
        # Filtra tareas de alta prioridad o que vencen en 1 día
        !t.completed and
          (t.priority == 1 || Date.compare(t.due_date, un_dia_hacia_adelante) == :eq)
      end)
      # Ordena las tareas urgentes por fecha
      |> Enum.sort_by(& &1.due_date)

    if urgentes != [] do
      # Muestra todas las tareas urgentes
      Enum.each(urgentes, fn tarea ->
        priority_str =
          case tarea.priority do
            1 -> "ALTA PRIORIDAD"
            2 -> "media prioridad"
            3 -> "baja prioridad"
            _ -> ""
          end

        IO.puts(
          "\e[31m\n ! Recordatorio: Tarea #{priority_str} '#{tarea.description}' vence el #{tarea.due_date}\e[0m"
        )
      end)
    end

    # Programa el siguiente recordatorio
    schedule_reminder()
    # No responde a la llamada
    {:noreply, state}
  end

  ## Auxiliares

  defp schedule_reminder do
    # Programa un recordatorio cada 20 segundos
    Process.send_after(self(), :recordatorio, 20_000)
  end

  defp save_tasks(tasks) do
    json =
      tasks
      |> Map.values()
      |> Enum.map(fn t ->
        # Convierte la fecha a formato ISO
        Map.update!(Map.from_struct(t), :due_date, &Date.to_iso8601/1)
      end)
      # Codifica las tareas a JSON
      |> Jason.encode!()

    # Guarda el JSON en el archivo
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
              # Convierte la fecha de cadena a Date
              date_str when is_binary(date_str) -> Date.from_iso8601!(date_str)
            end

          {
            map["id"],
            # Crea una nueva tarea a partir del mapa
            %TaskEntry{
              id: map["id"],
              description: map["description"],
              priority: map["priority"],
              due_date: due_date,
              completed: map["completed"]
            }
          }
        end)
        # Convierte la lista de tareas en un mapa
        |> Enum.into(%{})

      _ ->
        # Devuelve un mapa vacío si no se puede leer el archivo
        %{}
    end
  end
end
