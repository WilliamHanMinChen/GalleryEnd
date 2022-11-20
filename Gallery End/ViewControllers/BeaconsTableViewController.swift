//
//  BeaconsTableViewController.swift
//  Gallery End
//
//  Created by William Chen on 2022/11/21.
//

import UIKit

class BeaconsTableViewController: UITableViewController, DatabaseListener {
    
    
    //Sets the listener type
    var listenerType: ListenerType = ListenerType.beacons
    
    //List of beacons
    var beacons : [Beacon] = []
    
    //Stores a referene to the database
    weak var dataBaseController: DatabaseProtocol?
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        dataBaseController = appDelegate?.databaseController
        
        

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
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
        return beacons.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        //Get the cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "beaconCell", for: indexPath) as! BeaconTableViewCell
        //Get the corresponding Beacon object
        let beacon = beacons[indexPath.section]

        // Configure the cell...
        cell.nameLabel.text = beacon.name
        cell.UUIDLabel.text = beacon.UUID
        //Set to NA first, range beacons later...
        cell.distanceLabel.text = "--m"
        cell.strenghLabel.text = "RSSI: --"
        guard let minor = beacon.minor, let major = beacon.major else {
            fatalError("Failed to unwrap major and minor values for the beacon, is it deformed?")
        }
        
        cell.majorLabel.text = "Major: \(major)"
        cell.minorLabel.text = "Minor: \(minor)"

        return cell
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
            
            //Get the beacon we are trying to delete
            let beacon = beacons[indexPath.section]
            guard let uuid = beacon.UUID, let major = beacon.major, let minor = beacon.minor else {
                fatalError("Failed to unwrap values for the beacon, is it malformed?")
            }
            //Remove it from the database
            let _ = dataBaseController?.removeBeacon(uuid: uuid, major: major, minor: minor)
            
            beacons.remove(at: indexPath.section)
            
            // Delete the row from the data source
            let indexSet = IndexSet(integer: indexPath.section)
            tableView.deleteSections(indexSet, with: .automatic)
            
            
            tableView.reloadData()
        }
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
    
    
    //MARK: Database listener functions
    func onBeaconsChange(change: DataBaseChange, beacons: [Beacon]) {
        //Update our list of beacons
        self.beacons = beacons
        tableView.reloadData()
    }
    
    func onPaintingsChange(change: DataBaseChange, paintings: [Painting]) {
        
    }

}
