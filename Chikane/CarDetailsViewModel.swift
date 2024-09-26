//
//  CarDetailsViewModel.swift
//  Chikane
//
//  Created by Ty Mitchell on 9/22/24.
//


import SwiftUI
import Combine

class CarDetailsViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    @Published var make: String
    @Published var model: String
    @Published var year: Int
    @Published var trim: String
    @Published var horsepower: Int?
    @Published var torque: Int?
    @Published var weight: Int?
    @Published var notes: String
    
    private let car: Car
    private let authManager: AuthenticationManager
    
    init(car: Car, authManager: AuthenticationManager = .shared) {
        self.car = car
        self.authManager = authManager
        
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
        
        authManager.updateCar(updatedCar)
            .sink { completion in
                switch completion {
                case .finished:
                    print("Car updated successfully")
                case .failure(let error):
                    print("Failed to update car: \(error.localizedDescription)")
                }
            } receiveValue: { }
            .store(in: &cancellables)
    }
    
    func deleteCar() {
        authManager.deleteCar(car)
            .sink { completion in
                switch completion {
                case .finished:
                    print("Car deleted successfully")
                case .failure(let error):
                    print("Failed to delete car: \(error.localizedDescription)")
                }
            } receiveValue: { }
            .store(in: &cancellables)
    }
}
