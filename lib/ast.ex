defmodule Sin.Alias do
  @enforce_keys [:args]
  defstruct [meta: []] ++ @enforce_keys
end
defmodule Sin.Arrow do
  @enforce_keys [:lhs, :rhs]
  defstruct [meta: []] ++ @enforce_keys
end
defmodule Sin.Basic do
  @enforce_keys [:value]
  defstruct @enforce_keys
end
defmodule Sin.Block do
  @enforce_keys [:clauses]
  defstruct [meta: []] ++ @enforce_keys
end
defmodule Sin.Call do
  @enforce_keys [:name, :args]
  defstruct [meta: []] ++ @enforce_keys
end
defmodule Sin.Fn do
  @enforce_keys [:args, :clauses]
  defstruct [meta: []] ++ @enforce_keys
end
defmodule Sin.Map do
  @enforce_keys [:args]
  defstruct [meta: []] ++ @enforce_keys
end
defmodule Sin.Meta do
  @enforce_keys [:args]
  defstruct [meta: []] ++ @enforce_keys
end
defmodule Sin.Op do
  @enforce_keys [:name, :lhs, :rhs]
  defstruct [meta: []] ++ @enforce_keys
end
defmodule Sin.Struct do
  @enforce_keys [:name, :args]
  defstruct [meta: []] ++ @enforce_keys
end
defmodule Sin.Tuple do
  @enforce_keys [:args]
  defstruct [meta: []] ++ @enforce_keys
end
defmodule Sin.Var do
  @enforce_keys [:name, :context]
  defstruct [meta: []] ++ @enforce_keys
end
