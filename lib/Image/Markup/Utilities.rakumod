use HTTP::Tiny;
use MIME::Base64;

unit module Image::Markup::Utilities;


#===========================================================
# Markup decorations
#===========================================================

#===========================================================
#| Make an HTML image ('<img ...>') spec from a Base64 string.
#| C<$b> : A Base64 string.
#| C<:$width> : Width of the image.
#| C<:$height> : Width of the image.
#| Returns a string.
proto image-from-base64(Str $img-from, $to = Whatever, :$width = Whatever, :$height = Whatever, |) is export {*}

multi image-from-base64(Str $img-from is copy,
                        $to where $to.isa(Whatever) || $to ~~ Str && $to eq 'html' = Whatever,
                        :$width = Whatever,
                        :$height = Whatever,
                        :$alt = Whatever,
                        :$type is copy = Whatever,
                        Bool :$strip = True
        --> Str) is export {

    my $prefix = '<img';
    if $width ~~ Int { $prefix ~= ' width="' ~ $width.Str ~ '"'; }
    if $height ~~ Int { $prefix ~= ' height="' ~ $height.Str ~ '"'; }
    if $alt ~~ Str { $prefix ~= ' alt="' ~ $alt ~ '"'; }
    if $type.isa(Whatever) || $type !~~ Str { $type = 'png'; }

    # Strip Markdown decoration
    if $strip && ($img-from ~~ / ^ '![](data:image/' \w*? ';base64,' /) {
        $img-from = $img-from.subst(/ ^ '![](data:image/' \w*? ';base64,' /).chop;
    }

    # String HTML / WWW-POST decoration
    if $strip && ($img-from ~~ / ^ 'data:image/' \w*? ';base64,' /) {
        $img-from = $img-from.subst(/ ^ 'data:image/' \w*? ';base64,' /);
    }

    my $imgRes = $prefix ~ ' src="data:image/' ~ $type ~ ';base64,$IMGB64">';
    return $imgRes.subst('$IMGB64', $img-from);
}

#============================================================
# Encode image
#============================================================

our proto sub image-encode($spec, Str :$type= 'jpeg'-->Str) is export {*}

multi sub image-encode(Str $spec, Str :$type= 'jpeg'-->Str) {
    if $spec.IO.e {
        return image-encode($spec.IO, :$type);
    }
    my $img = MIME::Base64.encode($spec, :oneline);
    return "data:image/$type;base64,$img";
}

multi sub image-encode(IO::Path $path, Str :$type= 'jpeg'-->Str) {
    if $path.e {
        my $data = $path.IO.slurp(:bin);
        my $img = MIME::Base64.encode($data, :oneline);
        return "data:image/$type;base64,$img";
    } else {
        return Nil;
    }
}

#===========================================================
# Import image
#===========================================================

our sub image-import($spec, Str :f(:$format) = 'md-image') is export {

    my $data;
    if $spec ~~ / ^ http s? '://' / {
        my $resp = HTTP::Tiny.get: $spec;
        $data = $resp<content>;
    } elsif $spec.IO.e {
        $data = $spec.IO.slurp(:bin);
    }

    my $img2 = MIME::Base64.encode($data, :oneline);

    my $img3 = do given $format.lc {
        when $_ ∈ <md-image markdown-image markdown> { "![](data:image/jpeg;base64,$img2)" }
        when $_ ∈ <b64_json base64> { "data:image/jpeg;base64,$img2" }
        default { $img2 }
    }
    return $img3;
}


#============================================================
# Export image
#============================================================

our proto sub image-export($path, Str $image, Bool :$createonly = False -->Bool) is export {*}

multi sub image-export(Str $path, Str $image, Bool :$createonly = False -->Bool) {
    return image-export($path.IO, $image, :$createonly);
}

multi sub image-export(IO::Path $path, Str $image, Bool :$createonly = False-->Bool) {

    my &rg = / ^ '![](data:image/' \w*? ';base64,' /;
    my $img = do if $image ~~ &rg {
        $image.subst(&rg).chop
    } else {
        $image.subst(/ ^ 'data:image/' \w*? ';base64,'/)
    };

    my $data = MIME::Base64.decode($img);

    try {
        my $fh = $path.open(:bin, :w, create => !$createonly);
        $fh.write($data);
        return $fh.close;
    }
    if $! {
        note $!.Str;
        return False;
    }
}
