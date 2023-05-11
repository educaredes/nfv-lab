#!/bin/bash
pandoc -f gfm -c bin/github-pandoc.css -t docx RDSV-p4.md > RDSV-p4.docx
