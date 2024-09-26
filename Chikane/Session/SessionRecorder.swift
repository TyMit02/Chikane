//
//  SessionRecorder.swift
//  Chikane
//
//  Created by Ty Mitchell on 9/21/24.
//


import Foundation
import CoreLocation
import Combine

class SessionRecorder: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var isRecording = false
    @Published var currentLap = 0
    @Published var currentLapTime: TimeInterval = 0
    @Published var totalDistance: CLLocationDistance = 0
    @Published var currentSpeed: CLLocationSpeed = 0
    @Published var averageSpeed: CLLocationSpeed = 0
    @Published var maxSpeed: CLLocationSpeed = 0
    @Published var lapTimes: [TimeInterval] = []
    @Published var coordinates: [CLLocationCoordinate2D] = []
    
    private var locationManager: CLLocationManager
    private var startTime: Date?
    private var lapStartTime: Date?
    private var lastLocation: CLLocation?
    private var startFinishLine: CLCircularRegion?
    
    private var timer: Timer?
    
    init(track: Track) {
        self.locationManager = CLLocationManager()
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        self.locationManager.distanceFilter = 5 // Update every 5 meters
        self.setupStartFinishLine(for: track)
    }
    
    func startRecording() {
        isRecording = true
        startTime = Date()
        lapStartTime = Date()
        currentLap = 1
        locationManager.startUpdatingLocation()
        startTimer()
    }
    
    func stopRecording() {
        isRecording = false
        locationManager.stopUpdatingLocation()
        stopTimer()
    }
    
    private func setupStartFinishLine(for track: Track) {
        let center = CLLocationCoordinate2D(latitude: track.startFinishLatitude,
                                            longitude: track.startFinishLongitude)
        startFinishLine = CLCircularRegion(center: center, radius: 20, identifier: "StartFinishLine")
        startFinishLine?.notifyOnEntry = true
        locationManager.startMonitoring(for: startFinishLine!)
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateCurrentLapTime()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateCurrentLapTime() {
        guard let lapStart = lapStartTime else { return }
        currentLapTime = Date().timeIntervalSince(lapStart)
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, isRecording else { return }
        
        if let last = lastLocation {
            let distance = location.distance(from: last)
            totalDistance += distance
            
            currentSpeed = location.speed > 0 ? location.speed : currentSpeed
            maxSpeed = max(maxSpeed, currentSpeed)
            
            if let start = startTime {
                let totalTime = location.timestamp.timeIntervalSince(start)
                averageSpeed = totalDistance / totalTime
            }
        }
        
        lastLocation = location
        coordinates.append(location.coordinate)
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region.identifier == "StartFinishLine" && isRecording {
            completeCurrentLap()
        }
    }
    
    private func completeCurrentLap() {
        guard let lapStart = lapStartTime else { return }
        let lapTime = Date().timeIntervalSince(lapStart)
        lapTimes.append(lapTime)
        currentLap += 1
        lapStartTime = Date()
    }
}
