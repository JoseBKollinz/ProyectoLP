defmodule TaskCLI do
  # Alias para referirse a TaskManager
  alias TaskManager

  # Color verde para mensajes de éxito
  @green "\e[32m"
  # Color rojo para mensajes de error
  @red "\e[31m"
  # Fondo magenta
  @bg_magenta "\e[45m"
  # Color magenta
  @magenta "\e[35m"
  # Color cian
  @cyan "\e[36;1m"
  # Estilo cursiva
  @italic "\e[3m"
  # Restablece el color
  @reset "\e[0m"

  def start do
    # Inicia el menú
    menu()
  end

  defp menu do
    IO.puts("\n#{@magenta}========================================#{@reset}")

    IO.puts(
      "#{@magenta}||#{@reset}        #{@cyan}¿Qué desea hacer?#{@reset}           #{@magenta}||#{@reset}"
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
        # Llama a la función para agregar una tarea
        agregar_tarea()
        # Vuelve al menú
        menu()

      "2" ->
        # Llama a la función para completar una tarea
        completar_tarea()
        # Vuelve al menú
        menu()

      "3" ->
        # Llama a la función para mostrar todas las tareas
        mostrar_tareas()
        # Vuelve al menú
        menu()

      "4" ->
        # Llama a la función para listar tareas por prioridad
        listar_por_prioridad()
        # Vuelve al menú
        menu()

      "5" ->
        # Llama a la función para listar tareas por fecha
        listar_por_fecha()
        # Vuelve al menú
        menu()

      "6" ->
        # Mensaje de salida
        IO.puts("Saliendo de la aplicación...")
        # Detiene la aplicación
        :init.stop()

      _ ->
        # Mensaje de opción inválida
        IO.puts("Opción inválida")
        # Vuelve al menú
        menu()
    end
  end

  defp agregar_tarea do
    id = solicitar_id()

    descripcion = IO.gets("Ingrese tarea: ") |> String.trim()

    # Get numeric priority
    prioridad = IO.gets("Ingrese prioridad (1:alto, 2:medio, 3:bajo): ") |> String.trim()

    priority_num =
      case prioridad do
        "1" -> 1
        "2" -> 2
        "3" -> 3
        # Default to low priority
        _ -> 3
      end

    fecha_str = IO.gets("Ingrese fecha (YYYY-MM-DD): ") |> String.trim()
    {:ok, fecha} = Date.from_iso8601(fecha_str)

    TaskManager.add_task(%{
      id: id,
      description: descripcion,
      priority: priority_num,
      due_date: fecha
    })

    IO.puts("#{@green}Tarea agregada con ID #{id}#{@reset}\n")
  end

  defp solicitar_id do
    # Solicita el ID
    id = IO.gets("Ingrese ID de la tarea: ") |> String.trim() |> String.to_integer()
    # Verifica si el ID ya existe
    existente? = TaskManager.list_tasks() |> Enum.any?(&(&1.id == id))

    if existente? do
      # Mensaje de error
      IO.puts("#{@red} (×) ID ya existe. Ingrese otro ID.#{@reset}")
      # Vuelve a solicitar el ID
      solicitar_id()
    else
      # Devuelve el ID
      id
    end
  end

  defp priority_to_string(priority_num) do
    case priority_num do
      1 -> "alto"
      2 -> "medio"
      3 -> "bajo"
      _ -> "bajo"
    end
  end

  defp completar_tarea do
    # Solicita el ID de la tarea completada
    id = IO.gets("Ingrese ID de la tarea completada: ") |> String.trim() |> String.to_integer()
    # Completa la tarea
    TaskManager.complete_task(id)

    case TaskManager.list_tasks() |> Enum.find(&(&1.id == id)) do
      # Mensaje de éxito
      %{description: desc} -> IO.puts("#{@green}Tarea \"#{desc}\" completada#{@reset}\n")
      # Mensaje de error
      _ -> IO.puts("#{@red}Tarea no encontrada#{@reset}\n")
    end
  end

  defp mostrar_tareas do
    IO.puts(
      "\n#{@cyan}=============================== Tareas actuales ===============================================#{@reset}"
    )

    # Lista todas las tareas
    TaskManager.list_tasks()
    # Muestra cada tarea
    |> Enum.each(&mostrar_tarea(:normal, &1))

    IO.puts(
      "#{@cyan}===============================================================================================#{@reset}"
    )
  end

  defp listar_por_prioridad do
    IO.puts(
      "\n#{@cyan}=============================== Tareas por prioridad ==========================================#{@reset}"
    )

    # Lista tareas por prioridad
    TaskManager.list_by_priority()
    # Muestra cada tarea
    |> Enum.each(&mostrar_tarea(:prioridad, &1))

    IO.puts(
      "#{@cyan}===============================================================================================#{@reset}"
    )
  end

  defp listar_por_fecha do
    IO.puts(
      "\n#{@cyan}=============================== Tareas por fecha ==============================================#{@reset}"
    )

    # Lista tareas por fecha
    TaskManager.list_by_due_date()
    # Muestra cada tarea
    |> Enum.each(&mostrar_tarea(:fecha, &1))

    IO.puts(
      "#{@cyan}===============================================================================================#{@reset}"
    )
  end

  defp mostrar_tarea(modo, tarea) do
    estado = if tarea.completed, do: "#{@green}o#{@reset}", else: "#{@red}×#{@reset}"
    # Formatea el ID
    id = String.pad_leading(to_string(tarea.id), 4)
    # Formatea la descripción
    desc = String.pad_trailing(tarea.description, 40)
    # Convierte la prioridad a string
    priority_str = priority_to_string(tarea.priority)
    fecha = to_string(tarea.due_date)

    # Asegúrate de que la longitud de "Prioridad" y "Fecha" sea consistente
    # Ajusta el ancho
    priority_display = String.pad_trailing("Prioridad: #{@cyan}#{priority_str}#{@reset}", 30)
    # Ajusta el ancho
    fecha_display = String.pad_trailing("Fecha: #{@cyan}#{fecha}#{@reset}", 20)

    # {@bg_magenta}#{@cyan}

    case modo do
      :fecha ->
        IO.puts(
          " #{estado} #{@magenta}|#{@reset} ##{id} #{@magenta}|#{@reset} #{@italic}#{desc}#{@reset} #{@magenta}|#{@reset} #{priority_display} #{@magenta}|#{@reset} #{@bg_magenta}#{@cyan}#{fecha_display} #{@reset}"
        )

      :prioridad ->
        IO.puts(
          " #{estado} #{@magenta}|#{@reset} ##{id} #{@magenta}|#{@reset} #{@italic}#{desc}#{@reset} #{@magenta}|#{@reset} #{@bg_magenta}#{@cyan}#{priority_display}#{@reset} #{@magenta}|#{@reset} #{fecha_display}"
        )

      :normal ->
        IO.puts(
          " #{estado} #{@magenta}|#{@reset} ##{id} #{@magenta}|#{@reset} #{@italic}#{desc}#{@reset} #{@magenta}|#{@reset} #{priority_display} #{@magenta}|#{@reset} #{fecha_display}"
        )
    end
  end
end
