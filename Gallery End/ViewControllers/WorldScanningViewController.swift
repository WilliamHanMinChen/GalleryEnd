//
//  ViewController.swift
//  ARResumeSession
//
//  Created by William Chen on 2022/11/11.
//

import UIKit
import SceneKit
import ARKit
import FirebaseStorage
//Used for hashing
import CryptoKit


class WorldScanningViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, DatabaseListener {
    

    //Scene view reference
    @IBOutlet var sceneView: ARSCNView!
    //Labels and views references
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var sessionInfoLabel: UILabel!
    @IBOutlet weak var sessionInfoView: UIView!
    
    //Buttons
    @IBOutlet weak var loadWorldButton: UIButton!
    @IBOutlet weak var saveWorldButton: UIButton!
    @IBOutlet weak var anchorTypeButton: UIButton!
    @IBOutlet weak var newLoadButton: UIButton!
    
    //Indicating whether we should handle the button iteraction or not
    var saveButtonHandle = true
    var loadButtonHandle = true
    
    
    //Keeping track of the placed anchors
    var placedAnchors: [ARAnchor] = []
    //Name used to identify which anchors are user placed anchors
    var userPlacedAnchorName = "userPlacedAnchor"
    
    //Indicating whether we are trying to relocalize an existing map or not
    var isRelocalizingMap = false
    
    //Optional URL variable to hold the map the user chose
    var chosenURL: URL?
    
    // Lock the orientation of the app to the orientation in which it is launched
    override var shouldAutorotate: Bool {
        return false
    }
    
    // Called opportunistically to verify that map data can be loaded from filesystem.
    var mapDataFromFile: Data? {
        return try? Data(contentsOf: mapSaveURL)
    }
    
    //List of paintings
    var paintings: [Painting] = []
    var listenerType: ListenerType = .paintings
    //Stores a referene to the database
    weak var dataBaseController: DatabaseProtocol?
    
    //Keeps track of all nodes that we added audio players to
    var addedAudioPlayerNodes: [SCNNode] = []
    
    //Haptic feedback engine
    let hardImpact = UIImpactFeedbackGenerator(style: .heavy)
    
    //Records down the time when we last gave haptic feedback
    var lastImapctTime: Date = Date()
    
    //Ratio of impact time, smaller value = faster haptic feedback
    var impactRatio = 3.0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Read in any already saved map to see if we can load one. If not, disable the button
        if mapDataFromFile == nil {
            loadButtonHandle = false
            loadWorldButton.tintColor = .systemBlue
            print("No map data found")
        }
        
        //Get a reference to the database controller
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        dataBaseController = appDelegate?.databaseController
        
        
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        sceneView.session.pause()
        
        //Remove all audio players
        for node in addedAudioPlayerNodes{
            node.removeAllAudioPlayers()
        }
    }
    
    var defaultConfiguration: ARWorldTrackingConfiguration {
        let configuration = ARWorldTrackingConfiguration()
        configuration.environmentTexturing = .automatic
        sceneView.debugOptions = [ .showFeaturePoints ]
        
//        //Set tracking images...
//        //Loads all the images its going to look for
//        let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil)!
//        configuration.detectionImages = referenceImages
//
//        configuration.maximumNumberOfTrackedImages = 10
        
        //Minimum distance to change volume
        sceneView.audioEnvironmentNode.distanceAttenuationParameters.referenceDistance = 0.5
        //How steep the volume curve is
        sceneView.audioEnvironmentNode.distanceAttenuationParameters.rolloffFactor = 8
        
        
        return configuration
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Set the view's delegate
        sceneView.delegate = self
        
        sceneView.session.delegate = self

        // Run the view's session
        sceneView.session.run(defaultConfiguration)
        
        // Prevent the screen from being dimmed after a while as users will likely
        // have long periods of interaction without touching the screen or buttons.
        UIApplication.shared.isIdleTimerDisabled = true
        
        
        
        //Set up the button
        saveWorldButton.layer.cornerRadius = 8
        saveWorldButton.clipsToBounds = true
        saveWorldButton.alpha = 1.0
        saveWorldButton.setTitleColor(.white, for: [])
        saveWorldButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        
        
        loadWorldButton.layer.cornerRadius = 8
        loadWorldButton.clipsToBounds = true
        loadWorldButton.alpha = 1.0
        loadWorldButton.setTitleColor(.white, for: [])
        loadWorldButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        
        
        setUpButtonMenu()
        
        //Add it self as a listener
        dataBaseController?.addListener(listener: self)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Pause the view's session
        //sceneView.session.pause()
        
        //Remove it self as a listener
        dataBaseController?.removeListener(listener: self)
    }
    
    ///This function sets up the menu button
    func setUpButtonMenu(){
        
        
        let menuTapHandler = {(action: UIAction) in
                    
            self.anchorTypeButton.setTitle(action.title, for: .normal)
            }
        anchorTypeButton.menu = UIMenu(children: [
                    UIAction(title: "Painting", state: .on, handler:
                                menuTapHandler),
                    UIAction(title: "POI", handler: menuTapHandler),
                    UIAction(title: "Way point", handler: menuTapHandler),
                ])
        anchorTypeButton.showsMenuAsPrimaryAction = true
        anchorTypeButton.changesSelectionAsPrimaryAction = true
        
        
        
    }

    
    ///This function is called to update the map of the session
    func updateWorldMap(){
        
        guard let chosenURL = chosenURL else {
            fatalError("Function called before the URL was chosen")
        }
        
        let mapData = try? Data(contentsOf: chosenURL)
        
        //Read the world map from the saved file
        let worldMap: ARWorldMap = {
            guard let data = mapData
                else { fatalError("Map data should already be verified to exist before Load button is enabled.") }
            do {
                guard let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data)
                    else { fatalError("No ARWorldMap in archive.") }
                return worldMap
            } catch {
                fatalError("Can't unarchive ARWorldMap from file data: \(error)")
            }
        }()
        

        let configuration = self.defaultConfiguration // this app's standard world tracking settings
        configuration.initialWorldMap = worldMap
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])

        isRelocalizingMap = true
        //Empty the array of anchors we have already placed
        placedAnchors = []
        
    }
    
    
    
    // MARK: - ARSCNViewDelegate
    
    
    ///This function is called whenever the scene adds a node, including when the world is loaded a anchors are being added again
    ///
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        
        //Painting recognition code...
        
        //When the world is loading. the placed anchors is empty
        
        //Make sure we are only adding when it is an user added anchor
        guard anchor.name != nil else {
            return
        }
        
        //Check if it is an image anchor, if so we just ignore it for now
        if let imageAnchor = anchor as? ARImageAnchor{
            print("Found \(imageAnchor.name)")
            
            //Dont do anything
            return
            
        }
        
        //Depending on the name of anchor, load different models
        
        var modelName = "cup"
        
        guard let anchor = anchor as? CustomARAnchor else {
            print("Failed to cast to our custom AR anchor")
            return
        }
        
        switch anchor.anchorType {
        case .Painting:
            modelName = "Painting"
        case .POI:
            modelName = "POI"
        case .WayPoint:
            modelName = "Way point"
        default:
            modelName = "cup"
        }
        
        
        //Get the object
        guard let sceneURL = Bundle.main.url(forResource: modelName, withExtension: "scn", subdirectory: "art.scnassets"),
            let object = SCNReferenceNode(url: sceneURL) else {
                fatalError("can't load virtual object")
        }
        
        object.load()
        
        //Add it to the scene
        node.addChildNode(object)
        
        
        //Load audio files if it has any
        if !anchor.linkedDocumentID.isEmpty{
            //It is linked to something
            switch anchor.anchorType{
            case.Painting:
                print("Painting")
                //Find the right painting
                for painting in paintings{
                    if painting.id == anchor.linkedDocumentID{
                        //Found the corresponding painting, check the type of guidance
                        if painting.guidanceType == .layered{
                            //Check if it has layered audio
                            guard let farAudioURL = painting.farAudio, let mediumAudioURL = painting.mediumAudio, let closeAudioURL = painting.closeAudio else {
                                fatalError("Failed to unwrap values for \(painting.name!), is this painting malformed?")
                            }
                            //Check if they have been assigned audio files
                            if farAudioURL == "TBA" || mediumAudioURL == "TBA" || closeAudioURL == "TBA"{
                                print("No layered files for \(painting.name!)")
                                
                            } else {
                                print("Beginning loading layered audio files for \(painting.name!)")
                                //Get the local URLs for the audio files
                                if let closeAudioURL = loadAudio(url: closeAudioURL), let mediumAudioURL = loadAudio(url: mediumAudioURL), let farAudioURL = loadAudio(url: farAudioURL){
                                    
                                    print("Got the URLs, setting up layered audio for \(painting.name!)")
                                    //Setup audio sources
                                    //Load them
                                    let closeAudioSource = SCNAudioSource(url: closeAudioURL)!
                                    closeAudioSource.loops = true
                                    closeAudioSource.volume = 0.05
                                    closeAudioSource.load()
                                    closeAudioSource.isPositional = true

                                    let mediumAudioSource = SCNAudioSource(url: mediumAudioURL)!
                                    mediumAudioSource.loops = true
                                    mediumAudioSource.volume = 0.1
                                    mediumAudioSource.load()
                                    mediumAudioSource.isPositional = true

                                    let farAudioSource = SCNAudioSource(url: farAudioURL)!
                                    farAudioSource.loops = true
                                    farAudioSource.volume = 0.15
                                    farAudioSource.load()
                                    farAudioSource.isPositional = true
                                    
                                    //Add our sources to our object node
                                    object.addAudioPlayer(SCNAudioPlayer(source: closeAudioSource))
                                    object.addAudioPlayer(SCNAudioPlayer(source: mediumAudioSource))
                                    object.addAudioPlayer(SCNAudioPlayer(source: farAudioSource))
                                    //Add our object to our list of added audio player nodes
                                    addedAudioPlayerNodes.append(object)
                                    
                                }
                            }
                            
                        }
                        if painting.guidanceType == .music{
                            //Check if it has music linked to it
                            guard let musicAudioURL = painting.musicAudio else{
                                fatalError("Failed to unwrap values for \(painting.name!), is this painting malformed?")
                            }
                            
                            if musicAudioURL == "TBA"{
                                print("No music audio file found for \(painting.name!)")
                                
                            }
                            print("Beginning loading music file for \(painting.name!)")
                            
                            //Get the local URL
                            if let fileURL = loadAudio(url: musicAudioURL){
                                print("Setting up music for \(painting.name!)")
                                //Setup an audio source
                                let musicSource = SCNAudioSource(url: fileURL)!
                                musicSource.loops = true
                                musicSource.volume = 0.15
                                musicSource.load()
                                musicSource.isPositional = true
                                //Add our source to our object node
                                object.addAudioPlayer(SCNAudioPlayer(source: musicSource))
                                
                                //Add our object to our list of added audio player nodes
                                addedAudioPlayerNodes.append(object)
                            }
                            
                        }
                    }
                }
            default:
                print("Other type, no handle yet")
            }
        } else {
            //It is not linked to something, dont do anything
        }
        
        print("Added :\(anchor.name!)")
        
        
        
        
    }
    
    //Tap on the scene view
    
    @IBAction func tappedSceneView(_ sender: UITapGestureRecognizer) {
        
        
        //Gets a hit test, a point on a detected plane
        guard let hitTestResult = sceneView.raycastQuery(from: sender.location(in: sceneView), allowing: .estimatedPlane, alignment: .any) else {
            return
        }
        
        //Get the ray cast result
        guard let result = sceneView.session.raycast(hitTestResult).first else {
            print("Could not get raycast result, ignoring the tap")
            return
        }
    
        //Draw something where the user tapped
        let newImage = sceneView.snapshot()
        
        //Get the scale
        let imageSize = newImage.size
        let screenSize = UIScreen.main.bounds
        let scale = imageSize.width / screenSize.width
        UIGraphicsBeginImageContextWithOptions(imageSize, false, scale)
        newImage.draw(at: CGPoint.zero)
        let tapLocation = sender.location(in: sceneView)
        
        let rectangle = CGRect(x: (tapLocation.x * scale) - 15, y: (tapLocation.y * scale) - 15, width: 120, height: 120)
        UIColor.red.setFill()
        UIRectFill(rectangle)
        guard let processedImage = UIGraphicsGetImageFromCurrentImageContext() else {
            return
        }
        UIGraphicsEndImageContext()
        
        
        
        //Ask the user for a name of the anchor, this should be unique to the scene
        let alertController = UIAlertController(title: "Enter a name for the anchor", message: nil, preferredStyle: .alert)
        alertController.addTextField()
        
        let confirmAction = UIAlertAction(title: "Save", style: .default){_ in
            
            //Get the user input answer
            let userEnteredText = alertController.textFields![0]
            
            guard var text = userEnteredText.text else {
                fatalError("Invalid text")
            }
            
            
            var objectAnchor: ARAnchor
            
            //Prepend the name the user entered with the anchor type (Way point, POI, Painting etc...)
            //This allows us to distinguishe what type of object we should load for an anchor
            switch self.anchorTypeButton.titleLabel?.text {
            case "POI":
                //Create our own anchor type
                objectAnchor = CustomARAnchor(image: processedImage, transform: result.worldTransform, givenName: text, anchorType: .POI)
            case "Painting":
                //Create our own anchor type
                objectAnchor = CustomARAnchor(image: processedImage, transform: result.worldTransform, givenName: text, anchorType: .Painting)
                
            case "Way point":
                //Create our own anchor type
                objectAnchor = CustomARAnchor(image: processedImage, transform: result.worldTransform, givenName: text, anchorType: .WayPoint)
            default:
                objectAnchor = ARAnchor(name: text, transform: result.worldTransform)
            }
            
            
            
            //Add it to the scene
            self.sceneView.session.add(anchor: objectAnchor)
            //Add it to our list
            self.placedAnchors.append(objectAnchor)
            
            print("Handled tap")
            
        }
        //Add the action
        alertController.addAction(confirmAction)
        //Present the alert to the user
        self.present(alertController, animated: true)
        
        
        
    }
    
    
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    
    //Update the session information label
    private func updateSessionInfoLabel(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        // Update the UI to provide feedback on the state of the AR experience.
        let message: String
        
        switch (trackingState, frame.worldMappingStatus) {
        //If the world has been mapped or it is still extending
        case (.normal, .mapped),(.normal, .extending):
            
            //frame.anchors.contains(where: { $0.name == userPlacedAnchorName })
            if !placedAnchors.isEmpty {
                // User has placed an object in scene and the session is mapped, prompt them to save the experience
                message = "Tap 'Save Experience' to save the current map."
            } else {
                message = "Tap on the screen to place an object."
            }
            
        case (.normal, _) where mapDataFromFile != nil && !isRelocalizingMap:
            message = "Move around to map the environment or tap 'Load Experience' to load a saved experience."
            
        case (.normal, _) where mapDataFromFile == nil:
            message = "Move around to map the environment."
            
        case (.limited(.relocalizing), _) where isRelocalizingMap:
            //Get the map name
            let name = chosenURL?.lastPathComponent as! NSString
            message = "Keep moving your device near where \(name.deletingPathExtension) was scanned."
            
        default:
            message = trackingState.localizedFeedback
        }
        
        sessionInfoLabel.text = message
        sessionInfoView.isHidden = message.isEmpty
    }
    
    //MARK: Button Actions
    
    @IBAction func autoLoadButtonPressed(_ sender: Any) {
        
        guard let mapDataFromFile = mapDataFromFile else {
            print("No file loaded")
            return
        }
        
        //Perform the segue
        performSegue(withIdentifier: "scanningToBeaconSegue", sender: nil)
    }
    
    
    
    @IBAction func newLoadButtonPressed(_ sender: Any) {
        
        performSegue(withIdentifier: "homeToAnchorsSegue", sender: nil)
    }
    
    
    
    @IBAction func saveWorldButtonAction(_ sender: Any) {
        
        //If we are not enabled, just ignore the press
        if !saveButtonHandle{
            return
        }
        
        
        //If the user has chosen a map already, save it to that map's URL
        if let url = chosenURL{
            //Get the current world map
            self.sceneView.session.getCurrentWorldMap { worldMap, error in
                //Ensure we have a map
                guard let map = worldMap
                    else { self.showAlert(title: "Can't get current world map", message: error!.localizedDescription); return }
                
                do {
                    //Get the data
                    let data = try NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                    
                    //Write the data to our saved URL
                    try data.write(to: url, options: [.atomic])
                    
                    //Get the attributes of the file we just saved
                    let attribute:NSDictionary? = try FileManager.default.attributesOfItem(atPath: url.path) as NSDictionary
                    if let attribute = attribute {
                        let MBSize = round(Float(attribute.fileSize()) / 10000) / 100
                        //Show a message to the user indicating that we have successfully saved it
                        self.showAlert(title: "Success", message: "Map size of \(MBSize)mb has been saved, press load map to localise it.")
                    }
                    
                    DispatchQueue.main.async {
                        self.loadButtonHandle = true
                        self.loadWorldButton.tintColor = .systemBlue
                    }
                    print("Map saved")
                } catch {
                    fatalError("Can't save map: \(error.localizedDescription)")
                }
            }
            
            return
        }
        
        //Otherwise...
        //Ask the user for a name of the world
        let alertController = UIAlertController(title: "Enter a location name", message: nil, preferredStyle: .alert)
        alertController.addTextField()
        
        let confirmAction = UIAlertAction(title: "Save", style: .default){_ in
            //Get the user input answer
            let userEnteredText = alertController.textFields![0]
            
            //Convert the answer to a string
            guard var fileName = userEnteredText.text else {
                fatalError("The user entered an empty string")
            }
            
            
            if fileName.isEmpty{
                fileName = " "
            }
            
            //Get the current world map
            self.sceneView.session.getCurrentWorldMap { worldMap, error in
                //Ensure we have a map
                guard let map = worldMap
                    else { self.showAlert(title: "Can't get current world map", message: error!.localizedDescription); return }
                
                do {
                    //Get the data
                    let data = try NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                    
                    //Get the file URL
                    let fileURL = self.getMapURLFromName(name: fileName)
                    
                    //Write the data to our saved URL
                    try data.write(to: fileURL, options: [.atomic])
                    
                    //Get the attributes of the file we just saved
                    let attribute:NSDictionary? = try FileManager.default.attributesOfItem(atPath: fileURL.path) as NSDictionary
                    if let attribute = attribute {
                        let MBSize = round(Float(attribute.fileSize()) / 10000) / 100
                        //Show a message to the user indicating that we have successfully saved it
                        self.showAlert(title: "Success", message: "Map size of \(MBSize)mb has been saved, press load map to localise it.")
                    }
                    
                    DispatchQueue.main.async {
                        self.loadButtonHandle = true
                        self.loadWorldButton.tintColor = .systemBlue
                    }
                    print("Map saved")
                } catch {
                    fatalError("Can't save map: \(error)")
                }
            }
            
        }
        
        //Add the action
        alertController.addAction(confirmAction)
        //Present the alert to the user
        present(alertController, animated: true)
    
        
    }
    
    @IBAction func resetButtonPressed(_ sender: Any) {
        //Reset the session
        sceneView.session.run(defaultConfiguration, options: [.resetTracking, .removeExistingAnchors])
        isRelocalizingMap = false
        //Reset our anchors
        placedAnchors = []
        //Reset our chosen url
        chosenURL = nil
        
        
    }
    
    
    
    
    // MARK: - Persistence: Saving and Loading
    
    /// Returns the URL to a file given a name
    ///  - Parameter name: The name of the file
    func getMapURLFromName(name: String) ->URL{
        do {
            return try FileManager.default
                .url(for: .documentDirectory,
                     in: .userDomainMask,
                     appropriateFor: nil,
                     create: true)
                .appendingPathComponent(name + ".arexperience")
        } catch {
            fatalError("Can't get file save URL: \(error.localizedDescription)")
        }
        
    }
    
    
    lazy var mapSaveURL: URL = {
        do {
            return try FileManager.default
                .url(for: .documentDirectory,
                     in: .userDomainMask,
                     appropriateFor: nil,
                     create: true)
                .appendingPathComponent("map.arexperience")
        } catch {
            fatalError("Can't get file save URL: \(error.localizedDescription)")
        }
    }()

    
    
    
    //AR Session delegates
    //When the tracking state changes
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        //Update the text label
        updateSessionInfoLabel(for: session.currentFrame!, trackingState: camera.trackingState)
    }
    
    
    //When the mapping and tracking status changes
    ///This function is called whenever the session processes a new frame (Happens alot per second), USE CAREFULLY TO NOT OVERLOAD THE SYSTEM
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
        
        //If we have anchors that are in the scene
        if !placedAnchors.isEmpty{
            //Check the distance of each
            
        }
        // Enable Save button only when the mapping status is good and an object has been placed
        switch frame.worldMappingStatus {
        case .extending, .mapped:
            //Only enable the save button when we have placed more than 1 anchor in the map
            saveButtonHandle = !placedAnchors.isEmpty
        default:
            saveButtonHandle = false
        }
        
        //If it is true, change color to blue
        if saveButtonHandle{
            saveWorldButton.tintColor = .systemBlue
        } else{ //Change color to gray to indicate unpressable button
            saveWorldButton.tintColor = .gray
            
        }
        
        //Update the status label
        statusLabel.text = """
        Mapping: \(frame.worldMappingStatus.description)
        Tracking: \(frame.camera.trackingState.description)
        """
        //Update the session info label
        updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
        
        //Get the camera position
        guard let cameraPosition = session.currentFrame?.camera.transform.columns.3 else { fatalError("Could not get camera values") }
        
        
        //Loop through the anchors and only keeps the ones we care about for processing
        let filteredAnchors = frame.anchors.filter { anchor in
            return anchor.name == "UserPlacedAnchor"
        }
        
        //Sort the anchors by distance , closest first
        let anchors = filteredAnchors.sorted(by: { length(cameraPosition - $0.transform.columns.3) < length(cameraPosition - $1.transform.columns.3)})
        
//        //Initialise the anchor distance variable
//        var anchorDistance = 0.0
//
//        //Get distance to all anchors that user has placed
//        for anchor in filteredAnchors{
//            let anchorPosition = anchor.transform.columns.3
//            //Create a line between the camera and the anchor
//            let cameraToAnchor = cameraPosition - anchorPosition
//            //Get the scalar distance
//            anchorDistance = Double(length(cameraToAnchor))
//
//            //Print it for debugging
//            print("\(anchor.name) \(anchorDistance) m")
//
//        }
        //Give haptic feedback
        //Make sure we have anchors
        guard anchors.count > 0 else {
            return
        }
        //Get the cloesst image we calculated before
        let closestImage = anchors[0]
        //Get the distance
        let distance = length(cameraPosition - closestImage.transform.columns.3)
        
//        //Depending on the distance, we give intervaled feedback
//        if Date().timeIntervalSince(lastImapctTime) > ((Double(distance)/impactRatio)) && distance > Float(FOCUS_DISTANCE) {
//            if distance < 2.0 { //Less than a meter away
//                radarHaptic(impactIntensity: .medium, distance: distance)
//            } else if distance < 3.0 { //Less than 2.5 meters away
//                radarHaptic(impactIntensity: .medium, distance: distance)
//            } else { //Further than that
//                radarHaptic(impactIntensity: .light, distance: distance)
//            }
//            lastImapctTime = Date()
//        }
        
        //Depending on the distance, we give intervaled feedback
        if Date().timeIntervalSince(lastImapctTime) > ((Double(distance)/impactRatio)){
            if distance < 2.0 { //Less than a meter away
                radarHaptic(impactIntensity: .medium, distance: distance)
            } else if distance < 3.0 { //Less than 2.5 meters away
                radarHaptic(impactIntensity: .medium, distance: distance)
            } else { //Further than that
                radarHaptic(impactIntensity: .light, distance: distance)
            }
            lastImapctTime = Date()
        }
        
        
    }
    
    
    
    
    
    
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //If we are going to world files
        if segue.identifier == "homeToWorldFiles"{
            //Set the delegate
            let destination = segue.destination as! WorldFilesTableViewController
            destination.delegate = self
            
        }
        
        if segue.identifier == "homeToAnchorsSegue"{
            //Set the list of anchors
            let destination = segue.destination as! AnchorsTableViewController
            
            //Filter the list of anchors to only contain the user placed ones
            var filteredAnchors: [ARAnchor] = []
            guard let anchors = sceneView.session.currentFrame?.anchors else {
                fatalError("Failed to get list of anchors, is the session malformed?")
            }
            //Only add non nil name anchors
            for anchor in anchors {
                if anchor.name != nil{
                    filteredAnchors.append(anchor)
                }
            }
            
            //Set the delegate for the sake of debugging
            destination.delegate = self
            destination.anchors = filteredAnchors
            
        }
        
        
        //If we are going to the beacon loading VC
        if segue.identifier == "scanningToBeaconSegue"{
            let destination = segue.destination as! BeaconLoadingViewController
            
            guard let mapDataFromFile = mapDataFromFile else {
                fatalError("Segue performed before map was even loaded, logical error?")
            }
            //Set the map data
            destination.mapDataFromFile = mapDataFromFile
            
            
            
        }
        
    }
    
    //MARK: Delegate method
    
    ///This method is called when the anchor name is changed in the Anchors Table View Controller
    ///newName: The new name of the anchor
    ///UUID: The unique identifier of the anchor
    func changeAnchorName(newName: String, UUID: String){
        for anchor in sceneView.session.currentFrame!.anchors{
            //Find the right anchor
            if anchor.identifier.uuidString == UUID{
                let anchor = anchor as! CustomARAnchor
                //Modify its name
                anchor.givenName = newName
            }
        }
        
    }
    
    
    ///Prints all anchors with a name, used to debug...
    func printNames(){
        for anchor in sceneView.session.currentFrame!.anchors{
            if let anchor = anchor as? CustomARAnchor{
                print("Main session anchor name: \(anchor.givenName)")
                
            }
        }
        
        
    }
    
    ///This method is called to update an anchor's linked document when the user updates it in the modify screen
    func changeAnchorLinkedDoc(linkedDocument: String, UUID: String){
        for anchor in sceneView.session.currentFrame!.anchors{
            //Find the right anchor
            if anchor.identifier.uuidString == UUID{
                let anchor = anchor as! CustomARAnchor
                //Modify its name
                anchor.linkedDocumentID = linkedDocument
            }
        }
        
    }
    
    
    
    //Listener Functions:
    
    func onBeaconsChange(change: DataBaseChange, beacons: [Beacon]) {
        
    }
    
    func onPaintingsChange(change: DataBaseChange, paintings: [Painting]) {
        //Update our list of paintings
        self.paintings = paintings
        
    }
    
    
    //MARK: Download Audio Files
    
    //Firebase Storage reference, used to download images
    var storageReference = Storage.storage()
    
    
    ///This function takes in an URL and downloads the Audio file from that URL, after it is downloaded it then returns a local file path
    ///url: The URL to download from
    func loadAudio(url: String) -> URL?{
        
        //Set our file name to be the URL, this guarantees that the same audio file wont be downloaded twice
        let fileName = MD5(string: url)
        
        //Get the paths
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        //Gets the documents directory
        let documentsDirectory = paths[0]
        //Gets our audio file's path
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        //Check if file exists in local directory
        if FileManager.default.fileExists(atPath: fileURL.path){
            //It exists
            print("Music Exists")
            //Return URL
            return fileURL
        } else {
            print("Audio file doesnt exist, begin downloaded")
            //It doesnt exist, download it
            Task{
                do {
                    //Request URL
                    let audioURL = URL(string: url)!
                    let (data, response) = try await URLSession.shared.data(from: audioURL)
                    
                    //Save the data to the fileURL so we dont have to redownload again
                    print("Writing to URL: \(fileURL)")
                    try data.write(to: fileURL)
                    print("Downloaded Music")
                    //Return URL
                    return fileURL
                } catch {
                    fatalError("Error while downloading \(error)")
                }
            }
        }
        
        return nil
    }
    ///This function takes in a string and returns a unique value for that string
    func MD5(string: String) -> String {
        let digest = Insecure.MD5.hash(data: string.data(using: .utf8) ?? Data())

        return digest.map {
            String(format: "%02hhx", $0)
        }.joined()
    }
    
    //Haptic feedback generator
    func radarHaptic(impactIntensity: UIImpactFeedbackGenerator.FeedbackStyle, distance: Float){
        let generator = UIImpactFeedbackGenerator(style: impactIntensity)
        //Initial impact
        generator.impactOccurred()
        //Wait some time before the next impact
        let delay = (Double(distance)/impactRatio)/4
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            generator.impactOccurred()
        }
    }
    
    
    
    
    
    
    
    
    
}
