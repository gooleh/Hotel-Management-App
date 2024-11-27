import Foundation
import FirebaseFirestore  // Firestore를 사용하기 위한 임포트
import FirebaseFirestoreSwift



class Room: ObservableObject, Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    @Published var isCheckedIn: Bool
    @Published var lastCleaned: Date
    @Published var maintenanceNotes: String
    @Published var notes: String
    @Published var number: String
    @Published var occupied: Bool
    @Published var status: String
    @Published var supplies: [String]
    @Published var roomServices: [String]

    init(id: String? = nil, isCheckedIn: Bool = false, lastCleaned: Date = Date(), maintenanceNotes: String = "", notes: String = "", number: String = "", occupied: Bool = false, status: String = "Unknown", supplies: [String] = [], roomServices: [String] = []) {
        self.id = id
        self.isCheckedIn = isCheckedIn
        self.lastCleaned = lastCleaned
        self.maintenanceNotes = maintenanceNotes
        self.notes = notes
        self.number = number
        self.occupied = occupied
        self.status = status
        self.supplies = supplies
        self.roomServices = roomServices
    }

    // CodingKeys enum을 추가하여 Firebase와의 호환성을 유지합니다.
    enum CodingKeys: String, CodingKey {
        case id
        case isCheckedIn
        case lastCleaned
        case maintenanceNotes
        case notes
        case number
        case occupied
        case status
        case supplies
        case roomServices
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        isCheckedIn = try container.decode(Bool.self, forKey: .isCheckedIn)
        lastCleaned = try container.decode(Date.self, forKey: .lastCleaned)
        maintenanceNotes = try container.decode(String.self, forKey: .maintenanceNotes)
        notes = try container.decode(String.self, forKey: .notes)
        number = try container.decode(String.self, forKey: .number)
        occupied = try container.decode(Bool.self, forKey: .occupied)
        status = try container.decode(String.self, forKey: .status)
        supplies = try container.decode([String].self, forKey: .supplies)
        roomServices = try container.decode([String].self, forKey: .roomServices)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(isCheckedIn, forKey: .isCheckedIn)
        try container.encode(lastCleaned, forKey: .lastCleaned)
        try container.encode(maintenanceNotes, forKey: .maintenanceNotes)
        try container.encode(notes, forKey: .notes)
        try container.encode(number, forKey: .number)
        try container.encode(occupied, forKey: .occupied)
        try container.encode(status, forKey: .status)
        try container.encode(supplies, forKey: .supplies)
        try container.encode(roomServices, forKey: .roomServices)
    }

    // Equatable 및 hash(into:) 메서드 추가
    static func == (lhs: Room, rhs: Room) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}


struct Customer: Identifiable {
    var id: UUID
    var name: String
    var reservation: String
}

struct Request: Identifiable, Codable {
    @DocumentID var id: String?
    var type: String
    var item: String
    var timestamp: Timestamp
    var roomNumber: String // roomNumber 필드 추가
}

struct Supply: Identifiable {
    let id = UUID()
    let name: String
    let imageName: String
    var isSelected: Bool = false
}

struct NotificationModel: Identifiable, Codable {
    var id: String
    var message: String
    var recipient: String
    var timestamp: Date
}

