defmodule Exprotoc.Inspect do
  import Inspect.Algebra

  def inspect(module, msg, opts) do
    concat [to_doc(module, opts), "[",
            to_doc(msg.message, opts),
    #Enum.reduce(msg.message, empty,
    #            fn({k, v}, acc) ->
    #                inspect_field(module, k, v, acc, opts)
    #            end),
         "]"
           ]
  end

  def inspect_field(module, k, v, acc, opts) do
    name = module.get_fname(k)
    field = concat [
                    to_doc(name, opts),
                    "(",
                    to_doc(k, opts),
                    ")",
                    " ",
                    to_doc(v, opts)
              ]
    if empty == acc do
      field
    else
      glue(field, ", ", acc)
    end
  end
end