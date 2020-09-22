//
//  Amphisbaena_UnifiedTokenizer.swift
//  Amphisbaena
//
//  Created by Casey on 5/9/20.
//  Copyright © 2020 Casey Fasthorse. All rights reserved.
//
/*
 
 In a parsing system, true parsing is done on two passes: first, a pass is performed to transform the text data into "tokens", which are meaningful representations of the data storage. Then, the second pass goes over each generated token and uses it to make decisions.
 
 In Amphisbaena, to simplify the creation of a Unified File from other files, the contents of these files are tokenized together. Then the tokenized list is parsed into the single unified file without making expensive and complex decisions at generation time. This also makes the process fairly trivial to add, subtract, and adjust to the needs of the app and other parts of the data.
 
 */

import Foundation

class Amphisbaena_UnifiedTokenizer {
    struct Token: Equatable {
        var type: String = "TYPE"
        var identifier: String?
        var content: String?
        
        static func == (lhs: Token, rhs: Token) -> Bool {
            return lhs.type == rhs.type && lhs.identifier == rhs.identifier && lhs.content == rhs.content
        }
    }
    
    func flexTranskribus_tokenizeData(transkribusContainer: Amphisbaena_TranskribusTEIContainer, flexContainer: Amphisbaena_FlexTextContainer, wordLinkContainer: Amphisbaena_WordLinksContainer) -> [Token] {
        
        let flexFlatMap = flexContainer.flatMap(recursively: true)
        let transkribusFlatMap = transkribusContainer.flatMap(recursively: true)
        /*
        print(flexFlatMap.compactMap({ (taggable) -> String? in
            taggable.elementName+": "+(taggable.elementContent ?? "NIL")
        }))
        */
        var flexFlatMapIndex = 0
        var transkribusFlatMapIndex = 0
        
        var tokens: [Token] = []
        
        var currentParagraph: String = ""
        var currentPhrase: String = ""
        
        /*
         Tokenizing Transkribus and FLEx together is done through the Word Links as a base.
         
         Since it is not possible to generate word links that do not match the original FLEx file in count, and word links incorporate the "ground truth" from the FLEx data, we can use the Word Links as a reference point to make decisions when walking through the list and tokenizing.
         
         First, we have a counter start at 0. This counter represents a position in a flatmapped FLEx container (a FLEx container with all of its contents displayed in sequential order). As we walk through the word links, we make the counter walk down the list. Every time it encounters an element that is NOT the same word in the word links file, we add it as a token if it's a paragraph or a phrase. When it encounters the same word that is currently being processed in the word links file, we stop the walking and perform processing on the current word.
         
         In this way, once all the tokens are generated, each new paragraph token sets the current paragraph phrases get added to, and each new phrase token sets the current phrase words get added to.
         
         Phrase glosses also get tokenized at this point. However, since the last word in the word links will invariably occur before the last phrase gloss, a bit of code is added at the end to search for the last phrase gloss and add it to the tokenizer.
         */
        
        //var phraseCount = 0
        
        let wordLinks = wordLinkContainer.listWordLinks()
        for w in 0..<wordLinks.count {
            let wordLink = wordLinks[w]
            let guid = wordLink.getAttribute(attributeName: "guid")
            let groundtruth = wordLink.getAttribute(attributeName: "groundtruth")
        
            //continue to walk until we encounter our wordLink guid
            while flexFlatMapIndex < flexFlatMap.count {
                var stopWalking = false;
                var lookForPhraseGloss = false;
                
                var phraseToAdd: Token?
                var paragraphToAdd: Token?
                
                let element = flexFlatMap[flexFlatMapIndex]
                let elementGuid = element.getAttribute(attributeName: "guid") ?? ""
                let elementName = element.elementName
                let elementContent = element.elementContent
                
                if (elementGuid == guid || elementContent == groundtruth) {
                    stopWalking = true;
                }
                else {
                    switch elementName {
                    case "paragraph":
                        if elementGuid != currentParagraph {
                            let paragraphToken = Token(type: "flexparagraph", identifier: elementGuid, content: nil)
                            paragraphToAdd = paragraphToken
                            currentParagraph = elementGuid
                            lookForPhraseGloss = true;
                        }
                    case "phrase":
                        if elementGuid != currentPhrase {
                            let phraseToken = Token(type: "flexphrase", identifier: elementGuid, content: nil)
                            phraseToAdd = phraseToken
                            currentPhrase = elementGuid
                            lookForPhraseGloss = true;
                        }
                    case "languages":
                        lookForPhraseGloss = true;
                    default:
                        break;
                    }
                }
                //check for the existence of a phrase gloss, and if it exists, add it at this point
                //phrase glosses exist at the transition to a new phrase or paragraph, so check
                //the previous item in the flatmap when a transition occurs
                if (lookForPhraseGloss) {
                    let possibleGloss = flexFlatMap[max(0,flexFlatMapIndex-1)]
                    let possibleGlossType = possibleGloss.getAttribute(attributeName: "type") ?? ""
                    
                    if (possibleGlossType == "gls") {
                        let tokenGloss = Token(type: "flexphrasegloss", identifier: nil, content: possibleGloss.elementContent)
                        tokens.append(tokenGloss)
                    }
                }
                
                if let paragraphToAdd = paragraphToAdd {
                    tokens.append(paragraphToAdd)
                }
                if let phraseToAdd = phraseToAdd {
                    tokens.append(phraseToAdd)
                }
                
                if (stopWalking == true) {break;}
                flexFlatMapIndex += 1;
            }
            
            let flexToken = Token(type: "flexw", identifier: guid, content: groundtruth)
            tokens.append(flexToken)
            
            let facsElements = wordLink.getOrderedElements(ofName: "facs").compactMap{$0 as? Amphisbaena_Element}
            for facs in facsElements {
                let facs_id = facs.elementContent
                
                //continue to walk until we encounter our wordLink facs
                while transkribusFlatMapIndex < transkribusFlatMap.count {
                    var stopWalking = false;
                    
                    let element = transkribusFlatMap[transkribusFlatMapIndex]
                    let elementFacs = element.getAttribute(attributeName: "facs") ?? ""
                    let elementName = element.elementName
                    //let elementContent = element.elementContent
                    
                    if (elementFacs == facs_id) {
                        stopWalking = true;
                    }
                    else {
                        switch elementName {
                        case "pb":
                            if let n = element.getAttribute(attributeName: "n") {
                                let pagebreak = Token(type: "transkribusteipb", identifier: elementFacs, content: n)
                                tokens.append(pagebreak)
                            }
                        case "lb":
                            if let n = element.getAttribute(attributeName: "n") {
                                let pagebreak = Token(type: "transkribusteilb", identifier: elementFacs, content: n)
                                tokens.append(pagebreak)
                            }
                        default:
                            break;
                        }
                    }
                    
                    if (stopWalking == true) {break;}
                    transkribusFlatMapIndex += 1;
                }
                
                var transkribusContent: String?
                if let facs_id = facs_id {
                    let content = transkribusContainer.searchForElement(withName: "w", withAttribute: "facs", ofValue: facs_id, recursively: true)
                    transkribusContent = content.first?.elementContent
                }
                let facsToken = Token(type: "transkribusteiw", identifier: facs_id, content: transkribusContent)
                tokens.append(facsToken)
            }
            
            if (w == wordLinks.count-1) {
                //last one, find the last phrase gloss and add it
                let possibleGloss = flexFlatMap.last { (taggable) -> Bool in
                    if let taggable = taggable as? Amphisbaena_Element,
                        taggable.elementName == "item",
                        let taggableType = taggable.getAttribute(attributeName: "type"),
                        taggableType == "gls" {
                        return true
                    }
                    return false
                }
                
                if let possibleGloss = possibleGloss {
                    let possibleGlossType = possibleGloss.getAttribute(attributeName: "type") ?? ""
                    if (possibleGlossType == "gls") {
                        let tokenGloss = Token(type: "flexphrasegloss", identifier: nil, content: possibleGloss.elementContent)
                        tokens.append(tokenGloss)
                    }
                }
            }
        }
        
        return tokens
        
    }
    
    func flexTranskribus_tokenizeData_v02(transkribusContainer: Amphisbaena_TranskribusTEIContainer, flexContainer: Amphisbaena_FlexTextContainer, wordLinkContainer: Amphisbaena_WordLinksContainer) -> [Token] {
        
        let flexFlatMap = flexContainer.flatMap(recursively: true)
        let transkribusFlatMap = transkribusContainer.flatMap(recursively: true)
        let flexWords = flexContainer.getAll_Word()
        let transkribusWords = transkribusContainer.getAll_w()
        
        var flexFlatMapIndex = 0
        var transkribusFlatMapIndex = 0
        
        var tokens: [Token] = []
        
        var currentParagraph: String = ""
        var currentPhrase: String = ""
        
        let wordLinks = wordLinkContainer.listWordLinks()
        
        for w in 0..<wordLinks.count {
            let wordLink = wordLinks[w]
            tokens.append(Token(type: "wordLinkBegin", identifier: String(w), content: nil))
            let guid = wordLink.getAttribute(attributeName: "guid")
            let facs = wordLink.getAttribute(attributeName: "facs")
            
            while flexFlatMapIndex < flexFlatMap.count {
                var stopWalking = false;
                var lookForPhraseGloss = false;
                
                var phraseToAdd: Token?
                var paragraphToAdd: Token?
                
                let element = flexFlatMap[flexFlatMapIndex]
                let elementGuid = element.getAttribute(attributeName: "guid") ?? ""
                let elementName = element.elementName
                let elementContent = element.elementContent
                
                if (elementGuid == guid) {
                    stopWalking = true;
                }
                else {
                    switch elementName {
                    case "paragraph":
                        if elementGuid != currentParagraph {
                            let paragraphToken = Token(type: "flexparagraph", identifier: elementGuid, content: nil)
                            paragraphToAdd = paragraphToken
                            currentParagraph = elementGuid
                            lookForPhraseGloss = true;
                        }
                    case "phrase":
                        if elementGuid != currentPhrase {
                            let phraseToken = Token(type: "flexphrase", identifier: elementGuid, content: nil)
                            phraseToAdd = phraseToken
                            currentPhrase = elementGuid
                            lookForPhraseGloss = true;
                        }
                    case "languages":
                        lookForPhraseGloss = true;
                    /*
                    case "item":
                        let attributes = element.elementAttributes;
                        if let attributes = attributes,
                            let elementType = attributes["type"] {
                            if elementType == "gls" {
                                let tokenGloss = Token(type: "flexphrasegloss", identifier: nil, content: element.elementContent)
                                tokens.append(tokenGloss)
                            }
                        }
                    */
                    default:
                        break;
                    }
                }
                //check for the existence of a phrase gloss, and if it exists, add it at this point
                //phrase glosses exist at the transition to a new phrase or paragraph, so check
                //the previous item in the flatmap when a transition occurs
                if (lookForPhraseGloss) {
                    var foundGloss = false;
                    for i in 1...2 {
                        let possibleGloss = flexFlatMap[max(0,flexFlatMapIndex-i)]
                        let possibleGlossType = possibleGloss.getAttribute(attributeName: "type") ?? ""
                        
                        if (foundGloss == false) {
                            if (possibleGlossType == "gls") {
                                let tokenGloss = Token(type: "flexphrasegloss", identifier: nil, content: possibleGloss.elementContent)
                                tokens.append(tokenGloss)
                                foundGloss = true;
                            }
                        }
                        
                        if (possibleGlossType == "note") {
                            let tokenGloss = Token(type: "flexphrasenote", identifier: nil, content: possibleGloss.elementContent)
                            tokens.append(tokenGloss)
                        }
                    }
                }
                
                if let paragraphToAdd = paragraphToAdd {
                    tokens.append(paragraphToAdd)
                }
                if let phraseToAdd = phraseToAdd {
                    tokens.append(phraseToAdd)
                }
                
                if (stopWalking == true) {break;}
                flexFlatMapIndex += 1;
            }
            
            let flexIDs = wordLink.getOrderedElements(ofName: "guid") as? [Amphisbaena_Element]
            if let flexIDs = flexIDs {
                for flexID in flexIDs {
                    let flexguid = flexID.elementContent ?? ""
                    let groundtruth = flexID.getAttribute(attributeName: "groundtruth") ?? ""
                    let flexToken = Token(type: "flexw", identifier: flexguid, content: groundtruth)
                    tokens.append(flexToken)
                }
            }
            
            let facsElements = wordLink.getOrderedElements(ofName: "facs").compactMap{$0 as? Amphisbaena_Element}
            for facs in facsElements {
                let facs_id = facs.elementContent
                
                //continue to walk until we encounter our wordLink facs
                while transkribusFlatMapIndex < transkribusFlatMap.count {
                    var stopWalking = false;
                    
                    let element = transkribusFlatMap[transkribusFlatMapIndex]
                    let elementFacs = element.getAttribute(attributeName: "facs") ?? ""
                    let elementName = element.elementName
                    
                    if (elementFacs == facs_id) {
                        stopWalking = true;
                    }
                    else {
                        switch elementName {
                        case "pb":
                            if let n = element.getAttribute(attributeName: "n") {
                                let pagebreak = Token(type: "transkribusteipb", identifier: elementFacs, content: n)
                                tokens.append(pagebreak)
                            }
                        case "lb":
                            if let n = element.getAttribute(attributeName: "n") {
                                let pagebreak = Token(type: "transkribusteilb", identifier: elementFacs, content: n)
                                tokens.append(pagebreak)
                            }
                        default:
                            break;
                        }
                    }
                    
                    if (stopWalking == true) {break;}
                    transkribusFlatMapIndex += 1;
                }
                
                var transkribusContent: String?
                if let facs_id = facs_id {
                    let content = transkribusContainer.searchForElement(withName: "w", withAttribute: "facs", ofValue: facs_id, recursively: true)
                    transkribusContent = content.first?.elementContent
                }
                let facsToken = Token(type: "transkribusteiw", identifier: facs_id, content: transkribusContent)
                tokens.append(facsToken)
            }
            
            if (w == wordLinks.count-1) {
                //last one, find the last phrase gloss and add it
                let possibleGloss = flexFlatMap.last { (taggable) -> Bool in
                    if let taggable = taggable as? Amphisbaena_Element,
                        taggable.elementName == "item",
                        let taggableType = taggable.getAttribute(attributeName: "type"),
                        taggableType == "gls" {
                        return true
                    }
                    return false
                }
                
                if let possibleGloss = possibleGloss {
                    let possibleGlossType = possibleGloss.getAttribute(attributeName: "type") ?? ""
                    if (possibleGlossType == "gls") {
                        let tokenGloss = Token(type: "flexphrasegloss", identifier: nil, content: possibleGloss.elementContent)
                        tokens.append(tokenGloss)
                    }
                }
            }
            
            tokens.append(Token(type: "wordLinkEnd", identifier: String(w), content: nil))
        }
        
        return tokens
        
    }
}
