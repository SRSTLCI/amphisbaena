//
//  Amphisbaena_WordLinksContainer.swift
//  Amphisbaena
//
//  Created by Casey on 5/4/20.
//  Copyright © 2020 Casey Fasthorse. All rights reserved.
//

import Foundation

class Amphisbaena_WordLinksContainer: Amphisbaena_Container {
    enum Version: String, CaseIterable {
        case v01    = "0.1"
        case v02    = "0.2"
    }
    
    var version: Version = .v01
    
    init() {
        super.init(withName: "wordLinks", isRoot: true, preferredAttributeOrder: [])
    }
    
    func listWordLinks() -> [Amphisbaena_Container] {
        let wordLinks = self.getOrderedElements(ofName: "wordLink")
        return wordLinks.compactMap{$0 as? Amphisbaena_Container}
    }
}

extension Amphisbaena_WordLinksContainer {
    //convert 0.1 to 0.2
    func convertContainerFrom01(withTranskribusContainer transkribusContainer: Amphisbaena_TranskribusTEIContainer, withFLExFile flexContainer: Amphisbaena_FlexTextContainer) -> Amphisbaena_WordLinksContainer? {
        
        guard self.version == .v01 else {
            print("Attempted to convert word link container. This container is not v0.1")
            return nil
        }
        let wordLinkModifier = Amphisbaena_WordLinksModifier()
        wordLinkModifier.containerFlexText = flexContainer
        wordLinkModifier.containerTranskribusTEI = transkribusContainer
        wordLinkModifier.makeFlexList(fromFlexContainer: flexContainer)
        wordLinkModifier.makeTranskribusList(fromTranskribusContainer: transkribusContainer)
        
        //unwrap word links
        let wordLinks = self.getOrderedElements(ofName: "wordLink").compactMap {$0 as? Amphisbaena_Container}
        
        var facsIndex = 0;
        var guidIndex = 0;
        var facsIndices = [[Int]]()
        var guidIndices = [[Int]]()
        var wordLinksFinal = [Amphisbaena_WordLinksModifier.WordLink]()
        
        for i in 0..<wordLinks.count {
            let wordLink = wordLinks[i];
            
            //let guidValue       = wordLink.getAttribute(attributeName: "guid")
            let facsElements    = wordLink.getOrderedElements(ofName: "facs").compactMap{$0 as? Amphisbaena_Element}
            let facs = facsElements.compactMap{$0.elementContent}
            
            let guidArr = [guidIndex];
            guidIndices.append(guidArr)
            guidIndex += 1;
            var facsArr = [Int]()
            for _ in 0..<facs.count {
                facsArr.append(facsIndex)
                facsIndex += 1;
            }
            facsIndices.append(facsArr)
        }
        /*
        print(facsIndices)
        print(guidIndices)
        print(facsIndices.count)
        print(guidIndices.count)
        print(wordLinkModifier.transkribusWords.count)
        print(wordLinkModifier.flexWords.count)
        */
        for i in 0..<min(facsIndices.count,guidIndices.count) {
            let guid = guidIndices[i]
            let facs = facsIndices[i]
            let guidCount = guid.count
            let facsCount = facs.count == 0 ? -1 : facs.count
            let wordLink = Amphisbaena_WordLinksModifier.WordLink(uuid: UUID().uuidString, guidsFirst: guid.first ?? 0, guidsCount: guidCount, facsFirst: facs.first ?? 0, facsCount: facsCount)
            wordLinksFinal.append(wordLink)
        }
        wordLinkModifier.wordLinks = wordLinksFinal
        if wordLinksFinal.count <= 0 {return nil}
        wordLinkModifier.setupNewContainer()
        return wordLinkModifier.resultContainer
    }
}
