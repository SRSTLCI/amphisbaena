//
//  Amphisbaena_UnifiedContainer_TextBody_ELAN.swift
//  Amphisbaena
//
//  Created by Casey on 5/14/20.
//  Copyright © 2020 Casey Fasthorse. All rights reserved.
//

import Foundation

extension Amphisbaena_UnifiedContainer_TextBody {
    
    struct RegEx_ELAN {
        static let regexELANTag      = try! NSRegularExpression(pattern: #"(\w+?)="(.+?)""#, options: [])
    }
    
    
    struct ELANConstants {
        enum Level: Int {
            case paragraph = 0
            case sentence = 1
            case phraseSegnum = 2
            case wordTxtLkt = 3
            case wordGlossEn = 4
            case wordTags = 5
        }
        
        static let levelParagraph       = "paragraph"
        static let levelSentence        = "sentence"
        static let levelPhraseSegnum    = "phrase-segnum-en"
        static let levelWordTextLkt     = "word-txt-lkt"
        static let levelWordGlossEn     = "word-gls-en"
        static let levelTags            = "tags"
        
        static let levelLabel: [Level : String] = [
            .paragraph      : ELANConstants.levelParagraph,
            .sentence       : ELANConstants.levelSentence,
            .phraseSegnum   : ELANConstants.levelPhraseSegnum,
            .wordTxtLkt     : ELANConstants.levelWordTextLkt,
            .wordGlossEn    : ELANConstants.levelWordGlossEn,
            .wordTags       : ELANConstants.levelTags
        ]
        
        static let speakerIdentifiers   = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        
        static let regexIdentifySpeakersPattern = "(\\w)_.+"
        
        static let regexIdentifySpeakers = try! NSRegularExpression(pattern: ELANConstants.regexIdentifySpeakersPattern)
        
        static func speakerLevelName(speakerID: String, levelString: String) -> String {
            return speakerID+"_"+levelString;
        }
        
        static func speakerLevelName(speakerID: String, level: Level) -> String {
            return speakerID+"_"+(levelLabel[level] ?? "")
        }
        
        static func getSpeakerIdentifier(index i: Int) -> String {
            return String(speakerIdentifiers[speakerIdentifiers.index(speakerIdentifiers.startIndex, offsetBy: i)])
        }
    }
    
    convenience init(elanContainer: Amphisbaena_ELANContainer) {
        self.init();
        let _ = singleElan_identifySpeakers(inElanContainer: elanContainer)
        generateContent(fromElanContainer: elanContainer)
    }
    
    func singleElan_identifySpeakers(inElanContainer elanContainer: Amphisbaena_ELANContainer) -> [String] {
        var speakers: [String] = []
        for i in 0..<ELANConstants.speakerIdentifiers.count {
            let speakerID = ELANConstants.getSpeakerIdentifier(index: i)
            let paragraph = ELANConstants.speakerLevelName(speakerID: speakerID, levelString: ELANConstants.levelParagraph)
            if elanContainer.element_GetTier(tierID: paragraph) != nil {
                print(paragraph)
                speakers.append(speakerID)
            }
        }
        print(speakers)
        return speakers
    }
    
    func generateContent(fromElanContainer elanContainer: Amphisbaena_ELANContainer) {
        let speakers = singleElan_identifySpeakers(inElanContainer: elanContainer)
        
        for speaker in speakers {
            let tierID = ELANConstants.speakerLevelName(speakerID: speaker, level: .paragraph)
            let annotationsParagraphs = elanContainer.tier_GetOrderedAnnotations(tierID: tierID)
            for annotation in annotationsParagraphs {
                singleElan_addParagraph(fromElanContainer: elanContainer, annotationFromParagraph: annotation)
                if let currentParagraph = currentContainerParagraphP {
                    singleElan_addPhrases(fromElanContainer: elanContainer, speakerID: speaker, withinParagraph: currentParagraph)
                }
            }
        }
    }
    
    func singleElan_addParagraph(fromElanContainer elanContainer: Amphisbaena_ELANContainer, annotationFromParagraph annotationParagraph: AmphisbaenaXMLTaggable) {
        guard let annotationParagraph = annotationParagraph as? Amphisbaena_Container,
        let alignableAnnotation = annotationParagraph.getFirstElement(ofName: "ALIGNABLE_ANNOTATION") else {return;}
        guard let p_tsBegin = elanContainer.getTimeSlotValue(timeslot: alignableAnnotation.getAttribute(attributeName: "TIME_SLOT_REF1") ?? ""),
        let p_tsEnd = elanContainer.getTimeSlotValue(timeslot: alignableAnnotation.getAttribute(attributeName: "TIME_SLOT_REF2") ?? "") else {return;}
        
        let attributes = [  "start" : p_tsBegin,
                            "end" : p_tsEnd]
        let preferredAttributeOrder = ["start", "end"]
        
        let newParagraph = Amphisbaena_Container(withName: "p", isRoot: false)
        newParagraph.elementAttributes = attributes
        containerParagraphs.addElement(element: newParagraph)
        containerParagraphsP.append(newParagraph)
        currentContainerParagraphP = newParagraph;
        
        currentContainerParagraphP?.preferredAttributeOrder = preferredAttributeOrder
    }
    
    func singleElan_addPhrases(fromElanContainer elanContainer: Amphisbaena_ELANContainer, speakerID: String, withinParagraph paragraph: Amphisbaena_Container) {
        guard let attributes = paragraph.elementAttributes,
            let start = attributes["start"],
            let end = attributes["end"],
            let startValue = Int(start),
            let endValue    = Int(end) else {return;}
        
        let phrasesContainer = Amphisbaena_Container(withName: "phrases", isRoot: false)
        paragraph.addElement(element: phrasesContainer)
        
        let tierSentence = ELANConstants.speakerLevelName(speakerID: speakerID, level: .sentence)
        let tierPhraseSegnum = ELANConstants.speakerLevelName(speakerID: speakerID, level: .phraseSegnum)
        
        let annotationSentences = elanContainer.tier_GetOrderedAnnotations(tierID: tierSentence)
        
        let annotationSentencesSpeaker = elanContainer.tier_GetParticipant(tierID: tierPhraseSegnum)
        
        for annotationSentence in annotationSentences {
            guard let annotationSentence = annotationSentence as? Amphisbaena_Container,
                let alignableAnnotation = annotationSentence.getFirstElement(ofName: "ALIGNABLE_ANNOTATION") as? Amphisbaena_Container,
                let phr_tsBegin = elanContainer.getTimeSlotValue(timeslot: alignableAnnotation.getAttribute(attributeName: "TIME_SLOT_REF1") ?? ""),
                let phr_tsEnd = elanContainer.getTimeSlotValue(timeslot: alignableAnnotation.getAttribute(attributeName: "TIME_SLOT_REF2") ?? ""),
                let phr_tsBegin_Value = Int(phr_tsBegin),
                let phr_tsEnd_Value = Int(phr_tsEnd) else {continue}
                
            if phr_tsBegin_Value >= startValue && phr_tsEnd_Value <= endValue {
                var glossContent: String? = nil;
                var glossLang: String? = nil;
                
                if let annotationValue = alignableAnnotation.getFirstElement(ofName: "ANNOTATION_VALUE"),
                    let phraseGloss = annotationValue.elementContent {
                    glossContent = phraseGloss
                    glossLang = "en"
                }
                
                
                singleElan_addPhrase(fromElanContainer: elanContainer, speakerID: speakerID, withinPhrases: phrasesContainer, xmlID: nil, start: phr_tsBegin, end: phr_tsEnd, who: annotationSentencesSpeaker, mediaFile: nil, glossLang: glossLang, glossContent: glossContent)
            }
        }
        
    }
    
    func singleElan_addPhrase(fromElanContainer elanContainer: Amphisbaena_ELANContainer, speakerID: String, withinPhrases phrases: Amphisbaena_Container, xmlID: String?, start: String?, end: String?, who: String?, mediaFile: String?, glossLang: String?, glossContent: String?) {
        
        let phraseContainer = Amphisbaena_Container(withName: "phr", isRoot: false)
        let preferredAttributeOrder = ["uuid", "guid", "start", "end", "who", "media-file"]
        
        var attributes: [String : String] = [:]
        if let xmlID = xmlID {attributes["uuid"] = xmlID;}
        if let start = start {attributes["start"] = start}
        if let end = end {attributes["end"] = end}
        if let who = who {attributes["who"] = who}
        if let mediaFile = mediaFile {attributes["mediaFile"] = mediaFile}
        
        if xmlID != nil,
           xmlID!.count < 36 {
            let newUUID = UUID().uuidString
            attributes["uuid"] = newUUID
        }
        
        phraseContainer.elementAttributes = attributes
        phraseContainer.preferredAttributeOrder = preferredAttributeOrder;
        phrases.addElement(element: phraseContainer)
        
        guard let start = start,
            let end = end,
            let startValue = Int(start),
            let endValue = Int(end)
            else {return}
        
        singleElan_addUtterances(fromElanContainer: elanContainer, speakerID: speakerID, withinPhrase: phraseContainer, withinStart: startValue, withinEnd: endValue)
        
        if let glossLang = glossLang, let glossContent = glossContent {
            let phraseGloss = Amphisbaena_Element(elementName: "gloss")
            phraseGloss.elementAttributes = ["lang" : glossLang, "cert" : ""]
            phraseGloss.elementContent = glossContent;
            phraseGloss.preferredAttributeOrder = ["lang", "cert"]
            phraseContainer.addElement(element: phraseGloss)
        }
    }
    
    func singleElan_addUtterances(fromElanContainer elanContainer: Amphisbaena_ELANContainer, speakerID: String, withinPhrase phrase: Amphisbaena_Container, withinStart start: Int, withinEnd end: Int) {
        
        let containerUtterances = Amphisbaena_Container(withName: "utterances", isRoot: false)
        phrase.addElement(element: containerUtterances)
        
        let tierPhraseSegnum = ELANConstants.speakerLevelName(speakerID: speakerID, level: .phraseSegnum)
        
        let annotationUtteranceTimings = elanContainer.tier_GetOrderedAnnotations(tierID: tierPhraseSegnum)
        
        for annotationUtteranceTiming in annotationUtteranceTimings {
            guard let annotationUtteranceTiming = annotationUtteranceTiming as? Amphisbaena_Container,
                let alignableAnnotation = annotationUtteranceTiming.getFirstElement(ofName: "ALIGNABLE_ANNOTATION") as? Amphisbaena_Container,
                let phr_tsBegin = elanContainer.getTimeSlotValue(timeslot: alignableAnnotation.getAttribute(attributeName: "TIME_SLOT_REF1") ?? ""),
                let phr_tsEnd = elanContainer.getTimeSlotValue(timeslot: alignableAnnotation.getAttribute(attributeName: "TIME_SLOT_REF2") ?? ""),
                let uttr_tsBegin_Value = Int(phr_tsBegin),
                let uttr_tsEnd_Value = Int(phr_tsEnd),
                let uttr_ID = alignableAnnotation.getAttribute(attributeName: "ANNOTATION_ID") else {continue}
                
            if uttr_tsBegin_Value >= start && uttr_tsEnd_Value <= end {
                singleElan_addUtterance(fromElanContainer: elanContainer, speakerID: speakerID, withinUtterances: containerUtterances, withID: uttr_ID, withStart: uttr_tsBegin_Value, withEnd: uttr_tsEnd_Value)
            }
        }
        
    }
    
    func singleElan_addUtterance(fromElanContainer elanContainer: Amphisbaena_ELANContainer, speakerID: String, withinUtterances utterancesContainer: Amphisbaena_Container, withID annotationID: String, withStart start: Int, withEnd end: Int) {
        
        let utteranceContainer = Amphisbaena_Container(withName: "u", isRoot: false)
        let preferredAttributeOrder = ["uuid", "start", "end"]
        
        var attributes: [String : String] = [:]
        attributes["uuid"] = annotationID;
        attributes["start"] = String(start)
        attributes["end"] = String(end)
        if annotationID.count < 36 {
            let newUUID = UUID().uuidString
            attributes["uuid"] = newUUID
        }
        
        utteranceContainer.elementAttributes = attributes
        utteranceContainer.preferredAttributeOrder = preferredAttributeOrder;
        utterancesContainer.addElement(element: utteranceContainer)
        
        singleElan_addWords(fromElanContainer: elanContainer, speakerID: speakerID, withinUtterance: utteranceContainer, withinID: annotationID)
    }
    
    func singleElan_addWords(fromElanContainer elanContainer: Amphisbaena_ELANContainer, speakerID: String, withinUtterance utteranceContainer: Amphisbaena_Container, withinID: String) {
        
        let wordsContainer = Amphisbaena_Container(withName: "words", isRoot: false)
        utteranceContainer.addElement(element: wordsContainer)
        
        let tierWordTxtLkt = ELANConstants.speakerLevelName(speakerID: speakerID, level: .wordTxtLkt)
        
        let annotationWordsLkt = elanContainer.tier_GetOrderedAnnotations(tierID: tierWordTxtLkt)
        let wordLanguage = elanContainer.tier_GetLanguage(tierID: tierWordTxtLkt)
        
        for annotationWordLkt in annotationWordsLkt {
            guard let annotationWordLkt = annotationWordLkt as? Amphisbaena_Container,
                let refAnnotation = annotationWordLkt.getFirstElement(ofName: "REF_ANNOTATION") as? Amphisbaena_Container,
                let wordID = refAnnotation.getAttribute(attributeName: "ANNOTATION_ID"),
                let parentUtteranceID = refAnnotation.getAttribute(attributeName: "ANNOTATION_REF"),
                let lang = wordLanguage,
                parentUtteranceID == withinID else {continue;}
            
            singleElan_addWord(fromElanContainer: elanContainer, speakerID: speakerID, withinWords: wordsContainer, withWordID: wordID, ofLanguage: lang, refAnnotation: refAnnotation)
        }
    }
    
    func singleElan_addWord(fromElanContainer elanContainer: Amphisbaena_ELANContainer, speakerID: String, withinWords wordsContainer: Amphisbaena_Container, withWordID wordID: String, ofLanguage lang: String, refAnnotation: Amphisbaena_Container) {
        
        let wordContainer = Amphisbaena_Container(withName: "word", isRoot: false)
        let preferredAttributeOrder = ["uuid", "personID", "placeID"]
        var attributes: [String : String] = [:]
        attributes["uuid"] = wordID
        if wordID.count < 36 {
            let newUUID = UUID().uuidString
            attributes["uuid"] = newUUID
        }
        
        wordContainer.elementAttributes = attributes
        wordContainer.preferredAttributeOrder = preferredAttributeOrder
        wordsContainer.addElement(element: wordContainer)
        
        let flexContainer = Amphisbaena_Container(withName: "flex", isRoot: false)
        wordContainer.addElement(element: flexContainer)
        
        let origDummyContainer = Amphisbaena_Element(elementName: "orig", attributes: nil, elementContent: nil)
        origDummyContainer.elementContent = ""
        wordContainer.addElement(element: origDummyContainer)
        
        //get lak/dak word
        if let annotationValue = refAnnotation.getFirstElement(ofName: "ANNOTATION_VALUE"),
            let wordContent = annotationValue.elementContent {
            
            let unsafeChars = CharacterSet.alphanumerics.inverted
            let punctChars = wordContent.folding(options: .diacriticInsensitive, locale: nil).components(separatedBy: unsafeChars).joined(separator: "")
            if (punctChars == "") {
                let newPC = Amphisbaena_Element(elementName: "pc")
                newPC.elementContent = wordContent
                
                flexContainer.addElement(element: newPC)
            }
            else {
                let newReg = Amphisbaena_Element(elementName: "reg")
                let attributes = ["lang" : lang, "cert" : ""]
                let preferredAttributeOrder = ["lang", "cert"]
                newReg.preferredAttributeOrder = preferredAttributeOrder
                newReg.elementAttributes = attributes
                newReg.elementContent = wordContent
                
                flexContainer.addElement(element: newReg)
            }
        }
        
        //get word gloss
        let tierWordGloss = ELANConstants.speakerLevelName(speakerID: speakerID, level: .wordGlossEn)
        let glossAnnotations    = elanContainer.tier_GetOrderedAnnotations(tierID: tierWordGloss)
        if let glossLang        = elanContainer.tier_GetLanguage(tierID: tierWordGloss) {
            for glossAnnotation in glossAnnotations {
                guard let glossAnnotation = glossAnnotation as? Amphisbaena_Container,
                    let refAnnotation = glossAnnotation.getFirstElement(ofName: "REF_ANNOTATION") as? Amphisbaena_Container,
                    let parentID = refAnnotation.getAttribute(attributeName: "ANNOTATION_REF"),
                    parentID == wordID,
                    let annotationValue = refAnnotation.getFirstElement(ofName: "ANNOTATION_VALUE"),
                    let glossContent = annotationValue.elementContent
                    else {continue}
                
                let newGloss = Amphisbaena_Element(elementName: "gloss")
                newGloss.elementAttributes = ["lang" : glossLang, "cert" : ""]
                newGloss.preferredAttributeOrder = ["lang", "cert"]
                newGloss.elementContent = glossContent
                    
                flexContainer.addElement(element: newGloss)
            }
        }
        
        //get tags
        let tierWordTag = ELANConstants.speakerLevelName(speakerID: speakerID, level: .wordTags)
        let wordTags    = elanContainer.tier_GetOrderedAnnotations(tierID: tierWordTag)
        let tagAnnotation = wordTags.first { (taggable) -> Bool in
            guard let taggable = taggable as? Amphisbaena_Container,
                  let refAnnotation = taggable.getFirstElement(ofName: "REF_ANNOTATION") as? Amphisbaena_Container,
                  let annotationRef = refAnnotation.getAttribute(attributeName: "ANNOTATION_REF"),
                  annotationRef == wordID,
                  let annotationValue = refAnnotation.getFirstElement(ofName: "ANNOTATION_VALUE"),
                  annotationValue.elementContent != nil
            else {return false}
            return true;
        }
        if let tagAnnotation = tagAnnotation as? Amphisbaena_Container,
           let refAnnotation = tagAnnotation.getFirstElement(ofName: "REF_ANNOTATION") as? Amphisbaena_Container,
           let annotationValue = refAnnotation.getFirstElement(ofName: "ANNOTATION_VALUE"),
           let elementContent = annotationValue.elementContent {
            let unwrappedTags = unwrapTags(tagString: elementContent)
            for (label, value) in unwrappedTags {
                wordContainer.elementAttributes?[label] = value
            }
        }
    }
    
    func unwrapTags(tagString: String) -> [String : String] {
        var tags: [String : String] = [:]
        
        let tagStringRange = NSRange(tagString.startIndex..<tagString.endIndex, in: tagString)
        let tagStringMatches = RegEx_ELAN.regexELANTag.matches(in: tagString, options: [], range: tagStringRange)
        for match in tagStringMatches {
            var label: String?
            var value: String?
            
            for r in 1..<match.numberOfRanges {
                guard let range = Range( match.range(at: r), in: tagString) else {continue;}
                let matchRangeString = String(tagString[range])
                if (r == 1) {label = matchRangeString} else
                if (r == 2) {value = matchRangeString}
            }
            
            if let label = label, let value = value {
                tags[label] = value
            }
        }
        
        return tags
    }
}
