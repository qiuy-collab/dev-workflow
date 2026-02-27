# Frontend Project Structure Template

## React Project Structure (Vite + TypeScript)

```
project-name/
├── public/                     # Static assets
│   ├── favicon.ico
│   └── index.html
├── src/
│   ├── assets/                 # Resource files
│   │   ├── images/
│   │   ├── styles/
│   │   └── fonts/
│   │
│   ├── components/             # Shared components
│   │   ├── layout/
│   │   │   ├── Header.tsx
│   │   │   ├── Footer.tsx
│   │   │   └── Sidebar.tsx
│   │   ├── common/
│   │   │   ├── Button.tsx
│   │   │   ├── Input.tsx
│   │   │   └── Modal.tsx
│   │   └── index.ts
│   │
│   ├── pages/                  # Page components
│   │   ├── Home/
│   │   │   ├── index.tsx
│   │   │   └── index.module.css
│   │   ├── User/
│   │   │   ├── List/
│   │   │   ├── Detail/
│   │   │   └── Create/
│   │   └── index.ts
│   │
│   ├── api/                    # API client
│   │   ├── request.ts          # axios wrapper
│   │   ├── user.ts             # user API
│   │   ├── product.ts          # product API
│   │   └── order.ts            # order API
│   │
│   ├── store/                  # State management
│   │   ├── index.ts            # Store configuration
│   │   ├── modules/
│   │   │   ├── user.ts
│   │   │   └── app.ts
│   │   └── types.ts
│   │
│   ├── router/                 # Routing configuration
│   │   ├── index.tsx
│   │   └── routes.tsx
│   │
│   ├── hooks/                  # Custom hooks
│   │   ├── useAuth.ts
│   │   └── useRequest.ts
│   │
│   ├── utils/                  # Utilities
│   │   ├── format.ts
│   │   ├── validate.ts
│   │   └── storage.ts
│   │
│   ├── types/                  # TypeScript types
│   │   ├── user.ts
│   │   ├── product.ts
│   │   └── common.ts
│   │
│   ├── App.tsx                 # Root component
│   ├── main.tsx                # App entry
│   └── vite-env.d.ts
│
├── .env                        # Environment variables
├── .env.development            # Development environment variables
├── .env.production             # Production environment variables
├── package.json
├── tsconfig.json
├── vite.config.ts
└── README.md
```

## Vue 3 Project Structure (Vite + TypeScript)

```
project-name/
├── public/                     # Static assets
│   └── favicon.ico
├── src/
│   ├── assets/                 # Resource files
│   │   ├── images/
│   │   └── styles/
│   │
│   ├── components/             # Shared components
│   │   ├── layout/
│   │   │   ├── Header.vue
│   │   │   └── Footer.vue
│   │   └── common/
│   │       ├── Button.vue
│   │       └── Input.vue
│   │
│   ├── views/                  # Page components
│   │   ├── Home.vue
│   │   ├── User/
│   │   │   ├── List.vue
│   │   │   ├── Detail.vue
│   │   │   └── Create.vue
│   │   └── Login.vue
│   │
│   ├── api/                    # API client
│   │   ├── request.ts          # axios wrapper
│   │   ├── user.ts
│   │   └── product.ts
│   │
│   ├── store/                  # Pinia state management
│   │   ├── index.ts
│   │   ├── modules/
│   │   │   ├── user.ts
│   │   │   └── app.ts
│   │   └── types.ts
│   │
│   ├── router/                 # Routing configuration
│   │   └── index.ts
│   │
│   ├── composables/            # Composable functions
│   │   ├── useAuth.ts
│   │   └── useRequest.ts
│   │
│   ├── utils/                  # Utilities
│   │   ├── format.ts
│   │   └── validate.ts
│   │
│   ├── types/                  # TypeScript types
│   │   └── index.ts
│   │
│   ├── App.vue                 # Root component
│   └── main.ts                 # App entry
│
├── .env
├── .env.development
├── .env.production
├── package.json
├── tsconfig.json
├── vite.config.ts
└── README.md
```

## Angular Project Structure (Angular CLI)

```
project-name/
├── src/
│   ├── app/
│   │   ├── components/         # Shared components
│   │   │   ├── layout/
│   │   │   │   ├── header/
│   │   │   │   ├── footer/
│   │   │   │   └── sidebar/
│   │   │   └── common/
│   │   │       ├── button/
│   │   │       └── input/
│   │   │
│   │   ├── pages/              # Page components (lazy loaded)
│   │   │   ├── home/
│   │   │   ├── user/
│   │   │   │   ├── list/
│   │   │   │   ├── detail/
│   │   │   │   └── create/
│   │   │   └── login/
│   │   │
│   │   ├── services/           # Services (API client)
│   │   │   ├── http-interceptor.service.ts
│   │   │   ├── user.service.ts
│   │   │   └── product.service.ts
│   │   │
│   │   ├── store/              # NgRx state management
│   │   │   ├── user/
│   │   │   └── app/
│   │   │
│   │   ├── models/             # Data models
│   │   │   ├── user.model.ts
│   │   │   └── product.model.ts
│   │   │
│   │   ├── utils/              # Utilities
│   │   │   └── validators.ts
│   │   │
│   │   ├── app.component.ts
│   │   ├── app.component.html
│   │   ├── app.component.css
│   │   ├── app.module.ts
│   │   ├── app-routing.module.ts
│   │   └── app.component.html
│   │
│   ├── assets/                 # Static assets
│   ├── environments/           # Environment configuration
│   ├── styles/                 # Global styles
│   └── index.html
│
├── angular.json
├── package.json
├── tsconfig.json
└── README.md
```

## Project Initialization Commands

### React + Vite
```bash
npm create vite@latest project-name -- --template react-ts
cd project-name
npm install
npm install antd react-router-dom axios @reduxjs/toolkit react-redux
```

### Vue 3 + Vite
```bash
npm create vite@latest project-name -- --template vue-ts
cd project-name
npm install
npm install element-plus axios pinia vue-router
```

### Angular
```bash
ng new project-name --routing --style=scss
cd project-name
ng add @angular/material
npm install
```

## Configuration Examples

### Vite Config (React/Vue)
```typescript
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
      '@components': path.resolve(__dirname, './src/components'),
      '@pages': path.resolve(__dirname, './src/pages'),
      '@api': path.resolve(__dirname, './src/api'),
      '@utils': path.resolve(__dirname, './src/utils'),
    }
  },
  server: {
    port: 3000,
    proxy: {
      '/api': {
        target: 'http://localhost:8000',
        changeOrigin: true
      }
    }
  }
})
```

### Environment Variables
```bash
# .env.development
VITE_API_BASE_URL=http://localhost:8000/api/v1

# .env.production
VITE_API_BASE_URL=https://api.example.com/api/v1
```
