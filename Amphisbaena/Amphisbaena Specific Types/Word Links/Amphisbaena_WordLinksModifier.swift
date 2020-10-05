//
//  Amphisbaena_WordLinksModifier.swift
//  Amphisbaena
//
//  Created by Casey on 5/4/20.
//  Copyright © 2020 Casey Fasthorse. All rights reserved.
//

import Foundation


class Amphisbaena_WordLinksModifier {
    var containerTranskribusTEI: Amphisbaena_TranskribusTEIContainer?
    var containerFlexText: Amphisbaena_FlexTextContainer?
    
    private var initialWordLinks: [WordLink] = []
    private var initialFlexWords: [FlexWord] = []
    private var initialTranskribusWords: [TranskribusWord] = []
    
    var wordLinks: [WordLink] = []
    var flexWords: [FlexWord] = []
    var transkribusWords: [TranskribusWord] = []
    
    var resultContainer: Amphisbaena_WordLinksContainer?
    
    var itemCount: Int {
        return wordLinks.count
    }
    
    var maxComponentCount: Int {
        print(flexWords.count)
        print(transkribusWords.count)
        return max(flexWords.count, transkribusWords.count)
    }
    
    struct WordLink: Equatable {
        var guidsFirst: Int = 0
        var guidsCount: Int = 0
        var facsFirst: Int = 0
        var facsCount: Int = 0
        
        var guidsRange: IndexSet {
            return IndexSet(guidsFirst..<max(guidsFirst,guidsFirst+guidsCount))
        }
        var facsRange: IndexSet {
            return IndexSet(facsFirst..<max(facsFirst,facsFirst+facsCount))
        }
        
        static func == (lhs: WordLink, rhs: WordLink) -> Bool {
            return lhs.guidsFirst == rhs.guidsFirst &&
                lhs.guidsCount == rhs.guidsCount &&
                lhs.facsFirst == rhs.facsFirst &&
                lhs.facsCount == rhs.facsCount
        }
    }
    
    struct FlexWord: Equatable {
        var guid: String
        var content: String
        
        static func == (lhs: FlexWord, rhs: FlexWord) -> Bool {
            return lhs.guid == rhs.guid
        }
    }
    
    struct TranskribusWord: Equatable {
        var facs: String
        var content: String
        
        static func == (lhs: TranskribusWord, rhs: TranskribusWord) -> Bool {
            return lhs.facs == rhs.facs
        }
    }
    
    struct Placeholder {
        static let notFound: String = "NOT FOUND"
    }
    
    init() {
        resultContainer = Amphisbaena_WordLinksContainer()
    }
    
    init(fromFileContainers transkribusContainer: Amphisbaena_TranskribusTEIContainer, flexContainer: Amphisbaena_FlexTextContainer) {
        makeFlexList(fromFlexContainer: flexContainer)
        makeTranskribusList(fromTranskribusContainer: transkribusContainer)
        makeWordLinkList()
        resultContainer = Amphisbaena_WordLinksContainer()
    }
    
    init(fromExistingWordLinks existingWordLinks: [WordLink], transkribusContainer: Amphisbaena_TranskribusTEIContainer, flexContainer: Amphisbaena_FlexTextContainer) {
        
        makeFlexList(fromFlexContainer: flexContainer)
        makeTranskribusList(fromTranskribusContainer: transkribusContainer)
        self.wordLinks = existingWordLinks
        initialWordLinks = wordLinks.compactMap {$0}
        resultContainer = Amphisbaena_WordLinksContainer()
    }
    
    init(fromExistingContainer wordLinkContainer: Amphisbaena_WordLinksContainer, transkribusContainer: Amphisbaena_TranskribusTEIContainer, flexContainer: Amphisbaena_FlexTextContainer) {
        makeFlexList(fromFlexContainer: flexContainer)
        makeTranskribusList(fromTranskribusContainer: transkribusContainer)
        
        self.wordLinks = []
        let wordLinkContainers = wordLinkContainer.getOrderedElements(ofName: "wordLink").compactMap {$0 as? Amphisbaena_Container}
        for wordLinkContainer in wordLinkContainers {
            if let attributes = wordLinkContainer.elementAttributes {
                var modifierWordLink = Amphisbaena_WordLinksModifier.WordLink()
                if let facsFirst = attributes["facsFirst"], let facsFirstInt = Int(facsFirst) {modifierWordLink.facsFirst = facsFirstInt}
                if let facsCount = attributes["facsCount"], let facsCountInt = Int(facsCount) {modifierWordLink.facsCount = facsCountInt}
                if let guidFirst = attributes["guidFirst"], let guidFirstInt = Int(guidFirst) {modifierWordLink.guidsFirst = guidFirstInt}
                if let guidCount = attributes["guidCount"], let guidCountInt = Int(guidCount) {modifierWordLink.guidsCount = guidCountInt}
                wordLinks.append(modifierWordLink)
            }
        }
        initialWordLinks = wordLinks.compactMap {$0}
        resultContainer = Amphisbaena_WordLinksContainer();
    }

    func makeTranskribusList(fromTranskribusContainer transkribusContainer: Amphisbaena_TranskribusTEIContainer) {
        transkribusWords = [];
        let transkribus_w = transkribusContainer.getAll_w()
        for i in 0..<transkribus_w.count {
            let facs = transkribus_w[i].getAttribute(attributeName: "facs") ?? "FACS_MISSING"
            var text = transkribus_w[i].elementContent
            if let hiElement = transkribus_w[i].getFirstElement(ofName: "hi"),
               text == nil {
                text = hiElement.elementContent
            }
            let sic = transkribus_w[i].getFirstElement(ofName: "sic")?.elementContent
            let transkribusWord = TranskribusWord(facs: facs, content: text ?? sic ?? "")
            transkribusWords.append(transkribusWord)
        }
        initialTranskribusWords = transkribusWords.compactMap {$0}
    }
    
    func makeFlexList(fromFlexContainer flexContainer: Amphisbaena_FlexTextContainer) {
        flexWords = [];
        let words = flexContainer.getAll_Word()
        for i in 0..<words.count {
            let word = words[i]
            let text = word.searchForElement(withAttribute: "type", ofValue: "txt").first?.elementContent
            let punct = word.searchForElement(withAttribute: "type", ofValue: "punct").first?.elementContent
            let content = text ?? punct ?? "";
            let guid = word.getAttribute(attributeName: "guid") ?? ""
            self.flexWords.append(FlexWord(guid: guid, content: content))
        }
        initialFlexWords = flexWords.compactMap {$0}
    }
    
    func makeWordLinkList() {
        let count = maxComponentCount;
        self.wordLinks = []
        for i in 0..<count {
            var flexValues = [Int]()
            var transkribusValues = [Int]()
            if (i < flexWords.count) {flexValues.append(i)}
            if (i < transkribusWords.count) {transkribusValues.append(i)}
            let wordLink = WordLink(guidsFirst: i, guidsCount: flexValues.count, facsFirst: i, facsCount: transkribusValues.count)
            self.wordLinks.append(wordLink)
        }
        initialWordLinks = wordLinks.compactMap {$0}
    }
    
    func combineSelectedIntoFacs(fromIndexSet indexSet: IndexSet) {
        if indexSet.count > 0,
            indexSetIsContinuous(indexSet: indexSet),
            let first = indexSet.first,
            let last = indexSet.last,
            first >= 0,
            last < itemCount {
            
            let firstIndex = indexSet.compactMap {wordLinks[$0].guidsFirst}.min()!
            let combinedCount = indexSet.compactMap{wordLinks[$0].guidsCount}.reduce(0) { (x, y) in
                x + y
            }
            
            var firstWordLink = wordLinks[first];
            firstWordLink.guidsFirst = firstIndex;
            firstWordLink.guidsCount = max(0,combinedCount);
            
            wordLinks[first] = firstWordLink
            
            for i in first+1...last {
                wordLinks[i].guidsCount = 0;
            }
            
            consolidateWordLinks()
            trimEmptyWordLinks()
        }
    }
    
    func combineSelectedIntoGuid(fromIndexSet indexSet: IndexSet) {
        if indexSet.count > 0,
            indexSetIsContinuous(indexSet: indexSet),
            let first = indexSet.first,
            let last = indexSet.last,
            first >= 0,
            last < itemCount {
            
            let firstIndex = indexSet.compactMap {wordLinks[$0].facsFirst}.min()!
            let combinedCount = indexSet.compactMap{wordLinks[$0].facsCount}.reduce(0) { (x, y) in
                x + y
            }
            
            var firstWordLink = wordLinks[first];
            firstWordLink.facsFirst = firstIndex;
            firstWordLink.facsCount = max(0,combinedCount);
            
            wordLinks[first] = firstWordLink
            
            for i in first+1...last {
                wordLinks[i].facsCount = 0;
            }
            
            consolidateWordLinks()
            trimEmptyWordLinks()
        }
    }
    
    private func indexSetIsContinuous(indexSet: IndexSet) -> Bool {
        var difference: Int = 0;
        var previous: Int = 0;
        var canCombine = true;
        if let first = indexSet.first {
            previous = first as Int;
            indexSet.forEach { (index) in
                if (canCombine == true) {
                    difference = index-previous;
                    if difference > 1 {
                        canCombine = false;
                    }
                    previous = index as Int;
                }
            }
        }
        return canCombine;
    }
    
    private func consolidateWordLinks() {
        for i in 0..<wordLinks.count {
            let initialFacsCount = wordLinks[i].facsCount
            let initialGuidCount = wordLinks[i].guidsCount
            
            if (initialFacsCount == 0) {
                for n in i..<wordLinks.count {
                    if wordLinks[n].facsCount == 0 {continue;}
                    else {
                        wordLinks[i].facsFirst = wordLinks[n].facsFirst
                        wordLinks[i].facsCount = wordLinks[n].facsCount
                        wordLinks[n].facsCount = 0
                        break;
                    }
                }
            }
            
            if (initialGuidCount == 0) {
                for n in i..<wordLinks.count {
                    if wordLinks[n].guidsCount == 0 {continue;}
                    else {
                        wordLinks[i].guidsFirst = wordLinks[n].guidsFirst
                        wordLinks[i].guidsCount = wordLinks[n].guidsCount
                        wordLinks[n].guidsCount = 0
                        break;
                    }
                }
            }
        }
    }
    
    private func trimEmptyWordLinks() {
        self.wordLinks = self.wordLinks.filter({ (wordLink) -> Bool in
            wordLink.facsCount != 0 || wordLink.guidsCount != 0
        })
    }

    func insertEmptyTranskribus(atIndexSet indexSet: IndexSet) {
        if let first = indexSet.first,
        first >= 0,
        first < itemCount {
            
            let wordLink = wordLinks[first]
            var memoFacs = (wordLink.facsFirst, wordLink.facsCount);
            wordLinks[first].facsCount = -1;
            for i in first+1..<wordLinks.count {
                var currentWordLink = wordLinks[i];
                currentWordLink.facsFirst = memoFacs.0
                currentWordLink.facsCount = memoFacs.1
                memoFacs = (wordLinks[i].facsFirst, wordLinks[i].facsCount);
                wordLinks[i] = currentWordLink
            }
            trimEmptyWordLinks()
            let newEmptyGuid = WordLink(guidsFirst: 0, guidsCount: 0, facsFirst: memoFacs.0, facsCount: memoFacs.1)
            wordLinks.append(newEmptyGuid)
        }
    }
    
    func insertEmptyFLEx(atIndexSet indexSet: IndexSet) {
        if let first = indexSet.first,
        first >= 0,
        first < itemCount {
            let wordLink = wordLinks[first]
            var memoGuid = (wordLink.guidsFirst, wordLink.guidsCount)
            wordLinks[first].guidsCount = -1;
            for i in first+1..<wordLinks.count {
                var currentWordLink = wordLinks[i];
                currentWordLink.guidsFirst = memoGuid.0
                currentWordLink.guidsCount = memoGuid.1
                memoGuid = (wordLinks[i].guidsFirst, wordLinks[i].guidsCount);
                wordLinks[i] = currentWordLink
            }
            trimEmptyWordLinks()
            let newEmptyGuid = WordLink(guidsFirst: memoGuid.0, guidsCount: memoGuid.1, facsFirst: 0, facsCount: 0)
            wordLinks.append(newEmptyGuid)
        }
    }
    
    func setupNewContainer() {
        guard let resultContainer = resultContainer else {return}
        resultContainer.version = .v02
        resultContainer.elementEnclosing?.removeAll()
        resultContainer.addElement(element: Amphisbaena_Element(elementName: "formatVersion", attributes: nil, elementContent: "0.2"))
        for wordLink in wordLinks {
            
            let wordLinkContainer = Amphisbaena_Container(withName: "wordLink", isRoot: false)
            var attributes: [String : String] = [:]
            let preferredAttributeOrder = ["guid", "guidFirst", "guidCount", "facs", "facsFirst", "facsCount"]
            if wordLink.guidsCount != 0 {
                //attributes["guid"] = flexWords[wordLink.guidsFirst].guid
                
                if wordLink.guidsCount > 0 {
                    attributes["guid"] = flexWords[wordLink.guidsFirst].guid
                }
                else {
                    attributes["guid"] = ""
                }
                
                attributes["guidCount"] = String(wordLink.guidsCount)
                attributes["guidFirst"] = String(wordLink.guidsFirst)
                
                wordLink.guidsRange.forEach { (guidIndex) in
                    let flexWord = flexWords[guidIndex]
                    var flexAttributes: [String : String] = [:]
                    let guidElement = Amphisbaena_Element(elementName: "guid")
                    if flexWord.content.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
                        flexAttributes["groundtruth"] = flexWord.content
                        guidElement.elementContent = flexWord.guid
                    }
                    flexAttributes["index"] = String(guidIndex)
                    guidElement.preferredAttributeOrder = ["index", "groundtruth"]
                    guidElement.elementAttributes = flexAttributes
                    wordLinkContainer.addElement(element: guidElement)
                }
            }
            if wordLink.facsCount != 0 {
                //attributes["facs"] = transkribusWords[wordLink.facsFirst].facs
                
                if wordLink.facsCount > 0 {
                    attributes["facs"] = transkribusWords[wordLink.facsFirst].facs
                }
                else {
                    attributes["facs"] = ""
                }
                
                attributes["facsCount"] = String(wordLink.facsCount)
                attributes["facsFirst"] = String(wordLink.facsFirst)
                
                wordLink.facsRange.forEach { (facsIndex) in
                    let facsWord = transkribusWords[facsIndex]
                    var facsAttributes: [String : String] = [:]
                    let facsElement = Amphisbaena_Element(elementName: "facs")
                    if facsWord.content.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
                        facsAttributes["groundtruth"] = facsWord.content
                    }
                    facsAttributes["index"] = String(facsIndex)
                    facsElement.preferredAttributeOrder = ["index", "groundtruth"]
                    facsElement.elementContent = facsWord.facs
                    facsElement.elementAttributes = facsAttributes
                    wordLinkContainer.addElement(element: facsElement)
                }
            }
            wordLinkContainer.preferredAttributeOrder = preferredAttributeOrder
            wordLinkContainer.elementAttributes = attributes
            resultContainer.addElement(element: wordLinkContainer)
        }
        /*
        for f in 0..<flexGuids.count {
            let flex = flexGuids[f]
            let wordLinkContainer = Amphisbaena_Container(withName: "wordLink", isRoot: false)
            if flex.guid != "" {
                let attributes = ["guid" : flex.guid, "groundtruth" : flex.content]
                let preferredAttributeOrder = ["guid", "groundtruth"]
                wordLinkContainer.elementAttributes = attributes
                wordLinkContainer.preferredAttributeOrder = preferredAttributeOrder
            }
            else {
                let attributes = ["groundtruth" : flex.content]
                wordLinkContainer.elementAttributes = attributes
            }
            if let facs = transkribusWords[f] {
                for w in facs {
                    let newElement = Amphisbaena_Element(elementName: "facs")
                    newElement.elementContent = w.facs
                    wordLinkContainer.addElement(element: newElement)
                }
            }
            resultContainer.addElement(element: wordLinkContainer)
        }*/
    }
}
