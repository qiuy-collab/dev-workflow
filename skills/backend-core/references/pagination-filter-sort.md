# Pagination, Filtering, Sorting Guide

## Pagination

### Python + FastAPI

#### Parameter Definitions
```python
from pydantic import BaseModel, Field
from typing import Generic, TypeVar, Optional, List

T = TypeVar('T')

class PaginatedResponse(BaseModel, Generic[T]):
    total: int
    page: int
    limit: int
    pages: int
    items: List[T]

class PaginationParams(BaseModel):
    page: int = Field(1, ge=1)
    limit: int = Field(10, ge=1, le=100)
```

#### Pagination Implementation
```python
from sqlalchemy.orm import Session
from typing import TypeVar, Generic, List

ModelType = TypeVar("ModelType")

def paginate(
    query: Query,
    page: int,
    limit: int
) -> dict:
    """Pagination"""
    # Total count
    total = query.count()

    # Total pages
    pages = (total + limit - 1) // limit

    # Offset
    offset = (page - 1) * limit

    # Query
    items = query.offset(offset).limit(limit).all()

    return {
        "total": total,
        "page": page,
        "limit": limit,
        "pages": pages,
        "items": items
    }

# Usage
@router.get("/products")
def get_products(
    page: int = 1,
    limit: int = 10,
    db: Session = Depends(get_db)
):
    query = db.query(Product)
    result = paginate(query, page, limit)

    return {
        "code": 200,
        "message": "success",
        "data": result
    }
```

### Java + Spring Boot

#### Pageable Params
```java
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;

@RestController
public class ProductController {

    @GetMapping("/products")
    public ResponseEntity<Page<Product>> getProducts(
        @RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "10") int limit
    ) {
        Pageable pageable = PageRequest.of(page, limit);
        Page<Product> products = productRepository.findAll(pageable);
        return ResponseEntity.ok(products);
    }
}
```

#### Page Response Format
```json
{
  "content": [...],
  "pageable": {
    "pageNumber": 0,
    "pageSize": 10,
    "sort": {...}
  },
  "totalElements": 100,
  "totalPages": 10,
  "last": false,
  "first": true,
  "number": 0
}
```

### Node.js + Express

#### Pagination Params
```javascript
class PaginationService {
  async paginate(model, page = 1, limit = 10, filters = {}) {
    // Offset
    const skip = (page - 1) * limit;

    // Query
    const query = model.find(filters);

    // Total count
    const total = await model.countDocuments(filters);

    // Execute query
    const items = await query
      .skip(skip)
      .limit(limit)
      .sort({ createdAt: -1 });

    // Total pages
    const pages = Math.ceil(total / limit);

    return {
      total,
      page,
      limit,
      pages,
      items
    };
  }
}

// Usage
router.get('/products', async (req, res) => {
  const { page = 1, limit = 10 } = req.query;
  const result = await paginationService.paginate(
    Product,
    parseInt(page),
    parseInt(limit)
  );
  res.json({
    code: 200,
    message: 'success',
    data: result
  });
});
```

## Filtering

### Python + FastAPI

#### Dynamic Filters
```python
from typing import Optional, Dict, Any
from sqlalchemy import or_, and_

def apply_filters(query, filters: Dict[str, Any]) -> Query:
    """Apply filters"""

    # Status filter
    if filters.get('status'):
        query = query.filter(User.status == filters['status'])

    # Keyword search (username or email)
    if filters.get('keyword'):
        keyword = f"%{filters['keyword']}%"
        query = query.filter(
            or_(
                User.username.ilike(keyword),
                User.email.ilike(keyword)
            )
        )

    # Range (price)
    if filters.get('min_price'):
        query = query.filter(Product.price >= filters['min_price'])
    if filters.get('max_price'):
        query = query.filter(Product.price <= filters['max_price'])

    # Date range
    if filters.get('start_date'):
        query = query.filter(User.createdAt >= filters['start_date'])
    if filters.get('end_date'):
        query = query.filter(User.createdAt <= filters['end_date'])

    # Category filter
    if filters.get('category_id'):
        query = query.filter(Product.categoryId == filters['category_id'])

    return query

# Usage
@router.get("/products")
def get_products(
    page: int = 1,
    limit: int = 10,
    status: Optional[str] = None,
    keyword: Optional[str] = None,
    min_price: Optional[float] = None,
    max_price: Optional[float] = None,
    db: Session = Depends(get_db)
):
    filters = {
        'status': status,
        'keyword': keyword,
        'min_price': min_price,
        'max_price': max_price
    }

    query = db.query(Product)
    query = apply_filters(query, filters)

    result = paginate(query, page, limit)

    return {
        "code": 200,
        "message": "success",
        "data": result
    }
```

#### Combined Filters
```python
def apply_complex_filters(query, filters):
    """Apply complex filters"""

    # AND
    if filters.get('status') and filters.get('category_id'):
        query = query.filter(
            and_(
                Product.status == filters['status'],
                Product.categoryId == filters['category_id']
            )
        )

    # OR
    if filters.get('keywords'):
        keywords = filters['keywords'].split(',')
        conditions = [Product.name.ilike(f"%{k}%") for k in keywords]
        query = query.filter(or_(*conditions))

    return query
```

### Java + Spring Boot

#### Specification Dynamic Query
```java
import org.springframework.data.jpa.domain.Specification;
import javax.persistence.criteria.Predicate;
import java.util.ArrayList;
import java.util.List;

public class ProductSpecifications {
    public static Specification<Product> withFilters(String status, String keyword, Double minPrice, Double maxPrice) {
        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            // Status
            if (status != null && !status.isEmpty()) {
                predicates.add(cb.equal(root.get("status"), status));
            }

            // Keyword
            if (keyword != null && !keyword.isEmpty()) {
                predicates.add(cb.like(root.get("name"), "%" + keyword + "%"));
            }

            // Price range
            if (minPrice != null) {
                predicates.add(cb.ge(root.get("price"), minPrice));
            }
            if (maxPrice != null) {
                predicates.add(cb.le(root.get("price"), maxPrice));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };
    }
}

// Usage
@GetMapping("/products")
public ResponseEntity<Page<Product>> getProducts(
    @RequestParam(required = false) String status,
    @RequestParam(required = false) String keyword,
    @RequestParam(required = false) Double minPrice,
    @RequestParam(required = false) Double maxPrice,
    Pageable pageable
) {
    Specification<Product> spec = ProductSpecifications.withFilters(status, keyword, minPrice, maxPrice);
    Page<Product> products = productRepository.findAll(spec, pageable);
    return ResponseEntity.ok(products);
}
```

### Node.js + Express

#### Mongoose Dynamic Query
```javascript
class FilterService {
  applyFilters(query, filters) {
    // Status
    if (filters.status) {
      query = query.where('status').equals(filters.status);
    }

    // Keyword search (multi-field)
    if (filters.keyword) {
      query = query.or([
        { name: new RegExp(filters.keyword, 'i') },
        { description: new RegExp(filters.keyword, 'i') }
      ]);
    }

    // Price range
    if (filters.minPrice !== undefined) {
      query = query.where('price').gte(filters.minPrice);
    }
    if (filters.maxPrice !== undefined) {
      query = query.where('price').lte(filters.maxPrice);
    }

    // Date range
    if (filters.startDate) {
      query = query.where('createdAt').gte(new Date(filters.startDate));
    }
    if (filters.endDate) {
      query = query.where('createdAt').lte(new Date(filters.endDate));
    }

    // Multi-value filter (array)
    if (filters.categories) {
      query = query.where('categoryId').in(filters.categories);
    }

    return query;
  }
}

// Usage
router.get('/products', async (req, res) => {
  const { page = 1, limit = 10, status, keyword, minPrice, maxPrice } = req.query;
  const filters = { status, keyword, minPrice, maxPrice };

  let query = Product.find();
  query = filterService.applyFilters(query, filters);

  // Pagination
  const skip = (page - 1) * limit;
  const total = await Product.countDocuments();
  const products = await query.skip(skip).limit(limit);

  res.json({
    code: 200,
    message: 'success',
    data: {
      total,
      page,
      limit,
      pages: Math.ceil(total / limit),
      products
    }
  });
});
```

## Sorting

### Python + FastAPI

#### Sort Parameters
```python
from sqlalchemy import asc, desc

def apply_sorting(query, sort_by: str, order: str = "desc") -> Query:
    """Apply sorting"""

    # Allowed fields
    allowed_fields = {
        'id': User.id,
        'username': User.username,
        'email': User.email,
        'created_at': User.created_at,
        'updated_at': User.updated_at
    }

    # Resolve sort column
    sort_column = allowed_fields.get(sort_by)
    if not sort_column:
        sort_column = User.created_at

    # Apply ordering
    if order.lower() == "desc":
        query = query.order_by(desc(sort_column))
    else:
        query = query.order_by(asc(sort_column))

    return query

# Usage
@router.get("/users")
def get_users(
    page: int = 1,
    limit: int = 10,
    sort_by: str = "created_at",
    order: str = "desc",
    db: Session = Depends(get_db)
):
    query = db.query(User)
    query = apply_sorting(query, sort_by, order)
    result = paginate(query, page, limit)

    return {
        "code": 200,
        "message": "success",
        "data": result
    }
```

#### Multi-field Sorting
```python
def apply_multi_sorting(query, sort_params: List[dict]) -> Query:
    """Apply multi-field sorting"""

    for sort_param in sort_params:
        sort_by = sort_param.get('field')
        order = sort_param.get('order', 'desc')

        sort_column = getattr(User, sort_by, None)
        if sort_column:
            if order == "desc":
                query = query.order_by(desc(sort_column))
            else:
                query = query.order_by(asc(sort_column))

    return query

# Usage
@router.get("/products")
def get_products(
    page: int = 1,
    limit: int = 10,
    sort_by: str = "created_at",
    order: str = "desc",
    db: Session = Depends(get_db)
):
    # Multi-field: status desc, created_at desc
    query = db.query(Product)
    query = apply_multi_sorting(query, [
        {'field': 'status', 'order': 'desc'},
        {'field': 'created_at', 'order': 'desc'}
    ])

    result = paginate(query, page, limit)

    return {
        "code": 200,
        "message": "success",
        "data": result
    }
```

### Java + Spring Boot

#### Sort Params
```java
import org.springframework.data.domain.Sort;

@GetMapping("/products")
public ResponseEntity<Page<Product>> getProducts(
    @RequestParam(defaultValue = "0") int page,
    @RequestParam(defaultValue = "10") int limit,
    @RequestParam(defaultValue = "createdAt") String sortBy,
    @RequestParam(defaultValue = "desc") String order
) {
    Sort sort = Sort.by(
        order.equalsIgnoreCase("desc") ? Sort.Direction.DESC : Sort.Direction.ASC,
        sortBy
    );

    Pageable pageable = PageRequest.of(page, limit, sort);
    Page<Product> products = productRepository.findAll(pageable);

    return ResponseEntity.ok(products);
}
```

#### Multi-field Sorting
```java
@GetMapping("/products")
public ResponseEntity<Page<Product>> getProducts(
    @RequestParam(defaultValue = "0") int page,
    @RequestParam(defaultValue = "10") int limit
) {
    Sort sort = Sort.by(
        Sort.Order.desc("status"),
        Sort.Order.desc("createdAt")
    );

    Pageable pageable = PageRequest.of(page, limit, sort);
    Page<Product> products = productRepository.findAll(pageable);

    return ResponseEntity.ok(products);
}
```

### Node.js + Express

#### Sort Params
```javascript
class SortService {
  applySort(query, sortBy = 'createdAt', order = 'desc') {
    // Allowed fields
    const allowedFields = ['id', 'name', 'price', 'createdAt', 'updatedAt'];

    // Validate field
    const field = allowedFields.includes(sortBy) ? sortBy : 'createdAt';

    // Apply sort
    const sortDirection = order === 'asc' ? 1 : -1;
    return query.sort({ [field]: sortDirection });
  }
}

// Usage
router.get('/products', async (req, res) => {
  const { page = 1, limit = 10, sortBy = 'createdAt', order = 'desc' } = req.query;

  let query = Product.find();
  query = sortService.applySort(query, sortBy, order);

  // Pagination
  const skip = (page - 1) * limit;
  const total = await Product.countDocuments();
  const products = await query.skip(skip).limit(limit);

  res.json({
    code: 200,
    message: 'success',
    data: {
      total,
      page,
      limit,
      pages: Math.ceil(total / limit),
      products
    }
  });
});
```

#### Multi-field Sorting
```javascript
router.get('/products', async (req, res) => {
  let query = Product.find();

  // Multi-field: status desc, createdAt desc
  query = query.sort({
    status: -1,
    createdAt: -1
  });

  const products = await query.exec();
  res.json({ products });
});
```

## Comprehensive Example

### Python + FastAPI Full Example
```python
@router.get("/products")
def get_products(
    page: int = 1,
    limit: int = 10,
    status: Optional[str] = None,
    keyword: Optional[str] = None,
    min_price: Optional[float] = None,
    max_price: Optional[float] = None,
    sort_by: str = "created_at",
    order: str = "desc",
    db: Session = Depends(get_db)
):
    # Build query
    query = db.query(Product)

    # Apply filters
    filters = {
        'status': status,
        'keyword': keyword,
        'min_price': min_price,
        'max_price': max_price
    }
    query = apply_filters(query, filters)

    # Total count
    total = query.count()

    # Apply sorting
    query = apply_sorting(query, sort_by, order)

    # Apply pagination
    offset = (page - 1) * limit
    products = query.offset(offset).limit(limit).all()

    # Return result
    return {
        "code": 200,
        "message": "success",
        "data": {
            "total": total,
            "page": page,
            "limit": limit,
            "pages": (total + limit - 1) // limit,
            "products": products
        }
    }
```

### Test Checklist
- [ ] Pagination params correct (page, limit)
- [ ] Total count correct
- [ ] Pages count correct
- [ ] Offset correct
- [ ] Status filter works
- [ ] Keyword search works
- [ ] Range query works
- [ ] Date range query works
- [ ] Sort order correct (asc/desc)
- [ ] Multi-field sorting works
- [ ] Invalid sort field uses default
