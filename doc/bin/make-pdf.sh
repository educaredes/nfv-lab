#!/bin/bash
pandoc -f gfm -c github-pandoc.css -t context sdw-p2.md -o sdw-p2.pdf
