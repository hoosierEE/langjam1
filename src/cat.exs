# To run from the command line, you would compile and then execute with something like:
# elixir cat.exs file1.txt file2.txt
# Or, for stdin: elixir cat.exs

defmodule Cat do
  def main(args) do
    if args == [] do
      # Read from standard input and write to standard output
      IO.stream(:stdio, :line)
      |> Enum.each(&IO.write/1)
    else
      # For each file, read and print its contents
      Enum.each(args, fn file ->
        if File.exists?(file) do
          File.stream!(file)
          |> Stream.each(&IO.write/1)
          |> Stream.run()
        else
          IO.puts("Error: #{file} not found")
        end
      )
    end
  end
end

System.argv() |> Cat.main()
