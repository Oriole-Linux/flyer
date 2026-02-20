import Foundation

struct BuildFile: Codable {
    let name: String
    let version: String
    let desc: String
    let deps: [String]
    let maintainer: String
    let category: String
    let source: String
    let checksum: String
    let configuring: String
    let build: String
    let install: String
    let post: String
    let remove: String
}

func decode(from url: URL) throws -> BuildFile {
    let data = try Data(contentsOf: url)
    let decoder = PropertyListDecoder()
    return try decoder.decode(BuildFile.self, from: data)    
}

struct ParseTest {
    func test_name() throws -> String {
        let path = "/var/db/repos/oriole/app-misc/test/build.plist"
        let buildFile = try decode(from: URL(fileURLWithPath: path))

        return buildFile.name
    }
    func test_ver() throws -> String {
        let path = "/var/db/repos/oriole/app-misc/test/build.plist"
        let buildFile = try decode(from: URL(fileURLWithPath: path))

        return buildFile.version
    }
    func test_cmd() throws -> String {
        let path = "/var/db/repos/oriole/app-misc/test/build.plist"
        let buildFile = try decode(from: URL(fileURLWithPath: path))

        return buildFile.configuring
    }
}