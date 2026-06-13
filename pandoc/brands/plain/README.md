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
