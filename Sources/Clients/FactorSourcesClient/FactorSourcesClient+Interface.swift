import ClientPrelude
import Profile

// MARK: - FactorSourcesClient
public struct FactorSourcesClient: Sendable {
	public var getFactorSources: GetFactorSources
	public var factorSourcesAsyncSequence: FactorSourcesAsyncSequence
	public var addPrivateHDFactorSource: AddPrivateHDFactorSource

	public init(
		getFactorSources: @escaping GetFactorSources,
		factorSourcesAsyncSequence: @escaping FactorSourcesAsyncSequence,
		addPrivateHDFactorSource: @escaping AddPrivateHDFactorSource
	) {
		self.getFactorSources = getFactorSources
		self.factorSourcesAsyncSequence = factorSourcesAsyncSequence
		self.addPrivateHDFactorSource = addPrivateHDFactorSource
	}
}

// MARK: FactorSourcesClient.GetFactorSources
extension FactorSourcesClient {
	public typealias GetFactorSources = @Sendable () async throws -> FactorSources
	public typealias FactorSourcesAsyncSequence = @Sendable () async -> AnyAsyncSequence<FactorSources>
	public typealias AddPrivateHDFactorSource = @Sendable (PrivateHDFactorSource) async throws -> FactorSourceID
}

extension FactorSourcesClient {
	public func importOlympiaFactorSource(
		mnemonicWithPassphrase: MnemonicWithPassphrase
	) async throws -> FactorSourceID {
		let factorSource = try FactorSource.olympia(
			mnemonicWithPassphrase: mnemonicWithPassphrase
		)
		let privateFactorSource = try PrivateHDFactorSource(
			mnemonicWithPassphrase: mnemonicWithPassphrase,
			hdOnDeviceFactorSource: factorSource
		)
		return try await self.addPrivateHDFactorSource(privateFactorSource)
	}
}
