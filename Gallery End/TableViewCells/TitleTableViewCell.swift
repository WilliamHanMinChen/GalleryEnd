//
//  TitleTableViewCell.swift
//  ARResumeSession
//
//  Created by William Chen on 2022/12/1.
//

import UIKit

class TitleTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet var contentViewBackGround: UIView!
    
    //Delegate to be called when the save button is pressed
    var delegate: AnchorsTableViewController?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    @IBAction func saveButtonPressed(_ sender: Any) {
        delegate?.saveButtonPressed()
    }
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
