# Lattice

A graph-first, Apple-native knowledge base. Plain Markdown on disk, an Obsidian-compatible
vault, and a force-directed graph that runs on the GPU.

> **Status: Phase 1.** The graph engine, the wiki-syntax parser, and the shared value
> types are built and tested. The file layer, editor, importers, widgets, Siri intents,
> and MCP server are not — see [Roadmap](#roadmap).

> **Nothing here has been compiled.** Phase 1 was written in a Linux container with no
> Swift toolchain and no Xcode, so every Swift and Metal file is unverified by a compiler.
> The package tests are real and runnable; expect a first-build fixup pass. Files most
> likely to need one are called out in [First build](#first-build).

## Quick start

```bash
brew install xcodegen      # once
cd apps/Lattice
make bootstrap             # generates Lattice.xcodeproj and opens it
```

Then pick a signing team in **Signing & Capabilities** (or set `DEVELOPMENT_TEAM` in
`project.yml`) and run. The app opens on a synthetic 600-note vault, so the graph has
something to chew on before the file layer exists.

Run the tests without Xcode:

```bash
make test        # everything (macOS)
make test-core   # VaultCore + MarkdownKit only — works anywhere Swift does
```

## How it fits together

```
Markdown files  ──►  MarkdownKit  ──►  VaultCore types  ──►  GraphEngine  ──►  SwiftUI
 (source of truth)     parse             snapshots            Metal
```

Markdown files are the source of truth. Realm, when it lands in Phase 2, is a **derived
index** over them — rebuildable, never authoritative. That is a deliberate change from
"Realm is the database", and it buys three things: the vault stays readable by Obsidian,
iCloud handles sync for free, and **schema changes never need a Realm migration** (bump
`indexVersion`, delete the store, re-crawl).

### Packages

| Target | Depends on | What it holds |
|---|---|---|
| `VaultCore` | — | `NoteID`, `Tag`, `NoteSnapshot`, `LinkSnapshot`, `GraphSnapshot`. Pure `Sendable` value types. |
| `MarkdownKit` | `VaultCore` | Frontmatter, the wiki-syntax scanner, `NoteParser`, `LinkResolver`. |
| `GraphEngine` | `VaultCore` | Metal simulation, renderer, `MTKView` bridge, SwiftUI surface. |

`GraphEngine` depends only on `VaultCore` — never on the store — so it can be driven,
tested, and profiled from synthetic data with no vault present. `VaultCore` and
`MarkdownKit` touch neither Metal nor Realm, which is why they test on Linux.

## The graph engine

Four compute kernels run per step, in `Sources/GraphEngine/Shaders/GraphShaders.metal`:

| Kernel | What it does |
|---|---|
| `graph_repulsion` | Exact all-pairs repulsion, tiled through threadgroup memory so every thread in a group reads the same staged block. |
| `graph_attraction` | Spring forces walked over CSR adjacency — node-parallel, so no atomics. |
| `graph_integrate` | Velocity Verlet with damping, gravity, annealing, and a speed clamp. |
| `graph_reduce` | Threadgroup reduction of bounds and kinetic energy. |

**Why exact all-pairs rather than Barnes-Hut.** Tiled all-pairs sustains roughly
810 GFLOPS on Apple silicon, which puts a 10k-node force step near 2.5 ms — inside a
120 Hz frame. Barnes-Hut would add a GPU tree build and its approximation error to buy
headroom a personal vault does not need. If vaults ever reach six figures, that is the
upgrade; until then the simpler algorithm is also the faster one to get right.

**What the Apple silicon path actually buys.** Every buffer is `.storageModeShared`, so
there is one copy in unified memory. Hit-testing reads `MTLBuffer.contents()` directly —
no blit, no staging buffer, no stall — which is what lets node picking keep up at 120 Hz.
On an Intel Mac with a discrete GPU the code falls back to `.storageModeManaged` and
publishes CPU writes explicitly.

**Battery.** The simulation stops when kinetic energy per node falls below a threshold,
and the view stops requesting frames entirely. Pan, zoom, and hover redraw without
restarting the physics; dragging a node reheats it. A force-directed graph that keeps
integrating after it has converged is a battery fire and looks identical.

**Incremental updates.** `GraphSimulation.load(_:)` keeps the positions of nodes that
survived and seeds new ones at the centroid of their placed neighbours, so re-indexing
after a file save does not visibly detonate the layout.

## Wiki syntax

`swift-markdown` wraps cmark-gfm, whose inline grammar is fixed — there is no extension
point for `[[wikilinks]]`, `#tags`, or `^block-ids`. `InlineScanner` therefore lexes those
directly over the source, and CommonMark block structure is left to `swift-markdown` in
whatever layer wants a full AST.

Recognised: `[[Note]]`, `[[Note|Alias]]`, `[[Note#Heading]]`, `[[Note#^block]]`,
`![[Embed]]`, `#nested/tags`, trailing `^block-ids`, ATX headings, and YAML frontmatter.

The scanner is code-aware — fenced blocks, indented blocks, and inline spans emit nothing,
because a `#hashtag` in a shell snippet is a comment and indexing it would pollute the
graph. Backslash escapes work too.

Link resolution follows Obsidian's precedence: exact path, then title, then alias, then a
*unique* basename. An ambiguous basename stays unresolved rather than guessing. Unresolved
links are first-class — linking to a note before writing it is normal, so dangling targets
become hollow placeholder nodes in the graph.

## First build

These are the files most likely to need a fixup, and why:

- **`Shaders/GraphShaders.metal` and `GraphShaderTypes.swift`** hold mirrored struct
  definitions. SwiftPM gives a Metal target no dependable way to include a header from a
  Swift target, so they are duplicated rather than shared. `GraphShaderTypes.validateLayout()`
  asserts the sizes at startup in debug builds, so a drift fails loudly rather than
  producing a garbled simulation.
- **`GraphMetalView.swift`** has the only genuinely per-platform code: AppKit mouse and
  tracking-area handling versus UIKit gesture recognisers.
- **`project.yml`** was written without running `xcodegen`.

## Roadmap

**Phase 1 — done.** `VaultCore` value types · `MarkdownKit` parser and resolver · the full
Metal graph engine · synthetic graph generator · package tests · project scaffolding.

**Phase 2.** `VaultStore`: folder crawl, Realm index, `NSFileCoordinator` IO, change
watching. Graph fed from a real vault. Note list, editor, backlinks pane.

**Phase 3.** Importers (Reminders via EventKit; Apple Notes via ScriptingBridge on macOS;
Evernote `.enex`) · WidgetKit · App Intents and Siri · Core Spotlight · Share Extension ·
MCP server.

### Two things worth knowing early

- **Apple Notes has no public API.** macOS can import via AppleScript/ScriptingBridge with
  the user's Automation consent. iOS cannot read Apple Notes at all, at any price — so the
  iOS build will explain that rather than offering a button that cannot work. Apple
  *Reminders*, by contrast, has a real public API on both platforms.
- **File watching is the weak spot.** macOS gets FSEvents. iOS has no equivalent:
  `NSFilePresenter` on a deep tree is flaky and `NSMetadataQuery` is documented as
  unreliable for subdirectories in external ubiquity containers. Correctness will come
  from an incremental crawl on activation, with live watching as a per-platform
  enhancement only where it can be trusted.
- **Realm's binaries are unsigned.** MongoDB no longer distributes Realm, so its prebuilt
  XCFrameworks carry no signature and Xcode rejects them at embed time. `project.yml`
  already carries the re-signing build phase this needs; it is inert until Phase 2.

## Layout

```
apps/Lattice/
├── project.yml            XcodeGen spec (app target, entitlements, signing fixups)
├── Makefile               bootstrap / generate / test
├── App/                   @main app, ContentView, entitlements
├── Fixtures/SampleVault/  a small vault exercising every syntax form
└── Packages/LatticeKit/   VaultCore · MarkdownKit · GraphEngine + tests
```
