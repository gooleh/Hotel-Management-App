import SwiftUI

struct RoomServiceMenuCard: View {
    let service: RoomServiceMenu
    let image: UIImage?
    @Binding var selectedRoomServices: Set<RoomServiceMenu>

    var body: some View {
        VStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 135, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .shadow(radius: 5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(selectedRoomServices.contains(service) ? Color.green : Color.white, lineWidth: 2)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.white.opacity(0.3))
                            )
                    )
            } else {
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 130, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .shadow(radius: 5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.white, lineWidth: 2)
                    )
            }
            Text(service.name)
                .font(.headline)
                .foregroundColor(.brown)
                .padding(.top, 5)
        }
        .frame(width: 130, height: 135) // 고정된 카드 너비
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.6))
                .shadow(radius: 5)
        )
        .onTapGesture {
            if selectedRoomServices.contains(service) {
                selectedRoomServices.remove(service)
            } else {
                selectedRoomServices.insert(service)
            }
        }
    }
}

struct RoomServiceSection: View {
    let section: String
    let services: [RoomServiceMenu]
    @Binding var selectedRoomServices: Set<RoomServiceMenu>
    let selectedImages: [RoomServiceMenu: UIImage]

    var body: some View {
        VStack(alignment: .leading) {
            Text(section)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.top, 10)
            
            ForEach(services) { service in
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
                            .foregroundColor(.white)
                        Text(service.description)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                    if selectedRoomServices.contains(service) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white.opacity(0.2))
                        .shadow(radius: 5)
                )
                .onTapGesture {
                    if selectedRoomServices.contains(service) {
                        selectedRoomServices.remove(service)
                    } else {
                        selectedRoomServices.insert(service)
                    }
                }
            }
        }
    }
}


