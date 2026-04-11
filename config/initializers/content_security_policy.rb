# Content Security Policy
# https://guides.rubyonrails.org/security.html#content-security-policy-header
#
# Notes on this configuration:
#
#   script-src: uses nonces (auto-applied by Rails to importmap tags).
#               'self' covers all scripts loaded from /assets/.
#
#   style-src:  'unsafe-inline' is required for the Trix rich-text editor
#               and for the inline style= attributes in views (e.g. font-family).
#
#   img-src:    'https:' covers Active Storage images in production (S3/CDN).
#               data: covers Trix's base64-embedded images.
#               blob: covers Active Storage preview generation.
#
#   frame-ancestors: :none prevents this site being embedded in iframes (clickjacking).
#
# AdSense / programmatic ads — uncomment and extend these when configured:
#   policy.script_src :self, "https://pagead2.googlesyndication.com"
#   policy.frame_src  "https://googleads.g.doubleclick.net",
#                     "https://tpc.googlesyndication.com"
#   policy.img_src    :self, :https, :data, :blob,
#                     "https://www.google.com", "https://www.gstatic.com"

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :data
    policy.img_src     :self, :https, :data, :blob
    policy.object_src  :none
    policy.script_src  :self
    policy.style_src   :self, :unsafe_inline
    policy.connect_src :self
    policy.frame_ancestors :none
  end

  # Attach a nonce to every importmap <script> tag so they pass the script-src policy.
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w[script-src]

  # To test without breaking anything, switch to report-only mode first:
  # config.content_security_policy_report_only = true
end
