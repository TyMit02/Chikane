//
//  CornerPoint.swift
//  Chikane
//
//  Created by Ty Mitchell on 10/18/24.
//


import Foundation
import CoreLocation
import Accelerate

// New data structures
struct CornerPoint {
    let index: Int
    let coordinate: CLLocationCoordinate2D
    let speed: Double
    let timestamp: Date
}

enum CornerState {
    case straight
    case entering
    case apex
    case exiting
}

class ComplexCornerDetector {
    private let curvatureThreshold: Double = 0.00005 // Adjust based on your needs
    private let speedChangeThreshold: Double = 5 // mph
    private let minCornerDuration: TimeInterval = 1.0 // seconds
    private let smoothingWindowSize = 5
    
    private var state: CornerState = .straight
    private var potentialCornerStart: CornerPoint?
    private var potentialApex: CornerPoint?
    private var detectedCorners: [CornerAnalysis] = []
    
    func detectCorners(in telemetryData: [TelemetryPoint]) -> [CornerAnalysis] {
        var smoothedCurvatures: [Double] = []
        var smoothedSpeeds: [Double] = []
        
        // Calculate curvatures and smooth data
        let curvatures = calculateCurvatures(telemetryData)
        smoothedCurvatures = smoothData(curvatures)
        smoothedSpeeds = smoothData(telemetryData.map { $0.speed })
        
        for i in 0..<telemetryData.count {
            let point = CornerPoint(index: i, 
                                    coordinate: telemetryData[i].coordinate,
                                    speed: smoothedSpeeds[i],
                                    timestamp: telemetryData[i].timestamp)
            
            processPoint(point, curvature: smoothedCurvatures[i])
        }
        
        return detectedCorners
    }
    
    private func calculateCurvatures(_ data: [TelemetryPoint]) -> [Double] {
        guard data.count > 2 else { return [] }
        
        var curvatures: [Double] = []
        
        for i in 1..<data.count-1 {
            let prev = data[i-1].coordinate
            let curr = data[i].coordinate
            let next = data[i+1].coordinate
            
            let curvature = calculateCurvature(prev, curr, next)
            curvatures.append(curvature)
        }
        
        // Pad the first and last elements
        curvatures.insert(curvatures[0], at: 0)
        curvatures.append(curvatures[curvatures.count - 1])
        
        return curvatures
    }
    
    private func calculateCurvature(_ p1: CLLocationCoordinate2D, _ p2: CLLocationCoordinate2D, _ p3: CLLocationCoordinate2D) -> Double {
        let a = CLLocation(latitude: p1.latitude, longitude: p1.longitude).distance(from: CLLocation(latitude: p2.latitude, longitude: p2.longitude))
        let b = CLLocation(latitude: p2.latitude, longitude: p2.longitude).distance(from: CLLocation(latitude: p3.latitude, longitude: p3.longitude))
        let c = CLLocation(latitude: p3.latitude, longitude: p3.longitude).distance(from: CLLocation(latitude: p1.latitude, longitude: p1.longitude))
        
        let s = (a + b + c) / 2
        let area = sqrt(s * (s - a) * (s - b) * (s - c))
        
        return 4 * area / (a * b * c)
    }
    
    private func smoothData(_ data: [Double]) -> [Double] {
        let kernel: [Double] = [1, 2, 3, 2, 1]
        var smoothed = [Double](repeating: 0, count: data.count)
        vDSP_vsmulD(kernel, 1, [1.0 / Double(kernel.reduce(0, +))], 1, UnsafeMutablePointer(mutating: kernel), 1, 5)
        vDSP_convD(data, 1, kernel, 1, &smoothed, 1, vDSP_Length(data.count), vDSP_Length(kernel.count))
        return smoothed
    }
    
    private func processPoint(_ point: CornerPoint, curvature: Double) {
        switch state {
        case .straight:
            if curvature > curvatureThreshold {
                state = .entering
                potentialCornerStart = point
            }
        case .entering:
            if curvature > curvatureThreshold {
                if point.speed < potentialCornerStart!.speed - speedChangeThreshold {
                    state = .apex
                    potentialApex = point
                }
            } else {
                state = .straight
                potentialCornerStart = nil
            }
        case .apex:
            if curvature < curvatureThreshold || point.speed > potentialApex!.speed + speedChangeThreshold {
                state = .exiting
            }
        case .exiting:
            if curvature < curvatureThreshold && point.speed > potentialCornerStart!.speed - speedChangeThreshold {
                // Corner detected
                if point.timestamp.timeIntervalSince(potentialCornerStart!.timestamp) >= minCornerDuration {
                    let corner = CornerAnalysis(
                        number: detectedCorners.count + 1,
                        entrySpeed: potentialCornerStart!.speed,
                        apexSpeed: potentialApex!.speed,
                        exitSpeed: point.speed,
                        entryPoint: potentialCornerStart!.coordinate,
                        apexPoint: potentialApex!.coordinate,
                        exitPoint: point.coordinate,
                        minimumRadius: 1 / (curvature + Double.ulpOfOne), // Avoid division by zero
                        idealLineDeviation: 0 // You may want to calculate this separately
                    )
                    detectedCorners.append(corner)
                }
                state = .straight
                potentialCornerStart = nil
                potentialApex = nil
            }
        }
    }
}

// Update SessionRecorder to use the new ComplexCornerDetector
extension SessionRecorder {
    func analyzeSession() {
        let cornerDetector = ComplexCornerDetector()
        let detectedCorners = cornerDetector.detectCorners(in: telemetryData)
        
        // Update the corners property with the newly detected corners
        self.corners = detectedCorners.map { CornerAnnotation(corner: $0) }
        
        print("Detected \(detectedCorners.count) corners using complex detection algorithm")
    }
}