import Foundation
import SocketIO

class MySocketManager: ObservableObject {
    static let shared = MySocketManager()

    private var manager: SocketManager
    private var socket: SocketIOClient
    private var isConnected = false

    private init() {
        guard let url = URL(string: "http://localhost:4000") else {
            fatalError("Invalid URL")
        }
        
        manager = SocketManager(socketURL: url, config: [.log(true), .compress])
        socket = manager.defaultSocket

        socket.on(clientEvent: .connect) { data, ack in
            print("Socket connected")
            self.isConnected = true
        }

        socket.on(clientEvent: .disconnect) { data, ack in
            print("Socket disconnected")
            self.isConnected = false
        }
    }

    func connect() {
        if !isConnected {
            socket.connect()
        }
    }

    func disconnect() {
        if isConnected {
            socket.disconnect()
        }
    }

    func sendRequest(message: String, requestType: String, recipient: String) {
        let data: [String: Any] = ["message": message, "type": requestType, "recipient": recipient]
        socket.emit("sendRequest", data)
    }

    func sendNotification(message: String, recipients: [String]) {
        for recipient in recipients {
            sendRequest(message: message, requestType: "notification", recipient: recipient)
        }
    }

    func onReceiveRequest(forType type: String, handler: @escaping (String) -> Void) {
        socket.on("receiveRequest") { (dataArray, ack) in
            if let data = dataArray[0] as? [String: Any],
               let message = data["message"] as? String,
               let receivedType = data["type"] as? String,
               receivedType == type,
               let recipient = data["recipient"] as? String,
               recipient == type {
                handler(message)
                NotificationCenter.default.post(name: .newNotification, object: nil, userInfo: ["message": message])
            }
        }
    }

    func offReceiveRequest() {
        socket.off("receiveRequest")
    }
}

extension Notification.Name {
    static let newNotification = Notification.Name("newNotification")
}
