//
//  Amphisbaena_ELANContainer.swift
//  Amphisbaena
//
//  Created by Casey on 3/26/20.
//  Copyright © 2020 Casey Fasthorse. All rights reserved.
//

import Foundation

class Amphisbaena_ELANContainer: Amphisbaena_Container {
    var containerHeader: Amphisbaena_Container?
    var containerTimeOrder: Amphisbaena_Container?
    var containerTiers: [Amphisbaena_Container] = []
    var elementsLinguisticTypes: [Amphisbaena_Element] = []
    var elementLocale: Amphisbaena_Element?
    var elementConstraints: [Amphisbaena_Element] = []
    
    private var timeSlots: [String : String] = [:]
    
    init(withName name: String, isRoot: Bool) {
        super.init(withName: name, isRoot: isRoot, preferredAttributeOrder: ["AUTHOR","DATE","FORMAT","VERSION","xmlns:xsi","xsi:noNamespaceSchemaLocation"]);
    }
    
    func element_GetTier(tierID: String, participant: String? = nil) -> Amphisbaena_Container? {
        for tier in containerTiers {
            if let ID = tier.getAttributes()["TIER_ID"],
                ID == tierID {
                if let participant = participant {
                    if let tierParticipant = tier.getAttributes()["PARTICIPANT"],
                        participant == tierParticipant {
                        return tier;
                    }
                }
                else {
                    return tier;
                }
            }
        }
        return nil;
    }
    
    func element_GetTiers(tierID: String, participant: String? = nil) -> [Amphisbaena_Container] {
        var tiers: [Amphisbaena_Container] = []
        for tier in containerTiers {
            if let ID = tier.getAttributes()["TIER_ID"],
                ID == tierID {
                if let participant = participant {
                    if let tierParticipant = tier.getAttributes()["PARTICIPANT"],
                        participant == tierParticipant {
                        tiers.append(tier)
                    }
                }
                else {
                    tiers.append(tier)
                }
            }
        }
        return tiers;
    }
    
    func element_GetLanguages() -> [Amphisbaena_Element] {
        var languages: [Amphisbaena_Element] = []
        let languageElements = getOrderedElements(ofName: "LANGUAGE")
        for language in languageElements {
            if let language = language as? Amphisbaena_Element {
                languages.append(language)
            }
        }
        return languages;
    }
    
    func header_getElements(ofName name: String) -> [Amphisbaena_Element] {
        guard let header = containerHeader else {return []}
        return header.getOrderedElements(ofName: name).compactMap { $0 as? Amphisbaena_Element }
    }
    
    func tier_GetOrderedAnnotations(tierID: String) -> [AmphisbaenaXMLTaggable] {
        guard let tier = element_GetTier(tierID: tierID) else {return []}
        let annotations = tier.getOrderedElements(ofName: "ANNOTATION")
        return annotations;
    }
    
    func tier_GetLanguage(tierID: String) -> String? {
        guard let tier = element_GetTier(tierID: tierID),
            let lang = tier.getAttribute(attributeName: "LANG_REF") else {return nil}
        return lang
    }
    
    func tier_GetParticipant(tierID: String) -> String? {
        guard let tier = element_GetTier(tierID: tierID),
            let lang = tier.getAttribute(attributeName: "PARTICIPANT") else {return nil}
        return lang
    }
    
    func precacheTimeSlots() {
        timeSlots = [:]
        if let containerTimeOrder = containerTimeOrder {
            let timeSlotElements = containerTimeOrder.getOrderedElements(ofName: "TIME_SLOT")
            for timeSlot in timeSlotElements {
                if let timeSlot = timeSlot as? Amphisbaena_Element,
                    let attributes = timeSlot.elementAttributes {
                    if let ts = attributes["TIME_SLOT_ID"],
                        let tValue = attributes["TIME_VALUE"] {
                        timeSlots[ts] = tValue;
                    }
                }
            }
        }
    }
    
    func getTimeSlotValue(timeslot: String) -> String? {
        return timeSlots[timeslot];
    }
}
