import Foundation

extension DispatchTimeInterval {
	static func minutes(_ amount: Int) -> Self {
		.seconds(amount * 60)
	}
}
