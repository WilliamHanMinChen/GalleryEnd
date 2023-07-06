//
//  WayPointAnchor.swift
//  ARResumeSession
//
//  Created by William Chen on 2022/12/1.
//

import UIKit
import ARKit

class WayPointAnchor: ARAnchor {
    
    //Storing the snapshot picture
    var imageData: Data
    
    //Storing the reference to the linked painting
    //TODO: Change to Painting Object later
    var wayPoint: String?
    
    //Stores the 3D Model file name
    var fileName = "Way point"
    
    
    convenience init?(image: UIImage, name: String, transform: float4x4) {
        //Init it self
        self.init(imageData: image.jpegData(compressionQuality: 0.5)!, transform: transform, name: name)
    }
    
    init(imageData: Data, transform: float4x4, name: String) {
        //Set its attribute
        self.imageData = imageData
        //Initialise an AR Anchor
        super.init(name: name, transform: transform)
    }
    
    required init(anchor: ARAnchor) {
        self.imageData = (anchor as! WayPointAnchor).imageData
        super.init(anchor: anchor)
    }
    
    override class var supportsSecureCoding: Bool {
        return true
    }
    
    //Decode it to be loaded
    required init?(coder aDecoder: NSCoder) {
        if let snapshot = aDecoder.decodeObject(of: NSData.self, forKey: "snapshot") as? Data {
            self.imageData = snapshot
        } else {
            return nil
        }
        
        super.init(coder: aDecoder)
    }
    
    //Encode it to be saved
    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(imageData, forKey: "snapshot")
    }
}
