defmodule Sin.Guards do
  @moduledoc """
  These guards are used internally by syn to dispatch over elixir
  ast, but you are also welcome to use them.
  """
  
  defguard car(x) when hd(x)
  defguard cdr(x) when tl(x)
  defguard cadr(x) when car(cdr(x))
  defguard caddr(x) when car(cdr(cdr(x)))

  defguard call_fun(x) when elem(x, 0)

  defguard call_meta(x) when elem(x, 1)

  defguard call_args(x) when elem(x, 2)

  defguard call_arg1(x) when car(call_args(x))
  defguard call_arg2(x) when cadr(call_args(x))
  defguard call_arg3(x) when caddr(call_args(x))

  defguard is_three_tuple(x)
  when is_tuple(x) and tuple_size(x) == 3

  defguard is_call(x)
  when is_three_tuple(x)
  and is_atom(call_fun(x))
  and is_list(call_args(x))

  defguard is_call_to(f, x)
  when is_call(x) and call_fun(x) == f
    
  defguard is_var(x)
  when is_three_tuple(x)
  and is_atom(call_fun(x))
  and call_meta(x) == []
  and is_atom(call_args(x))

  defguard is_var(name, x)
  when is_var(x) and call_fun(x) == name

  defguard is_alias(x) when is_call_to(:__aliases__, x)

  defguard is_when(x) when is_call_to(:when, x)

  defguard is_map_ctor(x) when is_call_to(:%{}, x)

  defguard is_struct_ctor(x) when is_call_to(:%, x)

  defguard is_module_metadata(x) when is_call_to(:@, x)

  defguard is_tuple_ctor_call(x) when is_call_to(:{}, x)
  defguard is_simple_tuple(x) when is_tuple(x) and tuple_size(x) != 3
  defguard is_tuple_ctor(x) when is_simple_tuple(x) or is_tuple_ctor_call(x)

  defguard is_basic(x) when is_number(x) or is_binary(x) or is_atom(x)
  defguard is_structured(x) when is_list(x) or is_map(x) or is_tuple_ctor(x)

  defguard are_vars(x, y) when is_var(x) and is_var(y)
  defguard are_vars(x, y, z) when is_var(x) and is_var(y) and is_var(z)

end
