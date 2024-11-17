import SwiftUI
import CoreLocation
import Combine
import Firebase
import FirebaseFirestore
import AVFoundation

class SessionViewModel: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var isRunning = false
    @Published private(set) var isRecording = false
    @Published private(set) var isOutLap = true
    @Published private(set) var currentLap = 0
    @Published private(set) var currentLapTime: TimeInterval = 0
    @Published private(set) var totalDistance: CLLocationDistance = 0
    @Published private(set) var currentSpeed: CLLocationSpeed = 0
    @Published private(set) var isGPSActive = false
    @Published private(set) var showFastestLapAnimation = false
    @Published private(set) var laps: [TimeInterval] = []
    @Published var remainingTime: TimeInterval
    @Published var sessionId: String?
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var weatherCondition: WeatherCondition?
    
    // MARK: - Public Properties
    let sessionName: String
    let track: Track
    let carId: String
    let car: Car?
    let duration: TimeInterval
    let userProfileViewModel: UserProfileViewModel
    let eventViewModel: EventViewModel?
    
    var formattedCurrentLapTime: String {
        formatTime(currentLapTime)
    }
    
    var bestLapTime: TimeInterval {
        laps.min() ?? 0
    }
    
    // MARK: - Private Properties
    private let sessionRecorder: SessionRecorder
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?
    
    // MARK: - Initialization
    init(sessionName: String,
         track: Track,
         carId: String,
         event: Event? = nil,
         car: Car? = nil,
         duration: TimeInterval,
         eventViewModel: EventViewModel? = nil,
         userProfileViewModel: UserProfileViewModel) {
        
        self.sessionName = sessionName
        self.track = track
        self.carId = carId
        self.car = car
        self.duration = duration
        self.remainingTime = duration
        self.eventViewModel = eventViewModel
        self.userProfileViewModel = userProfileViewModel
        
        // Initialize session recorder
        self.sessionRecorder = SessionRecorder(
            track: track,
            eventViewModel: eventViewModel,
            userProfileViewModel: userProfileViewModel,
            car: car,
            sessionName: sessionName
        )
        
        super.init()
        setupBindings()
    }
    
    // MARK: - Public Methods
    func startSession() {
        guard !isRunning else { return }
        
        isRunning = true
        sessionId = UUID().uuidString
        sessionRecorder.startRecording()
        startTimer()
        
        print("Started session: \(sessionName)")
    }
    
    func stopSession() {
        guard isRunning else { return }
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Error: No user logged in")
            return
        }
        
        isRunning = false
        stopTimer()
        sessionRecorder.stopRecording(userId: userId, carId: carId)
        
        print("Stopped session: \(sessionName)")
    }
    
    func saveAndExitSession() {
        stopSession()
    }
    
    func startRecording() {
        isRecording = true
    }
    
    func stopRecording() {
        isRecording = false
    }
    
    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 1000)
        return String(format: "%02d:%02d.%03d", minutes, seconds, milliseconds)
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        // Bind all relevant SessionRecorder properties
        sessionRecorder.$isRecording
            .receive(on: DispatchQueue.main)
            .assign(to: &$isRunning)
        
        sessionRecorder.$currentLap
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentLap)
        
        sessionRecorder.$currentLapTime
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentLapTime)
        
        sessionRecorder.$isOutLap
            .receive(on: DispatchQueue.main)
            .assign(to: &$isOutLap)
        
        sessionRecorder.$totalDistance
            .receive(on: DispatchQueue.main)
            .assign(to: &$totalDistance)
        
        sessionRecorder.$currentSpeed
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentSpeed)
        
        sessionRecorder.$isGPSActive
            .receive(on: DispatchQueue.main)
            .assign(to: &$isGPSActive)
        
        sessionRecorder.$showFastestLapAnimation
            .receive(on: DispatchQueue.main)
            .assign(to: &$showFastestLapAnimation)
        
        sessionRecorder.$lapTimes
            .receive(on: DispatchQueue.main)
            .assign(to: &$laps)
        
        sessionRecorder.$currentWeather
            .receive(on: DispatchQueue.main)
            .assign(to: &$weatherCondition)
    }
    
    private func startTimer() {
        stopTimer() // Ensure no existing timer
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateTimer() {
        guard isRunning else { return }
        
        remainingTime -= 0.1
        if remainingTime <= 0 {
            stopSession()
        }
    }
}

// MARK: - Camera Permission Handling
extension SessionViewModel {
    func checkCameraAndMicrophonePermissions() {
        checkCameraPermission { [weak self] cameraGranted in
            if cameraGranted {
                self?.checkMicrophonePermission()
            }
        }
    }
    
    private func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                completion(granted)
            }
        case .denied, .restricted:
            print("Camera access denied")
            completion(false)
        @unknown default:
            completion(false)
        }
    }
    
    private func checkMicrophonePermission() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            break
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                print("Microphone permission granted: \(granted)")
            }
        case .denied:
            print("Microphone access denied")
        @unknown default:
            break
        }
    }
}