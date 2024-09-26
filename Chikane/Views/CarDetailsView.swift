//
//  CarDetailsView.swift
//  Chikane
//
//  Created by Ty Mitchell on 9/22/24.
//


import SwiftUI

struct CarDetailsView: View {
    @ObservedObject var viewModel: CarDetailsViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            AppColors.background.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    carInfoSection
                    performanceSection
                    notesSection
                    deleteButton
                }
                .padding()
            }
        }
        .navigationTitle("Car Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    viewModel.saveCar()
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(AppColors.accent)
            }
        }
    }
    
    private var carInfoSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Car Information")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.text)
            
            CustomTextField(icon: "car", placeholder: "Make", text: $viewModel.make)
            CustomTextField(icon: "car.fill", placeholder: "Model", text: $viewModel.model)
            CustomTextField(icon: "calendar", placeholder: "Year", text: Binding(
                get: { String(viewModel.year) },
                set: { if let value = Int($0) { viewModel.year = value } }
            ))
            CustomTextField(icon: "tag", placeholder: "Trim (Optional)", text: $viewModel.trim)
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(10)
    }
    
    private var performanceSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Performance")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.text)
            
            CustomTextField(icon: "speedometer", placeholder: "Horsepower", text: Binding(
                get: { viewModel.horsepower != nil ? String(viewModel.horsepower!) : "" },
                set: { if let value = Int($0) { viewModel.horsepower = value } }
            ))
            CustomTextField(icon: "tornado", placeholder: "Torque", text: Binding(
                get: { viewModel.torque != nil ? String(viewModel.torque!) : "" },
                set: { if let value = Int($0) { viewModel.torque = value } }
            ))
            CustomTextField(icon: "weight.scale", placeholder: "Weight (kg)", text: Binding(
                get: { viewModel.weight != nil ? String(viewModel.weight!) : "" },
                set: { if let value = Int($0) { viewModel.weight = value } }
            ))
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(10)
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Notes")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.text)
            
            TextEditor(text: $viewModel.notes)
                .frame(height: 100)
                .padding(5)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(10)
    }
    
    private var deleteButton: some View {
        Button(action: {
            viewModel.deleteCar()
            presentationMode.wrappedValue.dismiss()
        }) {
            Text("Delete Car")
                .font(AppFonts.headline)
                .foregroundColor(.white)
                .frame(height: 55)
                .frame(maxWidth: .infinity)
                .background(Color.red)
                .cornerRadius(10)
        }
    }
}


