//
//  ViewController.swift
//  Amphisbaena
//
//  Created by Casey on 2/16/20.
//  Copyright © 2020 Casey Fasthorse. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    //TAB 2 - INGEST FILES
    @IBOutlet weak var view_tab2_ingestFilesFrame: NSView!
    @IBOutlet weak var checkbox_tab2_autoViewXML: NSButton!
    
    //TAB 3 - SYNTHESIZE FILES
    @IBOutlet weak var view_tab3_synthesizeFile: NSView!
    
    var ingestViewController: ViewController_IngestFileManager?
    var synthesisViewController: ViewController_UnifiedFiles?
    
    var fileHandler: FileHandler = FileHandler();
    
    /*NEW CONTAINERS*/
    var containerTranskribusTEI: Amphisbaena_TranskribusTEIContainer?
    var containerFlexText: Amphisbaena_FlexTextContainer?
    var containerWordLink: Amphisbaena_WordLinksContainer?
    var containerELAN: Amphisbaena_ELANContainer?
    var containerTEITags: Amphisbaena_TEITagContainer?
    
    var container_Unified_FromTranskribusFLEx: Amphisbaena_UnifiedContainer?
    var container_Unified_FromElan: Amphisbaena_UnifiedContainer?
    
    /*OLD CONTAINERS*/
    
    //VIEW CONTROLLERS
    private var vcXMLViewer: ViewController_XMLViewer?
    
    func fileLoaded_updateUI() {
        if let ingestVC = ingestViewController {
            ingestVC.updateAllFileRows()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        ingestViewController = ViewController_IngestFileManager(rootViewController: self);
        if let ingestViewController = ingestViewController {
            self.addChild(ingestViewController)
            ingestViewController.rootViewController = self;
            view_tab2_ingestFilesFrame.addSubview(ingestViewController.view)
            
            ingestViewController.view.translatesAutoresizingMaskIntoConstraints = false;
            ingestViewController.view.topAnchor.constraint(equalTo: view_tab2_ingestFilesFrame.topAnchor, constant: 0.0).isActive = true;
            ingestViewController.view.leftAnchor.constraint(equalTo: view_tab2_ingestFilesFrame.leftAnchor, constant: 0.0).isActive = true;
            ingestViewController.view.rightAnchor.constraint(equalTo: view_tab2_ingestFilesFrame.rightAnchor, constant: 0.0).isActive = true;
            ingestViewController.view.bottomAnchor.constraint(equalTo: view_tab2_ingestFilesFrame.bottomAnchor, constant: 0.0).isActive = true;
            ingestViewController.setup();
        }
        
        synthesisViewController = ViewController_UnifiedFiles(rootViewController: self)
        if let synthesisViewController = synthesisViewController {
            self.addChild(synthesisViewController)
            view_tab3_synthesizeFile.addSubview(synthesisViewController.view)
            
            synthesisViewController.view.translatesAutoresizingMaskIntoConstraints = false;
            synthesisViewController.view.topAnchor.constraint(equalTo: view_tab3_synthesizeFile.topAnchor, constant: 0.0).isActive = true;
            synthesisViewController.view.leftAnchor.constraint(equalTo: view_tab3_synthesizeFile.leftAnchor, constant: 0.0).isActive = true;
            synthesisViewController.view.rightAnchor.constraint(equalTo: view_tab3_synthesizeFile.rightAnchor, constant: 0.0).isActive = true;
            synthesisViewController.view.bottomAnchor.constraint(equalTo: view_tab3_synthesizeFile.bottomAnchor, constant: 0.0).isActive = true;
            synthesisViewController.setup();
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func openFile() -> URL? {
        return fileHandler.openDialog()
    }
    
    func openFileCSV() -> URL? {
        return fileHandler.openDialogCSV()
    }
    
    func getXMLViewerVC() -> ViewController_XMLViewer? {
        if vcXMLViewer == nil {
            vcXMLViewer = NSStoryboard.main?.instantiateController(withIdentifier: "XMLViewer") as? ViewController_XMLViewer
        }
        if let vcXMLViewer = vcXMLViewer {
            return vcXMLViewer;
        }
        return nil;
    }
}
