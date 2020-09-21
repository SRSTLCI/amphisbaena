//
//  Amphisbaena_UnifiedContainer_TextBody_MultipleFiles.swift
//  Amphisbaena
//
//  Created by Casey on 5/14/20.
//  Copyright © 2020 Casey Fasthorse. All rights reserved.
//

import Foundation

extension Amphisbaena_UnifiedContainer_TextBody {
    convenience init(tokensFromTranskribusFlex tokens: [Amphisbaena_UnifiedTokenizer.Token], transkribusContainer: Amphisbaena_TranskribusTEIContainer, flexContainer: Amphisbaena_FlexTextContainer, TEITagsContainer: Amphisbaena_TEITagContainer?, elanContainer: Amphisbaena_ELANContainer?) {
        self.init();
        generateContent(tokensFromTranskribusFlex: tokens, transkribusContainer: transkribusContainer, flexContainer: flexContainer, TEITagsContainer: TEITagsContainer, elanContainer: elanContainer)
    }
    
    struct SortCriteria {
        static let sortCriteria: ((AmphisbaenaXMLTaggable, AmphisbaenaXMLTaggable) -> Bool) = {(taggable1, taggable2) -> Bool in
            if taggable1.elementName == "flex",
                taggable2.elementName == "flex" {
                if let taggable1guid = taggable1.getAttribute(attributeName: "guid"),
                    let taggable2guid = taggable2.getAttribute(attributeName: "guid") {
                    let taggable1order = flexWordOrder[taggable1guid]
                    let taggable2order = flexWordOrder[taggable2guid]
                    if let value1 = taggable1order, let value2 = taggable2order {
                        return value1 < value2
                    }
                    else if taggable1order != nil {
                        return true
                    }
                    else {
                        return false
                    }
                }
                else {
                    if taggable1.getAttribute(attributeName: "guid") != nil {
                        return true
                    }
                    else {
                        return false
                    }
                }
            }
            else if taggable1.elementName == "flex" {return true;}
            else if taggable2.elementName == "flex" {return false;}
            else if taggable1.elementName == "orig" {return false;}
            else if taggable2.elementName == "orig" {return true;}
            else {return taggable1.elementName < taggable2.elementName}
        }
        static var flexWordOrder = [String : Int]();
    }
    
    func generateContent(tokensFromTranskribusFlex tokens: [Amphisbaena_UnifiedTokenizer.Token], transkribusContainer: Amphisbaena_TranskribusTEIContainer, flexContainer: Amphisbaena_FlexTextContainer, TEITagsContainer: Amphisbaena_TEITagContainer?, elanContainer: Amphisbaena_ELANContainer?) {
        
        var currentPhrases: Amphisbaena_Container?
        var currentPhrase: Amphisbaena_Container?
        var currentUtterances: Amphisbaena_Container?
        var currentUtterance: Amphisbaena_Container?
        var currentWords: Amphisbaena_Container?
        var currentWord: Amphisbaena_Container?
        /*
        var tokensString = ""
        for token in tokens {
            tokensString += token.type
            tokensString += ": ["
            tokensString += token.identifier ?? "No ID"
            tokensString += " -> "
            tokensString += token.content ?? "No Content"
            tokensString += "]\n"
        }
        print(tokensString)
        */
        
        var currentPhraseGuid: String?
        var currentParagraphFacs: String?
        
        var elanPhrases: [(String, String)]?
        var phraseCount = 0;
        if let elanContainer = elanContainer {
            elanPhrases = []
            let annotations = elanContainer.tier_GetOrderedAnnotations(tierID: "A_sentence")
            print(annotations.count)
            for annotation in annotations {
                guard let annotation = annotation as? Amphisbaena_Container,
                    let annotationAlignable = annotation.getFirstElement(ofName: "ALIGNABLE_ANNOTATION"),
                    let ts1 = annotationAlignable.getAttribute(attributeName: "TIME_SLOT_REF1"),
                    let ts2 = annotationAlignable.getAttribute(attributeName: "TIME_SLOT_REF2"),
                    let t1 = elanContainer.getTimeSlotValue(timeslot: ts1),
                    let t2 = elanContainer.getTimeSlotValue(timeslot: ts2) else {continue}
                
                let phraseTs = (t1, t2)
                elanPhrases?.append(phraseTs)
            }
            if elanPhrases?.count == 0 {elanPhrases = nil}
            print("ELAN CONTAINER FOUND, PHRASES FOUND: "+String(elanPhrases?.count ?? 0))
        }
        
        var canCreateNewWord = true;
        
        for token in tokens {
            let type = token.type
            switch type {
            case "flexparagraph":
                guard let guid = token.identifier else {break;}
                
                canCreateNewWord = true;
                let newParagraph = Amphisbaena_Container(withName: "p", isRoot: false)
                newParagraph.elementAttributes = ["guid" : guid]
                containerParagraphs.addElement(element: newParagraph)
                containerParagraphsP.append(newParagraph)
                currentContainerParagraphP = newParagraph;

                currentContainerParagraphP?.preferredAttributeOrder = ElementAttributeOrder.paragraph
                currentParagraphFacs = nil
                
                let phrases = Amphisbaena_Container(withName: "phrases", isRoot: false)
                currentContainerParagraphP?.addElement(element: phrases)
                currentPhrases = phrases
            case "flexphrase":
                guard let guid = token.identifier,
                    let currentPhrases = currentPhrases else {break;}
                
                canCreateNewWord = true;
                let phrase = Amphisbaena_Container(withName: "phr", isRoot: false)
                phrase.elementAttributes = ["guid" : guid]
                
                if let elanPhrases = elanPhrases,
                    phraseCount < elanPhrases.count {
                    let elanPhrase = elanPhrases[phraseCount]
                    phrase.elementAttributes?["start"] = elanPhrase.0
                    phrase.elementAttributes?["end"]   = elanPhrase.1
                }
                
                phrase.preferredAttributeOrder = ElementAttributeOrder.phr
                currentPhraseGuid = guid
                currentPhrases.addElement(element: phrase)
                currentPhrase = phrase
                
                let utterances = Amphisbaena_Container(withName: "utterances", isRoot: false)
                currentPhrase?.addElement(element: utterances)
                currentUtterances = utterances
                
                let utterance = Amphisbaena_Container(withName: "u", isRoot: false)
                let utteranceAttributes = ["start" : "", "end": ""]
                utterance.preferredAttributeOrder = ElementAttributeOrder.utterance
                utterance.elementAttributes = utteranceAttributes
                utterances.addElement(element: utterance)
                currentUtterance = utterance
                
                let words = Amphisbaena_Container(withName: "words", isRoot: false)
                currentUtterance?.addElement(element: words)
                currentWords = words
                
                phraseCount += 1;
                
            case "flexw":
                currentWord?.sortElements(by: SortCriteria.sortCriteria)
                if let currentWords = currentWords {
                    if (canCreateNewWord == true) {
                        let word = Amphisbaena_Container(withName: "word", isRoot: false)
                        word.elementAttributes = ["xml:id" : ""]
                        currentWords.addElement(element: word)
                        currentWord = word
                        canCreateNewWord = false;
                        SortCriteria.flexWordOrder = [:]
                    }
                    
                    let flex = Amphisbaena_Container(withName: "flex", isRoot: false)
                    if let guid = token.identifier {
                        flex.elementAttributes = ["guid" : guid]
                    }
                    if let content = token.content {
                        flex.addElement(element: Amphisbaena_Element(elementName: "reg", attributes: nil, elementContent: content))
                        if let guid = token.identifier,
                            let wordElement = flexContainer.searchForElement(withName: "word", withAttribute: "guid", ofValue: guid, recursively: true).first as? Amphisbaena_Container,
                            let itemGloss = wordElement.searchForElement(withName: "item", withAttribute: "type", ofValue: "gls").first {
                            let gloss = Amphisbaena_Element(elementName: "gloss", attributes: nil, elementContent: itemGloss.elementContent)
                            flex.addElement(element: gloss)
                            
                        }
                    }
                    currentWord?.addElement(element: flex)
                    currentWord?.sortElements(by: SortCriteria.sortCriteria)
                    if let guid = token.identifier {
                        let count = SortCriteria.flexWordOrder.count
                        SortCriteria.flexWordOrder[guid] = count
                    }
                }
            case "transkribusteipb":
                if let identifier = token.identifier,
                    let currentWord = currentWord {
                    canCreateNewWord = true;
                    let orig = multipleFiles_getWordOrig(word: currentWord)
                    
                    let transkribusPb = Amphisbaena_Element(elementName: "pb")
                    transkribusPb.preferredAttributeOrder = ElementAttributeOrder.pb
                    transkribusPb.elementAttributes = [
                        "facs" : identifier,
                    ]
                    if let content = token.content {
                        transkribusPb.elementAttributes?["n"] = content
                    }
                    orig.addElement(element: transkribusPb)
                }
            case "transkribusteilb":
            if let identifier = token.identifier,
                let currentWord = currentWord {
                canCreateNewWord = true;
                let orig = multipleFiles_getWordOrig(word: currentWord)
                
                let transkribusLb = Amphisbaena_Element(elementName: "lb")
                transkribusLb.preferredAttributeOrder = ElementAttributeOrder.lb
                transkribusLb.elementAttributes = [
                    "facs" : identifier,
                ]
                if let content = token.content {
                    transkribusLb.elementAttributes?["n"] = content
                }
                orig.addElement(element: transkribusLb)
                
            }
            case "transkribusteiw":
                if let identifier = token.identifier,
                    let currentWord = currentWord {
                    canCreateNewWord = true;
                    //add tags
                    if let teiTagsContainer = TEITagsContainer {
                        let tagFacs = identifier.replacingOccurrences(of: "#", with: "")
                        if let tagContainer = teiTagsContainer.searchForElement(withName: "tag", withAttribute: "facs", ofValue: tagFacs).first as? Amphisbaena_Container {
                            //print(identifier+" has tags.")
                            
                            if let elements = tagContainer.elementEnclosing {
                                for tag in elements {
                                    guard let tag = tag as? Amphisbaena_Element else {continue;}
                                    if currentWord.hasElementsMatching(name: tag.elementName, matchingAttributes: tag.elementAttributes).isEmpty == false {continue;}
                                    
                                    let newTag = tag.copy() as! Amphisbaena_Element
                                    currentWord.addElement(element: newTag)
                                }
                            }
                        }
                    }
                    
                    //add transkribus w
                    
                    let orig = multipleFiles_getWordOrig(word: currentWord)
                    
                    let transkribusW = Amphisbaena_Element(elementName: "w")
                    transkribusW.preferredAttributeOrder = ElementAttributeOrder.w
                    transkribusW.elementAttributes = [
                        "facs" : identifier,
                        "cert" : ""
                    ]
                    transkribusW.elementContent = token.content
                    
                    orig.addElement(element: transkribusW)
                    
                    if let teiW = transkribusContainer.textBody?.searchForElement(withName: "w", withAttribute: "facs", ofValue: identifier, recursively: true).first {
                        let ancestors = teiW.getAllAncestors()
                        if let paragraphFacs = ancestors.first(where: {$0.elementName == "p"})?.getAttribute(attributeName: "facs") {
                            
                            if (paragraphFacs != currentParagraphFacs) {
                                currentContainerParagraphP?.elementAttributes?["facs"] = paragraphFacs
                                currentParagraphFacs = paragraphFacs
                            }
                        }
                    }
                    
                     currentWord.sortElements(by: SortCriteria.sortCriteria)
                }
            case "flexphrasegloss":
                if let guid = currentPhrase?.getAttribute(attributeName: "guid") ,
                    let flexPhrase = flexContainer.searchForElement(withAttribute: "guid", ofValue: guid, recursively: true).first as? Amphisbaena_Container,
                    let gloss = flexPhrase.searchForElement(withName: "item", withAttribute: "type", ofValue: "gls", recursively: false).first,
                    let lang = gloss.getAttribute(attributeName: "lang") {
                    canCreateNewWord = true;
                    let newGloss = Amphisbaena_Element(elementName: "gloss", attributes: ["lang" : lang, "cert" : ""], elementContent: gloss.elementContent)
                    newGloss.preferredAttributeOrder = ElementAttributeOrder.gloss
                    currentPhrase?.addElement(element: newGloss)
                    
                }
            default:
                break;
            }
        }
    }
    
    func multipleFiles_getWordOrig(word: Amphisbaena_Container) -> Amphisbaena_Container {
        if let orig = word.getFirstElement(ofName: "orig") as? Amphisbaena_Container {return orig}
        else {
            let orig = Amphisbaena_Container(withName: "orig", isRoot: false)
            word.addElement(element: orig)
            return orig
        }
    }
}
