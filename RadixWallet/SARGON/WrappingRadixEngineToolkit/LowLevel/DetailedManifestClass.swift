import Foundation

// MARK: - DetailedManifestClass
public enum DetailedManifestClass: DummySargon {
	case general, transfer
	case validatorClaim([ValidatorAddress], Bool)
	case validatorStake(validatorAddresses: [ValidatorAddress], validatorStakes: [TrackedValidatorStake])
	case validatorUnstake(validatorAddresses: [ValidatorAddress], validatorUnstakes: [TrackedValidatorUnstake], claimsNonFungibleData: [UnstakeDataEntry])
	case accountDepositSettingsUpdate(
		resourcePreferencesUpdates: [String: [String: ResourcePreferenceUpdate]],
		depositModeUpdates: [String: AccountDefaultDepositRule],
		authorizedDepositorsAdded:
		[String: [ResourceOrNonFungible]],
		authorizedDepositorsRemoved:
		[String: [ResourceOrNonFungible]]
	)

	case poolContribution(poolAddresses: [ComponentAddress], poolContributions: [TrackedPoolContribution])
	case poolRedemption(poolAddresses: [ComponentAddress], poolContributions: [TrackedPoolRedemption])

	var isSupported: Bool {
		switch self {
		case .general, .transfer, .poolContribution, .poolRedemption, .validatorStake, .validatorUnstake, .accountDepositSettingsUpdate, .validatorClaim:
			true
		}
	}
}
