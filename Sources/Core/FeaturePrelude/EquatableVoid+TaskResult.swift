import Prelude

extension TaskResult where Success == EquatableVoid {
	public init(catching body: @Sendable () async throws -> Void) async {
		do {
			try await body()
			self = .success(EquatableVoid())
		} catch {
			self = .failure(error)
		}
	}
}
