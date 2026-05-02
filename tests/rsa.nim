import os
import strutils

import nimterop/[build, cimport]

setDefines(@["cryptoStd"])
getHeader("openssl/crypto.h")

const
  basePath = cryptoPath.parentDir
  FLAGS {.strdefine.} = ""

# Skipping OPENSSL_VERSION_PRE_RELEASE because it is recognised as both a string and int
static:
  cSkipSymbol(@["ERR_load_crypto_strings", "OpenSSLDie", "OPENSSL_VERSION_PRE_RELEASE"])

cPlugin:
  import strutils

  proc onSymbol*(sym: var Symbol) {.exportc, dynlib.} =
    sym.name = sym.name.strip(chars = {'_'}).replace("__", "_")

    if sym.name in [
      "AES_ENCRYPT", "AES_DECRYPT", "BIO_CTRL_PENDING", "BIO_CTRL_WPENDING",
      "BN_F_BNRAND", "BN_F_BNRAND_RANGE", "CRYPTO_LOCK", "CRYPTO_NUM_LOCKS",
      "CRYPTO_THREADID", "EVP_CIPHER", "OPENSSL_VERSION", "PKCS7_ENCRYPT",
      "PKCS7_STREAM", "SSLEAY_VERSION", "SSL_TXT_ADH", "SSL_TXT_AECDH", "SSL_TXT_kECDHE",
    ]:
      sym.name = "C_" & sym.name

    const letter_case_collisions = [
      "OPENSSL_version_major", "OPENSSL_version_minor", "OPENSSL_version_patch",
      "OPENSSL_version_build_metadata",
    ]

    if sym.name in letter_case_collisions:
      # We append '_lc' (lower case) to keep the identifier unique in Nim
      # while acknowledging why we had to change it.
      sym.name &= "_lc"

cOverride:
  proc OPENSSL_die*(assertion: cstring, file: cstring, line: cint) {.importc.}

cPassL(cryptoLPath)

# Skip comments for https://github.com/tree-sitter/tree-sitter-c/issues/44
cImport(
  @[basePath / "rsa.h", basePath / "err.h"], recurse = true, flags = "-s -c " & FLAGS
)

OpensslInit()
echo $OPENSSL_VERSION_TEXT
