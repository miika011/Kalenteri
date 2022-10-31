# -*- coding: utf-8 -*-

### This script parses html pages downloaded from synonyymit.fi

import codecs
import re
import os
import glob
import util
from my_csv import *

fileDirectory = "synonym_html"

class Synonym:
    def __init__(self, word, synonyms = [], closestWords = [], relatedWords = []):
        self.word = word
        self.synonyms = synonyms
        self.closestWords = closestWords
        self.relatedWords = relatedWords

class SynonymHtmlFileParser:
    wordPattern = re.compile(r"<title>(.+) synonyymit - Synonyymit.fi</title>")
    genericLineString = r'^<ul class="%s">\n(.+)\n'
    synonymsLinePattern = re.compile(genericLineString %("first"), re.MULTILINE)
    closestWordsLinePattern = re.compile(genericLineString %("sec"), re.MULTILINE)
    relatedWordsLinePattern = re.compile(genericLineString %("rel"), re.MULTILINE)
    allWordsPattern = re.compile(r'(<li><a href=".+?">(.+?)</a></li>)')

    def __matchesToWordList(matches):
        #matches are tuples (<full string>, <actual word>)
        wordList = []
        for match in matches:
            if match[1][-1] != '-': #special cases where word ends with "-" are not useful
                wordList.append(match[1]) 
        return wordList

    def __getMatches(htmlStr, lineRegex):
        lineMatch = lineRegex.search(htmlStr)
        if lineMatch:
            line = lineMatch.group(1)
            matches = SynonymHtmlFileParser.allWordsPattern.findall(line)
            return SynonymHtmlFileParser.__matchesToWordList(matches)
        return []

    def getWord(htmlStr):
        match = SynonymHtmlFileParser.wordPattern.search(htmlStr)
        word = str.lower(match.group(1))
        return word
    
    def getSynonyms(htmlStr):
        return SynonymHtmlFileParser.__getMatches(htmlStr, SynonymHtmlFileParser.synonymsLinePattern)


    def getClosestWords(htmlStr):
        return SynonymHtmlFileParser.__getMatches(htmlStr, SynonymHtmlFileParser.closestWordsLinePattern)

    def getRelatedWords(htmlStr):
        return SynonymHtmlFileParser.__getMatches(htmlStr, SynonymHtmlFileParser.relatedWordsLinePattern)


    def parse(htmlFilePath):
        with codecs.open(htmlFilePath , mode= "r", encoding="utf-8") as f:
            htmlStr = f.read()
            parser = SynonymHtmlFileParser
            word = parser.getWord(htmlStr)
            synonyms = parser.getSynonyms(htmlStr)
            closestWords = parser.getClosestWords(htmlStr)
            relatedWords = parser.getRelatedWords(htmlStr)
            return Synonym(word=word, relatedWords=relatedWords,closestWords=closestWords,synonyms=synonyms)

 

def buildSynonymsDict():
    os.chdir(util.getScriptDirectory())
    synonyms = dict()
    fuckedUp = []
    filePaths = glob.glob(os.path.sep.join([".", fileDirectory, "*.html"]))
    for filePath in filePaths:
        try:
            synonym = SynonymHtmlFileParser.parse(filePath)
            synonyms[synonym.word] = synonym
        except:
            fuckedUp.append(filePath)
            
    if fuckedUp:
        filesFuckedUp = '\n'.join(fuckedUp)
        print(f"Failed to parse files {filesFuckedUp}")
    return synonyms
        


if __name__ == "__main__":
    synonymsDict = buildSynonymsDict()
    
    scriptDirectory = util.getScriptDirectory()
    newCategoriesPath = os.path.join(scriptDirectory, 'kategoriat.csv')
    newCategoriesCsv = Csv(newCategoriesPath)

    translatedSymbolsPath = os.path.join(scriptDirectory, "FinnishSymbolNames.csv")
    translatedSymbolsCsv = Csv(translatedSymbolsPath)

    synonymsExtendedCsv = Csv()

    newHeaders = ["fileName", "synonyms", "closestWords", "relatedWords", "categories"]
    for header in newHeaders:
        synonymsExtendedCsv.addHeader(header)
    
    SYMBOL_EN_INDEX = 1
    SYMBOL_FI_INDEX = 2
    SYMBOL_CATEGORY_INDEX = 3
    for translatedSymbolRow in translatedSymbolsCsv.asRows():
        symbolFileName = translatedSymbolRow[SYMBOL_EN_INDEX] + ".svg"
        symbolTranslation = translatedSymbolRow[SYMBOL_FI_INDEX].lower()
        try:
            synonym = synonymsDict[symbolTranslation]
        except:
            synonym = Synonym(symbolTranslation)
        originalCategory = translatedSymbolRow[SYMBOL_CATEGORY_INDEX]
        try:
            extendedCategoryRowNumber = newCategoriesCsv.dict["original"].index(originalCategory)
            extendedCategories = newCategoriesCsv.dict["split"][extendedCategoryRowNumber]
        except:
            extendedCategories = originalCategory
        synonyms = "&".join([symbolTranslation] + synonym.synonyms)
        closestWords = "&".join(synonym.closestWords)
        relatedWords = "&".join(synonym.relatedWords)
        
        synonymsExtendedCsv.addRow([symbolFileName, synonyms, closestWords, relatedWords, extendedCategories])
    outFile = os.path.join(scriptDirectory,"synonyms.csv")
    synonymsExtendedCsv.writeToFile(outFile)
        
