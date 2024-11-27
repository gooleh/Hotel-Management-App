import SwiftUI
import FirebaseFirestore

struct KitchenView: View {
    @State private var pendingOrders: [RoomServiceRequest] = []
    @State private var acceptedOrders: [RoomServiceRequest] = []
    @State private var isLoading: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var selectedOrder: RoomServiceRequest?
    @State private var estimatedTime: String = ""
    @State private var orderImages: [String: UIImage] = [:] // 추가된 상태 변수

    @EnvironmentObject var userSession: UserSession

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                Text("Incoming Orders")
                    .font(.custom("Times New Roman", size: 34))
                    .foregroundColor(.black)
                    .padding(.bottom, 20)
                    .shadow(color: .gray, radius: 2, x: 0, y: 2)

                ScrollView {
                    LazyVStack(spacing: 15) {
                        Section(header: Text("Pending Orders")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.black)) {
                            ForEach(pendingOrders) { order in
                                OrderCard(order: order, selectedOrder: $selectedOrder, orderImages: $orderImages)
                                    .frame(maxWidth: .infinity, minHeight: 100)
                                    .background(Color.white.opacity(0.8))
                                    .cornerRadius(15)
                                    .shadow(radius: 5)
                            }
                        }

                        Section(header: Text("Accepted Orders")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.black)) {
                            ForEach(acceptedOrders) { order in
                                OrderCard(order: order, selectedOrder: $selectedOrder, orderImages: $orderImages)
                                    .frame(maxWidth: .infinity, minHeight: 100)
                                    .background(Color.white.opacity(0.8))
                                    .cornerRadius(15)
                                    .shadow(radius: 5)
                            }
                        }
                    }
                    .padding()
                }

                if let selectedOrder = selectedOrder {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Selected Order")
                            .font(.headline)
                            .padding(.top, 20)
                        Text("Room: \(selectedOrder.roomNumber)")
                        Text("Order: \(selectedOrder.item)")
                        
                        if selectedOrder.status == "pending" {
                            TextField("Estimated Time (minutes)", text: $estimatedTime)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.vertical, 10)
                            
                            Button(action: {
                                acceptOrder(order: selectedOrder, estimatedTime: estimatedTime)
                            }) {
                                Text("Accept Order")
                                    .font(.headline)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        LinearGradient(gradient: Gradient(colors: [.green, .blue]), startPoint: .leading, endPoint: .trailing)
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                    .shadow(radius: 5)
                            }
                        } else if selectedOrder.status == "accepted" {
                            Button(action: {
                                completeOrder(order: selectedOrder)
                            }) {
                                Text("Complete Order")
                                    .font(.headline)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        LinearGradient(gradient: Gradient(colors: [.orange, .red]), startPoint: .leading, endPoint: .trailing)
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                    .shadow(radius: 5)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white)
                            .shadow(radius: 5)
                    )
                }

                Spacer()
            }
            .padding()
            .background(
                ZStack {
                    Image("KitchenView background_image")
                        .resizable()
                        .scaledToFill()
                        .edgesIgnoringSafeArea(.all)
                    Color.white.opacity(0.6).edgesIgnoringSafeArea(.all)
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
                addOrdersListener()
                MySocketManager.shared.onReceiveRequest(forType: "kitchen") { message in
                    sendNotification(message: message)
                }
            }
            .onDisappear {
                MySocketManager.shared.offReceiveRequest()
            }
            .navigationBarHidden(true)
        }
    }

    private func addOrdersListener() {
        let db = Firestore.firestore()
        db.collection("RoomServices").addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error listening for orders: \(error.localizedDescription)")
                alertMessage = "Failed to listen for orders."
                showAlert = true
                return
            }

            guard let documents = snapshot?.documents else {
                alertMessage = "No orders available."
                showAlert = true
                return
            }

            let orders = documents.compactMap { doc -> RoomServiceRequest? in
                let result = Result { try doc.data(as: RoomServiceRequest.self) }
                switch result {
                case .success(let order):
                    return order
                case .failure(let error):
                    print("Error decoding order: \(error)")
                    return nil
                }
            }

            self.pendingOrders = orders.filter { $0.status == "pending" }
            self.acceptedOrders = orders.filter { $0.status == "accepted" }

            print("Pending Orders: \(self.pendingOrders)")
            print("Accepted Orders: \(self.acceptedOrders)")

            loadImages(for: orders)
        }
    }

    private func loadImages(for orders: [RoomServiceRequest]) {
        for order in orders {
            loadImage(for: order)
        }
    }

    private func loadImage(for order: RoomServiceRequest) {
        let db = Firestore.firestore()
        db.collection("RoomServiceMenus").whereField("name", isEqualTo: order.item).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching room service menu: \(error.localizedDescription)")
                return
            }

            guard let document = snapshot?.documents.first else {
                print("No matching room service menu found.")
                return
            }

            let result = Result { try document.data(as: RoomServiceMenu.self) }
            switch result {
            case .success(let menu):
                menu.loadImage { image in
                    DispatchQueue.main.async {
                        self.orderImages[order.id ?? ""] = image
                    }
                }
            case .failure(let error):
                print("Error decoding room service menu: \(error)")
            }
        }
    }

    private func acceptOrder(order: RoomServiceRequest, estimatedTime: String) {
        guard let orderId = order.id else {
            alertMessage = "Invalid order ID."
            showAlert = true
            return
        }

        let db = Firestore.firestore()
        db.collection("RoomServices").document(orderId).updateData([
            "status": "accepted",
            "estimatedTime": estimatedTime
        ]) { error in
            if let error = error {
                print("Error updating order: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    alertMessage = "Failed to accept order: \(error.localizedDescription)"
                    showAlert = true
                }
            } else {
                print("Order successfully accepted!")
                DispatchQueue.main.async {
                    alertMessage = "Order accepted successfully!"
                    showAlert = true
                    self.selectedOrder = nil // 창을 닫기 위해 selectedOrder를 nil로 설정
                    MySocketManager.shared.sendRequest(message: "Order accepted with estimated time: \(estimatedTime) minutes.", requestType: "roomService", recipient: "roomService")
                }
            }
        }
    }

    private func completeOrder(order: RoomServiceRequest) {
        guard let orderId = order.id else {
            alertMessage = "Invalid order ID."
            showAlert = true
            return
        }

        let db = Firestore.firestore()
        db.collection("RoomServices").document(orderId).delete { error in
            if let error = error {
                print("Error deleting order: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    alertMessage = "Failed to complete order: \(error.localizedDescription)"
                    showAlert = true
                }
            } else {
                print("Order successfully completed and deleted!")
                DispatchQueue.main.async {
                    pendingOrders.removeAll { $0.id == order.id }
                    acceptedOrders.removeAll { $0.id == order.id }
                    selectedOrder = nil
                    alertMessage = "Order completed successfully!"
                    showAlert = true
                    MySocketManager.shared.sendRequest(message: "Order completed for room \(order.roomNumber).", requestType: "roomService", recipient: "roomService")
                }
            }
        }
    }
    
    private func sendNotification(message: String) {
        let content = UNMutableNotificationContent()
        content.title = "Order Update"
        content.body = message
        content.sound = UNNotificationSound.default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}

struct OrderCard: View {
    var order: RoomServiceRequest
    @Binding var selectedOrder: RoomServiceRequest?
    @Binding var orderImages: [String: UIImage]

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if let image = orderImages[order.id ?? ""] {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(radius: 5)
            } else {
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(radius: 5)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("Room: \(order.roomNumber)")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(width: 200, alignment: .leading)
                Text("Order: \(order.item)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(width: 200, alignment: .leading)
                Text("Requested by: \(order.requestedBy)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(width: 200, alignment: .leading)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 100) // 카드 크기 고정
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(radius: 5)
        )
        .onTapGesture {
            fetchOrder(orderId: order.id)
        }
    }

    private func fetchOrder(orderId: String?) {
        guard let orderId = orderId else { return }
        let db = Firestore.firestore()
        db.collection("RoomServices").document(orderId).getDocument { document, error in
            if let document = document, document.exists {
                do {
                    selectedOrder = try document.data(as: RoomServiceRequest.self)
                } catch {
                    print("Error decoding order: \(error)")
                }
            } else {
                print("Document does not exist")
            }
        }
    }
}
