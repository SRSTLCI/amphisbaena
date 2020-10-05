//
//  Amphisbaena_TEITagParser.swift
//  Amphisbaena
//
//  Created by Casey on 5/25/20.
//  Copyright © 2020 Casey Fasthorse. All rights reserved.
//

import Foundation

class Amphisbaena_TEITagParser {
    
    var csvHandler: CSVHandler?
    var resultContainer: Amphisbaena_TEITagContainer?
    
    struct RegEx {
        static let regexExtractType = try! NSRegularExpression(pattern: #"(\w+)\ \{.+\}"#)
        static let regexExtractBrackets = try! NSRegularExpression(pattern: #"\w+\ \{(.+)\}"#, options: [.caseInsensitive])
        static let regexSplitTags = try! NSRegularExpression(pattern: #"(?:^|(?<=,\ ))(\w+)=((?:.|é)+?)(?=, (?:.+=)|$)"#, options: [.caseInsensitive])
    }
    
    struct ElementAttributeOrders {
        static let sic          = ["correction"]
        static let person       = ["firstname", "lastname"]
        static let place        = ["geo","placeName","type"]
        static let date         = ["month","year","day"]
    }
    
    init?(string: String) {
        csvHandler = CSVHandler(string: string)
        resultContainer = Amphisbaena_TEITagContainer(withName: "tags", isRoot: true);
        if let originalString = csvHandler?.rawString {
            resultContainer?.originalCSV = originalString
        }
        if let csvHandler = csvHandler {
            for r in 0..<csvHandler.rows {
                var facs: String?
                if let page = csvHandler.getData(columnLabel: "Page", rowNumber: r),
                    let word = csvHandler.getData(columnLabel: "Word", rowNumber: r) {
                    facs = generateFacs(withPage: page, wordFacs: word)
                }
                if let tag = csvHandler.getData(columnLabel: "Tag", rowNumber: r),
                    let facs = facs {
                    if let unwrapTag = unwrapTag(rawTag: tag) {
                        ingestDataType(fromUnwrappedTag: unwrapTag, addedFacs: facs)
                    }
                }
            }
        }
        else {return nil;}
    }
    
    init?(csvFile: URL) {
        csvHandler = CSVHandler(csvFile: csvFile);
        resultContainer = Amphisbaena_TEITagContainer(withName: "tags", isRoot: true);
        if let originalString = csvHandler?.rawString {
            resultContainer?.originalCSV = originalString
        }
        if let csvHandler = csvHandler {
            for r in 0..<csvHandler.rows {
                var facs: String?
                if let page = csvHandler.getData(columnLabel: "Page", rowNumber: r),
                    let word = csvHandler.getData(columnLabel: "Word", rowNumber: r) {
                    facs = generateFacs(withPage: page, wordFacs: word)
                }
                if let tag = csvHandler.getData(columnLabel: "Tag", rowNumber: r),
                    let facs = facs {
                    if let unwrapTag = unwrapTag(rawTag: tag) {
                        ingestDataType(fromUnwrappedTag: unwrapTag, addedFacs: facs)
                    }
                }
            }
        }
        else {return nil;}
    }
    
    func generateFacs(withPage page: String, wordFacs: String) -> String {
        return "facs_"+page+"_"+wordFacs;
    }
    
    func stripDiacritics(string: String) -> String {
        return string.folding(options: .diacriticInsensitive, locale: nil)
    }
    
    func unwrapTag(rawTag tag: String) -> [String: [String : String]]? {
        var tagType: String?
        var tagContents: [String : String]?
        
        let tagRange = NSRange(tag.startIndex..<tag.endIndex, in: tag)
        let matchBrackets = RegEx.regexExtractBrackets.firstMatch(in: tag, options: [], range: tagRange)
        
        if let matchBrackets = matchBrackets {
            let matchType = RegEx.regexExtractType.firstMatch(in: tag, options: [], range: tagRange)
            if let matchType = matchType {
                for r in 1..<matchType.numberOfRanges {
                    if let matchRange = Range(matchType.range(at: r), in: tag) {
                        let matchString = String(tag[matchRange])
                        print("TYPE: "+matchString)
                        tagType = matchString
                    }
                }
            }
            for r in 1..<matchBrackets.numberOfRanges {
                if let matchRange = Range(matchBrackets.range(at: r), in: tag) {
                    tagContents = [:]
                    let matchString = String(tag[matchRange])
                    //print(matchString)
                    let matchStringRange = NSRange(matchString.startIndex..<matchString.endIndex, in: matchString)
                    let matchTags = RegEx.regexSplitTags.matches(in: matchString, options: [], range: matchStringRange)
                    var propertyMemo = "TAGS: "
                    for match in matchTags {
                        var pair: (String?, String?)
                        for rr in 1..<match.numberOfRanges {
                            if let matchTagRange = Range(match.range(at: rr), in: matchString) {
                                let matchTagString = String(matchString[matchTagRange])
                                propertyMemo += matchTagString
                                if (rr == 1) {propertyMemo += "="}
                                if rr == 1 {
                                    pair.0 = matchTagString
                                }
                                else if rr == 2 && matchTagString != "null" {
                                    pair.1 = matchTagString
                                }
                            }
                        }
                        if let pair0 = pair.0, let pair1 = pair.1 {
                            tagContents?[pair0] = pair1
                        }
                        propertyMemo += ", "
                    }
                    print(propertyMemo)
                }
            }
        }
        if let tagType = tagType, let tagContents = tagContents {
            let packagedTag: [String : [String : String]] = [tagType : tagContents]
            return packagedTag
        }
        else {
            return nil;
        }
    }
    
    func ingestDataType(fromUnwrappedTag unwrappedTag: [String : [String : String]], addedFacs: String) {
        for (key, dict) in unwrappedTag {
            
            var facsContainer: Amphisbaena_Container?
            let tagAttributes = ["facs" : addedFacs]
            let containerSearch = resultContainer?.hasElementsMatching(name: "tag", matchingAttributes: tagAttributes, recursively: false)
            if let foundContainer = containerSearch?.first as? Amphisbaena_Container {
                facsContainer = foundContainer;
            }
            else {
                facsContainer = Amphisbaena_Container(withName: "tag", isRoot: false)
                facsContainer?.elementAttributes = tagAttributes
                resultContainer?.addElement(element: facsContainer!)
            }
            
            switch (key) {
            case "sic":
                
                var attributes: [String : String] = [:]
                if let correction = dict["correction"] {
                    attributes["correction"] = correction
                }
                let elementSic = Amphisbaena_Element(elementName: "sic", attributes: attributes, elementContent: nil)
                elementSic.preferredAttributeOrder = ElementAttributeOrders.sic
                facsContainer?.addElement(element: elementSic)
                
            case "person":
                
                var attributes: [String : String] = [:]
                if let firstName = dict["firstname"] {
                    attributes["firstname"] = firstName
                }
                if let lastName = dict["lastname"] {
                    attributes["lastname"] = lastName
                }
                let elementPerson = Amphisbaena_Element(elementName: "person", attributes: attributes, elementContent: nil)
                elementPerson.preferredAttributeOrder = ElementAttributeOrders.person
                facsContainer?.addElement(element: elementPerson)
                
            case "place":
                
                var attributes: [String : String] = [:]
                if let geo = dict["geo"] {
                    attributes["geo"] = geo
                }
                if let placeName = dict["placeName"] {
                    attributes["placeName"] = placeName
                }
                if let type = dict["type"] {
                    attributes["type"] = type
                }
                let elementPlace = Amphisbaena_Element(elementName: "place", attributes: attributes, elementContent: nil)
                elementPlace.preferredAttributeOrder = ElementAttributeOrders.place
                facsContainer?.addElement(element: elementPlace)
            case "date":
                
                var attributes: [String : String] = [:]
                if let month = dict["month"] {
                    attributes["month"] = month
                }
                if let year = dict["year"] {
                    attributes["year"] = year
                }
                if let day = dict["day"] {
                    attributes["day"] = day
                }
                let elementDate = Amphisbaena_Element(elementName: "date", attributes: attributes, elementContent: nil)
                elementDate.preferredAttributeOrder = ElementAttributeOrders.date
                facsContainer?.addElement(element: elementDate)
            case "edit":
                var attributes: [String : String] = [:]
                if let month = dict["original"] {
                    attributes["original"] = month
                }
                let elementEdit = Amphisbaena_Element(elementName: "edit", attributes: attributes, elementContent: nil)
                facsContainer?.addElement(element: elementEdit)
            case "edited", "merged", "split":
                var attributes: [String : String] = [:]
                if let month = dict["unedited"] {
                    attributes["unedited"] = month
                }
                let elementEdit = Amphisbaena_Element(elementName: key, attributes: attributes, elementContent: nil)
                facsContainer?.addElement(element: elementEdit)
            case "del":
                let elementDel = Amphisbaena_Element(elementName: "del", attributes: nil, elementContent: nil)
                facsContainer?.addElement(element: elementDel)
            case "addition":
                let elementAddition = Amphisbaena_Element(elementName: "addition", attributes: nil, elementContent: nil)
                facsContainer?.addElement(element: elementAddition)
            default:
                print("Ingesting keys: Unhandled data type of kind "+key)
            }
        }
    }
}
