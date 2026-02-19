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

