defmodule FuncProvider do
  @funcs %{
    "max" => %{
      func: &max/2,
      arity: 2
    },
    "sin" => %{
      func: &:math.sin/1,
      arity: 1
    },
    "fn" => %{
      func: &IO.inspect/1,
      arity: 1
    }
  }

  def get(name), do: @funcs[name]
end
