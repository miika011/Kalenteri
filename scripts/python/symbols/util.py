# -*- coding: utf-8 -*-
import re
import os

def getScriptDirectory():
    return re.match(r"(^.+%s).+\.py" %(re.escape(os.sep)), __file__).group(1)

