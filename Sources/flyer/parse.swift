import Foundation

struct BuildFile: Codable {
    let name: String
    let version: String
    let desc: String
    let deps: [String]
    let maintainer: String
    let source: String
    let checksum: String
    let configuring: String
    let build: String
    let install: String
    let stagingFlag: String
    let category: String
    let post: String
    let remove: String
}

func decode(from url: URL) throws -> BuildFile {
    let data = try Data(contentsOf: url)
    let decoder = PropertyListDecoder()
    return try decoder.decode(BuildFile.self, from: data)    
}