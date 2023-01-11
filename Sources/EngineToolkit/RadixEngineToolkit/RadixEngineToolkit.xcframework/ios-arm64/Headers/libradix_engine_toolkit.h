#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

typedef char *Pointer;

Pointer information(Pointer string_pointer);

Pointer convert_manifest(Pointer string_pointer);

Pointer compile_transaction_intent(Pointer string_pointer);

Pointer compile_signed_transaction_intent(Pointer string_pointer);

Pointer compile_notarized_transaction_intent(Pointer string_pointer);

Pointer decompile_transaction_intent(Pointer string_pointer);

Pointer decompile_signed_transaction_intent(Pointer string_pointer);

Pointer decompile_notarized_transaction_intent(Pointer string_pointer);

Pointer decompile_unknown_transaction_intent(Pointer string_pointer);

Pointer derive_non_fungible_address(Pointer string_pointer);

Pointer derive_non_fungible_address_from_public_key(Pointer string_pointer);

Pointer derive_virtual_account_address(Pointer string_pointer);

Pointer encode_address(Pointer string_pointer);

Pointer decode_address(Pointer string_pointer);

Pointer sbor_encode(Pointer string_pointer);

Pointer sbor_decode(Pointer string_pointer);

Pointer toolkit_alloc(uintptr_t capacity);

void toolkit_free(Pointer pointer, uintptr_t capacity);

void toolkit_free_c_string(Pointer pointer);
