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
    @State private var isRecording = false
    @Environment(\.colorScheme) var colorScheme
   
    init(sessionName: String, track: Track, carId: String, event: Event? = nil, car: Car? = nil, duration: TimeInterval, eventViewModel: EventViewModel? = nil, userProfileViewModel: UserProfileViewModel, isPresented: Binding<Bool>) {
           _viewModel = StateObject(wrappedValue: SessionViewModel(
               sessionName: sessionName,
               track: track,
               carId: carId,
               event: event,
               car: car,
               duration: duration,
               eventViewModel: eventViewModel,
               userProfileViewModel: userProfileViewModel
           ))
           _isPresented = isPresented
       }

    var body: some View {
        ZStack {
            AppColors.background(for: colorScheme).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                topBar
                
               Spacer()
              //  mapView
                lapTimerDisplay
                Spacer()
               // statsDisplay
                recordButton
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
        .onAppear {
            viewModel.checkCameraAndMicrophonePermissions()
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
    }
 
    private var topBar: some View {
        HStack {
            Text(viewModel.sessionName)
                .font(AppFonts.headline)
                .foregroundColor(AppColors.text(for: colorScheme))
            Spacer()
            gpsStatusIndicator
            Button(action: { showingExitAlert = true }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(AppColors.accent(for: colorScheme))
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
                .foregroundColor(AppColors.lightText(for: colorScheme))
        }
    }
    
    private var mapView: some View {
        Map(coordinateRegion: .constant(MKCoordinateRegion(
            center: viewModel.userLocation ?? CLLocationCoordinate2D(latitude: viewModel.track.startFinishLatitude, longitude: viewModel.track.startFinishLongitude),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )), showsUserLocation: true)
        .frame(height: 200)
        .cornerRadius(10)
    }
    
    private var lapTimerDisplay: some View {
        VStack(spacing: 10) {
            Text(viewModel.isOutLap ? "OUT LAP" : viewModel.formattedCurrentLapTime)
                .font(.system(size: 60, weight: .bold, design: .monospaced))
                .foregroundColor(AppColors.text(for: colorScheme))
            
            Text("Lap \(viewModel.currentLap)")
                .font(AppFonts.title2)
                .foregroundColor(AppColors.lightText(for: colorScheme))
            
            if !viewModel.laps.isEmpty {
                HStack {
                    Text("Last: \(viewModel.formatTime(viewModel.laps.last ?? 0))")
                    Spacer()
                    Text("Best: \(viewModel.formatTime(viewModel.bestLapTime))")
                }
                .font(AppFonts.subheadline)
                .foregroundColor(AppColors.lightText(for: colorScheme))
            }
        }
        .padding()
        .background(AppColors.cardBackground(for: colorScheme))
        .cornerRadius(10)
    }
    
    private var statsDisplay: some View {
        HStack {
            statItem(title: "Speed", value: String(format: "%.1f mph", viewModel.currentSpeed))
            statItem(title: "Distance", value: String(format: "%.2f km", viewModel.totalDistance / 1000))
            statItem(title: "Corners", value: "\(viewModel.cornerCount)")
        }
        .padding()
        .background(AppColors.cardBackground(for: colorScheme))
        .cornerRadius(10)
    }
    
    private func statItem(title: String, value: String) -> some View {
        VStack {
            Text(title)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.lightText(for: colorScheme))
            Text(value)
                .font(AppFonts.headline)
                .foregroundColor(AppColors.text(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
    }
    
    private var recordButton: some View {
        Button(action: {
            if isRecording {
                viewModel.stopRecording()
            } else {
                viewModel.startRecording()
            }
            isRecording.toggle()
        }) {
            Image(systemName: isRecording ? "record.circle.fill" : "record.circle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 50, height: 50)
                .foregroundColor(isRecording ? .red : AppColors.accent(for: colorScheme))
        }
    }
    
    private var controlButtons: some View {
        HStack(spacing: 30) {
            mainActionButton
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
                .foregroundColor(AppColors.text(for: colorScheme))
                .frame(width: 100, height: 50)
                .background(viewModel.isRunning ? Color.red : AppColors.accent(for: colorScheme))
                .cornerRadius(25)
        }
    }
    
    private var lapButton: some View {
        Button(action: viewModel.manualLap) {
            Text("Lap")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.text(for: colorScheme))
                .frame(width: 80, height: 50)
                .background(AppColors.secondary(for: colorScheme))
                .cornerRadius(25)
        }
        .disabled(!viewModel.isRunning)
    }
}

class SessionViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    // MARK: - Published properties
    @Published var isRunning = false
    @Published var isOutLap = true
    @Published var isSimulating = false
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var weatherCondition: WeatherCondition?
    @Published var currentLap = 0
    @Published var currentLapTime: TimeInterval = 0
    @Published var totalDistance: CLLocationDistance = 0
    @Published var currentSpeed: CLLocationSpeed = 0
    @Published var cornerCount: Int = 0
    @Published var isGPSActive: Bool = false
    @Published var showFastestLapAnimation = false
    @Published var laps: [TimeInterval] = []
    @Published var remainingTime: TimeInterval
    @Published var isRecording = false
    @Published var sessionId: String?
    
    // MARK: - Public properties
    let sessionName: String
    let track: Track
    let carId: String
    let event: Event?
    var car: Car?
    let duration: TimeInterval

    // MARK: - Private properties
    private var sessionRecorder: SessionRecorder
    private var simulationTimer: Timer?
    private var simulationIndex = 0
    private let simulatedRoute = WatkinsGlenSimulation.coordinates
    private let simulationInterval: TimeInterval = 0.5
    private let db = Firestore.firestore()
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureMovieFileOutput?
    private var locationManager: CLLocationManager
    private var lastLocation: CLLocation?
    private let startFinishLine: CLCircularRegion
    private var timer: Timer?
    private let eventViewModel: EventViewModel?
    var userProfileViewModel: UserProfileViewModel

    // MARK: - Initialization
    init(sessionName: String, track: Track, carId: String, event: Event? = nil, car: Car?, duration: TimeInterval, eventViewModel: EventViewModel? = nil, userProfileViewModel: UserProfileViewModel) {
            self.sessionName = sessionName
            self.track = track
            self.carId = carId
            self.event = event
            self.car = car
            self.duration = duration
            self.eventViewModel = eventViewModel
            self.userProfileViewModel = userProfileViewModel
            self.remainingTime = duration
            self.sessionRecorder = SessionRecorder(track: track)
        
        locationManager = CLLocationManager()
        startFinishLine = CLCircularRegion(center: CLLocationCoordinate2D(latitude: track.startFinishLatitude, longitude: track.startFinishLongitude), radius: 20, identifier: "StartFinishLine")
        
        super.init()
        
        setupLocationManager()
        setupCaptureSession()
        setupSessionRecorderBindings()
    }

    // MARK: - Public methods
    func startSession() {
           isRunning = true
           isOutLap = true
           sessionRecorder.startRecording()
           sessionId = UUID().uuidString // Generate a new sessionId
           fetchAndSaveWeatherInfo()
           startTimer()
           locationManager.startUpdatingLocation()
       }


    func stopSession() {
        isRunning = false
        sessionRecorder.stopRecording()
        stopTimer()
        locationManager.stopUpdatingLocation()
    }

    func startSimulation() {
        isSimulating = true
        simulationIndex = 0
        simulationTimer = Timer.scheduledTimer(withTimeInterval: simulationInterval, repeats: true) { [weak self] _ in
            self?.updateSimulation()
        }
        startSession()
    }

    func stopSimulation() {
        isSimulating = false
        simulationTimer?.invalidate()
        simulationTimer = nil
        stopSession()
    }

    func manualLap() {
        sessionRecorder.manualLap()
    }

    func saveAndExitSession() {
        stopSession()
        
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Error: No user logged in")
            return
        }

        var session = sessionRecorder.finishSession()
        session.userId = userId
        session.carId = carId
        session.weather = weatherCondition
        session.name = sessionName

        print("Saving session - Name: \(session.name), UserID: \(session.userId), CarID: \(session.carId)")

        do {
            try db.collection("sessions").addDocument(from: session) { [weak self] error in
                if let error = error {
                    print("Error saving session: \(error.localizedDescription)")
                } else {
                    print("Session saved successfully")
                    print("Saved session details - ID: \(session.id ?? "N/A"), UserID: \(session.userId), Name: \(session.name), Date: \(session.date)")
                    self?.updateUserProfile()
                }
            }
        } catch {
            print("Error encoding session: \(error)")
        }
        updateUserProfile()
    }

    func endSession() {
        stopSession()
        // Add any additional cleanup if needed
    }

    private func fetchAndSaveWeatherInfo() {
           guard let location = sessionRecorder.currentLocation else { return }

           Task {
               do {
                   let weather = try await WeatherKitService.shared.getCurrentWeather(for: location)
                   DispatchQueue.main.async { [weak self] in
                       self?.weatherCondition = weather
                       self?.saveWeatherData(weather)
                   }
               } catch {
                   print("Error fetching weather: \(error.localizedDescription)")
               }
           }
       }
    
    private func saveWeatherData(_ weather: WeatherCondition) {
            guard let userId = Auth.auth().currentUser?.uid else {
                print("Error: No user logged in")
                return
            }

            let weatherData: [String: Any] = [
                "condition": weather.condition,
                "temperature": weather.temperature,
                "humidity": weather.humidity,
                "windSpeed": weather.windSpeed,
                "windDirection": weather.windDirection
            ]

            // Assuming you have a sessionId property
            guard let sessionId = self.sessionId else {
                print("Error: No session ID available")
                return
            }

            db.collection("sessions").document(sessionId).updateData([
                "weather": weatherData,
                "userId": userId  // Ensure the userId is set
            ]) { error in
                if let error = error {
                    print("Error saving weather data: \(error.localizedDescription)")
                } else {
                    print("Weather data saved successfully")
                }
            }
        }
    func checkCameraAndMicrophonePermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            checkMicrophonePermission()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    self?.checkMicrophonePermission()
                }
            }
        case .denied, .restricted:
            print("Camera access denied")
        @unknown default:
            break
        }
    }

    private func checkMicrophonePermission() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            setupCaptureSession()
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.setupCaptureSession()
                    }
                }
            }
        case .denied:
            print("Microphone access denied")
        @unknown default:
            break
        }
    }

    func startRecording() {
            guard let output = videoOutput else { return }
            
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let fileUrl = paths[0].appendingPathComponent("session_\(Date().timeIntervalSince1970).mov")
            output.startRecording(to: fileUrl, recordingDelegate: self)
            isRecording = true
        }

        func stopRecording() {
            videoOutput?.stopRecording()
            isRecording = false
        }

    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 1000)
        return String(format: "%02d:%02d.%03d", minutes, seconds, milliseconds)
    }

    var formattedCurrentLapTime: String {
        return formatTime(currentLapTime)
    }

    var bestLapTime: TimeInterval {
        return laps.min() ?? 0
    }

    // MARK: - Private methods
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 5
        locationManager.pausesLocationUpdatesAutomatically = false
    }

    private func setupCaptureSession() {
        captureSession = AVCaptureSession()
        guard let session = captureSession else { return }
        
        do {
            // Video input
            guard let videoDevice = AVCaptureDevice.default(for: .video) else { return }
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            if session.canAddInput(videoInput) {
                session.addInput(videoInput)
            }
            
            // Audio input
            guard let audioDevice = AVCaptureDevice.default(for: .audio) else { return }
            let audioInput = try AVCaptureDeviceInput(device: audioDevice)
            if session.canAddInput(audioInput) {
                session.addInput(audioInput)
            }
            
            videoOutput = AVCaptureMovieFileOutput()
            if let videoOutput = videoOutput, session.canAddOutput(videoOutput) {
                session.addOutput(videoOutput)
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
            }
        } catch {
            print("Error setting up capture session: \(error.localizedDescription)")
        }
    }

    private func setupSessionRecorderBindings() {
        sessionRecorder.$isRecording.assign(to: &$isRunning)
        sessionRecorder.$currentLap.assign(to: &$currentLap)
        sessionRecorder.$currentLapTime.assign(to: &$currentLapTime)
        sessionRecorder.$totalDistance.assign(to: &$totalDistance)
        sessionRecorder.$currentSpeed.assign(to: &$currentSpeed)
        sessionRecorder.$cornerCount.assign(to: &$cornerCount)
        sessionRecorder.$isGPSActive.assign(to: &$isGPSActive)
        sessionRecorder.$showFastestLapAnimation.assign(to: &$showFastestLapAnimation)
        sessionRecorder.$lapTimes.assign(to: &$laps)
            }

            private func updateSimulation() {
                guard isSimulating else { return }

                let (coordinate, speed) = simulatedRoute[simulationIndex]
                let course = calculateBearing(from: simulatedRoute[simulationIndex].0,
                                              to: simulatedRoute[(simulationIndex + 1) % simulatedRoute.count].0)

                let simulatedLocation = CLLocation(coordinate: coordinate,
                                                   altitude: 0,
                                                   horizontalAccuracy: 5,
                                                   verticalAccuracy: 5,
                                                   course: course,
                                                   speed: speed * 0.44704 / 3.6, // Convert mph to m/s and slow down
                                                   timestamp: Date())

                sessionRecorder.updateLocation(simulatedLocation)

                simulationIndex = (simulationIndex + 1) % simulatedRoute.count
                userLocation = coordinate
            }

            private func calculateBearing(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> CLLocationDirection {
                let lat1 = start.latitude * .pi / 180
                let lon1 = start.longitude * .pi / 180
                let lat2 = end.latitude * .pi / 180
                let lon2 = end.longitude * .pi / 180
                
                let dLon = lon2 - lon1
                
                let y = sin(dLon) * cos(lat2)
                let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
                let radiansBearing = atan2(y, x)
                
                return (radiansBearing * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
            }

            private func fetchWeatherInfo() {
                guard let location = sessionRecorder.currentLocation else { return }

                Task {
                    do {
                        let weather = try await WeatherKitService.shared.getCurrentWeather(for: location)
                        DispatchQueue.main.async {
                            self.weatherCondition = weather
                        }
                    } catch {
                        print("Error fetching weather: \(error.localizedDescription)")
                    }
                }
            }

            private func startTimer() {
                timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                    self?.updateTimer()
                }
            }

            private func stopTimer() {
                timer?.invalidate()
                timer = nil
            }

            private func updateTimer() {
                if !isOutLap {
                    currentLapTime += 0.1
                }
                
                remainingTime -= 0.1
                if remainingTime <= 0 {
                    stopSession()
                }
            }

            private func updateUserProfile() {
                guard let userId = Auth.auth().currentUser?.uid else { return }
                let userRef = db.collection("users").document(userId)
                
                userRef.getDocument { [weak self] (document, error) in
                    if let document = document, document.exists {
                        var data = document.data() ?? [:]
                        let currentTrackDays = data["trackDaysCount"] as? Int ?? 0
                        let currentTotalLaps = data["totalLaps"] as? Int ?? 0
                        
                        data["trackDaysCount"] = currentTrackDays + 1
                        data["totalLaps"] = currentTotalLaps + (self?.currentLap ?? 0)
                        
                        userRef.setData(data, merge: true) { error in
                            if let error = error {
                                print("Error updating user profile: \(error)")
                            } else {
                                print("User profile updated successfully")
                            }
                        }
                    }
                }
            }

            // MARK: - CLLocationManagerDelegate
            func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
                guard let location = locations.last, isRunning else { return }
                
                isGPSActive = true
                currentSpeed = location.speed * 2.23694 // Convert m/s to mph
                
                if let last = lastLocation {
                    totalDistance += location.distance(from: last)
                }
                
                if startFinishLine.contains(location.coordinate) {
                    if isOutLap {
                        isOutLap = false
                        currentLap = 1
                        currentLapTime = 0
                    } else {
                        laps.append(currentLapTime)
                        currentLap += 1
                        
                        if currentLapTime < bestLapTime || laps.count == 1 {
                            showFastestLapAnimation = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                self.showFastestLapAnimation = false
                            }
                        }
                        
                        currentLapTime = 0
                    }
                }
                
                sessionRecorder.updateLocation(location)
                lastLocation = location
                userLocation = location.coordinate
            }

            func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
                isGPSActive = false
                print("Location manager failed with error: \(error.localizedDescription)")
            }
        }

        extension SessionViewModel: AVCaptureFileOutputRecordingDelegate {
            func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
                    if let error = error {
                        print("Error recording video: \(error.localizedDescription)")
                    } else {
                        print("Video recorded successfully at \(outputFileURL)")
                        saveVideoToPhotoLibrary(videoURL: outputFileURL)
                    }
                }

                private func saveVideoToPhotoLibrary(videoURL: URL) {
                    PHPhotoLibrary.shared().performChanges {
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
                    } completionHandler: { success, error in
                        if success {
                            print("Video saved successfully to photo library")
                            self.deleteTemporaryFile(at: videoURL)
                        } else if let error = error {
                            print("Error saving video to photo library: \(error.localizedDescription)")
                        }
                    }
                }

                private func deleteTemporaryFile(at url: URL) {
                    do {
                        try FileManager.default.removeItem(at: url)
                        print("Temporary video file deleted")
                    } catch {
                        print("Error deleting temporary video file: \(error.localizedDescription)")
                    }
                }
            }
