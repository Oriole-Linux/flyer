import Foundation
/* Some users might be running this on a Mac. For me, it was on Foundation built-in, so let's only do this on Linux hosts.*/
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

func download(from url: URL) async throws -> URL {
    let fm = FileManager.default
    let path = "/var/cache/distfiles"
    let cache = URL(fileURLWithPath: path)

    let file = url.lastPathComponent
    let dest = cache.appendingPathComponent(file)
    
    if !fm.fileExists(atPath: cache.path) {
        do {
            try fm.createDirectory(at: cache, withIntermediateDirectories: true, attributes: nil)
            print("\(Colored.green)INFO:\(Colored.reset) Created cache directory at \(cache.path)")
        } catch {
            print("\(Colored.red)Error: \(Colored.reset) Could not create cache directory at \(Colored.blue)\(cache.path)\(Colored.reset): \(error.localizedDescription)")
            throw error
        }
    }
    
    if fm.fileExists(atPath: dest.path) {
        print("File \(Colored.blue)\(url.lastPathComponent)\(Colored.reset) already in cache, skipping.")
        return dest
    }

    print("\(Colored.green)INFO:\(Colored.reset) Starting download task for \(url)...")
    
    let (temp, _) = try await URLSession.shared.download(from: url)

    do {
        if fm.fileExists(atPath: dest.path) {
            print("\(Colored.green)INFO:\(Colored.reset) Removing existing file at \(dest.path)")
            try fm.removeItem(at: dest)
        }

        print("\(Colored.green)INFO:\(Colored.reset) Moving temp file from \(temp.path) to \(dest.path)")
        try fm.moveItem(at: temp, to: dest)

        print("\(Colored.green)>>> Download complete\(Colored.reset) for file \(Colored.blue)\(file)\(Colored.reset)")
        return dest
    } catch {
        print("\(Colored.red)ERROR:\(Colored.reset) Failed to move file: \(error.localizedDescription)")
        throw error
    }
}