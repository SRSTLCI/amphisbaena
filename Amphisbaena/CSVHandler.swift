//
//  CSVHandler.swift
//  Amphisbaena
//
//  Created by Casey Fasthorse on 8/13/18.
//  Copyright © 2018 Casey Fasthorse. All rights reserved.
//

import Cocoa

class CSVHandler {
    struct stringConstants {
        static let comma = ","
        static let commaQuoteSubstitute = "SUBASCII034"
    }
    
    enum rowLengthError: Int {
        case errorNone = 0
        case errorLengthNotMatch = 1
    }
    
    fileprivate var csvContents: String = ""
    fileprivate var csvRows: [String] = [String]()
    fileprivate var csvColumns: [String: [String]]!
    var rawString: String?
    var csvColumnLabels: [String]!
    var columns: Int {
        return csvColumns.count
    }
    var rows: Int {
        return csvRows.count-1
    }
    
    init?(csvFile: URL) {
        var text: String?
        do {
            text = try String(contentsOf: csvFile, encoding: .utf8)
        }
        catch {return nil}
        if let text = text {
            self.rawString = text
            print("CSV Loaded.")
            csvContents = text
            csvContents = csvContents.replacingOccurrences(of: "\r", with: "")
            if let rows = makeRows() {csvRows = rows} else {return nil}
            if let columns = makeColumns() {csvColumns = columns} else {return nil}
            printRows()
            printColumnLabels()
        }
    }
    
    init?(string: String) {
        let text: String = string
        self.rawString = text
        print("CSV Loaded.")
        csvContents = text
        csvContents = csvContents.replacingOccurrences(of: "\r", with: "")
        if let rows = makeRows() {csvRows = rows} else {return nil}
        if let columns = makeColumns() {csvColumns = columns} else {return nil}
        printRows()
        printColumnLabels()
    }
    
    fileprivate func replaceCommasInQuotesWithSubstitute(text: String) -> String {
        let formattedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let oddQuote = (formattedText.first != "\"")
        var stringArray = formattedText.components(separatedBy: "\"")
        for i in 0..<stringArray.count {
            if (oddQuote) {
                if i%2 == 0 {continue}
            }
            else {
                if (i+1)%2 == 0 {continue}
            }
            stringArray[i] = stringArray[i].replacingOccurrences(of: stringConstants.comma, with: stringConstants.commaQuoteSubstitute)
        }
        var rebuiltString = ""
        for str in stringArray {
            rebuiltString += str
        }
        return rebuiltString
    }
    
    fileprivate func restoreCommaSubstitutes(text: String) -> String {
        return text.replacingOccurrences(of: stringConstants.commaQuoteSubstitute, with: stringConstants.comma)
    }

    fileprivate func checkRowsForEqualLength(rows: [String]) -> rowLengthError {
        var rowLength = -1
        for row in rows {
            let index = rows.firstIndex(of: row)! as Int
            let rowCommaFix = replaceCommasInQuotesWithSubstitute(text: row)
            let rowCount = rowCommaFix.components(separatedBy: ",").count
            if rowLength == -1 {
                rowLength = rowCount
            }
            else if rowCount != rowLength {
                print("CSV Error: Length Expected: "+String(rowLength)+", Error Row/Length: "+String(index)+"/"+String(rowCount))
                return .errorLengthNotMatch
            }
        }
        return .errorNone
    }
    
    fileprivate func makeRows() -> [String]? {
        let rows = csvContents.components(separatedBy: "\n")
        if checkRowsForEqualLength(rows: rows) != .errorNone {
            print("CSV Error: Rows are not of equal length.")
            return nil
        }
        else {
            return rows
        }
    }
    
    func printRows() {
        print("CSV Rows: ")
        for row in csvRows {
            print("* "+row)
        }
    }
    
    func makeColumns() -> [String: [String]]? {
        var columns: [String: [String]] = [String: [String]]()
        let columnRow = csvRows[0]
        //get the name of the columns
        csvColumnLabels = columnRow.components(separatedBy: ",")
        //make the empty columns
        if let csvColumnLabels = csvColumnLabels {
            for column in 0..<csvColumnLabels.count {
                let label = csvColumnLabels[column]
                var data = [String]()
                for row in 1..<csvRows.count {
                    let rowCommaFix = replaceCommasInQuotesWithSubstitute(text: csvRows[row])
                    let rowSplit = rowCommaFix.components(separatedBy: ",")
                    let dataColumn = restoreCommaSubstitutes(text: rowSplit[column])
                    data.append(dataColumn)
                }
                columns[label] = data
            }
        }
        return columns
    }
    
    func printColumnLabels() {
        print("CSV Column Labels: ")
        var columnLabelsStr = ""
        if let csvColumnLabels = csvColumnLabels {
            for column in csvColumnLabels {
                columnLabelsStr += column+", "
            }
        }
        print("* Column Labels: "+String(columnLabelsStr))
    }
    
    func printColumn(label: String) {
        if csvColumns.keys.contains(label) {
            print("CSV Column: "+label)
            let data = csvColumns[label]!
            for row in data {
                print("* * "+row)
            }
        }
        else {
            print("Column does not exist.")
        }
    }
    
    func getData(columnLabel column: String, rowNumber row: Int) -> String? {
        if csvColumns.keys.contains(column) {
            let columnSelected = csvColumns[column]!
            return columnSelected[row]
        }
        else {
            return nil
        }
    }
    
    func columnsPresent(columns: [String]) -> Bool {
        var count = 0
        columns.forEach {
            if csvColumnLabels.contains($0) {count += 1}
        }
        return count == columns.count
    }
}
