defmodule ParserRpn do
  def parse(tokens) do
    parse_rec(tokens, {:queue.new(), []})
  end

  defp parse_rec([{:op, _} = op | rest], {q, s}) do
    {new_q, new_s} = pop_stack(op, {q, s})

    state = {new_q, [op | new_s]}

    parse_rec(rest, state)
  end

  @func_arity %{
    "max" => 2,
    "sin" => 1
  }
  defp parse_rec([{:word, name}, :lparen = paren | rest], {q, s}) do
    # find function arity, raise if not exists
    # push onto op stack

    state = {q, [paren, {:func, %{name: name, arity: @func_arity[name]}} | s]}

    parse_rec(rest, state)
  end

  defp parse_rec([{:word, name} | rest], {q, s}) do
    state = {:queue.in({:variable, %{name: name}}, q), s}

    parse_rec(rest, state)
  end

  defp parse_rec([{:num, _value} = num | rest], {q, s}) do
    state = {:queue.in(num, q), s}

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

  defp parse_rec([], {q, [hd | tl]}) do
    parse_rec([], {:queue.in(hd, q), tl})
  end

  defp parse_rec([], {q, []}) do
    :queue.to_list(q)
  end

  defp pop_stack(
         {:op, %{precedence: c_p, associativity: a}} = c_op,
         {q, [{:op, %{precedence: top_precedence}} = stack_top | stack_tail]}
       )
       when c_p < top_precedence or (c_p == top_precedence and a == :left) do
    pop_stack(c_op, {:queue.in(stack_top, q), stack_tail})
  end

  defp pop_stack(op, {q, [{:func, _} = stack_top | stack_tail]}) do
    pop_stack(op, {:queue.in(stack_top, q), stack_tail})
  end

  defp pop_stack(_, {q, s}), do: {q, s}

  defp pop_until_paren({q, [:lparen | s]}), do: {q, s}
  defp pop_until_paren({q, [hd | tl]}), do: pop_until_paren({:queue.in(hd, q), tl})
end
