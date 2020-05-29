//
//  View_GenerateUnifiedFile.swift
//  Amphisbaena
//
//  Created by Casey on 4/6/20.
//  Copyright © 2020 Casey Fasthorse. All rights reserved.
//

import Cocoa

class View_GenerateUnifiedFile: NSView {
    @IBOutlet weak var imageView_image: NSImageView!
    @IBOutlet weak var label_headerLabel: NSTextField!
    @IBOutlet weak var label_descriptionLabel: NSTextField!
    @IBOutlet weak var label_requirements: NSTextField!
    @IBOutlet weak var imageView_status: NSImageView!
    @IBOutlet weak var label_status: NSTextField!
    @IBOutlet weak var button_synthesizeNew: NSButton!
    @IBOutlet weak var button_viewFile: NSButton!
    
    enum FileStatus: Int {
        case needFile = 0;
        case notSynth = 1;
        case successSynth = 2;
    }
    
    var closureCheckStatus: (() -> FileStatus)?
    var closureButton1: (() -> Void)?
    var closureButton2: (() -> Void)?
    
    struct StatusLabels {
        static let statusNeedFiles = "Required files are missing. Check File Management tab."
        static let statusNotSynthesized = "Required files are found. Synthesis ready."
        static let statusSuccessSynthesized = "File successfully synthesized."
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    func updateFileStatus() {
        var status = FileStatus.needFile;
        if let closureCheckStatus = closureCheckStatus {
            status = closureCheckStatus()
        }
        setFileStatus(status: status)
        if status == .needFile {
            button_viewFile.isEnabled = false;
            button_synthesizeNew.isEnabled = false;
        }
        else if status == .notSynth {
            button_viewFile.isEnabled = false;
            button_synthesizeNew.isEnabled = true;
        }
        else if status == .successSynth {
            button_viewFile.isEnabled = true;
            button_synthesizeNew.isEnabled = true;
        }
    }
    
    func setFileStatus(status: FileStatus) {
        switch status {
        case .needFile:
            label_status.stringValue = StatusLabels.statusNeedFiles;
            imageView_status.image = NSImage(named: NSImage.statusUnavailableName)
        case .notSynth:
            label_status.stringValue = StatusLabels.statusNotSynthesized;
            imageView_status.image = NSImage(named: NSImage.statusPartiallyAvailableName)
        case .successSynth:
            label_status.stringValue = StatusLabels.statusSuccessSynthesized;
            imageView_status.image = NSImage(named: NSImage.statusAvailableName)
        }
    }
    
    @IBAction func button_synthesizeNew_Action(_ sender: Any) {
        if let closureButton1 = closureButton1 {
            closureButton1()
        }
    }
    
    @IBAction func button_ViewFile_Action(_ sender: Any) {
        if let closureButton2 = closureButton2 {
            closureButton2()
        }
    }
    
}
