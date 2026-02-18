import Foundation

enum InstallType: String {
    case new = "N"
    case reinstall = "R"
    // case upgrade = "U"
}

func installType(category: String, name: String, version: String) -> InstallType {
    let db = "/var/db/flyer/packages/\(category)/\(name)"
    if !FileManager.default.fileExists(atPath: db) {
        return .new
    }
    return .reinstall
}