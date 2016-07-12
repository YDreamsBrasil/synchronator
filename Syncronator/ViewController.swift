//
//  ViewController.swift
//  Syncronator
//
//  Created by Luiz Fonseca on 11/07/2016.
//  Copyright © 2016 Luiz Fonseca. All rights reserved.
//

import Cocoa

@available(OSX 10.10, *)
class ViewController: NSViewController {

    @IBOutlet weak var feedUrl: NSTextField!
    @IBOutlet weak var pathURL: NSTextField!

    // Action for both the text and browse button
    // To find a folder
    @IBAction func openPanel(sender: AnyObject) {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.canChooseFiles = false
        openPanel.beginWithCompletionHandler { (result) -> Void in
            if result == NSFileHandlingPanelOKButton {
                self.pathURL.stringValue = (openPanel.URLs[0].path)!
            }
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set default path to Desktop
        self.pathURL.stringValue = NSString(string: "~/Desktop").stringByExpandingTildeInPath
        
        
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject!) {
        //Checking identifier is crucial as there might be multiple
        // segues attached to same view
        let detailVC = segue.destinationController as! SyncController;
        detailVC.feedUrl = self.feedUrl
        detailVC.pathLocation = self.pathURL
            
    }


}

