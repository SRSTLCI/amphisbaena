//
//  Amphisbaena_FlexTextContainer.swift
//  Amphisbaena
//
//  Created by Casey on 5/4/20.
//  Copyright © 2020 Casey Fasthorse. All rights reserved.
//

import Foundation

class Amphisbaena_FlexTextContainer: Amphisbaena_Container {
    var interlinearText: Amphisbaena_Container?
    var paragraphs: Amphisbaena_Container?
    var languages: Amphisbaena_Container?

    init() {
        super.init(withName: "document", isRoot: true, preferredAttributeOrder: [])
        elementAttributes = ["version" : "2"]
    }
    
    func getAll_Paragraph() -> [Amphisbaena_Container] {
        //print("called: getAll_Paragraph()")
        guard let paragraphs = interlinearText?.getFirstElement(ofName: "paragraphs") as? Amphisbaena_Container else {return []}
        let paragraph_elements = paragraphs.getOrderedElements(ofName: "paragraph").compactMap{$0 as? Amphisbaena_Container}
        return paragraph_elements
    }
    
    func getAll_Phrase() -> [Amphisbaena_Container] {
        //print("called: getAll_Phrase()")
        let allParagraph = getAll_Paragraph();
        guard allParagraph.count > 0 else {return []}
        //print(allParagraph.count)
        
        var allPhrases: [Amphisbaena_Container] = []
        for paragraph in allParagraph {
            guard let paragraphPhrases = paragraph.getFirstElement(ofName: "phrases") as? Amphisbaena_Container else {continue;}
            allPhrases.append(paragraphPhrases)
        }
        //print(allPhrases.count)
        guard allPhrases.count > 0 else {return []}
        
        var allPhrase: [Amphisbaena_Container] = []
        for phrases in allPhrases {
            let phrase_elements = phrases.getOrderedElements(ofName: "phrase").compactMap {$0 as? Amphisbaena_Container}
            allPhrase.append(contentsOf: phrase_elements)
        }
        //print(allPhrase.count)
        return allPhrase
    }
    
    func getAll_Word() -> [Amphisbaena_Container] {
        //print("called: getAll_Word()")
        let allPhrase = getAll_Phrase();
        guard allPhrase.count > 0 else {return []}
        //print(allPhrase.count)
        
        var allWords: [Amphisbaena_Container] = []
        for phrase in allPhrase {
            guard let words = phrase.getFirstElement(ofName: "words") as? Amphisbaena_Container else {continue;}
            allWords.append(words)
        }
        //print(allWords.count)
        
        var allWord: [Amphisbaena_Container] = []
        for words in allWords {
            let word_elements = words.getOrderedElements(ofName: "word").compactMap {$0 as? Amphisbaena_Container}
            allWord.append(contentsOf: word_elements)
        }
        //print(allWord.count)
        
        return allWord
    }
}
