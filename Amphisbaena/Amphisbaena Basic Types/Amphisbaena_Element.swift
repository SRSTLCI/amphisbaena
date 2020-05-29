//
//  Amphisbaena_Element.swift
//  Amphisbaena
//
//  Created by Casey on 3/23/20.
//  Copyright © 2020 Casey Fasthorse. All rights reserved.
//

import Foundation

class Amphisbaena_Element: AmphisbaenaXMLTaggable {
    
    var elementName: String
    var elementAttributes: [String : String]?
    var elementContent: String?
    var elementEnclosing: [AmphisbaenaXMLTaggable]?
    var elementIndentLevel: Int = 0;
    weak var elementParent: AmphisbaenaXMLTaggable?
    
    var preferredAttributeOrder: [String] = []
    
    init(elementName: String, attributes: [String : String]? = nil, elementContent: String? = nil) {
        self.elementName = elementName;
        self.elementAttributes = attributes;
        self.elementContent = elementContent;
    }
    
    func generateXML(indentLevel: Int = 0) -> String {
        var xml = ""
        
        if let elementEnclosing = elementEnclosing {
            xml += AmphisbaenaTagFormatting.makeElement(beginElement: elementName, attributes: elementAttributes, preferredOrder: preferredAttributeOrder, indentNumber: indentLevel + elementIndentLevel, addNewline: true)
            
            for element in elementEnclosing {
                xml += element.generateXML(indentLevel: indentLevel+elementIndentLevel+1);
            }
            
            if let elementContent = elementContent {
                //xml += AmphisbaenaTagFormatting.XML.newline
                xml += elementContent;
            }
            
            xml += AmphisbaenaTagFormatting.makeElement(endElement: elementName, indentNumber: indentLevel + elementIndentLevel, addNewline: true)
        }
        else if let elementContent = elementContent {
            xml += AmphisbaenaTagFormatting.makeElement(beginElement: elementName, attributes: elementAttributes, preferredOrder: preferredAttributeOrder, indentNumber: indentLevel + elementIndentLevel, addNewline: false)
            
            xml += elementContent;
            
            xml += AmphisbaenaTagFormatting.makeElement(endElementOnSameLine: elementName, addNewline: true)
        }
        else {
            xml += AmphisbaenaTagFormatting.makeElement(singleLineElement: elementName, attributes: elementAttributes, preferredOrder: preferredAttributeOrder, indentNumber: indentLevel+elementIndentLevel);
        }
        
        return xml;
    }
    
    func addElement(element: AmphisbaenaXMLTaggable) {
        if elementEnclosing == nil {elementEnclosing = [];}
        elementEnclosing?.append(element);
        element.elementParent = self
    }
    
    func getAttributes() -> [String : String] {
        if let attributes = elementAttributes {return attributes}
        else {return [:]}
    }
    
    func getAttribute(attributeName: String) -> String? {
        guard let attributes = elementAttributes else {return nil}
        return attributes[attributeName]
    }
    
    func getFirstElement(ofName elementName: String) -> AmphisbaenaXMLTaggable? {
        guard let elementEnclosing = elementEnclosing else {return nil}
        for element in elementEnclosing {
            if element.elementName == elementName {
                return element;
            }
        }
        return nil;
    }
    
    func searchForAncestor(withName name: String, recursively: Bool) -> AmphisbaenaXMLTaggable? {
        
        guard let elementParent = elementParent else {return nil}
        
        if elementParent.elementName == name {
            return elementParent
        }
        else if recursively == true {
            return elementParent.searchForAncestor(withName: name, recursively: true)
        }
        else {return nil}
    }
    
    func searchForAncestor(withName name: String, withAttribute attribute: String, ofValue value: String, recursively: Bool = false) -> AmphisbaenaXMLTaggable? {
        
        guard let elementParent = elementParent else {return nil}
        
        if elementParent.elementName == name,
            let elementAttribute = elementParent.getAttribute(attributeName: attribute),
            elementAttribute == value {
            return elementParent
        }
        else if recursively == true {
            return elementParent.searchForAncestor(withName: name, withAttribute: attribute, ofValue: value, recursively: true)
        }
        else {return nil}
    }
    
    func getAllAncestors() -> [AmphisbaenaXMLTaggable] {
        var ancestors: [AmphisbaenaXMLTaggable] = []
        
        guard let elementParent = elementParent else {return []}
        ancestors.append(elementParent)
        
        if let elementParent = elementParent as? Amphisbaena_Container {
            let parentAncestors = elementParent.getAllAncestors()
            ancestors.append(contentsOf: parentAncestors)
        }
        
        return ancestors
    }
}

extension Amphisbaena_Element: NSCopying {
    func copy(with zone: NSZone? = nil) -> Any {
        let newElement = Amphisbaena_Element(elementName: elementName, attributes: elementAttributes, elementContent: elementContent)
        newElement.elementIndentLevel = elementIndentLevel
        newElement.preferredAttributeOrder = preferredAttributeOrder
        newElement.elementEnclosing = self.copyElements()
        return newElement
    }
    
    private func copyElements() -> [AmphisbaenaXMLTaggable]? {
        let duplicateElements = elementEnclosing?.compactMap{$0.copy() as? AmphisbaenaXMLTaggable}
        return duplicateElements
    }
    
    private func removeElement(fromCopiedElements copiedElements: [AmphisbaenaXMLTaggable]?, element: AmphisbaenaXMLTaggable) -> [AmphisbaenaXMLTaggable]? {
        guard let copiedElements = copiedElements else {return nil}
        var workingCopiedElements = copiedElements
        workingCopiedElements.removeAll(where: { (copiedElement) -> Bool in
            return copiedElement === element
        })
        return workingCopiedElements
    }
}
