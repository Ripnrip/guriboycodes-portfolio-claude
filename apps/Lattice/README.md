# Lattice

A graph-first, Apple-native knowledge base. Plain Markdown on disk, an Obsidian-compatible
vault, and a force-directed graph that runs on the GPU.

> **Status: Phase 2.** The vault layer is in — folder crawl, Realm index, coordinated file
> IO, change watching, editor, backlinks, rename-with-link-repair. Importers, widgets,
> Siri intents, Spotlight and the MCP server are Phase 3.

> **Nothing here has been compiled.** Both phases were written in a Linux container with no
> Swift toolchain and no Xcode, so every Swift and Metal file is unverified by a compiler.
> The package tests are real and runnable. Expect a first-build fixup pass — see
> [First build](#first-build).

## Quick start

```bash
brew install xcodegen      # once
cd apps/Lattice
make bootstrap             # generates Lattice.xcodeproj and opens it
```

Pick a signing team in **Signing & Capabilities** (or set `DEVELOPMENT_TEAM` in
`project.yml`), run, then **Open Folder…** and point it at `Fixtures/SampleVault/` — or at
an existing Obsidian vault, which works as-is.

```bash
make test        # everything (macOS)
make test-core   # VaultCore + MarkdownKit + VaultFiles — runs anywhere Swift does
```

## Architecture

**Markdown files are the source of truth. Realm is a derived index over them.**

```
Markdown files ──► VaultCrawler ──► VaultIndex (Realm) ──► snapshots ──► GraphEngine ──► SwiftUI
 source of truth    what changed     derived, disposable    Sendable       Metal
```

That one decision pays for itself three times: the vault stays readable by Obsidian, iCloud
handles sync for free, and **schema changes never need a Realm migration**. Bump
`IndexSchema.version`, the store is deleted, the files rebuild it. There is no migration
block anywhere in this project, and no way for a migration bug to eat someone's notes —
because the index was never the notes.

### Targets

Split by what each must link against, so the fiddly logic stays testable off a Mac:

| Target | Links | Holds |
|---|---|---|
| `VaultCore` | — | `NoteID`, `Tag`, `NoteSnapshot`, `LinkSnapshot`, `GraphSnapshot`, `TagCount` |
| `MarkdownKit` | — | Frontmatter, wiki-syntax scanner, `NoteParser`, `LinkResolver` |
| `VaultFiles` | — | Crawler, fingerprints, coordinated IO, bookmarks, watcher, link rewriting |
| `GraphEngine` | Metal | Simulation, renderer, `MTKView` bridge, SwiftUI surface |
| `VaultIndex` | Realm | Records, the index actor, queries, graph projection |
| `LatticeUI` | SwiftUI | Controller and views |

The first three touch neither Metal nor Realm, which is why `make test-core` works on Linux.
`Package.swift` adds the Apple-only targets only when the host can compile them.
`GraphEngine` depends on `VaultCore` alone — never on the store — so the graph can still be
driven from synthetic data with no vault present (`GraphViewModel.demo()`).

## Realm under Swift 6 — the one genuinely hard part

Realm objects are **not `Sendable`** and are **thread-confined**. A plain Swift `actor` is
not enough: actors guarantee mutual exclusion, not thread stability, so an actor can resume
on a different cooperative-pool thread between awaits and Realm will trap.

`VaultIndexActor` is a global actor backed by a `DispatchSerialQueue` as its executor, which
*does* pin every hop to one thread. The rule that follows is absolute: **nothing Realm-typed
leaves that actor.** Queries return `VaultCore` value types only — the same
snapshots-across-boundaries discipline `GraphSimulation` already uses for its GPU buffers.

## Incremental indexing

A crawl compares each file against its stored fingerprint and classifies it:

| Outcome | Meaning | Cost |
|---|---|---|
| unchanged | size and mtime match | never opened |
| `touched` | mtime moved, bytes identical | read, fingerprint refreshed, **not** re-parsed |
| `modified` | content hash differs | read and re-parsed |
| `added` / `removed` | new or gone | parsed / deleted |

`touched` exists for iCloud specifically: the sync daemon rewrites modification dates on
files it has merely re-downloaded. Without the content hash, every sync would look like the
whole vault changing, and every activation would re-parse it.

Link resolution is deliberately *not* incremental. A note added now can resolve a link that
has been dangling in a file nobody touched, so any structural change re-resolves everything;
a `touched`-only crawl rebuilds nothing.

## File watching — the weak spot, stated plainly

macOS gets FSEvents: recursive, reliable, coalesced. iOS has no equivalent —
`NSFilePresenter` on a deep tree is unreliable and `NSMetadataQuery` is documented as missing
changes in subdirectories of external ubiquity containers.

So **the crawl is the correctness mechanism and the watcher is only latency.** An incremental
crawl runs whenever the app becomes active; live watching is layered on where it can be
trusted, and `VaultWatcher.isSupported` reports honestly so the UI can say what it does. A
missed event costs freshness, never consistency.

All reads and writes go through `NSFileCoordinator`, so Lattice and Obsidian can hold the
same vault open without tearing each other's writes.

## The graph engine

Four compute kernels per step, in `Sources/GraphEngine/Shaders/GraphShaders.metal`:

| Kernel | Approach |
|---|---|
| `graph_repulsion` | Exact all-pairs, tiled through threadgroup memory so every thread in a group reads the same staged block |
| `graph_attraction` | Spring forces walked over CSR adjacency — node-parallel, so no atomics |
| `graph_integrate` | Velocity Verlet with damping, gravity, annealing, speed clamp |
| `graph_reduce` | Threadgroup reduction of bounds and kinetic energy |

**Exact all-pairs rather than Barnes-Hut.** Tiling sustains roughly 810 GFLOPS on Apple
silicon, putting a 10k-node step near 2.5 ms — inside a 120 Hz frame. Barnes-Hut would add a
GPU tree build and approximation error to buy headroom a personal vault does not need.

**What Apple silicon actually buys.** Every buffer is `.storageModeShared`, so there is one
copy in unified memory and hit-testing reads `MTLBuffer.contents()` directly — no blit, no
staging buffer, no stall. Intel Macs fall back to `.storageModeManaged`.

**Battery.** The simulation stops when kinetic energy settles and the view stops requesting
frames. Pan, zoom and hover redraw without restarting the physics. A force-directed graph
that keeps integrating after it converges is a battery fire and looks identical.

**Incremental updates.** Surviving nodes keep their positions and new ones seed at their
neighbours' centroid, so re-indexing after a save does not detonate the layout.

## Wiki features

`swift-markdown` wraps cmark-gfm, whose inline grammar is fixed — there is no extension point
for `[[wikilinks]]`, `#tags`, or `^block-ids`, so those are lexed directly over the source.

The scanner is code-aware: fenced blocks, indented blocks and inline spans emit nothing,
because a `#hashtag` in a shell snippet is a comment. The same property makes rename repair
safe — documentation that *shows* wikilink syntax is not silently rewritten.

Link resolution follows Obsidian precedence (exact path → title → alias → *unique*
basename). An ambiguous basename stays unresolved rather than guessing. Unresolved links are
first-class: linking to a note before writing it is normal, so dangling targets become hollow
placeholder nodes in the graph and a **Missing Notes** list that creates them on tap.

Renaming a note repairs every `[[link]]` to it, preserving aliases and anchors —
`[[Old#Design|as shown]]` keeps both halves. Repair is part of the rename, not a maintenance
command, because the alternative is silently breaking every reference.

### Known limitation

Realm has no FTS5. `VaultIndex.search` is a substring scan — fine for a link picker over a
personal vault, and explicitly not the inverted index that real unlinked-mention search
needs. That is the cost of the file-based/derived-index trade, and it is the one thing this
architecture is worse at than a SQLite-backed design.

## First build

Files most likely to need a fixup, and why:

- **`Shaders/GraphShaders.metal` + `GraphShaderTypes.swift`** hold mirrored struct
  definitions. SwiftPM gives a Metal target no dependable way to include a header from a
  Swift target, so they are duplicated. `GraphShaderTypes.validateLayout()` asserts the
  sizes at startup in debug builds, so drift fails loudly rather than garbling the
  simulation.
- **`GraphMetalView.swift`** has the only genuinely per-platform input code: AppKit mouse
  and tracking areas versus UIKit gesture recognisers.
- **`VaultWatcher.swift`** bridges the FSEvents C API, including a C callback and manual
  retain/release of its context.
- **Realm's binaries are unsigned** now that MongoDB no longer distributes it, so Xcode
  rejects them at embed time. `project.yml` carries a re-signing build phase for this.
- **`project.yml`** was written without running `xcodegen`.

## Roadmap

**Phase 1 — done.** `VaultCore` value types · `MarkdownKit` parser and resolver · the Metal
graph engine · synthetic graph generator · project scaffolding.

**Phase 2 — done.** `VaultFiles` (crawler, fingerprints, coordinated IO, bookmarks, FSEvents
watcher, link rewriting) · `VaultIndex` (Realm records, pinned actor, queries, graph
projection) · `LatticeUI` (controller, sidebar, note list, editor with `[[` completion,
backlinks pane) · real vault feeding the graph.

**Phase 3.** Importers (Reminders via EventKit; Apple Notes via ScriptingBridge on macOS;
Evernote `.enex`) · WidgetKit · App Intents and Siri · Core Spotlight · Share Extension ·
MCP server · cursor-accurate link completion via a TextKit bridge.

### Two things worth knowing early

- **Apple Notes has no public API.** macOS can import via AppleScript/ScriptingBridge with
  the user's Automation consent. iOS cannot read Apple Notes at all, at any price — so the
  iOS build will explain that rather than offering a button that cannot work. Apple
  *Reminders* has a real public API (EventKit) on both platforms.
- **The MCP server will write only Markdown** and open Realm read-only. That dissolves the
  two-processes-one-database hazard by construction: the app's watcher sees the file change
  and re-indexes, and nothing contends for a write lock.

## Layout

```
apps/Lattice/
├── project.yml            XcodeGen spec (app target, entitlements, Realm re-signing)
├── Makefile               bootstrap / generate / test / test-core
├── App/                   @main app and entitlements
├── Fixtures/SampleVault/  6 notes, 1 dangling link — exercises every syntax form
└── Packages/LatticeKit/
    ├── Sources/           VaultCore · MarkdownKit · VaultFiles · GraphEngine
    │                      VaultIndex · LatticeUI
    └── Tests/             VaultCoreTests · MarkdownKitTests · VaultFilesTests
                           GraphEngineTests
```
