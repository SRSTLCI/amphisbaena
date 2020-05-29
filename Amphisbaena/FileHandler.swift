//
//  FileHandler.swift
//  Amphisbaena
//
//  Created by Casey on 2/16/20.
//  Copyright © 2020 Casey Fasthorse. All rights reserved.
//

import Foundation
import Cocoa

class FileHandler: NSObject {
    
    func openDialog(withTitle title: String, ofTypes types: [String]) -> URL? {
        let dialog = NSOpenPanel();
        
        dialog.title                   = title;
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = false;
        dialog.canCreateDirectories    = true;
        dialog.allowsMultipleSelection = false;
        dialog.allowedFileTypes        = types;
        
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            return dialog.url
            
        } else {
            return nil
        }
    }
    
    func openDialog() -> URL? {
        let dialog = NSOpenPanel();
        
        dialog.title                   = "Choose an .xml file";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = false;
        dialog.canCreateDirectories    = true;
        dialog.allowsMultipleSelection = false;
        dialog.allowedFileTypes        = ["txt","xml"];
        
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            return dialog.url
            
        } else {
            return nil
        }
    }
    
    func openDialogCSV() -> URL? {
        let dialog = NSOpenPanel();
        
        dialog.title                   = "Choose a .csv file";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = false;
        dialog.canCreateDirectories    = true;
        dialog.allowsMultipleSelection = false;
        dialog.allowedFileTypes        = ["txt","csv"];
        
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            return dialog.url
            
        } else {
            return nil
        }
    }
    
    func saveDialog() -> URL? {
        let dialog = NSSavePanel()
        
        dialog.title                    = "Save an .xml file"
        dialog.showsResizeIndicator     = true
        dialog.showsHiddenFiles        = false
        dialog.canCreateDirectories    = true
        dialog.allowedFileTypes        = ["xml"]
        
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            return dialog.url
        }
        else {
            return nil
        }
    }
}
