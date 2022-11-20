//
//  PaintingsTableViewController.swift
//  Gallery End
//
//  Created by William Chen on 2022/11/27.
//

import UIKit

class PaintingsTableViewController: UITableViewController, DatabaseListener {
    
    
    //Sets the listener type
    var listenerType: ListenerType = ListenerType.paintings
    
    //List of paintings
    var paintings : [Painting] = []
    
    //Stores a referene to the database
    weak var dataBaseController: DatabaseProtocol?
    
    
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        dataBaseController = appDelegate?.databaseController
        
        
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
        return paintings.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }

    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        //Get the cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "paintingCell", for: indexPath) as! PaintingTableViewCell
        //Get the corresponding Beacon object
        let painting = paintings[indexPath.section]

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
    
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    //MARK: Listener functions
    func onBeaconsChange(change: DataBaseChange, beacons: [Beacon]) {
        
    }
    
    func onPaintingsChange(change: DataBaseChange, paintings: [Painting]) {
        print("Got here")
        self.paintings = paintings
        tableView.reloadData()
        
    }

}
