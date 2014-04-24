defmodule TestWrapperTest do
  use ExUnit.Case

  test "access uint32" do
    t = Proto.Test.Test1.new a: 3
    assert t[:a] == 3
    t = Proto.Test.Test1.put t, :a, 4
    assert t[:a] == 4
  end

  test "encode uint32" do
    t = Proto.Test.Test1.new a: 150
    p = t |> Proto.Test.Test1.encode |> iolist_to_binary
    assert p == << 8, 150, 1 >>
  end

  test "decode uint32" do
    t = Proto.Test.Test1.decode << 8, 150, 1 >>
    assert t[:a] == 150
  end

  test "encode enum" do
    t = Proto.Test.Test2.new b: Proto.Test.Test2.Foo.bar
    assert t[:b] == Proto.Test.Test2.Foo.bar
    payload = t |> Proto.Test.Test2.encode |> iolist_to_binary
    assert payload == << 8, 150, 1 >>
  end

  test "decode enum" do
    payload = << 8, 150, 1>>
    message = Proto.Test.Test2.decode payload
    assert message[:b] == { Proto.Test.Test2.Foo, :bar }
    assert Proto.Test.Test2.Foo.to_a(message[:b]) == :bar
  end

  test "encode nested message" do
    inner = Proto.Test.Test1.new a: 150
    outer = Proto.Test.Test3.new c: inner
    assert outer[:c][:a] == 150
    payload = outer |> Proto.Test.Test3.encode |> iolist_to_binary
    assert payload == << 26, 3, 8, 150, 1 >>
  end

  test "decode nested message" do
    payload = << 26, 3, 8, 150, 1 >>
    message = Proto.Test.Test3.decode payload
    assert message[:c][:a] == 150
  end

  test "encode repeated message" do
    message = Proto.Test.Test4.new d: [250, 150]
    assert message[:d] == [250, 150]
    payload = message |> Proto.Test.Test4.encode |> iolist_to_binary
    assert payload == << 8, 250, 1, 8, 150, 1 >>
  end

  test "decode repeated message" do
    payload = << 8, 250, 1, 8, 150, 1 >>
    message = Proto.Test.Test4.decode payload
    assert message[:d] == [250, 150]
  end

  test "encode nested repeated messages" do
    m1 = Proto.Test.Test5.Test6.new f: 150
    m2 = Proto.Test.Test5.Test6.new f: 300
    message = Proto.Test.Test5.new e: [m1, m2]
    payload = message |> Proto.Test.Test5.encode |> iolist_to_binary
    assert payload == << 10, 3, 8, 150, 1, 10, 3, 8, 172, 2 >>
  end

  test "decode nested repeated messages" do
    payload = << 10, 3, 8, 150, 1, 10, 3, 8, 172, 2 >>
    message = Proto.Test.Test5.decode payload
    [m1, m2] = message[:e]
    assert m1[:f] == 150
    assert m2[:f] == 300
  end

  test "encode bool" do
    message = Proto.Test.Test7.new g: true
    assert message[:g] == true
    payload = message |> Proto.Test.Test7.encode |> iolist_to_binary
    assert payload == << 8, 1 >>
  end

  test "decode bool" do
    payload = << 8, 1 >>
    message = Proto.Test.Test7.decode payload
    assert message[:g] == true
    payload = << 8, 0 >>
    message = Proto.Test.Test7.decode payload
    assert message[:g] == false
  end

  test "encode external enum" do
    message = Proto.Test.Test9.new j: Proto.Test.Test2.Foo.bar
    assert message[:j] == { Proto.Test.Test2.Foo, :bar }
    payload = message |> Proto.Test.Test9.encode |> iolist_to_binary
    assert payload == << 8, 150, 1 >>
  end

  test "decode external enum" do
    payload = << 8, 150, 1 >>
    message = Proto.Test.Test9.decode payload
    assert message[:j] == { Proto.Test.Test2.Foo, :bar }
  end

  test "encode external message" do
    m = Proto.Test.Test5.Test6.new f: 150
    message = Proto.Test.Test10.new k: m
    assert message[:k][:f] == 150
    payload = message |> Proto.Test.Test10.encode |> iolist_to_binary
    assert payload == << 10, 3, 8, 150, 1 >>
  end

  test "decode external message" do
    payload = << 10, 3, 8, 150, 1 >>
    message = Proto.Test.Test10.decode payload
    assert message[:k][:f] == 150
  end

  test "incode imported message" do
    m = Proto.Other.Msg1.new a: 150
    message = Proto.Test.Test11.new l: m
    assert message[:l][:a] == 150
    payload = message |> Proto.Test.Test11.encode |> iolist_to_binary
    assert payload == << 10, 3, 8, 150, 1 >>
  end

  test "decode imported message" do
    payload = << 10, 3, 8, 150, 1>>
    message = Proto.Test.Test11.decode payload
    assert message[:l][:a] == 150
  end

  test "encode nested imported message" do
    m = Proto.Other.Msg1.Msg3.new b: 150
    message = Proto.Test.Test12.new m: m
    assert message[:m][:b] == 150
    payload = message |> Proto.Test.Test12.encode |> iolist_to_binary
    assert payload == << 10, 3, 8, 150, 1 >>
  end

  test "decode nested imported message" do
    payload = << 10, 3, 8, 150, 1>>
    message = Proto.Test.Test12.decode payload
    assert message[:m][:b] == 150
  end

  test "missing package header" do
    message = Proto.NoPackage.new a: 150
    assert message[:a] == 150
    payload = message |> Proto.NoPackage.encode |> iolist_to_binary
    assert payload == << 8, 150, 1 >>
    message = Proto.NoPackage.decode payload
    assert message[:a] == 150
  end

  test "access field with default" do
    message = Proto.Test.Test7.new
    assert message[:g] == true
  end

  test "encode field with defaults" do
    message = Proto.Test.Test13.new
    assert message[:n] == 150
    assert message[:o] == 300
    payload = message |> Proto.Test.Test13.encode |> iolist_to_binary
    assert payload == << 8, 150, 1, 16, 172, 2 >>
  end

  test "decode field with defaults" do
    payload = <<>>
    message = Proto.Test.Test13.decode payload
    assert message[:n] == 150
    assert message[:o] == 300
  end

  test "copy existing message" do
    message = Proto.Test.Test13.new n: 100
    copy = Proto.Test.Test13.new message, o: 200
    assert copy[:n] == 100
    assert copy[:o] == 200
  end

  test "multi get" do
    m = Proto.Test.Test13.new n: 100, o: 200
    assert [200, 100] == Proto.Test.Test13.get(m, [:o, :n])
  end
  
  test "encode float" do
    t = Test.Test14.new num: 1.0
    p = t |> Test.Test14.encode |> iolist_to_binary
    assert p == <<13, 0, 0, 128, 63>>
  end

  test "decode float" do
    t = Test.Test14.decode <<13, 0, 0, 128, 63>>
    assert t[:num] == 1.0
  end
end
