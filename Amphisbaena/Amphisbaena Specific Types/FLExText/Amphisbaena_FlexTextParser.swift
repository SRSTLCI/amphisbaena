//
//  Amphisbaena_FlexTextParser.swift
//  Amphisbaena
//
//  Created by Casey on 5/4/20.
//  Copyright © 2020 Casey Fasthorse. All rights reserved.
//

import Foundation

class Amphisbaena_FlexTextParser: NSObject {
    var stringData: Data
    
    var parser: XMLParser?
    
    var resultContainer: Amphisbaena_FlexTextContainer?
    
    var foundCharacters: String = ""
    var skipCharacters: Bool = false;
    
    var currentInterlinearText: Amphisbaena_Container?
    var currentLanguages: Amphisbaena_Container?
    var currentParagraphs: Amphisbaena_Container?
    var currentParagraph: Amphisbaena_Container?
    var currentPhrases: Amphisbaena_Container?
    var currentPhrase: Amphisbaena_Container?
    var currentWords: Amphisbaena_Container?
    var currentWord: Amphisbaena_Container?
    var currentItem: Amphisbaena_Element?
    
    func parse() {
        parser = XMLParser(data: stringData)
        parser?.delegate = self
        parser?.parse()
    }
    
    func getCurrentItemRoot() -> Amphisbaena_Container? {
        if let word = currentWord {return word}
        if let phrase = currentPhrase {return phrase}
        if let paragraph = currentParagraph {return paragraph}
        if let interlinearText = currentInterlinearText {return interlinearText}
        return nil
    }
    
    init?(XMLString string: String) {
        if let data = string.data(using: .utf8) {
            stringData = data
            resultContainer = Amphisbaena_FlexTextContainer();
        }
        else {return nil}
    }
    
    struct ElementAttributeOrders {
        static let item         = ["type","lang"]
        static let language     = ["lang","font","vernacular"]
    }
}

extension Amphisbaena_FlexTextParser: XMLParserDelegate {
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        skipCharacters = false;
        switch (elementName) {
        case "document":
            break;
        case "interlinear-text":
            let interlinearTextContainer = Amphisbaena_Container(withName: "interlinear-text", isRoot: false)
            interlinearTextContainer.elementAttributes = attributeDict
            resultContainer?.addElement(element: interlinearTextContainer)
            resultContainer?.interlinearText = interlinearTextContainer
            currentInterlinearText = interlinearTextContainer
        case "paragraphs":
            guard let interlinearText = currentInterlinearText else {break;}
            let paragraphs = Amphisbaena_Container(withName: "paragraphs", isRoot: false)
            interlinearText.addElement(element: paragraphs)
            currentParagraphs = paragraphs
        case "paragraph":
            guard let paragraphs = currentParagraphs else {break;}
            let paragraphContainer = Amphisbaena_Container(withName: "paragraph", isRoot: false)
            paragraphContainer.elementAttributes = attributeDict
            paragraphs.addElement(element: paragraphContainer)
            currentParagraph = paragraphContainer
        case "phrases":
            guard let paragraph = currentParagraph else {break;}
            let phrases = Amphisbaena_Container(withName: "phrases", isRoot: false)
            currentPhrases = phrases
            paragraph.addElement(element: phrases)
        case "phrase":
            guard let phrases = currentPhrases else {break;}
            let phrase = Amphisbaena_Container(withName: "phrase", isRoot: false)
            phrase.elementAttributes = attributeDict
            phrases.addElement(element: phrase)
            currentPhrase = phrase
        case "words":
            guard let phrase = currentPhrase else {break;}
            let words = Amphisbaena_Container(withName: "words", isRoot: false)
            phrase.addElement(element: words)
            currentWords = words
        case "word":
            guard let words = currentWords else {break;}
            let word = Amphisbaena_Container(withName: "word", isRoot: false)
            word.elementAttributes = attributeDict
            words.addElement(element: word)
            currentWord = word
        case "item":
            guard let root = getCurrentItemRoot() else {break;}
            let item = Amphisbaena_Element(elementName: "item", attributes: attributeDict, elementContent: nil)
            item.preferredAttributeOrder = ElementAttributeOrders.item
            root.addElement(element: item)
            currentItem = item
        case "languages":
            guard let interlinearText = currentInterlinearText else {break;}
            let languages = Amphisbaena_Container(withName: "languages", isRoot: false)
            interlinearText.addElement(element: languages)
            currentLanguages = languages
        case "language":
            guard let languages = currentLanguages else {break;}
            let language = Amphisbaena_Element(elementName: "language", attributes: attributeDict, elementContent: nil)
            language.preferredAttributeOrder = ElementAttributeOrders.language
            languages.addElement(element: language)
        default:
            print("UNHANDLED Begin Element:" + elementName)
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        switch (elementName) {
        case "document", "interlinear-text", "language":
            break;
        case "paragraphs":
            currentParagraphs = nil
        case "paragraph":
            currentParagraph = nil
        case "phrases":
            currentPhrases = nil
        case "phrase":
            currentPhrase = nil
        case "words":
            currentWords = nil
        case "word":
            currentWord = nil
        case "languages":
            currentLanguages = nil
        case "item":
            currentItem?.elementContent = self.foundCharacters
            currentItem = nil
        default:
            print("UNHANDLED End Element:" + elementName)
        }
        self.foundCharacters = ""
        skipCharacters = false;
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if string.trimmingCharacters(in: .whitespacesAndNewlines) == "" {return;}
        if skipCharacters == true {return;}
        self.foundCharacters += string
    }
}
