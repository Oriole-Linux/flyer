import ArgumentParser

struct Sync: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Sync the build repository")
    
    func run() throws {
        try Repo.sync()
    }
}