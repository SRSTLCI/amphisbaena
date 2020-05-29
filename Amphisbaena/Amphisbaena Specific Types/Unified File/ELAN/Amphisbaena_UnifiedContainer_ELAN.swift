//
//  Amphisbaena_UnifiedContainer_ELAN.swift
//  Amphisbaena
//
//  Created by Casey on 5/14/20.
//  Copyright © 2020 Casey Fasthorse. All rights reserved.
//

import Foundation

extension Amphisbaena_UnifiedContainer {
    
    convenience init(unifiedFromElanContainer elanContainer: Amphisbaena_ELANContainer) {
        self.init();
        
        self.xenoData = generateXenoData(fromELAN: elanContainer)
        self.addElement(element: xenoData!)
        
        let textBody = Amphisbaena_UnifiedContainer_TextBody(elanContainer: elanContainer)
        self.textBody = textBody;
        
        self.addElement(element: textBody);
    }
    
    private func generateXenoData(fromELAN elanContainer: Amphisbaena_ELANContainer) -> Amphisbaena_Container {
        let xenoData = Amphisbaena_Container(withName: "xenoData", isRoot: false)
        let languages = Amphisbaena_Container(withName: "languages", isRoot: false)
        xenoData.addElement(element: languages)
        
        for languageElement in elanContainer.element_GetLanguages() {
            guard let attributes = languageElement.elementAttributes,
                let langCode = attributes["LANG_DEF"]
                else {continue;}
            
            let headerProperty = elanContainer.header_getElements(ofName: "PROPERTY").first { (element) -> Bool in
                if let attributes = element.elementAttributes, let name = attributes["NAME"], name == langCode {
                    return true
                }
                else {
                    return false
                }
            }
            
            if let font = headerProperty?.elementContent {
                let attributes: [String : String] = [
                "lang" : langCode,
                "font" : font
                ]
                let language = Amphisbaena_Element(elementName: "language", attributes: attributes)
                let preferredAttributeOrder = ["lang", "font", "vernacular"]
                language.preferredAttributeOrder = preferredAttributeOrder
                
                languages.addElement(element: language)
            }
        }
        
        xenoData.addElement(element: addFileSpecificData(fromELAN: elanContainer))
        
        return xenoData;
    }
    
    func addFileSpecificData(fromELAN elanContainer: Amphisbaena_ELANContainer) -> Amphisbaena_Container {
        let container = Amphisbaena_Container(withName: "elanFile", isRoot: false)
        
        if let header = elanContainer.containerHeader {
            container.addElement(element: header)
        }
        
        let linguistic_types = elanContainer.getOrderedElements(ofName: "LINGUISTIC_TYPE")
        for linguistic_type in linguistic_types {
            container.addElement(element: linguistic_type)
        }
        let languages = elanContainer.getOrderedElements(ofName: "LANGUAGE")
        for language in languages {
            container.addElement(element: language)
        }
        let constraints = elanContainer.getOrderedElements(ofName: "CONSTRAINT")
        for constraint in constraints {
            container.addElement(element: constraint)
        }
        let external_refs = elanContainer.getOrderedElements(ofName: "EXTERNAL_REF")
        for external_ref in external_refs {
            container.addElement(element: external_ref)
        }
        
        return container
    }
    
}
