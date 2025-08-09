defmodule CleanMixer.Workspace do
  use GenServer

  alias CleanMixer.Project
  alias CleanMixer.ArchMap
  alias CleanMixer.ArchMap.Component
  alias CleanMixer.ArchMap.Dependency
  alias CleanMixer.CodeMap
  alias CleanMixer.CodeMap.SourceFile
  alias CleanMixer.Graph

  @type options :: [timeout_ms: timeout()]

  @opaque t :: {pid, options}
  @type project_action :: (Project.t() -> any)

  @default_options [timeout_ms: :infinity]

  @spec new(Project.t(), options) :: t
  def new(project, options \\ []) do
    {:ok, pid} = GenServer.start_link(__MODULE__, [project])
    {pid, Keyword.merge(@default_options, options)}
  end

  @spec component(t, Component.name()) :: Component.t() | nil
  def component(workspace, name) do
    comp =
      use_project(workspace, fn project ->
        ArchMap.component(project.arch_map, name)
      end)

    unless comp do
      raise "unknown component name:#{name}; check .clean_mixer.exs"
    end

    comp
  end

  @spec component_with_file(t, Path.t()) :: Component.t() | nil
  def component_with_file(workspace, file_path) do
    use_project(workspace, fn project ->
      ArchMap.component_with_file(project.arch_map, file_path)
    end)
  end

  @spec dependencies_of(t, Component.name()) :: list(Dependency.t())
  def dependencies_of(workspace, comp_name) do
    comp = component(workspace, comp_name)

    use_project(workspace, fn project ->
      ArchMap.dependencies_of(project.arch_map, comp)
    end)
  end

  @spec reject_hex_packs(list(Dependency.t())) :: list(Dependency.t())
  def reject_hex_packs(deps) do
    Enum.reject(deps, &Component.hex_pack?(&1.target))
  end

  @spec usages_of(t, Component.name()) :: list(Dependency.t())
  def usages_of(workspace, comp_name) do
    comp = component(workspace, comp_name)

    use_project(workspace, fn project ->
      ArchMap.usages_of(project.arch_map, comp)
    end)
  end

  @spec dependency?(t, Component.name(), Component.name()) :: boolean
  def dependency?(workspace, comp_name, target_comp_name) do
    target_comp = component(workspace, target_comp_name)

    deps = dependencies_of(workspace, comp_name) |> Enum.map(& &1.target)
    target_comp in deps
  end

  @spec component_cycles(t()) :: [Graph.cycle(Component.t())]
  def component_cycles(workspace) do
    use_project(workspace, fn project ->
      project.arch_map
      |> ArchMap.graph()
      |> Graph.cycles()
    end)
  end

  @spec file_cycles(t()) :: [Graph.cycle(SourceFile.t())]
  def file_cycles(workspace) do
    use_project(workspace, fn project ->
      project.code_map
      |> CodeMap.graph()
      |> Graph.cycles()
    end)
  end

  @spec use_project(t, project_action) :: action_result :: any
  def use_project({pid, options}, action_fun) do
    GenServer.call(pid, {:use_project, action_fun}, options[:timeout_ms])
  end

  defmodule State do
    defstruct [:project]

    @type t :: %__MODULE__{
            project: Project.t()
          }
  end

  @impl GenServer
  def init([project]) do
    state = %State{
      project: project
    }

    {:ok, state}
  end

  @impl GenServer
  def handle_call({:use_project, action}, _from, %State{project: project} = state) do
    result = action.(project)
    {:reply, result, state}
  end
end
