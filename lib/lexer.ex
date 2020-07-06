defmodule Lexer do
  @space ~r/^[ \h]+/
  @number ~r/^[0-9]+/
  @word ~r/^[a-z]+[a-z_0-9]*/

  def lex(" " <> expr), do: lex(expr)

  def lex(expr) do
    keywords = keywords()

    cond do
      expr == "" ->
        []

      Regex.match?(@number, expr) ->
        num = String.to_integer(List.first(Regex.run(@number, expr, [{:capture, :first}])))

        [
          {:num, num}
          | lex(Regex.replace(@number, expr, "", global: false))
        ]

      kw = keyword?(expr, keywords) ->
        token = keyword_to_token(kw)

        [token | lex(String.replace_prefix(expr, kw, ""))]

      Regex.match?(@word, expr) ->
        name = List.first(Regex.run(@word, expr, [{:capture, :first}]))
        token = {:word, name}
        [token | lex(Regex.replace(@word, expr, "", global: false))]

      true ->
        raise "could not parse : #{expr}"
    end
  end

  defp keywords do
    ~w[^ * / + - ( ) ,]
  end

  defp keyword_to_token("^"), do: {:op, %{op: "^", precedence: 3, associativity: :right}}
  defp keyword_to_token("*"), do: {:op, %{op: "*", precedence: 2, associativity: :left}}
  defp keyword_to_token("/"), do: {:op, %{op: "/", precedence: 2, associativity: :left}}
  defp keyword_to_token("+"), do: {:op, %{op: "+", precedence: 1, associativity: :left}}
  defp keyword_to_token("-"), do: {:op, %{op: "-", precedence: 1, associativity: :left}}

  defp keyword_to_token("("), do: :lparen
  defp keyword_to_token(")"), do: :rparen
  defp keyword_to_token(","), do: :comma

  defp keyword?(expr, keywords) do
    Enum.find(keywords, false, fn kw ->
      if String.starts_with?(expr, kw), do: kw
    end)
  end
end
