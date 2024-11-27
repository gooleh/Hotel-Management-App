import Combine
import FirebaseFirestore
import FirebaseFirestoreSwift

class UserSession: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var department: String?
    @Published var roomNumber: String?
    @Published var currentRoom: Room?
    @Published var roomViewModel = RoomViewModel()
    @Published var socketManager = MySocketManager.shared // 소켓 매니저 추가
    @Published var userName: String? // 사용자 이름 추가

    private var db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?

    func login(phoneNumber: String, completion: @escaping (Bool, String?) -> Void) {
        db.collection("ApprovedNumbers").document(phoneNumber).getDocument { document, error in
            if let document = document, document.exists {
                self.department = document.data()?["dept"] as? String
                self.userName = document.data()?["name"] as? String // 사용자 이름 저장
                self.roomNumber = phoneNumber // Use phoneNumber as roomNumber
                self.isLoggedIn = true
                print("Login successful, room number: \(self.roomNumber ?? "nil")")
                self.fetchRoomDetails(roomNumber: phoneNumber) {
                    self.connectSocket() // 로그인 성공 시 소켓 연결
                    completion(true, nil)
                }
            } else {
                completion(false, "Phone number not approved or error: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }

    func fetchRoomDetails(roomNumber: String, completion: @escaping () -> Void) {
        db.collection("Rooms").document(roomNumber).getDocument { document, error in
            if let document = document, document.exists {
                self.currentRoom = try? document.data(as: Room.self)
                print("Room details fetched for room number: \(roomNumber)")
            } else {
                print("Failed to fetch room details for room number: \(roomNumber)")
            }
            completion()
        }
    }
    
    func startListeningForRoomUpdates() {
        guard let roomNumber = roomNumber else { return }
        
        listenerRegistration = db.collection("Rooms").document(roomNumber).addSnapshotListener { documentSnapshot, error in
            guard let document = documentSnapshot else {
                print("Error fetching document: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            self.currentRoom = try? document.data(as: Room.self)
        }
    }

    func stopListeningForRoomUpdates() {
        listenerRegistration?.remove()
    }
    
    // 소켓 연결 관리 메서드 추가
    func connectSocket() {
        socketManager.connect()
    }
    
    func disconnectSocket() {
        socketManager.disconnect()
    }
}
