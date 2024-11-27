import SwiftUI
import FirebaseFirestore
import Firebase

class RoomViewModel: ObservableObject {
    @Published var rooms = [Room]()
    @Published var groupedRooms = [String: [Room]]()
    @Published var selectedRoomIndex: Int? = nil
    @Published var groupedRooms2 = [String: [Room]]()
    @Published var groupedRoomsByStatus = [String: [Room]]()
    @Published var notifications = [NotificationModel]() // 추가

    private var db = Firestore.firestore()

        var selectedRoomNotes: Binding<String> {
            guard let selectedIndex = selectedRoomIndex, selectedIndex < rooms.count else {
                return .constant("")
            }
            return Binding<String>(
                get: { self.rooms[selectedIndex].notes },
                set: { self.rooms[selectedIndex].notes = $0 }
            )
        }

        init() {
            fetchRooms()
            fetchNotifications() // 추가
        }
        
        func fetchRooms() {
            db.collection("rooms").addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("No documents found")
                    return
                }
                self.rooms = documents.map { doc in
                    Room(
                        id: doc.documentID,
                        isCheckedIn: doc["isCheckedIn"] as? Bool ?? false,
                        lastCleaned: (doc["lastCleaned"] as? Timestamp)?.dateValue() ?? Date(),
                        maintenanceNotes: doc["maintenanceNotes"] as? String ?? "",
                        notes: doc["notes"] as? String ?? "",
                        number: doc["number"] as? String ?? "",
                        occupied: doc["occupied"] as? Bool ?? false,
                        status: doc["status"] as? String ?? "Unknown",
                        supplies: doc["supplies"] as? [String] ?? [],
                        roomServices: doc["roomServices"] as? [String] ?? []
                    )
                }
                self.groupRooms()
                self.groupRooms2()
                self.groupRoomsByStatus()
            }
        }

        private func groupRooms() {
            groupedRooms = Dictionary(grouping: rooms) {
                $0.isCheckedIn ? "Checked In" : "Checked Out"
            }
        }
        
        func groupRooms2() {
            let occupiedRooms = rooms.filter { $0.occupied }
            let availableRooms = rooms.filter { !$0.occupied }
            groupedRooms2 = [
                "Occupied Rooms": occupiedRooms,
                "Available Rooms": availableRooms
            ]
        }

        private func groupRoomsByStatus() {
            groupedRoomsByStatus = Dictionary(grouping: rooms) { $0.status }
        }

        func updateRoomStatus(room: Room, newStatus: String, newLastCleaned: Date? = nil) {
            var data: [String: Any] = ["status": newStatus]
            if let newLastCleaned = newLastCleaned {
                data["lastCleaned"] = Timestamp(date: newLastCleaned)
            }
            db.collection("rooms").document(room.id ?? "").updateData(data) { error in
                if let error = error {
                    print("Error updating room status: \(error.localizedDescription)")
                } else {
                    self.fetchRooms() // 상태 변경 후 데이터 다시 가져오기
                }
            }
        }

        func updateRoomOccupied(room: Room, occupied: Bool, report: String = "", completion: @escaping () -> Void) {
            let data: [String: Any] = ["occupied": occupied, "maintenanceNotes": report]
            db.collection("rooms").document(room.id ?? "").updateData(data) { error in
                if let error = error {
                    print("Error updating document: \(error.localizedDescription)")
                } else {
                    self.fetchRooms() // 상태 변경 후 데이터 다시 가져오기
                    completion()
                    let message = "Room \(room.number) occupancy changed to \(occupied ? "Occupied" : "Available")."
                    self.sendNotificationToRecipients(message: message, recipients: ["housekeeping", "frontdesk"])
                }
            }
        }

        func updateCheckInStatusOnly(room: Room, isCheckedIn: Bool) {
            let data: [String: Any] = ["isCheckedIn": isCheckedIn]
            db.collection("rooms").document(room.id ?? "").updateData(data) { error in
                if let error = error {
                    print("Error updating check-in status: \(error.localizedDescription)")
                } else {
                    self.fetchRooms() // 상태 변경 후 데이터 다시 가져오기
                }
            }
        }

        func updateRoomNotes(roomId: String?, notes: String) {
            guard let roomId = roomId else {
                print("Room ID not found.")
                return
            }
            let data = ["notes": notes]
            db.collection("rooms").document(roomId).updateData(data) { error in
                if let error = error {
                    print("Error updating notes: \(error.localizedDescription)")
                } else {
                    self.fetchRooms() // 상태 변경 후 데이터 다시 가져오기
                    print("Notes updated successfully.")
                }
            }
        }

        func saveNotification(message: String, recipient: String) {
            let newNotification = NotificationModel(id: UUID().uuidString, message: message, recipient: recipient, timestamp: Date())
            do {
                _ = try db.collection("issueReports").addDocument(from: newNotification)
            } catch {
                print("Error saving notification: \(error.localizedDescription)")
            }
        }
        
        func fetchNotifications() {
            db.collection("issueReports").addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("No documents found")
                    return
                }
                self.notifications = documents.compactMap { doc -> NotificationModel? in
                    try? doc.data(as: NotificationModel.self)
                }
            }
        }

        func sendNotificationToRecipients(message: String, recipients: [String]) {
            MySocketManager.shared.sendNotification(message: message, recipients: recipients)
        }

        func statusColor(for status: String) -> Color {
            switch status {
            case "Clean":
                return .green
            case "Dirty":
                return .red
            case "Inspected":
                return .blue
            default:
                return .gray
            }
        }
    }
