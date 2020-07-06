defmodule EvaluatorRpn do
  def evaluate(tokens, values) do
    tokens
    |> Enum.reduce([], &process_token(&1, &2, values))
    |> case do
      [result] -> {:ok, result}
      _ -> :error
    end
  end

  defp process_token({:op, %{op: operator}}, stack, _) do
    [y, x | rest] = stack
    [eval_op(operator, x, y) | rest]
  end

  defp process_token({:num, num}, stack, _) do
    [num | stack]
  end

  defp process_token({:variable, %{name: name}}, stack, values) do
    [Map.fetch!(values, name) | stack]
  end

  defp process_token({:func, %{name: name, arity: arity}}, stack, _) do
    func = FuncProvider.get(name)
    {args, stack} = Enum.split(stack, arity)

    [apply(func.func, args) | stack]
  end

  defp eval_op("^", x, y), do: :math.pow(x, y)
  defp eval_op("*", x, y), do: x * y
  defp eval_op("/", x, y), do: x / y
  defp eval_op("+", x, y), do: x + y
  defp eval_op("-", x, y), do: x - y
end
