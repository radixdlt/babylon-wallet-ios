import Foundation

public typealias Address = String

#if DEBUG
public extension Address {
	static var random: Self {
		let length = 26
		let characters = "abcdefghijklmnopqrstuvwxyz0123456789"
		return String((0 ..< length).map { _ in characters.randomElement()! })
	}
}
#endif
