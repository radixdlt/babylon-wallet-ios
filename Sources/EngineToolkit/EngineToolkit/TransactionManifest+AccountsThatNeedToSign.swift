import Cryptography
import EngineToolkitModels
import Prelude

public extension TransactionManifest {
	func accountsRequiredToSign(
		networkId: NetworkID
	) throws -> Set<ComponentAddress> {
		let convertedManifest = try EngineToolkit().convertManifest(request: ConvertManifestRequest(
			manifest: self,
			outputFormat: .parsed,
			networkId: networkId
		)).get()

		switch convertedManifest.instructions {
		case let .parsed(instructions):
			var accountsRequiredToSign: Set<ComponentAddress> = []
			for instruction in instructions {
				switch instruction {
				case let .callMethod(callMethodInstruction):
					let isMethodThatRequiresAuth = [
						"lock_fee",
						"lock_contingent_fee",
						"withdraw",
						"withdraw_by_amount",
						"withdraw_by_ids",
						"lock_fee_and_withdraw",
						"lock_fee_and_withdraw_by_amount",
						"lock_fee_and_withdraw_by_ids",
						"create_proof",
						"create_proof_by_amount",
						"create_proof_by_ids",
					].contains(callMethodInstruction.methodName)

					if let accountAddress = callMethodInstruction.receiver.asAccountComponentAddress, isMethodThatRequiresAuth {
						accountsRequiredToSign.insert(accountAddress)
					}
				case let .setMetadata(setMetadataInstruction):
					if let accountAddress = setMetadataInstruction.entityAddress.asAccountComponentAddress {
						accountsRequiredToSign.insert(accountAddress)
					}
				case let .setMethodAccessRule(setMethodAccessRuleInstruction):
					if let accountAddress = setMethodAccessRuleInstruction.entityAddress.asAccountComponentAddress {
						accountsRequiredToSign.insert(accountAddress)
					}
				case let .setComponentRoyaltyConfig(setCompœonentRoyaltyConfigInstruction):
					if let accountAddress = setCompœonentRoyaltyConfigInstruction.componentAddress.asAccountComponentAddress {
						accountsRequiredToSign.insert(accountAddress)
					}
				case let .claimComponentRoyalty(claimComponentRoyaltyInstruction):
					if let accountAddress = claimComponentRoyaltyInstruction.componentAddress.asAccountComponentAddress {
						accountsRequiredToSign.insert(accountAddress)
					}
				default:
					break
				}
			}

			return accountsRequiredToSign
		case .string:
			fatalError("Converted the manifest to Parsed by instead received a string manifest!")
		}
	}
}
