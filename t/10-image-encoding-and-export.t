use v6.d;

use lib '.';
use lib './lib';

use Image::Markup::Utilities;
use Test;

## 1
isa-ok image-encode($*CWD ~ '/resources/RandomMandala.png'), Str:D;

## 2
isa-ok image-import($*CWD ~ '/resources/RandomMandala.png'), Str:D;

## 3
is
        image-import($*CWD ~ '/resources/RandomMandala.png', format => 'base64'),
        image-encode($*CWD ~ '/resources/RandomMandala.png');

## 4
my $img2 = image-import($*CWD ~ '/resources/RandomMandala.png');
my $path4 = $*TMPDIR.child("RandomMandalaExported.png");
is image-export($path4, $img2), $path4;

done-testing;
