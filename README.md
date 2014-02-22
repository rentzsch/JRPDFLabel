JRPDFLabel is a subclass of NSTextField that makes it easy to use custom fonts in static labels in Interface Builder without having to include the font itself.

It works by rendering certain labels (views whose class is JRPDFLabel (a subclass of NSTextView)) into a .pdf that's included in your app.

Even if the user doesn't have your desired font installed, the custom font's glyph outlines are embedded in the .pdf, allowing subpixel- and Retina-friendly rendering.

## Usage

- Fire up Xcode
- Add JRPDFLabel as a subproject (submodule or [subtree](http://rentzsch.tumblr.com/post/22061209807/apps-i-love-git-subtree))
- Add a label to a view (NSTextField)
- Dial in Font via Attributes inspector (Font panel)
- Change the label's class from `NSTextField` to `JRPDFLabel`
- Run [xib2pdflabels](https://github.com/rentzsch/xib2pdflabels) against the .xib
- Add JRPDFLabel.pdf to your app's resources (one time)

You can automate the generation of the JRPDFLabel.pdf with a Run Script Build Phase, ensuring your PDF labels are always in sync with your xibs.

## TODO

- Add ability to use a different PDF source for the labels instead of just looking for the hard-coded `JRPDFLabel.pdf` in the app's resources.

## Version History

### v1.0.0 (Sat Feb 22 2014)

- Initial release.
