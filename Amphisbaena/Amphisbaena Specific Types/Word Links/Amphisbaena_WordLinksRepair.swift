//
//  Amphisbaena_WordLinksRepair.swift
//  Amphisbaena
//
//  Created by Casey on 11/16/20.
//  Copyright © 2020 Casey Fasthorse. All rights reserved.
//

import Foundation

class Amphisbaena_WordLinksRepair {
    
    var containerWordLinks: Amphisbaena_WordLinksContainer
    var containerTranskribus: Amphisbaena_TranskribusTEIContainer
    var containerFlexText: Amphisbaena_FlexTextContainer
    
    var finalWordLinks: [Amphisbaena_WordLinksModifier.WordLink] = []
    
    var resultWordLinksContainer: Amphisbaena_WordLinksContainer?
    
    init(containerWordLinks: Amphisbaena_WordLinksContainer, containerTranskribus: Amphisbaena_TranskribusTEIContainer, containerFlexText: Amphisbaena_FlexTextContainer) {
        
        self.containerWordLinks = containerWordLinks
        self.containerTranskribus = containerTranskribus
        self.containerFlexText = containerFlexText
        
        finalWordLinks = [];
        
    }
    
}

extension Amphisbaena_WordLinksRepair {
    func performRepair() {
        print("Word Link Repair started.")
        finalWordLinks = [];
        let wordLinks = containerWordLinks.listWordLinks()
        let transkribusW = containerTranskribus.getAll_w()
        let flextextWord = containerFlexText.getAll_Word()
        
        let wordLinksCount = wordLinks.count
        let transkribusWCount = transkribusW.count
        let flextextWordCount = flextextWord.count
        
        var wordLinkContainer = Amphisbaena_WordLinksContainer();
        let version = Amphisbaena_Element(elementName: "formatVersion", attributes: nil, elementContent: "0.2")
        wordLinkContainer.addElement(element: version)
        
        var currentTrack_T = 0
        var currentTrack_F = 0
        var currentLookAhead_T = 0
        var currentLookAhead_F = 0
        
        print("WORD LINK COUNT:")
        print(wordLinks.count)
        print("TRANSKRIBUS COUNT:")
        print(transkribusW.count)
        print("FLEX COUNT:")
        print(flextextWord.count)
        for wordLink in wordLinks {
            //reset lookahead
            currentLookAhead_T = 0
            currentLookAhead_F = 0
            
            //identify the guids in the word link
            let wlGuids = wordLink.getOrderedElements(ofName: "guid").compactMap{$0 as? Amphisbaena_Element}
            let wlFacs = wordLink.getOrderedElements(ofName: "facs").compactMap{$0 as? Amphisbaena_Element}
            
            //grab the first facs and guid value
            let wlGuids_First = wlGuids.first
            let wlFacs_First = wlFacs.first
            
            let flexGT = wlGuids_First?.getAttribute(attributeName: "groundtruth") ?? "NIL"
            let teiGT = wlFacs_First?.getAttribute(attributeName: "groundtruth") ?? "NIL"
            print("PROCESSING WORD LINK: "+flexGT+"/"+teiGT)
            
            //set initial values
            var facsFirst = currentTrack_F
            var guidFirst = currentTrack_T
            var facsCount = 0;
            var guidCount = 0;
            
            //advance the tracks until we find the first one in each
            while currentTrack_F < flextextWordCount {
                let currentFlex = flextextWord[currentTrack_F]
                let guid = wlGuids_First?.elementContent
                let content = wlGuids_First?.getAttribute(attributeName: "groundtruth")
                if flexMatch(guid: guid, content: content, container: currentFlex) {
                    guidCount = 1;
                    break;
                }
                currentTrack_F += 1;
            }
            if currentTrack_F >= flextextWordCount {
                guidCount = -1;
                currentTrack_F = min(guidFirst,flextextWordCount-1);
            }
            
            while currentTrack_T < transkribusWCount {
                let currentFacs = transkribusW[currentTrack_T]
                let facs = wlFacs_First?.elementContent
                let content = wlFacs_First?.getAttribute(attributeName: "groundtruth")
                if transkribusMatch(facs: facs, content: content, element: currentFacs) {
                    facsCount = 1;
                    break;
                }
                currentTrack_T += 1;
            }
            if currentTrack_T >= transkribusWCount {
                facsCount = -1;
                currentTrack_T = min(facsFirst,transkribusWCount-1);
            }
            
            //set the first facs and guid to the ones we found
            facsFirst = currentTrack_T
            guidFirst = currentTrack_F
            
            //if counts > 1, look ahead and try and find the next words in sequence
            if (guidCount > 0 && guidCount != wlGuids.count) {
                var abortLookAhead = false;
                currentLookAhead_F = 1;
                var lookAheadIndex = currentTrack_F + currentLookAhead_F;
                while (abortLookAhead == false && lookAheadIndex < flextextWordCount && guidCount != wlGuids.count) {
                    let wlGuidIndex = guidCount
                    let wlGuid = wlGuids[wlGuidIndex]
                    lookAheadIndex = currentTrack_F + currentLookAhead_F;
                    let currentFlex = flextextWord[lookAheadIndex]
                    let guid = wlGuid.elementContent
                    let content = wlGuid.getAttribute(attributeName: "groundtruth")
                    if flexMatch(guid: guid, content: content, container: currentFlex) {
                        guidCount += 1;
                    }
                    else {
                        abortLookAhead = true;
                    }
                    currentLookAhead_F += 1;
                }
            }
            
            if (facsCount > 0 && facsCount != wlFacs.count) {
                var abortLookAhead = false;
                currentLookAhead_T = 1;
                var lookAheadIndex = currentTrack_T + currentLookAhead_T;
                while (abortLookAhead == false && lookAheadIndex < transkribusWCount && facsCount != wlFacs.count) {
                    let wlFacsIndex = facsCount
                    let wlFacsSingle = wlFacs[wlFacsIndex]
                    lookAheadIndex = currentTrack_T + currentLookAhead_T;
                    let currentFacs = transkribusW[lookAheadIndex]
                    let facs = wlFacsSingle.elementContent
                    let content = wlFacsSingle.getAttribute(attributeName: "groundtruth")
                    if transkribusMatch(facs: facs, content: content, element: currentFacs) {
                        facsCount += 1;
                    }
                    else {
                        abortLookAhead = true;
                    }
                    currentLookAhead_T += 1;
                }
            }
            
            var flexContent = ""
            var teiContent = ""
            if (guidCount > 0) {
                for i in guidFirst..<(guidFirst+guidCount) {
                    let flexItem = flextextWord[i].searchForElement(withName: "item", withAttribute: "type", ofValue: "txt").first as? Amphisbaena_Element
                    flexContent += flexItem?.elementContent ?? "NIL"
                    if (i < guidFirst+guidCount-1) {
                        flexContent += ", "
                    }
                }
            }
            
            if (facsCount > 0) {
                for i in facsFirst..<(facsFirst+facsCount) {
                    teiContent += transkribusW[i].elementContent ?? "NIL"
                    if (i < facsFirst+facsCount-1) {
                        teiContent += ", "
                    }
                }
            }
            
            let statsFacs = String(format: "facs: %d, facsCount: %d", facsFirst, facsCount);
            let statsGuid = String(format: "guid: %d, guidCount: %d", guidFirst, guidCount);
            print("LINK: "+statsGuid+", "+statsFacs)
            print("CONTENT: flex: "+flexContent+", tei: "+teiContent);
            
            if let uuid = wordLink.getAttribute(attributeName: "uuid") {
                finalWordLinks.append(Amphisbaena_WordLinksModifier.WordLink(uuid: uuid, guidsFirst: guidFirst, guidsCount: guidCount, facsFirst: facsFirst, facsCount: facsCount))
            }
            
            currentTrack_F += 1;
            currentTrack_T += 1;
            
        }
        
        //create a new modifier with our containers and word links
        if finalWordLinks.count > 0 {
            let modifier = Amphisbaena_WordLinksModifier(fromExistingWordLinks: finalWordLinks, transkribusContainer: containerTranskribus, flexContainer: containerFlexText)
            modifier.setupNewContainer()
            if let newContainer = modifier.resultContainer {
                wordLinkContainer = newContainer
            }
            print(wordLinkContainer.generateXML())
        }
        resultWordLinksContainer = wordLinkContainer
    }
    
}
extension Amphisbaena_WordLinksRepair {
    func flexMatch(guid: String?, content: String?, container: Amphisbaena_Container) -> Bool {
        var guidMatch = false;
        if let guid = guid {
            guidMatch = flexMatchGuid(guid: guid, container: container)
        }
        var contentMatch = false
        if let content = content {
            contentMatch = flexMatchContent(content: content, container: container)
        }
        //print(String(format: "FLEX MATCH: guid: %d, content: %d", guidMatch ? 1 : 0, contentMatch ? 1 : 0))
        return guidMatch || contentMatch
    }
    
    func flexMatchGuid(guid: String, container: Amphisbaena_Container) -> Bool {
        if let containerGuid = container.getAttribute(attributeName: "guid") {
            return containerGuid == guid
        }
        return false
    }
    
    func flexMatchContent(content: String, container: Amphisbaena_Container) -> Bool {
        let containerItems = container.getOrderedElements(ofName: "item")
        if containerItems.contains(where: { (elementItem) -> Bool in
            elementItem.elementContent == content
           }) == true {
            return true
        }
        return false
    }
}

extension Amphisbaena_WordLinksRepair {
    func transkribusMatch(facs: String?, content: String?, element: Amphisbaena_Element) -> Bool {
        var facsMatch = false;
        if let facs = facs {
            facsMatch = transkribusMatchFacs(facs: facs, element: element)
        }
        var contentMatch = false
        if let content = content {
            contentMatch = transkribusMatchContent(content: content, element: element)
        }
        return facsMatch || contentMatch
    }
    
    func transkribusMatchFacs(facs: String, element: Amphisbaena_Element) -> Bool {
        if let elementFacs = element.getAttribute(attributeName: "facs") {
            return elementFacs == facs
        }
        return false
    }
    
    func transkribusMatchContent(content: String, element: Amphisbaena_Element) -> Bool {
        if let elementContent = element.elementContent {
            return elementContent == content
        }
        return false
    }
}
