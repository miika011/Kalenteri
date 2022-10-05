# -*- coding: utf-8 -*-
from operator import le
import util
import os
import shutil

PROJECT_ROOT = os.path.join(util.getScriptDirectory(),"../../..")
os.chdir(PROJECT_ROOT)
PROJECT_ROOT = os.getcwd()

outPath = "./lib/autogen"
if not os.path.isdir(outPath):
    os.makedirs(outPath)




