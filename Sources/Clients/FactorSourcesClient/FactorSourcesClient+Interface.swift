import ClientPrelude
import Profile

// MARK: - FactorSourcesClient
public struct FactorSourcesClient: Sendable {
	public var getFactorSources: GetFactorSources
	public var importOlympiaFactorSource: ImportOlympiaFactorSource
	public init(
		getFactorSources: @escaping GetFactorSources,
		importOlympiaFactorSource: @escaping ImportOlympiaFactorSource
	) {
		self.getFactorSources = getFactorSources
		self.importOlympiaFactorSource = importOlympiaFactorSource
	}
}

// MARK: FactorSourcesClient.GetFactorSources
extension FactorSourcesClient {
	public typealias GetFactorSources = @Sendable () async throws -> FactorSources
	public typealias ImportOlympiaFactorSource = @Sendable (MnemonicWithPassphrase) async throws -> Void
}
