#!/usr/bin/env python3
# Legal/open-access downloader skeleton. It will not bypass paywalls.
# Usage: python download_open_access_reference_pdfs_v44.py all_cited_references_manifest_v44_20260516_1905.csv downloaded_pdfs
import csv, pathlib, sys, urllib.request, os, re
manifest=sys.argv[1]; out=pathlib.Path(sys.argv[2] if len(sys.argv)>2 else 'downloaded_pdfs'); out.mkdir(exist_ok=True, parents=True)
print('Use DOI URLs and publisher/Unpaywall manually or extend this script with an Unpaywall email. Manifest:', manifest)
