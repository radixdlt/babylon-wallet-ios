import Prelude

extension TaskResult where Success == EquatableHashable {
	public init(catching body: @Sendable () async throws -> Void) async {
		do {
			try await body()
			self = .success(EquatableHashable())
		} catch {
			self = .failure(error)
		}
	}
}
