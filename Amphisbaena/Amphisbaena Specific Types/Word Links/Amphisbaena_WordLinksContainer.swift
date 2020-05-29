//
//  Amphisbaena_WordLinksContainer.swift
//  Amphisbaena
//
//  Created by Casey on 5/4/20.
//  Copyright © 2020 Casey Fasthorse. All rights reserved.
//

import Foundation

class Amphisbaena_WordLinksContainer: Amphisbaena_Container {
    init() {
        super.init(withName: "wordLinks", isRoot: true, preferredAttributeOrder: [])
    }
    
    func listWordLinks() -> [Amphisbaena_Container] {
        let wordLinks = self.getOrderedElements(ofName: "wordLink")
        return wordLinks.compactMap{$0 as? Amphisbaena_Container}
    }
}
