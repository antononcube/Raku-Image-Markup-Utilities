# Image::Markup::Utilities

Raku package for functions that facilitate the import, export, and viewing of images in different Markup types of documents.

## Installation

From GitHub:

```
zef install https://github.com/antononcube/Raku-Image-Markup-Utilities.git
```

From [Zef ecosystem](https://raku.land):

```
zef install Image::Markup::Utilities;
```

-------

## Usage examples

Import an image and display it (in this Markdown file):

```perl6, results=asis, output-prompt=NONE 
use Image::Markup::Utilities;
image-import($*CWD ~ '/resources/RandomMandala.png', format => 'md-image')
```

-------

## Implementation notes

- Initial version of the function `image-from-base64` was implemented in "Text::Plot", [AAp1].
  - In order to streamline the presentation material of the video ["Using Wolfram Engine in Raku sessions"](https://www.youtube.com/watch?v=nWeGkJU3wdM), [AAv1].  
- Initial versions of the functions `image-encode` and `image-export` were implemented in the package "WWW::OpenAI", [AAp2].
  - Now "WWW::OpenAI" depends on this package. 

-------

## References

### Packages

[AAp1] Anton Antonov, 
[Text::Plot Raku package](https://github.com/antononcube/Raku-Text-Plot),
(2022-2023),
[GitHub/antononcube](https://github.com/antononcube/).

[AAp2] Anton Antonov,
[WWW::OpenAI Raku package](https://github.com/antononcube/Raku-WWW-OpenAI),
(2023),
[GitHub/antononcube](https://github.com/antononcube/)

### Videos

[AAv1] Anton Antonov,
["Using Wolfram Engine in Raku sessions"](https://www.youtube.com/watch?v=nWeGkJU3wdM),
(2022),
[YouTube/antononcube](https://www.youtube.com/@AAA4prediction).



