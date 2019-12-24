defmodule CleanMixer.CompilerManifests.ManifestCartographerTest do
  use ExUnit.Case

  alias CleanMixer.CompilerManifests.ManifestCartographer
  alias CleanMixer.CodeMap
  alias CleanMixer.CodeMap.SourceFile
  alias CleanMixer.CodeMap.ModuleReference

  test "returns code map with files of current project" do
    assert %CodeMap{files: files} = ManifestCartographer.get_code_map()

    doge_owner_module = Enum.find(files, &(&1.path =~ "doge_owner.ex"))

    assert %SourceFile{
             path: "test/support/code_fixtures/doge_owner.ex",
             modules: [CleanMixer.Tests.CodeFixtures.DogeOwner],
             references: refs
           } = doge_owner_module

    assert %ModuleReference{
             module_name: CleanMixer.Tests.CodeFixtures.DogeMacros,
             ref_type: :compile
           } in refs

    assert %ModuleReference{
             module_name: CleanMixer.Tests.CodeFixtures.Doge,
             ref_type: :runtime
           } in refs

    assert %ModuleReference{
             module_name: CleanMixer.Tests.CodeFixtures.Doge,
             ref_type: :struct
           } in refs
  end
end