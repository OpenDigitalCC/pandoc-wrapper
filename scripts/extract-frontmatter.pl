#!/usr/bin/perl
# extract-frontmatter.pl - robust YAML front-matter reader for md-to-pdf.sh
#
# Reads a document (or a bare YAML block) on STDIN, parses the FIRST YAML
# front-matter block, and prints the requested top-level scalar fields as
# NUL-delimited "key=value" records on STDOUT. Values may contain newlines and
# '=' characters; the NUL record separator keeps them unambiguous for the shell.
#
# Usage:
#   extract-frontmatter.pl title subtitle brand date < document.md
#
# Each requested key that is present and scalar yields one record:
#   key=value\0
# Missing keys are simply omitted (the caller keeps its default).
#
# Why a real parser: the previous awk/sed/tr/xargs pipeline could not handle
# quoted colons, multi-line scalars, or distinguish front matter from YAML shown
# inside fenced code blocks. YAML::XS handles all of that correctly.

use strict;
use warnings;

# YAML::XS is the host-standard parser (libyaml-backed). Fail loudly and
# usefully if it is somehow absent rather than producing silent garbage.
my $have_yaml = eval { require YAML::XS; YAML::XS->import('Load'); 1 };
unless ($have_yaml) {
    print STDERR "extract-frontmatter.pl: YAML::XS not available - install libyaml-libyaml-perl\n";
    exit 3;
}

# Represent YAML booleans as JSON::PP::Boolean objects so we can tell a genuine
# boolean (printready: true) from the string "true" or the number 1, and emit a
# canonical lexical "true"/"false" that downstream string comparisons expect.
# Without this, libyaml coerces YAML 1.1 booleans to 1 / "" (empty).
no warnings 'once';
local $YAML::XS::Boolean = "JSON::PP";
use warnings 'once';

my @wanted = @ARGV;

# Slurp STDIN.
local $/;
my $text = <STDIN>;
$text = '' unless defined $text;

# Isolate the first front-matter block: a line of exactly --- (optionally with a
# leading BOM/whitespace) opening it, and a line of --- or ... closing it. If the
# document does not start with a front-matter fence, treat the whole input as
# YAML (callers sometimes pass a bare block).
my $yaml;
if ($text =~ /\A\x{feff}?\s*^---\s*$(.*?)^(?:---|\.\.\.)\s*$/ms) {
    $yaml = $1;
} else {
    $yaml = $text;
}

my $data = eval { YAML::XS::Load($yaml) };
if (!defined $data || ref $data ne 'HASH') {
    # Not a mapping (empty, malformed, or a list) - nothing to extract.
    exit 0;
}

binmode STDOUT;
for my $key (@wanted) {
    next unless exists $data->{$key};
    my $val = $data->{$key};
    if (ref $val eq 'JSON::PP::Boolean') {
        # Canonical lexical form so `[[ $x == "true" ]]` still works.
        $val = $val ? 'true' : 'false';
    } elsif (ref $val) {
        # Nested structure (list/map): consumed by pandoc / the Lua filter from
        # the document stream, not as a shell variable. Skip.
        next;
    }
    $val = '' unless defined $val;
    print $key, '=', $val, "\0";
}
exit 0;
