
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

        let cmd = Process()

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

        stage(name: "download", i: 1, max: 8)
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

        stage(name: "extract", i: 2, max: 8)

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
        
        stage(name: "configure", i: 3, max: 8)
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

        stage(name: "build", i: 4, max: 8)
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

        stage(name: "stage", i: 5, max: 8)
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

        stage(name: "install", i: 6, max: 8)
        print("\(Colored.green)Deploying\(Colored.reset) package \(Colored.blue)\(package)\(Colored.reset)")
        let installcmd = Process()

        installcmd.executableURL = URL(fileURLWithPath: "/bin/sh")
        installcmd.arguments = ["-c", "cp -r /var/tmp/flyer/\(buildFile.category)/\(buildFile.name)-\(buildFile.version)/STAGING/* /"]
        
        try installcmd.run()
        installcmd.waitUntilExit()

        if installcmd.terminationStatus != 0 {
            print("\(Colored.red)>>> Error\(Colored.reset) while deploying to system package \(Colored.blue)\(package)\(Colored.reset) to system")
            return
        }
 

        stage(name: "post", i: 7, max: 8)
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

        stage(name: "cleanup", i: 8, max: 8)  
        print("\(Colored.yellow)Cleaning up\(Colored.reset) for package \(Colored.blue)\(package)\(Colored.reset)")
        try file.removeItem(atPath: "/var/tmp/flyer/\(buildFile.category)/\(buildFile.name)-\(buildFile.version)")

        print("\(Bold.green)Installation complete\(Colored.reset) for package \(Colored.blue)\(package)\(Colored.reset)!")
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