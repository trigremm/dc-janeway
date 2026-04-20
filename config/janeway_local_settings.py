# Janeway local settings — bind-mounted at /app/src/core/janeway_local_settings.py.
# Place here any site-specific Django settings overrides that should NOT live
# in the image. Values from the environment (via docker-compose.yaml env block)
# are already read by Janeway's core/settings.py.
#
# Example overrides you may want:
#
# EMAIL_BACKEND = "django.core.mail.backends.smtp.EmailBackend"
# EMAIL_HOST = "smtp.example.com"
# EMAIL_PORT = 587
# EMAIL_HOST_USER = "no-reply@example.com"
# EMAIL_HOST_PASSWORD = "..."
# EMAIL_USE_TLS = True
# DEFAULT_FROM_EMAIL = "no-reply@example.com"
#
# SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
# USE_X_FORWARDED_HOST = True
