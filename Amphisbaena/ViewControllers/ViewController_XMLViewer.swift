//
//  ViewController_XMLViewer.swift
//  Amphisbaena
//
//  Created by Casey on 2/17/20.
//  Copyright © 2020 Casey Fasthorse. All rights reserved.
//

import Cocoa

class ViewController_XMLViewer: NSViewController {
    @IBOutlet weak var box_XMLView: NSBox!
    @IBOutlet var textView_XMLView: NSTextView!
    
    var boxLabel: String = "Box Label"
    var displayingXML: String = "Content"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override func viewWillAppear() {
        box_XMLView.title = boxLabel
        textView_XMLView.string = displayingXML
    }
    
    @IBAction func button_exportXML(_ sender: Any) {
        let fh = FileHandler()
        if let url = fh.saveDialog() {
            do {
                try displayingXML.write(to: url, atomically: true, encoding: .utf8)
            }
            catch {
                print("Writing file unsuccessful.")
            }
        }
    }
    
    
    @IBAction func button_Close(_ sender: Any) {
        dismiss(sender)
    }
    
}
