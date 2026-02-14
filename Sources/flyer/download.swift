import Foundation
/* Some users might be running this on a Mac. For me, it was on Foundation built-in, so let's only do this on Linux hosts.*/
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

func download(from url: URL, completion: @escaping @Sendable (Result<URL, Error>) -> Void) {
    let fm = FileManager.default
    let path = "/var/cache/distfiles"
    let cache = URL(fileURLWithPath: path)

    let file = url.lastPathComponent
    let dest = cache.appendingPathComponent(file)

    if fm.fileExists(atPath: dest.path) {
        print("File \(Colored.blue)\(url.lastPathComponent)\(Colored.reset) already in cache, skipping.")
        completion(.success(dest))
    }

    let task = URLSession.shared.downloadTask(with: url) { (temp, response, error) in 
        if let error = error {
            completion(.failure(error))
            return
        }

        guard let temp = temp else {
            let noData = NSError(domain: "DownloadError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received. The server might be experiencing problems right now."])
            completion(.failure(noData))
            return
        }

        do {
            if fm.fileExists(atPath: dest.path) {
                try fm.removeItem(at: dest)
            }

            try fm.moveItem(at: temp, to: dest)

            print("\(Colored.green)>>> Download complete\(Colored.reset) for file \(Colored.blue)\(file)\(Colored.reset)")
            completion(.success(dest))
        } catch {
            completion(.failure(error))
        }
    }
    task.resume()
}