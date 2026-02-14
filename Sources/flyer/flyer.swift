
import ArgumentParser
import Foundation


@main
struct flyer: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "flyer",
        abstract: "Source-based package manager in Swift",
        subcommands: [Install.self, Remove.self, Sync.self]
    )
}

struct Install: AsyncParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Install a package")

    @Argument(help: "Package to deploy (with category/name)")
    var package: String

    @Flag(name: .shortAndLong, help: "Show detailed output.")
    var verbose = false
    
    func run() async throws {
        try Repo.sync()

        let path = "\(Paths.base)/\(package)"
        let build = "\(path)/build.plist"
        let file = FileManager()

        let buildFile = try decode(from: URL(fileURLWithPath: build))
        if verbose {
            print("\(Colored.green)[INSTALL]\(Colored.reset) Start deployment for package \(Colored.blue)\(package)\(Colored.reset)")
            print("\(Bold.cyan)Starting\(Colored.reset) tree check for package \(package)")
        }

        if !file.fileExists(atPath: build) {
            print("\(Colored.red)Error: \(Colored.reset) Package \(Colored.blue)\(package)\(Colored.reset) does not exist.")
            return
        }

        print("\(Bold.green)Found\(Colored.reset) \(package), starting build")

        stage(name: "download", i: 1, max: 5)
        print("\(Colored.green)Starting\(Colored.reset) download for \(Colored.blue)\(package)\(Colored.reset)")

        print("Configure")

        stage(name: "build", i: 2, max: 4)

        print ("Build")

        stage(name: "stage", i: 3, max: 4)

        print("Staging")

        stage(name: "install", i: 4, max: 4)

        print("Installing to system")        
    }
}

struct Remove: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Remove a package")

    @Argument(help: "Package to remove")
    var package: String

    @Flag(name: .shortAndLong, help: "Show detailed output.")
    var verbose = false
    
    func run() throws {
        if verbose {
            print("\(Colored.red)[REMOVE]\(Colored.reset) Start removal for package \(Colored.blue)\(package)\(Colored.reset)")
        }

        print("Removing \(Colored.blue)\(package)\(Colored.reset)")
    }
}

struct Sync: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Sync the build repository")
    
    func run() throws {
        try Repo.sync()
    }
}