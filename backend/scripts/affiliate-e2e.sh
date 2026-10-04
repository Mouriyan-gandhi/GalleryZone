#!/bin/bash
# Real stack, no stubs: Firestore + Auth emulators, the built API, the seed script, HTTP in between.
#   npm run e2e:affiliate        (needs Java and a built API; this script builds it)
#
# STATUS: written and NEVER RUN. It was drafted at the end of the session that built the
# affiliate shelf and the run was skipped. Expect to fix small things (the JSON helper, the
# emulator ports, a status code you disagree with). Treat a failure as "check the script"
# before "check the API", then read /tmp/api.log. The lookup step calls real amazon.in and
# is allowed to answer 422 when Amazon serves a captcha.
cd "$(dirname "$0")/.."
export FIREBASE_PROJECT_ID=demo-gz GCP_PROJECT_ID=demo-gz PORT=8099 NODE_ENV=development
A=http://127.0.0.1:8099
AUTH=http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1
FS=http://127.0.0.1:8080
fail() { echo "FAIL: $*"; kill $API 2>/dev/null; exit 1; }
ok() { echo "ok   $*"; }
j() { node -e "let s='';process.stdin.on('data',d=>s+=d).on('end',()=>{const o=JSON.parse(s);console.log(eval('o'+process.argv[1]))})" "$1"; }

npm run build --silent || exit 1

echo "--- seed (dry, then real, then again)"
node --experimental-strip-types scripts/seed-affiliate-products.ts --dry | tail -3
node --experimental-strip-types scripts/seed-affiliate-products.ts | tee /tmp/seed1.txt
node --experimental-strip-types scripts/seed-affiliate-products.ts | tee /tmp/seed2.txt
grep -q "added 118, already on the shelf 0" /tmp/seed1.txt || fail "first seed"
grep -q "added 0, already on the shelf 118" /tmp/seed2.txt || fail "second seed should change nothing"
ok "seed adds 118, then adds nothing"

node --experimental-strip-types apps/api/dist/main.js > /tmp/api.log 2>&1 &
API=$!
for i in $(seq 1 60); do curl -sf $A/v1/health >/dev/null && break; sleep 0.5; done
curl -sf $A/v1/health >/dev/null || { cat /tmp/api.log | tail -20; fail "api did not start"; }
ok "api up"

echo "--- public list"
curl -s -D /tmp/h.txt $A/v1/affiliate-products -o /tmp/list.json
[ "$(j '.products.length' < /tmp/list.json)" = 118 ] || fail "public list length"
grep -qi "cache-control: public" /tmp/h.txt || fail "cache header"
[ "$(j '.products[0].asin' < /tmp/list.json)" = "B0CKW9P9Z7" ] || echo "note: first asin $(j '.products[0].asin' < /tmp/list.json) (chat order)"
node -e "const l=require('/tmp/list.json').products; const p=l[0]; console.log(Object.keys(p).sort().join(','))" | grep -q "active,asin,brand,category,createdAt,images,id,title,updatedAt,url" && ok "118 products, fields as the web expects, cacheable"
node -e "const l=require('/tmp/list.json').products; const t=l.map(p=>p.createdAt); if (JSON.stringify(t)!==JSON.stringify([...t].sort())) process.exit(1)" && ok "oldest first (chat order kept)"
grep -q '"price' /tmp/list.json && fail "a price field leaked into the public list"
ok "no price field anywhere"

echo "--- admin routes refuse the public"
[ "$(curl -s -o /dev/null -w '%{http_code}' $A/v1/admin/affiliate-products)" = 401 ] || fail "admin list without token should be 401"
[ "$(curl -s -o /dev/null -w '%{http_code}' -X POST -H 'content-type: application/json' -d '{}' $A/v1/admin/affiliate-products)" = 401 ] || fail "admin create without token should be 401"
ok "401 without a token"

echo "--- sign in as an admin and as a customer"
mk() { # email role -> idToken
  local r uid
  r=$(curl -s -X POST "$AUTH/accounts:signUp?key=x" -H 'content-type: application/json' -d "{\"email\":\"$1\",\"password\":\"secret123\",\"returnSecureToken\":true}")
  uid=$(echo "$r" | j '.localId'); tok=$(echo "$r" | j '.idToken')
  curl -s -X PATCH "$FS/v1/projects/demo-gz/databases/(default)/documents/users/$uid" -H 'Authorization: Bearer owner' -H 'content-type: application/json' \
    -d "{\"fields\":{\"role\":{\"stringValue\":\"$2\"},\"status\":{\"stringValue\":\"active\"},\"name\":{\"stringValue\":\"T\"},\"email\":{\"stringValue\":\"$1\"},\"roleGrants\":{\"arrayValue\":{}}}}" >/dev/null
  echo "$tok"
}
ADMIN=$(mk admin@example.in admin); CUST=$(mk cust@example.in customer)
[ "$(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: Bearer $CUST" $A/v1/admin/affiliate-products)" = 403 ] || fail "customer should be 403"
ok "customer gets 403"
curl -s -H "Authorization: Bearer $ADMIN" $A/v1/admin/affiliate-products -o /tmp/alist.json
[ "$(j '.products.length' < /tmp/alist.json)" = 118 ] || fail "admin list: $(head -c 300 /tmp/alist.json)"
ok "admin lists 118"

echo "--- create: validation, then a real add, then a duplicate"
post() { curl -s -w '\n%{http_code}' -X "$1" -H "Authorization: Bearer $ADMIN" -H 'content-type: application/json' -d "$3" "$A$2"; }
IMG='"images":["https://m.media-amazon.com/images/I/aaa._SL1500_.jpg"]'
for bad in \
  '{"url":"https://evil.example/x","title":"Thing","category":"Paints",'$IMG'}' \
  '{"url":"http://link.amazon/B1","title":"Thing","category":"Paints",'$IMG'}' \
  '{"url":"https://link.amazon/B1","title":"Thing","category":"Paints","images":["http://insecure/x.jpg"]}' \
  '{"url":"https://link.amazon/B1","title":"Thing","category":"Paints","images":[]}' \
  '{"url":"https://link.amazon/B1","title":"Thing","category":"Paints",'$IMG',"price":100}' ; do
  code=$(post POST /v1/admin/affiliate-products "$bad" | tail -1); [ "$code" = 400 ] || fail "bad body should be 400, got $code: $bad"
done
ok "5 bad bodies refused (non-Amazon host, http link, http image, no images, unknown field)"
out=$(post POST /v1/admin/affiliate-products '{"url":"https://link.amazon/B1abc","asin":"B0TESTAAA1","title":"Test easel","brand":"Acme","category":"Easels & Stands",'$IMG'}')
[ "$(echo "$out" | tail -1)" = 201 ] || fail "create: $out"
out=$(post POST /v1/admin/affiliate-products '{"url":"https://link.amazon/B1abc","asin":"B0TESTAAA1","title":"Test easel","category":"Easels & Stands",'$IMG'}')
[ "$(echo "$out" | tail -1)" = 409 ] && echo "$out" | grep -q "already on the shelf" || fail "duplicate: $out"
ok "created 201; the same ASIN again is 409 'already on the shelf'"
[ "$(curl -s $A/v1/affiliate-products | j '.products.length')" = 119 ] || fail "public list should see the new product at once (cache invalidated)"
ok "public list shows it immediately (cache invalidated on write)"

echo "--- hide, show, edit, delete"
post PATCH /v1/admin/affiliate-products/B0TESTAAA1 '{"active":false}' | tail -1 | grep -q 200 || fail "hide"
[ "$(curl -s $A/v1/affiliate-products | j '.products.length')" = 118 ] || fail "hidden product still public"
[ "$(curl -s -H "Authorization: Bearer $ADMIN" $A/v1/admin/affiliate-products | j '.products.length')" = 119 ] || fail "admin should still see hidden"
ok "hidden: gone from public, still in admin"
out=$(post PATCH /v1/admin/affiliate-products/B0TESTAAA1 '{"title":"Renamed easel","brand":null,"active":true}')
echo "$out" | head -1 | grep -q '"title":"Renamed easel"' && echo "$out" | head -1 | grep -q '"brand":null' && echo "$out" | head -1 | grep -q '"asin":"B0TESTAAA1"' || fail "edit: $out"
[ "$(post PATCH /v1/admin/affiliate-products/B0TESTAAA1 '{"asin":"B0OTHER000"}' | tail -1)" = 400 ] || fail "asin must not be editable"
[ "$(post PATCH /v1/admin/affiliate-products/NOPE '{"title":"x"}' | tail -1)" = 404 ] || fail "unknown id should be 404"
ok "edit keeps the ASIN, clears the brand; ASIN edits 400; unknown id 404"
[ "$(post DELETE /v1/admin/affiliate-products/B0TESTAAA1 '' | tail -1)" = 200 ] || fail "delete"
[ "$(post DELETE /v1/admin/affiliate-products/B0TESTAAA1 '' | tail -1)" = 404 ] || fail "second delete should be 404"
[ "$(curl -s $A/v1/affiliate-products | j '.products.length')" = 118 ] || fail "after delete"
ok "deleted; deleting again is 404"

echo "--- lookup (real amazon.in)"
out=$(post POST /v1/admin/affiliate-products/lookup '{"url":"https://link.amazon/B011xih2K"}')
code=$(echo "$out" | tail -1)
if [ "$code" = 201 ] || [ "$code" = 200 ]; then
  echo "$out" | head -1 | grep -q 'ECLET' && ok "lookup read the real Amazon page: $(echo "$out" | head -1 | j '.title' 2>/dev/null | cut -c1-60)"
else echo "note: lookup answered $code: $(echo "$out" | head -1 | cut -c1-160)"; fi
[ "$(post POST /v1/admin/affiliate-products/lookup '{"url":"https://169.254.169.254/latest/meta-data"}' | tail -1)" = 400 ] || fail "SSRF: non-Amazon host must be refused"
[ "$(post POST /v1/admin/affiliate-products/lookup '{"url":"https://amazon.in.evil.com/x"}' | tail -1)" = 400 ] || fail "SSRF: lookalike host must be refused"
ok "lookup refuses non-Amazon hosts (metadata IP, lookalike domain)"

kill $API 2>/dev/null
echo "ALL E2E CHECKS PASSED"
