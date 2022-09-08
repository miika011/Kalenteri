# -*- coding: utf-8 -*-

import subprocess
import os
from urllib.parse import quote
from urllib.parse import urljoin

class SynonymPageDownloader:
    def __init__(self):
        self.baseAddress = "https://www.synonyymit.fi/"

    def downloadPageFor(self, searchTerm, outFilePath):
        if os.path.exists(outFilePath):
            # print(rf"{outFilePath} found. Skipping")
            return True
        searchTerm = quote(searchTerm)
        url = self.getSearchUrl(searchTerm)
        return execInShell(f"wget '{url}' -OutFile '{outFilePath}'")

    def getSearchUrl(self, searchTerm):
        return urljoin(self.baseAddress, searchTerm)

def execInShell(command):
    shellCmd = rf'powershell -Command "{command}"'
    # print("EXECUTING " + shellCmd)
    p = subprocess.Popen(shellCmd, shell=True,stderr=subprocess.DEVNULL)
    return p.wait() == 0