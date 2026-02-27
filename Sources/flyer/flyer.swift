import ArgumentParser
import Foundation

@main
struct flyer: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "flyer",
        abstract: "Source-based package manager in Swift",
        version: "0.1.2.1",
        subcommands: [Install.self, Remove.self, Sync.self, Info.self]
    )
}

