# -*- coding: utf-8 -*-

import codecs
import re
import os

class Csv:
    def __init__(self, filePath, isReadImmediately = True, separator = u";", isStripped=True, isLowered = False):
        
        self.dict = dict()
        self.headers = []
        self.columns = []
        self.rows = []
        self.separator = separator
        self.isStripped = isStripped
        self.isLowered = isLowered
        if isReadImmediately:
            self.loadFromFile(filePath)

    def trimmedList(self, l):
        ret = list(l)
        if self.isStripped:
            ret = strippedList(ret)
        return self.isLowered and loweredList(ret) or ret

    def loadFromFile(self, filePath):
        with codecs.open(filePath, mode="r", encoding="utf-8") as f:
            self.headers = self.trimmedList(f.readline().split(self.separator))

            for columnNumber in range(len(self.headers)):
                column = []
                self.columns.append(column)
                self.dict[self.headers[columnNumber]] = column
            while line := f.readline():
                row = self.trimmedList(line.split(self.separator))
                self.rows.append(row)
                for columnNumber in range(len(self.headers)):
                    self.columns[columnNumber].append(row[columnNumber])
    
    def writeToFile(self, outFile):
        with codecs.open(outFile, mode="w", encoding="utf-8") as f:
            f.write(self.separator.join(self.headers) + u"\n")
            for row in self.rows:
                f.write(self.separator.join(row) + u"\n")

    def toString(self):
        ret = self.separator.join(self.headers) + u"\n"
        for row in self.rows:
            ret += self.separator.join(row) + u"\n"
        return ret


    
def strippedList(l):
    return list(map(lambda item: item.strip(), l))

def loweredList(l):
    return list(map(lambda i: i.lower(), l))