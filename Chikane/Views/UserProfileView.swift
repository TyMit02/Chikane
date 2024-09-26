//
//  UserProfileView.swift
//  Chikane
//
//  Created by Ty Mitchell on 9/16/24.
//


import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseAuth
import Firebase



struct UserProfileView: View {
    @StateObject private var viewModel = UserProfileViewModel()
    @StateObject private var carsViewModel = ManageCarsViewModel()
    @State private var isEditingProfile = false
    @State private var isAddingCar = false
    @State private var showingSessionHistory = false
    @State private var showingDeleteAccountAlert = false
    
    var body: some View {
        ZStack {
            AppColors.background.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 30) {
                    profileHeader
                    statsSection
                    sessionHistoryButton
                    carsSection
                        .onAppear{
                            viewModel.fetchUserData()
                        }
                    settingsSection
                    deleteAccountButton
                    signOutButton
                }
                .padding()
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditingProfile ? "Done" : "Edit") {
                    isEditingProfile.toggle()
                }
                .foregroundColor(AppColors.accent)
            }
        }
        .sheet(isPresented: $isEditingProfile) {
            EditProfileView(viewModel: viewModel)
        }
        .sheet(isPresented: $isAddingCar) {
            AddCarView(viewModel: carsViewModel)
        }
        .sheet(isPresented: $showingSessionHistory) {
            SessionHistoryView()
        }
        .alert(isPresented: $showingDeleteAccountAlert) {
            Alert(
                title: Text("Delete Account"),
                message: Text("Are you sure you want to delete your account? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    viewModel.deleteAccount()
                },
                secondaryButton: .cancel()
            )
        }
        .onAppear {
            viewModel.fetchUserData()
        }
    }
    
    private var profileHeader: some View {
            VStack {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(AppColors.accent)
                
                Text(viewModel.userProfile.username)
                    .font(AppFonts.title2)
                    .foregroundColor(AppColors.text)
                
                Text(viewModel.userProfile.email)
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.lightText)
            }
        }
        
        private var statsSection: some View {
            VStack(alignment: .leading, spacing: 15) {
                Text("Stats")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.text)
                
                HStack {
                    statItem(title: "Track Days", value: "\(viewModel.userProfile.trackDaysCount)")
                    statItem(title: "Best Lap", value: viewModel.userProfile.bestLapTime)
                    statItem(title: "Total Laps", value: "\(viewModel.userProfile.totalLaps)")
                }
            }
            .padding()
            .background(AppColors.cardBackground)
            .cornerRadius(10)
        }
        
        private func statItem(title: String, value: String) -> some View {
            VStack {
                Text(value)
                    .font(AppFonts.title3)
                    .foregroundColor(AppColors.accent)
                Text(title)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.lightText)
            }
            .frame(maxWidth: .infinity)
        }
        
        private var sessionHistoryButton: some View {
            Button(action: { showingSessionHistory = true }) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(AppColors.accent)
                    Text("Session History")
                        .font(AppFonts.headline)
                        .foregroundColor(AppColors.text)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppColors.lightText)
                }
                .padding()
                .background(AppColors.cardBackground)
                .cornerRadius(10)
            }
        }
        
    private var carsSection: some View {
            VStack(alignment: .leading, spacing: 15) {
                Text("My Cars")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.text)
                
                if viewModel.cars.isEmpty {
                    Text("No cars added yet. Add your first car to get started!")
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.lightText)
                } else {
                    ForEach(viewModel.cars) { car in
                        HStack {
                            Image(systemName: "car.fill")
                                .foregroundColor(AppColors.accent)
                            Text("\(car.year) \(car.make) \(car.model)")
                                .font(AppFonts.subheadline)
                                .foregroundColor(AppColors.text)
                        }
                    }
                }
                Button(action: { isAddingCar = true }) {
                    Text("Add Car")
                        .font(AppFonts.subheadline)
                        .foregroundColor(AppColors.accent)
                }
            }
            .padding()
            .background(AppColors.cardBackground)
            .cornerRadius(10)
        }
        
        private var settingsSection: some View {
            VStack(alignment: .leading, spacing: 15) {
                Text("Settings")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.text)
                
//                Toggle("Push Notifications", isOn: $viewModel.pushNotificationsEnabled)
//                    .toggleStyle(SwitchToggleStyle(tint: AppColors.accent))
                
//                Toggle("Dark Mode", isOn: $viewModel.darkModeEnabled)
//                    .toggleStyle(SwitchToggleStyle(tint: AppColors.accent))
            }
            .padding()
            .background(AppColors.cardBackground)
            .cornerRadius(10)
        }
        
        private var deleteAccountButton: some View {
            Button(action: { showingDeleteAccountAlert = true }) {
                Text("Delete Account")
                    .font(AppFonts.headline)
                    .foregroundColor(.red)
                    .frame(height: 55)
                    .frame(maxWidth: .infinity)
                    .background(AppColors.cardBackground)
                    .cornerRadius(10)
            }
        }
        
        private var signOutButton: some View {
            Button(action: viewModel.signOut) {
                Text("Sign Out")
                    .font(AppFonts.headline)
                    .foregroundColor(.white)
                    .frame(height: 55)
                    .frame(maxWidth: .infinity)
                    .background(AppColors.accent)
                    .cornerRadius(10)
            }
        }
    }

class UserProfileViewModel: ObservableObject {
    @Published var userProfile = UserProfile(username: "", email: "", trackDaysCount: 0, bestLapTime: "--:--:--", totalLaps: 0)
    @Published var cars: [Car] = []
    @Published var pushNotificationsEnabled: Bool = true
    @Published var darkModeEnabled: Bool = true
    @Published var settings = UserSettings()
    
    private let authManager = AuthenticationManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    func fetchUserData() {
        authManager.fetchUserData { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let userProfile):
                    self?.userProfile = userProfile
                case .failure(let error):
                    print("Error fetching user data: \(error.localizedDescription)")
                }
            }
        }
        
        fetchCars()
    }
    
    func fetchCars() {
           authManager.fetchCarsPublisher()
               .receive(on: DispatchQueue.main)
               .sink { completion in
                   if case .failure(let error) = completion {
                       print("Error fetching cars: \(error.localizedDescription)")
                   }
               } receiveValue: { [weak self] cars in
                   self?.cars = cars
                   print("Fetched \(cars.count) cars in UserProfileViewModel")
               }
               .store(in: &cancellables)
       }
   
    func fetchSettings() {
        authManager.fetchSettings()
            .sink { completion in
                if case .failure(let error) = completion {
                    print("Error fetching settings: \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] settings in
                self?.settings = settings
            }
            .store(in: &cancellables)
    }
    
    func addCar(_ car: Car) {
           authManager.addCar(car) { [weak self] result in
               DispatchQueue.main.async {
                   switch result {
                   case .success():
                       self?.fetchCars()
                   case .failure(let error):
                       print("Error adding car: \(error.localizedDescription)")
                   }
               }
           }
       }
       
       func updateProfile(username: String) {
           var updatedProfile = userProfile
           updatedProfile.username = username
           
           authManager.updateUserProfile(updatedProfile) { [weak self] result in
               DispatchQueue.main.async {
                   switch result {
                   case .success():
                       self?.userProfile = updatedProfile
                   case .failure(let error):
                       print("Error updating profile: \(error.localizedDescription)")
                   }
               }
           }
       }
       
    func updateSettings() {
        authManager.updateSettings(settings)
            .sink { completion in
                if case .failure(let error) = completion {
                    print("Error updating settings: \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] updatedSettings in
                self?.settings = updatedSettings
            }
            .store(in: &cancellables)
    }
    
    func deleteAccount() {
        authManager.deleteAccount()
            .sink { completion in
                if case .failure(let error) = completion {
                    print("Error deleting account: \(error.localizedDescription)")
                }
            } receiveValue: { _ in
                // Handle successful account deletion (e.g., navigate to login screen)
            }
            .store(in: &cancellables)
    }
    
    func signOut() {
        authManager.signOut()
        // Handle post-signout (e.g., navigate to login screen)
    }
}

struct EditProfileView: View {
    @ObservedObject var viewModel: UserProfileViewModel
    @State private var username: String
    @Environment(\.presentationMode) var presentationMode
    
    init(viewModel: UserProfileViewModel) {
        self.viewModel = viewModel
        _username = State(initialValue: viewModel.userProfile.username)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Information")) {
                    TextField("Username", text: $username)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarItems(
                leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() },
                trailing: Button("Save") {
                    viewModel.updateProfile(username: username)
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct AddCarView: View {
    @ObservedObject var viewModel: ManageCarsViewModel
    @State private var selectedMake: String = ""
    @State private var selectedModel: String = ""
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var makeSearchText: String = ""
    @State private var modelSearchText: String = ""
    @State private var makes: [String] = []
    @State private var models: [String] = []
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var selectedHorsepower: String = ""
    @State private var selectedWeight: String = ""
    @State private var selectedTorque: String = ""
    @State private var selectedNotes: String = ""
    @State private var selectedTrim : String = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            AppColors.background.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    makeSection
                    if !selectedMake.isEmpty {
                        modelSection
                    }
                    yearSection
                    saveButton
                }
                .padding()
            }
        }
        .navigationTitle("Add Car")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }
            .foregroundColor(AppColors.accent)
        )
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Invalid Input"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .onAppear {
            fetchMakes()
        }
    }
    
    private var makeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Make")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.text)
            
            CustomTextField(
                icon: "magnifyingglass",
                placeholder: "Search Make",
                text: $makeSearchText
            )
            .onChange(of: makeSearchText) { _ in fetchMakes() }
            
            Picker("Make", selection: $selectedMake) {
                Text("Select Make").tag("")
                ForEach(makes, id: \.self) { make in
                    Text(make).tag(make)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .onChange(of: selectedMake) { _ in
                selectedModel = ""
                modelSearchText = ""
                if !selectedMake.isEmpty { fetchModels() }
            }
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(10)
    }
    
    private var modelSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Model")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.text)
            
            CustomTextField(
                icon: "magnifyingglass",
                placeholder: "Search Model",
                text: $modelSearchText
            )
            .onChange(of: modelSearchText) { _ in fetchModels() }
            
            Picker("Model", selection: $selectedModel) {
                Text("Select Model").tag("")
                ForEach(models, id: \.self) { model in
                    Text(model).tag(model)
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(10)
    }
    
    private var yearSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Year")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.text)
            
            Picker("Year", selection: $selectedYear) {
                ForEach((1900...Calendar.current.component(.year, from: Date())).reversed(), id: \.self) { year in
                    Text(String(year)).tag(year)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .onChange(of: selectedYear) { _ in
                if !selectedMake.isEmpty { fetchModels() }
            }
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(10)
    }
    
    private var saveButton: some View {
        Button(action: {
            if validateInput() {
                let newCar = Car(
                    id: UUID().uuidString,
                    make: selectedMake,
                    model: selectedModel,
                    year: selectedYear,
                    trim: selectedTrim.isEmpty ? nil : selectedTrim,  // Add trim if available
                    horsepower: selectedHorsepower.isEmpty ? nil : Int(selectedHorsepower),  // Convert if needed
                    weight: selectedWeight.isEmpty ? nil : Int(selectedWeight),  // Convert if needed
                    torque: selectedTorque.isEmpty ? nil : Int(selectedTorque),  // Convert if needed
                    notes: selectedNotes.isEmpty ? nil : selectedNotes // Optional notes
                )
                viewModel.addCar(newCar)
                presentationMode.wrappedValue.dismiss()
            } else {
                showAlert = true
            }
        }) {
            Text("Save Car")
                .font(AppFonts.headline)
                .foregroundColor(.white)
                .frame(height: 55)
                .frame(maxWidth: .infinity)
                .background(AppColors.accent)
                .cornerRadius(10)
        }
    }
    
    private func fetchMakes() {
        CarDatabase.shared.fetchMakes(startingWith: makeSearchText, limit: 50) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let fetchedMakes):
                    self.makes = fetchedMakes
                case .failure(let error):
                    print("Error fetching makes: \(error.localizedDescription)")
                    self.alertMessage = "Failed to fetch makes. Please try again."
                    self.showAlert = true
                }
            }
        }
    }
    
    private func fetchModels() {
        CarDatabase.shared.fetchModels(for: selectedMake, year: selectedYear, startingWith: modelSearchText, limit: 50) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let fetchedModels):
                    self.models = fetchedModels
                case .failure(let error):
                    print("Error fetching models: \(error.localizedDescription)")
                    self.alertMessage = "Failed to fetch models. Please try again."
                    self.showAlert = true
                }
            }
        }
    }
    
    private func validateInput() -> Bool {
        if selectedMake.isEmpty {
            alertMessage = "Please select a make."
                        return false
                    }
                    if selectedModel.isEmpty {
                        alertMessage = "Please select a model."
                        return false
                    }
                    return true
                }
            }


            struct UserSettings: Codable, Equatable {
                var pushNotificationsEnabled: Bool = true
                var darkModeEnabled: Bool = true
                var preferredUnits: UnitSystem = .metric
                var autoDetectLaps: Bool = true
                var voiceAnnouncementsEnabled: Bool = false
                var dataRefreshFrequency: DataRefreshFrequency = .thirty
                var shareDataWithFriends: Bool = false
                var allowAnonymousUsageData: Bool = true
            }

            enum UnitSystem: String, Codable {
                case metric, imperial
            }

            enum DataRefreshFrequency: String, Codable {
                case fifteen, thirty, hourly
            }



extension AuthenticationManager {
    func fetchUserProfile() -> AnyPublisher<UserProfile, Error> {
        guard let userId = Auth.auth().currentUser?.uid else {
            return Fail(error: NSError(domain: "AuthenticationManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user logged in"]))
                .eraseToAnyPublisher()
        }
        
        let db = Firestore.firestore()
        return Future<UserProfile, Error> { promise in
            db.collection("users").document(userId).getDocument { snapshot, error in
                if let error = error {
                    promise(.failure(error))
                    return
                }
                
                guard let data = snapshot?.data() else {
                    promise(.failure(NSError(domain: "AuthenticationManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "User data not found"])))
                    return
                }
                
                let userProfile = UserProfile(
                    username: data["username"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    trackDaysCount: data["trackDaysCount"] as? Int ?? 0,
                    bestLapTime: data["bestLapTime"] as? String ?? "--:--:--",
                    totalLaps: data["totalLaps"] as? Int ?? 0
                )
                promise(.success(userProfile))
            }
        }.eraseToAnyPublisher()
    }
    
    func fetchCars() -> AnyPublisher<[Car], Error> {
        guard let userId = Auth.auth().currentUser?.uid else {
            return Fail(error: NSError(domain: "AuthenticationManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user logged in"]))
                .eraseToAnyPublisher()
        }
        
        let db = Firestore.firestore()
        return Future<[Car], Error> { promise in
            db.collection("users").document(userId).collection("cars").getDocuments { snapshot, error in
                if let error = error {
                    promise(.failure(error))
                    return
                }
                
                let cars = snapshot?.documents.compactMap { document -> Car? in
                    let data = document.data()
                    guard let make = data["make"] as? String,
                          let model = data["model"] as? String,
                          let year = data["year"] as? Int else {
                        return nil
                    }
                    let trim = data["trim"] as? String
                    let horsepower = data["horsepower"] as? Int
                    let weight = data["weight"] as? Int
                    let torque = data["torque"] as? Int
                    let notes = data["notes"] as? String
                    return Car(id: document.documentID, make: make, model: model, year: year, trim: trim, horsepower: horsepower, weight: weight, torque: torque, notes: notes)
                } ?? []
                
                promise(.success(cars))
            }
        }.eraseToAnyPublisher()
    }
    
    func fetchSettings() -> AnyPublisher<UserSettings, Error> {
        guard let userId = Auth.auth().currentUser?.uid else {
            return Fail(error: NSError(domain: "AuthenticationManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user logged in"]))
                .eraseToAnyPublisher()
        }
        
        let db = Firestore.firestore()
        return Future<UserSettings, Error> { promise in
            db.collection("users").document(userId).collection("settings").document("userSettings").getDocument { snapshot, error in
                if let error = error {
                    promise(.failure(error))
                    return
                }
                
                guard let data = snapshot?.data() else {
                    // If no settings document exists, return default settings
                    promise(.success(UserSettings()))
                    return
                }
                
                let settings = UserSettings(
                    pushNotificationsEnabled: data["pushNotificationsEnabled"] as? Bool ?? true,
                    darkModeEnabled: data["darkModeEnabled"] as? Bool ?? true,
                    preferredUnits: UnitSystem(rawValue: data["preferredUnits"] as? String ?? "metric") ?? .metric,
                    autoDetectLaps: data["autoDetectLaps"] as? Bool ?? true,
                    voiceAnnouncementsEnabled: data["voiceAnnouncementsEnabled"] as? Bool ?? false,
                    dataRefreshFrequency: DataRefreshFrequency(rawValue: data["dataRefreshFrequency"] as? String ?? "thirty") ?? .thirty,
                    shareDataWithFriends: data["shareDataWithFriends"] as? Bool ?? false,
                    allowAnonymousUsageData: data["allowAnonymousUsageData"] as? Bool ?? true
                )
                promise(.success(settings))
            }
        }.eraseToAnyPublisher()
    }
    
    func updateProfile(username: String) -> AnyPublisher<UserProfile, Error> {
        guard let userId = Auth.auth().currentUser?.uid else {
            return Fail(error: NSError(domain: "AuthenticationManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user logged in"]))
                .eraseToAnyPublisher()
        }
        
        let db = Firestore.firestore()
        return Future<UserProfile, Error> { promise in
            db.collection("users").document(userId).updateData(["username": username]) { error in
                if let error = error {
                    promise(.failure(error))
                    return
                }
                
                // Fetch the updated profile
                self.fetchUserProfile()
                    .sink(receiveCompletion: { completion in
                        if case let .failure(error) = completion {
                            promise(.failure(error))
                        }
                    }, receiveValue: { updatedProfile in
                        promise(.success(updatedProfile))
                    })
                    .store(in: &self.cancellables)
            }
        }.eraseToAnyPublisher()
    }
    
    func addCar(_ car: Car) -> AnyPublisher<Void, Error> {
        guard let userId = Auth.auth().currentUser?.uid else {
            return Fail(error: NSError(domain: "AuthenticationManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user logged in"]))
                .eraseToAnyPublisher()
        }
        
        let db = Firestore.firestore()
        return Future<Void, Error> { promise in
            db.collection("users").document(userId).collection("cars").addDocument(data: [
                "make": car.make,
                "model": car.model,
                "year": car.year,
                "trim": car.trim ?? NSNull()
            ]) { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func updateSettings(_ settings: UserSettings) -> AnyPublisher<UserSettings, Error> {
        guard let userId = Auth.auth().currentUser?.uid else {
            return Fail(error: NSError(domain: "AuthenticationManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user logged in"]))
                .eraseToAnyPublisher()
        }
        
        let db = Firestore.firestore()
        return Future<UserSettings, Error> { promise in
            let data: [String: Any] = [
                "pushNotificationsEnabled": settings.pushNotificationsEnabled,
                "darkModeEnabled": settings.darkModeEnabled,
                "preferredUnits": settings.preferredUnits.rawValue,
                "autoDetectLaps": settings.autoDetectLaps,
                "voiceAnnouncementsEnabled": settings.voiceAnnouncementsEnabled,
                "dataRefreshFrequency": settings.dataRefreshFrequency.rawValue,
                "shareDataWithFriends": settings.shareDataWithFriends,
                "allowAnonymousUsageData": settings.allowAnonymousUsageData
            ]
            
            db.collection("users").document(userId).collection("settings").document("userSettings").setData(data, merge: true) { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(settings))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func deleteAccount() -> AnyPublisher<Void, Error> {
        guard let user = Auth.auth().currentUser else {
            return Fail(error: NSError(domain: "AuthenticationManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user logged in"]))
                .eraseToAnyPublisher()
        }
        
        let db = Firestore.firestore()
        return Future<Void, Error> { promise in
            // Delete user data from Firestore
            db.collection("users").document(user.uid).delete { error in
                if let error = error {
                    promise(.failure(error))
                    return
                }
                
                // Delete the user account
                user.delete { error in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success(()))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }
}
