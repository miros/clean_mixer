defmodule CleanMixer.ArchMapTest do
  use ExUnit.Case
  alias CleanMixer.ArchMap
  alias CleanMixer.ArchMap.Component
  alias CleanMixer.ArchMap.Dependency
  alias CleanMixer.CodeMap.SourceFile
  alias CleanMixer.CodeMap.FileDependency

  test "calculates dependencies between components" do
    components = [
      comp1 =
        Component.new("comp1", [SourceFile.new("comp1/file1"), SourceFile.new("comp1/file2")], [
          FileDependency.new(SourceFile.new("comp1/file1"), SourceFile.new("comp2/file1")),
          FileDependency.new(SourceFile.new("comp1/file2"), SourceFile.new("comp3/file1"))
        ]),
      comp2 =
        Component.new("comp2", [SourceFile.new("comp2/file1")], [
          FileDependency.new(SourceFile.new("comp2/file1"), SourceFile.new("comp1/file1"))
        ]),
      comp3 = Component.new("comp3", [SourceFile.new("comp3/file1")], [])
    ]

    assert [
             Dependency.new(comp1, comp3, [
               FileDependency.new(SourceFile.new("comp1/file2"), SourceFile.new("comp3/file1"))
             ]),
             Dependency.new(comp1, comp2, [
               FileDependency.new(SourceFile.new("comp1/file1"), SourceFile.new("comp2/file1"))
             ]),
             Dependency.new(comp2, comp1, [
               FileDependency.new(SourceFile.new("comp2/file1"), SourceFile.new("comp1/file1"))
             ])
           ] ==
             ArchMap.build(components).dependencies
  end

  describe "usages_of" do
    test "returns incoming dependencies for given component" do
      comp1 = Component.new("comp1")
      comp2 = Component.new("comp2")
      comp3 = Component.new("comp3")

      arch_map = %ArchMap{
        components: [comp1, comp2, comp3],
        dependencies: [
          Dependency.new(comp1, comp3),
          Dependency.new(comp2, comp3),
          Dependency.new(comp3, comp1),
          Dependency.new(comp3, comp2)
        ]
      }

      assert ArchMap.usages_of(arch_map, comp3) == [
               Dependency.new(comp1, comp3),
               Dependency.new(comp2, comp3)
             ]
    end
  end

  describe "except" do
    test "returns arch map without given components" do
      components = [
        comp1 =
          Component.new("comp1", [SourceFile.new("comp1/file1"), SourceFile.new("comp1/file2")], [
            FileDependency.new(SourceFile.new("comp1/file1"), SourceFile.new("comp2/file1"))
          ]),
        comp2 = Component.new("comp2", [SourceFile.new("comp2/file1")])
      ]

      filtered_map = components |> ArchMap.build() |> ArchMap.except([comp2])
      assert filtered_map.components == [comp1]
      assert filtered_map.dependencies == []
    end
  end

  describe "public_files" do
    test "returns component files used by othe components" do
      comp1 = Component.new("comp1")
      comp2 = Component.new("comp2")
      comp3 = Component.new("comp3")

      arch_map = %ArchMap{
        components: [comp1, comp2, comp3],
        dependencies: [
          Dependency.new(comp2, comp1, [
            FileDependency.new(SourceFile.new("comp2/file1"), SourceFile.new("comp1/file1")),
            FileDependency.new(SourceFile.new("comp2/file2"), SourceFile.new("comp1/file2"))
          ]),
          Dependency.new(comp3, comp1, [
            FileDependency.new(SourceFile.new("comp3/file1"), SourceFile.new("comp1/file1"))
          ])
        ]
      }

      assert ArchMap.public_files(arch_map, comp1) == [SourceFile.new("comp1/file1"), SourceFile.new("comp1/file2")]
    end
  end
end
