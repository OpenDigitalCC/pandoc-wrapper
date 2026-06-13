#!/usr/bin/perl
# tools/make-sbom.pl - generate a CycloneDX 1.6 sbom.json for pandoc-wrapper
# from tools/sbom-config.json. Core-only Perl.
#
# The config curates three groups: `files` (this project's own shipped
# artifacts, hashed here), `bundled` (third-party content vendored/derived in
# the tree), and `dependencies` (external programs and modules required at
# runtime). Re-run after changing what ships.
#
#   tools/make-sbom.pl [--version VER] [--config PATH] [--out PATH]
#
# Copyright (c) 2026 Stuart J Mackintosh <sjm@opendigital.cc>
# SPDX-License-Identifier: BSD-3-Clause
use strict;
use warnings;
use Digest::SHA qw();
use JSON::PP qw();
use POSIX qw(strftime);
use Getopt::Long qw();
use FindBin qw();
use File::Basename qw(basename dirname);

my %opt = ( config => undef, version => undef, out => undef, help => 0 );
Getopt::Long::GetOptions(
    'config=s'  => \$opt{config},
    'version=s' => \$opt{version},
    'out=s'     => \$opt{out},
    'help'      => \$opt{help},
) or die usage();
print usage() and exit 0 if $opt{help};

my $REPO_ROOT = dirname($FindBin::Bin);          # tools/ -> repo root
$opt{config} //= "$REPO_ROOT/tools/sbom-config.json";
$opt{out}    //= "$REPO_ROOT/sbom.json";

exit main();

sub usage {
    return <<'USAGE';
tools/make-sbom.pl - generate CycloneDX 1.6 sbom.json

Options:
    --config PATH   Curated config (default: tools/sbom-config.json)
    --version VER   Override the component version (default: from config)
    --out PATH      Output path (default: sbom.json at repo root)
    --help          Show this help
USAGE
}

sub main {
    my $cfg     = load_json( $opt{config} );
    my $version = $opt{version} // $cfg->{component}{version} // '0.0.0';
    my $sbom    = build_sbom( $cfg, $version );
    write_canonical_json( $opt{out}, $sbom );
    print STDERR "make-sbom: wrote $opt{out} ("
      . scalar( @{ $sbom->{components} } ) . " components)\n";
    return 0;
}

sub build_sbom {
    my ( $cfg, $version ) = @_;
    my $uuid      = gen_uuid_v4();
    my $timestamp = strftime( '%Y-%m-%dT%H:%M:%SZ', gmtime );
    my @components;

    # 1. Own source / shipped files (hashed).
    for my $f ( @{ $cfg->{files} // [] } ) {
        my $full = "$REPO_ROOT/$f->{path}";
        die "make-sbom: missing file $f->{path}\n" unless -f $full;
        my $sha  = Digest::SHA->new(256)->addfile($full)->hexdigest;
        my $purl = 'pkg:generic/opendigital/' . uri_escape_path( $f->{path} ) . '@' . $version;
        my %props = (
            'pandoc-wrapper:category' => 'source',
            'pandoc-wrapper:bucket'   => $f->{bucket} // 'unknown',
            'pandoc-wrapper:path'     => $f->{path},
        );
        $props{'pandoc-wrapper:note'} = $f->{note} if defined $f->{note};
        push @components, {
            type     => 'file',
            name     => basename( $f->{path} ),
            version  => $version,
            hashes   => [ { alg => 'SHA-256', content => $sha } ],
            licenses => [ license_entry( $f->{license} ) ],
            purl     => $purl,
            properties => props_list( \%props ),
        };
    }

    # 2. Bundled / derived third-party content.
    for my $b ( @{ $cfg->{bundled} // [] } ) {
        my %props = ( 'pandoc-wrapper:category' => 'bundled' );
        $props{'pandoc-wrapper:used_by'} = $b->{used_by} if defined $b->{used_by};
        my $entry = {
            type    => 'library',
            'bom-ref' => $b->{purl} // $b->{name},
            name    => $b->{name},
            version => $b->{version} // 'unknown',
            properties => props_list( \%props ),
        };
        $entry->{purl}     = $b->{purl} if defined $b->{purl};
        $entry->{licenses} = [ license_entry( $b->{license} ) ] if defined $b->{license};
        $entry->{externalReferences} = [ { type => 'vcs', url => $b->{url} } ] if defined $b->{url};
        push @components, $entry;
    }

    # 3. External runtime / optional dependencies.
    for my $d ( @{ $cfg->{dependencies} // [] } ) {
        my $is_app = ( ( $d->{name} // '' ) =~ /^(pandoc|evince)$/ ) ? 1 : 0;
        my %props = (
            'pandoc-wrapper:category' => 'dependency',
            'pandoc-wrapper:kind'     => $d->{kind} // 'runtime',
        );
        $props{'pandoc-wrapper:debian_pkg'} = $d->{debian_pkg} if defined $d->{debian_pkg};
        my $entry = {
            type    => $is_app ? 'application' : 'library',
            'bom-ref' => $d->{purl} // $d->{name},
            name    => $d->{name},
            version => 'unknown',
            properties => props_list( \%props ),
        };
        $entry->{purl}        = $d->{purl}        if defined $d->{purl};
        $entry->{description} = $d->{description}  if defined $d->{description};
        $entry->{licenses}    = [ license_entry( $d->{license} ) ] if defined $d->{license};
        push @components, $entry;
    }

    return {
        bomFormat    => 'CycloneDX',
        specVersion  => '1.6',
        serialNumber => "urn:uuid:$uuid",
        version      => 1,
        metadata     => {
            timestamp => $timestamp,
            tools     => [ { name => 'make-sbom.pl', version => $version } ],
            component => {
                type        => 'application',
                name        => $cfg->{component}{name},
                version     => $version,
                description => $cfg->{component}{description},
                licenses    => [ license_entry( $cfg->{component}{license} ) ],
                ( $cfg->{component}{vcs}
                    ? ( externalReferences => [ { type => 'vcs', url => $cfg->{component}{vcs} } ] )
                    : () ),
            },
        },
        components => \@components,
    };
}

# A CycloneDX license entry: SPDX id for a plain id, expression otherwise.
sub license_entry {
    my ($lic) = @_;
    return { license => { name => 'NOASSERTION' } } unless defined $lic && length $lic;
    return { expression => $lic } if $lic =~ /\s(OR|AND|WITH)\s/;
    return { license => { id => $lic } };
}

sub props_list {
    my ($h) = @_;
    return [ map { { name => $_, value => $h->{$_} } } sort keys %$h ];
}

sub load_json {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "Cannot read $path: $!\n";
    my $text = do { local $/; <$fh> };
    close $fh;
    return JSON::PP::decode_json($text);
}

sub write_canonical_json {
    my ( $path, $data ) = @_;
    my $json = JSON::PP->new->utf8(1)->pretty(1)->indent_length(2)->canonical(1)->encode($data);
    open my $fh, '>:raw', $path or die "Cannot write $path: $!\n";
    print $fh $json;
    close $fh or die "Cannot close $path: $!\n";
}

sub gen_uuid_v4 {
    open my $fh, '<:raw', '/dev/urandom' or die "Cannot open /dev/urandom: $!\n";
    my $got = read $fh, my $bytes, 16;
    close $fh;
    die "Short read from /dev/urandom\n" unless defined $got && $got == 16;
    my @b = unpack 'C16', $bytes;
    $b[6] = ( $b[6] & 0x0f ) | 0x40;
    $b[8] = ( $b[8] & 0x3f ) | 0x80;
    return sprintf '%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x', @b;
}

sub uri_escape_path {
    my ($path) = @_;
    $path =~ s/([^A-Za-z0-9\-._~\/])/sprintf('%%%02X', ord($1))/ge;
    return $path;
}
