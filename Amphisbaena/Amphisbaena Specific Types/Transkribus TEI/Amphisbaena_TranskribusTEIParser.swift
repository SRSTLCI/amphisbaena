//
//  Amphisbaena_TranskribusTEIParser.swift
//  Amphisbaena
//
//  Created by Casey on 4/28/20.
//  Copyright © 2020 Casey Fasthorse. All rights reserved.
//

import Foundation

class Amphisbaena_TranskribusTEIParser: NSObject {
    var stringData: Data
    
    var parser: XMLParser?
    
    var resultContainer: Amphisbaena_TranskribusTEIContainer?
    
    var foundCharacters: String = ""
    var skipCharacters: Bool = false;
    
    var currentFileDesc: Amphisbaena_Container?
    var currentTitleStmt: Amphisbaena_Container?
    var currentTitle: Amphisbaena_Element?
    var currentPublicationStmt: Amphisbaena_Container?
    var currentSourceDesc: Amphisbaena_Container?
    var currentPublisher: Amphisbaena_Element?
    var currentBibl: Amphisbaena_Container?
    var currentFacsimile: Amphisbaena_Container?
    var currentSurface: Amphisbaena_Container?
    var currentZones: [Amphisbaena_TranskribusTEIContainer_Zone] = []
    var currentParagraph: Amphisbaena_Container?
    var currentWord: Amphisbaena_Element?
    var currentSic: Amphisbaena_Element?
    
    var currentAnnotation: Amphisbaena_Container?
    var currentAnnotationInner: Amphisbaena_Container?
    var currentAnnotationValue: Amphisbaena_Element?
    
    func parse() {
        parser = XMLParser(data: stringData)
        parser?.delegate = self
        parser?.parse()
    }
    
    init?(XMLString string: String) {
        if let data = string.data(using: .utf8) {
            stringData = data
            resultContainer = Amphisbaena_TranskribusTEIContainer();
        }
        else {return nil}
    }
    
    struct ElementAttributeOrders {
        static let surface      = ["ulx","uly","lrx","lry","corresp"]
        static let graphic      = ["url", "width", "height"]
        static let zone         = ["points","ulx","uly","lrx","lry","rendition","subtype","xml:id"]
        static let teiElement   = ["facs","xml:id","n"]
    }
}

extension Amphisbaena_TranskribusTEIParser: XMLParserDelegate {
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        skipCharacters = false;
        switch (elementName) {
        case "TEI", "hi", "date", "placeName", "persName":
            break;
        case "teiHeader":
            let teiHeaderContainer = Amphisbaena_Container(withName: "teiHeader", isRoot: false)
            resultContainer?.teiHeader = teiHeaderContainer
            resultContainer?.addElement(element: teiHeaderContainer)
        case "fileDesc":
            guard let headerContainer = resultContainer?.teiHeader else {break;}
            let fileDescContainer = Amphisbaena_Container(withName: "fileDesc", isRoot: false)
            headerContainer.addElement(element: fileDescContainer)
            currentFileDesc = fileDescContainer
        case "titleStmt":
            guard let fileDesc = currentFileDesc else {break;}
            let titleStmtContainer = Amphisbaena_Container(withName: "titleStmt", isRoot: false)
            fileDesc.addElement(element: titleStmtContainer)
            currentTitleStmt = titleStmtContainer
        case "publicationStmt":
            guard let fileDesc = currentFileDesc else {break;}
            let publicationStmtContainer = Amphisbaena_Container(withName: "publicationStmt", isRoot: false)
            fileDesc.addElement(element: publicationStmtContainer)
            currentPublicationStmt = publicationStmtContainer
        case "sourceDesc":
            guard let fileDesc = currentFileDesc else {break;}
            let sourceDescContainer = Amphisbaena_Container(withName: "sourceDesc", isRoot: false)
            fileDesc.addElement(element: sourceDescContainer)
            currentSourceDesc = sourceDescContainer
        case "publisher":
            let publisher = Amphisbaena_Element(elementName: "publisher", attributes: nil, elementContent: nil)
            currentPublisher = publisher
        case "bibl":
            guard let sourceDesc = currentSourceDesc else {break;}
            let bibl = Amphisbaena_Container(withName: "bibl", isRoot: false)
            currentBibl = bibl
            sourceDesc.addElement(element: bibl)
        case "title":
            guard let titleStmt = currentTitleStmt else {break;}
            let title = Amphisbaena_Element(elementName: "title")
            title.elementAttributes = attributeDict
            titleStmt.addElement(element: title)
            currentTitle = title
        case "facsimile":
            let facsimileContainer = Amphisbaena_Container(withName: "facsimile", isRoot: false)
            facsimileContainer.elementAttributes = attributeDict
            resultContainer?.addElement(element: facsimileContainer)
            currentFacsimile = facsimileContainer
        case "surface":
            guard let facsimile = currentFacsimile else {break;}
            let surfaceContainer = Amphisbaena_Container(withName: "surface", isRoot: false, preferredAttributeOrder: ElementAttributeOrders.surface)
            facsimile.addElement(element: surfaceContainer)
            surfaceContainer.elementAttributes = attributeDict
            currentSurface = surfaceContainer
        case "graphic":
            guard let surface = currentSurface else {break;}
            let graphicElement = Amphisbaena_Element(elementName: "graphic", attributes: attributeDict, elementContent: nil)
            graphicElement.preferredAttributeOrder = ElementAttributeOrders.graphic
            surface.addElement(element: graphicElement)
        case "zone":
            guard let surface = currentSurface else {break;}
            let newZone = Amphisbaena_TranskribusTEIContainer_Zone(withName: "zone", isRoot: false, preferredAttributeOrder: ElementAttributeOrders.zone)
            newZone.elementAttributes = attributeDict
            if let zone = currentZones.last {
                zone.addElement_Subzone(subzone: newZone)
            }
            else {
                surface.addElement(element: newZone)
            }
            currentZones.append(newZone)
        case "text":
            let textContainer = Amphisbaena_Container(withName: "text", isRoot: false)
            resultContainer?.text = textContainer
            resultContainer?.addElement(element: textContainer)
        case "body":
            let bodyContainer = Amphisbaena_Container(withName: "body", isRoot: false)
            resultContainer?.text?.addElement(element: bodyContainer)
        case "pb":
            guard let body = resultContainer?.textBody else {break;}
            let newElement = Amphisbaena_Element(elementName: "pb", attributes: attributeDict, elementContent: nil)
            newElement.preferredAttributeOrder = ElementAttributeOrders.teiElement
            body.addElement(element: newElement)
        case "p":
            guard let body = resultContainer?.textBody else {break;}
            let containerParagraph = Amphisbaena_Container(withName: "p", isRoot: false, preferredAttributeOrder: ElementAttributeOrders.teiElement)
            containerParagraph.elementAttributes = attributeDict
            body.addElement(element: containerParagraph)
            currentParagraph = containerParagraph
        case "lb":
            guard let paragraph = currentParagraph else {break;}
            let newElement = Amphisbaena_Element(elementName: "lb", attributes: attributeDict, elementContent: nil)
            newElement.preferredAttributeOrder = ElementAttributeOrders.teiElement
            paragraph.addElement(element: newElement)
        case "w":
            guard let paragraph = currentParagraph else {break;}
            let newElement = Amphisbaena_Element(elementName: "w", attributes: attributeDict, elementContent: nil)
            newElement.elementIndentLevel += 1;
            currentWord = newElement
            paragraph.addElement(element: newElement)
        case "sic":
            guard let word = currentWord else {break;}
            let newSic = Amphisbaena_Element(elementName: "sic", attributes: attributeDict, elementContent: nil)
            word.addElement(element: newSic)
            currentSic = newSic
        case "forename", "surname":
            skipCharacters = true;
        default:
            print("UNHANDLED Begin Element:" + elementName)
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        var rememberCharacters = false;
        switch (elementName) {
        case "teiHeader", "text", "body", "pb", "TEI", "lb", "graphic", "forename", "surname":
            break;
        case "fileDesc":
            currentFileDesc = nil
        case "titleStmt":
            currentTitleStmt = nil
        case "publicationStmt":
            currentPublicationStmt = nil
        case "sourceDesc":
            currentSourceDesc = nil
        case "publisher":
            if let publisher = currentPublisher {
                publisher.elementContent = foundCharacters
                if let publicationStmt = currentPublicationStmt {
                    publicationStmt.addElement(element: publisher)
                }
                else if let _ = currentSourceDesc, let bibl = currentBibl {
                    bibl.addElement(element: publisher)
                }
            }
            currentPublisher = nil
        case "bibl":
            currentBibl = nil
        case "title":
            if let title = currentTitle {
                title.elementContent = foundCharacters
            }
            currentTitle = nil
        case "facsimile":
            currentFacsimile = nil
        case "surface":
            currentSurface = nil
        case "zone":
            currentZones.removeLast(1)
        case "p":
            currentParagraph = nil
        case "w":
            if let word = currentWord, foundCharacters.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
                word.elementContent = foundCharacters
            }
            currentWord = nil
        case "sic":
            if let sic = currentSic {
                sic.elementContent = foundCharacters
            }
            currentSic = nil
        case "hi", "date", "placeName", "persName":
            rememberCharacters = true;
        default:
            print("UNHANDLED End Element:" + elementName)
        }
        if (rememberCharacters == false) {self.foundCharacters = ""}
        skipCharacters = false;
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if string.trimmingCharacters(in: .whitespacesAndNewlines) == "" {return;}
        if skipCharacters == true {return;}
        self.foundCharacters += string
    }
}
