* ToSVG - Vimscript to export buffer as SVG

When building documentation, it is sometimes easier to include a picture of source code than some formatted export of the sourcecode; for example, some CMS don't allow to include HTML and CSS directly.

Here it might be useful to use a SVG export - that allows copy/pasting the textual contents, doesn't wrap long lines, and can be scaled without loss of quality.


So, here's a `vim` plugin!


* Usage

On the command line:

```
:TOsvg
```

This will create an SVG export and put it in a new buffer that you can write somewhere.

This can also be used with a line range.


* Configuration

The script includes these settings:

- `g:to_svg_line_spacing` - vertical spacing between lines. `1.0` looks to dense to me, default is `1.1`.
- `g:to_svg_char_spacing` - when zero, just inserts spaces; with a numeric value, used the SVG `dx` value for horizontal space. \\ The best value depends on the font used, I like `0.8`.
- `g:to_svg_font_size` - default is `11`, used in the CSS as a pixel size. Also used to calculate the total dimensions of the viewbox.
- `g:to_svg_background` - default is `transparent`; by setting it to a color, you'll get the SVG's background colored in.

* License

LGPL v2.1; if you change something in this plugin, please tell me about it, eg. via a pull request. Thanks!
(C) 2021 Philipp Marek, see git changelog.


* TODOs

- Optional filename and writing without opening a buffer
- Background color (via `rect`s?)
- Hyperlinks?
