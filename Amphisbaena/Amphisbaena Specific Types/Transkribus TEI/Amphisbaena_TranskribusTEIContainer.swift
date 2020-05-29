//
//  Amphisbaena_TranskribusTEIContainer.swift
//  Amphisbaena
//
//  Created by Casey on 4/28/20.
//  Copyright © 2020 Casey Fasthorse. All rights reserved.
//

import Foundation

class Amphisbaena_TranskribusTEIContainer: Amphisbaena_Container {
    var teiHeader: Amphisbaena_Container?
    var facsimiles: [Amphisbaena_Container] = []
    var text: Amphisbaena_Container?
    
    var textBody: Amphisbaena_Container? {
        return text?.getFirstElement(ofName: "body") as? Amphisbaena_Container
    }
    
    init() {
        super.init(withName: "TEI", isRoot: true, preferredAttributeOrder: [])
        elementAttributes = ["xmlns" : "http://www.tei-c.org/ns/1.0"]
    }
    
    struct ZoneRendition {
        let printspace = "printspace"
        let textRegion = "TextRegion"
        let line = "Line"
        let word = "Word"
    }
    
    func findElement_withFacs(facs: String) -> AmphisbaenaXMLTaggable? {
        guard facsimiles.count > 0 else {return nil}
        for facsimile in facsimiles {
            guard let id = facsimile.getAttributes()["xml:id"] else {continue;}
            if id == facs {return facsimile}
            if let surface = facsimile.getFirstElement(ofName: "surface") as? Amphisbaena_Container {
                let zones = surface.getOrderedElements(ofName: "zone")
                for zone in zones {
                    if let zone = zone as? Amphisbaena_TranskribusTEIContainer_Zone {
                        if let zoneFacs = zone.getAttribute(attributeName: "xml:id"),
                            zoneFacs == facs {
                            return zone
                        }
                        else if let subzone = zone.findElement_withFacs(facs: facs) {
                            return subzone
                        }
                    }
                }
            }
        }
        return nil
    }
    
    func getAll_p() -> [Amphisbaena_Container] {
        guard let textBody = textBody else {return []}
        let p = textBody.getOrderedElements(ofName: "p").compactMap {$0 as? Amphisbaena_Container}
        return p
    }
    
    func getAll_w() -> [Amphisbaena_Element] {
        guard textBody != nil else {return []}
        let allp = getAll_p()
        guard allp.count > 0 else {return []}
        var allw: [Amphisbaena_Element] = []
        for p in allp {
            let p_w = p.getOrderedElements(ofName: "w").compactMap {$0 as? Amphisbaena_Element}
            allw.append(contentsOf: p_w)
        }
        return allw;
    }
}

class Amphisbaena_TranskribusTEIContainer_Zone: Amphisbaena_Container {
    var subzones: [Amphisbaena_TranskribusTEIContainer_Zone] = []
    
    func addElement_Subzone(subzone: Amphisbaena_TranskribusTEIContainer_Zone) {
        subzones.append(subzone)
        addElement(element: subzone)
    }
    
    func findElement_withFacs(facs: String) -> Amphisbaena_TranskribusTEIContainer_Zone? {
        for zone in subzones {
            if let zoneFacs = zone.getAttribute(attributeName: "xml:id"),
                zoneFacs == facs {
                return zone
            }
            else if let subzone = zone.findElement_withFacs(facs: facs) {
                return subzone
            }
        }
        return nil
    }
}
