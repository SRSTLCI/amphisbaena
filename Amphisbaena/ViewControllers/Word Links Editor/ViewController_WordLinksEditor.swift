//
//  ViewController_WordLinksEditor.swift
//  Amphisbaena
//
//  Created by Casey on 4/1/20.
//  Copyright © 2020 Casey Fasthorse. All rights reserved.
//

import Cocoa

class ViewController_WordLinksEditor: NSViewController {
    
    weak var wordLinkEditorDelegate: ViewController_WordLinksEditor_Delegate?
    var fileHandler: FileHandler = FileHandler();
    
    @IBOutlet weak var button_generateWordLinks: NSButton!
    @IBOutlet weak var button_saveWordLinks: NSButton!
    @IBOutlet weak var button_viewWordLinks: NSButton!
    @IBOutlet weak var table_wordLink: NSTableView!
    
    weak var containerTranskribus: Amphisbaena_TranskribusTEIContainer?
    weak var containerFLEx: Amphisbaena_FlexTextContainer?
    weak var containerWordLinks: Amphisbaena_WordLinksContainer?
    
    var wordLinkModifier: Amphisbaena_WordLinksModifier?
    var wordLinkSelection: IndexSet?
    
    enum WordLinkStatus: Int, CaseIterable {
        case doesNotExist    = 0
        case newlyGenerated  = 1
        case newlyImported   = 2
        case modified        = 3
        case complete        = 4
    }
    
    struct wordLinkStatusStrings {
        static let strings: [WordLinkStatus : String ] = [
            .doesNotExist   :   "No word links exist.",
            .newlyGenerated :   "Word Links successfully generated.",
            .newlyImported  :   "Word Links successfully imported.",
            .modified       :   "Word Links have been modified.",
            .complete       :   "Word Links have been flagged as complete by the user."
        ]
    }
    
    func clearWordLinks() {
        print("Word links clear called.")
        self.containerWordLinks = nil
        self.wordLinkModifier = nil
    }
    
    func enableSaveWordLinks() {
        button_saveWordLinks.isEnabled = true;
        button_viewWordLinks.isEnabled = true;
    }
    
    func wordMatcherHasContent() -> Bool {
        guard let wordMatcher = wordLinkModifier else {return false}
        return (wordMatcher.wordLinks.count > 0)
    }
    
    func setupWordLinkButtons() {
        if wordMatcherHasContent() {
            button_saveWordLinks.isEnabled = true;
            button_viewWordLinks.isEnabled = true;
        }
        else {
            button_saveWordLinks.isEnabled = false;
            button_viewWordLinks.isEnabled = false;
        }
    }
    
    func setup() {
        autoGenerateWordLinks()
        setupWordLinkButtons()
        table_wordLink.reloadData()
    }
    
    func autoGenerateWordLinks() {
        if let wordLinkContainer = containerWordLinks,
            let transkribusContainer = containerTranskribus,
            let flextextContainer = containerFLEx {
            self.wordLinkModifier = Amphisbaena_WordLinksModifier(fromExistingContainer: wordLinkContainer, transkribusContainer: transkribusContainer, flexContainer: flextextContainer)
        }
    }
    
    @IBAction func button_matchWords_Action(_ sender: Any) {
        if wordLinkModifier != nil {
            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.icon = NSImage(named: NSImage.infoName)
            alert.messageText = "Word links already exist within this project. Generating new word links will overwrite existing word links you have."
            alert.informativeText = "Are you sure you want to proceed? You cannot undo your changes."
            alert.addButton(withTitle: "Yes")
            alert.addButton(withTitle: "No")
            alert.beginSheetModal(for: self.view.window!) { (response) in
                if response == .alertSecondButtonReturn {
                    return;
                }
            }
        }
        guard let containerTranskribus = containerTranskribus, let containerFLEx = containerFLEx else {return;}
        wordLinkModifier = Amphisbaena_WordLinksModifier(fromFileContainers: containerTranskribus, flexContainer: containerFLEx)
        table_wordLink.reloadData()
        setupWordLinkButtons()
    }
    
    @IBAction func button_combineSelected_underFLEx_Action(_ sender: Any) {
        guard let wordLinkModifier = wordLinkModifier else {return}
        if let combineSelection = wordLinkSelection,
            matchWords_IndexSetCanBeCombined(indexSet: combineSelection) {
            wordLinkModifier.combineSelectedIntoGuid(fromIndexSet: combineSelection)
            table_wordLink.reloadData()
        }
    }
    
    @IBAction func button_combineSelected_underTranskribus_Action(_ sender: Any) {
        guard let wordLinkModifier = wordLinkModifier else {return}
        if let combineSelection = wordLinkSelection,
            matchWords_IndexSetCanBeCombined(indexSet: combineSelection) {
            wordLinkModifier.combineSelectedIntoFacs(fromIndexSet: combineSelection)
            table_wordLink.reloadData()
        }
    }
    
    @IBAction func button_insertEmpty_Transkribus(_ sender: Any) {
        guard let wordLinkModifier = wordLinkModifier else {return}
        if let singleSelection = wordLinkSelection,
            matchWords_IndexIsSingleIndex(indexSet: singleSelection) {
            wordLinkModifier.insertEmptyTranskribus(atIndexSet: singleSelection)
            table_wordLink.reloadData()
        }
    }
    
    @IBAction func button_saveWordLinks(_ sender: Any) {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.icon = NSImage(named: NSImage.infoName)
        alert.messageText = "You are about to override any existing word links in your project file with the word link setup you created here."
        alert.informativeText = "Are you sure you want to proceed? You cannot undo your changes."
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "No")
        alert.beginSheetModal(for: self.view.window!) { (response) in
            if response == .alertFirstButtonReturn {
                self.wordLinkModifier?.setupNewContainer()
                if let wordLinkContainer = self.wordLinkModifier?.resultContainer {
                    self.wordLinkEditorDelegate?.receiveFinalWordLinkObject(finalObject: wordLinkContainer)
                }
                self.view.window?.close()
            }
        }
    }
    
    @IBAction func button_closeWithoutSaving(_ sender: Any) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.icon = NSImage(named: NSImage.cautionName)
        alert.messageText = "You may have unsaved changes. Are you sure you want to close without saving?"
        alert.informativeText = "You cannot recover unsaved changes."
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "No")
        alert.beginSheetModal(for: self.view.window!) { (response) in
            if response == .alertFirstButtonReturn {
                self.clearWordLinks()
                self.view.window?.close()
            }
        }
    }
    
    @IBAction func button_viewWordLinks_Action(_ sender: Any) {
        if let modifier = wordLinkModifier {
            modifier.setupNewContainer()
            if let resultContainer = modifier.resultContainer {
                print(resultContainer.generateXML())
            }
        }
    }
    @IBAction func button_debugPrintLinks(_ sender: Any) {
        if let modifier = wordLinkModifier {
            print(modifier.wordLinks.compactMap {
                return [$0.facsFirst, $0.facsCount, $0.facsRange, $0.guidsFirst, $0.guidsCount, $0.guidsRange]
            })
        }
    }
    
    func matchWords_IndexSetCanBeCombined(indexSet: IndexSet) -> Bool {
        var difference: Int = 0;
        var previous: Int = 0;
        var canCombine = true;
        if let first = indexSet.first {
            previous = first as Int;
            indexSet.forEach { (index) in
                if (canCombine == true) {
                    difference = index-previous;
                    if difference > 1 {
                        canCombine = false;
                    }
                    previous = index as Int;
                }
            }
        }
        return canCombine;
    }
    
    func matchWords_IndexIsSingleIndex(indexSet: IndexSet) -> Bool {
        var count = 0;
        indexSet.forEach { (index) in
            count += 1;
        }
        return count == 1;
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        table_wordLink.delegate = self
        table_wordLink.dataSource = self
    }
    
}

protocol ViewController_WordLinksEditor_Delegate: AnyObject {
    func receiveFinalWordLinkObject(finalObject: Amphisbaena_WordLinksContainer)
    func showWordLinkXML(withXML XML: String)
}

extension ViewController_WordLinksEditor: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        guard let modifier = wordLinkModifier else {return 0}
        return modifier.wordLinks.count
    }
}

extension ViewController_WordLinksEditor: NSTableViewDelegate {
    
    struct TableIdentifiers {
        static var FLEx_itemIndex           = NSUserInterfaceItemIdentifier("FLEx_itemIndex")
        static var FLEx_txtItem             = NSUserInterfaceItemIdentifier("FLEx_txtItem")
        static var FLEx_guid                = NSUserInterfaceItemIdentifier("FLEx_guid")
        static var Transkribus_itemIndex    = NSUserInterfaceItemIdentifier("Transkribus_itemIndex")
        static var Transkribus_w            = NSUserInterfaceItemIdentifier("Transkribus_w")
        static var Transkribus_facs         = NSUserInterfaceItemIdentifier("Transkribus_facs")
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        guard let wordLinkModifier = wordLinkModifier else {return nil;}
        
        let wordLink = wordLinkModifier.wordLinks[row];
        
        var wordLinkTranskribusFacs: [Int]? = wordLink.facsRange.compactMap {$0}
        var wordLinkFLExGuid: [Int]? = wordLink.guidsRange.compactMap {$0}
        
        var text = "";
        var identifier: NSUserInterfaceItemIdentifier!
        
        if tableColumn == tableView.tableColumns[0] {
            identifier = TableIdentifiers.FLEx_itemIndex;
            var txt = ""
            if let wordLinkFLExGuid = wordLinkFLExGuid {
                for i in 0..<wordLinkFLExGuid.count {
                    txt += String(wordLinkFLExGuid[i])
                    if (i < wordLinkFLExGuid.count-1) {
                        txt += ", "
                    }
                }
            }
            text = txt
        }
        else if tableColumn == tableView.tableColumns[1] {
            identifier = TableIdentifiers.FLEx_txtItem;
            var txt = ""
            if let wordLinkFLExGuid = wordLinkFLExGuid {
                for i in 0..<wordLinkFLExGuid.count {
                    let flexWordIndex = wordLinkFLExGuid[i]
                    let flexWordGuid = wordLinkModifier.flexWords[flexWordIndex].guid
                    txt += flexWordGuid
                    if (i < wordLinkFLExGuid.count-1) {
                        txt += ", "
                    }
                }
            }
            text = txt
            /*
            if let currentGuid = currentGuid {
                text = currentGuid.guid
            }
            */
        }
        else if tableColumn == tableView.tableColumns[2] {
            identifier = TableIdentifiers.FLEx_guid
            var txt = ""
            if let wordLinkFLExGuid = wordLinkFLExGuid {
                for i in 0..<wordLinkFLExGuid.count {
                    let flexWordIndex = wordLinkFLExGuid[i]
                    let flexWordGuid = wordLinkModifier.flexWords[flexWordIndex].content
                    txt += flexWordGuid
                    if (i < wordLinkFLExGuid.count-1) {
                        txt += ", "
                    }
                }
            }
            text = txt
            /*
            if let currentGuid = currentGuid {
                text = currentGuid.content
            }
            */
        }
        else if tableColumn == tableView.tableColumns[3] {
            identifier = TableIdentifiers.FLEx_itemIndex
            var txt = ""
            if let wordLinkTranskribusFacs = wordLinkTranskribusFacs {
                for i in 0..<wordLinkTranskribusFacs.count {
                    txt += String(wordLinkTranskribusFacs[i])
                    if (i < wordLinkTranskribusFacs.count-1) {
                        txt += ", "
                    }
                }
            }
            text = txt
            /*
            if currentFacs != nil {
                text = String(row)
            }
            */
        }
        else if tableColumn == tableView.tableColumns[4] {
            identifier = TableIdentifiers.Transkribus_w
            var txt = ""
            if let wordLinkTranskribusFacs = wordLinkTranskribusFacs {
                for i in 0..<wordLinkTranskribusFacs.count {
                    let transkribusFacsIndex = wordLinkTranskribusFacs[i]
                    let transkribusFacs = wordLinkModifier.transkribusWords[transkribusFacsIndex].facs
                    txt += transkribusFacs
                    if (i < wordLinkTranskribusFacs.count-1) {
                        txt += ", "
                    }
                }
            }
            text = txt
            /*
            if let currentFacs = currentFacs {
                for w in 0..<currentFacs.count {
                    text += currentFacs[w].content
                    if (w < currentFacs.count-1) {text += ", "}
                }
            }
            */
        }
        else if tableColumn == tableView.tableColumns[5] {
            identifier = TableIdentifiers.Transkribus_facs
            var txt = ""
            if let wordLinkTranskribusFacs = wordLinkTranskribusFacs {
                for i in 0..<wordLinkTranskribusFacs.count {
                    let transkribusFacsIndex = wordLinkTranskribusFacs[i]
                    let transkribusFacs = wordLinkModifier.transkribusWords[transkribusFacsIndex].content
                    txt += transkribusFacs
                    if (i < wordLinkTranskribusFacs.count-1) {
                        txt += ", "
                    }
                }
            }
            text = txt
            /*
            if let currentFacs = currentFacs {
                for w in 0..<currentFacs.count {
                    text += currentFacs[w].facs
                    if (w < currentFacs.count-1) {text += ", "}
                }
            }
            */
        }
        
        if let cell = tableView.makeView(withIdentifier: identifier, owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            //cell.imageView?.image = image
            return cell
        }
        return nil
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        if let tableView = notification.object as? NSTableView,
            tableView == table_wordLink {
            wordLinkSelection = tableView.selectedRowIndexes;
        }
    }
}
