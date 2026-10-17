import Testing
@testable import VaultCore

@Suite("Tag")
struct TagTests {
    @Test("Parses a nested tag and drops the leading hash")
    func parsesNested() throws {
        let tag = try #require(Tag("#area/work/hiring"))
        #expect(tag.components == ["area", "work", "hiring"])
        #expect(tag.path == "area/work/hiring")
        #expect(tag.display == "#area/work/hiring")
        #expect(tag.leaf == "hiring")
    }

    @Test("Lowercases so #Work and #work are one tag")
    func caseInsensitive() throws {
        let upper = try #require(Tag("#Work"))
        let lower = try #require(Tag("#work"))
        #expect(upper == lower)
    }

    @Test("Rejects empty and separator-only input")
    func rejectsEmpty() {
        #expect(Tag("") == nil)
        #expect(Tag("#") == nil)
        #expect(Tag("///") == nil)
        #expect(Tag(components: []) == nil)
    }

    @Test("Walks ancestors nearest first")
    func ancestors() throws {
        let tag = try #require(Tag("a/b/c"))
        #expect(tag.ancestors.map(\.path) == ["a/b", "a"])
        #expect(tag.parent?.path == "a/b")

        let root = try #require(Tag("a"))
        #expect(root.parent == nil)
        #expect(root.ancestors.isEmpty)
    }

    @Test("Descendant test includes the tag itself but not sibling prefixes")
    func descendants() throws {
        let parent = try #require(Tag("area/work"))
        let child = try #require(Tag("area/work/hiring"))
        let sibling = try #require(Tag("area/home"))
        // "workshop" shares a string prefix with "work" but is a different component.
        let lookalike = try #require(Tag("area/workshop"))

        #expect(child.isDescendant(of: parent))
        #expect(parent.isDescendant(of: parent))
        #expect(!sibling.isDescendant(of: parent))
        #expect(!lookalike.isDescendant(of: parent))
    }

    @Test("Sorts parents immediately before their children")
    func sorting() {
        let tags = ["b", "a/b", "a", "a/a"].compactMap { Tag($0) }
        #expect(tags.sorted().map(\.path) == ["a", "a/a", "a/b", "b"])
    }
}
