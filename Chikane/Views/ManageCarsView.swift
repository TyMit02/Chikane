//
//  ManageCarsView.swift
//  Chikane
//
//  Created by Ty Mitchell on 9/16/24.
//


import SwiftUI
import Combine


struct ManageCarsView: View {
    @StateObject private var viewModel = ManageCarsViewModel()
    @StateObject private var trackEventsViewModel = TrackEventsViewModel()
    @State private var showingAddCar = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.edgesIgnoringSafeArea(.all)
                
                VStack {
                    if viewModel.cars.isEmpty {
                        emptyStateView
                    } else {
                        carsList
                    }
                    addCarButton
                    UpcomingEventsView()
                }
                .padding()
            }
            .navigationTitle("My Cars")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddCar = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(AppColors.accent)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddCar) {
            AddCarView(viewModel: viewModel)
        }
        .onAppear {
            viewModel.fetchCars()
        }
    }
    
    
    private var emptyStateView: some View {
           VStack(spacing: 20) {
               Image(systemName: "car")
                   .font(.system(size: 60))
                   .foregroundColor(AppColors.accent)
               Text("No cars added yet")
                   .font(AppFonts.title2)
                   .foregroundColor(AppColors.text)
               Text("Add your first car to start tracking your performance")
                   .font(AppFonts.body)
                   .foregroundColor(AppColors.lightText)
                   .multilineTextAlignment(.center)
           }
           .padding()
           .frame(maxWidth: .infinity)
           .background(AppColors.cardBackground)
           .cornerRadius(10)
       }
    
    private var carsList: some View {
           List {
               ForEach(viewModel.cars) { car in
                   NavigationLink(destination: CarDetailsView(viewModel: CarDetailsViewModel(car: car))) {
                       CarRow(car: car)
                   }
               }
               .onDelete { indexSet in
                   for index in indexSet {
                       viewModel.deleteCar(viewModel.cars[index])
                   }
               }
           }
           .listStyle(PlainListStyle())
           .background(AppColors.background)
       }
    

    
    private var addCarButton: some View {
        Button(action: { showingAddCar = true }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(AppColors.accent)
                Text("Add New Car")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.text)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppColors.cardBackground)
            .cornerRadius(10)
        }
    }
}

struct CarRow: View {
    let car: Car
    
    var body: some View {
        HStack {
            Image(systemName: "car.fill")
                .foregroundColor(AppColors.accent)
                .font(.title2)
            VStack(alignment: .leading) {
                Text("\(car.year) \(car.make) \(car.model)")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.text)
                if let trim = car.trim {
                    Text(trim)
                        .font(AppFonts.subheadline)
                        .foregroundColor(AppColors.lightText)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(AppColors.lightText)
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(10)
    }
}
