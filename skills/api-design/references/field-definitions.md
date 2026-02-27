# Field Definition Spec

## Table of Contents
- [Field Type Definitions](#field-type-definitions)
- [Field Attribute Descriptions](#field-attribute-descriptions)
- [Field Examples](#field-examples)
- [Validation Rule Definitions](#validation-rule-definitions)

## Field Type Definitions

### Basic Types
| Type | Description | Example | Data Type |
|------|------|------|----------|
| text | Single-line text | Username, product name | String |
| textarea | Multi-line text | Product description, notes | String |
| number | Number | Price, stock, age | Number |
| date | Date | Birth date, order date | Date |
| datetime | DateTime | Created time, updated time | DateTime |
| email | Email address | Email login | String |
| phone | Phone number | Phone login | String |
| url | URL | Product image, website | String |
| select | Dropdown | User type, product category | String/Number |
| radio | Radio button | Gender, payment method | String/Number |
| checkbox | Checkbox | User tags, product tags | Array |
| switch | Toggle | Enabled, visible | Boolean |
| file | File upload | Avatar, product image | String (URL) |
| image | Image upload | Avatar, product image | String (URL) |
| password | Password | Login password, payment password | String (encrypted) |
| rich-text | Rich text | Product details, article content | String (HTML) |
| json | JSON object | Extensions, configuration | Object |
| array | Array | Product specs, order items | Array |

### Composite Types
| Type | Description | Subfield Examples |
|------|------|------------|
| address | Address | Country, province, city, detail address |
| user | User reference | user_id, user_name, user_avatar |
| product | Product reference | product_id, product_name, product_image |

## Field Attribute Descriptions

### Basic Attributes
| Attribute | Description | Required |
|------|------|------|
| Field ID | Unique identifier (e.g., F-001) | Yes |
| Field Name | Display name | Yes |
| Field Key | Variable name used by code | Yes |
| Field Type | Data type | Yes |
| Required | true/false | Yes |
| Default | Default value | No |
| Placeholder | Hint text | No |
| Description | Field purpose | No |

### Validation Attributes
| Attribute | Description | Example |
|------|------|------|
| Length Limit | Min/max length | min: 6, max: 20 |
| Range | Min/max value | min: 0, max: 100 |
| Regex | Format validation | ^[a-zA-Z0-9_]+$ |
| Enum Values | Allowed values | ['Male', 'Female', 'Secret'] |
| Uniqueness | Unique or not | true/false |
| Custom Validation | Custom rules | Password strength check |

### Display Attributes
| Attribute | Description | Example |
|------|------|------|
| Read-only | Editable or not | true/false |
| Hidden | Visible or not | true/false |
| Disabled | Usable or not | true/false |
| Conditional Display | Display condition logic | role === 'admin' |
| Display Order | Field order | 1, 2, 3... |

## Field Examples

### F-001 Username

| Attribute | Value |
|------|-----|
| Field ID | F-001 |
| Field Name | Username |
| Field Key | username |
| Field Type | text |
| Required | Yes |
| Default | None |
| Placeholder | Enter username |
| Description | Unique identifier for user login |
| Length Limit | min: 4, max: 20 |
| Regex | ^[a-zA-Z0-9_]+$ |
| Uniqueness | Yes |
| Read-only | No |
| Display Order | 1 |

---

### F-002 Password

| Attribute | Value |
|------|-----|
| Field ID | F-002 |
| Field Name | Password |
| Field Key | password |
| Field Type | password |
| Required | Yes |
| Default | None |
| Placeholder | Enter password |
| Description | User login password, must meet security requirements |
| Length Limit | min: 8, max: 32 |
| Regex | ^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)[a-zA-Z\\d]{8,}$ |
| Custom Validation | Include uppercase, lowercase, and numbers |
| Read-only | No |
| Display Order | 2 |

---

### F-003 Email

| Attribute | Value |
|------|-----|
| Field ID | F-003 |
| Field Name | Email |
| Field Key | email |
| Field Type | email |
| Required | Yes |
| Default | None |
| Placeholder | Enter email address |
| Description | Used for verification emails and important notifications |
| Regex | ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$ |
| Uniqueness | Yes |
| Read-only | No |
| Display Order | 3 |

---

### F-004 Mobile

| Attribute | Value |
|------|-----|
| Field ID | F-004 |
| Field Name | Mobile |
| Field Key | mobile |
| Field Type | phone |
| Required | No |
| Default | None |
| Placeholder | Enter phone number |
| Description | Used for SMS codes and important notifications |
| Regex | ^1[3-9]\\d{9}$ |
| Uniqueness | Yes |
| Read-only | No |
| Display Order | 4 |

---

### F-005 Gender

| Attribute | Value |
|------|-----|
| Field ID | F-005 |
| Field Name | Gender |
| Field Key | gender |
| Field Type | radio |
| Required | No |
| Default | Secret |
| Enum Values | Male, Female, Secret |
| Description | User gender information |
| Read-only | No |
| Display Order | 5 |

---

### F-006 Avatar

| Attribute | Value |
|------|-----|
| Field ID | F-006 |
| Field Name | Avatar |
| Field Key | avatar |
| Field Type | image |
| Required | No |
| Default | /images/default-avatar.png |
| Description | User avatar image, supports JPG/PNG |
| Length Limit | max: 2MB |
| Read-only | No |
| Display Order | 6 |

---

### F-007 Shipping Address

| Attribute | Value |
|------|-----|
| Field ID | F-007 |
| Field Name | Shipping Address |
| Field Key | address |
| Field Type | address (composite) |
| Required | Yes |
| Subfields | receiver_name, mobile, province, city, district, detail_address |
| Description | User shipping address information |
| Read-only | No |
| Display Order | 7 |

---

### F-008 Product Price

| Attribute | Value |
|------|-----|
| Field ID | F-008 |
| Field Name | Product Price |
| Field Key | price |
| Field Type | number |
| Required | Yes |
| Default | 0 |
| Range | min: 0.01 |
| Precision | 2 decimal places |
| Description | Product sale price, unit: CNY |
| Read-only | No |
| Display Order | 1 |

---

### F-009 Product Stock

| Attribute | Value |
|------|-----|
| Field ID | F-009 |
| Field Name | Product Stock |
| Field Key | stock |
| Field Type | number |
| Required | Yes |
| Default | 0 |
| Range | min: 0 |
| Precision | Integer |
| Description | Product stock quantity |
| Read-only | No |
| Display Order | 2 |

---

### F-010 Product Status

| Attribute | Value |
|------|-----|
| Field ID | F-010 |
| Field Name | Product Status |
| Field Key | status |
| Field Type | select |
| Required | Yes |
| Default | Active |
| Enum Values | Active, Inactive, Sold out |
| Description | Product listing status |
| Read-only | No |
| Display Order | 3 |

---

### F-011 Product Description

| Attribute | Value |
|------|-----|
| Field ID | F-011 |
| Field Name | Product Description |
| Field Key | description |
| Field Type | rich-text |
| Required | No |
| Default | None |
| Placeholder | Enter detailed product description |
| Description | Product details, supports rich-text editing |
| Length Limit | max: 10000 |
| Read-only | No |
| Display Order | 4 |

## Validation Rule Definitions

### Common Validation Rules

#### Username Validation
```javascript
{
  pattern: /^[a-zA-Z0-9_]{4,20}$/,
  message: "Username length 4-20, only letters, numbers, underscore"
}
```

#### Password Validation
```javascript
{
  pattern: /^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)[a-zA-Z\\d]{8,}$/,
  message: "Password at least 8 characters with upper/lowercase and numbers"
}
```

#### Email Validation
```javascript
{
  pattern: /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$/,
  message: "Enter a valid email address"
}
```

#### Phone Validation
```javascript
{
  pattern: /^1[3-9]\\d{9}$/,
  message: "Enter a valid phone number"
}
```

#### ID Card Validation
```javascript
{
  pattern: /^[1-9]\\d{5}(18|19|20)\\d{2}((0[1-9])|(1[0-2]))(([0-2][1-9])|10|20|30|31)\\d{3}[0-9Xx]$/,
  message: "Enter a valid ID number"
}
```

#### URL Validation
```javascript
{
  pattern: /^https?:\\/\\/.+/,
  message: "Enter a valid URL"
}
```

### Field Naming Conventions

#### Naming Styles
- **Frontend fields**: camelCase (e.g., userName, userId)
- **Backend fields**: snake_case (e.g., user_name, user_id)
- **Database fields**: snake_case (e.g., user_name, user_id)
- **JSON fields**: camelCase or snake_case, keep consistent

#### Common Field Names
| Chinese Name | Field Key | Type |
|----------|----------|------|
| User ID | user_id / userId | Number |
| Username | username | String |
| Password | password | String |
| Email | email | String |
| Mobile | mobile / phone | String |
| Created At | created_at / createTime | DateTime |
| Updated At | updated_at / updateTime | DateTime |
| Deleted At | deleted_at / deleteTime | DateTime |
| Status | status | String/Number |
| Type | type | String/Number |
| Name | name | String |
| Description | description | String |
| Count | count / quantity | Number |
| Amount | amount | Number |
| Price | price | Number |
