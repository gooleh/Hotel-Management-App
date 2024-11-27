import SwiftUI
import FirebaseFirestore
import UserNotifications

struct RoomServiceRequestView: View {
    @EnvironmentObject var userSession: UserSession
    @State private var selectedRoomServices: Set<RoomServiceMenu> = []
    @State private var roomServices: [RoomServiceMenu] = []
    @State private var selectedImages: [RoomServiceMenu: UIImage] = [:]
    @State private var isLoading: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var showCart: Bool = false

    private let sectionOrder = ["Morning Menu", "Korean Food", "Pizza", "Pasta", "Drink", "Coffee"]
    
    private var groupedRoomServices: [String: [RoomServiceMenu]] {
        Dictionary(grouping: roomServices, by: { $0.section })
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                Text("Room Service Menu")
                    .font(.custom("Times New Roman", size: 34))
                    .foregroundColor(.white)
                    .padding(.bottom, 20)
                    .shadow(color: .black, radius: 2, x: 0, y: 2)
                
                ScrollView {
                    ForEach(sectionOrder, id: \.self) { section in
                        if let services = groupedRoomServices[section] {
                            RoomServiceSection(section: section, services: services, selectedRoomServices: $selectedRoomServices, selectedImages: selectedImages)
                        }
                    }
                }
                
                if !selectedRoomServices.isEmpty {
                    Button(action: {
                        showCart.toggle()
                    }) {
                        HStack {
                            Image(systemName: "cart.fill")
                            Text("View Cart (\(selectedRoomServices.count))")
                                .font(.headline)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(gradient: Gradient(colors: [.brown, .orange]), startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .shadow(radius: 5)
                    }
                    .padding(.top, 20)
                    .sheet(isPresented: $showCart) {
                        CartView(selectedRoomServices: Array(selectedRoomServices), selectedImages: selectedImages)
                            .environmentObject(userSession)
                    }
                }
                
            }
            .padding()
            .background(
                ZStack {
                    Image("RoomServiceBackground_image")
                        .resizable()
                        .scaledToFill()
                        .edgesIgnoringSafeArea(.all)
                    LinearGradient(gradient: Gradient(colors: [.white.opacity(0.6), .white.opacity(0.3)]), startPoint: .top, endPoint: .bottom)
                        .edgesIgnoringSafeArea(.all)
                }
            )
            .overlay(
                Group {
                    if isLoading {
                        ProgressView()
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(10)
                    }
                }
            )
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .onAppear {
                fetchRoomServices()
                MySocketManager.shared.onReceiveRequest(forType: "roomService") { message in
                    sendNotification(message: message)
                }
            }
            .onDisappear {
                MySocketManager.shared.offReceiveRequest()
            }
            .navigationBarHidden(true)
        }
    }

    private func fetchRoomServices() {
        let db = Firestore.firestore()
        db.collection("RoomServiceMenus").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching room services: \(error.localizedDescription)")
                alertMessage = "Failed to fetch room services."
                showAlert = true
                return
            }

            guard let documents = snapshot?.documents else {
                alertMessage = "No room services available."
                showAlert = true
                return
            }

            self.roomServices = documents.compactMap { doc in
                try? doc.data(as: RoomServiceMenu.self)
            }
            
            loadAllImages()
        }
    }
    
    private func loadAllImages() {
        for service in roomServices {
            loadImage(for: service)
        }
    }

    private func loadImage(for service: RoomServiceMenu?) {
        guard let service = service else {
            return
        }
        service.loadImage { image in
            DispatchQueue.main.async {
                self.selectedImages[service] = image
            }
        }
    }

    private func loadImage(from urlString: String) -> UIImage? {
        guard let url = URL(string: urlString),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            return nil
        }
        return image
    }

    private func requestRoomService(service: RoomServiceMenu) {
        guard let roomNumber = userSession.roomNumber, let userName = userSession.userName else {
            alertMessage = "Room number or username not found."
            showAlert = true
            return
        }

        isLoading = true
        let db = Firestore.firestore()
        var request = RoomServiceRequest(type: "RoomService", item: service.name, timestamp: Timestamp(), roomNumber: roomNumber, requestedBy: userName)
        request.status = "pending" // 기본값 설정

        do {
            _ = try db.collection("RoomServices").addDocument(from: request) { error in
                if let error = error {
                    print("Error adding document: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        isLoading = false
                        alertMessage = "Request error: \(error.localizedDescription)"
                        showAlert = true
                    }
                } else {
                    print("Document successfully added!")
                    DispatchQueue.main.async {
                        isLoading = false
                        alertMessage = "Room service request successful!"
                        showAlert = true
                        MySocketManager.shared.sendRequest(message: "New room service request from room \(roomNumber) for \(service.name).", requestType: "roomService", recipient: "kitchen")
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                isLoading = false
                alertMessage = "Request error: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
    
    private func sendNotification(message: String) {
        let content = UNMutableNotificationContent()
        content.title = "Room Service Update"
        content.body = message
        content.sound = UNNotificationSound.default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}

struct CartView: View {
    var selectedRoomServices: [RoomServiceMenu]
    var selectedImages: [RoomServiceMenu: UIImage]
    @EnvironmentObject var userSession: UserSession
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                Text("Cart")
                    .font(.custom("Times New Roman", size: 34))
                    .foregroundColor(.brown)
                    .padding(.bottom, 20)
                    .shadow(color: .black, radius: 2, x: 0, y: 2)

                ScrollView {
                    LazyVStack(spacing: 15) {
                        ForEach(selectedRoomServices, id: \.self) { service in
                            HStack {
                                if let image = selectedImages[service] {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 60, height: 60)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .shadow(radius: 5)
                                }
                                VStack(alignment: .leading) {
                                    Text(service.name)
                                        .font(.headline)
                                        .foregroundColor(.brown)
                                    Text(service.description)
                                        .font(.subheadline)
                                        .foregroundColor(.brown.opacity(0.7))
                                    Text("Cost: \(service.cost)") // 비용 표시 추가
                                        .font(.subheadline)
                                        .foregroundColor(.brown.opacity(0.7))
                                }
                                Spacer()
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.white.opacity(0.6))
                                    .shadow(radius: 5)
                            )
                        }
                    }
                    .padding()
                }

                Button(action: {
                    for service in selectedRoomServices {
                        requestRoomService(service: service)
                    }
                }) {
                    HStack {
                        Image(systemName: "bell.fill")
                        Text("Request Room Service")
                            .font(.headline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(gradient: Gradient(colors: [.brown, .orange]), startPoint: .leading, endPoint: .trailing)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .shadow(radius: 5)
                }
                .padding(.top, 20)
            }
            .padding()
            .background(
                ZStack {
                    Image("RoomServiceBackground_image")
                        .resizable()
                        .scaledToFill()
                        .edgesIgnoringSafeArea(.all)
                    LinearGradient(gradient: Gradient(colors: [.white.opacity(0.6), .white.opacity(0.3)]), startPoint: .top, endPoint: .bottom)
                        .edgesIgnoringSafeArea(.all)
                }
            )
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }

    private func requestRoomService(service: RoomServiceMenu) {
        guard let roomNumber = userSession.roomNumber, let userName = userSession.userName else {
            // 오류 처리
            return
        }

        let db = Firestore.firestore()
        var request = RoomServiceRequest(type: "RoomService", item: service.name, timestamp: Timestamp(), roomNumber: roomNumber, requestedBy: userName)
        request.status = "pending" // 기본값 설정

        do {
            _ = try db.collection("RoomServices").addDocument(from: request) { error in
                if let error = error {
                    print("Error adding document: \(error.localizedDescription)")
                } else {
                    print("Document successfully added!")
                    MySocketManager.shared.sendRequest(message: "New room service request from room \(roomNumber) for \(service.name).", requestType: "kitchen", recipient: "kitchen")
                }
            }
        } catch {
            print("Request error: \(error.localizedDescription)")
        }
    }
}

struct RoomServiceRequest: Codable, Identifiable {
    @DocumentID var id: String?
    var type: String
    var item: String
    var timestamp: Timestamp
    var roomNumber: String
    var requestedBy: String
    var status: String? = "pending" // 기본값 설정
    var estimatedTime: String?
}

struct RoomServiceMenu: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    var name: String
    var description: String
    var imageUrl: String
    var section: String // 추가된 섹션 필드
    var cost: String // 비용 필드를 문자열로 변경

    func loadImage(completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: imageUrl) else {
            completion(nil)
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data, let image = UIImage(data: data) {
                completion(image)
            } else {
                completion(nil)
            }
        }.resume()
    }
}
