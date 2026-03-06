# Skill: Security Review

Perform a security audit of the specified code or the entire application.

## Steps

1. Run Brakeman for automated analysis: `bundle exec brakeman -q`
2. Manual review for OWASP Top 10 vulnerabilities:

### Authentication & Authorization
- Verify authentication is required for protected endpoints
- Check authorization (Pundit/CanCanCan policies) for resource access
- Look for insecure direct object references (IDOR)

### Input Validation
- SQL injection: parameterized queries used everywhere?
- XSS: user input properly escaped in views?
- Mass assignment: strong parameters correctly configured?
- File upload: type/size validation in place?

### Data Protection
- Secrets not hardcoded (use Rails credentials or ENV)
- Sensitive data not logged (filter_parameters configured)
- CSRF protection enabled on state-changing endpoints
- Secure headers configured (CSP, HSTS, X-Frame-Options)

### Dependencies
- Check for known vulnerabilities: `bundle audit check`
- Review Gemfile for outdated gems with security patches

## Output
- Categorize findings by severity: critical / high / medium / low
- Include CWE references where applicable
- Provide remediation steps for each finding
