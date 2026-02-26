import Foundation
import ArgumentParser

struct Remove: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Remove a package")

    @Argument(help: "Package to remove")
    var package: String

    @Flag(name: .shortAndLong, help: "Show detailed output.")
    var verbose = false
    
    @Option(name: .shortAndLong, help: "Target directory (by default /)")
    var root: String = "/"

    func pdec(path: String) -> String {
        if root == "/" { return path }
        return "\(root)/\(path)".replacingOccurrences(of: "//", with: "/")
    }

    func run() throws {
        guard NSUserName() != "root" else {
            print("\(Colored.red)Error:\(Colored.reset) You are not running flyer as root. This won't work.")
            print("\(Colored.yellow)Tip:\(Colored.reset) Try rerunning flyer with \(Colored.cyan)sudo\(Colored.reset).")
            return
        }

        let file = FileManager.default
        let db = pdec(path: "/var/db/flyer/packages/\(package)")
        let contents = "\(db)/CONTENTS"

        guard file.fileExists(atPath: contents) else {
            print("\(Colored.red)Error:\(Colored.reset) Package \(Colored.blue)\(package)\(Colored.reset) not found. \n If you believe this is a mistake, the database may be corrupted.")
            return
        }

        if verbose {
            print("\(Colored.red)[REMOVE]\(Colored.reset) Start removal for package \(Colored.blue)\(package)\(Colored.reset)")
        }

        print("\u{1b}]0;flyer: remove \(package)\u{07}", terminator: "")
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
