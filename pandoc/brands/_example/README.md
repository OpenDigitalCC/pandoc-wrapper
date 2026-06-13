# Example brand (scaffold)

Copy this folder to create a new brand:

```bash
cp -r _example my-brand
# edit my-brand/template.yaml
```

Then reference it from a document's front matter:

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

The build adds this folder to the asset search path
(`--resource-path` for Markdown images, `TEXINPUTS` for LaTeX graphics),
so reference assets by **bare filename** - `logo.png`, not an absolute
path. Keeping assets in the folder makes the brand self-contained and
portable: it can live in its own repo or package.

## Adding title pages and logos

The asset lines in `template.yaml` are commented out so the brand renders
before you add any image. Once you drop files in:

- Logo on the generated title page: add `logo.png`, then uncomment
  `titlepage-logo: logo.png` (and adjust `logo-width`).
- Full-page PDF/image cover: add `cover.pdf`, then uncomment
  `titlepage-background: cover.pdf`. This replaces the generated layout
  with your artwork.

## Where brands live

Brands are user data and live in a base folder **outside** the tool's
repository, set by the config file
(`~/.config/pandoc-wrapper/config`):

```ini
brands_dir = /path/to/your/brands
```

Resolution order: `MD_TO_PDF_BRANDS` env var, then `brands_dir` from the
config, then the bundled defaults shipped with the tool. So you can keep
brands in a synced or shared location and manage them independently.

`plain` and this `_example` scaffold are the only brands bundled with the
tool (the always-available fallback). Organisation brands live in their
own base/repo - on this host, `/srv/projects/pandoc-brands/`.

## What belongs in a brand (and what does not)

In a brand: colours, fonts, heading colours, title-page settings,
identity, layout, and assets.

Not in a brand: package loads or table/box/chart support - those are
provided by `pipeline-preamble.tex` through the template. Re-adding them
here risks option clashes. See `documentation/TEMPLATE-CONTRACT.md`.
