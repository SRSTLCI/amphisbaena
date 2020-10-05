//
//  Amphisbaena_WordLinksParser.swift
//  Amphisbaena
//
//  Created by Casey on 5/6/20.
//  Copyright © 2020 Casey Fasthorse. All rights reserved.
//

import Foundation

class Amphisbaena_WordLinksParser_Format01: Amphisbaena_WordLinksParser {
    override var version: Amphisbaena_WordLinksContainer.Version {
        return .v01
    }

    override func parse() {
        parser = XMLParser(data: stringData)
        parser?.delegate = self
        parser?.parse()
    }
    
    override init?(XMLString string: String) {
        super.init(XMLString: string)
    }
    
    struct ElementAttributeOrders {
        static let wordLink     = ["guid","groundtruth"]
        static let language     = ["lang","font","vernacular"]
    }
}

extension Amphisbaena_WordLinksParser_Format01 {
    override func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        skipCharacters = false;
        switch (elementName) {
        case "wordLink":
            let wordLinkContainer = Amphisbaena_Container(withName: "wordLink", isRoot: false)
            wordLinkContainer.elementAttributes = attributeDict
            wordLinkContainer.preferredAttributeOrder = ElementAttributeOrders.wordLink
            resultContainer?.addElement(element: wordLinkContainer)
            currentWordLink = wordLinkContainer
        case "facs":
            let facs = Amphisbaena_Element(elementName: "facs", attributes: attributeDict, elementContent: nil)
            currentFacs = facs
        default:
            print("UNHANDLED Begin Element:" + elementName)
        }
    }
    
    override func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        switch (elementName) {
        case "wordLink":
            currentWordLink = nil
        case "facs":
            if let currentFacs = currentFacs {
                currentFacs.elementContent = foundCharacters
                currentWordLink?.addElement(element: currentFacs)
            }
            currentFacs = nil
        default:
            print("UNHANDLED End Element:" + elementName)
        }
        self.foundCharacters = ""
        skipCharacters = false;
    }
    
    override func parser(_ parser: XMLParser, foundCharacters string: String) {
        if string.trimmingCharacters(in: .whitespacesAndNewlines) == "" {return;}
        if skipCharacters == true {return;}
        self.foundCharacters += string
    }
    
    /*
    override func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        skipCharacters = false;
        switch (elementName) {
        case "wordLinks":
            break;
        case "wordLink":
            let wordLinkContainer = Amphisbaena_Container(withName: "wordLink", isRoot: false)
            wordLinkContainer.elementAttributes = attributeDict
            wordLinkContainer.preferredAttributeOrder = ElementAttributeOrders.wordLink
            resultContainer?.addElement(element: wordLinkContainer)
            currentWordLink = wordLinkContainer
        case "facs":
            let facs = Amphisbaena_Element(elementName: "facs", attributes: attributeDict, elementContent: nil)
            currentFacs = facs
        default:
            print("UNHANDLED Begin Element:" + elementName)
        }
    }
    
    override func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        switch (elementName) {
        case "wordLinks":
            break;
        case "wordLink":
            currentWordLink = nil
        case "facs":
            if let currentFacs = currentFacs {
                currentFacs.elementContent = foundCharacters
                currentWordLink?.addElement(element: currentFacs)
            }
            currentFacs = nil
        default:
            print("UNHANDLED End Element:" + elementName)
        }
        self.foundCharacters = ""
        skipCharacters = false;
    }
    
    override func parser(_ parser: XMLParser, foundCharacters string: String) {
        if string.trimmingCharacters(in: .whitespacesAndNewlines) == "" {return;}
        if skipCharacters == true {return;}
        self.foundCharacters += string
    }
    */
}
