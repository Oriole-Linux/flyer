import Foundation
import ArgumentParser

struct Builder {
    static func phase(_ command: String, in directory: String, phaseName: String) throws {
        guard !command.trimmingCharacters(in: .whitespaces).isEmpty else {
            print("\(Colored.yellow)>>> Skipping\(Colored.reset) \(phaseName)")
            return
        }

        print("\(Colored.blue)>>> Starting phase \(phaseName)\(Colored.reset)")

        let cmd = Process()
        cmd.executableURL = URL(fileURLWithPath: "/bin/sh")
        cmd.arguments = ["-c", command]
        cmd.currentDirectoryURL = URL(fileURLWithPath: directory)

        cmd.environment = ProcessInfo.processInfo.environment

        try cmd.run()
        cmd.waitUntilExit()

        if cmd.terminationStatus != 0 {
            print("\(Bold.red)Error \(Colored.reset) while building phase \(Colored.blue)\(phaseName)\(Colored.reset)")
            throw ExitCode.failure
        }
    }
}