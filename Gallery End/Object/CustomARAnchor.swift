//
//  CustomARAnchor.swift
//  ARResumeSession
//
//  Created by William Chen on 2022/12/3.
//

import UIKit
import ARKit


///The different types of CustomAnchor we can have

enum AnchorType: String {
    case Painting = "Painting"
    case POI = "POI"
    case WayPoint = "WayPoint"
    case Undefined = "Undefined"
}

///This class outlines the basic information that is shared across all subclasses for ease of coding
class CustomARAnchor: ARAnchor {
    
    //The name of the anchor
    var givenName: String
    //The image data associated to when the anchor was placed
    var imageData: Data
    //Signaling the type of anchor
    var anchorType: AnchorType
    //The Description Object DocumentID it is linked to (Painting, POI etc)
    var linkedDocumentID: String
    
    //TODO: Add linked anchor list (we can link anchors together to form a graph)
    //var linkedAnchors: [ARAnchor]
    
    convenience init(image: UIImage, transform: float4x4, givenName: String, anchorType: AnchorType) {
        //Init it self
        self.init(givenName: givenName, imageData: image.jpegData(compressionQuality: 0.5)!, transform: transform, anchorType: anchorType)
        
    }
    
    
    
    init(givenName: String, imageData: Data, transform: float4x4, anchorType: AnchorType) {
        //Set the attributes
        self.givenName = givenName
        self.imageData = imageData
        self.anchorType = anchorType
        //Init our linked document initially to be empty since it is not linked to anything
        self.linkedDocumentID = ""
        
        super.init(name: "UserPlacedAnchor", transform: transform)
        
    }
    
    
    required init(anchor: ARAnchor) {
        //Get our attributes
        self.imageData = (anchor as! CustomARAnchor).imageData
        self.givenName = (anchor as! CustomARAnchor).givenName
        self.anchorType = (anchor as! CustomARAnchor).anchorType
        self.linkedDocumentID = (anchor as! CustomARAnchor).linkedDocumentID
        
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
        
        if let name = aDecoder.decodeObject(of: NSString.self, forKey: "givenName") as? String {
            self.givenName = name
        } else {
            return nil
        }
        
        if let documentID = aDecoder.decodeObject(of: NSString.self, forKey: "linkedDocument") as? String {
            self.linkedDocumentID = documentID
        } else {
            return nil
        }
        
        if let anchorType = aDecoder.decodeObject(of: NSString.self, forKey: "type") as? String {
            self.anchorType = AnchorType(rawValue: anchorType) ?? .Undefined
        } else {
            return nil
        }
        
        super.init(coder: aDecoder)
    }
    
    //Encode it to be saved
    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        
        print("AAAA Given name: \(givenName)")
        aCoder.encode(imageData, forKey: "snapshot")
        aCoder.encode(givenName, forKey: "givenName")
        aCoder.encode(anchorType.rawValue, forKey: "type")
        aCoder.encode(linkedDocumentID, forKey: "linkedDocument")
    }

    
    
    

}
