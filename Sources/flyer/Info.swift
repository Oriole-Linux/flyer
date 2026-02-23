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

        let pkg = try decode(from: URL(fileURLWithPath: build))

        print("package \(Colored.blue)\(package)\(Colored.reset)")
        print("    Name: \(Colored.yellow)\(pkg.name)\(Colored.reset) (in category: \(Colored.yellow)\(pkg.category)\(Colored.reset))")
        print("    Version: \(Colored.yellow)\(pkg.version)\(Colored.reset)")
        print("    Maintainer: \(Colored.yellow)\(pkg.maintainer)\(Colored.reset)")
        print("    Dependencies: \(Colored.yellow)\(pkg.deps)\(Colored.reset)")
        if file.fileExists(atPath: "/var/db/flyer/packages/\(pkg.category)/\(pkg.name)") {
            print("    Installed: \(Colored.green)yes\(Colored.reset)")
        } else {
            print("    Installed: \(Colored.red)no\(Colored.reset)")
        }
        if verbose {
            print("    Source: \(Colored.yellow)\(pkg.source)\(Colored.reset)")
            print("    Configuring command: \(Colored.yellow)\(pkg.configuring)\(Colored.reset)")
            print("    Compiling command: \(Colored.yellow)\(pkg.build)\(Colored.reset)")
            print("    Installing command: \(Colored.yellow)\(pkg.install)\(Colored.reset)")
        }
    }
}