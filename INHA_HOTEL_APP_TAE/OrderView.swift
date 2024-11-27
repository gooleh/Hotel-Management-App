import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import Combine

struct Order: Identifiable, Codable {
    @DocumentID var id: String?
    var roomNumber: String
    var item: String
    var timestamp: Timestamp
    var assignedTo: String?
    var type: String? // type 필드를 추가합니다.
}

class OrderViewModel: ObservableObject {
    @Published var orders: [Order] = []

    init() {
        fetchOrders()
    }

    func fetchOrders() {
        let db = Firestore.firestore()
        db.collection("Requests").order(by: "timestamp", descending: false).addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                print("No documents found")
                return
            }
            self.orders = documents.compactMap { doc in
                try? doc.data(as: Order.self)
            }
        }
    }

    func assignOrder(order: Order, to name: String) {
        let db = Firestore.firestore()
        if let orderId = order.id {
            db.collection("Requests").document(orderId).updateData(["assignedTo": name]) { error in
                if let error = error {
                    print("Error updating order: \(error)")
                } else {
                    print("Order successfully updated")
                }
            }
        }
    }

    func completeOrder(order: Order) {
        let db = Firestore.firestore()
        if let orderId = order.id {
            // Create a new document in CompletedOrders with the same data
            do {
                try db.collection("CompletedOrders").document(orderId).setData(from: order) { error in
                    if let error = error {
                        print("Error adding completed order: \(error.localizedDescription)")
                    } else {
                        // Remove the original document from Requests
                        db.collection("Requests").document(orderId).delete { error in
                            if let error = error {
                                print("Error completing order: \(error)")
                            } else {
                                print("Order successfully completed")
                            }
                        }
                    }
                }
            } catch {
                print("Error creating completed order: \(error.localizedDescription)")
            }
        }
    }
}


struct OrderView: View {
    @ObservedObject var viewModel: OrderViewModel
    @EnvironmentObject var userSession: UserSession

    var body: some View {
        VStack {
            Text("Order History")
                .font(.largeTitle)
                .padding()

            List(viewModel.orders) { order in
                OrderRowView(order: order, viewModel: viewModel, userName: userSession.userName ?? "")
            }
        }
        .navigationTitle("Orders")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct OrderRowView: View {
    var order: Order
    @ObservedObject var viewModel: OrderViewModel
    var userName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Room \(order.roomNumber)")
                    .font(.headline)
                Spacer()
                if let assignedTo = order.assignedTo {
                    Text("Assigned to: \(assignedTo)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            Text("Item: \(order.item)")
                .font(.subheadline)
            Text("Time: \(order.timestamp.dateValue().formatted(.dateTime.month().day().hour().minute()))")
                .font(.subheadline)
                .foregroundColor(.gray)

            HStack {
                if order.assignedTo == nil {
                    Button(action: {
                        viewModel.assignOrder(order: order, to: userName)
                    }) {
                        Text("Assign to Me")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 10)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(5)
                    }
                } else if order.assignedTo == userName {
                    Button(action: {
                        viewModel.completeOrder(order: order)
                    }) {
                        Text("Complete")
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 10)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(5)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.vertical, 5)
    }
}
