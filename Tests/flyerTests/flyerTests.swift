import Testing
@testable import flyer
import Foundation

// Dev note: DO NOT use this for anything other than Tests!
func testPackage(name: String, deps: [String], at base: String) throws {
    let path = "\(base)/\(name)"
    try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
    
    let parts = name.components(separatedBy: "/")
    let category = parts.first ?? "unknown"
    let packageName = parts.last ?? "unknown"

    let content = """
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com">
    <plist version="1.0">
    <dict>
        <key>name</key>
        <string>\(packageName)</string>
        <key>category</key>
        <string>\(category)</string>
        <key>version</key>
        <string>1.0</string>
        <key>checksum</key>
        <string>none</string>
        <key>desc</key>
        <string>test</string>
        <key>maintainer</key>
        <string>test</string>
        <key>deps</key>
        <array>
            \(deps.map { "<string>\($0)</string>" }.joined(separator: "\n        "))
        </array>
        <key>source</key>
        <string>https://example.com/src.tar.gz</string>
        <key>build</key>
        <string>make</string>
        <key>install</key>
        <string>make install</string>
        <key>configuring</key>
        <string>./configure</string>
        <key>post</key>
        <string></string>
        <key>remove</key>
        <string></string>
    </dict>
    </plist>
    """
    
    try content.write(toFile: "\(path)/build.plist", atomically: true, encoding: .utf8)
}


// Start tests
@Test func colors() async throws {
    // define Testing variables
    let success = "\(Colored.green)Green\(Colored.reset)"
    let warn = "\(Bold.yellow)This is a warning in bold yellow\(Colored.reset)"
    let intense = "\(Intense.purple)High intensity purple\(Colored.reset)"
    let underline = "\(Underline.cyan)Underlined cyan\(Colored.reset)"
    let bg = "\(Back.red)Red background\(Colored.reset)"

    // Check
    #expect(success == "\u{001B}[32mGreen\u{001B}[0m")
    #expect(warn == "\u{001B}[1;33mThis is a warning in bold yellow\u{001B}[0m")
    #expect(intense == "\u{001B}[0;95mHigh intensity purple\u{001B}[0m")
    #expect(underline == "\u{001B}[4;36mUnderlined cyan\u{001B}[0m")
    #expect(bg == "\u{001B}[41mRed background\u{001B}[0m")
}

@Suite(.serialized)
struct GitTest {
    @Test func git() async throws {
        Paths.base = "/tmp/test-repo"
        let path = Paths.base

        try? FileManager.default.removeItem(atPath: path)
        try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
        
        try Repo.sync()

        let gitPath = path + "/.git"
        #expect(FileManager.default.fileExists(atPath: gitPath))
    }

    @Test func repo() async throws {
        let url = Paths.fetch()
        #expect(url == "/tmp/flyer-test-deps")
    }

    @Test(.enabled(if: Repo.exists)) func syncCommand() async throws {
        try Sync().run()

        let git = "/var/db/repos/oriole/.git"
        #expect(FileManager.default.fileExists(atPath: git))
    }

    @Test(.enabled(if: Repo.exists)) func cacheTest() async throws {
        try Paths.checkCache()

        #expect(FileManager.default.fileExists(atPath: "/var/cache/distfiles"))
    }
}

// These tests only work if installed
@Test(.enabled(if: Repo.exists)) func build() async throws {
    let name = try ParseTest().test_name()
    let version = try ParseTest().test_ver()
    let cfg = try ParseTest().test_cmd()

    #expect(name == "test")
    #expect(version == "1.0")
    #expect(cfg == "mkdir -p STAGING && sh configure --prefix=/usr")
}


@Test func stage() async throws {
    let output = stage(name: "testing", i: 1, max: 1, pkg: "testing")

    #expect(output == "\u{001B}[33m>>> Starting stage\u{001B}[0m testing (\u{001B}[1;33m1\u{001B}[0m of \u{001B}[1;34m1\u{001B}[0m)")
}

@Suite(.serialized)
struct InstallTest {
    @Test func argparse() async throws {
        let args = ["app-misc/test", "--verbose", "--ask"]
        let cmd = try Install.parseAsRoot(args) as! Install

        #expect(cmd.package == "app-misc/test")
        #expect(cmd.verbose == true)
        #expect(cmd.ask == true)
    }

    @Test func installcheck() async throws {
        let args = ["app-misc/test"]
        let cmd = try Install.parse(args)
        let res = cmd.installed(package: "idont/exist")
        #expect(res == false)
    }

    @Test func root() throws {
        var cmd = try Install.parse(["pkg", "--root", "devenv"])
        let normalized = cmd.pdec(path: "/var/db/test")
        #expect(normalized == "devenv/var/db/test")

        let cmd2 = try Install.parse(["pkg", "--root", "/devenv"])
        let normalized2 = cmd2.pdec(path: "/var/db/test")
        #expect(normalized2 == "/devenv/var/db/test")

        let base = "/tmp/flyer-test-deps"
        try? FileManager.default.removeItem(atPath: base)
        Paths.base = base
        defer {
            Paths.base = base
            try? FileManager.default.removeItem(atPath: base)
        }

        try testPackage(name: "sys-libs/B", deps: [], at: base)
        try testPackage(name: "sys-apps/A", deps: ["sys-libs/B"], at: base)

        cmd.root = "devenv"
        let toInstall = try cmd.deps(for: "sys-apps/A")
        #expect(toInstall.count == 1)
        #expect(toInstall.first == "sys-libs/B")
    }

    @Test func removeRootNormalization() throws {
        let cmd = try Remove.parse(["pkg", "--root", "devenv"])
        let normalized = cmd.pdec(path: "/var/db/test")
        #expect(normalized == "/devenv/var/db/test")
    }

    @Test func deps() async throws {
        let base = "/tmp/flyer-test-deps"
        try? FileManager.default.removeItem(atPath: base)

        Paths.base = base

        defer {
            Paths.base = base
            try? FileManager.default.removeItem(atPath: base)
        }

        try testPackage(name: "sys-libs/B", deps: [], at: base)
        try testPackage(name: "sys-apps/A", deps: ["sys-libs/B"], at: base)

        let cmd = try Install.parse(["sys-apps/A"])
        let toInstall = try cmd.deps(for: "sys-apps/A")

        #expect(toInstall.count == 1)
        #expect(toInstall.contains("sys-libs/B"))
        #expect(toInstall.first == "sys-libs/B")
    }
    @Test func verbose() throws {
        let base = "/tmp/flyer-test-deps"
        let dep = "sys-libs/dep"
        let main = "app-misc/test"
        let orig = Paths.base
        Paths.base = base
        
        defer { 
            Paths.base = orig
            try? FileManager.default.removeItem(atPath: base)
        }

        try? FileManager.default.removeItem(atPath: base)
        
        try testPackage(name: dep, deps: [], at: base)
        try testPackage(name: main, deps: [dep], at: base)

        let db = "/tmp/flyer/test-db/\(dep)"
        try? FileManager.default.removeItem(atPath: db)
        try FileManager.default.createDirectory(atPath: db, withIntermediateDirectories: true)
        
        #expect(FileManager.default.fileExists(atPath: db))

        let cmd = try Install.parse([main, "--verbose"])        
        let toInstall = try cmd.deps(for: main)

        #expect(!toInstall.isEmpty)
        
        try? FileManager.default.removeItem(atPath: db)
    }
}

struct TypeTest {
    @Test func pkgtype() async throws {
        let type = installType(category: "app-misc", name: "test", version: "1.0", root: "/tmp/idontexist")
        #expect(type == .new)
    }
    @Test func reinstall() async throws {
        let root = "/tmp/flyer-test"
        let path = "\(root)/app-misc/test"
        try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
    
        let result = installType(category: "app-misc", name: "test", version: "1.0", root: root)
        #expect(result == .reinstall)

        try? FileManager.default.removeItem(atPath: root)
    }
}