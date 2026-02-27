# API Client Template

## Axios Wrapper (React/Vue)

### request.ts - Base Wrapper

```typescript
import axios, { AxiosInstance, AxiosRequestConfig, AxiosResponse, AxiosError } from 'axios';
import { message } from 'antd'; // Or Element Plus ElMessage

// Create axios instance
const request: AxiosInstance = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL,
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor
request.interceptors.request.use(
  (config: AxiosRequestConfig) => {
    // Add token
    const token = localStorage.getItem('token');
    if (token) {
      config.headers = config.headers || {};
      config.headers.Authorization = `Bearer ${token}`;
    }

    // Add timestamp to prevent cache
    if (config.method === 'get') {
      config.params = {
        ...config.params,
        _t: Date.now(),
      };
    }

    return config;
  },
  (error: AxiosError) => {
    return Promise.reject(error);
  }
);

// Response interceptor
request.interceptors.response.use(
  (response: AxiosResponse) => {
    const { code, message: msg, data } = response.data;

    // Success
    if (code === 200 || code === 201) {
      return response;
    }

    // Business error
    message.error(msg || 'Request failed');
    return Promise.reject(new Error(msg || 'Request failed'));
  },
  (error: AxiosError) => {
    const { response } = error;

    if (response) {
      const { status, data } = response;

      switch (status) {
        case 400:
          message.error(data.message || 'Invalid request parameters');
          break;
        case 401:
          message.error('Unauthorized, please log in again');
          localStorage.removeItem('token');
          window.location.href = '/login';
          break;
        case 403:
          message.error('Access denied');
          break;
        case 404:
          message.error('Resource not found');
          break;
        case 500:
          message.error('Server error');
          break;
        default:
          message.error(data.message || 'Network error');
      }
    } else {
      message.error('Network connection failed');
    }

    return Promise.reject(error);
  }
);

export default request;
```

### user.ts - User API

```typescript
import request from './request';
import type { User, UserCreate, UserUpdate } from '@/types/user';

export const userApi = {
  // Get user list
  getUsers: (params: { page: number; limit: number; keyword?: string }) => {
    return request.get('/users', { params });
  },

  // Get single user
  getUser: (id: number) => {
    return request.get(`/users/${id}`);
  },

  // Create user
  createUser: (data: UserCreate) => {
    return request.post('/users', data);
  },

  // Update user
  updateUser: (id: number, data: UserUpdate) => {
    return request.put(`/users/${id}`, data);
  },

  // Delete user
  deleteUser: (id: number) => {
    return request.delete(`/users/${id}`);
  },

  // Upload avatar
  uploadAvatar: (formData: FormData) => {
    return request.post('/users/upload-avatar', formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });
  },
};
```

### product.ts - Product API

```typescript
import request from './request';
import type { Product, ProductCreate, ProductUpdate } from '@/types/product';

export const productApi = {
  // Get product list
  getProducts: (params: {
    page: number;
    limit: number;
    category_id?: number;
    keyword?: string;
    min_price?: number;
    max_price?: number;
  }) => {
    return request.get('/products', { params });
  },

  // Get product detail
  getProduct: (id: number) => {
    return request.get(`/products/${id}`);
  },

  // Create product
  createProduct: (data: ProductCreate) => {
    return request.post('/products', data);
  },

  // Update product
  updateProduct: (id: number, data: ProductUpdate) => {
    return request.put(`/products/${id}`, data);
  },

  // Delete product
  deleteProduct: (id: number) => {
    return request.delete(`/products/${id}`);
  },
};
```

### order.ts - Order API

```typescript
import request from './request';
import type { Order, OrderCreate } from '@/types/order';

export const orderApi = {
  // Get order list
  getOrders: (params: {
    page: number;
    limit: number;
    status?: string;
  }) => {
    return request.get('/orders', { params });
  },

  // Get order detail
  getOrder: (id: number) => {
    return request.get(`/orders/${id}`);
  },

  // Create order
  createOrder: (data: OrderCreate) => {
    return request.post('/orders', data);
  },

  // Update order status
  updateOrderStatus: (id: number, status: string) => {
    return request.put(`/orders/${id}/status`, { status });
  },

  // Cancel order
  cancelOrder: (id: number) => {
    return request.put(`/orders/${id}/cancel`);
  },
};
```

## Angular HttpClient Wrapper

### http-interceptor.service.ts - Interceptor

```typescript
import { Injectable } from '@angular/core';
import {
  HttpRequest,
  HttpHandler,
  HttpEvent,
  HttpInterceptor,
  HttpErrorResponse,
} from '@angular/common/http';
import { Observable, throwError } from 'rxjs';
import { catchError, finalize } from 'rxjs/operators';
import { NzMessageService } from 'ng-zorro-antd/message';
import { Router } from '@angular/router';

@Injectable()
export class HttpInterceptorService implements HttpInterceptor {
  constructor(
    private message: NzMessageService,
    private router: Router
  ) {}

  intercept(
    request: HttpRequest<any>,
    next: HttpHandler
  ): Observable<HttpEvent<any>> {
    // Add token
    const token = localStorage.getItem('token');
    if (token) {
      request = request.clone({
        setHeaders: {
          Authorization: `Bearer ${token}`,
        },
      });
    }

    return next.handle(request).pipe(
      catchError((error: HttpErrorResponse) => {
        if (error.status === 401) {
          this.message.error('Unauthorized, please log in again');
          localStorage.removeItem('token');
          this.router.navigate(['/login']);
        } else if (error.status === 403) {
          this.message.error('Access denied');
        } else if (error.status === 404) {
          this.message.error('Resource not found');
        } else if (error.status === 500) {
          this.message.error('Server error');
        } else {
          this.message.error(error.error?.message || 'Network error');
        }
        return throwError(() => error);
      })
    );
  }
}
```

### user.service.ts - User Service

```typescript
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';

@Injectable({
  providedIn: 'root',
})
export class UserService {
  private apiUrl = `${environment.apiUrl}/users`;

  constructor(private http: HttpClient) {}

  // Get user list
  getUsers(params: any): Observable<any> {
    return this.http.get(this.apiUrl, { params });
  }

  // Get single user
  getUser(id: number): Observable<any> {
    return this.http.get(`${this.apiUrl}/${id}`);
  }

  // Create user
  createUser(data: any): Observable<any> {
    return this.http.post(this.apiUrl, data);
  }

  // Update user
  updateUser(id: number, data: any): Observable<any> {
    return this.http.put(`${this.apiUrl}/${id}`, data);
  }

  // Delete user
  deleteUser(id: number): Observable<any> {
    return this.http.delete(`${this.apiUrl}/${id}`);
  }
}
```

## Usage Examples

### Use in React Component

```typescript
import { useEffect, useState } from 'react';
import { userApi } from '@/api/user';

const UserList = () => {
  const [users, setUsers] = useState([]);

  const loadUsers = async () => {
    try {
      const response = await userApi.getUsers({ page: 1, limit: 10 });
      setUsers(response.data.data.users);
    } catch (error) {
      console.error('Load failed', error);
    }
  };

  useEffect(() => {
    loadUsers();
  }, []);

  return <div>User List</div>;
};
```

### Use in Vue 3 Component

```vue
<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { userApi } from '@/api/user';

const users = ref([]);

const loadUsers = async () => {
  try {
    const response = await userApi.getUsers({ page: 1, limit: 10 });
    users.value = response.data.data.users;
  } catch (error) {
    console.error('Load failed', error);
  }
};

onMounted(() => {
  loadUsers();
});
</script>
```

### Use in Angular Component

```typescript
import { Component, OnInit } from '@angular/core';
import { UserService } from '@/services/user.service';

@Component({
  selector: 'app-user-list',
  templateUrl: './user-list.component.html',
})
export class UserListComponent implements OnInit {
  users: any[] = [];

  constructor(private userService: UserService) {}

  ngOnInit() {
    this.loadUsers();
  }

  loadUsers() {
    this.userService.getUsers({ page: 1, limit: 10 }).subscribe({
      next: (response: any) => {
        this.users = response.data.users;
      },
      error: (error) => {
        console.error('Load failed', error);
      },
    });
  }
}
```
