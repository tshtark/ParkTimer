import Foundation

enum VehicleType: String, CaseIterable, Codable {
    case car
    case bike
    case truck
    case motorcycle
    case scooter

    var iconName: String {
        switch self {
        case .car: "car.fill"
        case .bike: "bicycle"
        case .truck: "truck.box.fill"
        case .motorcycle: "motorcycle.fill"
        case .scooter: "scooter"
        }
    }

    var displayName: String {
        switch self {
        case .car: "Car"
        case .bike: "Bicycle"
        case .truck: "Truck"
        case .motorcycle: "Motorcycle"
        case .scooter: "Scooter"
        }
    }
}
