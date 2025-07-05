defmodule TaskCLI do
  alias TaskManager

  @green "\e[32m"
  @red "\e[31m"
  @bg_magenta "\e[45m"
  @magenta "\e[35m"
  # Cyan bold
  @cyan "\e[36;1m"
  @italic "\e[3m"
  @reset "\e[0m"

  def start do
    menu()
  end

  defp menu do
    IO.puts("\n#{@magenta}========================================#{@reset}")

    IO.puts(
      "#{@magenta}||#{@reset}        #{@cyan}¿Qué desea hacer?#{@reset}             #{@magenta}||#{@reset}"
    )

    IO.puts("#{@magenta}========================================#{@reset}")
    IO.puts(" #{@cyan}1#{@reset}. Agregar una tarea")
    IO.puts(" #{@cyan}2#{@reset}. Completar una tarea")
    IO.puts(" #{@cyan}3#{@reset}. Mostrar la lista de tareas")
    IO.puts(" #{@cyan}4#{@reset}. Ordenar lista en orden de prioridad")
    IO.puts(" #{@cyan}5#{@reset}. Ordenar lista por fechas")
    IO.puts(" #{@cyan}6#{@reset}. Salir de la aplicación")
    IO.puts("#{@magenta}---------------------------------------#{@reset}")

    case IO.gets("") |> String.trim() do
      "1" ->
        agregar_tarea()
        menu()

      "2" ->
        completar_tarea()
        menu()

      "3" ->
        mostrar_tareas()
        menu()

      "4" ->
        listar_por_prioridad()
        menu()

      "5" ->
        listar_por_fecha()
        menu()

      "6" ->
        IO.puts("Saliendo de la aplicación...")
        :init.stop()

      _ ->
        IO.puts("Opción inválida")
        menu()
    end
  end

  defp agregar_tarea do
    id = solicitar_id()

    descripcion = IO.gets("Ingrese tarea: ") |> String.trim()
    prioridad = IO.gets("Ingrese prioridad (1-5): ") |> String.trim() |> String.to_integer()
    fecha_str = IO.gets("Ingrese fecha (YYYY-MM-DD): ") |> String.trim()
    {:ok, fecha} = Date.from_iso8601(fecha_str)

    TaskManager.add_task(%{
      id: id,
      description: descripcion,
      priority: prioridad,
      due_date: fecha
    })

    IO.puts("#{@green}Tarea agregada con ID #{id}#{@reset}\n")
  end

  defp solicitar_id do
    id = IO.gets("Ingrese ID de la tarea: ") |> String.trim() |> String.to_integer()
    existente? = TaskManager.list_tasks() |> Enum.any?(&(&1.id == id))

    if existente? do
      IO.puts("#{@red} (×) ID ya existe. Ingrese otro ID.#{@reset}")
      solicitar_id()
    else
      id
    end
  end

  defp completar_tarea do
    id = IO.gets("Ingrese ID de la tarea completada: ") |> String.trim() |> String.to_integer()
    TaskManager.complete_task(id)

    case TaskManager.list_tasks() |> Enum.find(&(&1.id == id)) do
      %{description: desc} -> IO.puts("#{@green}Tarea \"#{desc}\" completada#{@reset}\n")
      _ -> IO.puts("#{@red}Tarea no encontrada#{@reset}\n")
    end
  end

  defp mostrar_tareas do
    IO.puts("\n#{@cyan}=============================== Tareas actuales ========================================#{@reset}")

    TaskManager.list_tasks()
    |> Enum.each(&mostrar_tarea(:normal, &1))

    IO.puts("#{@cyan}========================================================================================#{@reset}")

  end

  defp listar_por_prioridad do
    IO.puts("\n#{@cyan}=============================== Tareas por prioridad ===================================#{@reset}")

    TaskManager.list_by_priority()
    |> Enum.each(&mostrar_tarea(:prioridad, &1))

    IO.puts("#{@cyan}========================================================================================#{@reset}")

  end

  defp listar_por_fecha do
    IO.puts("\n#{@cyan}=============================== Tareas por fecha =======================================#{@reset}")

    TaskManager.list_by_due_date()
    |> Enum.each(&mostrar_tarea(:fecha, &1))

    IO.puts("#{@cyan}========================================================================================#{@reset}")

  end

  defp mostrar_tarea(modo, tarea) do
    estado = if tarea.completed, do: "#{@green}o#{@reset}", else: "#{@red}×#{@reset}"

    id = String.pad_leading(to_string(tarea.id), 4)
    desc = String.pad_trailing(tarea.description, 40)
    pri = to_string(tarea.priority)
    fecha = to_string(tarea.due_date)

    case modo do
      :fecha ->
        IO.puts(
          " #{estado} #{@magenta}|#{@reset} ##{id} #{@magenta}|#{@reset} #{@italic}#{desc}#{@reset} #{@magenta}|#{@reset} Prioridad: #{@cyan}#{pri} #{@magenta}|#{@reset} Fecha: #{@bg_magenta}#{@cyan}#{fecha}#{@reset} "
        )

      :prioridad ->
        IO.puts(
          " #{estado} #{@magenta}|#{@reset} ##{id} #{@magenta}|#{@reset} #{@italic}#{desc}#{@reset} #{@magenta}|#{@reset} Prioridad: #{@bg_magenta}#{@cyan}#{pri}#{@reset} #{@magenta}|#{@reset} Fecha: #{@cyan}#{fecha}#{@reset}"
        )

      :normal ->
        IO.puts(
          " #{estado} #{@magenta}|#{@reset} ##{id} #{@magenta}|#{@reset} #{@italic}#{desc}#{@reset} #{@magenta}|#{@reset} Prioridad: #{@cyan}#{pri}#{@reset} #{@magenta}|#{@reset} Fecha: #{@cyan}#{fecha}#{@reset}"
        )
    end
  end
end
