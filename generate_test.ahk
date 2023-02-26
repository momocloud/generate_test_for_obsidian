#Requires AutoHotkey v2.0


FileEncoding "UTF-8"

global gFilePaths := Array.Call()
global gScope := true
global gShuffle := false
global gSort := false
global gExChinese := false
global gExJapanese := false
global gExEnglish := false
global gSelect := false


ArrayHasElem(pArr, pElem) {
/*!
    Function: ArrayHasElem
    Parameters: pArr - Array to pass in; pElem - Elem to pass in
    Returns: bool - whether the element is in the array
*/
    for elem in pArr {
        if elem = pElem {
            return true
        }
    }
    return false
}


ShuffleArray(pArr) {
/*!
    Function: ShuffleArray
    Parameters: pArr - Array to shuffle
    Returns: resArr - Array after shuffled
*/
    resArr := Array.Call()
    Loop pArr.Length {
        if (A_Index = 1) {
            resArr.InsertAt(1, pArr[A_Index])
        } else {
            ran := Random(1, resArr.Length + 1)
            resArr.InsertAt(ran, pArr[A_Index])
        }
    }
    return resArr
}


SortArray(pArr) {
/*!
    Function: SortArray
    Parameters: pArr - Array to sort
    Remarks: Reference (https://www.reddit.com/r/AutoHotkey/comments/qx0nho/comment/hl6ig7a/)
    Returns: resArr - Array after sorted
*/
    assNum := Map.Call()
    resArr := Array.Call()

    For k, v in pArr {
        assNum[v] := k
    }

    For k, v in assNum {
        resArr.Push(k)
    }

    return resArr
}


DetectIfSelected(pStr) {
/*!
    Function: DetectIfSelected
    Parameters: pStr - Str to pass in
    Returns: bool - whether the string is selected
*/
    res := RegExMatch(pStr, "(?<===).+(?===)")
    if res = 0 {
        return false
    } else {
        return true
    }
}


DetectContainChinese(pStr) {
/*!
    Function: DetectContainChinese
    Parameters: pStr - Str to pass in
    Returns: bool - whether the string contains any Chinese characters
*/
    res := RegExMatch(pStr, "[一-龥]+")
    if res = 0 {
        return false
    } else {
        return true
    }
}


DetectContainJapanese(pStr) {
/*!
    Function: DetectContainJapanese
    Parameters: pStr - Str to pass in
    Returns: bool - whether the string contains any Japanese characters
*/
    res := RegExMatch(pStr, "[ぁ-んァ-ン]+")
    if res = 0 {
        return false
    } else {
        return true
    }
}


DetectAllEnglish(pStr) {
/*!
    Function: DetectAllEnglish
    Parameters: pStr - Str to pass in
    Remarks: Use ASCII standard to judge
    Returns: bool - whether the string is all English and number characters.
*/
    loop parse pStr {
        if not (0x00 <= Ord(A_LoopField) and Ord(A_LoopField) <= 0xff)
            return false
    }
    return true
}


GetSelectedFilesPath() {
/*!
    Function: DetectAllEnglish
    Remarks: Use clipboard to get all selected file paths,
             and then stored into the global value [gFilePaths]
*/
    oldClipboard := A_Clipboard

    Send("^c")
    Sleep(200)
    
    global gFilePaths := Array.Call()

    ; loop parse A_Clipboard "`r`n", "`r`n" {
    ;     gFilePaths.Push(A_LoopField)
    ; }
    for filePath in StrSplit(A_Clipboard, "`r`n") {
        gFilePaths.Push(filePath)
    }

    A_Clipboard := oldClipboard
}


BuildWordMap(pFileToReadPath) {
/*!
    Function: BuildWordMap
    Parameters: pfileToReadPath - the note file path to pass in
    Returns: Map - a map storing all the information which is {word: [tests]}
*/
    wordMap := Map.Call()

    slicing := false
    selected := true
    word := ""

    loop read pFileToReadPath {
        if InStr(A_LoopReadLine, "{") and gScope {
            if not slicing {
                wordMap := Map.Call()
                slicing := true
            }
            selected := true
        }
        if InStr(A_LoopReadLine, "# ") and selected {
            RegExMatch(A_LoopReadLine, "[^#]+$", &match)
            word := Trim(match[])
            wordMap[word] := Array.Call()
        }
        if InStr(A_LoopReadLine, "|") and selected and StrLen(word) != 0 {
            text := Trim(RegExReplace(A_LoopReadLine, "[-]", word))
            for subText in StrSplit(text, "|") {
                if StrLen(subText) > 0 and not ArrayHasElem(wordMap[word], subText){
                    wordMap[word].Push(subText)
                }
            }
        }
        if InStr(A_LoopReadLine, "}") and slicing and gScope {
            selected := false
        }
    }

    for word, testList in wordMap {
        if testList.Length = 0 {
            testList.Push(word)
        }
    }

    return wordMap
}


BuildLineToWriteList(pFileToReadPath, pWordMap) {
/*!
    Function: BuildLineToWriteList
    Parameters: pFileToReadPath - the note file path to pass in; pWordMap - the word map generated
    Returns: Array - an array stored generated line text to write in test file 
*/
    lineToWriteList := Array.Call()

    for word, testList in pWordMap {
        for test in testList {
            if (gExChinese and DetectContainChinese(test)) or 
                (gExJapanese and DetectContainJapanese(test)) or
                (gExEnglish and DetectAllEnglish(test)) or
                (gSelect and not DetectIfSelected(test)) {
                    continue
                }
            if DetectIfSelected(test) {
                word := "\" . SubStr(test, 1, 1) . 
                        "\" . SubStr(test, 2, StrLen(test)-3) . 
                        "\" . SubStr(test, -2, 1) . 
                        "\" . SubStr(test, -1, 1)
                test := SubStr(test, 3, StrLen(test)-4)
                lineToWrite := "==[[" pFileToReadPath "#" word "|" test "]]==`n"
            } else {
                lineToWrite := "[[" pFileToReadPath "#" word "|" test "]]`n"
            }
            lineToWriteList.Push(lineToWrite)
        }
    }

    if gShuffle {
        lineToWriteList := ShuffleArray(lineToWriteList)
    }

    if gSort {
        lineToWriteList := SortArray(lineToWriteList)
    }

    return lineToWriteList
}






^1:: {
    ; str_test_1 := "你好ぁ！"
    ; str_test_2 := "Thank you!"
    ; MsgBox(DetectContainChinese(str_test_1))
    ; MsgBox(DetectContainJapanese(str_test_1))
    ; MsgBox(DetectAllEnglish(str_test_1))
    ; MsgBox(DetectAllEnglish(str_test_2))

    ; GetSelectedFilesPath()
    
    ; for filepath in gfilePaths {
    ;     MsgBox(filepath)
    ; }

    ; for filepath in gfilePaths {
    ;     MsgBox(filepath)
    ;     for word, arr in BuildWordMap(filepath) {
    ;         MsgBox(word)
    ;         for elem in arr {
    ;             MsgBox(elem)
    ;         }
    ;     }
    ;     MsgBox("=====")
    ; }

    ; testArr := [1, 3, 2, 4, 5]
    ; testArr := ShuffleArray(testArr)
    ; loop testArr.Length {
    ;     MsgBox(testArr[A_Index])
    ; }
    ; testStr := "Heliolo!"
    ; MsgBox("\" SubStr(testStr, 1, 1) 
    ;         "\" SubStr(testStr, 2, StrLen(testStr)-3) 
    ;         "\" SubStr(testStr, -2, 1)
    ;         "\" SubStr(testStr, -1, 1))
    ; MsgBox(SubStr(testStr, 3, StrLen(testStr)-4))
    ; MsgBox("==[[" testStr "#" testStr "|" testStr "]]`n")

    ; testArr := ["==abc", "==cba", "==bac"]
    ; testArr := SortArray(testArr)

    ; for k, v in testArr {
    ;     MsgBox(v)
    ; }


    ExitApp()
}