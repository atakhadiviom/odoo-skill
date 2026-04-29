# Odoo eCommerce: Product Content & Translations via API

Learned from live production work on Odoo 16/17 (SaaS). Covers the right fields to use,
HTML sanitizer rules, multilingual translation pattern, and known website builder bugs.

---

## 1. Product Description Fields — Which One to Use

`product.template` has many description fields. Use the right one:

| Field | Type | Where it appears | Use for |
|---|---|---|---|
| `website_description` | html | **Product page body** (what customers see) | ✅ Rich product content |
| `description_sale` | text | Quotations / sale orders only | Sales team notes |
| `description` | html | Internal notes | Internal use |
| `public_description` | html | Some themes | Alternate body |
| `description_ecommerce` | html | Some themes | Alternate body |

**Always use `website_description` for customer-facing product page content.**

```python
models.execute_kw(DB, uid, API_KEY, 'product.template', 'write',
    [[product_id], {'website_description': html_content}])
```

---

## 2. HTML Sanitizer Rules

Odoo's HTML sanitizer (`html_sanitize`) runs on html fields before storing. Violations cause
silent stripping that can produce malformed HTML and crash the website builder iframe.

### ✅ Safe — always allowed
- Standard block/inline tags: `div`, `p`, `h1–h6`, `ul`, `ol`, `li`, `table`, `tr`, `td`, `th`, `span`, `strong`, `em`, `a`
- `class` attribute — Bootstrap classes pass through untouched
- `dir` attribute — required for RTL Arabic (`dir="rtl"`)
- HTML entities: `&mdash;`, `&middot;`, `&amp;`, `&#9889;` etc.

### ❌ Unsafe — stripped or mangled
- **HTML comments** `<!-- -->` — always stripped; leaving them causes broken HTML structure
- **Inline `style="..."`** — stripped in some Odoo configs; never rely on them for layout
- **CSS Grid** (`display: grid; grid-template-columns: ...`) — unsafe even if style attr survives
- **JavaScript** / `<script>` — stripped
- **`<iframe>`, `<object>`, `<embed>`** — stripped

### Rule: Use Bootstrap classes, not inline styles

```html
<!-- ❌ BREAKS the website builder -->
<div style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 16px;">

<!-- ✅ SAFE — Bootstrap grid -->
<div class="row g-3">
  <div class="col-6 col-md-3">...</div>
</div>
```

Full safe pattern for a product description:

```html
<div class="container-fluid px-0">

  <!-- Hero banner -->
  <div class="bg-dark text-white rounded-3 p-4 mb-4">
    <h3 class="fw-bold">Product Name</h3>
    <p class="mb-0 opacity-75">Short intro paragraph.</p>
  </div>

  <!-- Feature cards: 4-up on desktop, 2-up on mobile -->
  <div class="row g-3 mb-4">
    <div class="col-6 col-md-3">
      <div class="border rounded-3 p-3 text-center h-100">
        <div class="fs-2 mb-2">&#9889;</div>
        <div class="fw-bold">Feature Title</div>
        <small class="text-muted">Subtitle</small>
      </div>
    </div>
    <!-- repeat col blocks -->
  </div>

  <!-- Specs table in a bordered box -->
  <div class="border rounded-3 overflow-hidden mb-4">
    <div class="bg-dark text-white px-4 py-2 fw-bold">Specifications</div>
    <table class="table table-striped table-bordered mb-0">
      <tbody>
        <tr><th class="w-40">Model</th><td>XYZ-1000</td></tr>
      </tbody>
    </table>
  </div>

  <!-- Two-column bottom row -->
  <div class="row g-3">
    <div class="col-md-6">
      <div class="bg-warning bg-opacity-10 border border-warning rounded-3 p-3 h-100">
        <div class="fw-bold mb-2">&#128230; What's in the Box</div>
        <ul class="mb-0"><li>Item x 1</li></ul>
      </div>
    </div>
    <div class="col-md-6">
      <div class="bg-success bg-opacity-10 border border-success rounded-3 p-3 h-100">
        <div class="fw-bold mb-2">&#9989; Why Choose This?</div>
        <p class="mb-0 text-muted">Selling point paragraph.</p>
      </div>
    </div>
  </div>

</div>
```

---

## 3. Arabic (RTL) Translation Pattern — Odoo 16+

In Odoo 16+, `ir.translation` is **removed**. Translations are stored inline per field using
language context. Writing order matters — write English base first, Arabic second.

```python
import xmlrpc.client

URL = "https://yourinstance.odoo.com"
DB  = "your-db-name"
UID = common.authenticate(DB, USERNAME, API_KEY, {})

def write(model, ids, vals, lang=None):
    ctx = {'lang': lang} if lang else {}
    return models.execute_kw(DB, UID, API_KEY, model, 'write',
                             [ids, vals], {'context': ctx} if ctx else {})

# Step 1 — English base (always first)
write('product.template', [product_id], {
    'website_description': EN_HTML,
    'website_meta_title': 'Product | Brand',
    'website_meta_description': 'SEO description...',
    'website_meta_keywords': 'keyword1, keyword2',
}, lang='en_US')

# Step 2 — Arabic translation
write('product.template', [product_id], {
    'website_description': AR_HTML,          # full Arabic HTML
    'website_meta_title': 'المنتج | العلامة',
    'website_meta_description': 'وصف SEO...',
    'website_meta_keywords': 'كلمة1، كلمة2',
}, lang='ar_001')

# Step 3 — Arabic product name
write('product.template', [product_id], {
    'name': 'اسم المنتج بالعربي',
}, lang='ar_001')
```

### Arabic HTML wrapper

Always add `dir="rtl"` on the outermost div. For RTL `border-start` / `border-end`,
swap `col-md-*` order if needed — Bootstrap 5 handles RTL automatically when `dir="rtl"` is set.

```html
<div class="container-fluid px-0" dir="rtl">
  <!-- Arabic content here, same Bootstrap classes as English -->
  <ul class="mb-0" style="padding-right:18px; padding-left:0;">
    <li>العنصر</li>
  </ul>
</div>
```

### Verify translations saved correctly

```python
def read_lang(product_id, lang):
    return models.execute_kw(DB, UID, API_KEY, 'product.template', 'read',
        [[product_id]], {'fields': ['website_description'], 'context': {'lang': lang}})

en = read_lang(product_id, 'en_US')
ar = read_lang(product_id, 'ar_001')
assert 'Product' in str(en[0]['website_description'])
assert 'المنتج' in str(ar[0]['website_description'])
```

---

## 4. SEO Fields

```python
write('product.template', [product_id], {
    'website_meta_title':       'Model XYZ | Feature | Brand Country',   # ~60 chars
    'website_meta_description': 'Buy Model XYZ in [country]. [2-3 key specs]. Shop [Brand].',  # ~155 chars
    'website_meta_keywords':    'model, keyword1, keyword2, brand, country',
})
```

Meta title formula: `[Model] [Key Feature] | [Category] | [Brand] [Country]`
Meta description formula: `Buy [Model] in [Country]. [Spec1], [Spec2], [Spec3]. Shop [Brand].`

---

## 5. Find a Product by Name or URL Slug

```python
# By name
results = models.execute_kw(DB, UID, API_KEY, 'product.template', 'search_read',
    [[['name', 'ilike', 'STH-3007']]],
    {'fields': ['id', 'name', 'website_url'], 'limit': 5})

# The number at the end of the URL slug is the product template ID
# e.g. /shop/walking-pad-sth-3007-9848  →  id = 9848
```

---

## 6. Known Bug: WebsiteBuilderClientAction.onIframeLoad

**Error:** `Cannot read properties of null (reading 'body')` in `web.assets_web.min.js`

**When it occurs:** When opening the Odoo Website Builder (edit mode) on a product page.

**Cause:** The website builder loads the product page in an iframe. If `iframe.contentDocument`
is null (page failed to render, or stale cached JS bundle), the builder crashes.

**This error is NOT caused by `website_description` content.** The public product page
continues to work normally for customers.

**Fixes (in order of likelihood):**
1. Clear browser cache hard-refresh: `Cmd+Shift+R` / `Ctrl+Shift+R`
2. Clear Odoo asset bundles: `Settings → Technical (dev mode) → User Interface → Assets → Clean Assets Bundles`
3. Re-login to Odoo (stale session token)
4. Try a different browser
5. If persistent: contact Odoo support and reference `WebsiteBuilderClientAction.onIframeLoad`

**Diagnosis tip:** If the error persists after clearing all product fields via API,
it is a pre-existing Odoo bug and not related to your content changes.

---

## 7. Discover All Description Fields on Any Model

```python
fields = models.execute_kw(DB, UID, API_KEY, 'product.template', 'fields_get',
    [], {'attributes': ['string', 'type']})

for name, meta in fields.items():
    if any(x in name for x in ['desc', 'website', 'body', 'page']):
        print(f"{name}: {meta['type']} — {meta['string']}")
```

Run this whenever working with a new model to find the correct field before writing.
