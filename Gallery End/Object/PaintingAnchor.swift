//
//  PaintingAnchor.swift
//  ARResumeSession
//
//  Created by William Chen on 2022/12/1.
//

/*
 
 A custom anchor for painting anchors in an ARWorldMap
 */
import UIKit
import ARKit

class PaintingAnchor: ARAnchor {
    
    //The name that the user chose for this anchor, this allows the anchor name to be changed
    var givenName: String
    
    //Storing the snapshot picture
    var imageData: Data
    
    //Storing the reference to the linked painting
    //TODO: Change to Painting Object later
    var painting: String?
    
    //Stores the 3D Model file name
    var fileName = "Painting"
    
    
    convenience init?(image: UIImage, name: String, transform: float4x4, givenName: String) {
        //Init it self
        self.init(imageData: image.jpegData(compressionQuality: 0.5)!, transform: transform, name: name, givenName: givenName)
    }
    
    init(imageData: Data, transform: float4x4, name: String, givenName: String) {
        //Set its attribute
        self.imageData = imageData
        self.givenName = givenName
        //Initialise an AR Anchor
        super.init(name: name, transform: transform)
    }
    
    required init(anchor: ARAnchor) {
        self.imageData = (anchor as! PaintingAnchor).imageData
        self.givenName = (anchor as! PaintingAnchor).givenName
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
        
        if let name = aDecoder.decodeObject(of: NSString.self, forKey: "name") as? String {
            self.givenName = name
        } else {
            return nil
        }
        
        super.init(coder: aDecoder)
    }
    
    //Encode it to be saved
    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(imageData, forKey: "snapshot")
        aCoder.encode(givenName, forKey: "name")
    }

}

