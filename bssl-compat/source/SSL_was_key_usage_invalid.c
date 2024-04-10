#include <openssl/ssl.h>
#include <ossl.h>
#include "log.h"

int SSL_was_key_usage_invalid(const SSL *ssl) {
// TODO dcillera - was_key_usage_invalid not present in OpenSSL
#if 0
  return ssl->s3->was_key_usage_invalid;
#else
  bssl_compat_fatal("SSL_was_key_usage_invalid() is not implemented");
  return 0;
#endif

}

