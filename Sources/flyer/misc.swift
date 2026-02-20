import Foundation

@discardableResult
func stage(name: String, i: Int, max: Int, pkg: String = Install().package) -> String {
    let message = "\(Colored.yellow)>>> Starting stage\(Colored.reset) \(name) (\(Bold.yellow)\(i)\(Colored.reset) of \(Bold.blue)\(max)\(Colored.reset))"
    print(message)
    setTitle(title: "flyer: \(name): \(pkg)")
    return message
}