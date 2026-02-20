import Foundation

enum InstallType: String {
    case new = "N"
    case reinstall = "R"
    // case upgrade = "U"
}

func installType(category: String, name: String, version: String, root: String = "/var/db/flyer/packages") -> InstallType {
    let db = "\(root)/\(category)/\(name)"
    if !FileManager.default.fileExists(atPath: db) {
        return .new
    }
    return .reinstall
}