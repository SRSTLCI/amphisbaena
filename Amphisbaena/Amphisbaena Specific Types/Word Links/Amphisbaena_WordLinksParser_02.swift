//
//  Amphisbaena_WordLinksParser.swift
//  Amphisbaena
//
//  Created by Casey on 5/6/20.
//  Copyright © 2020 Casey Fasthorse. All rights reserved.
//

import Foundation

class Amphisbaena_WordLinksParser_Format02: Amphisbaena_WordLinksParser {
    var currentModifierWordLink: Amphisbaena_WordLinksModifier.WordLink?
    var modifierWordLinks: [Amphisbaena_WordLinksModifier.WordLink] = []
    
    override var version: Amphisbaena_WordLinksContainer.Version {
        return .v02
    }

    override func parse() {
        parser = XMLParser(data: stringData)
        modifierWordLinks = [];
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

extension Amphisbaena_WordLinksParser_Format02 {
    override func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        skipCharacters = false;
        switch (elementName) {
        case "wordLink":
            currentModifierWordLink = Amphisbaena_WordLinksModifier.WordLink()
            let attributes = attributeDict
            if let facsFirst = attributes["facsFirst"], let facsFirstInt = Int(facsFirst) {currentModifierWordLink?.facsFirst = facsFirstInt}
            if let facsCount = attributes["facsCount"], let facsCountInt = Int(facsCount) {currentModifierWordLink?.facsCount = facsCountInt}
            if let guidFirst = attributes["guidFirst"], let guidFirstInt = Int(guidFirst) {currentModifierWordLink?.guidsFirst = guidFirstInt}
            if let guidCount = attributes["guidCount"], let guidCountInt = Int(guidCount) {currentModifierWordLink?.guidsCount = guidCountInt}
        case "wordLinks", "formatVersion", "guid", "facs":
            break;
        default:
            print("UNHANDLED Begin Element:" + elementName)
        }
    }
    
    override func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        switch (elementName) {
        case "wordLink":
            if let currentModifierWordLink = currentModifierWordLink {
                modifierWordLinks.append(currentModifierWordLink)
            }
            currentModifierWordLink = nil
        case "wordLinks", "formatVersion", "guid", "facs":
            break;
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
}
