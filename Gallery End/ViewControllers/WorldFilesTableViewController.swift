//
//  WorldFilesTableViewController.swift
//  ARResumeSession
//
//  Created by William Chen on 2022/11/13.
//

import UIKit

class WorldFilesTableViewController: UITableViewController {
    
    //Delegate
    var delegate: WorldScanningViewController?
    
    var worldFiles: [URL] = []
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        
        
        
        //Get all the files within the directory
        updateListOfWorldFiles()
        
        tableView.delegate = self
        
        //Reload the table view
        tableView.reloadData()
        
    }
    
    
    /// Updates the worldFiles list that contains all the world files within the default directory of the app
    func updateListOfWorldFiles(){
        
        do {
            //Get the directory
            let directory = try FileManager.default
                .url(for: .documentDirectory,
                     in: .userDomainMask,
                     appropriateFor: nil,
                     create: true)
            
            //Get the contents(URL) of the direcotry
            let directoryContents = try FileManager.default.contentsOfDirectory(
                    at: directory,
                    includingPropertiesForKeys: nil
                )
            
            //Filter such that only the world files are included in our world files list
            for url in directoryContents{
                //We only care about files that end in .arexperience
                if url.lastPathComponent.contains(".arexperience"){
                    //append this url to our world files list
                    worldFiles.append(url)
                    
                }
            }
        } catch{
            fatalError("Could not get the saved directory YRL \(error.localizedDescription)")
        }
    }
    
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return worldFiles.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "worldFileCell", for: indexPath) as! WorldFilesTableViewCell

        
        //Get our cell's corresponding URL
        let url = worldFiles[indexPath.section]
        
        do {
            
            //Get the attributes of the file we just saved
            let attribute:NSDictionary? = try FileManager.default.attributesOfItem(atPath: url.path) as NSDictionary
            if let attribute = attribute {
                //Get the size
                let MBSize = round(Float(attribute.fileSize()) / 10000) / 100
                
                //Get the modification date
                let date = attribute.fileModificationDate()
                
                //Gets the full file name with the extension
                var fullFileName: NSString = url.lastPathComponent as NSString
                
                //Removes the file extension
                let fileName = fullFileName.deletingPathExtension
                
                cell.nameLabel.text = fileName
                cell.dateLabel.text = date?.formatted(date: .abbreviated, time: .standard).description
                cell.sizeLabel.text = "\(MBSize.description) mb"
                
            }
            
            
            
        } catch {
            print("Fatal error while retrieving details about the file \(error.localizedDescription)")
        }
        
        

        return cell
    }
    
    //Called when the user clicks on a table view cell
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //Get the index
        let index = indexPath.section
        
        //Call the delegate function
        delegate?.chosenURL = worldFiles[index]
        delegate?.updateWorldMap()
        dismiss(animated: true)
    }
    
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            //Delete the file
            do {

                try FileManager.default.removeItem(atPath: worldFiles[indexPath.section].path)
                
            } catch{
                fatalError("Error occurred while deleting an item \(error.localizedDescription)")
            }
            
            
            worldFiles.remove(at: indexPath.section)
            
            // Delete the row from the data source
            
            //Convert to an index set
            let indexSet = IndexSet(integer: indexPath.section)
            
            
            tableView.deleteSections(indexSet, with: .fade)
//            tableView.deleteRows(at: [indexPath], with: .fade)
            
            
            
            
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
        
        tableView.reloadData()
    }
    

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
