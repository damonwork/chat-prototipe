import Foundation

struct UserProfile: Codable {
    var username: String
    var displayName: String
    var avatarData: Data?
}
