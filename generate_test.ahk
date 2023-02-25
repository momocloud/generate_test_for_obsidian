#Requires AutoHotkey v2.0

FileEncoding "UTF-8"

global gFilePaths := Array.Call()
global gScope := true


ArrayHasElem(pArr, pElem) {
/*!
    Function: ArrayHasElem
    Parameters: pArr - Array to pass in; pElem - Elem to pass in
    Returns: bool - whether the element is in the array
*/
    for elem in pArr {
        if elem == pElem {
            return true
        }
    }
    return false
}


DetectIfSelected(pStr) {
/*!
    Function: DetectIfSelected
    Parameters: pStr - Str to pass in
    Returns: bool - whether the string is selected
*/
    res := RegExMatch(pStr, "(?<===).+(?===)")
    if res == 0 {
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
    if res == 0 {
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
    if res == 0 {
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

BuildWordMap(fileToReadPath) {
/*!
    Function: BuildWordMap
    Parameters: fileToReadPath - the note file path to pass in
    Returns: Map - a map storing all the information which is {word: [tests]}
*/
    wordMap := Map.Call()

    slicing := false
    selected := true
    word := ""

    loop read fileToReadPath {
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
        if testList.Length == 0 {
            testList.Push(word)
        }
    }

    return wordMap
}



^1:: {
    ; str_test_1 := "你好ぁ！"
    ; str_test_2 := "Thank you!"
    ; MsgBox(DetectContainChinese(str_test_1))
    ; MsgBox(DetectContainJapanese(str_test_1))
    ; MsgBox(DetectAllEnglish(str_test_1))
    ; MsgBox(DetectAllEnglish(str_test_2))

    GetSelectedFilesPath()
    
    ; for filepath in gfilePaths {
    ;     MsgBox(filepath)
    ; }

    for filepath in gfilePaths {
        MsgBox(filepath)
        for word, arr in BuildWordMap(filepath) {
            MsgBox(word)
            for elem in arr {
                MsgBox(elem)
            }
        }
        MsgBox("=====")
    }

    ; ExitApp()
}