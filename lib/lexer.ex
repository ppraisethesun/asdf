defmodule Lexer do
  @space ~r/^[ \h]+/
  @number ~r/^[0-9]+/
  @word ~r/^[a-z]+[a-z_0-9]*/

  @op_info %{
    mul: %{precedence: 2, associativity: :left},
    div: %{precedence: 2, associativity: :left},
    add: %{precedence: 1, associativity: :left},
    sub: %{precedence: 1, associativity: :left}
  }

  def lex(expr) do
    keywords = keywords()

    cond do
      expr == "" ->
        []

      Regex.match?(@space, expr) ->
        lex(Regex.replace(@space, expr, "", global: false))

      Regex.match?(@number, expr) ->
        num = String.to_integer(List.first(Regex.run(@number, expr, [{:capture, :first}])))

        [
          {:num, num}
          | lex(Regex.replace(@number, expr, "", global: false))
        ]

      kw = keyword?(expr, keywords) ->
        {kw, str_rep} = kw

        token =
          case kw do
            {:op, op} -> {:op, Map.fetch!(@op_info, op)}
            {a, b} -> {a, b}
            a -> a
          end

        [token | lex(String.replace_leading(expr, str_rep, ""))]

      Regex.match?(@word, expr) ->
        name = List.first(Regex.run(@word, expr, [{:capture, :first}]))
        token = {:word, name}
        [token | lex(Regex.replace(@word, expr, "", global: false))]

      true ->
        raise "could not parse : #{expr}"
    end
  end

  defp keywords do
    Enum.into(
      [
        {:op, :add},
        {:op, :mul},
        {:op, :sub},
        {:op, :div},
        :lparen,
        :rparen,
        :comma
      ],
      %{},
      &{&1, show_token(&1)}
    )
  end

  defp keyword?(expr, keywords) do
    Enum.find(keywords, false, fn {token, str_rep} ->
      if String.starts_with?(expr, str_rep) do
        {token, str_rep}
      end
    end)
  end

  def show_token(token) do
    case token do
      {:op, _} -> show_op(token)
      {:num, a} -> to_string(a)
      {:word, name} -> name
      :lparen -> "("
      :rparen -> ")"
      :comma -> ","
    end
  end

  defp show_op({:op, operator}) do
    case operator do
      :sub -> "-"
      :add -> "+"
      :div -> "/"
      :mul -> "*"
      :mod -> "%"
    end
  end
end
