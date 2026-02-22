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

our proto sub image-export($path, Str $image, Bool :$createonly = False) is export {*}

multi sub image-export(Str $path, Str $image, Bool :$createonly = False) {
    return image-export($path.IO, $image, :$createonly);
}

multi sub image-export(IO::Path $path, Str $image, Bool :$createonly = False) {

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
        $fh.close;
        return $path.Str;
    }
    if $! {
        note $!.Str;
        return Nil;
    }
}

#===========================================================
# List-animate (generic)
#===========================================================

our proto sub list-animate(@imgs, *%args) is export {*}

multi sub list-animate(@imgs where @imgs.all ~~ Str:D, *%args) {
    return list-animate-svg(@imgs, |%args);
}

#===========================================================
# List-animate (SVG)
#===========================================================

our sub list-animate-svg(@svgs,
                         :$duration = Whatever,
                         :$delay = Whatever,
                         :$fps = Whatever,
                         :$repeat-count = '1',
                         :$fill = 'freeze',
                         :$width = Whatever,
                         :$height = Whatever,
                         :$id = 'animatedImage',
                         :$graph-id-prefix = 'graph'
        --> Str) is export {

    my @items = @svgs.grep(*.defined);

    note 'No images found.' if @items.elems == 0;
    return Nil if @items.elems == 0;

    my $first = @items[0];
    my $view = do with ($first ~~ / 'viewBox="' .*? '"' /) { $/.Str } else { '' };
    my $orig-width = do with ($first ~~ / 'width="' .*? '"' /) { $/.Str } else { '' };
    my $orig-height = do with ($first ~~ / 'height="' .*? '"' /) { $/.Str } else { '' };

    my $width-attr = do given $width {
        when $_.isa(Whatever) { $orig-width.chars ?? $orig-width !! '' }
        when $_ ~~ Str:D || $_ ~~ Numeric:D { 'width="' ~ $_.Str ~ '"' }
        default {
            die 'The value of $width is expected to be string, a number or Whatever'
        }
    }

    my $height-attr = do given $height {
        when $_.isa(Whatever) { $orig-height.chars ?? $orig-height !! '' }
        when $_ ~~ Str:D || $_ ~~ Numeric:D { 'height="' ~ $_.Str ~ '"' }
        default {
            die 'The value of $height is expected to be string, a number or Whatever'
        }
    }

    my @defs;
    for @items.kv -> $i, $svg {
        my $g = do if $svg ~~ / ('<g' \s+ 'id="' <-["]>+ '"' .* '</g>') / { $0.Str }
        else { Nil };
        next unless $g.defined;

        my $gid = $graph-id-prefix ~ ($i + 1).Str;
        $g = $g.subst(/ 'id="' <-["]>+ '"' /, "id=\"$gid\"");
        @defs.push: $g;
    }

    note 'No definitions found.' if @defs.elems == 0;
    return Nil if @defs.elems == 0;

    my $n = @defs.elems;
    my $dur = do if $duration.defined && $duration !~~ Whatever {
        $duration ~~ Str ?? $duration !! ($duration.Str ~ 's')
    } else {
        my $delay-sec = do if $delay.defined && $delay !~~ Whatever {
            $delay
        } elsif $fps.defined && $fps !~~ Whatever {
            1 / $fps
        } else {
            1
        };
        ($delay-sec * $n).Str ~ 's'
    };

    my $values = (1..$n).map({ "#{$graph-id-prefix}{$_}" }).join(';');
    my $first-id = "#{$graph-id-prefix}1";

    my @attrs = ('xmlns="http://www.w3.org/2000/svg"');
    @attrs.push: $width-attr if $width-attr.chars;
    @attrs.push: $height-attr if $height-attr.chars;
    @attrs.push: $view if $view.chars;

    return Q:c:s:to/END/;
<svg {@attrs.join(' ')}>
  <defs>
    {@defs.join("\n")}
  </defs>

  <use href="$first-id" id="$id">
    <animate attributeName="href" values="$values" dur="$dur" repeatCount="$repeat-count" fill="$fill"/>
  </use>
</svg>
END
}