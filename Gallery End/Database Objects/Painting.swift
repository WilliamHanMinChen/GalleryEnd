//
//  Painting.swift
//  Gallery End
//
//  Created by William Chen on 2022/11/29.
//

import UIKit
import FirebaseFirestore
import FirebaseFirestoreSwift

///Enum with Raw values to be stored in the database
enum GuidanceType: String, Codable {
    case music = "Music"
    case layered = "Layered"
    
}

class Painting: NSObject, Codable {
    
    @DocumentID var id: String?
    //Author of the painting
    var author: String?
    //Name of the painting
    var name: String?
    //Date of creation
    var creationDate: String?
    //URL of the description
    var descriptionAudio: String?
    //Textual description
    var descriptionText: String?
    //URL of the segmented JSON file
    var segmentFile: String?
    //URL of the music
    var musicAudio: String?
    //URL of the far layer
    var farAudio: String?
    //URL of the medium layer
    var mediumAudio: String?
    //URL of the close layer
    var closeAudio: String?
    //Type of audio guidance
    var guidanceType: GuidanceType?

}
