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



struct Remove: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Remove a package")

    @Argument(help: "Package to remove")
    var package: String

    @Flag(name: .shortAndLong, help: "Show detailed output.")
    var verbose = false
    
    func run() throws {
        let file = FileManager.default
        let db = "/var/db/flyer/packages/\(package)"
        let contents = "\(db)/CONTENTS"

        guard file.fileExists(atPath: contents) else {
            print("\(Colored.red)Error:\(Colored.reset) Package \(Colored.blue)\(package)\(Colored.reset) not found. \n If you believe this is a mistake, the database may be corrupted.")
            return
        }

        if verbose {
            print("\(Colored.red)[REMOVE]\(Colored.reset) Start removal for package \(Colored.blue)\(package)\(Colored.reset)")
        }

        print("Removing \(Colored.blue)\(package)\(Colored.reset)")

        let content = try String(contentsOfFile: contents, encoding: .utf8)
        let toRemove = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
    
        for path in toRemove {
            if file.fileExists(atPath: path) {
                if file.fileExists(atPath: path) {
                    print("> \(path)")
                    try? file.removeItem(atPath: path)
                }
            }
        }

        try file.removeItem(atPath: db)

        print("\(Bold.green)Removed\(Colored.reset) package \(package)")
    }
}

struct Sync: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Sync the build repository")
    
    func run() throws {
        try Repo.sync()
    }
}