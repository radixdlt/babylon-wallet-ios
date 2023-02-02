import Foundation

public enum InstructionKind: String, Codable, Sendable, Hashable {
	case callFunction = "CALL_FUNCTION"
	case callMethod = "CALL_METHOD"

	case takeFromWorktop = "TAKE_FROM_WORKTOP"
	case takeFromWorktopByAmount = "TAKE_FROM_WORKTOP_BY_AMOUNT"
	case takeFromWorktopByIds = "TAKE_FROM_WORKTOP_BY_IDS"

	case returnToWorktop = "RETURN_TO_WORKTOP"

	case assertWorktopContains = "ASSERT_WORKTOP_CONTAINS"
	case assertWorktopContainsByAmount = "ASSERT_WORKTOP_CONTAINS_BY_AMOUNT"
	case assertWorktopContainsByIds = "ASSERT_WORKTOP_CONTAINS_BY_IDS"

	case popFromAuthZone = "POP_FROM_AUTH_ZONE"
	case pushToAuthZone = "PUSH_TO_AUTH_ZONE"

	case clearAuthZone = "CLEAR_AUTH_ZONE"

	case createProofFromAuthZone = "CREATE_PROOF_FROM_AUTH_ZONE"
	case createProofFromAuthZoneByAmount = "CREATE_PROOF_FROM_AUTH_ZONE_BY_AMOUNT"
	case createProofFromAuthZoneByIds = "CREATE_PROOF_FROM_AUTH_ZONE_BY_IDS"

	case createProofFromBucket = "CREATE_PROOF_FROM_BUCKET"

	case cloneProof = "CLONE_PROOF"
	case dropProof = "DROP_PROOF"
	case dropAllProofs = "DROP_ALL_PROOFS"

	case publishPackage = "PUBLISH_PACKAGE"
	case publishPackageWithOwner = "PUBLISH_PACKAGE_WITH_OWNER"

	case burnResource = "BURN_RESOURCE"
	case recallResource = "RECALL_RESOURCE"

	case setMetadata = "SET_METADATA"

	case setPackageRoyaltyConfig = "SET_PACKAGE_ROYALTY_CONFIG"
	case setComponentRoyaltyConfig = "SET_COMPONENT_ROYALTY_CONFIG"

	case claimPackageRoyalty = "CLAIM_PACKAGE_ROYALTY"
	case claimComponentRoyalty = "CLAIM_COMPONENT_ROYALTY"
	case setMethodAccessRule = "SET_METHOD_ACCESS_RULE"

	case mintFungible = "MINT_FUNGIBLE"
	case mintNonFungible = "MINT_NON_FUNGIBLE"
	case mintUuidNonFungible = "MINT_UUID_NON_FUNGIBLE"

	case createFungibleResource = "CREATE_FUNGIBLE_RESOURCE"
	case createFungibleResourceWithOwner = "CREATE_FUNGIBLE_RESOURCE_WITH_OWNER"
	case createNonFungibleResource = "CREATE_NON_FUNGIBLE_RESOURCE"
	case createNonFungibleResourceWithOwner = "CREATE_NON_FUNGIBLE_RESOURCE_WITH_OWNER"

	case createAccessController = "CREATE_ACCESS_CONTROLLER"
	case createIdentity = "CREATE_IDENTITY"
	case assertAccessRule = "ASSERT_ACCESS_RULE"

	case createValidator = "CREATE_VALIDATOR"
}
