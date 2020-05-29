//
//  ViewController_UnifiedFiles.swift
//  Amphisbaena
//
//  Created by Casey on 4/6/20.
//  Copyright © 2020 Casey Fasthorse. All rights reserved.
//

import Cocoa

class ViewController_UnifiedFiles: NSViewController {
    
    weak var rootViewController: ViewController?
    var fileHandler: FileHandler = FileHandler();
    
    var rowHeight: CGFloat = 48.0;
    
    var fileRows: [FileSynthTypes : View_GenerateUnifiedFile]!
    
    enum FileSynthTypes: CaseIterable {
        case FullUnified
        case ElanOnly
        case UnifiedWithElan
    }
    
    convenience init(rootViewController: ViewController) {
        self.init();
        self.rootViewController = rootViewController;
    }
    
    struct ViewerTitles {
        static let transkribus = "Viewing XML for Transkribus TEI"
        static let flex = "Viewing XML for FLEx Export"
        static let elan = "Viewing XML for ELAN .eaf"
        static let wordLink = "Viewing XML for word links"
        static let unifiedFile = "Viewing XML for unified format created with Multiple Files"
        static let elanFile = "Viewing XML for unified format created with ELAN file"
    }
    
    struct ButtonTitles {
        static let viewXML = "View XML..."
        static let generate = "Generate..."
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    func setup() {
        fileRows = [:];
        
        self.view.translatesAutoresizingMaskIntoConstraints = false;
        
        addFileRow(fileLabel: "Synthesize with Multiple Files",
                   description: "Create a unified file with multiple separate files. Using data from Transkribus, FLEx, and a mapping of word links, you can generate a unified file for digital scans.",
                   requirements: "• Transkribus .tei file\n• FLEx .xml file\n• Amphisbaena word links .xml file\n• (optional) Transkribus tags .csv\n• (optional) ELAN .eaf for timestamp positioning",
                   image: NSImage(named: "FilestoUnify"),
                   type: .FullUnified,
                   previous: nil);
        
        if let row = fileRows[.FullUnified] {
            addFileRow(fileLabel: "Synthesize with ELAN",
                       description: "Create a unified file with an ELAN .eaf file. Best suited for videos or audio with subtitles.",
                       requirements: """
                                        • ELAN .eaf file
                                            • Annotations within the .eaf must be set up with a specific configuration
                                            • Each speaker must be associated with a capital letter, and have annotation names preceded by this letter
                                     """,
                       image: NSImage(named: "ELANtoUnify"),
                       type: .ElanOnly,
                       previous: row);
        }
        
        if let row = fileRows[.ElanOnly] {
            constrainViewToLastFileRow(lastRow: row)
        }
        
        setupUnifiedMultipleFiles()
        setupUnifiedELANFile()
        
    }
    
    func addFileRow(fileLabel: String, description: String, requirements: String, image: NSImage?, type: FileSynthTypes, previous: NSView?) {
        var topLevelObjects: NSArray?;
        let _ = Bundle.main.loadNibNamed("View_GenerateUnifiedFile", owner: self, topLevelObjects: &topLevelObjects);
        if let topLevelObjects = topLevelObjects {
            let views = (topLevelObjects as Array).filter { $0 is NSView }
            let newView = views[0] as! View_GenerateUnifiedFile;
            
            newView.label_headerLabel.stringValue = fileLabel;
            newView.label_descriptionLabel.stringValue = description;
            newView.label_requirements.stringValue = requirements;
            newView.imageView_image.image = image
            
            newView.frame = self.view.bounds;
            
            self.view.addSubview(newView);
            
            setupFileRowFrame(view: newView, superview: self.view, placeUnder: previous)

            fileRows[type] = newView;
        }
    }
    
    func setupFileRowFrame(view: NSView, superview: NSView, placeUnder viewOver: NSView?) {
        view.translatesAutoresizingMaskIntoConstraints = false;
        view.frame = NSRect(x: 0.0, y: 0.0, width: superview.bounds.width, height: rowHeight)
        view.leftAnchor.constraint(equalTo: superview.leftAnchor, constant: 0.0).isActive = true;
        view.rightAnchor.constraint(equalTo: superview.rightAnchor, constant: 0.0).isActive = true;
        if (viewOver == nil) {
            view.topAnchor.constraint(equalTo: superview.topAnchor).isActive = true;
        }
        else if let viewOver = viewOver {
            view.topAnchor.constraint(equalTo: viewOver.bottomAnchor).isActive = true;
        }
    }
    
    func constrainViewToLastFileRow(lastRow: NSView) {
        self.view.bottomAnchor.constraint(equalTo: lastRow.bottomAnchor).isActive = true;
    }
    
    
    func setupUnifiedMultipleFiles() {
        guard let row = fileRows[.FullUnified] else {return}
        let closure1 = {() -> Void in
            guard let rootController = self.rootViewController else {return;}
            if let transkribusContainer = rootController.containerTranskribusTEI,
                let flexContainer = rootController.containerFlexText,
                let wordlinkContainer = rootController.containerWordLink {
                let unifiedContainer: Amphisbaena_UnifiedContainer = Amphisbaena_UnifiedContainer(transkribusContainer: transkribusContainer, flexContainer: flexContainer, wordlinkContainer: wordlinkContainer, TEITagsContainer: rootController.containerTEITags, elanContainer: rootController.containerELAN)
                self.rootViewController?.container_Unified_FromTranskribusFLEx = unifiedContainer;
                if let row = self.fileRows[.FullUnified] {
                    row.updateFileStatus();
                }
            }
        }
        let closureCheck = {() -> View_GenerateUnifiedFile.FileStatus in
            print("Unified closure check.")
            guard let rootController = self.rootViewController else {return .needFile}
            guard rootController.containerTranskribusTEI != nil,
                rootController.containerFlexText != nil,
                rootController.containerWordLink != nil else {return .needFile}
            if rootController.container_Unified_FromTranskribusFLEx == nil {
                return .notSynth}
            else {return .successSynth}
        }
        
        let closure2 = {() -> Void in
            if let unifiedFile = self.rootViewController?.container_Unified_FromTranskribusFLEx {
                self.viewXML(withXML: unifiedFile.generateXML(), title: ViewerTitles.unifiedFile)
            }
        }
        
        row.closureButton1 = closure1;
        row.closureButton2 = closure2;
        row.closureCheckStatus = closureCheck;
    }
    
    
    func setupUnifiedELANFile() {
        guard let row = fileRows[.ElanOnly] else {return}
        let closure1 = {() -> Void in
            guard let rootController = self.rootViewController else {return;}
            if let elanContainer = rootController.containerELAN {
                let unifiedContainer = Amphisbaena_UnifiedContainer(unifiedFromElanContainer: elanContainer)
                self.rootViewController?.container_Unified_FromElan = unifiedContainer;
                if let row = self.fileRows[.ElanOnly] {
                    row.updateFileStatus();
                }
            }
        }
        let closureCheck = {() -> View_GenerateUnifiedFile.FileStatus in
            guard let rootController = self.rootViewController else {return .needFile}
            guard rootController.containerELAN != nil else {return .needFile}
            if rootController.container_Unified_FromElan == nil {
                return .notSynth}
            else {return .successSynth}
        }
        
        let closure2 = {() -> Void in
            if let unifiedFile = self.rootViewController?.container_Unified_FromElan {
                self.viewXML(withXML: unifiedFile.generateXML(), title: ViewerTitles.elanFile)
            }
        }
        
        row.closureButton1 = closure1;
        row.closureButton2 = closure2;
        row.closureCheckStatus = closureCheck;
    }
    
    func viewXML(withXML string: String, title: String) {
        if let XMLViewerVC = rootViewController?.getXMLViewerVC() {
            XMLViewerVC.boxLabel = title
            XMLViewerVC.displayingXML = string
            self.rootViewController?.presentAsSheet(XMLViewerVC);
        }
    }
    
    override func viewDidAppear() {
        updateFileStatuses()
    }
    
    func updateFileStatuses() {
        for (_, row) in fileRows {
            row.updateFileStatus();
        }
    }
    
}
