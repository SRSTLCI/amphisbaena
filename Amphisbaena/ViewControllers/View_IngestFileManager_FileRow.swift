//
//  View_IngestFileManager_File.swift
//  Amphisbaena
//
//  Created by Casey on 3/23/20.
//  Copyright © 2020 Casey Fasthorse. All rights reserved.
//

import Cocoa

class View_IngestFileManager_File: NSView {
    
    @IBOutlet weak var labelFileTypeName: NSTextField!
    @IBOutlet weak var button_Trash: NSButton!
    @IBOutlet weak var button_Import: NSButton!
    @IBOutlet weak var button_Button2: NSButton!
    @IBOutlet weak var button_Button3: NSButton!
    
    @IBOutlet weak var image_status: NSImageView!
    @IBOutlet weak var label_status: NSTextField!
    
    var trashActionClosure: (() -> Void)?
    var importActionClosure: (() -> Void)?
    var button2ActionClosure: (() -> Void)?
    var button3ActionClosure: (() -> Void)?
    
    struct StatusLabels {
        static let statusNotLoaded = "No file loaded."
        static let statusSuccessfulLoad = "File successfully loaded."
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    func setStatus_NoFileLoaded() {
        self.label_status.stringValue = StatusLabels.statusNotLoaded;
        self.image_status.image = NSImage(named: NSImage.statusUnavailableName);
        self.button_Trash.isEnabled = false
    }
    
    func setStatus_FileLoadSuccessful() {
        self.label_status.stringValue = StatusLabels.statusSuccessfulLoad;
        self.image_status.image = NSImage(named: NSImage.statusAvailableName);
        self.button_Trash.isEnabled = true
    }
    
    @IBAction func button_Trash_Action(_ sender: Any) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.icon = NSImage(named: NSImage.cautionName)
        alert.messageText = "Are you sure you want to delete this file?"
        alert.informativeText = "You cannot recover a deleted file from within Amphisbaena. If this file was imported, you can import it again later if you have the original file."
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "No")
        alert.beginSheetModal(for: self.window!) { (response) in
            if response == .alertFirstButtonReturn {
                if let trashActionClosure = self.trashActionClosure {
                    trashActionClosure()
                }
            }
        }
    }
    
    @IBAction func button_Import_Action(_ sender: Any) {
        if let importActionClosure = importActionClosure {
            importActionClosure();
        }
    }
    @IBAction func button_Button2_Action(_ sender: Any) {
        if let button2ActionClosure = button2ActionClosure {
            button2ActionClosure();
        }
    }
    @IBAction func button_Button3_Action(_ sender: Any) {
        if let button3ActionClosure = button3ActionClosure {
            button3ActionClosure();
        }
    }
}
