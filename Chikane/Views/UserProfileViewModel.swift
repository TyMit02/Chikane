 class UserProfileViewModel: ObservableObject {
        @Published var userProfile = Profile(id: "", email: "", username: "", trackDaysCount: 0, totalLaps: 0, bestLapTime: "--:--:--")
        @Published var cars: [Car] = []
        @Published var pushNotificationsEnabled: Bool = true
        @Published var darkModeEnabled: Bool = true
        @Published var settings = UserSettings()
        @Published var bestLapTimes: [TrackBestLap] = []
        @Published var isTestingOBD = false
        @Published var obdTestResult: String?
        
        private let supabaseService = SupabaseService.shared
        private var cancellables = Set<AnyCancellable>()
        
        @MainActor
        func fetchUserData() async {
            do {
                let profile = try await supabaseService.fetchProfile()
                self.userProfile = profile
                try await fetchBestLapTimes()
                try await fetchCars()
            } catch {
                print("Error fetching user data: \(error.localizedDescription)")
            }
        }
        
        func refreshUserData() async {
            await fetchUserData()
        }
        
        private func refreshData() {
            Task { @MainActor in
                await viewModel.fetchUserData()
            }
        }
        
        @MainActor
        func fetchCars() async throws {
            guard let userId = supabaseService.currentUser?.id.uuidString else { return }
            
            do {
                let response = try await supabaseService.supabase.database
                    .from("cars")
                    .select()
                    .eq("user_id", value: userId)
                    .execute()
                
                let jsonData = try JSONSerialization.data(withJSONObject: response.data)
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                self.cars = try decoder.decode([Car].self, from: jsonData)
            } catch {
                throw SupabaseError.networkError(error)
            }
        }
        
        @MainActor
        func fetchBestLapTimes() async throws {
            guard let userId = supabaseService.currentUser?.id.uuidString else { return }
            
            do {
                let response = try await supabaseService.supabase.database
                    .from("leaderboards")
                    .select("track_id, tracks!inner(name), lap_time")
                    .eq("user_id", value: userId)
                    .order("lap_time", ascending: true)
                    .execute()
                
                let jsonData = try JSONSerialization.data(withJSONObject: response.data)
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                
                let leaderboardEntries = try decoder.decode([LeaderboardEntry].self, from: jsonData)
                self.bestLapTimes = leaderboardEntries.map { entry in
                    TrackBestLap(
                        trackId: entry.trackId,
                        trackName: entry.track.name,
                        bestLapTime: entry.lapTime
                    )
                }
            } catch {
                throw SupabaseError.networkError(error)
            }
        }
        
        func updateBestLapTime(trackId: String, trackName: String, lapTime: TimeInterval) {
            Task {
                do {
                    guard let userId = supabaseService.currentUser?.id.uuidString,
                          let carId = cars.first?.id else { return }
                    
                    // Update the leaderboard entry
                    let leaderboardEntry = PostgresInsert([
                        "track_id": trackId,
                        "user_id": userId,
                        "car_id": carId,
                        "lap_time": lapTime
                    ])
                    
                    try await supabaseService.supabase.database
                        .from("leaderboards")
                        .upsert(leaderboardEntry)
                        .execute()
                    
                    await MainActor.run {
                        try? await fetchBestLapTimes()
                    }
                } catch {
                    print("Error updating best lap time: \(error.localizedDescription)")
                }
            }
        }
        
        func updateProfile(username: String) {
            Task {
                do {
                    var updatedProfile = userProfile
                    updatedProfile.username = username
                    try await supabaseService.updateProfile(updatedProfile)
                    await MainActor.run {
                        self.userProfile = updatedProfile
                    }
                } catch {
                    print("Error updating profile: \(error.localizedDescription)")
                }
            }
        }
        
        func addCar(_ car: Car) {
            Task {
                do {
                    guard let userId = supabaseService.currentUser?.id.uuidString else { return }
                    
                    let carData = PostgresInsert([
                        "user_id": userId,
                        "make": car.make,
                        "model": car.model,
                        "year": car.year,
                        "trim": car.trim as Any,
                        "horsepower": car.horsepower as Any,
                        "weight": car.weight as Any,
                        "torque": car.torque as Any,
                        "notes": car.notes as Any
                    ])
                    
                    try await supabaseService.supabase.database
                        .from("cars")
                        .insert(carData)
                        .execute()
                    
                    await MainActor.run {
                        try? await self.fetchCars()
                    }
                } catch {
                    print("Error adding car: \(error.localizedDescription)")
                }
            }
        }
        
        func updateSettings() {
            if let encoded = try? JSONEncoder().encode(settings) {
                UserDefaults.standard.set(encoded, forKey: "userSettings")
            }
        }
        
        func updatePreferredUnits(_ units: UnitSystem) {
            settings.preferredUnits = units
            updateSettings()
        }
        
        @MainActor
        func deleteAccount() async {
            do {
                guard let userId = supabaseService.currentUser?.id.uuidString else { return }
                
                // Delete all user related data
                try await supabaseService.supabase.database
                    .from("cars")
                    .delete()
                    .eq("user_id", value: userId)
                    .execute()
                
                try await supabaseService.supabase.database
                    .from("leaderboards")
                    .delete()
                    .eq("user_id", value: userId)
                    .execute()
                
                try await supabaseService.supabase.database
                    .from("profiles")
                    .delete()
                    .eq("id", value: userId)
                    .execute()
                
                try await supabaseService.supabase.auth.signOut()
            } catch {
                print("Error deleting account: \(error.localizedDescription)")
            }
        }
        
        func signOut() async {
            do {
                try await supabaseService.signOut()
            } catch {
                print("Error signing out: \(error.localizedDescription)")
            }
        }
        
        private func formatTime(_ time: TimeInterval) -> String {
            let minutes = Int(time) / 60
            let seconds = Int(time) % 60
            let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 1000)
            return String(format: "%d:%02d.%03d", minutes, seconds, milliseconds)
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
            NavigationStack {
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