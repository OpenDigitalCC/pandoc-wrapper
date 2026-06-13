# Skills: pandoc-markdown

Two packagings of one capability — making Claude write Markdown in this
pipeline's house format so generated documents render cleanly to PDF.

```
skills/
├── claude-code/pandoc-markdown/   installed into a Claude Code skills dir
│   ├── SKILL.md
│   └── REFERENCE.md
└── claude-ai/pandoc-markdown/     uploaded to claude.ai as a Skill
    ├── SKILL.md
    └── REFERENCE.md
```

Both share the same rules. They differ only in framing: the Claude Code variant
can invoke `md-to-pdf.sh` and points at repo paths; the claude.ai variant is
self-contained (the user compiles the result themselves).

## Install the Claude Code skill

Copy the folder into a skills directory Claude Code reads:

Personal (all projects, this machine):

```bash
mkdir -p ~/.claude/skills
cp -r pandoc/skills/claude-code/pandoc-markdown ~/.claude/skills/
```

Project-scoped (checked in, shared with collaborators) instead:

```bash
mkdir -p .claude/skills
cp -r pandoc/skills/claude-code/pandoc-markdown .claude/skills/
```

Claude Code discovers `SKILL.md` files under those directories automatically and
loads the skill when a task matches its `description`. No restart logic beyond
starting a new session.

## Upload the claude.ai skill

1. Zip the folder: `cd pandoc/skills/claude-ai && zip -r pandoc-markdown.zip pandoc-markdown`
   (a prebuilt `pandoc-markdown.zip` is committed alongside).
2. In claude.ai, open Settings → Capabilities (Skills) → add a custom skill and
   upload the zip.
3. The skill activates when you ask for a report, brief, policy document, or any
   Markdown destined for this PDF pipeline.

## Keeping them in sync

When the document format changes (a new box type, a new datatable option), update
`SKILL.md`/`REFERENCE.md` in both variants and the source guides under
`pandoc/documentation/`. The two skill variants are intentionally near-identical;
diff them after edits to keep them aligned.
