import ArgumentParser
import Foundation

struct Info: AsyncParsableCommand {
    static let configuration = CommandConfiguration(abstract: "See detailed information of a package")

    @Argument(help: "Package to view info")
    var package: String

    @Flag(name: .shortAndLong, help: "Show information mainly useful for developers.")
    var verbose: Bool = false

    func run() async throws {
        let path = "\(Paths.base)/\(package)"
        let build = "\(path)/build.plist"
        let file = FileManager()

        if !file.fileExists(atPath: build) {
            print("\(Colored.red)Error: \(Colored.reset) Package \(Colored.blue)\(package)\(Colored.reset) does not exist.")
            return
        }

        let pkg = try decode(from: URL(fileURLWithPath: path))

        print("package \(Colored.blue)\(package)\(Colored.reset)")
        print("    Name: \(Colored.yellow)\(pkg.name)\(Colored.reset) (in category: \(Colored.yellow))")
        print("    Version: \(Colored.yellow)\(pkg.version)\(Colored.yellow)")
        print("    Maintainer: \(Colored.yellow)")
    }
}