#!/usr/bin/env python
# encoding: utf-8
"""
utils.py

Created by Rasmus Andersson on 2007-06-24.
Copyright (c) 2007 Rasmus Andersson. All rights reserved.
"""

def word_wrap(text, width):
    """
    A word-wrap function that preserves existing line breaks
    and most spaces in the text. Expects that existing line
    breaks are posix newlines (\n).
    """
    return reduce(lambda line, word, width=width: '%s%s%s' %
                  (line,
                   ' \n'[(len(line)-line.rfind('\n')-1
                         + len(word.split('\n',1)[0]
                              ) >= width)],
                   word),
                  text.split(' ')
                 )