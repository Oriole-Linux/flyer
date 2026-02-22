import Foundation

func setTitle(pkg: String, stage: String) {
    print("\u{1b}]0;flyer: \(stage) for \(pkg)\u{07}", terminator: "")
}

@discardableResult
func stage(name: String, i: Int, max: Int, pkg: String) -> String {
    let message = "\(Colored.yellow)>>> Starting stage\(Colored.reset) \(name) (\(Bold.yellow)\(i)\(Colored.reset) of \(Bold.blue)\(max)\(Colored.reset))"
    print(message)
    setTitle(pkg: pkg, stage: name)
    return message
}
