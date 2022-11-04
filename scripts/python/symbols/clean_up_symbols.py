# -*- coding: utf-8 -*-

### Removes symbol references from the .csv with <style> tag which are not supported by the library
### and .svg files that have no reference

### **********************WARNING*********************
### Make sure to backup the svg assets before running this script.

from util import getScriptDirectory
import os
import shutil
import time
import codecs
import sys

now = time.localtime()
CSV_TO_EDIT_FILE_NAME = "synonyms.csv"
CSV_BACKUP_NAME = f"synonyms-backup-{now.tm_mon}-{now.tm_mday}-{now.tm_hour}_{now.tm_min:02d}.csv"
CSV_DIRECTORY = os.path.join(getScriptDirectory(),"../../../assets/")
SYMBOLS_DIRECTORY = os.path.join(CSV_DIRECTORY, "icons/svg/symbols")
CSV_SEPARATOR = ";"
CSV_FILE_NAME_INDEX = 0


def isValidSvgReference(csvLine):
    fileName = csvLine.split(CSV_SEPARATOR)[CSV_FILE_NAME_INDEX]
    filePath = os.path.join(SYMBOLS_DIRECTORY, fileName)
    with codecs.open(filePath, mode="r", encoding="utf-8") as f:
        content = f.read()
        if "<style>" in content:
            print(f"{filePath} has unsupported <style> element. Removing...")
            return False
    return True


if __name__ == "__main__":
    print("Removing references to unsupported assets:")
    shutil.copy(os.path.join(CSV_DIRECTORY, CSV_TO_EDIT_FILE_NAME), os.path.join(CSV_DIRECTORY, CSV_BACKUP_NAME))
    with codecs.open(os.path.join(CSV_DIRECTORY, CSV_TO_EDIT_FILE_NAME), mode="r", encoding="utf-8") as f:
        lines = f.readlines()
        headerLine = lines.pop(0)
        lines = list(filter(isValidSvgReference, lines)) #ignore header line
    with codecs.open(os.path.join(CSV_DIRECTORY, CSV_TO_EDIT_FILE_NAME), mode="w", encoding="utf-8") as f:
        f.writelines([headerLine] + lines)

    print("Removing unreferenced files:")
    svgAssets = os.listdir(SYMBOLS_DIRECTORY)
    referencedAssets = list(map(lambda line: line.split(CSV_SEPARATOR)[CSV_FILE_NAME_INDEX], lines))
    print(len(svgAssets))
    print(len(referencedAssets))
    for asset in svgAssets:
        if asset not in referencedAssets:
            os.remove(os.path.join(SYMBOLS_DIRECTORY, asset))

    pass
    