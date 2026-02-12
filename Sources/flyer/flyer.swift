
import ArgumentParser

struct Install: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Install a package")

    @Argument(help: "Package to deploy")
    var package: String

    @Flag(name: .shortAndLong, help: "Show detailed output.")
    var verbose = false
    
    func run() throws {
        if verbose {
            print("\(Colored.green)[INSTALL]\(Colored.reset) Start deployment for package \(Colored.blue)\(package)\(Colored.reset)")
        }

        print("Installing \(Colored.blue)\(package)\(Colored.reset)")
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

@main
struct flyer: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "flyer",
        abstract: "Source-based package manager in Swift",
        subcommands: [Install.self, Remove.self]
    )
}