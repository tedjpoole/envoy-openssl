#include <openssl/ssl.h>
#include <ossl.h>

void SSL_set_enforce_rsa_key_usage(SSL *ssl, int enabled) {
#if 0 // TODO dcillera - config and enforce_rsa_key_usage not defined in OpenSSL
  if (!ssl->config) {
    return;
  }
  ssl->config->enforce_rsa_key_usage = !!enabled;
#else
  bssl_compat_fatal("SSL_set_enforce_rsa_key_usage() is not implemented");
#endif
}

