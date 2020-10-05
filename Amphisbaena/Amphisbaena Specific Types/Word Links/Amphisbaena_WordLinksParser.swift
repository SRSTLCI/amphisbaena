//
//  Amphisbaena_WordLinksParser.swift
//  Amphisbaena
//
//  Created by Casey on 5/6/20.
//  Copyright © 2020 Casey Fasthorse. All rights reserved.
//

import Foundation

class Amphisbaena_WordLinksParser: NSObject {
    
    var version: Amphisbaena_WordLinksContainer.Version {
        return .v01
    }
    
    var stringData: Data
    
    var parser: XMLParser?
    
    var resultContainer: Amphisbaena_WordLinksContainer? {
        didSet {
            print("Parser result container has been set.")
        }
    }
    
    var currentWordLink: Amphisbaena_Container?
    var currentFacs: Amphisbaena_Element?
    
    var foundCharacters: String = ""
    var skipCharacters: Bool = false;
    
    func parse() {
        parser = XMLParser(data: stringData)
        parser?.delegate = self
        parser?.parse()
    }
    
    init?(XMLString string: String) {
        if let data = string.data(using: .utf8) {
            stringData = data
            resultContainer = Amphisbaena_WordLinksContainer();
        }
        else {return nil}
    }
}

extension Amphisbaena_WordLinksParser: XMLParserDelegate {
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
    }
}
