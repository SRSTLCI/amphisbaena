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
    
    struct RegEx {
        static let regexNoteGloss   = try! NSRegularExpression(pattern: #"(\«)(.+?)(\»)"#, options: [])
        static let regexNoteReg     = try! NSRegularExpression(pattern: #"(\{)(.+?)(\})"#, options: [])
    }
    
    struct PhraseNotes {
        var contentRaw: String
        var content: String?
        
        var glossRanges: [NSRange] = []
        var regRanges: [NSRange] = []
        
        func getGlossContent() -> [String] {
            guard let content = content else {return []}
            var strings: [String] = []
            for glossRange in glossRanges {
                if let range = Range(glossRange, in: content) {
                    strings.append(String(content[range]))
                }
            }
            return strings
        }
        
        func getRegContent() -> [String] {
            guard let content = content else {return []}
            var strings: [String] = []
            for regRange in regRanges {
                if let range = Range(regRange, in: content) {
                    strings.append(String(content[range]))
                }
            }
            return strings
        }
        
        mutating func format() {
            let newContent = contentRaw;
            let matchRange = NSRange(newContent.startIndex..<newContent.endIndex, in: newContent)
            let glossMatches = RegEx.regexNoteGloss.matches(in: newContent, options: [], range: matchRange)
            let regMatches = RegEx.regexNoteReg.matches(in: newContent, options: [], range: matchRange)
            
            print("NOTE TEXT: "+newContent)
            var glossCount = 0;
            for match in glossMatches {
                glossCount += 1;
                print(String(format: "MATCHES IN GLOSS %d: ", glossCount))
                for r in 0..<match.numberOfRanges {
                    guard let matchRange = Range(match.range(at: r), in: newContent) else {continue;}
                    let matchStr = String(newContent[matchRange])
                    print(matchStr)
                }
            }
            var regCount = 0;
            for match in regMatches {
                regCount += 1;
                print(String(format: "MATCHES IN REG %d: ", regCount))
                for r in 0..<match.numberOfRanges {
                    guard let matchRange = Range(match.range(at: r), in: newContent) else {continue;}
                    let matchStr = String(newContent[matchRange])
                    print(matchStr)
                }
            }
            print("NOTE TEXT END.")
            
            let allMatches = glossMatches + regMatches;
            var allRanges = allMatches.reduce([Range<String.Index>]()) { (resultArr, newResult) in
                var resultRange = resultArr
                for r in 1..<newResult.numberOfRanges {
                    guard let matchRange = Range(newResult.range(at: r), in: newContent) else {continue}
                    resultRange.append(matchRange)
                }
                return resultRange
            }
            var startIndex = 0;
            var currentMemoRange: Range<String.Index>?
            for c in 1..<newContent.count {
                guard let newRange = Range(NSRange(startIndex...c), in: newContent) else {continue;}
                print(newRange)
                var collision = false
                for range in allRanges {
                    collision = range.overlaps(newRange)
                    if (collision) {break;}
                }
                if collision == true {
                    if let currentMemoRange = currentMemoRange {allRanges.append(currentMemoRange)}
                    startIndex = c;
                    currentMemoRange = nil
                }
                else {
                    currentMemoRange = newRange
                }
            }
            var orderedRanges = allRanges.sorted { (range1, range2) -> Bool in
                if range1.overlaps(range2) == false {
                    return range1.lowerBound < range2.lowerBound
                }
                else {
                    return false
                }
            }
            //add last range
            var lastRange: Range<String.Index>?
            if let lastOrderedRange = orderedRanges.last {
                let nsRange = NSRange(lastOrderedRange.upperBound..<newContent.endIndex, in: newContent)
                lastRange = Range(nsRange, in: newContent)
            }
            if let lastRange = lastRange {orderedRanges.append(lastRange)}
            
            let textTokens = orderedRanges.compactMap({ (range) -> String in
                let newStr = String(newContent[range]);
                return newStr
            })
            print("TEXT TOKENS: "+String(describing: textTokens))
            if orderedRanges.count > 0 {
                content = ""
                var foundCurlyBrace = false
                var foundFrenchQuote = false
                var offsetCorrection = 1;
                for range in orderedRanges {
                    let textToken = String(newContent[range])
                    if textToken.contains("{") {
                        foundCurlyBrace = true;
                    }
                    else if textToken.contains("}") {
                        foundCurlyBrace = false;
                    }
                    else if (foundCurlyBrace == true) {
                        let nsRange = NSRange(range, in: contentRaw)
                        let newRange = NSRange(location: nsRange.lowerBound-offsetCorrection, length: nsRange.length)
                        guard let finalRange = Range(newRange, in: contentRaw) else {continue;}
                        regRanges.append(NSRange(finalRange, in: contentRaw))
                        offsetCorrection += 2;
                    }
                    if textToken.contains("«") {
                        foundFrenchQuote = true;
                    }
                    else if textToken.contains("»") {
                        foundFrenchQuote = false;
                    }
                    else if (foundFrenchQuote == true) {
                        let nsRange = NSRange(range, in: contentRaw)
                        let newRange = NSRange(location: nsRange.lowerBound-offsetCorrection, length: nsRange.length)
                        guard let finalRange = Range(newRange, in: contentRaw) else {continue;}
                        glossRanges.append(NSRange(finalRange, in: contentRaw))
                        offsetCorrection += 2;
                    }
                    if textToken.rangeOfCharacter(from: .alphanumerics) != nil {
                        content?.append(textToken)
                    }
                }
            }
            print(getRegContent())
            print(getGlossContent())
            print(regRanges)
            print(glossRanges)
        }
    }
    
    struct TagSpecifiers {
        enum TagLevel: Int {
            case word       = 0
            case orig       = 1
            case orig_w     = 2
        }
        
        static let defaultTagLevel: TagLevel = .orig_w
        
        static let tagRename: [String : String] = [
            "edit"      :   "corr",
            "addition"  :   "add",
            "original"  :   "misprint"
        ]
        
        static let tagLevels: [String : TagLevel] = [
            "addition"  :   .orig_w,
            "edit"      :   .orig_w,
            "del"       :   .orig_w
        ]
        
        static let tagInjectContent: [String : String] = [
            "addition"  :   "yes",
            "del"       :   "yes",
            "edit"      :   "yes",
            "edited"    :   "yes",
            "merged"    :   "yes",
            "split"     :   "yes"
        ]
        
        static let tagSplitAttribute: [String : String] = [
            "edit"      :   "original",
            "edited"    :   "unedited",
            "merged"    :   "unedited",
            "split"    :   "unedited"
        ]
    }
    
    func tagLevel(forTag tagName: String) -> TagSpecifiers.TagLevel {
        if let tagLevel = TagSpecifiers.tagLevels[tagName] {return tagLevel}
        return TagSpecifiers.defaultTagLevel
    }
    
    func tagNewName(forTag tagName: String) -> String? {
        return TagSpecifiers.tagRename[tagName]
    }
    
    func tagInjectContent(forTag tagName: String) -> String? {
        return TagSpecifiers.tagInjectContent[tagName]
    }
    
    func tagSplitAttribute(forTag tagElement: Amphisbaena_Element) -> Amphisbaena_Element? {
        if let attributeSplit = TagSpecifiers.tagSplitAttribute[tagElement.elementName],
           let attributes = tagElement.elementAttributes,
           let attributeValue = attributes[attributeSplit] {
            
            //modify the tag in place to remove its tag
            let newAttributes = attributes.filter { (key, _) -> Bool in
                key != attributeSplit
            }
            tagElement.elementAttributes = newAttributes
            
            //create a new tag and return it
            let newElement = Amphisbaena_Element(elementName: attributeSplit)
            newElement.elementContent = attributeValue
            return newElement
        }
        else {return nil}
    }
    
    func findTags(forFacs identifier: String, usingTagContainer TEITagsContainer: Amphisbaena_TEITagContainer?) -> [Amphisbaena_Element] {
        guard let teiTagsContainer = TEITagsContainer else {return []}
        let tagFacs = identifier.replacingOccurrences(of: "#", with: "")
        if let tagContainer = teiTagsContainer.searchForElement(withName: "tag", withAttribute: "facs", ofValue: tagFacs).first as? Amphisbaena_Container,
           let elements = tagContainer.elementEnclosing?.compactMap({ $0 as? Amphisbaena_Element }) {
            return elements
        }
        else {return []}
    }
    
    func formatPhraseNote(noteString: String) -> Amphisbaena_Container? {
        var newPhraseNote = PhraseNotes(contentRaw: noteString)
        
        return nil
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
        var badCert_flexWord = false;
        
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
            case "flexw_BadCertBegin":
                badCert_flexWord = true;
            case "flexw_BadCertEnd":
                badCert_flexWord = false;
            case "flexw":
                currentWord?.sortElements(by: SortCriteria.sortCriteria)
                if let currentWords = currentWords {
                    if (canCreateNewWord == true) {
                        let word = Amphisbaena_Container(withName: "word", isRoot: false)
                        //word.elementAttributes = ["xml:id" : ""]
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
                        var regAttributes = [String : String]()
                        regAttributes["cert"] = badCert_flexWord ? "no" : "yes"
                        flex.addElement(element: Amphisbaena_Element(elementName: "reg", attributes: regAttributes, elementContent: content))
                        if let guid = token.identifier,
                            let wordElement = flexContainer.searchForElement(withName: "word", withAttribute: "guid", ofValue: guid, recursively: true).first as? Amphisbaena_Container,
                            let itemGloss = wordElement.searchForElement(withName: "item", withAttribute: "type", ofValue: "gls").first {
                            
                            var glossAttributes = [String : String]()
                            glossAttributes["cert"] = "yes"
                            if itemGloss.elementContent?.contains("{") ?? false || itemGloss.elementContent?.contains("}") ?? false {
                                glossAttributes["cert"] = "no"
                            }
                            
                            let gloss = Amphisbaena_Element(elementName: "gloss", attributes: glossAttributes, elementContent: itemGloss.elementContent)
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
            case "flexwNotPresent":
                if let currentWords = currentWords {
                    if (canCreateNewWord == true) {
                        let word = Amphisbaena_Container(withName: "word", isRoot: false)
                        currentWords.addElement(element: word)
                        currentWord = word
                        canCreateNewWord = false;
                        SortCriteria.flexWordOrder = [:]
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
                    
                    let foundTags = findTags(forFacs: identifier, usingTagContainer: TEITagsContainer)
                    /*
                    for tag in foundTags {
                        guard tagLevel(forTag: tag.elementName) == .word else {continue;}
                        if currentWord.hasElementsMatching(name: tag.elementName, matchingAttributes: tag.elementAttributes).isEmpty == false {continue;}
                        
                        let newTag = tag.copy() as! Amphisbaena_Element
                        if let tagName = tagNewName(forTag: tag.elementName) {
                            newTag.elementName = tagName
                        }
                        if let tagInjectContent = tagInjectContent(forTag: tag.elementName) {
                            newTag.elementContent = tagInjectContent
                        }
                        currentWord.addElement(element: newTag)
                    }
                    */
                    //add transkribus w
                    let orig = multipleFiles_getWordOrig(word: currentWord)
                    
                    let transkribusW =  Amphisbaena_Element(elementName: "w")
                    var transkribusWAttributes = [
                        "facs" : identifier,
                    ]
                    transkribusW.preferredAttributeOrder = ElementAttributeOrder.w
                    transkribusW.elementContent = token.content

                    //cert element
                    transkribusWAttributes["cert"] = "yes"
                    if token.content?.contains("{") ?? false ||
                        token.content?.contains("}") ?? false {
                        transkribusWAttributes["cert"] = "no"
                    }
                    
                    //add tags to transkribus w
                    for tag in foundTags {
                        guard tagLevel(forTag: tag.elementName) == .orig_w else {continue;}
                        var newAttribute = [String : String]();
                        
                        let newTag = tag.copy() as! Amphisbaena_Element
                        let splitTag = tagSplitAttribute(forTag: newTag)
                        
                        if let tagName = tagNewName(forTag: tag.elementName) {
                            newTag.elementName = tagName
                        }
                        if let tagInjectContent = tagInjectContent(forTag: tag.elementName) {
                            newTag.elementContent = tagInjectContent
                        }
                        newAttribute[newTag.elementName] = newTag.elementContent
                        if let splitTag = splitTag {
                            if let splitTagName = tagNewName(forTag: splitTag.elementName) {
                                splitTag.elementName = splitTagName
                            }
                            newAttribute[splitTag.elementName] = splitTag.elementContent
                        }
                        transkribusWAttributes.merge(newAttribute) { (key1, key2) -> String in
                            return key1;
                        }
                    }
                    
                    transkribusW.elementAttributes = transkribusWAttributes
                    
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
                    
                    var attributes: [String : String] = ["lang" : lang, "cert" : "yes"]
                    if gloss.elementContent?.contains("{") ?? false ||
                        gloss.elementContent?.contains("}") ?? false {
                        attributes["cert"] = "no"
                    }
                    
                    let newGloss = Amphisbaena_Element(elementName: "gloss", attributes: attributes, elementContent: gloss.elementContent)
                    newGloss.preferredAttributeOrder = ElementAttributeOrder.gloss
                    currentPhrase?.addElement(element: newGloss)
                    
                }
            case "flexphrasenote":
                if let guid = currentPhrase?.getAttribute(attributeName: "guid") ,
                    let flexPhrase = flexContainer.searchForElement(withAttribute: "guid", ofValue: guid, recursively: true).first as? Amphisbaena_Container,
                    let note = flexPhrase.searchForElement(withName: "item", withAttribute: "type", ofValue: "note", recursively: false).first {
                    
                    let newNote = Amphisbaena_Container(withName: "note", isRoot: false)
                    currentPhrase?.addElement(element: newNote)
                    
                    let noteContent = note.elementContent
                    
                    var noteStruct = PhraseNotes(contentRaw: noteContent ?? "")
                    noteStruct.format()
                    if let content = noteStruct.content {
                        let noteContentElement = Amphisbaena_Element(elementName: "content", attributes: nil, elementContent: content)
                        newNote.addElement(element: noteContentElement)
                    }
                    if noteStruct.glossRanges.count > 0 {
                        for glossRange in noteStruct.glossRanges {
                            let beginIndex = String(glossRange.lowerBound)
                            let length = String(glossRange.length)
                            let glossElement = Amphisbaena_Element(elementName: "gloss", attributes: ["begin" : beginIndex, "length" : length], elementContent: nil)
                            glossElement.preferredAttributeOrder = ["begin", "length"]
                            newNote.addElement(element: glossElement)
                        }
                    }
                    if noteStruct.regRanges.count > 0 {
                        for regRange in noteStruct.regRanges {
                            let beginIndex = String(regRange.lowerBound)
                            let length = String(regRange.length)
                            let regElement = Amphisbaena_Element(elementName: "reg", attributes: ["begin" : beginIndex, "length" : length], elementContent: nil)
                            regElement.preferredAttributeOrder = ["begin", "length"]
                            newNote.addElement(element: regElement)
                        }
                    }
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
