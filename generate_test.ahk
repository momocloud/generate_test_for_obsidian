#Requires AutoHotkey v2.0
; Author: momocloud


FileEncoding "UTF-8"

RegExMatch(A_ScriptFullPath, "[^\\].*(?=\.)", &match)
global gConfigPath := match[] . ".ini"

global gFilePaths := Array.Call()
global gFileToWritePath := Array.Call()
global gScope := true
global gShuffle := false
global gSort := false
global gSelect := false
global gEmphasis := 4
global gMark := true
global gExChinese := false
global gExJapanese := false
global gExEnglish := false


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

    for k, v in pArr {
        assNum[v] := k
    }

    for k, _ in assNum {
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


GenWriteFilesPath() {
/*!
    Function: GenWriteFilesPath
    Remarks: Use [gFilePaths] to generarte the file path to write,
             and then stored into the global value [gFileToWritePath]
*/
    if gFilePaths.Length = 0 {
        return
    }
    for _, filePath in gFilePaths {
        RegExMatch(filePath, "[^\\].*?(?=\.)", &match)
        fileToWritePath := String(match[] . "_gentest.md")
        gFileToWritePath.Push(fileToWritePath)
    }
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
            RegExMatch(pFileToReadPath, "[^\\]+$", &match)
            matchFileName := String(match[])
            if DetectIfSelected(test) {
                word := "\" . SubStr(test, 1, 1) . 
                        "\" . SubStr(test, 2, StrLen(test)-3) . 
                        "\" . SubStr(test, -2, 1) . 
                        "\" . SubStr(test, -1, 1)
                test := SubStr(test, 3, StrLen(test)-4)
                lineToWrite := "==[[" matchFileName "#" word "|" test "]]==`n"
            } else {
                lineToWrite := "[[" matchFileName "#" word "|" test "]]`n"
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


WriteLines(pFileToWritePath, pLineToWriteList) {
/*!
    Function: WriteLines
    Parameters: pFileToWritePath - the note file path to write; pLineToWriteList - the word list generated before
*/
    lineStart := ""
    Loop gEmphasis {
        lineStart := lineStart . "#"
    }
    if gEmphasis > 0 {
        lineStart := lineStart . " "
    }

    for index, line in pLineToWriteList {
        if gMark {
            line := lineStart . index . ". " . line
        } else {
            line := lineStart . line
        }
        FileAppend(line, pFileToWritePath)
    }
}


ReadConfigFile() {
/*!
    Function: ReadConfigFile
    Remarks: Read config file into global values
*/
    global gScope := IniRead(gConfigPath, "ReadConfig", "gScope", true)
    global gSelect := IniRead(gConfigPath, "ReadConfig", "gSelect", false)

    global gShuffle := IniRead(gConfigPath, "ShowConfig", "gShuffle", false)
    global gSort := IniRead(gConfigPath, "ShowConfig", "gSort", false)
    global gEmphasis := IniRead(gConfigPath, "ShowConfig", "gEmphasis", 4)
    global gMark := IniRead(gConfigPath, "ShowConfig", "gMark", true)

    global gExChinese := IniRead(gConfigPath, "LangConfig", "gExChinese", false)
    global gExJapanese := IniRead(gConfigPath, "LangConfig", "gExJapanese", false)
    global gExEnglish := IniRead(gConfigPath, "LangConfig", "gExEnglish", false)
}


#f1::{
    GetSelectedFilesPath()
    GenWriteFilesPath()

    Loop gFilePaths.Length {
        filePath := gFilePaths[A_Index]
        fileToWritePath := gFileToWritePath[A_Index]

        if FileExist(fileToWritePath) {
            fileExistResult := MsgBox(Format("
                (LTrim
                    检测到待生成文件
                    {1} 
                    已经存在，是否重写该文件？
                    Yes 将重写原文件；No 将在原文件后追加内容；Cancel 将跳过该文件的处理
                )", fileToWritePath), "WARN: FILE EXISTED", "Y/N/C")
            
            if fileExistResult = "Yes" {
                FileDelete(fileToWritePath)
            } else if fileExistResult = "Cancel" {
                continue
            }
        }

        wordMap := BuildWordMap(filePath)
        lineToWriteList := BuildLineToWriteList(filePath, wordMap)
        WriteLines(fileToWritePath, lineToWriteList)
    }
}


#f2::{
    MsgBox("感谢使用！下次再来哦~ (*^▽^*)", "BYE~")
    ExitApp()
}


#f3::{
    configSetter := Gui(, "INI Config Generator")
    configSetter.SetFont("S10")
    configSetter.Add("Text","x60 y26 w355 h38 +Center +", "欢迎使用配置文件生成器！`n可在脚本运行中使用Win F3重新打开此页面~")

    configSetter.Add("Text", "x21 y93 w316 h19 +Center +", "是否开启选定范围生成（使用{}来控制范围）")
    scope := configSetter.Add("Checkbox", "vscope x348 y93 w67 h19 Checked1", "建议是")

    configSetter.Add("Text", "x21 y132 w316 h19 +Center +", "是否开启仅限重点词生成（使用====来控制范围）")
    select := configSetter.Add("Checkbox", "vselect x348 y132 w67 h19 Checked0", "建议否")

    configSetter.Add("Text", "x21 y170 w316 h19 +Center +", "是否开启随机顺序生成")
    shuffle := configSetter.Add("Checkbox", "vshuffle x348 y170 w67 h19 Checked1", "建议是")

    configSetter.Add("Text", "x21 y208 w316 h19 +Center +", "是否进行排序（这将强制关闭随机顺序生成！）")
    sort_ := configSetter.Add("Checkbox", "vsort_ x348 y208 w67 h19 Checked0", "建议否")

    configSetter.Add("Text", "x21 y266 w316 h19 +Center +", "生成的标题级别（推荐为4，0则禁用标题）")
    emphasis := configSetter.Add("ListBox", "vemphasis x348 y237 w67 h80 Choose5", [0, 1, 2, 3, 4])

    configSetter.Add("Text", "x21 y314 w316 h19 +Center +", "是否生成标号")
    mark := configSetter.Add("Checkbox", "vmark x348 y314 w76 h19 Checked1", "建议是")

    configSetter.Add("Text", "x21 y362 w316 h19 +Center +", "是否排除含有中文项")
    exChinese := configSetter.Add("Checkbox", "vexChinese x348 y362 w86 h19 Checked0", "建议否")

    configSetter.Add("Text", "x21 y400 w316 h19 +Center +", "是否排除日文项（假名）")
    exJapanese := configSetter.Add("Checkbox", "vexJapanese x348 y400 w96 h19 Checked0", "建议否")

    configSetter.Add("Text", "x21 y439 w316 h19 +Center +", "是否**全**英文项")
    exEnglish := configSetter.Add("Checkbox", "vexEnglish x348 y439 w96 h19 Checked0", "建议否")

    finishButton := configSetter.Add("Button", "x190 y477 w96 h30", "完成")
    finishButton.OnEvent("Click", finishButton_Click)

    configSetter.Show("w476 h530")
    configSetter.OnEvent("Close", configSetter_Close)

    finishButton_Click(thisButton, info) {
        if not configSetter_Close(configSetter) {
            configSetter.Destroy()
        }
    }

    configSetter_Close(thisGui) {
        if MsgBox("是否保存配置?", "WARN: CONFIG CONFIRM", "y/n") = "No" {
            return true
        } else {
            writeConfigFile()
            ReadConfigFile()
            return false
        }
    }

    writeConfigFile() {
        if FileExist(gConfigPath) {
            FileDelete(gConfigPath)
        }
        IniWrite(scope.Value, gConfigPath, "ReadConfig", "gScope")
        IniWrite(select.Value, gConfigPath, "ReadConfig", "gSelect")
        IniWrite(shuffle.Value, gConfigPath, "ReadConfig", "gShuffle")
        IniWrite(sort_.Value, gConfigPath, "ShowConfig", "gSort")
        IniWrite(emphasis.Value-1, gConfigPath, "ShowConfig", "gEmphasis")
        IniWrite(mark.Value, gConfigPath, "ShowConfig", "gMark")
        IniWrite(exChinese.Value, gConfigPath, "LangConfig", "gExChinese")
        IniWrite(exJapanese.Value, gConfigPath, "LangConfig", "gExJapanese")
        IniWrite(exEnglish.Value, gConfigPath, "LangConfig", "gExEnglish")
    }

}


ScriptOpen() {
    if not FileExist(gConfigPath) {
        MsgBox("
                (LTrim
                未检测到配置文件！即将打开配置文件创建窗口。
                )", "WARN: INI NOT FOUND")
        Send("#{f3}")
    }

    readConfigFile()
}


ScriptOpen()