//
//  AnchorsTableViewController.swift
//  ARResumeSession
//
//  Created by William Chen on 2022/12/1.
//

import UIKit
import ARKit

class AnchorsTableViewController: UITableViewController {

    
    //List holding all the anchors
    var anchors: [ARAnchor] = []
    
    //Delegate only for debuggin anchor names
    var delegate: WorldScanningViewController?
    
    //Anchor that is being linked
    var linkingAnchor: CustomARAnchor?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return anchors.count + 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        //If it is the first cel, dequeue a title cell
        if indexPath.section == 0{
            let cell = tableView.dequeueReusableCell(withIdentifier: "titleCell", for: indexPath) as! TitleTableViewCell
            //Set the delegate
            cell.delegate = self
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "anchorCell", for: indexPath) as! AnchorTableViewCell

        //Get the corresponding anchor
        let anchor = anchors[indexPath.section - 1] as! CustomARAnchor
        // Configure the cell...
        
        //Set the anchor the cell is displaying
        cell.displayedAnchor = anchor
        
        //Display the type
        cell.typeLabel.text = "Type: \(anchor.anchorType.rawValue ?? "")"
        
        //Set the image
        cell.snapshotImage.image = UIImage(data: anchor.imageData)
        
        //Set the cell's name textfield
        cell.nameTextField.text = anchor.givenName
        
        //Set the delegate
        cell.delegate = self
        
        //Set the scene delegate
        cell.sceneSessionDelegate = delegate
        
        //Check if it has a linked document ID
        if anchor.linkedDocumentID == "" {
            cell.linkedLabel.text = "Linked: False"
        } else {
            cell.linkedLabel.text = "Linked: True"
        }

        return cell
    }
    
    
    //MARK: Delegate methods
    
    ///This function is called whenever the save button is pressed inside the title cell
    
    func saveButtonPressed(){
        //Perform the segue
        self.dismiss(animated: true)
        //TODO: Actually save the file
    }
    
    ///This function is called when the link button of one of the cells is pressed
    func linkButtonDelegate(anchor: CustomARAnchor){
        //Perform the segue but with our CustomARAnchor as the sender to differentiate the types
        performSegue(withIdentifier: "anchorsToLinkSegue", sender: anchor)
    }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "anchorsToLinkSegue"{
            let destination = segue.destination as! LinkAnchorTableViewController
            let anchor = sender as! CustomARAnchor
            switch anchor.anchorType{
            case .Painting:
                destination.listenerType = .paintings
            case .POI:
                //TODO: CHANGE THIS LATER
                destination.listenerType = .all
            default:
                destination.listenerType = .all
            }
            
            //Set our linking anchor
            linkingAnchor = anchor
            
            //Set the delegate
            destination.delegate = self
            
        }
    }
    
    //Delegate call back for when the user selects a linkable object
    func updateAnchorLinkageDelegate(linkedDocument: String){
        if let linkingAnchor = linkingAnchor{
            linkingAnchor.linkedDocumentID = linkedDocument
            //Cascade this to the session
            delegate?.changeAnchorLinkedDoc(linkedDocument: linkedDocument, UUID: linkingAnchor.identifier.uuidString)
            
            tableView.reloadData()
        }
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

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
