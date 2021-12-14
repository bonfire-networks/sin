defmodule Sin do
  @moduledoc """
  A convenient isomorphic alternative to elixir's AST. Describes
  elixir syntax as structs.
  """
  import Sin.Guards

  @binops [
    :and, :or, :in, :when, :+, :-, :/, :*, :++, :--, :.,
    :~~~, :<>, :.., :^^^, :<|>, :<~>, :<~, :~>, :~>>, :<<~,
    :>>>, :<<<, :|>, :>=, :<=, :>, :<, :!==, :===, :=~,
    :!=, :==, :&&&, :&&, :|||, :||, :=, :|, :"::", :\\, :<-
  ]
  @unops [:not, :^, :!, :+, :-, :&]
  @postops [:.]

  @doc "Turns the awkward elixir AST into slightly less awkward sin structs"
  def read(x) do
    case x do
      l when is_list(l) ->
        Enum.map(l, &read/1)
      {:__aliases__, meta, args} when is_list(args) ->
        struct(Sin.Alias, meta: meta, args: args)
      {:->, meta, [lhs, rhs]} ->
        struct(Sin.Arrow, meta: meta, lhs: lhs, rhs: rhs)
      b when is_basic(b) ->
        struct(Sin.Basic, value: b)
      {:__block__, meta, clauses} when is_list(clauses) ->
        struct(Sin.Block, meta: meta, clauses: read(clauses))
      {:fn, meta, clauses} when is_list(clauses) ->
        struct(Sin.Fn, meta: meta, clauses: clauses)
      {:%{}, meta, args} when is_list(args) ->
        struct(Sin.Map, meta: meta, args: read(args))
      {:@, meta, args} when is_list(args) ->
        struct(Sin.Meta, meta: meta, args: read(args))
      {op, meta, [lhs, rhs]} when op in @binops ->
        struct(Sin.Op, name: op, meta: meta, lhs: read(lhs), rhs: read(rhs))
      {op, meta, [rhs]} when op in @unops ->
        struct(Sin.Op, name: op, meta: meta, lhs: nil, rhs: read(rhs))
      {op, meta, [lhs]} when op in @postops ->
        struct(Sin.Op, name: op, meta: meta, lhs: read(lhs), rhs: nil)
      {:%, meta, args} when is_list(args) ->
        struct(Sin.Struct, name: read(car(args)), meta: meta, args: read(cdr(args)))
      {x,y} ->
        struct(Sin.Tuple, args: read([x, y]))
      {:{}, meta, args} when is_list(args) ->
        struct(Sin.Tuple, meta: meta, args: read(args))
      {name, meta, context} when is_atom(name) and is_atom(context) ->
        struct(Sin.Var, name: name, meta: meta, context: context)
      # call is a special snowflake and must be handled last
      {name, meta, args} when is_list(args) ->
        struct(Sin.Call, name: read(name), meta: meta, args: read(args))
    end
  end

  @doc "Turns sin structs back into elixir ast"
  def write(x) do
    case x do
      l when is_list(l) -> Enum.map(l, &write/1)
      %Sin.Alias{meta: m, args: a} -> {:__aliases__, m, a}
      %Sin.Arrow{meta: m, lhs: l, rhs: r} -> {:->, m, write([l, r])}
      %Sin.Basic{value: v} -> v
      %Sin.Block{meta: m, clauses: c} -> {:__block__, m, write(c)}
      %Sin.Call{name: n, meta: m, args: a} -> {write(n), m, write(a)}
      %Sin.Fn{clauses: c, meta: m} -> {:fn, m, write(c)}
      %Sin.Map{args: a, meta: m} -> {:%{}, m, write(a)}
      %Sin.Meta{args: a, meta: m} -> {:@, m, write(a)}
      %Sin.Op{name: n, meta: m, lhs: nil, rhs: r} when n in @unops -> {n, m, [write(r)]}
      %Sin.Op{name: n, meta: m, lhs: l, rhs: r} when n in @binops -> {n, m, write([l, r])}
      %Sin.Op{name: n, meta: m, rhs: r} when n in @postops -> {n, m, [write(r)]}
      %Sin.Struct{name: n, meta: m, args: a} -> {:%, m, write([n | a])}
      %Sin.Tuple{args: [a,b]}-> {write(a), write(b)}
      %Sin.Tuple{args: a, meta: m} -> {:{}, m, write(a)}
      %Sin.Var{name: n, meta: m, context: c} -> {n, m, c}
      # allow sloppy usage
      b -> b
    end
  end

  @doc """
  If the provided item is an alias, return an expanded
  version. Otherwise, returns the input unchanged.

  If provided an elixir ast, returns elixir ast. If provided a
  Sin.Alias, returns a Sin.Basic.
  """
  def expand_alias({:__aliases__, _, _} = ast, env), do: Macro.expand(ast, env)
  def expand_alias(%Sin.Alias{} = a, env),
    do: struct(Sin.Basic, value: expand_alias(write(a), env))
  def expand_alias(other, _), do: other

  @doc "Like quote, but returns Sin structs instead of elixir ast."
  defmacro quot([do: x]), do: quot_impl(x, __CALLER__)

  defp quot_impl(x, env) do
    code = {:quote, [], [[do: x]]}
    env = Macro.escape(env)
    quote, do: Sin.unquot(Sin.read(unquote(code)), unquote(env))
  end  

  @doc "Like unquote, but for use in `quot/1`"
  def unquot(x, env) do
    case x do
      %Sin.Arrow{}  -> %{ x | lhs: unquot(x.lhs, env), rhs: unquot(x.rhs, env) }
      %Sin.Block{}  -> %{ x | clauses: unquot(x.clauses, env) }
      %Sin.Fn{}     -> %{ x | clauses: unquot(x.clauses, env) }
      %Sin.Map{}    -> %{ x | args: unquot(x.args, env) }
      %Sin.Meta{}   -> %{ x | args: unquot(x.args, env) }
      %Sin.Op{}     -> %{ x | lhs: unquot(x.lhs, env), rhs: unquot(x.rhs, env) }
      %Sin.Struct{} -> %{ x | args: unquot(x.args, env) }
      %Sin.Tuple{}  -> %{ x | args: unquot(x.args, env) }
      %Sin.Call{}   -> unquot_call(x.name, x, env)
      l when is_list(l) -> Enum.map(l, &unquot(&1, env))
      _ -> x
    end
  end

  defp unquot_call(%Sin.Basic{value: :unquot}, call, env),
    do: Sin.read(elem(Code.eval_quoted(write(call.args), env), 0))
  defp unquot_call(_, call, env), do: %{ call | args: unquot(call.args, env) }

end

