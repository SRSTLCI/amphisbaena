//
//  Amphisbaena_UnifiedContainer_MultipleFiles.swift
//  Amphisbaena
//
//  Created by Casey on 5/14/20.
//  Copyright © 2020 Casey Fasthorse. All rights reserved.
//

import Foundation

extension Amphisbaena_UnifiedContainer {
    convenience init(transkribusContainer: Amphisbaena_TranskribusTEIContainer,
                     flexContainer: Amphisbaena_FlexTextContainer,
                     wordlinkContainer: Amphisbaena_WordLinksContainer,
                     TEITagsContainer: Amphisbaena_TEITagContainer?,
                     elanContainer: Amphisbaena_ELANContainer?) {
        self.init()
        
        if let transkribusTeiFileHeader = transkribusContainer.getFirstElement(ofName: "teiHeader") as? Amphisbaena_Container,
            let transkribusFileDesc = transkribusTeiFileHeader.getFirstElement(ofName: "fileDesc") as? Amphisbaena_Container
            {
                let fileHeader = Amphisbaena_Container(withName: "teiHeader", isRoot: false)
                self.addElement(element: fileHeader)
                
                let fileDesc = transkribusFileDesc.copy() as! Amphisbaena_Container
                fileHeader.addElement(element: fileDesc)
                
                fileHeader.addElement(element: generateXenoData(transkribusContainer: transkribusContainer, flexContainer: flexContainer))
                
                let facsimiles = transkribusContainer.getOrderedElements(ofName: "facsimile")
                for facsimile in facsimiles {
                    if let facsimileCopy = facsimile.copy() as? Amphisbaena_Container {
                        fileHeader.addElement(element: facsimileCopy)
                }
            }
        }
        
        if wordlinkContainer.version == .v02 {
            print("Word link version is v02.")
            let tokens = tokenizer.flexTranskribus_tokenizeData_v02(transkribusContainer: transkribusContainer, flexContainer: flexContainer, wordLinkContainer: wordlinkContainer)
            let textBody = Amphisbaena_UnifiedContainer_TextBody(tokensFromTranskribusFlex: tokens, transkribusContainer: transkribusContainer, flexContainer: flexContainer, TEITagsContainer: TEITagsContainer, elanContainer: elanContainer)
            self.textBody = textBody;
            self.addElement(element: textBody)
            
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
            
        }
        else if wordlinkContainer.version == .v01 {
            print("Word link version is v01.")
            let tokens = tokenizer.flexTranskribus_tokenizeData(transkribusContainer: transkribusContainer, flexContainer: flexContainer, wordLinkContainer: wordlinkContainer)
            let textBody = Amphisbaena_UnifiedContainer_TextBody(tokensFromTranskribusFlex: tokens, transkribusContainer: transkribusContainer, flexContainer: flexContainer, TEITagsContainer: TEITagsContainer, elanContainer: elanContainer)
            self.textBody = textBody;
            self.addElement(element: textBody)
        }
    }
    
    private func generateXenoData(transkribusContainer: Amphisbaena_TranskribusTEIContainer,
    flexContainer: Amphisbaena_FlexTextContainer) -> Amphisbaena_Container {
        let xenoData = Amphisbaena_Container(withName: "xenoData", isRoot: false)
        
        //languages
        if let interlinearText = flexContainer.interlinearText {
            if let languages = interlinearText.getFirstElement(ofName: "languages"),
                let languagesCopy = languages.copy() as? Amphisbaena_Container {
                xenoData.addElement(element: languagesCopy)
            }
        }
        
        return xenoData
    }
}
