//
//  ManageCarsViewModel.swift
//  Chikane
//
//  Created by Ty Mitchell on 9/21/24.
//

import SwiftUI
import Combine

  class ManageCarsViewModel: ObservableObject {
        @Published var cars: [Car] = []
        
        private let authManager = AuthenticationManager.shared
        private var cancellables = Set<AnyCancellable>()
        
        func fetchCars() {
            authManager.fetchCars()
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    if case .failure(let error) = completion {
                        print("Error fetching cars: \(error.localizedDescription)")
                    }
                } receiveValue: { [weak self] cars in
                    self?.cars = cars
                }
                .store(in: &cancellables)
        }
        
        func addCar(_ car: Car) {
            authManager.addCar(car)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    if case .failure(let error) = completion {
                        print("Error adding car: \(error.localizedDescription)")
                    }
                } receiveValue: { [weak self] in
                    self?.fetchCars()
                }
                .store(in: &cancellables)
        }
        
        
        func deleteCar(_ car: Car) {
            // In a real app, you'd implement this method to delete the car from Firestore
            // For now, we'll just remove it from the local array
            cars.removeAll { $0.id == car.id }
        }
    }
