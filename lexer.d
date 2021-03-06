/*
Copyright (c) 2011-2014 Timur Gafarov 

Boost Software License - Version 1.0 - August 17th, 2003

Permission is hereby granted, free of charge, to any person or organization
obtaining a copy of the software and accompanying documentation covered by
this license (the "Software") to use, reproduce, display, distribute,
execute, and transmit the Software, and to prepare derivative works of the
Software, and to permit third-parties to whom the Software is furnished to
do so, all subject to the following:

The copyright notices in the Software and this entire statement, including
the above license grant, this restriction and the following disclaimer,
must be included in all copies of the Software, in whole or in part, and
all derivative works of the Software, unless such copies or derivative
works are solely in the form of machine-executable object code generated by
a source language processor.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
*/

module lexer;

import std.string;
import std.ascii;
import std.conv;
import std.algorithm;

static string[] stddelimiters = 
[
    "==","!=","<=",">=","+=","-=","*=","/=",
    "++","--","||","&&","<<",">>","<>",
    "//","/*","*/","\\\\","\\\"","\\\'",
    "+","-","*","/","%","=","|","^","~","<",">","!",
    "(",")","{","}","[","]",
    ";",":",",","@","#","$","&",
    "\\","\"","\'"
];

/* 
 * Helper functions
 */

bool matches(T)(T input, T[] list)
{
    foreach(v; list)
        if (input==to!T(v)) return true;
    return false;
}

bool isWhitespace(string input)
{
    if (input.length==0) return false;
    else if (matches(input[0], std.ascii.whitespace)) return true;
    return false;
}

/* 
 * General-purpose lexical analyther
 */

final class Lexer
{
   private:
    string source;
    int pos = 0;
    string[] delimiters;
	
   public:
    string singleLineComment = "//";
    string multiLineCommentBegin = "/*";
    string multiLineCommentEnd = "*/";
    string[] stringLiteralQuote = ["\"","\'"];

    string current;

    uint line = 1;
    uint lastTokenLine = 0;
    bool noTokensOnCurrentLine = true;
	
    this(string src)
    {
        source = src;
    }

    void addDelimiter(string op)
    {
        delimiters ~= op;
        sort!("a.length > b.length")(delimiters);
    }

    void addDelimiters(string[] op = stddelimiters)
    {
        delimiters ~= op;
        sort!("a.length > b.length")(delimiters);
    }

    void readNext()
    {
        current = getLexeme();
    }

    string getLexeme()
    {
        string result;
        bool commentSingleLine = false;
        bool commentMultiLine = false;
        bool stringLiteral = false;
        string tempStringLiteral = "";
        bool satisfied = false;

        while(!satisfied)
        {
            string lexeme = getLexemeUnfiltered();
            if (!lexeme) satisfied = true;
            else if (lexeme == "\n") 
            { 
                if (!commentMultiLine)
                {
                    if (!stringLiteral) commentSingleLine = false; 
                    else tempStringLiteral ~= lexeme;
                }
                line++;
                noTokensOnCurrentLine = true;
            }
            else if (lexeme == singleLineComment && !commentMultiLine) 
            {
                if (!stringLiteral)
                    commentSingleLine = true;
            }
            else if (!commentSingleLine)
            {
                if (lexeme == multiLineCommentBegin) { if (!stringLiteral) commentMultiLine = true; }
                else if (lexeme == multiLineCommentEnd) { if (!stringLiteral) commentMultiLine = false; }
                else if (!commentMultiLine)
                { 
                    if (matches(lexeme, stringLiteralQuote)) 
                    {
                        tempStringLiteral ~= lexeme;
                        if (stringLiteral)
                        {
                            if (lexeme[0] == tempStringLiteral[0]) 
                            {
                                result = tempStringLiteral; 
                                stringLiteral = false; 
                                satisfied = true; 
                            }
                        }
                        else stringLiteral = true;
                    }
                    else
                    {
                        if (stringLiteral)
                            tempStringLiteral ~= lexeme;
                        else if (!lexeme.isWhitespace)
                        {
                            if (!commentSingleLine && !commentMultiLine) 
                            {
                                result = lexeme;
                                satisfied = true;
                            }
                        }
                    }
                }
            }
        }

        if (result != "" && noTokensOnCurrentLine)
        {
            lastTokenLine = line;
            noTokensOnCurrentLine = false;
        }

	return result;
    }

   private:
    string getLexemeUnfiltered()
    {
        string temp;
        while (pos < source.length) 
        {
            string forw = matchForward(pos, delimiters);
            if (source[pos] == '\n')
            {
                if (!temp) { temp ~= "\n"; pos++; }
                break;
            }
            else if (matches(source[pos], std.ascii.whitespace)) 
            {
                if (!temp) { temp ~= source[pos]; pos++; }
                break;
            }
            else if (forw.length > 0)
            {
                if (!temp)
                { 
                    temp ~= forw; 
                    pos += forw.length;
                    break;
                }
                else break;
            }
            else
            {
                temp ~= source[pos];
                pos++;
            }
        }
        return temp;
    }

    string matchForward(size_t start, string[] list)
    {
        foreach(v; list)
        {
            string forward = getForward(start,v.length);
            if (forward == v) return forward;
        }
        return "";
    }

    string getForward(size_t position, size_t num)
    {
        if (position + num < source.length)
             return source[position..position+num];
        else 
             return source[position..$];
    }
}

