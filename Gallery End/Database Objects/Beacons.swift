//
//  Beacons.swift
//  Gallery End
//
//  Created by William Chen on 2022/11/21.
//

import Foundation
import FirebaseFirestoreSwift

class Beacon: NSObject, Codable{
    
    //Attributes
    
    //Document ID
    @DocumentID var id: String?
    var UUID: String?
    var name: String?
    var major: Int?
    var minor: Int?
    
    
}
