import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var preferredUnits: UnitSystem = .metric
    @State private var carMake = ""
    @State private var carModel = ""
    @State private var carYear = ""

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            TabView(selection: $currentPage) {
                welcomePage
                    .tag(0)
                accountCreationPage
                    .tag(1)
                unitsSelectionPage
                    .tag(2)
                carInfoPage
                    .tag(3)
                finalPage
                    .tag(4)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)
            
            VStack {
                Spacer()
                if currentPage < 4 {
                    Button(action: nextPage) {
                        Text(currentPage == 3 ? "Finish" : "Next")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 200, height: 50)
                            .background(Color.blue)
                            .cornerRadius(25)
                    }
                }
            }
            .padding(.bottom, 50)
        }
    }
    
    var welcomePage: some View {
        VStack(spacing: 20) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
            Text("Welcome to Chikane")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Text("Your personal track day companion")
                .font(.title2)
                .foregroundColor(.gray)
        }
    }
    
    var accountCreationPage: some View {
        VStack(spacing: 20) {
            Text("Create Your Account")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding()
    }
    
    var unitsSelectionPage: some View {
        VStack(spacing: 20) {
            Text("Choose Your Preferred Units")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Picker("Units", selection: $preferredUnits) {
                Text("Metric").tag(UnitSystem.metric)
                Text("Imperial").tag(UnitSystem.imperial)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
        }
    }
    
    var carInfoPage: some View {
        VStack(spacing: 20) {
            Text("Tell Us About Your Car")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            TextField("Make", text: $carMake)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            TextField("Model", text: $carModel)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            TextField("Year", text: $carYear)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
        }
        .padding()
    }
    
    var finalPage: some View {
        VStack(spacing: 20) {
            Text("You're All Set!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Get ready to enhance your track day experience with Chikane")
                .font(.title2)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Button(action: completeOnboarding) {
                Text("Start Using Chikane")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 250, height: 50)
                    .background(Color.green)
                    .cornerRadius(25)
            }
        }
        .padding()
    }
    
    func nextPage() {
        if currentPage < 4 {
            currentPage += 1
        }
    }
    
    func completeOnboarding() {
        // Here you would typically save the user's information and car details
        authManager.signUp(email: email, password: password) { result in
            switch result {
            case .success(let user):
                print("User signed up successfully: \(user.uid)")
                // Save additional user info and car details to Firestore
                saveUserInfo()
                saveCarInfo()
                UserDefaults.standard.set(preferredUnits.rawValue, forKey: "preferredUnits")
                hasCompletedOnboarding = true
            case .failure(let error):
                print("Error signing up: \(error.localizedDescription)")
                // Handle error (show alert, etc.)
            }
        }
    }
    
    func saveUserInfo() {
        // Save user info to Firestore
    }
    
    func saveCarInfo() {
        // Save car info to Firestore
    }
}