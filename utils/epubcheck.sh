#!/bin/bash

MIX_ENV=docs mix deps.update ex_doc_epub
MIX_ENV=docs mix deps.compile
MIX_ENV=docs mix docs.epub
cd doc
zip -0Xq ecto.epub mimetype
zip -Xr9Dq ecto.epub *
java -jar ../epubcheck-3.0.1/epubcheck-3.0.1.jar ecto.epub
