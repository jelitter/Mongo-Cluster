readConfig() {
    FileRead, res, % "config.txt"
    res := Trim(res)
    cluster.config := res
    EnvGet, USERPROFILE, USERPROFILE
    cluster.folder := USERPROFILE "\Desktop\cluster"
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

max(a, b) {
    return (a > b) ? a : b
}

toLower(string="") {
  return Format("{:L}", string)
}
