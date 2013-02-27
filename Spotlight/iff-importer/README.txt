This code sample is a simple Spotlight plug-in (importer) that
publishes metadata for IFF image files.  It shows how to get a
rudimentary importer working and does not do anything except
publish the kMDItemPixelWidth and kMDItemPixelHeight attributes.

The one flaw of this importer is that it reads the entire file
into memory with the NSData method, dataWithContentsOfFile.  A
real image importer would only read the necessary pieces of the
header and/or only read in a fixed size chunk from the start of
the file.  Fortunately IFF images tend to be less than a few megs
in size so this isn't such a problem for this importer.




