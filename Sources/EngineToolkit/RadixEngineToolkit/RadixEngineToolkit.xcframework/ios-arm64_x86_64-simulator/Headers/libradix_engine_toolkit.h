#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

#define RADIX_ENGINE_HASH_LENGTH 32

typedef char *Pointer;

Pointer information(Pointer string_pointer);

Pointer convert_manifest(Pointer string_pointer);

Pointer extract_addresses_from_manifest(Pointer string_pointer);

Pointer analyze_transaction_execution(Pointer string_pointer);

Pointer compile_transaction_intent(Pointer string_pointer);

Pointer compile_signed_transaction_intent(Pointer string_pointer);

Pointer compile_notarized_transaction(Pointer string_pointer);

Pointer hash_transaction_intent(Pointer string_pointer);

Pointer hash_signed_transaction_intent(Pointer string_pointer);

Pointer hash_notarized_transaction(Pointer string_pointer);

Pointer decompile_transaction_intent(Pointer string_pointer);

Pointer decompile_signed_transaction_intent(Pointer string_pointer);

Pointer decompile_notarized_transaction(Pointer string_pointer);

Pointer decompile_unknown_transaction_intent(Pointer string_pointer);

Pointer derive_babylon_address_from_olympia_address(Pointer string_pointer);

Pointer derive_babylon_resource_address_from_olympia_resource_address(Pointer string_pointer);

Pointer derive_olympia_address_from_public_key(Pointer string_pointer);

Pointer derive_virtual_account_address(Pointer string_pointer);

Pointer derive_virtual_identity_address(Pointer string_pointer);

Pointer encode_address(Pointer string_pointer);

Pointer decode_address(Pointer string_pointer);

Pointer sbor_encode(Pointer string_pointer);

Pointer sbor_decode(Pointer string_pointer);

Pointer known_entity_addresses(Pointer string_pointer);

Pointer statically_validate_transaction(Pointer string_pointer);

Pointer hash(Pointer string_pointer);

Pointer toolkit_alloc(uintptr_t capacity);

void toolkit_free(Pointer pointer, uintptr_t capacity);

void toolkit_free_c_string(Pointer pointer);
