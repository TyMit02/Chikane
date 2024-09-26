//
//  SessionView.swift
//  Chikane
//
//  Created by Ty Mitchell on 9/16/24.
//

import SwiftUI
import CoreLocation
import Combine
import MapKit
import AVFoundation
import Photos
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct SessionView: View {
    @StateObject private var viewModel: SessionViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showingExitAlert = false
    @Binding var isPresented: Bool
    
    init(sessionName: String, track: Track, carId: String, event: Event? = nil, car: Car? = nil, isPresented: Binding<Bool>) {
           _viewModel = StateObject(wrappedValue: SessionViewModel(sessionName: sessionName, track: track, carId: carId, event: event, car: car))
           _isPresented = isPresented
       }
    var body: some View {
           ZStack {
               AppColors.background.edgesIgnoringSafeArea(.all)
               
               VStack {
                   topBar
                   Spacer()
                   lapTimerDisplay
                   Spacer()
                   controlButtons
               }
               .padding()
               
                if viewModel.showFastestLapAnimation {
                    AppColors.fastestLap
                        .opacity(0.3)
                        .edgesIgnoringSafeArea(.all)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.5), value: viewModel.showFastestLapAnimation)
                }
            }
            .navigationBarHidden(true)
            .alert(isPresented: $showingExitAlert) {
                Alert(
                    title: Text("Exit Session"),
                    message: Text("Do you want to save this session?"),
                    primaryButton: .default(Text("Save and Exit")) {
                        viewModel.saveAndExitSession()
                        isPresented = false
                    },
                    secondaryButton: .destructive(Text("Discard")) {
                        viewModel.endSession()
                        isPresented = false
                    }
                )
            }
            .onAppear {
                viewModel.setupCaptureSession()
            }
        }
    
    private var topBar: some View {
        HStack {
            Text(viewModel.sessionName)
                .font(AppFonts.headline)
                .foregroundColor(AppColors.text)
            Spacer()
            gpsStatusIndicator
            Button(action: { showingExitAlert = true }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(AppColors.accent)
                    .font(.title2)
            }
        }
    }
    
    private var gpsStatusIndicator: some View {
        HStack {
            Image(systemName: "location.fill")
                .foregroundColor(viewModel.isGPSActive ? .green : .red)
            Text(viewModel.isGPSActive ? "GPS Active" : "GPS Inactive")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.lightText)
        }
    }
    
    private var lapTimerDisplay: some View {
        VStack(spacing: 20) {
            Text(viewModel.formattedCurrentLapTime)
                .font(.system(size: 80, weight: .bold, design: .monospaced))
                .foregroundColor(AppColors.text)
            
            Text("Lap \(viewModel.currentLap)")
                .font(AppFonts.title2)
                .foregroundColor(AppColors.lightText)
            
            if !viewModel.laps.isEmpty {
                HStack {
                    Text("Last Lap: \(viewModel.formatTime(viewModel.laps.last ?? 0))")
                    Text("Best Lap: \(viewModel.formatTime(viewModel.bestLapTime))")
                }
                .font(AppFonts.subheadline)
                .foregroundColor(AppColors.lightText)
            }
        }
    }
    
    private var controlButtons: some View {
           HStack(spacing: 30) {
               mainActionButton
               recordButton
               lapButton
           }
       }
    
    
    
    private var mainActionButton: some View {
        Button(action: {
            if viewModel.isRunning {
                viewModel.stopSession()
            } else {
                viewModel.startSession()
            }
        }) {
            Text(viewModel.isRunning ? "Stop" : "Start")
                .font(AppFonts.headline)
                .foregroundColor(.white)
                .frame(width: 100, height: 50)
                .background(viewModel.isRunning ? Color.red : AppColors.accent)
                .cornerRadius(25)
        }
    }
    
    
    private var recordButton: some View {
           Button(action: viewModel.toggleRecording) {
               Image(systemName: viewModel.isRecording ? "record.circle.fill" : "record.circle")
                   .font(.system(size: 40))
                   .foregroundColor(viewModel.isRecording ? .red : AppColors.accent)
           }
           .disabled(!viewModel.isRunning)
       }
    
    private var lapButton: some View {
        Button(action: viewModel.recordLap) {
            Text("Lap")
                .font(AppFonts.headline)
                .foregroundColor(.white)
                .frame(width: 80, height: 50)
                .background(AppColors.secondary)
                .cornerRadius(25)
        }
        .disabled(!viewModel.isRunning)
    }
}

struct StatView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
        }
    }
}

class SessionViewModel: NSObject, ObservableObject, CLLocationManagerDelegate, AVCaptureFileOutputRecordingDelegate {
    let sessionName: String
       let track: Track
       let carId: String
       let event: Event?
       let car: Car?
    
    init(sessionName: String, track: Track, carId: String, event: Event? = nil, car: Car? = nil) {
            self.sessionName = sessionName
            self.track = track
            self.carId = carId
            self.event = event
            self.car = car
            super.init()
            setupLocationManager()
            setupStartFinishLine()
        }
    
    @Published var isRunning = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var laps: [TimeInterval] = []
    @Published var alertItem: AlertItem?
    @Published var currentLap: Int = 0
    @Published var totalDistance: CLLocationDistance = 0
    @Published var currentSpeed: CLLocationSpeed = 0
    @Published var averageSpeed: CLLocationSpeed = 0
    @Published var maxSpeed: CLLocationSpeed = 0
    @Published var isGPSActive = false
    @Published var isRecording = false
    @Published var currentLapTime: TimeInterval = 0
    @Published var showFastestLapAnimation = false
    
    
    private var timer: Timer?
    private var startTime: Date?
    private var lastLapStartTime: Date?
    private let locationManager = CLLocationManager()
    private var startFinishRegion: CLCircularRegion?
    private let sessionManager = SessionManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var lastLocation: CLLocation?
    private var audioRecorder: AVAudioRecorder?
     var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureMovieFileOutput?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    
    
    
    var formattedCurrentLapTime: String {
           formatTime(currentLapTime)
       }
    
    var formattedElapsedTime: String {
        formatTime(elapsedTime)
    }
    
    
    var averageLapTime: TimeInterval {
        laps.isEmpty ? 0 : laps.reduce(0, +) / Double(laps.count)
    }
    
    var mapRegion: MKCoordinateRegion {
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: track.startFinishLatitude,
                    longitude: track.startFinishLongitude
                ),
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
        }
   
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 5 // Update every 5 meters
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func setupStartFinishLine() {
           let startFinishCoordinate = CLLocationCoordinate2D(
               latitude: track.startFinishLatitude,
               longitude: track.startFinishLongitude
           )
           startFinishRegion = CLCircularRegion(center: startFinishCoordinate, radius: 20, identifier: "StartFinishLine")
           startFinishRegion?.notifyOnEntry = true
           startFinishRegion?.notifyOnExit = false
       }
    func startSession() {
            isRunning = true
            startTime = Date()
            lastLapStartTime = startTime
            currentLap = 1
            locationManager.startUpdatingLocation()
            if let region = startFinishRegion {
                locationManager.startMonitoring(for: region)
            }
            startTimer()
        }
    
    func stopSession() {
           isRunning = false
           timer?.invalidate()
           timer = nil
           locationManager.stopUpdatingLocation()
           if let region = startFinishRegion {
               locationManager.stopMonitoring(for: region)
           }
           stopRecording()
       }
    
    private func startTimer() {
           timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] _ in
               self?.updateElapsedTime()
               self?.updateCurrentLapTime()
           }
       }
    
    private func updateCurrentLapTime() {
            guard let lastLapStartTime = lastLapStartTime else { return }
            currentLapTime = Date().timeIntervalSince(lastLapStartTime)
        }
        
    func setupCaptureSession() {
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let audioCaptureDevice = AVCaptureDevice.default(for: .audio),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
              let audioInput = try? AVCaptureDeviceInput(device: audioCaptureDevice),
              let captureSession = captureSession else {
            print("Failed to set up capture session")
            return
        }
        
        if captureSession.canAddInput(videoInput) && captureSession.canAddInput(audioInput) {
            captureSession.addInput(videoInput)
            captureSession.addInput(audioInput)
        }
        
        videoOutput = AVCaptureMovieFileOutput()
        if let videoOutput = videoOutput, captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.videoGravity = .resizeAspectFill
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession?.startRunning()
            print("Capture session started running")
        }
    }
        
    func toggleRecording() {
        if isRecording {
            print("Stopping recording")
            stopRecording()
        } else {
            print("Starting recording")
            startRecording()
        }
    }
    
    func startRecording() {
        guard let videoOutput = videoOutput, !isRecording else {
            print("Cannot start recording: videoOutput is nil or already recording")
            return
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let videoFilename = documentsPath.appendingPathComponent("\(sessionName)_\(Date().timeIntervalSince1970).mov")
        
        print("Starting recording to: \(videoFilename.path)")
        videoOutput.startRecording(to: videoFilename, recordingDelegate: self)
        isRecording = true
    }

    func stopRecording() {
        print("Stopping recording")
        videoOutput?.stopRecording()
        isRecording = false
    }
    
    private func saveBestLapToLeaderboard() {
        guard let userId = Auth.auth().currentUser?.uid,
              let eventCode = event?.eventCode,
              let bestLapTime = laps.min(),
              let car = car else { return }

        let db = Firestore.firestore()
        let leaderboardEntry = LeaderboardEntry(
            position: 0, // This will be calculated server-side or when fetching the leaderboard
            driverName: Auth.auth().currentUser?.displayName ?? "Unknown",
            carInfo: "\(car.make) \(car.model)",
            carMake: car.make,
            carModel: car.model,
            bestLapTime: formatTime(bestLapTime)
        )

        db.collection("events").document(eventCode).collection("leaderboard")
            .document(userId).setData(try! Firestore.Encoder().encode(leaderboardEntry))
    }
    
    private func updateElapsedTime() {
        guard let startTime = startTime else { return }
        elapsedTime = Date().timeIntervalSince(startTime)
    }
    
    func endSession() {
        stopSession()
    }
    
    func saveAndExitSession() {
        endSession()
        guard let userId = AuthenticationManager.shared.user?.uid else {
            print("Error: No user logged in")
            self.alertItem = AlertItem(title: "Error", message: "No user logged in")
            return
            saveBestLapToLeaderboard()
        }
        
        let session = Session(
            id: UUID().uuidString,
            userId: userId,
            name: sessionName,
            date: Date(),
            track: track,
            carId: carId,
            lapTimes: laps,
            sectorTimes: [], // Add sector times if you have them
            bestLapTime: bestLapTime,
            averageLapTime: averageLapTime,
            weather: WeatherCondition(condition: "Unknown", temperature: 0, humidity: 0, windSpeed: 0, windDirection: "Unknown"),
            totalDistance: totalDistance,
            averageSpeed: averageSpeed,
            maxSpeed: maxSpeed,
            notes: nil,
            fuelConsumption: nil,
            tireCompound: nil,
            trackTemperature: nil,
            airTemperature: nil
        )
        
        print("Attempting to save session: \(session.id ?? "No ID") for user: \(userId)")
        
        SessionManager.shared.saveSession(session)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .finished:
                    print("Session saved successfully: \(session.id ?? "No ID")")
                    self.alertItem = AlertItem(title: "Success", message: "Session saved successfully.")
                case .failure(let error):
                    print("Failed to save session: \(error.localizedDescription)")
                    self.alertItem = AlertItem(title: "Error", message: "Failed to save session: \(error.localizedDescription)")
                }
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }
    
   
    
    func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        let milliseconds = Int((timeInterval.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
    
    func lapColor(for index: Int) -> Color {
        if laps[index] == bestLapTime {
            return .green
        } else if index > 0 && laps[index] < laps[index - 1] {
            return .yellow
        } else {
            return .primary
        }
    }
    
    @objc func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Error recording video: \(error.localizedDescription)")
        } else {
            print("Video recorded successfully: \(outputFileURL.path)")
            saveVideoToPhotoLibrary(outputFileURL)
        }
    }

    private func saveVideoToPhotoLibrary(_ videoURL: URL) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                print("Photo library access not authorized")
                return
            }
            
            print("Attempting to save video to photo library")
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .video, fileURL: videoURL, options: nil)
            }) { success, error in
                if success {
                    print("Video saved to photo library successfully")
                    try? FileManager.default.removeItem(at: videoURL)
                } else if let error = error {
                    print("Error saving video to photo library: \(error.localizedDescription)")
                }
            }
        }
    }
        
    var bestLapTime: TimeInterval {
        laps.min() ?? 0
    }

    func recordLap() {
        guard let lastLapStartTime = lastLapStartTime else { return }
        let lapTime = Date().timeIntervalSince(lastLapStartTime)
        laps.append(lapTime)
        self.lastLapStartTime = Date()
        currentLap += 1
        
        if lapTime == bestLapTime {
            showFastestLapAnimation = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.showFastestLapAnimation = false
            }
        }
    }
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, isRunning else { return }
        
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
        isGPSActive = true
        lastLocation = location
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region.identifier == "StartFinishLine" {
            recordLap()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
           print("Location manager failed with error: \(error.localizedDescription)")
           isGPSActive = false
       }
}

struct VideoPreviewView: UIViewRepresentable {
    let session: AVCaptureSession?
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        guard let session = session else { return view }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}
