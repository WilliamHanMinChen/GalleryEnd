//
//  AddBeaconViewController.swift
//  Gallery End
//
//  Created by William Chen on 2022/11/24.
//

import UIKit
import FirebaseFirestore
import FirebaseFirestoreSwift

class AddBeaconViewController: UIViewController, DatabaseListener {
    

    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var minorTextField: UITextField!
    @IBOutlet weak var majorTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var uuidTextField: UITextField!
    
    
    //Stores a referene to the database
    weak var dataBaseController: DatabaseProtocol?
    //Listen to all beacons
    var listenerType: ListenerType = ListenerType.beacons
    //Reference to the listener
    var databaseListener: ListenerRegistration?
    
    //List holding the beacons
    var beacons: [Beacon] = []
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        //Change the appearance of the button
        addButton.backgroundColor = .systemIndigo
        addButton.layer.cornerRadius = 5
        
        
        //Get reference to the database controller
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        dataBaseController = appDelegate?.databaseController
        
        
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //Register as listener
        dataBaseController?.addListener(listener: self)
        
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        //Remove it self as an listener
        dataBaseController?.removeListener(listener: self)
    }
    
    ///Handle the logic after the add beacon button has been pressed
    @IBAction func addBeaconAction(_ sender: Any) {
        //Make sure all fields are entered
        guard let uuid = uuidTextField.text, let name = nameTextField.text, let major = majorTextField.text, let minor = minorTextField.text else {
            fatalError("Failed to unwrap textfield data")
        }
        
        if uuid.isEmpty || name.isEmpty || major.isEmpty || minor.isEmpty {
            let alert = UIAlertController(title: "Uh oh", message: "Please enter all fields!", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Dismiss", style: .default))
            self.present(alert, animated: true)
            return
        }
        
        //Make sure this beacon has never been added before
        for beacon in beacons {
            print(beacon.UUID)
            if beacon.UUID == uuid && (String(beacon.major ?? -1)) == major && (String(beacon.minor ?? -1)) == minor {
                let alert = UIAlertController(title: "Uh oh", message: "This beacon has already been added", preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "Dismiss", style: .default))
                self.present(alert, animated: true)
                return
            }
        }
        
        //Add the beacon
        let _ = dataBaseController?.addBeacon(uuid: uuid, name: name, major: Int(major) ?? -1 , minor: Int(minor) ?? -1)
    
        let alert = UIAlertController(title: "Success", message: "Beacon Added", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        self.present(alert, animated: true)
        
    }
    
    
    func onBeaconsChange(change: DataBaseChange, beacons: [Beacon]) {
        //Update our list of beacons
        self.beacons = beacons
        
        print("Beacons List updated")
        
    }
    
    func onPaintingsChange(change: DataBaseChange, paintings: [Painting]) {
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
