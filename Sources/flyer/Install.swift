import Foundation
import ArgumentParser

struct Install: AsyncParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Install a package")

    @Argument(help: "Package to deploy (with category/name)")
    var package: String

    @Flag(name: .shortAndLong, help: "Show detailed output.")
    var verbose = false

    @Flag(name: .shortAndLong, help: "Ask for confirmation before installing.")
    var ask: Bool = false

    func installed(package: String) -> Bool {
        let db = "/var/db/flyer/packages/\(package)"
        return FileManager.default.fileExists(atPath: db)
    }

    func deps(for package: String) throws -> [String] {
        var toInstall: [String] = []
        var seen: Set<String> = []

        func check(pkg: String) throws {
            if seen.contains(pkg) { return }
            seen.insert(pkg)

            let path = "\(Paths.base)/\(pkg)/build.plist"
            let buildFile = try decode(from: URL(fileURLWithPath: path))

            for dep in buildFile.deps {
                if !installed(package: dep) {
                    try check(pkg: dep)
                    if !toInstall.contains(dep) {
                        toInstall.append(dep)
                    }
                } else {
                    if verbose { 
                        print("Dependency \(Colored.blue)\(dep)\(Colored.reset) is already installed, skipping.")
                    }
                }   
            }
        }

        try check(pkg: package)
        return toInstall
    }
    func run() async throws {
        try Repo.sync()

        let cmd = Process()

        let path = "\(Paths.base)/\(package)"
        let build = "\(path)/build.plist"
        let file = FileManager()


        if verbose {
            print("\(Colored.green)[INSTALL]\(Colored.reset) Start deployment for package \(Colored.blue)\(package)\(Colored.reset)")
            print("\(Bold.cyan)Starting\(Colored.reset) tree check for package \(package)")
        }

        if !file.fileExists(atPath: build) {
            print("\(Colored.red)Error: \(Colored.reset) Package \(Colored.blue)\(package)\(Colored.reset) does not exist.")
            return
        }

        let deps = try deps(for: package)
        let all = deps + [package]

        print("These packages would be installed, in order: ")

        for pkg in all {
            let path = "\(Paths.base)/\(pkg)/build.plist"
            let url = URL(fileURLWithPath: path)
            let build = try decode(from: url)
            let repo = url.deletingLastPathComponent().deletingLastPathComponent().lastPathComponent
            let installed = installed(package: pkg)
            let status = installed ? "R" : "N"
            let color = installed ? Colored.blue : Colored.green

            print("[\(Bold.yellow)r:\(repo)\(Colored.reset) \(color)\(status)\(Colored.reset)] \(Colored.blue)\(pkg)-\(build.version)\(Colored.reset)")
        }

        let total = all.count
        let count = all.filter { !self.installed(package: $0) }.count
        let skip = total - count

        print("Total: \(Bold.yellow)\(total)\(Colored.reset) packages (\(Bold.yellow)\(count)\(Colored.reset) new, \(Bold.yellow)\(skip)\(Colored.reset) skipped)")
        if ask {
            var confirmed = false
            while true {
                print("\n\(Bold.yellow)Is this ok?\(Colored.reset) (yes/no)")
                try? FileHandle.standardOutput.synchronize()

                guard let input = readLine()?.lowercased().trimmingCharacters(in: .whitespaces) else {
                    continue
                }

                if ["yes", "y"].contains(input) {
                    confirmed = true
                    break
                } else if ["no", "n"].contains(input) {
                    confirmed = false
                    break
                } else {
                    print("\(Bold.white)Sorry, response not understood.\(Colored.reset) (yes/no)")
                }
            }

            if !confirmed {
                print("Exiting.")
                return
            }
        }

        for pkg in all { 

            if pkg != package && self.installed(package: pkg) {
                if verbose {
                    print("\(Colored.purple)Skipping\(Colored.reset) package \(pkg)")
                }
            }

            let buildPath = "\(Paths.base)/\(pkg)/build.plist"
            let buildFile = try decode(from: URL(fileURLWithPath: buildPath))

            print("\(Bold.green)Found\(Colored.reset) \(package), starting build")

            stage(name: "download", i: 1, max: 9)
            print("\(Colored.green)Starting\(Colored.reset) download for \(Colored.blue)\(package)\(Colored.reset)")

            guard let source = URL(string: buildFile.source) else {
                print("\(Colored.red)Error:\(Colored.reset) Invalid source URL: \(buildFile.source)")
                return
            }
            do {
                let url = try await download(from: source)
                print("\(Colored.green)Download successful\(Colored.reset) for \(Colored.blue)\(package)\(Colored.reset) at path \(url.path)")
            } catch {
                print("\(Colored.red)Download failed\(Colored.reset) for \(Colored.blue)\(package)\(Colored.reset): \(error.localizedDescription)")
                return
            }

            stage(name: "extract", i: 2, max: 9)

            try file.createDirectory(atPath: "/var/tmp/flyer/\(buildFile.category)/\(buildFile.name)-\(buildFile.version)", withIntermediateDirectories: true)

            cmd.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
            if verbose {
                cmd.arguments = ["xfv", "/var/cache/distfiles/\(source.lastPathComponent)", "-C", "/var/tmp/flyer/\(buildFile.category)/\(buildFile.name)-\(buildFile.version)"]
            } else {
                cmd.arguments = ["xf", "/var/cache/distfiles/\(source.lastPathComponent)", "-C", "/var/tmp/flyer/\(buildFile.category)/\(buildFile.name)-\(buildFile.version)"]
            }

            try cmd.run()
            cmd.waitUntilExit()
            if cmd.terminationStatus != 0 {
                print("\(Colored.red)>>> Error\(Colored.reset) while extracting archive for \(Colored.blue)\(package)\(Colored.reset)")
                return
            }
            
            stage(name: "configure", i: 3, max: 9)
            print("\(Colored.green)Configuring\(Colored.reset) for package \(Colored.blue)\(package)\(Colored.reset)")

            let cfgcmd = Process()
            cfgcmd.executableURL = URL(fileURLWithPath: "/bin/sh")
            cfgcmd.arguments = ["-c", buildFile.configuring]
            cfgcmd.currentDirectoryURL = URL(fileURLWithPath: "/var/tmp/flyer/\(buildFile.category)/\(buildFile.name)-\(buildFile.version)")
            
            try cfgcmd.run()
            cfgcmd.waitUntilExit()

            if cfgcmd.terminationStatus != 0 {
                print("\(Colored.red)>>> Error\(Colored.reset) while configuring package \(Colored.blue)\(package)\(Colored.reset)")
                return
            }

            stage(name: "build", i: 4, max: 9)
            print("\(Colored.green)Building\(Colored.reset) for package \(Colored.blue)\(package)\(Colored.reset)")

            let buildcmd = Process()

            buildcmd.executableURL = URL(fileURLWithPath: "/bin/sh")
            buildcmd.arguments = ["-c", buildFile.build]
            buildcmd.currentDirectoryURL = URL(fileURLWithPath: "/var/tmp/flyer/\(buildFile.category)/\(buildFile.name)-\(buildFile.version)")

            try buildcmd.run()
            buildcmd.waitUntilExit()

            if buildcmd.terminationStatus != 0 {
                print("\(Colored.red)>>> Error\(Colored.reset) while building package \(Colored.blue)\(package)\(Colored.reset)")
                return
            }

            stage(name: "staging install", i: 5, max: 9)
            let stagecmd = Process()

            stagecmd.executableURL = URL(fileURLWithPath: "/bin/sh")
            stagecmd.arguments = ["-c", buildFile.install]
            stagecmd.currentDirectoryURL = URL(fileURLWithPath: "/var/tmp/flyer/\(buildFile.category)/\(buildFile.name)-\(buildFile.version)")   

            try stagecmd.run()
            stagecmd.waitUntilExit()

            if stagecmd.terminationStatus != 0 {
                print("\(Colored.red)>>> Error\(Colored.reset) while temporary installing package \(Colored.blue)\(package)\(Colored.reset)")
                return
            }

            stage(name: "check", i: 6, max: 9)
            print("\(Bold.yellow)Checking for file collisions...\(Colored.reset)")

            let staging = "/var/tmp/flyer/\(buildFile.category)/\(buildFile.name)-\(buildFile.version)/STAGING"
            let check_enumerator = file.enumerator(atPath: staging) 
            var collisions: [String] = []

            while let rel = check_enumerator?.nextObject() as? String {
                let targetPath = "/" + rel
                var isDir: ObjCBool = false

                if file.fileExists(atPath: targetPath, isDirectory: &isDir) {
                    if !isDir.boolValue {
                        collisions.append(targetPath)
                    }
                }
            }

            if !collisions.isEmpty {
                print("\(Colored.red)!!!\(Colored.reset) \(Colored.yellow)Collisions detected\(Colored.reset)")
                if !verbose {
                    for c in collisions.prefix(10) { 
                        print("\(Colored.red)*\(Colored.reset) \(c)")
                    }
                    if collisions.count > 10 {
                        print("and \(collisions.count) more.")
                    }
                } else {
                    print("Showing full list of file collisions")
                    for c in collisions {
                        print("\(Colored.red)*\(Colored.reset) \(c)")
                    }
                }

                print("If you don't know where these files came from or you don't need them, you can safely ignore this warning.")
                print("\(Bold.red)If you need these files in their current version, it's best to cancel.\(Colored.reset)")

                if ask {
                    print("\n\(Bold.yellow)Is this ok?\(Colored.reset) (yes/no)")
                    try? FileHandle.standardOutput.synchronize()

                    if let response = readLine()?.lowercased(), response == "yes" || response == "y" {
                        print("\(Colored.green)Continuing installation.\(Colored.reset)")
                    } else {
                        print("\(Colored.red)Cancelled.\(Colored.reset)")
                        return
                    }
                } else {
                    for i in (1...10).reversed() {
                        print("\rWaiting \(i) seconds before installing...")
                        try? FileHandle.standardOutput.synchronize()

                        let input = await Task.detached {
                            var descriptor = pollfd(fd: STDIN_FILENO, events: Int16(POLLIN), revents: 0)
                            let result = poll(&descriptor, 1, 1000)
                            return result > 0
                        }.value

                        if input {
                            _ = readLine()
                            print("\n\(Colored.green)Starting install\(Colored.reset)")
                            break
                        }

                        if i == 1 {
                            print("\n\(Colored.yellow)Forcing install start, time's over.\(Colored.reset)")
                        }
                    }
                }
            }
            stage(name: "install", i: 7, max: 9)
            print("\(Colored.green)Deploying\(Colored.reset) package \(Colored.blue)\(package)\(Colored.reset)")
            let installcmd = Process()

            installcmd.executableURL = URL(fileURLWithPath: "/bin/sh")
            installcmd.arguments = ["-c", "cp -rv /var/tmp/flyer/\(buildFile.category)/\(buildFile.name)-\(buildFile.version)/STAGING/* /"]
            
            try installcmd.run()
            installcmd.waitUntilExit()

            if installcmd.terminationStatus != 0 {
                print("\(Colored.red)>>> Error\(Colored.reset) while deploying to system package \(Colored.blue)\(package)\(Colored.reset) to system")
                return
            }

            // We need to register the installed package in the database for simple removal.
            print("\(Colored.green)Installed\(Colored.reset) package \(Colored.blue)\(package)\(Colored.reset)")
            print("\(Colored.blue)>>> Registering package\(Colored.reset) \(Colored.reset)\(package)\(Colored.reset)")
            
            let prefix = "STAGING/"
            let db = "/var/db/flyer/packages/\(buildFile.category)/\(buildFile.name)"
            try file.createDirectory(atPath: db, withIntermediateDirectories: true)

            let enumerator = file.enumerator(atPath: "/var/tmp/flyer/\(buildFile.category)/\(buildFile.name)-\(buildFile.version)")
            var installed: [String] = []

            while let rel = enumerator?.nextObject() as? String {
                if rel.hasPrefix(prefix) {
                    let fullPath = URL(fileURLWithPath: "/var/tmp/flyer/\(buildFile.category)/\(buildFile.name)-\(buildFile.version)")
                        .appendingPathComponent(rel)

                    var isDir: ObjCBool = false
                    if file.fileExists(atPath: fullPath.path, isDirectory: &isDir), !isDir.boolValue {
                        let cleaned = String(rel.dropFirst(prefix.count))
                        installed.append("/\(cleaned)")
                    }
                }
            }

            let contents = "\(db)/CONTENTS"
            let fileContents = installed.joined(separator: "\n")
            try fileContents.write(toFile: contents, atomically: true, encoding: .utf8)

            stage(name: "post", i: 8, max: 9)
            let postcmd = Process()
            if !buildFile.post.isEmpty {
                print("\(Colored.green)Running \(Colored.reset) post-install scripts for package \(Colored.blue)\(package)\(Colored.reset)")
                postcmd.executableURL = URL(fileURLWithPath: "/bin/sh")
                postcmd.arguments = ["-c", buildFile.post]
                postcmd.currentDirectoryURL = URL(fileURLWithPath: "/var/tmp/flyer/\(buildFile.category)/\(buildFile.name)-\(buildFile.version)")   

                try postcmd.run()
                postcmd.waitUntilExit()

                if postcmd.terminationStatus != 0 {
                    print("\(Colored.red)>>> Error\(Colored.reset) while running post-install script for package \(Colored.blue)\(package)\(Colored.reset)")
                    return
                }
            }

            stage(name: "cleanup", i: 9, max: 9)  
            print("\(Colored.yellow)Cleaning up\(Colored.reset) for package \(Colored.blue)\(package)\(Colored.reset)")
            try file.removeItem(atPath: "/var/tmp/flyer/\(buildFile.category)/\(buildFile.name)-\(buildFile.version)")

            print("\(Bold.green)Installation complete\(Colored.reset) for package \(Colored.blue)\(package)\(Colored.reset)!")
        }
    }
}