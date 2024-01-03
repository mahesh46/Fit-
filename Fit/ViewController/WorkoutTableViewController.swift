//
//  WorkoutTableViewController.swift
//  Fit
//
//  Created by Administrator on 04/03/2019.
//  Copyright © 2019 mahesh lad. All rights reserved.
//

import UIKit

class WorkoutTableViewController: UITableViewController {
    
    var workouts : [Workout]?
    let dateFormatter = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dateFormatter.dateStyle = .medium
        overrideUserInterfaceStyle = . dark
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        WorkoutDataManager.sharedManager.loadWorkoutsFromHealthKit { [weak self] (fetchedWorkouts: [Workout]?) in
            if let fetchedWorkouts = fetchedWorkouts {
                self?.workouts = fetchedWorkouts
                DispatchQueue.main.async {
                    self?.tableView?.reloadData()
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.workouts?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "workoutCell", for: indexPath)
        
        guard let workouts = workouts else {
            return cell
        }
        
        let selectedWorkout = workouts[indexPath.row]
        let dateString = dateFormatter.string(from: selectedWorkout.startTime)
        let durationString =  WorkoutDataManager.stringFromTime(timeInterval: selectedWorkout.duration)
        
        let titleText = "\(dateString) | \(selectedWorkout.workoutType) | \(durationString)"
        let detailText = String(format: "%.0f m | %.0f floors", arguments: [selectedWorkout.distance, selectedWorkout.flightsClimbed])
        
        // Configure the cell...
        cell.textLabel?.text = titleText
        cell.detailTextLabel?.text = detailText
        
        return cell
    }
    
    @IBAction func lunchHealthApp(_ sender: Any) {
        UIApplication.shared.open(URL(string: "x-apple-health://")!)
    }
    
}
