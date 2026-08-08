# [Project/Repo Name]

## Context 
This repo's context lives in a separate knowledge repo, not in
this file. Full schema and conventions: $KNOWLEDGE_ROOT/CLAUDE.md
(default $KNOWLEDGE_ROOT: ../engineering-knowledge — adjust if this repo
is checked out elsewhere relative to it).

This repo implements (all or part of): [SYSTEM_NAME]
System overview: $KNOWLEDGE_ROOT/wiki/systems/[system-slug]/overview.md

## Finding a feature
1. Check $KNOWLEDGE_ROOT/wiki/index.md for the feature's entry and status.
   (If it looks stale, regenerate first: scripts/lint.sh from
   $KNOWLEDGE_ROOT.)
2. Read the feature's overview.md:
   $KNOWLEDGE_ROOT/wiki/systems/[system-slug]/features/{ado-id}-{slug}/overview.md
3. Read only the other files in that folder that are actually relevant
   (design.md, linked decisions) — don't read everything by default.
4. If the feature touches a specific component, read its current state:
   $KNOWLEDGE_ROOT/wiki/systems/[system-slug]/components/{component}.md
5. Check linked decisions in
   $KNOWLEDGE_ROOT/wiki/systems/[system-slug]/decisions/ — only the ones
   the feature overview references or that clearly apply.
6. If any page's source_last_modified is newer than last_synced, or its
   status is needs-review or the review_by date has passed, tell me
   before proceeding and summarize what likely changed.

## No feature ID yet?
If I ask you to start work but haven't given you an ADO ID, ask for one
(or the ADO details) before creating anything in the knowledge repo —
features are ADO-gated there; don't scaffold a feature folder without one.

## As you work
This is a strict boundary, not a suggestion: never edit files under
$KNOWLEDGE_ROOT while actively writing or debugging code in this repo.
If you learn something during the session that should be captured — a
decision, a constraint, an open question, something that changes what a
component page says — note it and propose the update at a natural
checkpoint (see below). Don't write to the knowledge repo mid-session.

## At a checkpoint (session end, feature shipped, or I ask)
1. Propose updating feature_status in the feature's overview.md
   frontmatter (in-progress -> shipped, etc.) — wait for my approval.
2. Propose updates to the relevant components/*.md reflecting the new
   steady state — a revision, not a copy of what the feature file says.
3. Propose a one-line "Touched by" backlink from the component page to
   the feature.
4. On my approval: write the changes, then run scripts/lint.sh from
   $KNOWLEDGE_ROOT to revalidate and regenerate the index.
5. Never delete or move a feature folder, completed or not — it's the
   permanent historical record.

## Querying past work
If I ask something like "have we dealt with X before" or "what did we
decide about Y," check $KNOWLEDGE_ROOT/wiki/index.md and the relevant
system's decisions/ and components/ pages before answering from memory —
this repo alone doesn't have that history.