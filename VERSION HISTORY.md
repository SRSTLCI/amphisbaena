# Version History

## Version 0.15
* Word Links files have been updated to a new format. New file format is used where wordLink elements contain a list of their facs and guids with a copy of their index occurrence and original text. This format is acknowledged as version 0.2.
* Support for importing the old version of the Word Link file format (retroactively named version 0.1) has been added, including dialog boxes to aid in conversion from 0.1 to 0.2.
* Added confirmation dialog when generating new Word Links that you may overwrite your settings.
* Changed label to open Word Links Editor from “Generate…” to “Edit…”
* Made Word Links Editor resizable.
* Table in Word Links now resizes cells to show the full contents of a word link.
* Word Links Editor UI is rearranged:
    * “Combine Selected to FLEx” is renamed to “Combine to FLEx”
    * “Combine Selected to Transkribus” is renamed to “Combine to Transkribus”
    * Buttons are rearranged and labeled with their key command.
    * New command “Insert Empty FLEx”
    * A Word Link missing a FLEx guid will cause a strikethrough to appear on the Transkribus facs and content.
* Support for additional TEI tags have been added for the goals of the Wóoyake project.
* Unified files are constructed differently for the specification of the Wóoyake project.

## Version 0.1
* Initial commit to GitHub.
