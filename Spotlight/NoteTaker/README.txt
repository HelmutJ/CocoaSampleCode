This is an example Spotlight plugin (importer) that shows how to
import data from a package based file format.  In this case we
publish metadata for the note files saved by the application
NoteTaker.

The import parts of this importer are the changes made to the
Info.plist file.  First, it use the UTImportedTypeDeclarations
instead of UTExportedTypeDeclarations so that if NoteTaker
does declare its own UTI for its file format that it will not
override the one declared in the importer.

Next, the UTTypeConformsTo section shows how you should declare
a file format which is a package.  Getting the type hierarchy
correct is import for your files to display properly in the
Finder and Spotlight search results.

Last, the implementation of GetMetadataForFile() shows how you
can get the information out of a package using the Cocoa api's.

