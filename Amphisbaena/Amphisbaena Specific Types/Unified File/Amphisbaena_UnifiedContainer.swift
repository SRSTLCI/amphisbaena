//
//  Amphisbaena_UnifiedContainer.swift
//  Amphisbaena
//
//  Created by Casey on 3/30/20.
//  Copyright © 2020 Casey Fasthorse. All rights reserved.
//

import Foundation

class Amphisbaena_UnifiedContainer: Amphisbaena_Container {
    var teiHeader: Amphisbaena_UnifiedContainer_Tei?
    var xenoData: Amphisbaena_Container?
    var textBody: Amphisbaena_UnifiedContainer_TextBody?
    
    lazy var tokenizer = Amphisbaena_UnifiedTokenizer()
    
    init() {
        super.init(withName: "tei", isRoot: true, preferredAttributeOrder: [])
        elementAttributes = ["xmlns" : "http://www.tei-c.org/ns/1.0"]
    }
    
    struct ElementAttributeOrders {
        static let transkribus_surface      = ["ulx","uly","lrx","lry","corresp"]
        static let transkribus_graphic      = ["url", "width", "height"]
        static let transkribus_zone         = ["points","ulx","uly","lrx","lry","rendition","subtype","xml:id"]
        static let transkribus_teiElement   = ["facs","xml:id","n"]
    }
    
    private struct Token {
        var type: String = "TYPE"
        var identifier: String?
        var content: String?
    }
}

class Amphisbaena_UnifiedContainer_Tei: Amphisbaena_Container {
    var containerFileDesc: Amphisbaena_Container?
    var containerXenoData: Amphisbaena_Container?
    var containerFacsimiles: [Amphisbaena_Container] = [];
}
