import ClientPrelude
import Profile

// MARK: - FactorSourcesClient
public struct FactorSourcesClient: Sendable {
	public var getFactorSources: GetFactorSources
	public var factorSourcesAsyncSequence: FactorSourcesAsyncSequence
	public var importOlympiaFactorSource: ImportOlympiaFactorSource

	public init(
		getFactorSources: @escaping GetFactorSources,
		factorSourcesAsyncSequence: @escaping FactorSourcesAsyncSequence,
		importOlympiaFactorSource: @escaping ImportOlympiaFactorSource
	) {
		self.getFactorSources = getFactorSources
		self.factorSourcesAsyncSequence = factorSourcesAsyncSequence
		self.importOlympiaFactorSource = importOlympiaFactorSource
	}
}

// MARK: FactorSourcesClient.GetFactorSources
extension FactorSourcesClient {
	public typealias GetFactorSources = @Sendable () async throws -> FactorSources
	public typealias FactorSourcesAsyncSequence = @Sendable () async -> AnyAsyncSequence<FactorSources>
	public typealias ImportOlympiaFactorSource = @Sendable (MnemonicWithPassphrase) async throws -> Void
}
