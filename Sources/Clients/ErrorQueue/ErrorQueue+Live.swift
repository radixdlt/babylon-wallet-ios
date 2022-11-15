import AsyncAlgorithms
import Dependencies
import Foundation

extension ErrorQueue: DependencyKey {
	public typealias Value = ErrorQueue

	public static var liveValue: Self {
		let errors = AsyncChannel<Error>()
		return Self(
			errors: { errors },
			schedule: { error in
				Task {
					await errors.send(error)
				}
			}
		)
	}
}
