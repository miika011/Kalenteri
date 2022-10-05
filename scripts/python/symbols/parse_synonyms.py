# -*- coding: utf-8 -*-

### This script parses html pages downloaded from synonyymit.fi

import codecs
import re
import os
import glob
import util

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

if __name__ == "__main__":
    print(util.getScriptDirectory())
    os.chdir(util.getScriptDirectory())
    synonyms = dict()
    synonym = None
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
        

