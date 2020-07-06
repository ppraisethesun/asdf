defmodule Parser do
  def parse(tokens) do
    # {expr_stack, op_stack}
    parse_rec(tokens, {[], []})
  end

  defp parse_rec([{:op, _} = op | rest], {q, s}) do
    {new_q, new_s} = pop_stack(op, {q, s})

    state = {new_q, [op | new_s]}

    parse_rec(rest, state)
  end

  defp parse_rec([{:word, name}, :lparen = paren | rest], {q, s}) do
    # find function arity, raise if not exists
    # push onto op stack

    func = FuncProvider.get(name)
    state = {q, [paren, {:func, %{name: name, arity: func.arity}} | s]}

    parse_rec(rest, state)
  end

  defp parse_rec([{:word, name} | rest], {q, s}) do
    state = {[{:variable, %{name: name}} | q], s}

    parse_rec(rest, state)
  end

  defp parse_rec([{:num, _value} = num | rest], {q, s}) do
    state = {[num | q], s}

    parse_rec(rest, state)
  end

  defp parse_rec([:lparen = paren | rest], {q, s}) do
    # push to op stack
    state = {q, [paren | s]}

    parse_rec(rest, state)
  end

  defp parse_rec([:rparen | rest], {q, s}) do
    # pop everything until next lparen
    state = pop_until_paren({q, s})

    parse_rec(rest, state)
  end

  defp parse_rec([:comma | rest], state) do
    # ignore?
    parse_rec(rest, state)
  end

  defp parse_rec([], {q, [{:op, _} = stack_top | stack_tail]}) do
    [y, x | rest_q] = q
    parse_rec([], {[Tuple.append(stack_top, [x, y]) | rest_q], stack_tail})
  end

  defp parse_rec([], {q, [{:func, %{arity: arity}} = stack_top | stack_tail]}) do
    {args, rest_q} = Enum.split(q, arity)
    parse_rec([], {[Tuple.append(stack_top, Enum.reverse(args)) | rest_q], stack_tail})
  end

  defp parse_rec([], {[tree], []}) do
    tree
  end

  defp pop_stack(
         {:op, %{precedence: c_p, associativity: a}} = c_op,
         {q, [{:op, %{precedence: top_precedence}} = stack_top | stack_tail]}
       )
       when c_p < top_precedence or (c_p == top_precedence and a == :left) do
    [y, x | rest_q] = q

    pop_stack(c_op, {[Tuple.append(stack_top, [x, y]) | rest_q], stack_tail})
  end

  defp pop_stack(op, {q, [{:func, %{arity: arity}} = stack_top | stack_tail]}) do
    {args, rest_q} = Enum.split(q, arity)
    pop_stack(op, {[Tuple.append(stack_top, Enum.reverse(args)) | rest_q], stack_tail})
  end

  defp pop_stack(_, {q, s}), do: {q, s}

  defp pop_until_paren({q, [:lparen | s]}), do: {q, s}

  defp pop_until_paren({q, [{:op, _} = stack_top | stack_tail]}) do
    [y, x | rest_q] = q

    pop_until_paren({[Tuple.append(stack_top, [x, y]) | rest_q], stack_tail})
  end

  defp pop_until_paren({q, [{:func, %{arity: arity}} = stack_top | stack_tail]}) do
    {args, rest_q} = Enum.split(q, arity)
    {[Tuple.append(stack_top, Enum.reverse(args)) | rest_q], stack_tail}
  end
end
