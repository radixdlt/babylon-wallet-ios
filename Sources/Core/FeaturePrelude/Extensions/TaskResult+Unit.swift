import Prelude

extension TaskResult where Success == Prelude.Unit {
	public init(catching body: @Sendable () async throws -> Void) async {
		do {
			try await body()
			self = .success(Prelude.Unit())
		} catch {
			self = .failure(error)
		}
	}
}
