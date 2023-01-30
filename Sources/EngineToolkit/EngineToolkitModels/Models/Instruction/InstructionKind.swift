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

	case publishPackageWithOwner = "PUBLISH_PACKAGE_WITH_OWNER"

	case createResource = "CREATE_RESOURCE"
	case burnBucket = "BURN_BUCKET"
	case mintFungible = "MINT_FUNGIBLE"
}
