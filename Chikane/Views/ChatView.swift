//
//  ChatView.swift
//  Chikane
//
//  Created by Ty Mitchell on 9/22/24.
//
import SwiftUI
import FirebaseFirestore
import Firebase
import FirebaseAuth

struct ChatView: View {
    @StateObject private var viewModel: ChatViewModel
    @State private var newMessage: String = ""
    
    init(eventCode: String) {
        _viewModel = StateObject(wrappedValue: ChatViewModel(eventCode: eventCode))
    }
    
    var body: some View {
        ZStack {
            AppColors.background.edgesIgnoringSafeArea(.all)
            
            VStack {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            ForEach(viewModel.messages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages) { _ in
                        if let lastMessage = viewModel.messages.last {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                
                HStack {
                    TextField("Type a message", text: $newMessage)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .foregroundColor(AppColors.text)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(AppColors.accent)
                    }
                }
                .padding()
                .background(AppColors.cardBackground)
            }
        }
        .navigationTitle("Event Chat")
        .onAppear { viewModel.listenForMessages() }
    }
    
    private func sendMessage() {
        viewModel.sendMessage(newMessage)
        newMessage = ""
    }
}

struct ChatBubble: View {
    let message: ChatMessage
    @State private var isSentByCurrentUser: Bool = false
    
    var body: some View {
        HStack {
            if isSentByCurrentUser { Spacer() }
            VStack(alignment: isSentByCurrentUser ? .trailing : .leading, spacing: 5) {
                Text(message.sender)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.lightText)
                Text(message.content)
                    .padding(10)
                    .background(isSentByCurrentUser ? AppColors.accent : AppColors.cardBackground)
                    .foregroundColor(isSentByCurrentUser ? .white : AppColors.text)
                    .cornerRadius(10)
            }
            if !isSentByCurrentUser { Spacer() }
        }
        .onAppear {
            isSentByCurrentUser = message.senderId == Auth.auth().currentUser?.uid
        }
    }
}

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    private let eventCode: String
    private let db = Firestore.firestore()
    
    init(eventCode: String) {
        self.eventCode = eventCode
    }
    
    func listenForMessages() {
        db.collection("events").document(eventCode).collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching messages: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                self?.messages = documents.compactMap { document -> ChatMessage? in
                    try? document.data(as: ChatMessage.self)
                }
            }
    }
    
    func sendMessage(_ content: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let newMessage = ChatMessage(
            senderId: userId,
            sender: "Current User", // You might want to fetch the actual username
            content: content,
            timestamp: Date()
        )
        
        do {
            try db.collection("events").document(eventCode).collection("messages").addDocument(from: newMessage)
        } catch {
            print("Error sending message: \(error.localizedDescription)")
        }
    }
}

struct ChatMessage: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    let senderId: String
    let sender: String
    let content: String
    let timestamp: Date
    
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id &&
        lhs.senderId == rhs.senderId &&
        lhs.sender == rhs.sender &&
        lhs.content == rhs.content &&
        lhs.timestamp == rhs.timestamp
    }
}
