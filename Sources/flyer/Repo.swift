import Foundation
import ArgumentParser

struct Paths {
    static let base = "/var/db/repos/oriole"
    static let cache = "/var/cache/distfiles"
    static let db = "/var/db/flyer"
    static func check() throws {
        let file = FileManager.default
        if !file.fileExists(atPath: base) {
            do {
                try file.createDirectory(atPath: base, withIntermediateDirectories: true)
                print("\(Colored.green)Created\(Colored.reset) repository folder")
            } catch {
                let e: NSError = error as NSError

                print("\(Bold.red)Creation Error\(Colored.reset) while trying to create \(Colored.blue)\(base)\(Colored.reset)")
                print("\(Colored.red)Error Code: \(e.code)\(Colored.reset)")
                
                if e.code == 513 {
                    print("\(Colored.yellow)Tip: \(Colored.reset) Try running the command as root, i.e. with su or sudo.")
                }

                throw error     
            }
        }
        if !file.fileExists(atPath: db) {
            do {
                try file.createDirectory(atPath: db, withIntermediateDirectories: true)
                print("\(Colored.green)Created\(Colored.reset) database directory")
            } catch {
                let e: NSError = error as NSError

                print("\(Bold.red)Error\(Colored.reset) while trying to create \(Colored.blue)\(db)\(Colored.reset)")
                print("\(Colored.red)Error Code: \(e.code)\(Colored.reset)")

                if e.code == 513 {
                    print("\(Colored.yellow)Tip: \(Colored.reset) Try running the command as root, i.e. with su or sudo.")
                }

                throw error
            }
        }
    }

    static func checkCache() throws {
        let file = FileManager.default
        if !file.fileExists(atPath: cache) {
            do {
                try file.createDirectory(atPath: cache, withIntermediateDirectories: true)
                print("\(Colored.green)Created\(Colored.reset) cache folder")
            } catch {
                let e: NSError = error as NSError

                print("\(Bold.red)Creation Error\(Colored.reset) while trying to create \(Colored.blue)\(cache)\(Colored.reset)")
                print("\(Colored.red)Error Code: \(e.code)\(Colored.reset)")
                
                if e.code == 513 {
                    print("\(Colored.yellow)Tip: \(Colored.reset) Try running the command as root, i.e. with su or sudo.")
                }

                throw error     
            }
        }
    }
}

struct Repo {
    static let repo = "https://github.com/Oriole-Linux/packages"

    static func sync() throws {
        try Paths.check()
        let fm: FileManager = FileManager.default
        let git_src = "\(Paths.base)/.git"

        if fm.fileExists(atPath: git_src) {
            print("\(Colored.blue)[*] Starting sync\(Colored.reset) for source tree \(Paths.base)")
            try git(args: ["-C", Paths.base, "pull"])
        } else {
            print("\(Colored.blue)[*] Setting up\(Colored.reset) package source tree")
            try git(args: ["clone", repo, Paths.base])
        }
    }

    private static func git(args: [String]) throws {
        let cmd = Process()
        cmd.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        cmd.arguments = args
        try cmd.run()
        cmd.waitUntilExit()
        if cmd.terminationStatus != 0 {
            throw ExitCode.failure
        }
    }
}