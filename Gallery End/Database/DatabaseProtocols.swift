//
//  DatabaseProtocol.swift
//  Gallery End
//
//  Created by William Chen on 2022/11/21.
//
///This class includes interfaces for all interactions we have with the firebase database

import Foundation
import Firebase

///Enum for differentiating actions on the database
enum DataBaseChange{
    case add
    case remove
    case update
}

///This is to differentiate the different listeners we have
enum ListenerType{
    case all
    case beacons
    case paintings
    case worldmaps
    case none
}


///Interface that a database listener must implement if they are listening to database changes
protocol DatabaseListener: AnyObject{
    //The type of listener
    var listenerType: ListenerType {get set}
    
    //This method is called when the list of beacons change
    func onBeaconsChange(change: DataBaseChange, beacons: [Beacon])
    //This method is called when the list of paintings change
    func onPaintingsChange(change: DataBaseChange, paintings: [Painting])
    
}


///Interface that a class that interacts with the database must implement
protocol DatabaseProtocol: AnyObject{
    
    //MARK: Listener Functions
    //Adds a listener
    func addListener(listener: DatabaseListener)
    //Removes a listener
    func removeListener(listener: DatabaseListener)
    
    
    //MARK: Beacons related functions
    //Adds a beacon
    func addBeacon(uuid: String, name: String, major: Int, minor: Int) -> Bool
    //Removes a beacon
    func removeBeacon(uuid: String, major: Int, minor: Int) -> Bool
    
    
    //MARK: Paintings related functions
    //Adds a painting
    func addPainting(author: String, name: String, creationDate: String, descriptionAudio: String, descriptionText: String, segmentFile: String, musicAudio: String, farAudio: String, mediumAudio: String, closeAudio: String, guidanceType: GuidanceType) -> Bool
    //Removes a painting
    func removePainting(author: String, name: String, creationDate: String) -> Bool
    
    
    
    
    
}
