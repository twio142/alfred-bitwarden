include "bw";

# Format an item for Alfred
def alfred(f; v; a; i):
  {
    title: "\(f)",
    subtitle: "\(a)",
    arg: v,
    icon: { path: "icons/\(if i == "" then "icon" else i end).png" },
    variables: {
      field: f
    }
  }
;

##################################################
# Main

.data.data[] |
  [
    # Common
    if .notes then alfred("Notes"; .notes; .notes; "note") else empty end,

    # Login
    if .login.username then alfred("Username"; .login.username; .login.username; "user") else empty end,
    if .login.password then alfred("Password"; .login.password; "********"; "password") else empty end,
    if .login.totp then alfred("TOTP Secret"; .login.totp; "********"; "totp") else empty end,
    if .login.uris then [ .login.uris[] | alfred("URL"; .uri; .uri; "url") ] else empty end,

    # Card
    if .card.number then alfred("Number"; .card.number; .card.number; "card") else empty end,
    if .card.code then alfred("CCV"; .card.code; "***"; "password") else empty end,
    if .card.expMonth and .card.expYear then alfred("Expiration"; "\(.card.expMonth)/\(.card.expYear)"; "\(.card.expMonth)/\(.card.expYear)"; "calendar") else empty end,

    # Identity
    if .identity.title then alfred("Title"; .identity.title; .identity.title; "id") else empty end,
    if .identity.firstName then alfred("First"; .identity.firstName; .identity.firstName; "user") else empty end,
    if .identity.middleName then alfred("Middle"; .identity.middleName; .identity.middleName; "user") else empty end,
    if .identity.lastName then alfred("Last"; .identity.lastName; .identity.lastName; "user") else empty end,
    if .identity.addres then alfred("Address"; .identity.addres; .identity.addres; "home") else empty end,
    if .identity.city then alfred("City"; .identity.city; .identity.city; "map") else empty end,
    if .identity.state then alfred("State"; .identity.state; .identity.state; "map") else empty end,
    if .identity.postalCode then alfred("ZIP"; .identity.postalCode; .identity.postalCode; "post") else empty end,
    if .identity.country then alfred("Country"; .identity.country; .identity.country; "map") else empty end,
    if .identity.company then alfred("Company"; .identity.company; .identity.company; "company") else empty end,
    if .identity.phone then alfred("Phone"; .identity.phone; .identity.phone; "phone") else empty end,
    if .identity.ssn then alfred("SSN"; .identity.ssn; "***-**-****"; "") else empty end,
    if .identity.username then alfred("Username"; .identity.username; .identity.username; "user") else empty end,
    if .identity.licenseNumber then alfred("License"; .identity.licenseNumber; "********"; "") else empty end,
    if .identity.passportNumber then alfred("Passport"; .identity.passportNumber; .identity.passportNumber; "") else empty end
  ]

  +

  [
    try (.fields[] | if .type < 2 then alfred(.name; .value; if .type == 1 then "********" else .value end; "") else empty end)
    catch empty
  ]
