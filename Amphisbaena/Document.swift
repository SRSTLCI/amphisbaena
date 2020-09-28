//
//  Document.swift
//  Amphisbaena
//
//  Created by Casey on 2/16/20.
//  Copyright © 2020 Casey Fasthorse. All rights reserved.
//

import Cocoa

class Document: NSDocument {
    
    var primaryWindowController: NSWindowController?
    var rawData: Data?
    var plistData: [String : Any]?
    
    struct FileDictionaryKeys {
        static let flexXML = "flextext"
        static let transkribusTEI = "transkribusTEI"
        static let transkribusTags = "transkribusTags"
        static let elanEAF  = "elanEAF"
        static let wordLinks    = "wordLinks"
    }

    override init() {
        super.init()
        // Add your subclass-specific initialization here.
    }

    override class var autosavesInPlace: Bool {
        return true
    }

    override func makeWindowControllers() {
        Swift.print("makeWindowControllers()")
        // Returns the Storyboard that contains your Document window.
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        let windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("Document Window Controller")) as! NSWindowController
        primaryWindowController = windowController
        self.addWindowController(windowController)
        setViewControllerContent(data: plistData)
    }
    
    func setViewControllerContent(data: [String : Any]?) {
        guard let plistData = plistData, let windowController = primaryWindowController, let viewController = windowController.contentViewController as? ViewController else {return}
        
            
        if let transkribus = plistData[FileDictionaryKeys.transkribusTEI] as? String,
            let transkribusParser = Amphisbaena_TranskribusTEIParser(XMLString: transkribus) {
            transkribusParser.parse()
            viewController.containerTranskribusTEI = transkribusParser.resultContainer
        }
        
        if let flexText = plistData[FileDictionaryKeys.flexXML] as? String,
            let flexParser = Amphisbaena_FlexTextParser(XMLString: flexText) {
            flexParser.parse()
            viewController.containerFlexText = flexParser.resultContainer
        }
        
        if let elanEaf = plistData[FileDictionaryKeys.elanEAF] as? String,
            let elanParser = Amphisbaena_ELANParser(XMLString: elanEaf) {
            elanParser.parse()
            viewController.containerELAN = elanParser.resultContainer
        }
        
        if let wordLink = plistData[FileDictionaryKeys.wordLinks] as? String,
           let wordLinkParser = Amphisbaena_WordLinksParserProvider.getParser(forText: wordLink) {
            let version: String? = Amphisbaena_WordLinksParserProvider.determineVersion(forText: wordLink)
            var resultContainer: Amphisbaena_WordLinksContainer?
            if version == Amphisbaena_WordLinksContainer.Version.v01.rawValue || version == nil {
                Swift.print("Importing a v01 word link container.")
                if let transkribusContainer = viewController.containerTranskribusTEI, let flexTextContainer = viewController.containerFlexText {
                    wordLinkParser.parse()
                    resultContainer = wordLinkParser.resultContainer
                    resultContainer = resultContainer?.convertContainerFrom01(withTranskribusContainer: transkribusContainer, withFLExFile: flexTextContainer)
                    viewController.containerWordLink = resultContainer
                }
                else {
                    wordLinkParser.parse()
                    viewController.containerWordLink = wordLinkParser.resultContainer
                }
            }
            else {
                Swift.print("Importing a v02 word link container.")
                if let transkribusContainer = viewController.containerTranskribusTEI,
                   let flexTextContainer = viewController.containerFlexText {
                    wordLinkParser.parse();
                    if let parser = wordLinkParser as? Amphisbaena_WordLinksParser_Format02 {
                        //Swift.print(transkribusContainer.getAll_w().count)
                        //Swift.print(flexTextContainer.getAll_Word().count)
                        //Swift.print(parser.modifierWordLinks )
                        let importModifier = Amphisbaena_WordLinksModifier(fromExistingWordLinks: parser.modifierWordLinks, transkribusContainer: transkribusContainer, flexContainer: flexTextContainer)
                        //Swift.print(importModifier.flexWords)
                        //Swift.print(importModifier.transkribusWords)
                        importModifier.setupNewContainer()
                        resultContainer = importModifier.resultContainer
                        //Swift.print(resultContainer?.version)
                        viewController.containerWordLink = resultContainer
                    }
                }
            }
        }
        
        if let transkribusTags = plistData[FileDictionaryKeys.transkribusTags] as? String {
            let tagsParser = Amphisbaena_TEITagParser(string: transkribusTags)
            viewController.containerTEITags = tagsParser?.resultContainer
        }
        
        viewController.fileLoaded_updateUI()
        
    }

    override func data(ofType typeName: String) throws -> Data {
        // Insert code here to write your document to data of the specified type, throwing an error in case of failure.
        // Alternatively, you could remove this method and override fileWrapper(ofType:), write(to:ofType:), or write(to:ofType:for:originalContentsURL:) instead.
        
        guard let windowController = primaryWindowController, let viewController = windowController.contentViewController as? ViewController else {throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)}
        
        var fileDictionary = [String : Any]()

        if let flexContainerContent = viewController.containerFlexText?.generateXML() {
            fileDictionary[FileDictionaryKeys.flexXML] = flexContainerContent
            Swift.print("Collected FlexText")
        }
        if let transkribusContainerContent = viewController.containerTranskribusTEI?.generateXML() {
            fileDictionary[FileDictionaryKeys.transkribusTEI] = transkribusContainerContent
            Swift.print("Collected Transkribus")
        }
        if let transkribusTagsContent = viewController.containerTEITags?.originalCSV {
            fileDictionary[FileDictionaryKeys.transkribusTags] = transkribusTagsContent
            Swift.print("Collected Transkribus Tags")
        }
        if let elanEAFContent = viewController.containerELAN?.generateXML() {
            fileDictionary[FileDictionaryKeys.elanEAF] = elanEAFContent
            Swift.print("Collected EAF")
        }
        if let wordLinksContent = viewController.containerWordLink?.generateXML() {
            fileDictionary[FileDictionaryKeys.wordLinks] = wordLinksContent
            Swift.print("Collected Word Links")
        }
        
        do {
            let data = try PropertyListSerialization.data(fromPropertyList: fileDictionary, format: .xml, options: 0)
            return data
        }
        catch {
            Swift.print(error)
            return Data()
        }
    }
    
    func loadPropertyList(fromData data: Data) -> Bool {
        var result = false
        do {
            if let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String : Any] {
                plistData = plist
                Swift.print("Plist data loaded.")
                result = true
            } else {
                Swift.print("Not a dictionary.")
            }
        } catch let error {
            Swift.print("Not a plist: ", error.localizedDescription)
        }
        return result
    }

    override func read(from data: Data, ofType typeName: String) throws {
        // Insert code here to read your document from the given data of the specified type, throwing an error in case of failure.
        // Alternatively, you could remove this method and override read(from:ofType:) instead.
        // If you do, you should also override isEntireFileLoaded to return false if the contents are lazily loaded.
        Swift.print("read(from data)")
        rawData = data
        if let rawData = rawData {
            let _ = loadPropertyList(fromData: rawData)
        }
        else {
            throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
        }
    }


}

