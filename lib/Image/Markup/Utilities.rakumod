
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
proto from-base64(Str $from, $to = Whatever, :$width = Whatever, :$height = Whatever, |) is export {*}

multi from-base64(Str $b is copy,
                  $to where $to.isa(Whatever) || $to ~~ Str && $to eq 'html' = Whatever,
                  :$width = Whatever,
                  :$height = Whatever,
                  :$alt = Whatever,
                  :$kind is copy = Whatever,
                  Bool :$strip-md = True
        --> Str) is export {

    my $prefix = '<img';
    if $width ~~ Int { $prefix ~= ' width="' ~ $width.Str ~ '"';}
    if $height ~~ Int { $prefix ~= ' height="' ~ $height.Str ~ '"';}
    if $alt ~~ Str { $prefix ~= ' alt="' ~ $alt ~ '"';}
    if $kind.isa(Whatever) || $kind !~~ Str { $kind = 'png'; }

    if $strip-md && ($b ~~ / ^ '![](data:image/' \w*? ';base64,' /) {
        $b = $b.subst(/ ^ '![](data:image/' \w*? ';base64,' /, '').subst( /')' $/, '');
    }

    my $imgStr = $prefix ~ ' src="data:image/' ~ $kind ~ ';base64,$IMGB64">';
    return $imgStr.subst('$IMGB64',$b);
}

#============================================================
# Encode image
#============================================================

our proto sub encode-image($spec, Str :$type= 'jpeg'-->Str) is epxort {*}

multi sub encode-image(Str $spec, Str :$type= 'jpeg'-->Str) {
    if $spec.IO.e {
        return encode-image($spec.IO, :$type);
    }
    my $img = MIME::Base64.encode($spec, :oneline);
    return "data:image/$type;base64,$img";
}

multi sub encode-image(IO::Path $path, Str :$type= 'jpeg'-->Str) {
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

our sub import-image($spec, Str :f(:$format) = 'md-image') is export {

    my $data;
    if $spec ~~ / ^ http s? '://' / {
        my $resp = HTTP::Tiny.get: $spec;
        $data = $resp<content>;
    } elsif $spec.IO.e {
        $data =$spec.IO.slurp(:bin);
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

our proto sub export-image($path, Str $image, Bool :$createonly = False -->Bool) is export {*}

multi sub export-image(Str $path, Str $image, Bool :$createonly = False -->Bool) {
    return export-image($path.IO, $image, :$createonly);
}

multi sub export-image(IO::Path $path, Str $image, Bool :$createonly = False-->Bool) {

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
