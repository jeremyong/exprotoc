# Exprotoc

Elixir protocol buffers compiler

## Mix project options

To use `exprotoc`, first include `exprotoc` in your mixfile as a
dependency. Then, in the project property of your mix project, add
`:exprotoc` to the list of compilers (e.g. `compilers:
[:exprotoc, :elixir, :app`).

To configure the `:exprotoc` compiler prepass, there are three
exposed options: `proto_out`, `proto_files`, and `proto_path`.

### `proto_out`

Binary string that represents the directory generated code should
be output to. Defaults to the `lib` folder.

### `proto_files`

This should be a list of all the proto files you wish to turn into
elixir code.

### `proto_path`

List of directories in the order `exprotoc` should visit to look
for proto files and imports.

### Example `mix.exs file`

```elixir
defmodule Example.Mixfile do
  use Mix.Project

  def project do
    [ app: :example,
      version: "0.0.1",
      elixir: "~> 0.12.5",
      compilers: [:exprotoc, :elixir, :app],
      proto_files: ["example.proto"],
      proto_path: ["priv"],
      deps: deps ]
  end

  defp deps do
    [{ :exprotoc, github: "jeremyong/exprotoc" }]
  end
end
```

This will compile the `Example` application with the generated code
for the proto file `example.proto`. Because no `proto_out` option
is specified, the generated code will be output to the lib folder.

## Usage

Just access your message modules as you would a standard Elixir dict.

For example, with the following proto message:

```proto
package Example;
message Foo {
  enum Bar {
    Zap = 150;
  }
  required Foo a = 1;
  required uint32 b = 2;
}
```

`exprotoc` will create a module `Example.Foo` and submodule
`Example.Foo.Bar`.

You can create a new message simply with `Example.Foo.new` or
`Example.Foo.new a: Example.Foo.Bar.zap`.

You can access your message with the access protocol. For example:

```elixir
message = Example.Foo.new a: Example.Foo.Bar.zap
IO.inspect message[:a] # Will output { Example.Foo.Bar, :zap }
IO.inspect message[:b] # Will output nil
message = Example.Foo.put message, :b, 150
IO.inspect message[:b] # Will output 150
```

All message modules export the `encode` and `decode` functions to turn
a message into an iolist or turn binary into a message.

Default values work as expected.

Repeated fields are represented as lists.
