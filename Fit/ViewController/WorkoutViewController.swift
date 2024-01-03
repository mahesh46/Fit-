//
//  WorkoutViewController.swift
//  Fit
//
//  Created by Administrator on 04/03/2019.
//  Copyright © 2019 mahesh lad. All rights reserved.
//

import UIKit
import CoreLocation
import CoreMotion

enum WorkoutState {
    case inactive
    case active
    case paused
}

struct WorkoutType {
    static let automotive = "Driving"
    static let running = "Running"
    static let bicycling = "Bicycling"
    static let stationary = "Stationary"
    static let walking = "Walking"
    static let unknown = "Unknown"
}

let timerInterval : TimeInterval = 1.0

class WorkoutViewController: UIViewController {
    
    let locationManager = CLLocationManager()
    @IBOutlet weak var workoutTimeLabel: UILabel?
    @IBOutlet weak var workoutDistanceLabel: UILabel?
    @IBOutlet weak var toggleWorkoutButton: UIButton?
    @IBOutlet weak var pauseWorkoutButton: UIButton?
    
    @IBOutlet weak var workoutPaceLabel : UILabel?
    
    var currentWorkoutState = WorkoutState.inactive
    var currentWorkoutType = WorkoutType.unknown
    
    var workoutStartTime : Date?
    var lastSavedTime : Date?
    var workoutDuration : TimeInterval = 0.0
    var workoutTimer : Timer?
    
    var workoutAltitude : Double = 0.0
    var workoutDistance : Double = 0.0
    var averagePace : Double = 0.0
    var floorsAscended : Double = 0.0
    var workoutSteps : Double = 0.0
    
    var lastSavedLocation : CLLocation?
    
    var isMotionAvailable : Bool = false
    
    var pedometer : CMPedometer?
    var motionManager : CMMotionActivityManager?
    var altimeter : CMAltimeter?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        updateUserInterface()
        overrideUserInterfaceStyle = . dark
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func resetWorkoutData() {
        lastSavedTime = Date()
        workoutDuration = 0.0
        workoutDistance = 0.0
        workoutAltitude = 0.0
        workoutSteps = 0
        floorsAscended = 0
        averagePace = 0.0
        currentWorkoutType = WorkoutType.unknown
        DispatchQueue.main.async {
            self.toggleWorkoutButton?.setTitle("Start", for: .normal)
            self.pauseWorkoutButton?.setTitle("Pause", for: .normal)
            self.pauseWorkoutButton?.isHidden = true
        }
        
    }
    
    func startWorkout() {
        DispatchQueue.main.async {
            self.toggleWorkoutButton?.setTitle("Stop", for: .normal)
            self.pauseWorkoutButton?.setTitle("Pause", for: .normal)
            self.pauseWorkoutButton?.isHidden = false
        }
        currentWorkoutState = .active
        UserDefaults.standard.setValue(true, forKey: "isConfigured")
        UserDefaults.standard.synchronize()
        DispatchQueue.main.async {
            self.workoutTimer = Timer.scheduledTimer(timeInterval: timerInterval, target: self, selector: #selector(self.updateWorkoutData), userInfo: nil, repeats: true)
        }
        
        locationManager.startUpdatingLocation()
        lastSavedTime = Date()
        workoutStartTime = Date()
        WorkoutDataManager.sharedManager.createNewWorkout()
        
        if (CMMotionManager().isDeviceMotionAvailable && CMPedometer.isStepCountingAvailable() && CMAltimeter.isRelativeAltitudeAvailable()) {
            isMotionAvailable = true
            
            startPedometerUpdates()
            startActivityUpdates()
            startAltimeterUpdates()
            
        } else {
            NSLog("Motion acitivity not available on device.")
            isMotionAvailable = false
        }
    }
    
    func stopWorkoutTimer() {
        DispatchQueue.main.async {
            self.workoutTimer?.invalidate()
        }
    }
    
    @IBAction func toggleWorkout() {
        
        switch currentWorkoutState {
        case .inactive:
            currentWorkoutState = .active
            DispatchQueue.main.async {
                self.requestLocationPermission()
            }
        case .active:
            currentWorkoutState = .inactive
            stopWorkoutTimer()
            pedometer?.stopUpdates()
            motionManager?.stopActivityUpdates()
            altimeter?.stopRelativeAltitudeUpdates()
            
            if let workoutStartTime = workoutStartTime {
                let workout = Workout(startTime: workoutStartTime, endTime: Date(), duration: workoutDuration, locations: [], workoutType: self.currentWorkoutType, totalSteps: workoutSteps, flightsClimbed: floorsAscended, distance: workoutDistance)
                WorkoutDataManager.sharedManager.saveWorkout(workout)
            }
        default:
            NSLog("toggleWorkout() called out of context!")
        }
        
        updateUserInterface()
    }
    
    @IBAction func pauseWorkout() {
        
        switch currentWorkoutState {
        case .paused:
            startWorkout()
        case .active:
            currentWorkoutState = .paused
            lastSavedTime = nil
            stopWorkoutTimer()
        case .inactive:
            stopWorkoutTimer()
            NSLog("pauseWorkout() called out of context!")
        }
        
        updateUserInterface()
    }
    
    func updateUserInterface() {
        
        switch(currentWorkoutState) {
        case .active:
            toggleWorkoutButton?.setTitle("Stop", for: .normal)
            pauseWorkoutButton?.setTitle("Pause", for: .normal)
            pauseWorkoutButton?.isHidden = false
            toggleWorkoutButton?.isHidden = false
        case .paused:
            pauseWorkoutButton?.setTitle("Resume", for: .normal)
            pauseWorkoutButton?.isHidden = false
            toggleWorkoutButton?.isHidden = true
        case .inactive:
            resetWorkoutData()
            toggleWorkoutButton?.setTitle("Start", for: .normal)
            pauseWorkoutButton?.setTitle("Pause", for: .normal)
            pauseWorkoutButton?.isHidden = true
            toggleWorkoutButton?.isHidden = false
            
        }
    }
    
    @objc func updateWorkoutData() {
        let now = Date()
        
        var workoutPaceText = String(format: "%.2f m/s |  %0.2fm ", arguments: [averagePace, workoutAltitude])
        
        if let lastTime = lastSavedTime {
            self.workoutDuration += now.timeIntervalSince(lastTime)
        }
        
        if currentWorkoutType != WorkoutType.unknown {
            workoutPaceText.append(" | \(currentWorkoutType)")
        }
        
        workoutTimeLabel?.text = WorkoutDataManager.stringFromTime(timeInterval: self.workoutDuration)
        
        workoutDistanceLabel?.text = String(format: "%.2fm | %.0f steps | %.0f floors", arguments: [workoutDistance, workoutSteps, floorsAscended])
        
        workoutPaceLabel?.text = workoutPaceText
        
        lastSavedTime = now
    }
    
    func startPedometerUpdates() {
        
        guard let workoutStartTime = workoutStartTime else {
            return
        }
        
        pedometer = CMPedometer()
        pedometer?.startUpdates(from: workoutStartTime, withHandler: { [weak self] (pedometerData : CMPedometerData?, error: Error?) in
            NSLog("Received pedometer update!")
            if let error = error {
                NSLog("Error reading pedometer data: \(error.localizedDescription)")
                return
            }
            
            guard let pedometerData = pedometerData,
                  let distance = pedometerData.distance as? Double,
                  let averagePace = pedometerData.averageActivePace as? Double,
                  let steps = pedometerData.numberOfSteps as? Int,
                  let floorsAscended = pedometerData.floorsAscended as? Int else {
                return
            }
            self?.workoutDistance = distance
            self?.floorsAscended = Double(floorsAscended)
            self?.workoutSteps = Double(steps)
            self?.averagePace = averagePace
        })
    }
    
    func startActivityUpdates() {
        
        motionManager = CMMotionActivityManager()
        motionManager?.startActivityUpdates(to: OperationQueue.main, withHandler: { [weak self] (activity : CMMotionActivity?) in
            guard let activity = activity else {
                return
            }
            if activity.walking {
                self?.currentWorkoutType = WorkoutType.walking
            } else if activity.running {
                self?.currentWorkoutType = WorkoutType.running
            } else if activity.cycling {
                self?.currentWorkoutType = WorkoutType.bicycling
            } else if activity.stationary {
                self?.currentWorkoutType = WorkoutType.stationary
            } else {
                self?.currentWorkoutType = WorkoutType.unknown
            }
        })
    }
    
    func startAltimeterUpdates() {
        altimeter = CMAltimeter()
        altimeter?.startRelativeAltitudeUpdates(to: OperationQueue.main, withHandler: { [weak self] (altitudeData : CMAltitudeData?, error: Error?) in
            if let error = error {
                NSLog("Error reading altimeter data: \(error.localizedDescription)")
                return
            }
            
            guard let altitudeData = altitudeData,
                  let relativeAltitude = altitudeData.relativeAltitude as? Double else {
                return
            }
            self?.workoutAltitude = relativeAltitude
        })
    }
    
    func requestLocationPermission() {
        DispatchQueue.global().async {
            if CLLocationManager.locationServicesEnabled() {
                
                self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                self.locationManager.distanceFilter = 10.0  // In meters.
                self.locationManager.pausesLocationUpdatesAutomatically = true
                self.locationManager.allowsBackgroundLocationUpdates = true
                self.locationManager.delegate = self
                
                switch(CLLocationManager.authorizationStatus()) {
                case .notDetermined:
                    self.locationManager.requestWhenInUseAuthorization()
                case .authorizedWhenInUse :
                    self.requestAlwaysPermission()
                    self.startWorkout()
                case .authorizedAlways:
                    self.resetWorkoutData()
                    self.startWorkout()
                default:
                    self.presentPermissionErrorAlert()
                }
                
            } else {
                self.presentEnableLocationAlert()
            }
            
        }
    }
    
    func requestAlwaysPermission() {
        if let isConfigured = UserDefaults.standard.value(forKey: "isConfigured") as? Bool, isConfigured == true {
            //        startWorkout()
        } else {
            locationManager.requestAlwaysAuthorization()
        }
    }
    
    func presentEnableLocationAlert() {
        let alert = UIAlertController(title: "Permission Error", message: "Please enable location services on your device", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func presentPermissionErrorAlert() {
        let alert = UIAlertController(title: "Permission Error", message: "Please enable location services for this app", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: { (action : UIAlertAction) in
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
            }
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
}

extension WorkoutViewController : CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse:
            requestAlwaysPermission()
        case .authorizedAlways:
            resetWorkoutData()
            startWorkout()
        case .denied:
            presentPermissionErrorAlert()
        default:
            NSLog("Unhandled Location Manager Status: \(status)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let mostRecentLocation = locations.last else {
            NSLog("Unable to read most recent location")
            return
        }
        
        
        lastSavedLocation = mostRecentLocation
        NSLog("Most recent location: \(String(describing: mostRecentLocation))")
        
        WorkoutDataManager.sharedManager.addLocation(coordinate: mostRecentLocation.coordinate)
    }
    
    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        NSLog("Location tracking paused")
    }
    
    func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        NSLog("Location tracking resumed")
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
