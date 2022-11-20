//
//  BeaconLoadingViewController.swift
//  ARResumeSession
//
//  Created by William Chen on 2022/11/11.
//

import UIKit
import SceneKit
import ARKit

import CoreLocation
import CoreBluetooth



class BeaconLoadingViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var sceneView: ARSCNView!
    
    //Bluetooth manager
    var bluetoothManager: CBCentralManager = CBCentralManager()
    
    //Location manager
    var locationManager: CLLocationManager = CLLocationManager()
    
    //The UUID for the beacon
    var beaconUUID: String = "01122334-4556-6778-899A-ABBCCDDEEFF0"
    
    //Beacon Major ID, 2 right now for the demo we are displaying
    var majorID: Int = 1
    
    //Beacon Minor ID
    var minorID: Int = 0
    
    //Map Name
    var mapName: String = ""
    
    //Array to hold the beacons
    var beacons: [CLBeacon] = []
    
    //Haptic generator
    var generator = UIImpactFeedbackGenerator(style: .medium)
    
    
    //Keeping track of the placed anchors
    var placedAnchors: [ARAnchor] = []
    //Name used to identify which anchors are user placed anchors
    var userPlacedAnchorName = "userPlacedAnchor"
    
    
    // Lock the orientation of the app to the orientation in which it is launched
    override var shouldAutorotate: Bool {
        return false
    }
    
    //Coaching overlay
    let coachingOverlay = ARCoachingOverlayView()
    
    //The Map we are going to automatically load with the beacon
    var mapDataFromFile: Data?
    
    
    
    
    //References
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var beaconStatusLabel: UILabel!
    @IBOutlet weak var sessionInfoView: UIView!
    @IBOutlet weak var sessionInfoLabel: UILabel!
    
    //Variable to indicate whether we are relocalizing or not
    var isRelocalizingMap = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        //Request Location Usage
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        
        //Check if the user has granted permission
        if CLLocationManager.locationServicesEnabled() {
            switch locationManager.authorizationStatus {
            case .denied: //If the user had denied it
                
                //Give them an alert
                let alert = UIAlertController(title: "Alert", message: "Location access has been disabled, please enable it in the settings app",preferredStyle: UIAlertController.Style.alert)
                
                alert.addAction(UIAlertAction(title: "Take me there", style: UIAlertAction.Style.default, handler: { _ in
                    //Get the settings app's URL
                    guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
                        return
                    }
                    
                    //If we can open it
                    if UIApplication.shared.canOpenURL(settingsURL) {
                        UIApplication.shared.open(settingsURL, completionHandler: { (success) in
                            print("Settings opened: \(success)") // Prints true
                        })
                    }
                    
                }))
                
                //Present this alert message
                self.present(alert, animated: true, completion: nil)
                
            case .authorizedWhenInUse, .authorizedAlways:
                print("accepted")
            default:
                print("Other case")
                
            }
            
            // Set up coaching overlay.
            setupCoachingOverlay()

            
            
        }
            
        
        
        //Start finding the beacons
        guard let uuid = UUID(uuidString: beaconUUID) else {
            fatalError("Failed to create UUID")
        }
        
        
        //Set the constraint as to which beacons we will look for
        let beaconConstraint = CLBeaconIdentityConstraint(uuid: uuid)
        
        //Begin listening to those beacons
        locationManager.startRangingBeacons(satisfying: beaconConstraint)
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Set the view's delegate
        sceneView.delegate = self
        
        sceneView.session.delegate = self

        // Run the view's session
        sceneView.session.run(defaultConfiguration)
        
        // Prevent the screen from being dimmed after a while as users will likely
        // have long periods of interaction without touching the screen or buttons.
        UIApplication.shared.isIdleTimerDisabled = true
        
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
        
    }
    
    
    var defaultConfiguration: ARWorldTrackingConfiguration {
        let configuration = ARWorldTrackingConfiguration()
        configuration.environmentTexturing = .automatic
        sceneView.debugOptions = [ .showFeaturePoints ]
        
        return configuration
    }
    
    
//    // Called opportunistically to verify that map data can be loaded from filesystem.
//    var mapDataFromFile: Data? {
//        return try? Data(contentsOf: mapSaveURL)
//    }
//
//    lazy var mapSaveURL: URL = {
//        do {
//            return try FileManager.default
//                .url(for: .documentDirectory,
//                     in: .userDomainMask,
//                     appropriateFor: nil,
//                     create: true)
//                .appendingPathComponent(mapName)
//        } catch {
//            fatalError("Can't get file save URL: \(error.localizedDescription)")
//        }
//    }()
    
    
    
    //Delegate method called when we find beacons satisfying the constraints we set
    func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint) {
        
        for beacon in beacons {
            //We only care about 1 beacon right now
            if beacon.major.isEqual(majorID){
                //Update the beacon status text
                //Ignore if our rssi is 0 meaning the signal strength was really weak
                
                if beacon.rssi == 0 {
                    return
                }
                //Update the status label
                beaconStatusLabel.text = """
                RSSI: \(beacon.rssi)
                Distance: \(round(beacon.accuracy * 100)/400)m
                """
                
                //Check this distance if it is less than 1 meter inside of the beacon, we begin loading the map only if we havnt started loading it already
                if beacon.accuracy/4 <= 1 && !isRelocalizingMap {
                    isRelocalizingMap = true
                    
                    //TODO: Begin UI Guidance on relocalizing
                    
                    //Load the map
                    //Read the world map from the saved file
                    let worldMap: ARWorldMap = {
                        guard let data = mapDataFromFile
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

                }
                
            }
        }
        
        
    }
    
    //AR Session delegates
    //When the tracking state changes
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        //Update the text label
        updateSessionInfoLabel(for: session.currentFrame!, trackingState: camera.trackingState)
    }
    
    
    //Update the session information label
    private func updateSessionInfoLabel(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        // Update the UI to provide feedback on the state of the AR experience.
        let message: String
        
        switch (trackingState, frame.worldMappingStatus) {
        case (.limited(.relocalizing), _) where isRelocalizingMap:
            message = "Keep moving your device near where the map was scanned."
            
        default:
            message = trackingState.localizedFeedback
        }
        
        sessionInfoLabel.text = message
        sessionInfoView.isHidden = message.isEmpty
    }
    
    //When the mapping and tracking status changes
    func session(_ session: ARSession, didUpdate frame: ARFrame) {

        
        //Update the status label
        statusLabel.text = """
        Mapping: \(frame.worldMappingStatus.description)
        Tracking: \(frame.camera.trackingState.description)
        """
        //Update the session info label
        updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
    }
    
    
    
    //Adds
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        //Make sure we are only adding when it is an user added anchor
        guard anchor.name == userPlacedAnchorName else {
            return
        }
        //Get the object
        guard let sceneURL = Bundle.main.url(forResource: "cup", withExtension: "scn", subdirectory: "art.scnassets/cup"),
            let object = SCNReferenceNode(url: sceneURL) else {
                fatalError("can't load virtual object")
        }
        object.load()
        //Add it to the scene
        node.addChildNode(object)
        
    }
    
    

}





/// - Tag: CoachingOverlayViewDelegate
extension BeaconLoadingViewController: ARCoachingOverlayViewDelegate {
    
    func setupCoachingOverlay() {
        // Set up coaching view
        coachingOverlay.session = sceneView.session
        coachingOverlay.delegate = self
        
        coachingOverlay.translatesAutoresizingMaskIntoConstraints = false
        sceneView.addSubview(coachingOverlay)
        
        NSLayoutConstraint.activate([
            coachingOverlay.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            coachingOverlay.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            coachingOverlay.widthAnchor.constraint(equalTo: view.widthAnchor),
            coachingOverlay.heightAnchor.constraint(equalTo: view.heightAnchor)
            ])
        
        setActivatesAutomatically()
        
        // Most of the virtual objects in this sample require a horizontal surface,
        // therefore coach the user to find a horizontal plane.
        setGoal()
    }
    
    
    /// - Tag: CoachingActivatesAutomatically
    func setActivatesAutomatically(){
        coachingOverlay.activatesAutomatically = true
    }

    /// - Tag: CoachingGoal
    func setGoal() {
        coachingOverlay.goal = .tracking
    }
    
    
    
}
