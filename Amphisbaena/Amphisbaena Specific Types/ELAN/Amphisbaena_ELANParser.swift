//
//  Amphisbaena_ELANContainer.swift
//  Amphisbaena
//
//  Created by Casey on 3/25/20.
//  Copyright © 2020 Casey Fasthorse. All rights reserved.
//

import Foundation

class Amphisbaena_ELANParser: NSObject {
    var stringData: Data
    
    var parser: XMLParser?
    
    var resultContainer: Amphisbaena_ELANContainer?
    
    var foundCharacters: String = ""
    var skipCharacters: Bool = false;
    
    var currentPropertyAttributes: [String : String]?
    var currentTier: Amphisbaena_Container?
    var currentTierAttributes: [String : String]?
    
    var currentAnnotation: Amphisbaena_Container?
    var currentAnnotationInner: Amphisbaena_Container?
    var currentAnnotationValue: Amphisbaena_Element?
    
    func parse() {
        parser = XMLParser(data: stringData)
        parser?.delegate = self
        parser?.parse()
        if let resultContainer = resultContainer {
            resultContainer.precacheTimeSlots();
        }
    }
    
    init?(XMLString string: String) {
        if let data = string.data(using: .utf8) {
            stringData = data
            resultContainer = Amphisbaena_ELANContainer(withName: "ANNOTATION_DOCUMENT", isRoot: true)
        }
        else {return nil}
    }
}

extension Amphisbaena_ELANParser: XMLParserDelegate {
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        skipCharacters = false;
        switch (elementName) {
        case "ANNOTATION_DOCUMENT":
            resultContainer?.elementAttributes = attributeDict
        case "HEADER":
            let headerContainer = Amphisbaena_Container(withName: elementName, isRoot: false)
            headerContainer.elementAttributes = attributeDict;
            resultContainer?.addElement(element: headerContainer);
            resultContainer?.containerHeader = headerContainer;
        case "MEDIA_DESCRIPTOR":
            if let headerContainer = resultContainer?.containerHeader {
                let attributes = attributeDict;
                let element = Amphisbaena_Element(elementName: elementName);
                element.elementAttributes = attributes;
                var preferredAttributeOrder: [String] = [];
                if let mimetype = attributes["MIME_TYPE"] {
                    if mimetype == "video/mp4" {
                        preferredAttributeOrder = ["MEDIA_URL","MIME_TYPE","RELATIVE_MEDIA_URL"]
                    }
                    else {
                        preferredAttributeOrder = ["EXTRACTED_FROM","MEDIA_URL","MIME_TYPE","RELATIVE_MEDIA_URL"]
                    }
                }
                element.preferredAttributeOrder = preferredAttributeOrder;
                headerContainer.addElement(element: element)
            }
        case "PROPERTY":
            if let _ = resultContainer?.containerHeader {
                currentPropertyAttributes = attributeDict;
            }
        case "TIME_ORDER":
            let timeOrderContainer = Amphisbaena_Container(withName: elementName, isRoot: false)
            resultContainer?.addElement(element: timeOrderContainer)
            resultContainer?.containerTimeOrder = timeOrderContainer
        case "TIME_SLOT":
            if let timeOrderContainer = resultContainer?.containerTimeOrder {
                let timeSlotElement = Amphisbaena_Element(elementName: elementName, attributes: attributeDict)
                timeSlotElement.preferredAttributeOrder = ["TIME_SLOT_ID", "TIME_VALUE"];
                timeOrderContainer.addElement(element: timeSlotElement)
            }
        case "TIER":
            let tierContainer = Amphisbaena_Container(withName: elementName, isRoot: false, preferredAttributeOrder: ["ANNOTATOR","DEFAULT_LOCALE","LINGUISTIC_TYPE_REF","PARENT_REF","PARTICIPANT","TIER_ID"])
            tierContainer.elementAttributes = attributeDict;
            currentTier = tierContainer
            resultContainer?.addElement(element: tierContainer)
            resultContainer?.containerTiers.append(tierContainer)
        case "ANNOTATION":
            if let currentTier = currentTier {
                let annotationContainer = Amphisbaena_Container(withName: elementName, isRoot: false)
                currentAnnotation = annotationContainer
                currentTier.addElement(element: annotationContainer)
            }
        case "ALIGNABLE_ANNOTATION", "REF_ANNOTATION":
            if let currentAnnotation = currentAnnotation {
                let annotationInner = Amphisbaena_Container(withName: elementName, isRoot: false)
                annotationInner.elementAttributes = attributeDict;
                currentAnnotation.addElement(element: annotationInner)
                currentAnnotationInner = annotationInner
                var preferredAttributeOrder: [String] = []
                if (elementName == "ALIGNABLE_ANNOTATION") {
                    preferredAttributeOrder = ["ANNOTATION_ID","TIME_SLOT_REF1","TIME_SLOT_REF2"]
                }
                else if (elementName == "REF_ANNOTATION") {
                    preferredAttributeOrder = ["ANNOTATION_ID","ANNOTATION_REF","PREVIOUS_ANNOTATION"]
                }
                annotationInner.preferredAttributeOrder = preferredAttributeOrder;
            }
        case "ANNOTATION_VALUE":
            if let currentAnnotationInner = currentAnnotationInner {
                let annotationValue = Amphisbaena_Element(elementName: elementName)
                currentAnnotationInner.addElement(element: annotationValue)
                currentAnnotationValue = annotationValue;
            }
        case "LINGUISTIC_TYPE":
            let linguisticTypeElement = Amphisbaena_Element(elementName: elementName)
            let preferredAttributeOrder = ["CONSTRAINTS","GRAPHIC_REFERENCES","LINGUISTIC_TYPE_ID","TIME_ALIGNABLE"]
            linguisticTypeElement.preferredAttributeOrder = preferredAttributeOrder;
            linguisticTypeElement.elementAttributes = attributeDict;
            resultContainer?.addElement(element: linguisticTypeElement)
            resultContainer?.elementsLinguisticTypes.append(linguisticTypeElement)
        case "LOCALE":
            let localeElement = Amphisbaena_Element(elementName: elementName)
            let preferredAttributeOrder = ["COUNTRY_CODE","LANGUAGE_CODE"]
            localeElement.preferredAttributeOrder = preferredAttributeOrder;
            localeElement.elementAttributes = attributeDict;
            resultContainer?.addElement(element: localeElement)
            resultContainer?.elementLocale = localeElement;
        case "CONSTRAINT":
            let constraintElement = Amphisbaena_Element(elementName: elementName)
            let preferredAttributeOrder = ["DESCRIPTION","STEREOTYPE"]
            constraintElement.preferredAttributeOrder = preferredAttributeOrder;
            constraintElement.elementAttributes = attributeDict;
            resultContainer?.addElement(element: constraintElement)
            resultContainer?.elementConstraints.append(constraintElement)
        case "LANGUAGE":
            let languageElement = Amphisbaena_Element(elementName: elementName)
            let preferredAttributeOrder = ["LANG_DEF", "LANG_ID", "LANG_LABEL"]
            languageElement.preferredAttributeOrder = preferredAttributeOrder;
            languageElement.elementAttributes = attributeDict;
            resultContainer?.addElement(element: languageElement)
            //resultContainer?.elementConstraints.append(languageElement)
        case "EXTERNAL_REF":
            let externalRefElement = Amphisbaena_Element(elementName: elementName)
            let preferredAttributeOrder = ["EXT_REF_ID","TYPE","VALUE"]
            externalRefElement.preferredAttributeOrder = preferredAttributeOrder;
            externalRefElement.elementAttributes = attributeDict;
            resultContainer?.addElement(element: externalRefElement)
            //resultContainer?.elementConstraints.append(externalRefElement)
        default:
            print("UNHANDLED Begin Element:" + elementName)
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        var rememberCharacters = false;
        switch (elementName) {
        case "ANNOTATION_DOCUMENT", "HEADER", "MEDIA_DESCRIPTOR", "TIME_SLOT", "LINGUISTIC_TYPE", "LOCALE", "CONSTRAINT", "LANGUAGE", "EXTERNAL_REF":
            break;
        case "PROPERTY":
            if let headerContainer = resultContainer?.containerHeader {
                let newProperty = Amphisbaena_Element(elementName: elementName, attributes: currentPropertyAttributes, elementContent: foundCharacters);
                headerContainer.addElement(element: newProperty)
                currentPropertyAttributes = nil;
            }
        case "TIER":
            currentTier = nil;
        case "TIME_ORDER":
            break;
        case "ANNOTATION":
            currentAnnotation = nil;
        case "ALIGNABLE_ANNOTATION", "REF_ANNOTATION":
            currentAnnotationInner = nil;
        case "ANNOTATION_VALUE":
            if let annotationValue = currentAnnotationValue {
                annotationValue.elementContent = foundCharacters;
                currentAnnotationValue = nil;
            }
        default:
            print("UNHANDLED End Element:" + elementName)
        }
        if (rememberCharacters == false) {self.foundCharacters = ""}
        skipCharacters = false;
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if string.trimmingCharacters(in: .whitespacesAndNewlines) == "" {return;}
        if skipCharacters == true {return;}
        self.foundCharacters += string
    }
}
