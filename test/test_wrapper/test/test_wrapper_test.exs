defmodule TestWrapperTest do
  use ExUnit.Case

  test "access uint32" do
    t = Test.Test1.new a: 3
    assert t[:a] == 3
    t = Test.Test1.put t, :a, 4
    assert t[:a] == 4
  end

  test "encode uint32" do
    t = Test.Test1.new a: 150
    p = t |> Test.Test1.encode |> iolist_to_binary
    assert p == << 8, 150, 1 >>
  end

  test "decode uint32" do
    t = Test.Test1.decode << 8, 150, 1 >>
    assert t[:a] == 150
  end

  test "encode enum" do
    t = Test.Test2.new b: Test.Test2.Foo.bar
    assert t[:b] == Test.Test2.Foo.bar
    payload = t |> Test.Test2.encode |> iolist_to_binary
    assert payload == << 8, 150, 1 >>
  end

  test "decode enum" do
    payload = << 8, 150, 1>>
    message = Test.Test2.decode payload
    assert message[:b] == { Test.Test2.Foo, :bar }
  end

  test "encode nested message" do
    inner = Test.Test1.new a: 150
    outer = Test.Test3.new c: inner
    assert outer[:c][:a] == 150
    payload = outer |> Test.Test3.encode |> iolist_to_binary
    assert payload == << 26, 3, 8, 150, 1 >>
  end

  test "decode nested message" do
    payload = << 26, 3, 8, 150, 1 >>
    message = Test.Test3.decode payload
    assert message[:c][:a] == 150
  end

  test "encode repeated message" do
    message = Test.Test4.new d: [250, 150]
    assert message[:d] == [250, 150]
    payload = message |> Test.Test4.encode |> iolist_to_binary
    assert payload == << 8, 250, 1, 8, 150, 1 >>
  end

  test "decode repeated message" do
    payload = << 8, 250, 1, 8, 150, 1 >>
    message = Test.Test4.decode payload
    assert message[:d] == [250, 150]
  end

  test "encode nested repeated messages" do
    m1 = Test.Test5.Test6.new f: 150
    m2 = Test.Test5.Test6.new f: 300
    message = Test.Test5.new e: [m1, m2]
    payload = message |> Test.Test5.encode |> iolist_to_binary
    assert payload == << 10, 3, 8, 150, 1, 10, 3, 8, 172, 2 >>
  end

  test "decode nested repeated messages" do
    payload = << 10, 3, 8, 150, 1, 10, 3, 8, 172, 2 >>
    message = Test.Test5.decode payload
    [m1, m2] = message[:e]
    assert m1[:f] == 150
    assert m2[:f] == 300
  end

  test "encode bool" do
    message = Test.Test7.new g: true
    assert message[:g] == true
    payload = message |> Test.Test7.encode |> iolist_to_binary
    assert payload == << 8, 1 >>
  end

  test "decode bool" do
    payload = << 8, 1 >>
    message = Test.Test7.decode payload
    assert message[:g] == true
    payload = << 8, 0 >>
    message = Test.Test7.decode payload
    assert message[:g] == false
  end

  test "encode external enum" do
    message = Test.Test9.new j: Test.Test2.Foo.bar
    assert message[:j] == { Test.Test2.Foo, :bar }
    payload = message |> Test.Test9.encode |> iolist_to_binary
    assert payload == << 8, 150, 1 >>
  end

  test "decode external enum" do
    payload = << 8, 150, 1 >>
    message = Test.Test9.decode payload
    assert message[:j] == { Test.Test2.Foo, :bar }
  end

  test "encode external message" do
    m = Test.Test5.Test6.new f: 150
    message = Test.Test10.new k: m
    assert message[:k][:f] == 150
    payload = message |> Test.Test10.encode |> iolist_to_binary
    assert payload == << 10, 3, 8, 150, 1 >>
  end

  test "decode external message" do
    payload = << 10, 3, 8, 150, 1 >>
    message = Test.Test10.decode payload
    assert message[:k][:f] == 150
  end

  test "incode imported message" do
    m = Other.Msg1.new a: 150
    message = Test.Test11.new l: m
    assert message[:l][:a] == 150
    payload = message |> Test.Test11.encode |> iolist_to_binary
    assert payload == << 10, 3, 8, 150, 1 >>
  end

  test "decode imported message" do
    payload = << 10, 3, 8, 150, 1>>
    message = Test.Test11.decode payload
    assert message[:l][:a] == 150
  end

  test "encode nested imported message" do
    m = Other.Msg1.Msg3.new b: 150
    message = Test.Test12.new m: m
    assert message[:m][:b] == 150
    payload = message |> Test.Test12.encode |> iolist_to_binary
    assert payload == << 10, 3, 8, 150, 1 >>
  end

  test "decode nested imported message" do
    payload = << 10, 3, 8, 150, 1>>
    message = Test.Test12.decode payload
    assert message[:m][:b] == 150
  end

  test "missing package header" do
    message = NoPackage.new a: 150
    assert message[:a] == 150
    payload = message |> NoPackage.encode |> iolist_to_binary
    assert payload == << 8, 150, 1 >>
    message = NoPackage.decode payload
    assert message[:a] == 150
  end

  test "access field with default" do
    message = Test.Test7.new
    assert message[:g] == true
  end

  test "encode field with defaults" do
    message = Test.Test13.new
    assert message[:n] == 150
    assert message[:o] == 300
    payload = message |> Test.Test13.encode |> iolist_to_binary
    assert payload == << 8, 150, 1, 16, 172, 2 >>
  end

  test "decode field with defaults" do
    payload = <<>>
    message = Test.Test13.decode payload
    assert message[:n] == 150
    assert message[:o] == 300
  end

  test "copy existing message" do
    message = Test.Test13.new n: 100
    copy = Test.Test13.new message, o: 200
    assert copy[:n] == 100
    assert copy[:o] == 200
  end
end
