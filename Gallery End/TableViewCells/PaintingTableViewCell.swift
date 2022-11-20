//
//  PaintingTableViewCell.swift
//  Gallery End
//
//  Created by William Chen on 2022/11/29.
//

import UIKit

class PaintingTableViewCell: UITableViewCell {
    
    //References
    
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var authorLabel: UILabel!
    
    @IBOutlet weak var creationDateLabel: UILabel!
    
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet weak var typeLabel: UILabel!
    
    @IBOutlet weak var musicLabel: UILabel!
    
    @IBOutlet weak var layeredLabel: UILabel!
    
    @IBOutlet weak var descriptionAudioLabel: UILabel!
    
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
