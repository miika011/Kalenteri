# -*- coding: utf-8 -*-

import codecs
import re
import os

class Csv:
    def __init__(self, inputFilePath = None, isReadImmediately = True, separator = u";", isStripped=True, isLowered = False):
        
        self.dict = dict()
        self.headers = []
        self.data = []
        self.separator = separator
        self.isStripped = isStripped
        self.isLowered = isLowered
        self.inputFilePath = inputFilePath
        if inputFilePath != None and isReadImmediately:
            self.loadFromFile(self.inputFilePath)

    def addHeader(self, header):
        column = list()
        self.headers.append(header)
        self.data.append(column)
        self.dict[header] = column

    def addRow(self, row):
        assert(len(row) == len(self.headers))
        rowIter = iter(row)

        for column in self.data:
            column.append(next(rowIter))

    def trimmedList(self, l):
        ret = list(l)
        if self.isStripped:
            ret = strippedList(ret)
        return self.isLowered and loweredList(ret) or ret

    def loadFromFile(self, filePath = None):
        if filePath:
            self.inputFilePath = filePath

        with codecs.open(self.inputFilePath, mode="r", encoding="utf-8-sig") as f:
            self.headers = self.trimmedList(f.readline().split(self.separator))

            for columnNumber in range(len(self.headers)):
                column = []
                self.data.append(column)
                self.dict[self.headers[columnNumber]] = column
            while line := f.readline():
                row = self.trimmedList(line.split(self.separator))
                for columnNumber in range(len(self.headers)):
                    self.data[columnNumber].append(row[columnNumber])
    
    def writeToFile(self, outFile):
        with codecs.open(outFile, mode="w", encoding="utf-8-sig") as f:
            f.write(self.separator.join(self.headers) + u"\n")
            for row in self.asRows():
                f.write(self.separator.join(row) + u"\n")

    def toString(self):
        ret = self.separator.join(self.headers) + u"\n"
        for row in self.asRows():
            ret += self.separator.join(row) + u"\n"
        return ret
    
    def asRows(self):
        if not self.data:
            return []
        for rowNumber in range(len(self.data[0])):
            yield [self.data[columnNumber][rowNumber] for columnNumber in range(len(self.data))]




    
def strippedList(l):
    return list(map(lambda item: item.strip(), l))

def loweredList(l):
    return list(map(lambda i: i.lower(), l))