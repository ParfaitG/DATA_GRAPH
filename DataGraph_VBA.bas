''''''''''''''''''
'' MS ACCESS
''''''''''''''''''
Option Explicit
Option Compare Database

Private Sub TXTImport_Click()
On Error GoTo ErrHandle
    Dim db As Database: Set db = CurrentDb
    Dim strFile As String: strFile = Application.CurrentProject.Path
    
    ' MULTIFACTOR PRODUCT DATA
    db.Execute "DELETE FROM MultiFactorProductData", dbFailOnError
    DoCmd.TransferText acImportDelim, "ProductImportSpec", "MultiFactorProductData", strFile & "\DATA\MultiFactorProductData.txt", True
        
    ' MULTIFACTOR SECTOR DATA
    db.Execute "DELETE FROM MultiFactorSectorData", dbFailOnError
    DoCmd.TransferText acImportDelim, "SectorImportSpec", "MultiFactorSectorData", strFile & "\DATA\MultiFactorSectorData.txt", True
        
    MsgBox "Successfully imported TXT data!", vbInformation
    Exit Sub
    
ErrHandle:
    MsgBox Err.Number & " - " & Err.Description, vbCritical
    Exit Sub
    
End Sub

Private Sub GraphOutput_Click()
    DoCmd.OpenForm "GraphForm"
End Sub

Private Sub GraphExport_Click()
On Error GoTo ErrHandle

    Dim oleGrf As Object
    Dim db As Database
    Dim rst As Recordset
    
    Set db = CurrentDb
    Set rst = db.OpenRecordset("SELECT sector_code FROM MultifactorSectorData", dbOpenDynaset)
    
    rst.MoveLast: rst.MoveFirst
    
    Do While Not rst.EOF
        Me.SectorCbo = rst!sector_code
        Me.Form.Refresh
        
        Set oleGrf = Me.MFPGraph.Object
        oleGrf.Export FileName:=Application.CurrentProject.Path & "\GRAPHS\sector_" & Me.SectorCbo & "_acc.jpg"
        Set oleGrf = Nothing
        
        rst.MoveNext
    Loop
    
    rst.Close
    Set rst = Nothing
    Set db = Nothing
    Set oleGrf = Nothing
        
    MsgBox "Successfully exported current graphs!", vbInformation, "GRAPH EXPORT"
    Exit Sub
    
ErrHandle:
    MsgBox Err.Number & " - " & Err.Description, vbCritical, "RUNTIME ERROR"
    Exit Sub
End Sub

Private Sub SectorCbo_AfterUpdate()
    Me.Form.Requery
    Me.Form.Refresh
End Sub


''''''''''''''''''
'' MS EXCEL
''''''''''''''''''
Option Explicit

Public Sub ProduceGraphs()
    Call ImportTextData
    Call GraphDataHandle
    Call GraphExport
    
    MsgBox "Successfully produced graphs!", vbInformation, "GRAPH OUT"
End Sub

Public Sub ImportTextData()
    Call QTableProcess("MFP_DATA", ActiveWorkbook.Path & "\DATA\MultifactorProductData.txt")
    Call QTableProcess("SECTOR_DATA", ActiveWorkbook.Path & "\DATA\MultifactorSectorData.txt")
End Sub

Public Function QTableProcess(sheetName As String, fileName As String)
    Dim qt As QueryTable
    
    ThisWorkbook.Worksheets(sheetName).Columns("A:G").Delete xlToLeft
    
    ' IMPORT MFP DATA
    With ThisWorkbook.Worksheets(sheetName).QueryTables.Add(Connection:="TEXT;" & fileName, _
        Destination:=ThisWorkbook.Worksheets(sheetName).Cells(1, 1))
            .TextFileStartRow = 1
            .TextFileParseType = xlDelimited
            .TextFileConsecutiveDelimiter = False
            .TextFileTabDelimiter = True
            .TextFileSemicolonDelimiter = False
            .TextFileCommaDelimiter = False
            .TextFileSpaceDelimiter = False

            .Refresh BackgroundQuery:=False
    End With
  
    For Each qt In ThisWorkbook.Worksheets(sheetName).QueryTables
        qt.Delete
    Next qt
End Function

Public Sub GraphDataHandle()
On Error GoTo ErrHandle
    Dim lastRow As Long, i As Long
    
    ThisWorkbook.Worksheets("GRAPH").Activate
    ThisWorkbook.Worksheets("GRAPH").Columns("A:G").Delete xlToLeft
    ThisWorkbook.Worksheets("MFP_DATA").Cells.Copy _
                    Destination:=ThisWorkbook.Worksheets("GRAPH").Cells
        
    With ThisWorkbook.Worksheets("GRAPH")
        lastRow = .Cells(.Rows.Count, "A").End(xlUp).Row
        
        .Columns("A:A").NumberFormat = "@"
        .Columns("E:E").Delete xlShiftToLeft
                        
        For i = 2 To lastRow
            If Mid(.Range("A" & i), 8, 3) <> "012" Then
                .Range("A" & i & ":G" & i).ClearContents
            End If
        Next i

        .Range("A1:D" & lastRow).Select
        Selection.Sort Key1:=.Range("A1"), Order1:=xlAscending, Key2:=.Range("B1") _
            , Order2:=xlAscending, Header:=xlGuess, OrderCustom:=1, MatchCase:= _
            False, Orientation:=xlTopToBottom
        
        ThisWorkbook.Save
        lastRow = .Cells(.Rows.Count, "A").End(xlUp).Row
        
        .Range("E1") = "sector_code"
        .Range("F1") = "sector_name"
        .Range("G1") = "sector_name"
        .Range("H1") = "NAICS"
        
        For i = 2 To lastRow
            .Range("E" & i) = Mid(.Range("A" & i), 4, 4)
            .Range("F" & i) = Application.WorksheetFunction.Index( _
                                        ThisWorkbook.Worksheets("SECTOR_DATA").Range("$A$2:$B$24"), _
                                        Application.WorksheetFunction.Match(.Range("E" & i), _
                                        ThisWorkbook.Worksheets("SECTOR_DATA").Range("$A$2:$A$24"), 0), 2)
            .Range("G" & i) = Left(.Range("F" & i), InStr(.Range("F" & i), " (NAICS") - 1)
            .Range("H" & i) = Mid(.Range("F" & i), InStr(.Range("F" & i), " (NAICS") + 1)
            
        Next i
        
        .Columns("F:F").Delete xlShiftToLeft
        
        ' PIVOT WORKSHEET
        ThisWorkbook.Worksheets("PIVOT").PivotTables("MFPPivot").ChangePivotCache _
            ThisWorkbook.PivotCaches.Create( _
            SourceType:=xlDatabase, _
            SourceData:=.Range("A1:G" & lastRow))
        
        ThisWorkbook.Worksheets("PIVOT").PivotTables("MFPPivot").RefreshTable
    End With
    Exit Sub
    
ErrHandle:
    MsgBox Err.Number & " - " & Err.Description, vbCritical, "RUNTIME ERROR"
    Exit Sub
End Sub

Public Sub GraphExport()
On Error GoTo ErrHandle
    Dim sectorDict As Object
    Dim key As String, val As Variant
    Dim element As Variant, item As Variant
    Dim lastRow As Long, i As Long
    Dim pvtTable As PivotTable
    Dim pvtChartObj As ChartObject, pvtChart As Chart
    
    Set sectorDict = CreateObject("Scripting.Dictionary")
    
    ' DISTINCT LIST (DICTIONARY) OF SECTOR CODES
    With ThisWorkbook.Worksheets("GRAPH")
        lastRow = .Cells(.Rows.Count, "A").End(xlUp).Row
        
        For i = 2 To lastRow
            If .Range("E" & i) <> .Range("E" & i - 1) Then
                key = .Range("E" & i): val = .Range("F" & i)
                sectorDict.Add key, val
            End If
        Next i
        
    End With
    
    ' ITERATIVELY EXPORT PIVOT CHART AS IMAGE
    ThisWorkbook.Worksheets("PIVOT").Activate
    Set pvtTable = Worksheets("PIVOT").PivotTables("MFPPivot")
    Set pvtChartObj = Worksheets("PIVOT").ChartObjects("MFPChart")
    Set pvtChart = pvtChartObj.Chart
    
    For Each element In sectorDict.keys
        
        pvtTable.PivotFields("sector_code").ClearAllFilters
        pvtTable.PivotFields("sector_code").CurrentPage = element
    
        pvtChart.Export fileName:=ThisWorkbook.Path & "\GRAPHS\sector_" & element & "_xl.png"
        
    Next element

    sectorDict.RemoveAll
    Set sectorDict = Nothing

    Set pvtChart = Nothing
    Set pvtChartObj = Nothing
    Set pvtTable = Nothing
    Exit Sub
    
ErrHandle:
    MsgBox Err.Number & " - " & Err.Description, vbCritical, "RUNTIME ERROR"
    Exit Sub
End Sub