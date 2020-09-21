//
//  Amphisbaena_UnifiedContainer_TextBody.swift
//  Amphisbaena
//
//  Created by Casey on 5/14/20.
//  Copyright © 2020 Casey Fasthorse. All rights reserved.
//

import Foundation

class Amphisbaena_UnifiedContainer_TextBody: Amphisbaena_Container {
    var containerBody: Amphisbaena_Container = Amphisbaena_Container(withName: "body", isRoot: false)
    var containerParagraphs: Amphisbaena_Container = Amphisbaena_Container(withName: "paragraphs", isRoot: false);
    var containerParagraphsP: [Amphisbaena_Container] = [];
    var currentContainerParagraphP: Amphisbaena_Container?
    var participants: [Participant] = [];
    
    //var flexWordOrder: [String : Int] = [:]

    typealias Participant = String

    init() {
        super.init(withName: "text", isRoot: false, preferredAttributeOrder: [])
        setupBodyParagraphs()
    }

    struct ElementAttributeOrder {
        static let paragraph = ["guid", "facs"]
        static let utterance = ["start", "end"]
        static let gloss = ["lang", "cert"]
        static let phr = ["guid", "start", "end", "who", "media-file"]
        static let w = ["facs", "cert"]
        static let lb = ["facs", "n"]
        static let pb = ["facs", "n"]
    }

    func setupBodyParagraphs() {
        self.addElement(element: containerBody)
        containerBody.addElement(element: containerParagraphs)
    }
}
