//
//  AmphisbaenaTagFormatting.swift
//  Amphisbaena
//
//  Created by Casey on 3/25/20.
//  Copyright © 2020 Casey Fasthorse. All rights reserved.
//

import Foundation

struct AmphisbaenaTagFormatting {
    
    struct XML {
        static let xmlHeader                    = "<?xml version='1.0' encoding='UTF-8'?>"
        
        static let placeholderElementName       = "$ELEMENTNAME$"
        static let placeholderElementAttributes = "$ATTRIBUTES$"
        static let placeholderAttributeName     = "$ATTRIBUTENAME$"
        static let placeholderAttributeValue    = "$ATTRIBUTEVALUE$"
        
        static let elementBegin         = "<$ELEMENTNAME$$ATTRIBUTES$>"
        static let elementEnd           = "</$ELEMENTNAME$>"
        static let elementSingleLine    = "<$ELEMENTNAME$$ATTRIBUTES$/>"
        
        static let attribute            = "$ATTRIBUTENAME$=\"$ATTRIBUTEVALUE$\""
        
        static let indent               = "\t"
        static let newline              = "\n"
        static let empty                = ""
    }
    
    static func indent(by number: Int) -> String {
        var str = ""
        for _ in 0..<number {str += XML.indent}
        return str;
    }
    
    static func makeElement(beginElement name: String, attributes: [String : String]?, preferredOrder: [String] = [], indentNumber: Int, addNewline: Bool = true) -> String {
        var element = indent(by: indentNumber) + XML.elementBegin.replacingOccurrences(of: XML.placeholderElementName, with: name);
        let attributeString = makeAttributes(attributes: attributes, preferredOrder: preferredOrder);
        if (attributeString != XML.empty) {
            element = element.replacingOccurrences(of: XML.placeholderElementAttributes, with: " "+attributeString);
        }
        else {
            element = element.replacingOccurrences(of: XML.placeholderElementAttributes, with: XML.empty);
        }
        if (addNewline) {element += XML.newline}
        return element;
    }
    
    static func makeElement(endElement name: String, indentNumber: Int, addNewline: Bool = true) -> String {
        var element = indent(by: indentNumber) + XML.elementEnd.replacingOccurrences(of: XML.placeholderElementName, with: name);
        if (addNewline) {element += XML.newline}
        return element;
    }
    
    static func makeElement(endElementOnSameLine name: String, addNewline: Bool = true) -> String {
        var element = XML.elementEnd.replacingOccurrences(of: XML.placeholderElementName, with: name);
        if (addNewline) {element += XML.newline}
        return element;
    }
    
    static func makeElement(singleLineElement name: String, attributes: [String : String]?, preferredOrder: [String] = [], indentNumber: Int, addNewline: Bool = true) -> String {
        var element = indent(by: indentNumber) + XML.elementSingleLine.replacingOccurrences(of: XML.placeholderElementName, with: name);
        let attributeString = makeAttributes(attributes: attributes, preferredOrder: preferredOrder);
        if (attributeString != XML.empty) {
            element = element.replacingOccurrences(of: XML.placeholderElementAttributes, with: " "+attributeString);
        }
        else {
            element = element.replacingOccurrences(of: XML.placeholderElementAttributes, with: XML.empty);
        }
        if (addNewline) {element += XML.newline}
        return element;
    }
    
    static func makeAttributes(attributes: [String : String]?, preferredOrder: [String] = []) -> String {
        var atts = XML.empty;
        if let attributes = attributes {
            var mutableAttributes = attributes;
            for key in preferredOrder {
                if let value = mutableAttributes[key] {
                    let newAtt = makeAttribute(attributeName: key, attributeValue: value)
                    atts = addAttribute(toAttributeList: atts, attributeToAdd: newAtt)
                    mutableAttributes.removeValue(forKey: key)
                }
            }
            for (key, value) in mutableAttributes {
                let newAtt = makeAttribute(attributeName: key, attributeValue: value)
                atts = addAttribute(toAttributeList: atts, attributeToAdd: newAtt)
            }
        }
        return atts;
    }
    
    static func makeAttribute(attributeName: String, attributeValue: String) -> String {
        var newAtt = XML.attribute;
        
        newAtt = newAtt.replacingOccurrences(of: XML.placeholderAttributeName, with: attributeName)
        newAtt = newAtt.replacingOccurrences(of: XML.placeholderAttributeValue, with: attributeValue)
        
        return newAtt;
    }
    
    static func addAttribute(toAttributeList attributeList: String, attributeToAdd newAtt: String) -> String {
        var atts = attributeList;
        if (atts == XML.empty) {
            atts = newAtt;
        }
        else {
            atts += " "
            atts += newAtt;
        }
        return atts;
    }
}
