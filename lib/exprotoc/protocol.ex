defmodule Exprotoc.Protocol do
  use Bitwise

  @type wire_type :: 0 | 1 | 2 | 5
  @type value :: integer | float | binary

  @spec decode_payload(binary | list, atom) :: Message.t
  def decode_payload(message, module) when is_list(message) do
    decode_payload iolist_to_binary(message), module
  end
  def decode_payload(payload, module) do
    { message, keys } = decode_payload payload, module, HashDict.new, []
    List.foldl keys, message,
         fn(k, m) ->
             { :repeated, vs } = m[k]
             HashDict.put m, k, { :repeated, Enum.reverse(vs) }
         end
  end

  defp decode_payload("", _, acc, keys), do: { acc, keys }
  defp decode_payload(message, module, acc, keys) do
    { varint, message } = pop_varint message
    field_num = varint >>> 3
    wire_type = varint - (field_num <<< 3)
    { value, message } = pop_value(wire_type, message)
    field_type = module.get_ftype field_num
    data_type = module.get_type field_num
    value = cast value, data_type
    if field_type == :repeated do
      if HashDict.has_key? acc, field_num do
        { :repeated, current } =  acc[field_num]
        acc = HashDict.put acc, field_num , { :repeated, [ value | current ] }
      else
        acc = HashDict.put acc, field_num, { :repeated, [value] }
        keys = [ field_num | keys ]
      end
    else
      acc = HashDict.put acc, field_num, value
    end
    decode_payload message, module, acc, keys
  end

  def encode_message(message) do
    message = message |> List.keysort(1) |> Enum.reverse
    encode_message message, []
  end

  defp encode_message([], acc), do: acc
  defp encode_message([ { field_num, { type, { :repeated, values } } } | rest ],
                      acc) do
    payload = Enum.map values, &encode_value(field_num, type, &1)
    encode_message rest, [ payload | acc ]
  end
  defp encode_message([ { field_num, { type, value } } | rest ],
                      acc) do
    payload = encode_value field_num, type, value
    encode_message rest, [ payload | acc ]
  end

  @spec pop_value(wire_type, binary) :: { value, binary }
  defp pop_value(0, message), do: pop_varint(message)
  defp pop_value(1, message), do: pop_64bits(message)
  defp pop_value(2, message), do: pop_string(message)
  defp pop_value(5, message), do: pop_32bits(message)

  defp pop_varint(message) do
    pop_varint(message, 0, 0)
  end
  defp pop_varint(<< 1 :: 1, data :: 7, rest :: binary >>,
                  acc, pad) do
    pop_varint rest, (data <<< pad) + acc, pad + 7
  end
  defp pop_varint(<< 0 :: 1, data:: 7, rest :: binary >>,
                  acc, pad) do
    { (data <<< pad) + acc, rest }
  end

  defp pop_64bits(<< value :: [64, unit(1), binary], rest :: binary >>), do: { value, rest }

  defp pop_32bits(<< value :: [32, unit(1), binary], rest :: binary >>), do: { value, rest }

  defp pop_string(message) do
    { len, message } = pop_varint message
    << string :: [ size(len), binary ], message :: binary >> = message
    { string, message }
  end

  defp encode_value(_, _, :undefined), do: []
  defp encode_value(field_num, { :enum, enum }, value) do
    varint = enum.to_i value
    [ encode_varint(field_num <<< 3), encode_varint(varint) ]
  end
  defp encode_value(field_num, { :message, module }, message) do
    payload = module.encode message
    size = iolist_size payload
    [ encode_varint((field_num <<< 3) ||| 2), encode_varint(size) , payload ]
  end
  defp encode_value(field_num, type, data) do
    key = (field_num <<< 3) ||| wire_type(type)
    [ key, encode_value(type, data) ]
  end

  defp encode_value(:int32, data) when data < 0 do
    encode_varint(data + (1 <<< 32))
  end
  defp encode_value(:int32, data) do
    encode_varint data
  end
  defp encode_value(:int64, data) when data < 0 do
    encode_varint(data + (1 <<< 64))
  end
  defp encode_value(:int64, data) do
    encode_varint data
  end
  defp encode_value(:uint32, data), do: encode_varint(data)
  defp encode_value(:uint64, data), do: encode_varint(data)
  defp encode_value(:sint32, data)
  when data <= 0x80000000
  when data >= -0x7fffffff do
    int = bxor (data <<< 1), (data >>> 31)
    encode_varint int
  end
  defp encode_value(:sint64, data)
  when data <= 0x8000000000000000
  when data >= -0x7fffffffffffffff do
    int = bxor (data <<< 1), (data >>> 63)
    encode_varint int
  end
  defp encode_value(:bool, true), do: encode_varint(1)
  defp encode_value(:bool, false), do: encode_varint(0)
  defp encode_value(:string, data), do: encode_value(:bytes, data)
  defp encode_value(:bytes, data) do
    len = byte_size data
    [ encode_varint(len), data ]
  end
  defp encode_value(:float, data) do
    << data :: [ size(32), float, little ] >>
  end

  defp encode_varint(data) when data >= 0 do
    data |> encode_varint([]) |> Enum.reverse
  end
  defp encode_varint(true, acc), do: [1|acc]
  defp encode_varint(false, acc), do: [0|acc]
  defp encode_varint(int, acc) when int <= 127, do: [int|acc]
  defp encode_varint(int, acc) do
    next = int >>> 7
    last_seven = int - (next <<< 7)
    acc = [ (1 <<< 7) + last_seven | acc ]
    encode_varint next, acc
  end

  def wire_type(:int32), do: 0
  def wire_type(:int64), do: 0
  def wire_type(:uint32), do: 0
  def wire_type(:uint64), do: 0
  def wire_type(:sint32), do: 0
  def wire_type(:sint64), do: 0
  def wire_type(:bool), do: 0
  def wire_type(:enum), do: 0
  def wire_type(:fixed64), do: 1
  def wire_type(:sfixed64), do: 1
  def wire_type(:double), do: 1
  def wire_type(:string), do: 2
  def wire_type(:bytes), do: 2
  def wire_type(:embedded), do: 2
  def wire_type(:repeated), do: 2
  def wire_type(:fixed32), do: 5
  def wire_type(:sfixed32), do: 5
  def wire_type(:float), do: 5
  def wire_type(_), do: :custom

  defp cast(value, :int32) do
    if value &&& 0x8000000000000000 != 0 do
      value - 0x8000000000000000
    else
      value
    end
  end
  defp cast(value, :int64) do
    if value &&& 0x8000000000000000 != 0 do
      value - 0x8000000000000000
    else
      value
    end
  end
  defp cast(value, :uint32), do: value
  defp cast(value, :uint64), do: value
  defp cast(value, :sint32) do
    bxor (value >>> 1), -(value &&& 1)
  end
  defp cast(value, :sint64) do
    bxor (value >>> 1), -(value &&& 1)
  end
  defp cast(value, :string), do: value
  defp cast(value, :bytes), do: value
  defp cast(1, :bool), do: true
  defp cast(0, :bool), do: false
  defp cast(<< value :: [ size(32), little, unsigned, integer ] >>,
            :fixed32), do: value
  defp cast(<< value :: [ size(32), little, unsigned, integer ] >>,
            :sfixed32) do
    bxor (value >>> 1), -(value &&& 1)
  end
  defp cast(<< value :: [ size(64), little, unsigned, integer ] >>,
            :fixed64), do: value
  defp cast(<< value :: [ size(64), little, unsigned, integer ] >>,
            :sfixed64) do
    bxor (value >>> 1), -(value &&& 1)
  end
  defp cast(<< value :: [ little, float ] >>, :double), do: value
  defp cast(value, :float) do
    bits = byte_size(value) * 8
    << float :: [ size(bits), little, float ] >> = value
    float
  end
  defp cast(value, { :enum, enum }) do
    enum.to_symbol value
  end
  defp cast(value, { :message, module }) do
    module.decode value
  end

end
