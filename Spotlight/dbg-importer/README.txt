This code sample is a slightly more advanced Spotlight plugin
(importer) that demonstrates the following:

   - defining new attributes in the schema.xml and schema.strings
     files 
   - getting new attributes displayed by the Finder and Spotlight
   - how to publish a multivalued attribute, kMDItemKeywords

The importer publishes metadata from a simple text file format we
created for this example.  The text file format itself is not of
much interest.  The main thrust of this example are the changes
made to the schema.xml and schema.strings files.

Note that schema.strings is a UTF-16 file so you'll need a capable
editor to make changes to it.


   