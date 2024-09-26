//
//  AuthenticationManager.swift
//  Chikane
//
//  Created by Ty Mitchell on 9/16/24.
//


import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import Combine

class AuthenticationManager: ObservableObject {
    @Published var user: User?
    static let shared = AuthenticationManager()
    private let db = Firestore.firestore()
    var cancellables = Set<AnyCancellable>()
    
    private init() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
        }
    }
    
    func signIn(email: String, password: String) -> AnyPublisher<User, Error> {
            Future { promise in
                Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                    if let user = authResult?.user {
                        promise(.success(user))
                    } else if let error = error {
                        promise(.failure(error))
                    }
                }
            }.eraseToAnyPublisher()
        }
    
    func signUp(email: String, password: String, username: String) -> AnyPublisher<User, Error> {
           Future { [weak self] promise in
               Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                   if let user = authResult?.user {
                       self?.createUserProfile(user: user, username: username)
                           .sink(receiveCompletion: { completion in
                               if case let .failure(error) = completion {
                                   promise(.failure(error))
                               }
                           }, receiveValue: { _ in
                               promise(.success(user))
                           })
                           .store(in: &self!.cancellables)
                   } else if let error = error {
                       promise(.failure(error))
                   }
               }
           }.eraseToAnyPublisher()
       }
    
    private func createUserProfile(user: User, username: String) -> AnyPublisher<Void, Error> {
           Future { [weak self] promise in
               guard let self = self else { return }
               let userData: [String: Any] = [
                   "username": username,
                   "email": user.email ?? "",
                   "createdAt": FieldValue.serverTimestamp(),
                   "trackDaysCount": 0,
                   "bestLapTime": "--:--:--",
                   "totalLaps": 0
               ]
               
               self.db.collection("users").document(user.uid).setData(userData) { error in
                   if let error = error {
                       promise(.failure(error))
                   } else {
                       promise(.success(()))
                   }
               }
           }.eraseToAnyPublisher()
       }
    
    func addEventToUserProfile(eventId: String, completion: @escaping (Result<Void, Error>) -> Void) {
            guard let userId = Auth.auth().currentUser?.uid else {
                completion(.failure(NSError(domain: "AuthenticationManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])))
                return
            }
            
            let userRef = db.collection("users").document(userId)
            
            userRef.updateData([
                "participatingEvents": FieldValue.arrayUnion([eventId])
            ]) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    
    func fetchUserData(completion: @escaping (Result<UserProfile, Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])))
            return
        }
        
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                completion(.failure(error))
            } else if let document = document, document.exists {
                do {
                    let userProfile = try document.data(as: UserProfile.self)
                    completion(.success(userProfile))
                } catch {
                    completion(.failure(error))
                }
            } else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User document does not exist"])))
            }
        }
    }
    
    func updateUserProfile(_ userProfile: UserProfile, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])))
            return
        }
        
        do {
            try db.collection("users").document(userId).setData(from: userProfile) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func signOut() {
            do {
                try Auth.auth().signOut()
            } catch {
                print("Error signing out: \(error.localizedDescription)")
            }
        }
    
    func addCar(_ car: Car, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "AuthenticationManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])))
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("cars").addDocument(data: [
            "id": car.id,
            "make": car.make,
            "model": car.model,
            "year": car.year,
            "trim": car.trim ?? NSNull()
        ]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func fetchCars(completion: @escaping (Result<[Car], Error>) -> Void) {
            guard let userId = Auth.auth().currentUser?.uid else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])))
                return
            }
            
            db.collection("users").document(userId).collection("cars").getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                } else if let snapshot = snapshot {
                    let cars = snapshot.documents.compactMap { try? $0.data(as: Car.self) }
                    completion(.success(cars))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No cars found"])))
                }
            }
        }

    func fetchCarsPublisher() -> AnyPublisher<[Car], Error> {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No user logged in when trying to fetch cars")
            return Fail(error: NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
                .eraseToAnyPublisher()
        }
        
        print("Fetching cars for user: \(userId)")
        
        return Future<[Car], Error> { promise in
            let carsRef = self.db.collection("users").document(userId).collection("cars")
            print("Querying Firestore path: \(carsRef.path)")
            
            carsRef.getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching cars: \(error.localizedDescription)")
                    promise(.failure(error))
                } else if let snapshot = snapshot {
                    print("Firestore query successful. Document count: \(snapshot.documents.count)")
                    let cars = snapshot.documents.compactMap { document -> Car? in
                        do {
                            let car = try document.data(as: Car.self)
                            print("Successfully decoded car: \(car.make) \(car.model)")
                            return car
                        } catch {
                            print("Error decoding car document: \(error.localizedDescription)")
                            print("Document data: \(document.data())")
                            return nil
                        }
                    }
                    print("Fetched and decoded \(cars.count) cars from Firestore")
                    promise(.success(cars))
                } else {
                    print("No snapshot returned from Firestore query")
                    promise(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No cars found"])))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func updateCar(_ car: Car) -> AnyPublisher<Void, Error> {
            guard let userId = Auth.auth().currentUser?.uid else {
                return Fail(error: NSError(domain: "AuthenticationManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user logged in"]))
                    .eraseToAnyPublisher()
            }
            
            return Future<Void, Error> { promise in
                do {
                    try self.db.collection("users").document(userId).collection("cars").document(car.id).setData(from: car) { error in
                        if let error = error {
                            promise(.failure(error))
                        } else {
                            promise(.success(()))
                        }
                    }
                } catch {
                    promise(.failure(error))
                }
            }.eraseToAnyPublisher()
        }
    func deleteCar(_ car: Car) -> AnyPublisher<Void, Error> {
            guard let userId = Auth.auth().currentUser?.uid else {
                return Fail(error: NSError(domain: "AuthenticationManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user logged in"]))
                    .eraseToAnyPublisher()
            }
            
            return Future<Void, Error> { promise in
                self.db.collection("users").document(userId).collection("cars").document(car.id).delete { error in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success(()))
                    }
                }
            }.eraseToAnyPublisher()
        }
}

struct UserProfile: Codable {
    var username: String
    var email: String
    var trackDaysCount: Int
    var bestLapTime: String
    var totalLaps: Int
    var participatingEvents: [String]?  // Change this to be optional
    
    enum CodingKeys: String, CodingKey {
        case username, email, trackDaysCount, bestLapTime, totalLaps, participatingEvents
    }
    
    init(username: String, email: String, trackDaysCount: Int, bestLapTime: String, totalLaps: Int, participatingEvents: [String]? = nil) {
        self.username = username
        self.email = email
        self.trackDaysCount = trackDaysCount
        self.bestLapTime = bestLapTime
        self.totalLaps = totalLaps
        self.participatingEvents = participatingEvents
    }
}

struct Car: Identifiable, Codable {
    let id: String
    let make: String
    let model: String
    let year: Int
    let trim: String?
    let horsepower: Int?
    let weight: Int?
    let torque: Int?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case make
        case model
        case year
        case trim
        case horsepower
        case weight
        case torque
        case notes
    }

    init(id: String = UUID().uuidString, make: String, model: String, year: Int, trim: String?, horsepower: Int?, weight: Int?, torque: Int?, notes: String?) {
        self.id = id
        self.make = make
        self.model = model
        self.year = year
        self.trim = trim
        self.horsepower = horsepower
        self.weight = weight
        self.torque = torque
        self.notes = notes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        make = try container.decode(String.self, forKey: .make)
        model = try container.decode(String.self, forKey: .model)
        year = try container.decode(Int.self, forKey: .year)
        trim = try container.decodeIfPresent(String.self, forKey: .trim)
        horsepower = try container.decodeIfPresent(Int.self, forKey: .horsepower)
        weight = try container.decodeIfPresent(Int.self, forKey: .weight)
        torque = try container.decodeIfPresent(Int.self, forKey: .torque)
        notes = (try container.decodeIfPresent(String.self, forKey: .notes))
    }
}
class CarDatabase {
    static let shared = CarDatabase()
    private let db = Firestore.firestore()
    private let baseURL = "https://vpic.nhtsa.dot.gov/api/vehicles"
    private var makeCache: [String] = []
    private var modelCache: [String: [String]] = [:]
    
    private init() {}
    
    func fetchMakes(startingWith prefix: String = "", limit: Int = 20, completion: @escaping (Result<[String], Error>) -> Void) {
        if !makeCache.isEmpty {
            let filteredMakes = makeCache.filter { $0.lowercased().hasPrefix(prefix.lowercased()) }
            completion(.success(Array(filteredMakes.prefix(limit))))
            return
        }
        
        let urlString = "\(baseURL)/GetAllMakes?format=json"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 0, userInfo: nil)))
                return
            }
            
            do {
                let result = try JSONDecoder().decode(MakeResponse.self, from: data)
                let makes = result.Results.map { $0.Make_Name }
                self?.makeCache = makes
                let filteredMakes = makes.filter { $0.lowercased().hasPrefix(prefix.lowercased()) }
                completion(.success(Array(filteredMakes.prefix(limit))))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func fetchModels(for make: String, year: Int, startingWith prefix: String = "", limit: Int = 20, completion: @escaping (Result<[String], Error>) -> Void) {
        let cacheKey = "\(make)-\(year)"
        if let cachedModels = modelCache[cacheKey] {
            let filteredModels = cachedModels.filter { $0.lowercased().hasPrefix(prefix.lowercased()) }
            completion(.success(Array(filteredModels.prefix(limit))))
            return
        }
        
        let urlString = "\(baseURL)/GetModelsForMakeYear/make/\(make)/modelyear/\(year)?format=json"
        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 0, userInfo: nil)))
                return
            }
            
            do {
                let result = try JSONDecoder().decode(ModelResponse.self, from: data)
                let models = result.Results.map { $0.Model_Name }
                self?.modelCache[cacheKey] = models
                let filteredModels = models.filter { $0.lowercased().hasPrefix(prefix.lowercased()) }
                completion(.success(Array(filteredModels.prefix(limit))))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

struct MakeResponse: Codable {
    let Results: [MakeResult]
}

struct MakeResult: Codable {
    let Make_ID: Int
    let Make_Name: String
}

struct ModelResponse: Codable {
    let Results: [ModelResult]
}

struct ModelResult: Codable {
    let Make_ID: Int
    let Make_Name: String
    let Model_ID: Int
    let Model_Name: String
}
