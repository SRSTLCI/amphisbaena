//
//  Amphisbaena_WordLinksParserProvider.swift
//  Amphisbaena
//
//  Created by Casey on 9/15/20.
//  Copyright © 2020 Casey Fasthorse. All rights reserved.
//

import Foundation

class Amphisbaena_WordLinksParserProvider {
    struct RegEx {
        static let regexExtractVersion = try! NSRegularExpression(pattern: #"<formatVersion>(.+)<\/formatVersion>"#, options: [.dotMatchesLineSeparators])
    }
    
    static func determineVersion(forExistingContainer container: Amphisbaena_WordLinksContainer) -> Amphisbaena_WordLinksContainer.Version {
        return container.version
    }
    
    static func determineVersion(forText text: String) -> String? {
        let textRange = NSRange(text.startIndex..<text.endIndex, in: text)
        let matchVersion = RegEx.regexExtractVersion.firstMatch(in: text, options: [], range: textRange)
        var versionString: String? = nil
        if let matchVersion = matchVersion {
            for r in 1..<matchVersion.numberOfRanges {
                print("RANGE "+String(r))
                if let matchRange = Range(matchVersion.range(at: r), in: text) {
                    let matchString = String(text[matchRange])
                    print("PARSE MATCH: "+matchString)
                    versionString = matchString
                }
            }
        }
        return versionString
    }
    
    static func determineVersion(forText text: String) -> Amphisbaena_WordLinksContainer.Version? {
        if let versionString: String = determineVersion(forText: text),
            let version = Amphisbaena_WordLinksContainer.Version(rawValue: versionString) {
            return version
        }
        else {return nil}
    }
    
    static func getParser(forVersionString versionString: String?, withText text: String) -> Amphisbaena_WordLinksParser? {
        switch (versionString) {
        case "0.2":
            print("PARSER PROVIDER: File is version 0.2.")
            return Amphisbaena_WordLinksParser_Format02(XMLString: text)
        case "0.1",
             nil:
            if versionString == nil {
                print("PARSER PROVIDER: No value was found, so we are assuming this is a 0.1 word link file.")
            }
            else {
                print("PARSER PROVIDER: File is version 0.1.")
            }
            return Amphisbaena_WordLinksParser_Format01(XMLString: text)
        default:
            print("PARSER PROVIDER: A value other than no value at all or a supported version was found, so we are returning nil.")
            return nil;
        }
    }
    
    static func getParser(forVersion version: Amphisbaena_WordLinksContainer.Version, withText text: String) -> Amphisbaena_WordLinksParser? {
        return getParser(forVersionString: version.rawValue, withText: text)
    }
    
    static func getParser(forText text: String) -> Amphisbaena_WordLinksParser? {
        let versionString: String? = determineVersion(forText: text)
        switch (versionString) {
        case "0.2":
            print("PARSER PROVIDER: File is version 0.2.")
            return Amphisbaena_WordLinksParser_Format02(XMLString: text)
        case "0.1",
             nil:
            if versionString == nil {
                print("PARSER PROVIDER: No value was found, so we are assuming this is a 0.1 word link file.")
            }
            else {
                print("PARSER PROVIDER: File is version 0.1.")
            }
            return Amphisbaena_WordLinksParser_Format01(XMLString: text)
        default:
            print("PARSER PROVIDER: A value other than no value at all or a supported version was found, so we are returning nil.")
            return nil;
        }
    }
}
