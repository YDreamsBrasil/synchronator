//
//  SyncController.swift
//  Syncronator
//
//  Created by Luiz Fonseca on 11/07/2016.
//  Copyright © 2016 Luiz Fonseca. All rights reserved.
//

import Foundation
import Cocoa
import Alamofire


extension String {
    func regexMatches(pattern: String) -> Array<String> {
        let re: NSRegularExpression
        do {
            re = try NSRegularExpression(pattern: pattern, options: [NSRegularExpressionOptions.AnchorsMatchLines])
        } catch {
            return []
        }
        
        let matches = re.matchesInString(self, options: [], range: NSRange(location: 0, length: self.utf16.count))
        var collectMatches: Array<String> = []
        for match in matches {
            // range at index 0: full match
            // range at index 1: first capture group
            let substring = (self as NSString).substringWithRange(match.rangeAtIndex(1))
            collectMatches.append(substring)
        }
        return collectMatches
    }
}


@available(OSX 10.10, *)
class SyncController: NSViewController {
    
    @IBOutlet weak var resourcesLoader: NSProgressIndicator!
    @IBOutlet weak var dataLoader: NSProgressIndicator!
    
    @IBOutlet weak var currentItemDownload: NSTextField!
    @IBOutlet weak var totalItemDownload: NSTextField!
    
    var feedUrl: NSTextField!
    var pathLocation: NSTextField!
    
    private var currentCount: Int!
    private var timer: NSTimer!
    private var manager: Manager!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let url = self.feedUrl
        let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("br.com.ydreams.Syncronator.background")
        self.manager = Alamofire.Manager(configuration: configuration)
   
        // Requesting data
        if (!url.stringValue.isEmpty) {
            self.loaderTimer()
            self.downloadUrl("feed.xml", url: url.stringValue, params: ["r": "feed"], dataFunction: { (response: AnyObject) in
                let urlRes = response as! NSHTTPURLResponse
                if (urlRes.statusCode == 200) {
                    self.downloadUrl("feed.json", url: url.stringValue, params: ["r": "feed/json"], dataFunction: self.dataSaved)
                }
                
            })
        }
       
    }
    
    func dataSaved(sentData: AnyObject) {
        
        dispatch_async(dispatch_get_main_queue()){
            //print(self.pathLocation.allowedTypes)
            self.dataLoader.incrementBy(100.00)
            self.timer.invalidate()
            
        }
        
        self.fetchResources()


    }
    
    
    func fetchResources() {
        
        let currPath    = self.pathLocation.stringValue
        var fileContent = try? String(contentsOfFile: "\(currPath)/Resources/feed.xml", encoding: NSUTF8StringEncoding)
        fileContent = fileContent?.stringByReplacingOccurrencesOfString(" ", withString: "\n")
        
        let pattern = "(resources\\/(.*)?\\.png|gif|jpeg|jpg)"
        var str = fileContent!.regexMatches(pattern)
        str = Array(Set(str))
        
        let resourcesUrl = self.feedUrl.stringValue.regexMatches("(http(s)?(.+)/)index.php")
        
        self.currentCount = 0
        self.totalItemDownload.stringValue = "\(str.count)"
        let itemIncrement = 100.00 / (Double(str.count))
        
        
        for value: String in str {
            
            var name = value.regexMatches("resources\\/((.+)\\.png|gif|jpeg|jpg)")
            
            
            self.downloadUrl(name[0], url: "\(resourcesUrl[0])resources/\(name[0])", params: [:]) { (data: AnyObject) in
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.currentCount = self.currentCount + 1
                    self.resourcesLoader.incrementBy(itemIncrement)
                    self.currentItemDownload.stringValue = "\(self.currentCount)"
                }
                
            }
        }
    }
    
    

    
    
    // Download
    func downloadUrl(name: String, url: String, params: [String: AnyObject],dataFunction: (AnyObject) ->()) {
        
        let fileManager = NSFileManager.defaultManager()
        let currPath    = self.pathLocation.stringValue
        fileManager.changeCurrentDirectoryPath(currPath)

        
        do {
            try fileManager.createDirectoryAtPath("\(fileManager.currentDirectoryPath)/Resources/", withIntermediateDirectories: false, attributes: nil)

        } catch { }
        
        let finalPath = NSURL(fileURLWithPath: "\(currPath)/Resources/", isDirectory: true).URLByAppendingPathComponent(name)

        self.manager.download(.GET, url, parameters: params) { temporaryURL, response in
            dataFunction(response)
            return finalPath

        }
    }
    
    
    // Request URL method using .GET method
    func requestUrl(url: String, dataFunction: (AnyObject) -> ()) {
        
        self.manager.request(.GET, url,  parameters:["r": "feed/json"])
            .validate()
            .responseJSON { response in
                switch response.result {
                case .Success:
                    if response.result.value != nil {
                        dataFunction(response.result.value!)
                    }
                    else {
                        
                    }
                    
                case .Failure(let error):
                    print(error);
                }
    }

    }
    
    
    
    // Create timer for the given loader (NSProgressIndicator)
    func loaderTimer() {
      self.timer = NSTimer.scheduledTimerWithTimeInterval(0.2, target: self, selector: #selector(SyncController.updateDataLoader), userInfo: nil, repeats: true)
    }
    
    
    // Function to increment loader by time
    func updateDataLoader() {
        self.dataLoader.incrementBy(1.0)
    }
    
    
    // Convert JSON array to Dictionary of Strings
    func convertStringToDictionary(text: String) -> [String:AnyObject]? {
        if let data = text.dataUsingEncoding(NSUTF8StringEncoding) {
            do {
                return try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String:AnyObject]
            } catch let error as NSError {
                print(error)
            }
        }
        return nil
    }

    
    
    
    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
    }
}