# Engineering Knowledge — Schema & Conventions

This repository is a living engineering knowledge base. Raw source material is ingested into `raw/`; synthesized, maintained pages live in `wiki/`. Keep this document as the source of truth for structure and frontmatter.

## raw/ vs wiki/

**`raw/`** holds immutable source material: dumps, exports, transcripts, design docs as received. After ingest, files under `raw/` are never edited. Correct mistakes by adding a new raw artifact or noting the correction in the wiki — do not rewrite history in place.

**`wiki/`** holds synthesized knowledge maintained by Claude (and humans reviewing Claude's work). Pages here are derived from raw sources, prior wiki pages, and ongoing decisions. Edit freely to keep the steady-state picture accurate; link back to raw sources where they exist.

New category folders under `raw/` must be proposed and confirmed before creation. Do not invent new `raw/` categories silently.

## Frontmatter schema (wiki/ pages)

Every wiki page should use YAML frontmatter. Fields below are conventions, not a filled catalog of values.

| Field | Values / form | When to use |
| --- | --- | --- |
| `status` | `draft` \| `active` \| `needs-review` \| `superseded` \| `archived` | All wiki pages |
| `feature_status` | `in-progress` \| `shipped` \| `cancelled` | Feature pages only |
| `review_by` | date (`YYYY-MM-DD`) | Docs with no external source of truth (set a review date) |
| `source_last_modified` | date or timestamp | Docs tied to an external source |
| `last_synced` | date or timestamp | Docs tied to an external source (when this wiki page was last brought in sync) |
| `related_systems` | list of wiki paths or ids | Cross-links to systems |
| `related_projects` | list of wiki paths or ids | Cross-links to projects |
| `component` | component identifier / path | When the page is scoped to a component |
| `superseded_by` | path to the replacement page | Only when `status: superseded` |

Omit fields that do not apply. Prefer empty omission over placeholder values.

## Decisions

Decisions are **append-only**. They live under a system's `decisions/` folder (created when that system first needs one).

- Never edit a decision file after it is written.
- To change course, add a new decision file that supersedes the old one and links back to it. Do not rewrite or amend the superseded decision's body or frontmatter.

## Meetings

File meetings at the narrowest applicable scope:

1. **Feature-level** `meetings/` — the meeting is about one feature.
2. **System-level** `meetings/` — the meeting is about that system / platform broadly.
3. **Top-level** `wiki/meetings/` — only for cross-cutting meetings that do not fit a single system or feature.

Do not duplicate the same meeting under multiple scopes; choose one home and link from elsewhere if needed.

## Features

Feature folders have **no fixed template**. Start with `overview.md` only. Add `design.md`, `diagrams/`, `meetings/`, and similar only when that feature actually needs them.

When a feature ships:

1. Set its `feature_status` to `shipped` (and update `status` as appropriate).
2. Update the relevant component page(s) under the system so they reflect the new steady state.
3. Add a one-line **"Touched by"** backlink from each updated component page to the feature.

Features are never deleted or moved after completion. They remain in place as the detailed historical record.

## Catalog & log

- **`index.md`** — generated-and-maintained catalog of wiki content, organized by section (systems, entities, practices, meetings). Update on every ingest or structural change.
- **`log.md`** — chronological change log. Update on every ingest or change. Entry format: `## [YYYY-MM-DD] <action> | <description>`.
