defmodule TaskApp do

  @green "\e[32m"
  @cyan "\e[36m"
  @reset "\e[0m"

  use Application

  def start(_type, _args) do
    TaskManager.start_link([])
    IO.puts("#{@cyan}=================================================================#{@reset}")
    IO.puts(" El sistema fue iniciado. Ejecuta #{@green}TaskCLI.start()#{@reset} para comenzar.")
    IO.puts("#{@cyan}=================================================================#{@reset}")
    {:ok, self()}
  end
end
