//
//  ViewController_IngestFileManager.swift
//  Amphisbaena
//
//  Created by Casey on 3/23/20.
//  Copyright © 2020 Casey Fasthorse. All rights reserved.
//
import Foundation
import Cocoa

class ViewController_IngestFileManager: NSViewController {
    
    weak var rootViewController: ViewController?
    var fileHandler: FileHandler = FileHandler();
    
    var rowHeight: CGFloat = 48.0;
    
    var fileRows: [FileIngestTypes : View_IngestFileManager_File]!
    
    enum FileIngestTypes: CaseIterable {
        case FLExXML
        case TranskribusTEIXML
        case WordLinksXML
        case PhraseCSV
        case TranskribusTagsCSV
        case ELANEAF
    }
    
    convenience init(rootViewController: ViewController) {
        self.init();
        self.rootViewController = rootViewController;
    }
    
    var windowGenerateWordLinks: NSWindowController?
    
    func updateAllFileRows() {
        
        for (ingestType, rowView) in fileRows {
            var container: Amphisbaena_Container?
            switch ingestType {
            case .TranskribusTEIXML:
                container = rootViewController?.containerTranskribusTEI
            case .FLExXML:
                container = rootViewController?.containerFlexText
            case .ELANEAF:
                container = rootViewController?.containerELAN
            case .WordLinksXML:
                container = rootViewController?.containerWordLink
            case .TranskribusTagsCSV:
                container = rootViewController?.containerTEITags
            default:
                break;
            }
            
            if container != nil {
                rowView.setStatus_FileLoadSuccessful()
                self.setFileRow_ButtonEnable(forType: ingestType, button2Enable: true)
            }
            else {
                rowView.setStatus_NoFileLoaded()
                self.setFileRow_ButtonEnable(forType: ingestType, button2Enable: false)
            }
        }
        
        self.enableGenerateWordLinksIfFilesPresent()
    }
    
    func showGenerateWordLinksWindow() {
        if rootViewController?.containerWordLink?.version != .v02 && rootViewController?.containerWordLink != nil {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.icon = NSImage(named: NSImage.cautionName)
            alert.messageText = "You cannot edit Word Links files created with an older version of Amphisbaena."
            alert.informativeText = """
            If you have the original Transkribus TEI file and FLExText file for this Word Links file, you can convert this file to the newer version.
            
            To do this, import the Transkribus TEI file and the FLExText file. Then, attempt to import this Word Links file. Finally, click "Convert" to create a new, editable Word Links file.
            """
            alert.addButton(withTitle: "OK")
            alert.beginSheetModal(for: self.view.window!)
        }
        else if rootViewController?.containerTranskribusTEI == nil || rootViewController?.containerFlexText == nil {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.icon = NSImage(named: NSImage.cautionName)
            alert.messageText = "You cannot edit Word Links because a Transkribus TEI file or a FLExText file was not imported or is missing."
            alert.informativeText = """
            If you wish to edit this Word Links file, import both the Transkribus TEI file and a FLExText file which accompany this Word Links file, and try again.
            
            Old versions of Amphisbaena permitted you to edit Word Links while missing one or both of these files. Newer versions require these files to ensure data integrity.
            """
            alert.addButton(withTitle: "OK")
            alert.beginSheetModal(for: self.view.window!)
        }
        else {
            presentWordLinkWindow()
        }
        
        
    }
    
    private func presentWordLinkWindow() {
        if windowGenerateWordLinks == nil {
            let window = NSWindow()
            window.styleMask = [.titled, .resizable]
            window.backingType = .buffered
            window.animationBehavior = .alertPanel
            window.title = "Word Links Editor"
            
            
            let newVC = NSStoryboard.main?.instantiateController(withIdentifier: "WordLinksEditor") as? ViewController_WordLinksEditor
            newVC?.wordLinkEditorDelegate = self;
            
            window.contentViewController = newVC
            
            let windowController = NSWindowController()
            windowController.contentViewController = window.contentViewController
            windowController.window = window
            windowGenerateWordLinks = windowController;
        }
        if let window = windowGenerateWordLinks?.window {
            self.view.window?.addChildWindow(window, ordered: .above)
        }
        if let wordLinkEditorVC = windowGenerateWordLinks?.window?.contentViewController as? ViewController_WordLinksEditor {
            
            if let containerTranskribus = rootViewController?.containerTranskribusTEI {
                wordLinkEditorVC.containerTranskribus = containerTranskribus
            }
            
            if let containerFLEx = rootViewController?.containerFlexText {
                wordLinkEditorVC.containerFLEx = containerFLEx
            }
            
            if let containerWordLinks = rootViewController?.containerWordLink {
                wordLinkEditorVC.containerWordLinks = containerWordLinks
            }
            
            
            wordLinkEditorVC.setup();
        }
        windowGenerateWordLinks?.showWindow(self)
    }
    
    
    func readOption_checkboxOpenXMLOnImport() -> Bool {
        if let rootViewController = rootViewController {
            return rootViewController.checkbox_tab2_autoViewXML.state == .on ? true : false;
        }
        else {return false;}
    }
    
    struct ViewerTitles {
        static let transkribus = "Viewing XML for Transkribus TEI"
        static let flex = "Viewing XML for FLEx Export"
        static let elan = "Viewing XML for ELAN .eaf"
        static let wordLink = "Viewing XML for word links"
        static let teiTags = "Viewing XML for Transkribus TEI Tags"
    }
    
    struct ButtonTitles {
        static let viewXML = "View XML..."
        static let edit = "Edit..."
        static let generate = "Generate..."
    }
    
    func addFileRow(fileLabel: String, type: FileIngestTypes, previous: NSView?) {
        var topLevelObjects: NSArray?;
        let _ = Bundle.main.loadNibNamed("View_IngestFileManager_FileRow", owner: self, topLevelObjects: &topLevelObjects);
        if let topLevelObjects = topLevelObjects {
            let views = (topLevelObjects as Array).filter { $0 is NSView }
            let newView = views[0] as! View_IngestFileManager_File;
            
            newView.labelFileTypeName.stringValue = fileLabel;
            
            newView.frame = self.view.bounds;
            
            self.view.addSubview(newView);
            
            setupFileRowFrame(view: newView, superview: self.view, placeUnder: previous)

            fileRows[type] = newView;
        }
    }
    
    func enableGenerateWordLinksIfFilesPresent() {
        if let _ = rootViewController?.containerWordLink {setFileRow_ButtonEnable(forType: .WordLinksXML, button3Enable: true);}
        else {
            guard let rootViewController = self.rootViewController,
                let _ = rootViewController.containerTranskribusTEI,
                let _ = rootViewController.containerFlexText,
                let _ = fileRows[.WordLinksXML] else {
                    setFileRow_ButtonEnable(forType: .WordLinksXML, button3Enable: false)
                    return;
            }
            setFileRow_ButtonEnable(forType: .WordLinksXML, button3Enable: true)
        }
    }
    
    func setup() {
        fileRows = [:];
        
        self.view.translatesAutoresizingMaskIntoConstraints = false;
        
        addFileRow(fileLabel: "FLEx XML:", type: .FLExXML, previous: nil);
        setFileRow_ButtonVisibility(forType: .FLExXML, button2Visible: true, button3Visible: false)
        setFileRow_ButtonLabels(forType: .FLExXML, button2Label: ButtonTitles.viewXML)
        setFileRow_ButtonEnable(forType: .FLExXML, button2Enable: false, button3Enable: false)
        fileRows[.FLExXML]?.setStatus_NoFileLoaded();
        
        if let row = fileRows[.FLExXML] {
            addFileRow(fileLabel: "Transkribus TEI XML:", type: .TranskribusTEIXML, previous: row);
            setFileRow_ButtonVisibility(forType: .TranskribusTEIXML, button2Visible: true, button3Visible: false)
            setFileRow_ButtonLabels(forType: .TranskribusTEIXML, button2Label: ButtonTitles.viewXML)
            setFileRow_ButtonEnable(forType: .TranskribusTEIXML, button2Enable: false, button3Enable: false)
            fileRows[.TranskribusTEIXML]?.setStatus_NoFileLoaded();
        }
        
        if let row = fileRows[.TranskribusTEIXML] {
            addFileRow(fileLabel: "Transkribus Tags CSV:", type: .TranskribusTagsCSV, previous: row);
            setFileRow_ButtonVisibility(forType: .TranskribusTagsCSV, button2Visible: true, button3Visible: false)
            setFileRow_ButtonLabels(forType: .TranskribusTagsCSV, button2Label: ButtonTitles.viewXML)
            setFileRow_ButtonEnable(forType: .TranskribusTagsCSV, button2Enable: false, button3Enable: false)
            fileRows[.TranskribusTagsCSV]?.setStatus_NoFileLoaded();
        }
        
        if let row = fileRows[.TranskribusTagsCSV] {
            addFileRow(fileLabel: "ELAN .eaf file:", type: .ELANEAF, previous: row)
            setFileRow_ButtonVisibility(forType: .ELANEAF, button2Visible: true, button3Visible: false)
            setFileRow_ButtonLabels(forType: .ELANEAF, button2Label: ButtonTitles.viewXML)
            setFileRow_ButtonEnable(forType: .ELANEAF, button2Enable: false, button3Enable: false)
            fileRows[.ELANEAF]?.setStatus_NoFileLoaded();
        }
        
        if let row = fileRows[.ELANEAF] {
            addFileRow(fileLabel: "Transkribus/FLEx Word Linking:", type: .WordLinksXML, previous: row)
            setFileRow_ButtonVisibility(forType: .WordLinksXML, button2Visible: true, button3Visible: true)
            setFileRow_ButtonLabels(forType: .WordLinksXML, button2Label: ButtonTitles.viewXML, button3Label: ButtonTitles.edit)
            setFileRow_ButtonEnable(forType: .WordLinksXML, button2Enable: false, button3Enable: false)
            fileRows[.WordLinksXML]?.setStatus_NoFileLoaded();
        }
        
        constrainViewToLastFileRow()
        
        setup_FLExImportButton();
        setup_TranskribusImportButton();
        setup_TranskribusTagsImport()
        setup_ELANImportButton();
        setup_WordLinkImportButton()
    }
    
    func viewXML(withXML string: String, title: String) {
        if let XMLViewerVC = rootViewController?.getXMLViewerVC() {
            XMLViewerVC.boxLabel = title
            XMLViewerVC.displayingXML = string
            self.rootViewController?.presentAsSheet(XMLViewerVC);
        }
    }
    
    func setup_FLExImportButton() {
        guard let fileRow = fileRows[.FLExXML] else {return;}
        let action = {() -> Void in
            let url = self.fileHandler.openDialog();
            if let url = url {
                print("Open file successful.")
                do {
                    let fileContents = try String(contentsOf: url, encoding: .utf8)
                    let parser = Amphisbaena_FlexTextParser(XMLString: fileContents)
                    //let parser = Amphisbaena_FLExParser(XMLString: fileContents)
                    if let parser = parser {
                        parser.parse()
                        self.rootViewController?.containerFlexText = parser.resultContainer
                        fileRow.setStatus_FileLoadSuccessful()
                        self.setFileRow_ButtonEnable(forType: .FLExXML, button2Enable: true)
                        
                        self.enableGenerateWordLinksIfFilesPresent()
                        
                        if self.readOption_checkboxOpenXMLOnImport(),
                            let containerFLEx = self.rootViewController?.containerFlexText {
                            
                            //let phrasesByGuid = containerFLEx.getAll_Word().compactMap{$0.getAttribute(attributeName: "guid") ?? "PUNCT"}
                            //print(phrasesByGuid)
                            
                            self.viewXML(withXML: containerFLEx.generateXML(), title: ViewerTitles.flex)
                            
                            
                        }
                    }
                }
                catch {
                    print("Not successful.")
                }
            }
        }
        fileRow.importActionClosure = action;
        
        let button2action = {() -> Void in
            if let containerFLEx = self.rootViewController?.containerFlexText {
                self.viewXML(withXML: containerFLEx.generateXML(), title: ViewerTitles.flex)
            }
        }
        fileRow.button2ActionClosure = button2action;
        
        let trashAction = {() -> Void in
            self.rootViewController?.containerFlexText = nil
            fileRow.setStatus_NoFileLoaded()
            self.setFileRow_ButtonEnable(forType: .FLExXML, button2Enable: false)
            self.enableGenerateWordLinksIfFilesPresent()
        }
        fileRow.trashActionClosure = trashAction
    }
    
    func setup_TranskribusImportButton() {
        guard let fileRow = fileRows[.TranskribusTEIXML] else {return;}
        let action = {() -> Void in
            let url = self.fileHandler.openDialog();
            if let url = url {
                print("Open file successful.")
                do {
                    let fileContents = try String(contentsOf: url, encoding: .utf8)
                    //let parser = Amphisbaena_TranskribusParser(XMLString: fileContents)
                    let parser = Amphisbaena_TranskribusTEIParser(XMLString: fileContents)
                    if let parser = parser {
                        parser.parse()
                        self.rootViewController?.containerTranskribusTEI = parser.resultContainer
                        fileRow.setStatus_FileLoadSuccessful()
                        self.setFileRow_ButtonEnable(forType: .TranskribusTEIXML, button2Enable: true)
                        
                        self.enableGenerateWordLinksIfFilesPresent()
                        
                        if self.readOption_checkboxOpenXMLOnImport(),
                            let containerTranskribus = self.rootViewController?.containerTranskribusTEI {
                            
                            let words = containerTranskribus.getAll_w().compactMap{$0.elementContent ?? "NESTED"
                            }
                            print(words)
                            print(words.count)
                            
                            self.viewXML(withXML: containerTranskribus.generateXML(), title: ViewerTitles.transkribus)
                            
                            
                        }
                    }
                }
                catch {
                    print("Not successful.")
                }
            }
        }
        fileRow.importActionClosure = action;
        
        let button2action = {() -> Void in
            if let containerTranskribus = self.rootViewController?.containerTranskribusTEI {
                self.viewXML(withXML: containerTranskribus.generateXML(), title: ViewerTitles.transkribus)
            }
        }
        fileRow.button2ActionClosure = button2action;
        
        let trashAction = {() -> Void in
            self.rootViewController?.containerTranskribusTEI = nil
            fileRow.setStatus_NoFileLoaded()
            self.setFileRow_ButtonEnable(forType: .TranskribusTEIXML, button2Enable: false)
            self.enableGenerateWordLinksIfFilesPresent()
        }
        fileRow.trashActionClosure = trashAction
    }
    
    func setup_TranskribusTagsImport() {
        guard let fileRow = fileRows[.TranskribusTagsCSV] else {return;}
        let action = {() -> Void in
            let url = self.fileHandler.openDialog(withTitle: "Open a CSV file.", ofTypes: ["csv","txt"])
            if let url = url {
                print("Open file successful.")
                let parser = Amphisbaena_TEITagParser(csvFile: url)
                if let parser = parser {
                    self.rootViewController?.containerTEITags = parser.resultContainer
                    fileRow.setStatus_FileLoadSuccessful()
                    self.setFileRow_ButtonEnable(forType: .TranskribusTagsCSV, button2Enable: true)
                    
                    if self.readOption_checkboxOpenXMLOnImport(),
                        let containerTags = self.rootViewController?.containerTEITags {
                        
                        self.viewXML(withXML: containerTags.generateXML(), title: ViewerTitles.teiTags)
                        
                        
                    }
                }
            }
        }
        fileRow.importActionClosure = action;
        
        let button2action = {() -> Void in
            if let containerTeiTags = self.rootViewController?.containerTEITags {
                self.viewXML(withXML: containerTeiTags.generateXML(), title: ViewerTitles.teiTags)
            }
        }
        fileRow.button2ActionClosure = button2action;
        
        let trashAction = {() -> Void in
            self.rootViewController?.containerTEITags = nil
            self.setFileRow_ButtonEnable(forType: .TranskribusTagsCSV, button2Enable: false)
            fileRow.setStatus_NoFileLoaded()
        }
        fileRow.trashActionClosure = trashAction
    }
    
    func setup_ELANImportButton() {
        guard let fileRow = fileRows[.ELANEAF] else {return;}
        let action = {() -> Void in
            let url = self.fileHandler.openDialog(withTitle: "Open .eaf file.", ofTypes: ["eaf","xml","txt"])
            if let url = url {
                print("Open file successful.")
                do {
                    let fileContents = try String(contentsOf: url, encoding: .utf8)
                    let parser = Amphisbaena_ELANParser(XMLString: fileContents)
                    if let parser = parser {
                        parser.parse();
                        if let container = parser.resultContainer {
                            self.rootViewController?.containerELAN = container;
                            fileRow.setStatus_FileLoadSuccessful()
                            self.setFileRow_ButtonEnable(forType: .ELANEAF, button2Enable: true)
                            
                            if self.readOption_checkboxOpenXMLOnImport() {
                                self.viewXML(withXML: container.generateXML(), title: ViewerTitles.elan)
                            }
                        }
                    }
                }
                catch {
                    print("Not successful.")
                }
            }
        }
        fileRow.importActionClosure = action;
        
        let button2action = {() -> Void in
            
            if let containerELAN = self.rootViewController?.containerELAN {
                self.viewXML(withXML: containerELAN.generateXML(), title: ViewerTitles.elan)
            }
        }
        fileRow.button2ActionClosure = button2action;
        
        let trashAction = {() -> Void in
            self.rootViewController?.containerELAN = nil
            fileRow.setStatus_NoFileLoaded()
            self.setFileRow_ButtonEnable(forType: .ELANEAF, button2Enable: false)
        }
        fileRow.trashActionClosure = trashAction
    }
    
    func setup_WordLinkImportButton() {
        guard let fileRow = fileRows[.WordLinksXML] else {return;}
        let action = {() -> Void in
            let url = self.fileHandler.openDialog();
            if let url = url {
                print("Open file successful.")
                do {
                    let fileContents = try String(contentsOf: url, encoding: .utf8)
                    let version: String? = Amphisbaena_WordLinksParserProvider.determineVersion(forText: fileContents)
                    let parser = Amphisbaena_WordLinksParserProvider.getParser(forText: fileContents)
                    var resultContainer: Amphisbaena_WordLinksContainer?
                    if version != Amphisbaena_WordLinksContainer.Version.v02.rawValue {
                        /*
                        print(self.rootViewController?.containerTranskribusTEI)
                        print(self.rootViewController?.containerFlexText);
                        print(version)
                        */
                        if version == Amphisbaena_WordLinksContainer.Version.v01.rawValue || version == nil,
                            let transkribusContainer = self.rootViewController?.containerTranskribusTEI,
                            let flexContainer = self.rootViewController?.containerFlexText {
                            let alert = NSAlert()
                            alert.alertStyle = .warning
                            alert.icon = NSImage(named: NSImage.infoName)
                            alert.messageText = "This Word Links file was created with an older version of Amphisbaena. You can convert this file to the current version."
                            alert.informativeText = """
                            A Transkribus TEI file and a FLEx flextext file were found and will be used to aid in conversion. Do you want to convert your file?
                            
                            Note that if you do not convert your file, it will be incompatible with other functionality in Amphisbaena.
                            """
                            alert.addButton(withTitle: "Convert")
                            alert.addButton(withTitle: "Import")
                            alert.addButton(withTitle: "Cancel")
                            alert.beginSheetModal(for: self.view.window!) { (response) in
                                if response == .alertFirstButtonReturn {
                                    parser?.parse();
                                    resultContainer = parser?.resultContainer
                                    if resultContainer?.version == .v01 {
                                        resultContainer = resultContainer?.convertContainerFrom01(withTranskribusContainer: transkribusContainer, withFLExFile: flexContainer)
                                        print(resultContainer?.version)
                                        self.populateWordLinks(withContainer: resultContainer, fileRow: fileRow)
                                    }
                                }
                                else if response == .alertSecondButtonReturn {
                                    parser?.parse();
                                    resultContainer = parser?.resultContainer
                                    print(resultContainer?.version)
                                    self.populateWordLinks(withContainer: resultContainer, fileRow: fileRow)
                                }
                            }
                        }
                        else {
                            let alert = NSAlert()
                            alert.alertStyle = .warning
                            alert.icon = NSImage(named: NSImage.cautionName)
                            alert.messageText = "This Word Links file was created with an older version of Amphisbaena. Do you want to import this file anyway?"
                            alert.informativeText = """
                            If you have a Transkribus TEI file and a FLEx flextext file that go together with this Word Links file, you can convert this file to the new version. However, these files were not found. Import them first and try again if you want to try converting this Word Links file.
                            """
                            alert.addButton(withTitle: "Yes")
                            alert.addButton(withTitle: "No")
                            alert.beginSheetModal(for: self.view.window!) { (response) in
                                if response == .alertFirstButtonReturn {
                                    parser?.parse();
                                    resultContainer = parser?.resultContainer
                                    print(resultContainer?.version)
                                    self.populateWordLinks(withContainer: resultContainer, fileRow: fileRow)
                                }
                            }
                        }
                    }
                    else {
                        print("File is a v02 file")
                        if let transkribusContainer = self.rootViewController?.containerTranskribusTEI,
                            let flexContainer = self.rootViewController?.containerFlexText {
                            parser?.parse();
                            if let parser = parser as? Amphisbaena_WordLinksParser_Format02 {
                                let importModifier = Amphisbaena_WordLinksModifier(fromExistingWordLinks: parser.modifierWordLinks, transkribusContainer: transkribusContainer, flexContainer: flexContainer)
                                importModifier.setupNewContainer()
                                resultContainer = importModifier.resultContainer
                                print(resultContainer?.version)
                                self.populateWordLinks(withContainer: resultContainer, fileRow: fileRow)
                            }
                        }
                        else {
                            let alert = NSAlert()
                            alert.alertStyle = .warning
                            alert.icon = NSImage(named: NSImage.infoName)
                            alert.messageText = "This is a Word Links file that has been created with the current version of Amphisbaena. This file requires that you import both a Transkribus and a FLEx file to accompany it."
                            alert.informativeText = """
                            Please import the Transkribus TEI file and FLEx flextext file that accompanies this Word Links file, and try again.
                            
                            Old versions of Amphisbaena allowed you to import a Word Links file without an accompanying Transkribus TEI or FLEx flextext file. Word Links now require these files to be present before you can import them.
                            """
                            alert.addButton(withTitle: "OK")
                            alert.beginSheetModal(for: self.view.window!)
                        }
                    }
                }
                catch {
                    print("Not successful.")
                }
            }
        }
        fileRow.importActionClosure = action;
        
        let button2action = {() -> Void in
            
            if let containerWordLinks = self.rootViewController?.containerWordLink {
                self.viewXML(withXML: containerWordLinks.generateXML(), title: ViewerTitles.wordLink)
            }
        }
        fileRow.button2ActionClosure = button2action;
        
        let button3action = {() -> Void in
            self.showGenerateWordLinksWindow()
        }
        fileRow.button3ActionClosure = button3action
        
        let trashAction = {() -> Void in
            self.rootViewController?.containerWordLink = nil
            fileRow.setStatus_NoFileLoaded()
            self.setFileRow_ButtonEnable(forType: .WordLinksXML, button2Enable: false)
            self.setFileRow_ButtonEnable(forType: .WordLinksXML, button3Enable: false)
            self.enableGenerateWordLinksIfFilesPresent()
            
            if let windowGenerateWordLinks = self.windowGenerateWordLinks,
                let vc = windowGenerateWordLinks.contentViewController as? ViewController_WordLinksEditor {
                vc.clearWordLinks()
            }
        }
        fileRow.trashActionClosure = trashAction
    }
    
    private func populateWordLinks(withContainer resultContainer: Amphisbaena_WordLinksContainer?, fileRow: View_IngestFileManager_File) {
        if let container = resultContainer {
            rootViewController?.containerWordLink = container;
            enableGenerateWordLinksIfFilesPresent()
            fileRow.setStatus_FileLoadSuccessful()
            setFileRow_ButtonEnable(forType: .WordLinksXML, button2Enable: true)
            
            if readOption_checkboxOpenXMLOnImport() {
                viewXML(withXML: container.generateXML(), title: ViewerTitles.wordLink)
            }
        }
    }
    
    func setFileRow_ButtonVisibility(forType type: FileIngestTypes, button2Visible visible2: Bool, button3Visible visible3: Bool) {
        if let row = fileRows[type] {
            row.button_Button2.isHidden = !visible2;
            row.button_Button3.isHidden = !visible3;
        }
    }
    
    func setFileRow_ButtonLabels(forType type: FileIngestTypes, button2Label label2: String, button3Label label3: String = "") {
        if let row = fileRows[type] {
            row.button_Button2.title = label2;
            row.button_Button3.title = label3;
        }
    }
    
    func setFileRow_ButtonEnable(forType type: FileIngestTypes, button2Enable enable2: Bool, button3Enable enable3: Bool) {
        if let row = fileRows[type] {
            row.button_Button2.isEnabled = enable2
            row.button_Button3.isEnabled = enable3
        }
    }
    
    func setFileRow_ButtonEnable(forType type: FileIngestTypes, button2Enable enable2: Bool) {
        if let row = fileRows[type] {
            row.button_Button2.isEnabled = enable2
        }
    }
    
    func setFileRow_ButtonEnable(forType type: FileIngestTypes, button3Enable enable3: Bool) {
        if let row = fileRows[type] {
            row.button_Button3.isEnabled = enable3
        }
    }
    
    func setupFileRowFrame(view: NSView, superview: NSView, placeUnder viewOver: NSView?) {
        view.translatesAutoresizingMaskIntoConstraints = false;
        view.frame = NSRect(x: 0.0, y: 0.0, width: superview.bounds.width, height: rowHeight)
        view.heightAnchor.constraint(equalToConstant: 48.0).isActive = true;
        view.leftAnchor.constraint(equalTo: superview.leftAnchor, constant: 0.0).isActive = true;
        view.rightAnchor.constraint(equalTo: superview.rightAnchor, constant: 0.0).isActive = true;
        if (viewOver == nil) {
            view.topAnchor.constraint(equalTo: superview.topAnchor).isActive = true;
        }
        else if let viewOver = viewOver {
            view.topAnchor.constraint(equalTo: viewOver.bottomAnchor).isActive = true;
        }
    }
    
    func constrainViewToLastFileRow() {
        let height = CGFloat(fileRows.count) * rowHeight
        self.view.frame.size.height = height
        self.view.heightAnchor.constraint(equalToConstant: height).isActive = true;
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}

extension ViewController_IngestFileManager: ViewController_WordLinksEditor_Delegate {
    
    func receiveFinalWordLinkObject(finalObject: Amphisbaena_WordLinksContainer) {
        if let rootViewController = rootViewController {
            rootViewController.containerWordLink = finalObject;
            if let row = fileRows[.WordLinksXML] {
                row.setStatus_FileLoadSuccessful()
                row.button_Button2.isEnabled = true;
            }
            
        }
    }
    
    func showWordLinkXML(withXML XML: String) {
        self.viewXML(withXML: XML, title: "View Word Links XML")
    }
}
