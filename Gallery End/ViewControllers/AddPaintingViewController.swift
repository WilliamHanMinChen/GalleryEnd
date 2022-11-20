//
//  AddPaintingViewController.swift
//  Gallery End
//
//  Created by William Chen on 2022/11/27.
//

import UIKit
import FirebaseFirestore
import FirebaseFirestoreSwift

class AddPaintingViewController: UIViewController, DatabaseListener, UITextFieldDelegate {
    
    //References
    
    @IBOutlet weak var authorTextfield: UITextField!
    
    @IBOutlet weak var nameTextfield: UITextField!
    
    @IBOutlet weak var creationDateTextfield: UITextField!
    
    @IBOutlet weak var descriptionTextfield: UITextField!
    
    @IBOutlet weak var addButton: UIButton!
    
    @IBOutlet weak var guidanceTypeSegmentedControl: UISegmentedControl!
    
    ///Stores a referene to the database
    weak var dataBaseController: DatabaseProtocol?
    //Listen to all beacons
    var listenerType: ListenerType = ListenerType.paintings
    //Reference to the listener
    var databaseListener: ListenerRegistration?
    
    
    //List holding the paintings
    var paintings: [Painting] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        //Change the appearance of the button
        addButton.backgroundColor = .systemIndigo
        addButton.layer.cornerRadius = 5
        
        
        //Get reference to the database controller
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        dataBaseController = appDelegate?.databaseController
        
        //Set the textfield delegates
        authorTextfield.delegate = self
        nameTextfield.delegate = self
        creationDateTextfield.delegate = self
        descriptionTextfield.delegate = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //Register as listener
        dataBaseController?.addListener(listener: self)
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //Remove it self as an listener
        dataBaseController?.removeListener(listener: self)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    //MARK: Actions
    

    @IBAction func addPaintingPressed(_ sender: Any) {
        //Make sure all fields are entered
        guard let author = authorTextfield.text, let name = nameTextfield.text, let descriptionText = descriptionTextfield.text, let creationDate = creationDateTextfield.text else {
            fatalError("Failed to unwrap textfield data")
        }
        
        if author.isEmpty || name.isEmpty || descriptionText.isEmpty || creationDate.isEmpty {
            let alert = UIAlertController(title: "Uh oh", message: "Please enter all fields!", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Dismiss", style: .default))
            self.present(alert, animated: true)
            return
        }
        
        //Make sure this painting has never been added before
        for painting in paintings {
            if painting.name == name && painting.creationDate == creationDate && painting.author == author {
                let alert = UIAlertController(title: "Uh oh", message: "This painting has already been added", preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "Dismiss", style: .default))
                self.present(alert, animated: true)
                return
            }
        }
        
        //Add the painting
        var guidanceType = GuidanceType.layered
        //Check which guidance type the user picked
        if guidanceTypeSegmentedControl.selectedSegmentIndex == 1{
            guidanceType = .music
        }
        let _ = dataBaseController?.addPainting(author: author, name: name, creationDate: creationDate, descriptionAudio: "TBA", descriptionText: descriptionText, segmentFile: "TBA", musicAudio: "TBA", farAudio: "TBA", mediumAudio: "TBA", closeAudio: "TBA", guidanceType: guidanceType)
    
        let alert = UIAlertController(title: "Success", message: "Painting Added", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        self.present(alert, animated: true)
        
    }
    
    //MARK: Database Listener Functions
    func onBeaconsChange(change: DataBaseChange, beacons: [Beacon]) {
        
    }
    
    
    func onPaintingsChange(change: DataBaseChange, paintings: [Painting]) {
        //Update our list of paintings
        self.paintings = paintings
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        //Dismiss keyboard
        textField.resignFirstResponder()
        return true
    }
    
    
    
}
