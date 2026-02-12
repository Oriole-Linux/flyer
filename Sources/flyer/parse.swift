import Foundation

struct BuildFile: Codable {
    let name: String
    let version: String
    let description: String
    let maintainer: String
    let source: String
    let checksum: String
    let configuring: String
    let build: String
    let install: String
    let stagingFlag: String
    let post: String
}