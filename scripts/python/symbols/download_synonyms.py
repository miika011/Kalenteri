# -*- coding: utf-8 -*-

from downloader import SynonymPageDownloader
import re
import os
import codecs
from my_csv import Csv
from concurrent.futures import ThreadPoolExecutor
import util

outFolder = "synonym_html"
blackList = ["ja", "tai", "ät-merkki"]




if __name__ == "__main__":
    os.chdir(util.getScriptDirectory())
    csv = Csv("FinnishSymbolNames.csv",isLowered=True)
    downloader = SynonymPageDownloader()
    i = 1
    downloaded = 1
    terms = csv.dict["symbol-fi"]
    step = maxWorkers = 8
    sliceStart = 0
    sliceEnd = step
    words = []
    for term in terms:
        for word in term.split():
            if word not in blackList:
                words.append(word)

    # csv.writeToFile("testi.csv")

    with ThreadPoolExecutor(max_workers=maxWorkers) as executor:
        while sliceEnd < len(words) - 1 + step:
            toBeDownloaded = words[sliceStart : sliceEnd]
            futures = {}
            for word in toBeDownloaded:
                future = executor.submit(downloader.downloadPageFor, word, os.path.join(outFolder, f"{word}.html"))
                futures[word] = future
            for futureWord, future in futures.items():
                if future.result():
                    downloaded +=1
                else:
                    print(f"Failed to download: {futureWord}")
            i += step
            print(f"Done: {min(100,round(i / len(words) * 100, 2))}%")
            sliceStart = sliceEnd
            sliceEnd += step