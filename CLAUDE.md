# ORCA

**ORCA** (Operational Records & Context Archive) is an engineering knowledge
base: source material lands in `raw/` and stays immutable after ingest;
synthesized pages live in `wiki/` and are maintained by LLMs (with human
review). This file is the schema and conventions for that work — follow it
when ingesting, editing, or querying.

## Project structure

- `raw/` — Immutable source material. Never modified after ingest.
  - `raw/inbox/` — drop zone; sort into a category below, or propose a new category and confirm:w
  -  with the user before creating one.
  - `raw/azure-devops/` — cached work-item snapshots, timestamped.
  - `raw/design-docs/` — exported or linked design documents.
  - `raw/transcripts/` — meeting/conversation transcripts.
  - `raw/emails/` — exported email threads / written follow-ups.
- `wiki/` — LLM-maintained, synthesized. This is what gets read during work.
  - `wiki/index.md` — master catalog (TSV). Regenerate via
  `scripts/build-index.sh` on every ingest or edit.
  - `wiki/log.md` — append-only operation log.
  - `wiki/systems/{name}/` — overview.md, decisions/, components/,
  meetings/, features/.
  - `wiki/entities/` — people/, teams/, external-systems/.
  - `wiki/practices/` — conventions, glossary, cross-cutting patterns not
  tied to one system.
  - `wiki/meetings/` — cross-cutting meetings not scoped to one system.



## Frontmatter

Every wiki page requires:
    ---
    type: system | component | decision | feature | meeting |
          entity-person | entity-team | entity-external | practice
    status: draft | active | needs-review | superseded | archived
    created: YYYY-MM-DD
    updated: YYYY-MM-DD
    related_systems: []
    ---

`related_systems` is required on every page (use `[]` when none apply).
It is a flat list of system names for the index — not a linking mechanism.

Add these fields when applicable:
    feature_status: in-progress | shipped | cancelled | on-pause     # features only
    component: cel-rules-engine                             # features only
    review_by: YYYY-MM-DD          # docs with no external source (systems,
                                    # components, practices) — mandatory if
                                    # source_last_modified/last_synced below
                                    # don't apply
    source_last_modified:    # docs derived from an external
    last_synced:             # source (ADO, design doc)
    superseded_by: path/to/new-decision.md    # decisions only, once superseded
    related:                 # optional — non-obvious relationships only;
                             # prefer in-prose [[wikilinks]] for normal cross-refs

Meetings also require:
    date: YYYY-MM-DD
    attendees:               # list (structure not schema-validated)
    action_items:            # nested list (structure not schema-validated)

## Naming and linking

- Filenames: kebab-case, unique across the whole wiki (not just within a
folder) — wikilinks resolve by filename, so collisions are ambiguous.
- Feature folders: `{ado-id}-{slug}/`. Create only from an ADO work item or
user-supplied ADO details — never from design docs or other non-ADO sources
alone (see Ingest).
- Decisions: numbered, `000N-short-title.md`, never renumbered or reused.
- Internal cross-references: use in-prose `[[wikilinks]]`. Obsidian’s
backlinks panel and graph derive “what points at this page” from those —
do not maintain a parallel manual link list in frontmatter for that job.
Optional `related:` is only for calling out a non-obvious relationship
that prose alone would miss.
- Links from a wiki page back to a `raw/` source: relative markdown link
(`[label](../../raw/design-docs/...)`), not a wikilink — raw/ is source
material Obsidian doesn't need to graph, and a wikilink there gets you an
orphan-looking node with no real relationship.
- Renaming a wiki page: grep for `[[old-name]]` across wiki/ and update
references — Claude Code file operations don't go through Obsidian's
automatic link updater.



## wiki/index.md

Generated, not hand-maintained. Run `scripts/build-index.sh` to regenerate
from frontmatter across wiki/. Never edit `wiki/index.md` directly — edit the
source page's frontmatter and regenerate. Format: tab-delimited,
columns: path, type, status, feature_status, updated, related_systems.

## wiki/log.md

Hand-maintained, append-only — never edit or delete existing lines.
Tab-delimited: date, action, description. action is one of:
ingest | update | decision | ship | archive | lint. Append one line as
part of every ingest/update/ship/decision/lint workflow.

## Workflows



### Reading any wiki page

Whenever reading a systems/components/practices page with a review_by
date, check if it's passed. If so, mention it before using the page's
content, even outside a formal Lint pass (see Lint below).

### Ingest (new source arrives)

1. Read the source (from `raw/inbox/` or wherever it landed).
2. If it's an ADO work item: cache the raw response under
  `raw/azure-devops/{id}.json` before doing anything else.
3. Discuss what it means with the user before creating or changing anything.
4. Draft the relevant wiki page(s) — updated component, new decision,
  system overview, meeting, etc. — and show the draft. Do not write files
  until approved.
5. On approval: write the file(s), update `wiki/log.md`, regenerate `wiki/index.md` via `scripts/build-index.sh`.

**Features are ADO-gated.** Create or update a `type: feature` page only when
the source is an Azure DevOps work item (cached under `raw/azure-devops/`),
or when the user explicitly supplies ADO details (id, title, state, etc.).
Design docs, transcripts, emails, and other sources may reference a feature,
link to an existing one, or suggest that an ADO item should be ingested next —
they must not create a feature folder on their own.

### Starting work on a feature

1. Check `wiki/index.md` for the feature's current entry and status.
2. Read the feature's `overview.md`, then only the additional files in its
  folder that are actually relevant (design.md, linked decisions, etc.) —
   don't read everything in the folder by default.
3. Read the relevant `components/{x}.md` for current system state.
4. If `source_last_modified` is newer than `last_synced`, or `status` is
  `needs-review`, tell the user before proceeding.



### Completing a feature

1. Update `feature_status: shipped` in the feature's frontmatter.
2. Propose updates to the relevant `components/*.md` reflecting the new
  steady state — this is a revision, not a copy of the feature content.
3. Add a one-line "Touched by" backlink from the component page to the
  feature.
4. Never delete or move the feature folder — it stays as the detailed
  historical record.
5. Confirm all of the above with the user before writing; this is a
  deliberate checkpoint, not something to do mid-session as a side effect
   of code changes.



### Query

1. Read `wiki/index.md` to find relevant pages.
2. Read those pages and synthesize an answer — don't reproduce large
  spans of any single page verbatim.
3. Note the source pages used.
4. If the synthesis is novel and worth keeping, offer to file it back as
  a wiki update rather than letting it live only in chat.



### Lx

