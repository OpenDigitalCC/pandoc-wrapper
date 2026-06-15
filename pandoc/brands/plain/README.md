# plain - the default brand (and the one to copy)

`plain` is the default brand and the reference for new ones. It ships bundled
with the tool, so it is always available as a fallback.

## Make a new brand

```bash
cp -r plain my-brand          # in your brands base (not the tool repo)
# edit my-brand/template.yaml: colours, fonts, identity, title-page logo/cover
```

Reference it from a document:

```yaml
brand: my-brand
```

## Brand folder layout

```
my-brand/
├── template.yaml     the brand config (required)
├── logo.png          title-page logo            (optional)
├── cover.pdf         full-page cover/title page (optional)
├── letter-logo.png   letterhead logo            (optional, letters)
├── letterhead.pdf    full-page letterhead art   (optional, letters)
├── filter.lua        brand-specific Lua filter  (optional)
└── ... any other assets referenced by template.yaml
```

The build adds the brand folder to the asset search path (`--resource-path`
for Markdown images, `TEXINPUTS` for LaTeX graphics), so reference assets by
**bare filename** - `logo.png`, not an absolute path. This keeps a brand
self-contained and portable: it can live in its own repo or package.

## Adding title pages and logos

The asset lines in `template.yaml` are commented out so a brand renders before
you add any image. Once you drop files in:

- Logo on the generated title page: add `logo.png`, uncomment `titlepage-logo`.
- Full-page PDF/image cover: add `cover.pdf`, uncomment `titlepage-background`
  (this replaces the generated layout with your artwork).

## Letters and slides

The same brand styles all three output formats (report, letter, slides). Most
brand settings - colours, fonts, heading colours - apply everywhere. Two formats
have a few extra, optional brand keys.

### Slides (`template: beamer` or `template: slides`)

Wire the brand palette into the slide colours by naming two of your
`brand-colours` (the plain brand does this):

```yaml
beamer-structure: plain-charcoal   # structure, palette, title, frametitle
beamer-accent: plain-accent        # block titles, head/foot subsection
```

These two keys drive **both** slide formats:

- **Beamer** (`template: beamer`): they map onto the beamer palette. A deck still
  controls its own beamer `theme` / `colortheme`, and anything it sets in
  `header-includes` overrides the brand. Leave both out and slides fall back to
  the chosen beamer theme.
- **Modern** (`template: slides`): `beamer-structure` is the title/dark
  full-bleed ground and `beamer-accent` the rule/accent ground. A deck can
  override per-document with `slide-title-bg` / `slide-accent`.

### Letters (`template: letter`)

Letters inherit the brand fonts and colours automatically. A brand can also
supply letterhead defaults so every letter is on-brand without per-document
settings - drop the assets into the brand folder and add:

```yaml
# Built letterhead (logo top-right + ruled contact footer):
letterhead-logo: letter-logo.png
letterhead-company: "Your Organisation Ltd"
letterhead-contact:
  - "1 High Street, Town AB1 2CD"
  - "hello@example.org"
letterhead-rule-colour: plain-accent   # a brand-colour name
# Statutory footer line (constant per company, so set it here):
letterhead-tel: "+44 161 000 0000"
letterhead-reg-number: "12345678"
letterhead-vat: "GB 123 4567 89"
# Stylised divider instead of the plain rule (optional):
# letterhead-rule-image: footer-rule.png
# ...or a single full-page artwork instead of all the above:
# letterhead: letterhead.pdf
```

A document can still override or add any of these. See the authoring guide's
**Letters** and **Slides** sections for the full field lists.

## Where brands live

Brands are user data, kept in a base folder **outside** the tool, set by the
config file (`~/.config/pandoc-wrapper/config`):

```ini
brands_dir = /path/to/your/brands
```

Resolution: `MD_TO_PDF_BRANDS` env var, then `brands_dir` from the config, then
the bundled defaults shipped with the tool. `plain` is the only bundled brand;
organisation brands live in their own base/repo and are managed separately.

## What belongs in a brand (and what does not)

In a brand: colours, fonts, heading colours, title-page settings, identity,
layout, and assets.

Not in a brand: package loads or table/box/chart support - those come from
`pipeline-preamble.tex` via the template. Re-adding them risks option clashes.
See `documentation/TEMPLATE-CONTRACT.md`.
