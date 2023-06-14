import Foundation

public enum InstructionKind: String, Codable, Sendable, Hashable {
	case callFunction = "CALL_FUNCTION"
	case callMethod = "CALL_METHOD"
	case callRoyaltyMethod = "CALL_ROYALTY_METHOD"
	case callMetadataMethod = "CALL_METADATA_METHOD"
	case callAccessRulesMethod = "CALL_ACCESS_RULES_METHOD"

	case takeAllFromWorktop = "TAKE_ALL_FROM_WORKTOP"
	case takeFromWorktop = "TAKE_FROM_WORKTOP"
	case takeNonFungiblesFromWorktop = "TAKE_NON_FUNGIBLES_FROM_WORKTOP"

	case returnToWorktop = "RETURN_TO_WORKTOP"

	case assertWorktopContains = "ASSERT_WORKTOP_CONTAINS"
	case assertWorktopContainsByAmount = "ASSERT_WORKTOP_CONTAINS_BY_AMOUNT"
	case assertWorktopContainsNonFungibles = "ASSERT_WORKTOP_CONTAINS_NON_FUNGIBLES"

	case popFromAuthZone = "POP_FROM_AUTH_ZONE"
	case pushToAuthZone = "PUSH_TO_AUTH_ZONE"

	case clearAuthZone = "CLEAR_AUTH_ZONE"
	case clearSignatureProofs = "CLEAR_SIGNATURE_PROOFS"

	case createProofFromAuthZone = "CREATE_PROOF_FROM_AUTH_ZONE"
	case createProofFromAuthZoneOfAll = "CREATE_PROOF_FROM_AUTH_ZONE_OF_ALL"
	case createProofFromAuthZoneOfAmount = "CREATE_PROOF_FROM_AUTH_ZONE_OF_AMOUNT"
	case createProofFromAuthZoneOfNonFungibles = "CREATE_PROOF_FROM_AUTH_ZONE_OF_NON_FUNGIBLES"

	case createProofFromBucket = "CREATE_PROOF_FROM_BUCKET"
	case createProofFromBucketAll = "CREATE_PROOF_FROM_BUCKET_OF_ALL"
	case createProofFromBucketOfAmount = "CREATE_PROOF_FROM_BUCKET_OF_AMOUNT"
	case createProofFromBucketOfNonFungibles = "CREATE_PROOF_FROM_BUCKET_OF_NON_FUNGIBLES"

	case cloneProof = "CLONE_PROOF"
	case dropProof = "DROP_PROOF"
	case dropAllProofs = "DROP_ALL_PROOFS"

	case publishPackage = "PUBLISH_PACKAGE"
	case publishPackageAdvanced = "PUBLISH_PACKAGE_ADVANCED"

	case burnResource = "BURN_RESOURCE"
	case recallResource = "RECALL_RESOURCE"

	case setMetadata = "SET_METADATA"
	case removeMetadata = "REMOVE_METADATA"

	case setPackageRoyaltyConfig = "SET_PACKAGE_ROYALTY_CONFIG"
	case setComponentRoyaltyConfig = "SET_COMPONENT_ROYALTY_CONFIG"

	case claimPackageRoyalty = "CLAIM_PACKAGE_ROYALTY"
	case claimComponentRoyalty = "CLAIM_COMPONENT_ROYALTY"
	case setMethodAccessRule = "SET_METHOD_ACCESS_RULE"
	case setAuthorityAccessRule = "SET_AUTHORITY_ACCESS_RULE"
	case setAuthorityMutability = "SET_AUTHORITY_MUTABILITY"

	case mintFungible = "MINT_FUNGIBLE"
	case mintNonFungible = "MINT_NON_FUNGIBLE"
	case mintUuidNonFungible = "MINT_UUID_NON_FUNGIBLE"

	case createFungibleResource = "CREATE_FUNGIBLE_RESOURCE"
	case createFungibleResourceWithInitialSupply = "CREATE_FUNGIBLE_RESOURCE_WITH_INITIAL_SUPPLY"
	case createNonFungibleResource = "CREATE_NON_FUNGIBLE_RESOURCE"
	case createNonFungibleResourceWithInitialSupply = "CREATE_NON_FUNGIBLE_RESOURCE_WITH_INITIAL_SUPPLY"

	case createAccessController = "CREATE_ACCESS_CONTROLLER"
	case createIdentity = "CREATE_IDENTITY"
	case createIdentityAdvanced = "CREATE_IDENTITY_ADVANCED"
	case assertAccessRule = "ASSERT_ACCESS_RULE"

	case createAccount = "CREATE_ACCOUNT"
	case createAccountAdvanced = "CREATE_ACCOUNT_ADVANCED"

	case createValidator = "CREATE_VALIDATOR"
}
