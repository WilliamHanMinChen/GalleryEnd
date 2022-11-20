//
//  PaintingAnchorTableViewCell.swift
//  ARResumeSession
//
//  Created by William Chen on 2022/12/1.
//

import UIKit
import ARKit

class AnchorTableViewCell: UITableViewCell, UITextFieldDelegate {

    @IBOutlet var nameLabel: UILabel!
    
    @IBOutlet var typeLabel: UILabel!
    
    @IBOutlet var linkedLabel: UILabel!
    
    @IBOutlet var linkButton: UIButton!
    
    @IBOutlet var snapshotImage: UIImageView!
    
    @IBOutlet weak var nameTextField: UITextField!
    
    //The anchor the cell is displaying
    var displayedAnchor: CustomARAnchor?
    
    //Delegate view controller
    var delegate: AnchorsTableViewController?
    
    //Delegate reference back to the scanning VC for modifying the anchors
    var sceneSessionDelegate: WorldScanningViewController?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        
        nameTextField.delegate = self
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    //TODO: Assign delegate method later...
    @IBAction func linkButtonPressed(_ sender: Any) {
        delegate?.linkButtonDelegate(anchor: displayedAnchor!)
        
    }
    
    //MARK: Delegate functions
    
    ///This function is called when the user presses the return key and hides the keyboard
    ///Which in turn means they finished editing the anchor's name, meaning we need to update it
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        guard let userEnteredText = nameTextField.text else {
            fatalError("Failed to unwrap text field data")
        }
        
        
        
        //Update the name
        displayedAnchor?.givenName = userEnteredText
        
        //Change the anchor name in the AR Session
        sceneSessionDelegate?.changeAnchorName(newName: userEnteredText, UUID: displayedAnchor!.identifier.uuidString)
        
    
        self.endEditing(true)
        
        return true
        
    }
    

}
