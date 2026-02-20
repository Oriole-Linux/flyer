import Foundation

@discardableResult
func stage(name: String, i: Int, max: Int) -> String {
    let message = "\(Colored.yellow)>>> Starting stage\(Colored.reset) \(name) (\(Bold.yellow)\(i)\(Colored.reset) of \(Bold.blue)\(max)\(Colored.reset))"
    print(message)
    return message
}