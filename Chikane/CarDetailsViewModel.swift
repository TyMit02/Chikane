//
//  CarDetailsViewModel.swift
//  Chikane
//
//  Created by Ty Mitchell on 9/22/24.
//


import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

class CarDetailsViewModel: ObservableObject {
    @Published var make: String
    @Published var model: String
    @Published var year: Int
    @Published var trim: String
    @Published var horsepower: Int?
    @Published var torque: Int?
    @Published var weight: Int?
    @Published var notes: String
    
    private let car: Car
    private let db = Firestore.firestore()
    
    init(car: Car) {
        self.car = car
        self.make = car.make
        self.model = car.model
        self.year = car.year
        self.trim = car.trim ?? ""
        self.horsepower = car.horsepower
        self.torque = car.torque
        self.weight = car.weight
        self.notes = car.notes ?? ""
    }
    
    func saveCar() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Error: No user logged in")
            return
        }

        let updatedCar = Car(
            id: car.id,
            make: make,
            model: model,
            year: year,
            trim: trim.isEmpty ? nil : trim,
            horsepower: horsepower,
            weight: weight,
            torque: torque,
            notes: notes.isEmpty ? nil : notes
        )
        
        let carData: [String: Any] = [
            "make": updatedCar.make,
            "model": updatedCar.model,
            "year": updatedCar.year,
            "trim": updatedCar.trim as Any,
            "horsepower": updatedCar.horsepower as Any,
            "weight": updatedCar.weight as Any,
            "torque": updatedCar.torque as Any,
            "notes": updatedCar.notes as Any
        ]
        
        db.collection("users").document(userId).collection("cars").document(updatedCar.id).setData(carData, merge: true) { error in
            if let error = error {
                print("Error saving car: \(error.localizedDescription)")
            } else {
                print("Car successfully saved with ID: \(updatedCar.id)")
            }
        }
    }
    
    func deleteCar() {
        db.collection("cars").document(car.id).delete { error in
            if let error = error {
                print("Error deleting car: \(error.localizedDescription)")
            } else {
                print("Car successfully deleted")
            }
        }
    }
}
