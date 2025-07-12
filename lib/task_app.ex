defmodule TaskApp do
  @green "\e[32m"
  @cyan "\e[36m"
  @reset "\e[0m"
  @red "\e[91m"
  @blue "\e[94m"
  @yellow "\e[93m"
  @magenta "\e[95m"

  use Application

  def start(_type, _args) do
    TaskManager.start_link([])
    print_header()
    {:ok, self()}
  end

  defp print_header do
    IO.puts("#{@cyan}=================================================================#{@reset}")
    IO.puts(center_colored("Proyecto Final de Lenguajes de Programación", @reset))
    IO.puts(center_colored("- Realizado por -", @reset))
    IO.puts(center_colored("BRIONES SUAREZ JOSE DANIEL", @blue))
    IO.puts(center_colored("GONZALEZ ALCIVAR SAREN CRISTINA", @yellow))
    IO.puts(center_colored("GONZALEZ MACIAS DANNY JAMPIER", @red))
    IO.puts(center_colored("PIGUAVE PIGUAVE DIEGO ALEXANDER", @green))
    IO.puts(center_colored("PINCAY DELGADO HEIDY MADELAYNE", @magenta))
    IO.puts("#{@cyan}=================================================================#{@reset}")
    IO.puts("El sistema fue iniciado. Ejecuta #{@green}TaskCLI.start()#{@reset} para comenzar.")
    IO.puts("#{@cyan}=================================================================#{@reset}")
  end

  defp center_colored(text, color) do
    width = 70
    stripped = strip_ansi(text)
    padding = div(width - String.length(stripped), 2)
    String.duplicate(" ", padding) <> color <> text <> @reset
  end

  defp strip_ansi(text) do
    Regex.replace(~r/\e\[\d{1,3}m/, text, "")
  end
end
