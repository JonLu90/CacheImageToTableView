//
//  TableVC.swift
//  Download And Cache Image Files
//
//  Created by Jon Lu on 6/7/17.
//  Copyright © 2017 Jon Lu. All rights reserved.
//

import UIKit

class TableVC: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        session = URLSession.shared
        task = URLSessionDownloadTask()
        
        self.refreshControl = UIRefreshControl()
        // TODO selector function
        self.refreshControl!.addTarget(self, action: #selector(refreshTableView), for: .valueChanged)
        tableData = []
        cache = NSCache()
    }
    
    func refreshTableView() {
        let url: URL! = URL(string: "https://itunes.apple.com/search?term=flappy&entity=software")
        task = session.downloadTask(with: url, completionHandler: { (location: URL?, response: URLResponse?, error: Error?) -> Void in
            if location != nil {
                let data: Data! = try? Data(contentsOf: location!)
                do{
                    let jsonDictionary = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as AnyObject
                    self.tableData = jsonDictionary.value(forKey: "results") as? [AnyObject]
                    DispatchQueue.main.async(execute: {() -> Void in
                        self.tableView.reloadData()
                    self.refreshControl?.endRefreshing()
                    })
                } catch {
                    print("Parsing process went unsuccessful!")
                }
            }
        
        })
        task.resume()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let dictionary = tableData[indexPath.row] as! [String: AnyObject]
        cell.textLabel!.text = dictionary["trackNAme"] as? String
        cell.imageView!.image = UIImage(named: "placeholder")
        
        // cache image
        if cache.object(forKey: indexPath.row as AnyObject) as AnyObject != nil {
            // image already been cached
            // so no need to download
            print("Image file is cached!")
            cell.imageView?.image = cache.object(forKey: indexPath.row as AnyObject) as? UIImage
        } else {
            let artworkURL = dictionary["artworkUrl100"] as! String
            let url: URL! = URL(string: artworkURL)
            task = session.downloadTask(with: url, completionHandler: { (location, response, error) -> Void in
                if let data = try? Data(contentsOf: url) {
                    DispatchQueue.main.async(execute: { () -> Void in
                        // check if cell is visible right now
                        if let cellToCheck = tableView.cellForRow(at: indexPath) {
                            let img: UIImage = UIImage(data: data)!
                            cellToCheck.imageView?.image = img
                            self.cache.setObject(img, forKey: indexPath.row as AnyObject)
                        }
                    })
                }
            })
            task.resume()
        }
        
        return cell
        
    }
    
    // Properties
    // UIScrollView by default has refreshcontrol property to do UIRefreshControl
    var tableData: [AnyObject]!
    var task: URLSessionDownloadTask!
    var session: URLSession!
    var cache: NSCache<AnyObject, AnyObject>!
    
}
