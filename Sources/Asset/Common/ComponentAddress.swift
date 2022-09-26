import Foundation

public typealias ComponentAddress = String

#if DEBUG
public extension ComponentAddress {
	static var random: Self {
		let length = 26
		let characters = "abcdefghijklmnopqrstuvwxyz0123456789"
		return String((0 ..< length).map { _ in characters.randomElement()! })
	}
}
#endif
