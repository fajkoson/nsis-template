!include "FileFunc.nsh"
!include "LogicLib.nsh"

OutFile "..\out\bin\package.exe"
InstallDir "$PROGRAMFILES\MyApp"
Page directory
Page instfiles

RequestExecutionLevel admin

Section "Main"

SetOutPath "$INSTDIR"

; Add extra content to the installer
File /r "..\extra\*"

; Copy external TAR and SIG files next to installer
CopyFiles "$EXEDIR\payload.tar" "$INSTDIR\payload.tar"
CopyFiles "$EXEDIR\payload.sig" "$INSTDIR\payload.sig"

DetailPrint "Verifying integrity..."

; Create temporary verify.bat to compute the hash
FileOpen $0 "$INSTDIR\verify.bat" w
FileWrite $0 'certutil -hashfile "$INSTDIR\payload.tar" SHA256 > "$INSTDIR\hash.txt"$\r$\n'
FileClose $0

ExecWait '"$INSTDIR\verify.bat"'

; Read computed hash from line 2 of hash.txt
FileOpen $1 "$INSTDIR\hash.txt" r
FileRead $1 $0      ; Skip first line
FileRead $1 $1      ; Actual hash
FileClose $1
StrCpy $1 $1 64     ; Trim

; Read expected signature (1 line only)
FileOpen $2 "$INSTDIR\payload.sig" r
FileRead $2 $3
FileClose $2
StrCpy $3 $3 64

DetailPrint "Computed: $1"
DetailPrint "Expected: $3"

${If} $1 == $3
    DetailPrint "Signature valid."

    ; === Extract TAR using built-in Windows tar.exe
    DetailPrint "Extracting payload.tar..."
    nsExec::ExecToLog 'tar -xf "$INSTDIR\payload.tar" -C "$INSTDIR"'
    Pop $0
    ${If} $0 != 0
        MessageBox MB_ICONSTOP "Extraction failed. Code: $0"
        ; Cleanup
        Delete "$INSTDIR\payload.tar"
        Delete "$INSTDIR\payload.sig"
        Delete "$INSTDIR\verify.bat"
        Delete "$INSTDIR\hash.txt"
        Abort
    ${EndIf}

    DetailPrint "Extraction completed."

    ; Final cleanup
    Delete "$INSTDIR\payload.tar"
    Delete "$INSTDIR\payload.sig"
    Delete "$INSTDIR\verify.bat"
    Delete "$INSTDIR\hash.txt"

${Else}
    MessageBox MB_ICONSTOP "ERROR: Invalid TAR signature. Installation aborted."

    ; Cleanup on failure
    Delete "$INSTDIR\payload.tar"
    Delete "$INSTDIR\payload.sig"
    Delete "$INSTDIR\verify.bat"
    Delete "$INSTDIR\hash.txt"
    Abort
${EndIf}

SectionEnd
