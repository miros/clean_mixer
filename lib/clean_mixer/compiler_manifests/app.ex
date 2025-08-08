defmodule CleanMixer.CompilerManifests.App do
  alias CleanMixer.CompilerManifests.MixProject

  @manifest_filename "compile.elixir"

  defstruct [:path, :build_path, :name, :manifest_path]

  @type t :: %__MODULE__{
          path: Path.t(),
          build_path: Path.t(),
          name: :atom,
          manifest_path: Path.t()
        }

  @spec umbrella_project_apps(list(MixProject.mix_dep())) :: list(t)
  def umbrella_project_apps(deps) do
    for %{app: app_name, scm: Mix.SCM.Path, opts: opts} <- deps, umbrella_app?(opts) do
      %__MODULE__{
        path: opts[:path],
        build_path: opts[:build],
        name: app_name,
        manifest_path: manifest_path(opts[:build])
      }
    end
  end

  @spec current() :: t
  def current() do
    %__MODULE__{
      path: "",
      build_path: Mix.Project.app_path(),
      name: Mix.Project.config() |> Keyword.fetch!(:app),
      manifest_path: Mix.Project.manifest_path() |> Path.join(@manifest_filename)
    }
  end

  @spec poncho_project_apps() :: list(t)
  def poncho_project_apps do
    current_deps()
    |> Enum.reject(&String.starts_with?(&1.path, "deps/"))
  end

  @spec current_deps() :: list(t)
  def current_deps do
    deps =
      if Version.match?(System.version(), ">= 1.16.0") do
        apply(Mix.Dep.Converger, :converge, [[env: Mix.env()]])
      else
        apply(Mix.Dep.Converger, :converge, [nil, nil, [env: Mix.env()], &{&1, &2, &3}]) |> elem(0)
      end

    for %{app: app_name, opts: opts} <- deps, !umbrella_app?(opts) do
      %__MODULE__{
        path: opts[:dest] |> Path.relative_to(File.cwd!()),
        build_path: opts[:build],
        name: app_name,
        manifest_path: manifest_path(opts[:build])
      }
    end
  end

  defp umbrella_app?(opts) do
    opts[:from_umbrella] || opts[:in_umbrella]
  end

  defp manifest_path(build_path) do
    Path.join([build_path, ".mix", @manifest_filename])
  end
end
