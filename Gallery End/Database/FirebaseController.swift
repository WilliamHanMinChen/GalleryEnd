//
//  FirebaseController.swift
//  Gallery End
//
//  Created by William Chen on 2022/11/21.
//

///This class handles all interactions between our application and the firebase servers

import Foundation
import Firebase
import FirebaseFirestoreSwift
import FirebaseFirestore


class FirebaseController: NSObject, DatabaseProtocol{
    
    //Array holding all of the listeners
    var listeners = MulticastDelegate<DatabaseListener>()
    
    //Reference to the FireStore Database
    var fireStore: Firestore
    
    //Collection References
    var beaconsCollection: CollectionReference?
    var paintingCollection: CollectionReference?
    
    //Array that keeps track of beacons
    var beacons: [Beacon]
    //Array that keeps track of paintings
    var paintings: [Painting]
    
    override init(){
        
        
        //Setup and configure the firebase frameworks, this must be called first before calling any firebase methods
        FirebaseApp.configure()
        
        //Get the FireStore reference
        fireStore = Firestore.firestore()
        
        //Initialise the attributes
        beacons = []
        paintings = []
        
        super.init()
        
        //Setup the Snapshot Listeners
        setupBeaconsListener()
        setupPaintingsListener()
        
        
        
    }
    
    //MARK: Database Snapshot Listener Functions
    ///This function will add a Snapshot Listener to the Paintings Collection that will listen to all changes within the Paintings Collection
    func setupPaintingsListener(){
        
        //Get the reference to the beacons collection
        paintingCollection = fireStore.collection("Paintings")
        
        //Add a snapshot listener to this collection
        paintingCollection?.addSnapshotListener(){
            (QuerySnapshot, error) in
            //This chunk of code is run every time there is a new update to the collection (Encapsulated in the QuerySnapshot object)
            //Unwrap it
            guard let querySnapshot = QuerySnapshot else {
                fatalError("Failed to fetch documents with error: \(error?.localizedDescription)")
            }

            //Parse the results of the query
            self.parsePaintingsSnapshot(snapshot: querySnapshot)
        }
        
    }
    
    
    ///This function takes in a Snapshot and parses it into a list of paintings
    func parsePaintingsSnapshot(snapshot: QuerySnapshot){
        //Loop through each document change within the snapshot
        snapshot.documentChanges.forEach { change in
            //The parsed beacon
            var parsedPainting: Painting?
            
            //Try to decode it into a beacon object first
            do{
                parsedPainting = try change.document.data(as: Painting.self)
            } catch{
                //fatalError("Unable to decode the painting object, is it malformed? \(error)")
            }
            
            //Make sure it is a beacon
            
            guard let painting = parsedPainting else {
                fatalError("Painting document does not exist")
            }
            //Check what type of change it is
            //Determine what the change was
            if change.type == .added {
                //Insert the beacon into its corresponding position. It needs to match firestore in order to handle deletion and modification.
                paintings.insert(painting, at: Int(change.newIndex))
            }
            
            if change.type == .modified {
                //Assign the old index to a new beacon object
                paintings[Int(change.oldIndex)] = painting
            }

            if change.type == .removed {
                //Delete the beacon at the old index
                paintings.remove(at: Int(change.oldIndex))
            }
            
            //After we make the changes to the facility list, pass it onto the listeners
            listeners.invoke { (listener) in
                if listener.listenerType == ListenerType.paintings ||
                    listener.listenerType == ListenerType.all {
                    listener.onPaintingsChange(change: .update, paintings: paintings)
                }
            }
            
        }
        
    }
    
    
    
    
    
    ///This function will add a Snapshot Listener to the Beacons Collection that will listen to all changes within the Beacons Collection
    func setupBeaconsListener(){
        
        //Get the reference to the beacons collection
        beaconsCollection = fireStore.collection("Beacons")
        
        //Add a snapshot listener to this collection
        beaconsCollection?.addSnapshotListener(){
            (QuerySnapshot, error) in
            //This chunk of code is run every time there is a new update to the collection (Encapsulated in the QuerySnapshot object)
            //Unwrap it
            guard let querySnapshot = QuerySnapshot else {
                fatalError("Failed to fetch documents with error: \(error?.localizedDescription)")
            }
            
            //Parse the results of the query
            self.parseBeaconsSnapshot(snapshot: querySnapshot)
        }
        
    }
    
    ///This function takes in a Snapshot and parses it into a list of beacons
    func parseBeaconsSnapshot(snapshot: QuerySnapshot){
        //Loop through each document change within the snapshot
        snapshot.documentChanges.forEach { change in
            //The parsed beacon
            var parsedBeacon: Beacon?
            
            //Try to decode it into a beacon object first
            do{
                parsedBeacon = try change.document.data(as: Beacon.self)
            } catch{
                fatalError("Unable to decode the beacon object, is it malformed? \(error.localizedDescription)")
            }
            
            //Make sure it is a beacon
            
            guard let beacon = parsedBeacon else {
                fatalError("Beacon document does not exist")
            }
            //Check what type of change it is
            //Determine what the change was
            if change.type == .added {
                //Insert the beacon into its corresponding position. It needs to match firestore in order to handle deletion and modification.
                beacons.insert(beacon, at: Int(change.newIndex))
            }
            
            if change.type == .modified {
                //Assign the old index to a new beacon object
                beacons[Int(change.oldIndex)] = beacon
            }

            if change.type == .removed {
                //Delete the beacon at the old index
                beacons.remove(at: Int(change.oldIndex))
            }
            
            //After we make the changes to the facility list, pass it onto the listeners
            listeners.invoke { (listener) in
                if listener.listenerType == ListenerType.beacons ||
                    listener.listenerType == ListenerType.all {
                    listener.onBeaconsChange(change: .update, beacons: beacons)
                }
            }
            
        }
        
    }
    //MARK: Database protocol functions
    //Adds a listener
    func addListener(listener: DatabaseListener) {
        //Set its delegate
        listeners.addDelegate(listener)

        //If the listener is a beacon listener or all type, update them about the beacons
        if listener.listenerType == .beacons || listener.listenerType == .all {
            listener.onBeaconsChange(change: .update, beacons: beacons)
        }
        
        //If the listener is a painting listener or all type, update them about the paintings
        if listener.listenerType == .paintings || listener.listenerType == .all {
            listener.onPaintingsChange(change: .update, paintings: paintings)
        }
        
        
    }
    
    //Removes a listener
    func removeListener(listener: DatabaseListener) {
        listeners.removeDelegate(listener)
    }
    
    
    //MARK: Painting functions
    func addPainting(author: String, name: String, creationDate: String, descriptionAudio: String, descriptionText: String, segmentFile: String, musicAudio: String, farAudio: String, mediumAudio: String, closeAudio: String, guidanceType: GuidanceType) -> Bool{
        
        //Create the painting
        let painting = Painting()
        painting.author = author
        painting.name = name
        painting.creationDate = creationDate
        painting.descriptionAudio = descriptionAudio
        painting.descriptionText = descriptionText
        painting.segmentFile = segmentFile
        painting.musicAudio = musicAudio
        painting.farAudio = farAudio
        painting.mediumAudio = mediumAudio
        painting.closeAudio = closeAudio
        painting.guidanceType = guidanceType
        
        //Create a document for the painting within the paintings collection
        paintingCollection?.addDocument(data: [
            "author" : author,
            "name" : name,
            "creationDate" : creationDate,
            "descriptionText" : descriptionText,
            "descriptionAudio" : descriptionAudio,
            "segmentFile" : segmentFile,
            "musicAudio" : musicAudio,
            "farAudio" : farAudio,
            "mediumAudio" : mediumAudio,
            "closeAudio" : closeAudio,
            "guidanceType" : guidanceType.rawValue])

        return true
        
        
        
        
    }
    
    func removePainting(author: String, name: String, creationDate: String) -> Bool {
        
        return true
        
    }
    
    
    
    
    //MARK: Beacon functions
    ///This function adds a beacon to the database
    func addBeacon(uuid: String, name: String, major: Int, minor: Int) -> Bool{
        //Create the beacon
        let beacon = Beacon()
        beacon.UUID = uuid
        beacon.name = name
        beacon.major = major
        beacon.minor = minor
        
        //Create a document for the beacon within the beacon collection
        beaconsCollection?.addDocument(data: [
            "UUID" : uuid,
            "major" : major,
            "minor" : minor,
            "name" : name])
        
        return true
    }
    
    ///This function deletes a beacon given its UUID, major and minor
    ///returns: True if the operation was successful
    ///False if the operation was unsuccessful
    func removeBeacon(uuid: String, major: Int, minor: Int) -> Bool{
        //Find the document with the relative uuid
        for beacon in beacons{
            //If we find the one
            if beacon.UUID == uuid && beacon.major == major && beacon.minor == minor{
                //Get the document ID
                let documentID = beacon.id
                //Get the reference to the document within the beacons collection
                guard let id = beacon.id else {
                    fatalError("Beacon does not have a document ID")
                }
                let documentReference = beaconsCollection?.document(id)
                //Delete it
                documentReference?.delete()
                //Return True
                return true
                
            }
        }
        return false
        
    }
    
    
}
