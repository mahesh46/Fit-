//
//  FirstViewController.swift
//  Fit
//
//  Created by Administrator on 04/03/2019.
//  Copyright © 2019 mahesh lad. All rights reserved.
//
import UIKit
import MapKit

class WorkoutMapViewController: UIViewController {
    
    @IBOutlet weak var mapView : MKMapView?
    
    @IBOutlet weak var shareMapButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        mapView?.delegate = self
        overrideUserInterfaceStyle = . dark
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard var locations = WorkoutDataManager.sharedManager.getLastWorkout(), let first = locations.first, let last = locations.last else {
            return
        }
        let startPin = workoutAnnotation(title: "Start", coordinate: first)
        let finishPin = workoutAnnotation(title: "Finish", coordinate: last)
        
        if let oldAnnotations = mapView?.annotations {
            mapView?.removeAnnotations(oldAnnotations)
        }
        
        mapView?.showAnnotations([startPin, finishPin], animated: true)
        
        let workoutRoute = MKPolyline(coordinates: &locations, count: locations.count)
        mapView?.addOverlays([workoutRoute])
    }
    
    func workoutAnnotation(title: String, coordinate: CLLocationCoordinate2D) -> MKPointAnnotation {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = title
        return annotation
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func shareButtonPress(_ sender: Any) {
        
        if let screenshot = takeScreenshot() {
            print("share map image")
            
            //Set the link to share.
            let imageToShare = [ screenshot ]
            let activityVC = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
            activityVC.excludedActivityTypes = [UIActivity.ActivityType.airDrop, UIActivity.ActivityType.addToReadingList]
            self.present(activityVC, animated: true, completion: nil)
            
        }
        
    }
    
  
    open func takeScreenshot(_ shouldSave: Bool = true) -> UIImage? {
        var screenshotImage :UIImage?
        let layer = UIApplication.shared.keyWindow!.layer
        
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(layer.frame.size, false, scale);
        guard let context = UIGraphicsGetCurrentContext() else {return nil}
        layer.render(in:context)
        screenshotImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        if let image = screenshotImage, shouldSave {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        }
        return screenshotImage
    }
}

extension WorkoutMapViewController : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        let pathRenderer = MKPolylineRenderer(overlay: overlay)
        pathRenderer.strokeColor = UIColor.red
        pathRenderer.lineWidth = 1
        return pathRenderer
        
    }
    func mapView( _ mapView: MKMapView, didUpdate userLocation: MKUserLocation )
    {
        let regionRadius = 400 // in meters
        let coordinateRegion = MKCoordinateRegion( center: userLocation.coordinate, latitudinalMeters: CLLocationDistance(regionRadius), longitudinalMeters: CLLocationDistance(regionRadius) )
        self.mapView?.setRegion( coordinateRegion, animated: true)
    }
    
}


