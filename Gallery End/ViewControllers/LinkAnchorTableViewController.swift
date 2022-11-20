//
//  LinkAnchorTableViewController.swift
//  Gallery End
//
//  Created by William Chen on 2022/12/3.
//

import UIKit
import FirebaseFirestore
import FirebaseFirestoreSwift

class LinkAnchorTableViewController: UITableViewController, DatabaseListener, UISearchBarDelegate, UITextFieldDelegate {
    
    //The search bar reference
    @IBOutlet weak var searchBar: UISearchBar!
    
    
    //TODO: Depending on the type of anchor, display a list of POI, Paintings
    
    //Type of anchor we are trying to link
    var anchorType: AnchorType?
    
    //List holding our objects
    var linkableObjects : [NSObject] = []
    //List holding the filtered objects
    var filteredLinkableObjects: [NSObject] = []
    
    //Listener type
    var listenerType: ListenerType = .none
    
    //Stores a referene to the database
    weak var dataBaseController: DatabaseProtocol?
    
    //Delegates used to update the anchors to be saved
    var delegate: AnchorsTableViewController?
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        dataBaseController = appDelegate?.databaseController
        
        //Setup the searchbar
        searchBar.delegate = self
        searchBar.searchTextField.delegate = self
        
        //Set our initial filtered list to just be the list of objects
        filteredLinkableObjects = linkableObjects
        tableView.reloadData()
    }
    
    
    
    //This registers this class to receive updates from the database
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dataBaseController?.addListener(listener: self)
    }
    
    //This unregisters this class to receive updates from the database
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dataBaseController?.removeListener(listener: self)
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return filteredLinkableObjects.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //Get the cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "paintingCell", for: indexPath) as! PaintingTableViewCell
        //Get the corresponding Beacon object
        let painting = filteredLinkableObjects[indexPath.section] as! Painting

        // Configure the cell...
        
        cell.nameLabel.text = painting.name
        cell.authorLabel.text = painting.author
        cell.creationDateLabel.text = "Creation Date: \(painting.creationDate!)"
        cell.descriptionLabel.text = painting.descriptionText
        
        //Unwrap the guidance type
        guard let guidanceType = painting.guidanceType?.rawValue else {
            fatalError("Failed to unwrap guidance value, is the guidance type valid?")
        }
        cell.typeLabel.text = "\(guidanceType)"

        //Check if music has been provided
        if painting.musicAudio == "TBA" {
            cell.musicLabel.text = "Not Provided"
        } else {
            cell.musicLabel.text = "Provided"
        }
        //Check if all layered audio has been provided
        if painting.closeAudio == "TBA" || painting.mediumAudio == "TBA" || painting.farAudio == "TBA"{
            cell.layeredLabel.text = "Not Provided"

        } else {
            cell.layeredLabel.text = "Provided"
        }

        //Check if descriptive audio has been provided
        if painting.descriptionAudio == "TBA" {
            cell.descriptionAudioLabel.text = "Not Provided"
        } else {
            cell.descriptionAudioLabel.text = "Provided"
        }

        return cell
    }
    
    ///This method is called when the user taps on a cell
    ///We need to link what the user tapped to the anchor
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        //If it is empty, display all the objects
        if searchText.isEmpty {
            filteredLinkableObjects = linkableObjects
        } else {
            let searchText = searchText.lowercased()
            filteredLinkableObjects = searchPaintings(searchText: searchText.lowercased())
            tableView.reloadData()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
        
    }
    
    ///Searches through a list of painitings and returning only the ones containing the search text
    func searchPaintings(searchText: String) -> [Painting]{
        var returnList: [Painting] = []
        for painting in linkableObjects{
            let painting = painting as! Painting
            if painting.name?.lowercased().contains(searchText) ?? false || painting.descriptionText?.lowercased().contains(searchText) ?? false {
                returnList.append(painting)
            }
        }
        return returnList
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        //Get the cell's linkable object and its document ID
        var linkableObject = filteredLinkableObjects[indexPath.section]
        
        //Cast it to the corresponding type
        switch listenerType{
        case .paintings:
            let linkableObject = linkableObject as! Painting
            delegate?.updateAnchorLinkageDelegate(linkedDocument: linkableObject.id!)
            
        default:
            print("Null type")
        }
        
        self.dismiss(animated: true)
        
        
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
    
    //MARK: Listener functions
    //MARK: Listener functions
    func onBeaconsChange(change: DataBaseChange, beacons: [Beacon]) {
        
    }
    
    func onPaintingsChange(change: DataBaseChange, paintings: [Painting]) {
        
        //Update our list of objects
        self.linkableObjects = paintings
        
        searchBar(searchBar, textDidChange: searchBar.text!)
        
        tableView.reloadData()
        
    }
    
    

}
