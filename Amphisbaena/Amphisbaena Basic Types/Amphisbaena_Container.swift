//
//  Amphisbaena_Container.swift
//  Amphisbaena
//
//  Created by Casey on 3/23/20.
//  Copyright © 2020 Casey Fasthorse. All rights reserved.
//

import Foundation

class Amphisbaena_Container: AmphisbaenaXMLTaggable {
    
    var rawFileContent: String?
    
    var isRoot: Bool = false;
    
    var elementName: String = ""
    var elementAttributes: [String : String]?
    var elementContent: String?
    var elementEnclosing: [AmphisbaenaXMLTaggable]?
    var elementIndentLevel: Int = 0;
    weak var elementParent: AmphisbaenaXMLTaggable?
    
    var elementEnclosingCount: Int {
        return elementEnclosing?.count ?? 0
    }
    
    var preferredAttributeOrder: [String] = []
    
    init(withName name: String, isRoot: Bool, preferredAttributeOrder: [String] = []) {
        self.isRoot = isRoot;
        self.preferredAttributeOrder = preferredAttributeOrder;
        self.elementName = name;
    }
    
    func sortElements(by closure: (AmphisbaenaXMLTaggable, AmphisbaenaXMLTaggable) -> Bool) {
        elementEnclosing?.sort(by: closure)
    }
    
    func generateXML(indentLevel: Int = 0) -> String {
        var xml = ""
        
        if isRoot {
            xml += AmphisbaenaTagFormatting.XML.xmlHeader + AmphisbaenaTagFormatting.XML.newline;
        }
        
        if elementContent == nil && elementEnclosingCount == 0 {
            xml += AmphisbaenaTagFormatting.makeElement(singleLineElement: elementName, attributes: elementAttributes, preferredOrder: preferredAttributeOrder, indentNumber: indentLevel+elementIndentLevel);
        }
        else {
            xml += AmphisbaenaTagFormatting.makeElement(beginElement: elementName, attributes: elementAttributes, preferredOrder: preferredAttributeOrder, indentNumber: indentLevel+elementIndentLevel)
            
            if let elementEnclosing = elementEnclosing {
                for element in elementEnclosing {
                    xml += element.generateXML(indentLevel: indentLevel+1+elementIndentLevel);
                }
            }
            
            xml += AmphisbaenaTagFormatting.makeElement(endElement: elementName, indentNumber: indentLevel+elementIndentLevel)
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
    
    func getOrderedElements(ofName elementName: String) -> [AmphisbaenaXMLTaggable] {
        guard let elementEnclosing = elementEnclosing else {return []}
        var elementCollection: [AmphisbaenaXMLTaggable] = []
        for element in elementEnclosing {
            if element.elementName == elementName {
                elementCollection.append(element);
            }
        }
        return elementCollection;
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
    
    func hasElementsMatching(name: String, matchingAttributes attributes: [String : String]?, recursively: Bool = false) -> [AmphisbaenaXMLTaggable] {
        guard let elementEnclosing = elementEnclosing else {return []}
        var elements: [AmphisbaenaXMLTaggable] = []
        for element in elementEnclosing {
            if element.elementName == name,
                element.elementAttributes == attributes {
                elements.append(element)
            }
            if recursively == true, let element = element as? Amphisbaena_Container {
                let subElements = element.hasElementsMatching(name: name, matchingAttributes: attributes, recursively: true)
                elements.append(contentsOf: subElements);
            }
        }
        return elements
    }
    
    func searchForElement(withName name: String, withAttribute attribute: String, ofValue value: String, recursively: Bool = false) -> [AmphisbaenaXMLTaggable] {
        guard let elementEnclosing = elementEnclosing else {return []}
        var elements: [AmphisbaenaXMLTaggable] = []
        for element in elementEnclosing {
            if element.elementName == name,
                let elementAttribute = element.getAttribute(attributeName: attribute),
                elementAttribute == value {
                elements.append(element)
            }
            if recursively == true, let element = element as? Amphisbaena_Container {
                let subElements = element.searchForElement(withName: name, withAttribute: attribute, ofValue: value, recursively: recursively)
                elements.append(contentsOf: subElements);
            }
        }
        return elements
    }
    
    func searchForElement(withAttribute attribute: String, ofValue value: String, recursively: Bool = false) -> [AmphisbaenaXMLTaggable] {
        guard let elementEnclosing = elementEnclosing else {return []}
        var elements: [AmphisbaenaXMLTaggable] = []
        for element in elementEnclosing {
            if let elementAttribute = element.getAttribute(attributeName: attribute),
                elementAttribute == value {
                elements.append(element)
            }
            if recursively == true, let element = element as? Amphisbaena_Container {
                let subElements = element.searchForElement(withAttribute: attribute, ofValue: value, recursively: recursively)
                elements.append(contentsOf: subElements);
            }
        }
        return elements
    }
    
    func searchForContainer(containingElementWithAttribute attribute: String, ofValue value: String, recursively: Bool = false) -> [Amphisbaena_Container] {
        guard let elementEnclosing = elementEnclosing else {return []}
        var elements: [Amphisbaena_Container] = []
        for element in elementEnclosing {
            if let element = element as? Amphisbaena_Container {
                let subElements = element.searchForElement(withAttribute: attribute, ofValue: value, recursively: recursively)
                if subElements.count > 0, elements.contains(where: {$0 === element}) == false {
                    elements.append(element);
                }
            }
            if recursively == true, let element = element as? Amphisbaena_Container {
                let subElements = element.searchForContainer(containingElementWithAttribute: attribute, ofValue: value, recursively: true)
                elements.append(contentsOf: subElements.filter({ (container) -> Bool in
                    elements.contains(where: {$0 === container}) == false
                }))
            }
        }
        return elements
    }
    
    func searchForAncestor(withName name: String, recursively: Bool) -> AmphisbaenaXMLTaggable? {
        
        if isRoot == true {return nil}
        
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
        
        if isRoot == true {return nil}
        
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
        if (isRoot) {return ancestors}
        
        guard let elementParent = elementParent else {return []}
        ancestors.append(elementParent)
        
        if let elementParent = elementParent as? Amphisbaena_Container {
            let parentAncestors = elementParent.getAllAncestors()
            ancestors.append(contentsOf: parentAncestors)
        }
        
        return ancestors
    }
    
    func flatMap(includeSelf: Bool = false, recursively: Bool = false) -> [AmphisbaenaXMLTaggable] {
        var elements: [AmphisbaenaXMLTaggable] = []
        if (includeSelf) {elements.append(self)}
        guard let elementEnclosing = elementEnclosing else {return elements}
        for element in elementEnclosing {
            elements.append(element)
            if recursively == true, let element = element as? Amphisbaena_Container {
                let subElements = element.flatMap(includeSelf: false, recursively: true)
                elements.append(contentsOf: subElements);
            }
        }
        return elements
    }
}

extension Amphisbaena_Container: NSCopying {
    func copy(with zone: NSZone? = nil) -> Any {
        let newContainer = Amphisbaena_Container(withName: self.elementName, isRoot: self.isRoot, preferredAttributeOrder: self.preferredAttributeOrder)
        newContainer.rawFileContent = rawFileContent
        newContainer.elementAttributes = elementAttributes
        newContainer.elementContent = elementContent
        newContainer.elementIndentLevel = elementIndentLevel
        newContainer.preferredAttributeOrder = preferredAttributeOrder
        newContainer.elementEnclosing = self.copyElements()
        return newContainer
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

