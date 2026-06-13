---
title: "pandoc-wrapper Maturation Plan"
subtitle: "Templates, installation, packaging, and document versioning"
brand: plain
date: 13 June 2026
---

# Purpose

The pipeline has outgrown its origins as a personal wrapper. Other people want
to use it, which raises three questions this document answers, each grounded in
what was measured and prototyped in the repository:

- How should the templates be structured - what is common, should there be a shim over Eisvogel, and what must every template guarantee?
- How should it be installed (per-user and system-wide), and can it be packaged as a `.deb` / `.rpm`?
- Where should document version information live, ported from the old `compile.sh`?

Two supporting artifacts were built and tested while writing this:
`pipeline-preamble.tex`, `mvp.latex`, `conformance-test.md`, `TEMPLATE-CONTRACT.md`,
and `scripts/install.sh`.

# Template architecture

## What is actually common

Measuring the nine brand files settles the "what should be common" question. Of
roughly 22 `header-includes` lines per brand, **19 are byte-identical across all
nine brands** - the entire package-load block (`fontawesome5`, `sourcesanspro`,
`sourcecodepro`, `tabularx`, `longtable,booktabs,colortbl`, `pgfplots`,
`pgf-pie`, `wrapfig`, `microtype`, `parskip`, `xcolor`) plus structural settings
(`\tolerance`, `\hyphenpenalty`, `\setkeys{Gin}`, `\pgfplotsset`, table spacing).

Only three things genuinely vary per brand:

- heading colours - `\addtokomafont{section}{\color{<brand-colour>}}` and similar;
- a couple of font choices (one brand uses `sourceserifpro`);
- occasional spacing tweaks (`arraystretch`).

In other words the brands are about 85% duplicated boilerplate. That boilerplate
is the source of drift: the dead `\usepackage{markdown}` line removed this session
existed in all nine because each was hand-maintained.

## The coupling problem

The Lua filter emits raw LaTeX for boxes (`tcolorbox`), datatables
(`longtable`/`multirow`/`colortbl`) and charts (`tikz`/`pgfplots`/`pgf-pie`). The
packages those rely on are loaded inconsistently: some by every brand's
`header-includes`, `tcolorbox` only by the Eisvogel template, and `multirow` (until
this session) by nobody. That is why a row span failed with exit code 43 and why
swapping to a template that does not load `tcolorbox` would silently break every
box. Feature packages must not live in templates or be duplicated across brands.

## Recommended structure: three layers

base template
: Look only - geometry, title page, headers/footers, sectioning. Swappable.

pipeline preamble (the shim)
: `pipeline-preamble.tex`, created this session. Carries every package the filter
  needs plus generic settings, with no template- or KOMA-specific commands. This
  is the "interim shim" the brief asks about: it lets a stock base template be
  used unchanged, with the pipeline's requirements layered on top via `\input`
  (the wrapper now puts the templates directory on `TEXINPUTS`) rather than by
  forking the template.

brand
: Identity only - colours, fonts, logo, heading colours.

This was validated: `mvp.latex` (pandoc's default template plus an `\input` of the
preamble) renders the full `conformance-test.md` - boxes, a row-span datatable,
pie and bar charts, a citation - with a colour-only brand and zero Eisvogel
coupling. See `TEMPLATE-CONTRACT.md` for the formal contract and the conformance
procedure.

## On Eisvogel: vendor it, don't fork it

The repository currently carries three ~1000-1500 line Eisvogel forks
(`eisvogel.latex`, `report.latex`, `eisvogel-reorganized.latex`) plus a
`template-multi-file/` split. Maintaining forks means every upstream Eisvogel
release has to be re-merged by hand.

::: recommendation
Treat Eisvogel as a vendored dependency: keep one pristine copy under a clear
version tag, and express all local customisation as the pipeline preamble plus
brand header-includes layered on top. Pick `eisvogel-reorganized.latex` as the
single supported Eisvogel-based template, archive the other two, and record the
upstream version it derives from.
:::

## Additional base templates and the contract

New base templates (selected per brand, overridable per document) are expected.
To keep them interchangeable they must meet a defined contract:

- honour the `header-includes` injection point;
- pull in `pipeline-preamble.tex`;
- consume the core pandoc variables (title, toc, body, documentclass, title page, headers/footers);
- use a KOMA class for full brand heading-colour support;
- pass `conformance-test.md`.

`TEMPLATE-CONTRACT.md` is the authority. `mvp.latex` is the minimal reference
implementation and the recommended starting point for new templates - including
the "very simple MVP as a test and basis" the brief asks for, which now exists
and passes.

## Migration sequence for brands

1. Move the 19 common lines out of every brand into `pipeline-preamble.tex` (done as an artifact; brands still duplicate them - the next step removes that).
2. Strip those lines from each brand, leaving only colours, fonts, identity, and heading colours.
3. Optionally auto-generate the heading-colour `\addtokomafont` lines from a brand convention, exactly as `\definecolor` lines are already auto-generated by the filter - which would shrink a brand to little more than its palette.
4. Move `tcolorbox`/`needspace` and the other feature packages fully into the preamble (and consider having the filter inject them, closing the bug class for good).
5. Re-run the conformance test per brand.

# Installation

`scripts/install.sh` was written and tested this session. It uses one FHS-style
layout for both scopes, so the wrapper locates its own assets relatively with no
environment variables:

```text
<prefix>/bin/md-to-pdf
<prefix>/lib/md-to-pdf/extract-frontmatter.pl
<prefix>/share/pandoc-wrapper/templates/   (*.latex *.tex *.lua)
<prefix>/share/pandoc-wrapper/brands/      (*.yaml)
```

per-user
: `prefix = ~/.local` (the default). Binary on the user's `PATH` at
  `~/.local/bin`, assets under `~/.local/share`. No root needed. This matches the
  XDG base-directory convention and is the right default for "just me".

system-wide
: `--system` uses `prefix = /usr/local` (or `--prefix /opt/...`). Identical shape,
  so the same resolution logic works. `/usr/local` for manual installs;
  `/usr` is reserved for the distribution package below.

The driver was updated to support this: it resolves assets from a co-located
`../share/pandoc-wrapper` tree, then falls back to `~/.pandoc`, and honours
`MD_TO_PDF_TEMPLATES` / `MD_TO_PDF_BRANDS` / `MD_TO_PDF_VIEWER` overrides. Tested:
installing into a throwaway prefix and running the installed binary builds a
branded PDF with no environment set.

## Per-user assets vs the legacy `~/.pandoc`

The original layout put templates and brands in `~/.pandoc`. That is fine but
non-standard. The installer instead uses `~/.local/share/pandoc-wrapper`; the
driver still falls back to `~/.pandoc` so existing setups keep working. New
installs should prefer the XDG path.

# Packaging

The pipeline is very packageable - it is a script, a Perl helper, and data
files, with external dependencies that are all already distribution packages.

## Debian `.deb` (primary, this host is Debian)

Layout maps cleanly onto a package built with `debhelper`/`dpkg-buildpackage`:

```text
/usr/bin/md-to-pdf
/usr/lib/md-to-pdf/extract-frontmatter.pl
/usr/share/pandoc-wrapper/templates/...
/usr/share/pandoc-wrapper/brands/...
/usr/share/doc/pandoc-wrapper/...
```

Dependencies expressed in `debian/control`:

```text
Depends: pandoc, texlive-xetex, texlive-latex-recommended (KOMA-Script),
         texlive-latex-extra (tcolorbox, pgf, multirow, ...),
         texlive-fonts-extra (fontawesome5, source* fonts),
         libyaml-libyaml-perl, perl, bash, fonts-open-sans
Recommends: evince
```

Build with `debhelper-compat`, no compilation step (arch: all). This is the
recommended distribution path: it also documents the exact TeX Live dependency
set that has been discovered piecemeal this week.

## RPM (secondary)

Straightforward with an analogous `.spec`: same file layout under the same
prefixes, with `Requires:` naming the Fedora/openSUSE TeX Live sub-packages
(`texlive-tcolorbox`, `texlive-pgf`, `texlive-multirow`, `texlive-fontawesome5`,
`perl-YAML-LibYAML`). Worth doing only when there is an actual RPM-based user;
the `.deb` and the `install.sh` cover the current audience.

## Portability notes

The hard dependency is a working TeX Live with XeLaTeX and the listed packages.
The pipeline itself is portable Bash + Perl. Keep `install.sh` as the
zero-packaging fallback for users on other distributions.

# Document versioning

## What `compile.sh` did

The original `compile.sh` (now under `experiments/`) had a neat scheme: it stored
a version in a `DOC.VER` sidecar and the last content hash in `content.md5`,
both next to the source. On each build it hashed the concatenated Markdown; if the
hash changed it bumped the patch component and stamped the document with today's
date, otherwise it reused the stored version and date. The version then appeared
on the page, never in the source.

That last property is the one to preserve: the version relates to the content but
is not written back into the source Markdown.

## The storage question

The brief's constraints are: do not modify the source Markdown, and cope with
sources that may not be local (a URL, or multiple fragments). Sidecar files next
to the source satisfy the first constraint but fail the second. So the version
store must be keyed by a *document identity* that is stable across edits and
independent of where the source lives.

::: recommendation
Keep a central version registry, keyed by document identity, and inject the
resolved version into the build as metadata - never back into the source.
:::

Recommended design:

document identity
: In priority order: an explicit `docid:` in the front matter (author-written
  once, stable across title changes, ignored by rendering); else a slug derived
  from `title` (+`subtitle`); else the source path or URL. Deriving from the title
  means renaming the document starts a new lineage - acceptable, and warned about.

store location
: `${XDG_STATE_HOME:-~/.local/state}/pandoc-wrapper/versions.json` (state, not
  config or cache: it is regenerable-ish but meaningful to keep). One entry per
  identity: `{ version, last_sha256, last_dated, updated_at }`. JSON is enough;
  SQLite only if concurrency or history matter.

change detection
: Hash the concatenated *document* sources (before the brand is merged and before
  the date is injected, so a brand tweak or a rebuild on a new day does not bump
  the version). Compare to `last_sha256`.

bump policy
: On change, increment the last component and set the document date to today;
  on no change, reuse the stored version and date. Major/minor stay manual - via
  a front-matter `version:` to pin, or a `--release` flag to bump intentionally.

injection
: Pass the resolved version to pandoc as `--metadata revision=<v>` (and a
  `revision-date`), consumed by the template's title page or footer. The source
  Markdown is never rewritten, which keeps it clean for editing and works for
  non-local sources.

local/git workflows
: Offer an opt-in sidecar mode (`version-store: sidecar`, or `--version-sidecar`)
  that writes `DOC.VER`/`.md5` next to a local source for teams who want the
  version tracked in git beside the document. Same engine, different backend.

This keeps the good idea from `compile.sh`, removes its local-only and
directory-keyed limitations, and honours "do not touch the source".

# Suggested sequence

1. Land the template layering: finish moving common lines into `pipeline-preamble.tex` and slim the brands (template section above). Re-run conformance per brand.
2. Adopt `install.sh` as the supported install; write the `debian/` packaging using the documented dependency set.
3. Implement versioning as a small `scripts/version.pl` (registry + hash + bump) called by `md-to-pdf.sh`, injecting `--metadata revision`.
4. Pick one Eisvogel-based template, archive the rest, and record the upstream version.
5. Add the automated tests noted in `RECOMMENDATIONS.md` around the pure-logic functions (filename generation, the new front-matter registry, version bumping).
