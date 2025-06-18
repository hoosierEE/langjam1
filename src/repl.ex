
defmodule Parser do
  def e1, do: "[]" |> parse
  def e2, do: "[1 2 3]" |> parse
  def e3, do: "1 [2 3]" |> parse
  def tokenize(line), do: Regex.scan(~r/-?\d+|[\[\]\{\}\(\)\+\-\*]|\w+/, line) |> List.flatten()
  def parse(str) when is_binary(str), do: str |> tokenize |> parse
  def parse(tokens), do: do_parse(tokens, Stack.new())
  defp do_parse([], stack), do: {:expr, Enum.reverse(stack)}
  defp do_parse(["[" | rest], stack) do
    {nested_items, rest2} = extract_list(rest, [])
    {:lst, items} = parse_list(nested_items)
    stack = Stack.push(stack, {:lst, items})
    do_parse(rest2, stack)
  end
  defp do_parse([token | rest], stack), do: do_parse(rest, Stack.push(stack, token))

  # [tokens] => {:lst, [tokens]}
  defp extract_list([], _), do: raise "Unmatched ["
  defp extract_list(["[" | rest], acc) do
    {nested, rest2} = extract_list(rest, [])
    extract_list(rest2, [[:open | nested] | acc])
  end
  defp extract_list(["]" | rest], acc), do: {Enum.reverse(acc), rest}
  defp extract_list([token | rest], acc), do: extract_list(rest, [token | acc])

  # flatten [:open | nested] markers into nested lists
  defp parse_list(tokens) do
    {:lst, Enum.map(tokens, fn
        [:open | nested_tokens] -> parse_list(nested_tokens)
        token -> token
      end)}
  end
end


defmodule AstEvaluator do
  def eval({:expr, nodes}), do: eval_nodes(nodes, [])
  defp eval_nodes([], [result]), do: result
  defp eval_nodes([], stack), do: raise "Unexpected stack at end: #{inspect(stack, charlists: :as_lists)}"
  defp eval_nodes([node | rest], stack) do
    case node do
      {:lst, items} ->
        value = eval({:expr, items})
        eval_nodes(rest, [value | stack])

      op when op in ["+", "-", "*", "/"] ->
        [b, a | stack_rest] = stack
        result = apply_op(op, a, b)
        eval_nodes(rest, [result | stack_rest])

      value ->
        val = parse_value(value)
        eval_nodes(rest, [val | stack])
    end
  end

  defp apply_op(op, a, b) do
    fun = operator_fun(op)
    cond do
      is_list(a) and is_list(b) ->
        Enum.zip_with(a, b, fun)
      is_list(a) ->
        Enum.map(a, &fun.(&1, b))
      is_list(b) ->
        Enum.map(b, &fun.(a, &1))
      true ->
        fun.(a, b)
    end
  end

  defp operator_fun("+"), do: &+/2
  defp operator_fun("-"), do: &-/2
  defp operator_fun("*"), do: &*/2
  defp operator_fun("/"), do: &div/2

  defp parse_value(val) when is_integer(val), do: val
  defp parse_value(val) when is_list(val), do: Enum.map(val, &parse_value/1)
  defp parse_value(val) when is_binary(val) do
    case Integer.parse(val) do
      {int, ""} -> int
      _ -> val
    end
  end
end

defmodule Stack do
  def new, do: []
  def push(stack, value), do: [value | stack]
end
