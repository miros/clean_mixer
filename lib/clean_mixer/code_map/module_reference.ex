defmodule CleanMixer.CodeMap.ModuleReference do
  alias CleanMixer.CodeMap.CodeModule

  # struct is valid only for elixir versions < 1.11
  @type ref_type :: :compile | :struct | :export | :runtime | :typespec | :unknown

  defstruct [:module_name, :ref_type]

  @type t :: %__MODULE__{
          module_name: CodeModule.name(),
          ref_type: ref_type
        }

  @spec new(CodeModule.name(), ref_type) :: t
  def new(module_name, type \\ :unknown) do
    %__MODULE__{
      module_name: module_name,
      ref_type: type
    }
  end
end
