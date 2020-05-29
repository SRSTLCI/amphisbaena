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
    
    var flexGuids: [FlexWord] = []
    var transkribusWords: [Int : [TranskribusWord]] = [:]
    
    var resultContainer: Amphisbaena_WordLinksContainer?
    
    var itemCount: Int {
        if let keyCount = transkribusWords.keys.max() {return keyCount + 1}
        return flexGuids.count
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
    
    init(fromFileContainers transkribusContainer: Amphisbaena_TranskribusTEIContainer, flexContainer: Amphisbaena_FlexTextContainer) {
        
        let flexWords = flexContainer.getAll_Word()
        flexGuids = flexWords.compactMap {
            let text = $0.searchForElement(withAttribute: "type", ofValue: "txt").first?.elementContent
            let punct = $0.searchForElement(withAttribute: "type", ofValue: "punct").first?.elementContent
            let content = text ?? punct ?? "";
            return FlexWord(guid: $0.getAttribute(attributeName: "guid") ?? "", content: content)
        }
        
        let transkribus_w = transkribusContainer.getAll_w()
        for i in 0..<transkribus_w.count {
            let facs = transkribus_w[i].getAttribute(attributeName: "facs") ?? "FACS_MISSING"
            let text = transkribus_w[i].elementContent
            let sic = transkribus_w[i].getFirstElement(ofName: "sic")?.elementContent
            let transkribusWord = TranskribusWord(facs: facs, content: text ?? sic ?? "")
            transkribusWords[i] = [transkribusWord]
        }
        
        resultContainer = Amphisbaena_WordLinksContainer()
    }
    
    init(fromExistingContainer wordLinkContainer: Amphisbaena_WordLinksContainer, withOptionalTranskribusContainer transkribusContainer: Amphisbaena_TranskribusTEIContainer? = nil, optionalFlexTextContainer flexContainer: Amphisbaena_FlexTextContainer? = nil) {
        
        let wordLinks = wordLinkContainer.getOrderedElements(ofName: "wordLink").compactMap{$0 as? Amphisbaena_Container}
        
        //PROCESSING FLEX
        print(wordLinks.count)
        
        var wordCountMatches = false
        var flexWords: [Amphisbaena_Container]?
        if let flexContainer = flexContainer {
            flexWords = flexContainer.getAll_Word()
            wordCountMatches = (flexWords!.count == wordLinks.count)
        }
        print(wordCountMatches)
        
        for w in 0..<wordLinks.count {
            let wordLink = wordLinks[w]
            let guid = wordLink.getAttribute(attributeName: "guid") ?? ""
            var content: String!
            if wordCountMatches == true,
                let flexWords = flexWords,
                guid.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
                
                let txt = flexWords[w].searchForElement(withName: "item", withAttribute: "type", ofValue: "txt").first as? Amphisbaena_Element
                content = txt?.elementContent ?? Placeholder.notFound
                
            }
            else {
                content = wordLink.getAttribute(attributeName: "groundtruth") ?? Placeholder.notFound
            }
            let flexWord = FlexWord(guid: guid, content: content)
            
            flexGuids.append(flexWord)
        }
        
        //PROCESSING TRANSKRIBUS
        var transkribusAll_w: [Amphisbaena_Element]?
        if let transkribusContainer = transkribusContainer {
            transkribusAll_w = transkribusContainer.getAll_w()
        }
        for w in 0..<wordLinks.count {
            let wordLink = wordLinks[w]
            let guid = wordLink.getAttribute(attributeName: "guid") ?? ""
            guard guid.trimmingCharacters(in: .whitespacesAndNewlines) != "" else {continue;}
            
            var importedFacs: [TranskribusWord] = []
            
            let facsElements = wordLink.getOrderedElements(ofName: "facs")
            for facsElement in facsElements {
                let facs = facsElement.elementContent
                var content = Placeholder.notFound
                
                if let transkribusAll_w = transkribusAll_w,
                    let facs = facs,
                    facs.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
                    for wElement in transkribusAll_w {
                        if wElement.getAttribute(attributeName: "facs") == facs,
                            let wElementContent = wElement.elementContent {
                            content = wElementContent
                        }
                    }
                }
                
                if let facs = facs {
                    let word = TranskribusWord(facs: facs, content: content)
                    importedFacs.append(word)
                }
            }
            transkribusWords[w] = importedFacs;
        }
        
        resultContainer = Amphisbaena_WordLinksContainer()
    }
    
    func combineSelected(fromIndexSet indexSet: IndexSet) {
        if let first = indexSet.first,
            let last = indexSet.last,
            first >= 0,
            last < itemCount {
            
            var facsArr = transkribusWords[first]
            if facsArr != nil {
                indexSet.forEach { (index) in
                    if index != first {
                        if let newFacs = transkribusWords[index] {
                            facsArr!.append(contentsOf: newFacs)
                        }
                    }
                }
                transkribusWords[first] = facsArr!
                
                indexSet.forEach { (index) in
                    if index != first {
                        transkribusWords.removeValue(forKey: index)
                    }
                }
                
                let difference = max(last-first,0)
                
                for key in transkribusWords.keys.sorted() {
                    if key > first {
                        let newKey = key-difference;
                        let oldValue = transkribusWords[key]
                        transkribusWords[newKey] = oldValue
                        
                        if key >= transkribusWords.keys.count - difference {
                            transkribusWords.removeValue(forKey: key)
                        }
                    }
                }
            }
        }
    }
    
    func insertEmptyTranskribus(atIndexSet indexSet: IndexSet) {
        if let first = indexSet.first,
        first >= 0,
        first < itemCount {
            
            for key in transkribusWords.keys.sorted().dropFirst().reversed() {
                if key >= first {
                    let newKey = key+1;
                    let oldValue = transkribusWords[key]
                    transkribusWords[newKey] = oldValue
                }
            }
            
            transkribusWords[first] = nil
        }
    }
    
    func setupNewContainer() {
        guard let resultContainer = resultContainer else {return}
        resultContainer.elementEnclosing?.removeAll()
        
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
        }
    }
}
