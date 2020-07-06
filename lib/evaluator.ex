defmodule Evaluator do
  def evaluate(ast, values) do
    eval_ast(ast, values)
  end

  defp eval_ast({:op, %{op: "^"}, [a, b]}, var_values) do
    :math.pow(eval_ast(a, var_values), eval_ast(b, var_values))
  end

  defp eval_ast({:op, %{op: "*"}, [a, b]}, var_values) do
    eval_ast(a, var_values) * eval_ast(b, var_values)
  end

  defp eval_ast({:op, %{op: "/"}, [a, b]}, var_values) do
    eval_ast(a, var_values) / eval_ast(b, var_values)
  end

  defp eval_ast({:op, %{op: "+"}, [a, b]}, var_values) do
    eval_ast(a, var_values) + eval_ast(b, var_values)
  end

  defp eval_ast({:op, %{op: "-"}, [a, b]}, var_values) do
    eval_ast(a, var_values) - eval_ast(b, var_values)
  end

  defp eval_ast({:func, %{name: name, arity: arity}, args}, var_values) do
    if length(args) != arity, do: raise("invalid number of arguments to function #{name}")

    func = FuncProvider.get(name)
    args = Enum.map(args, &eval_ast(&1, var_values))
    apply(func.func, args)
  end

  defp eval_ast({:variable, %{name: name}}, var_values) do
    Map.fetch!(var_values, name)
  end

  defp eval_ast({:num, number}, _), do: number
end
