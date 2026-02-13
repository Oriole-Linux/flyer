import Foundation

func stage(name: String, i: Int, max: Int) {
    print("\(Colored.yellow)>>> Starting stage\(Colored.reset) \(name) (\(Bold.yellow)\(i)\(Colored.reset) of \(Bold.blue)\(max)\(Colored.reset))")
}