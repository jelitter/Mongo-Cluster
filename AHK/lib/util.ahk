readConfig() {
    FileRead, res, % "config.txt"
    res := Trim(res)
    cluster.config := res
    return res
}

clean(str) {
    while InStr(str, "`r")
        str := StrReplace(Trim(str), "`r", "")
    while InStr(str, "`n`n")
        str := StrReplace(Trim(str), "`n`n", "`n")
    return Trim(str)
}

min(a, b) {
    return (a < b) ? a : b
}
