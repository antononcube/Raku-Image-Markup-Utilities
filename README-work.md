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

Import an image and display it:

```perl6, results=asis, output-prompt=NONE, eval=TRUE
use Image::Markup::Utilities;
my $img = image-import($*CWD ~ '/resources/RandomMandala.png', format => 'asis');
image-from-base64($img);
```

**Remark:** GitHub's Markdown renderer does not display the image imported above, 
but other Markdown rendering apps, like, One Markdown or Visual Studio Code do show the image.

**Remark:** If this Markdown file is converted into an HTML file, say, with 
["Markdown::Grammar"](https://raku.land/zef:antononcube/Markdown::Grammar), [AAp3],
the image is seen any browser.

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
[GitHub/antononcube](https://github.com/antononcube/).

[AAp2] Anton Antonov,
[Markdown::Grammar Raku package](https://github.com/antononcube/Raku-Markdown-Grammar),
(2023),
[GitHub/antononcube](https://github.com/antononcube/).

### Videos

[AAv1] Anton Antonov,
["Using Wolfram Engine in Raku sessions"](https://www.youtube.com/watch?v=nWeGkJU3wdM),
(2022),
[YouTube/antononcube](https://www.youtube.com/@AAA4prediction).



