//
//  AmphisbaenaXMLTaggable.swift
//  Amphisbaena
//
//  Created by Casey on 3/25/20.
//  Copyright © 2020 Casey Fasthorse. All rights reserved.
//

import Foundation

protocol AmphisbaenaXMLTaggable: AnyObject, NSCopying {
    var elementIndentLevel: Int {get set}
    var elementName: String {get set}
    var elementAttributes: [String : String]? {get set}
    var elementContent: String? {get set}
    var elementEnclosing: [AmphisbaenaXMLTaggable]? {get set}
    var elementParent: AmphisbaenaXMLTaggable? { get set }
    
    var preferredAttributeOrder: [String] {get set}
    
    func generateXML(indentLevel: Int) -> String
    func getAttributes() -> [String : String]
    func getAttribute(attributeName: String) -> String?
    
    func searchForAncestor(withName name: String, recursively: Bool) -> AmphisbaenaXMLTaggable?
    func searchForAncestor(withName name: String, withAttribute attribute: String, ofValue value: String, recursively: Bool) -> AmphisbaenaXMLTaggable?
    func getAllAncestors() -> [AmphisbaenaXMLTaggable]
}
